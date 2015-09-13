%
%Written by Matz JB
%Version 4 of the taxi sim.
%
% If you wish to create the same results as in article, run
% <Experiment_battery.m>
% If you wish to just run the simulator, just define control_to_outside=0
% using_priority_placement=0 using_GBG_rules=1
%
%

%
%Latest version update: 2/12~12
% [] 1/12 general debugging
% [] 2/12 Rewrote the assignment and fetching fields
% [] 3/12 *First run without error*
% [] 4/12 First run with bailing and scaled city of Gothenburg
% [] 5/12 Visualizing the result and adjusting customer spawn speed
% ... Many changes and additions, including optimization using caches,
%     makes the simulation ~3 times faster.
% [] 17/12 Last changes, fixed hotspot randNode2 and added customer list.
% ...
% [] 21/12 FInal version
%
%
%{
%%%%%%%%%%%%%%%%%%
 %              %%
  %              %
   %
    %
    Taxi Simulator Nov, Dec 2012
    Matz Johansson B. FOCAL-5
    for "Simulation of Complex Systems"
    %
   %
  %
 %               %
%%%%%%%%%%%%%%%%%%
%}


%addpath('C:\Users\Matz\Dropbox\Dropbox\Projects\Simulation of Complex Systems\Project\kod')

addpath('D:\Archive 2014\ACADEMIC_LABS\LABS in all courses\PHYSICS\Simulation of Complex Systems\Project\kod\matlab_bgl')
addpath('D:\Archive 2014\ACADEMIC_LABS\LABS in all courses\PHYSICS\Simulation of Complex Systems\Project\Github')

global T Q Dists b n n_zones spAM spAMzones speedup Mileage_quotient customer_vector customer_list idle_mileage driving_mileage missed_customers customer_waiting
global zoneids_cache

n = size(Dists, 2);
n_tot=n;
zoneids_cache = ZoneID(1:n); %Speedier code, 21/12

% must be here because randNode2 needs Dists


%rng('default'); % for reproducibility
run = 1;
%clc
%format compact

savefile = ['run', num2str(run), '.mat'];

verbose     = 0;

if verbose
    disp('Todo:')
    disp('* Verify that stealing is possible...done')
    disp('*    \Do we need bail field?...done')
    disp('* Fix realistic customer bailout time...done')
    disp('* Fix scaling...done')
    disp('* Test distance distribution based on city size (1-3km is prevalent)...done')
    disp('* Rescale distance from seconds to meter...done')
    disp(' ')
    disp(' Hotspot control:')
    disp(' Use * or / buttons to increase or decrease source')
    disp(' Use + or - buttons to increase or decrease sink')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%moving average window
%mavgsize=10;
control_to_outside=false

fprintf(1, 'Creating hotspot vector\n');

hotspot_values = [];
i = 1;
for x = 0:0.5:1
    for y = 0:0.5:1
        hotspot_values(i, 1:2) = [x, y];
        i = i + 1;
    end
end


if ~control_to_outside%if we use this matlab code to create data only
    
    n_cabs         = 50; %23, total number of cabs in the simulation
    n_cust         = 3000; %number of customers allowed at one time (will be reused)
    hotspot_source = 0;
    hotspot_sink   = 0;
    
end
%hotspot_source = 1;%affects waiting time so it is no longer gamma
%distributed


safe        = 0;
number_of_spawned_customers = 0;
refreshrate = 1; %update graphics each 'refreshrate' frame, use low value for debugging
inputs      = 0; %input node start, end and customer start node
speedup     = 1; %enable all speedups used throughout the simulation
cab_IDs     = 1;
adaptive_customer_spawnage = 0;%if we wish the flow of customers to be adaptive or not
%diary('hist.txt');

Mileage_quotient = [];

TEST_SPREAD = 0; %spawn all the cabs inside zone 1 and no customers
TEST_STEAL  = 0; %only 2 cabs

if TEST_STEAL
    inputs = 1;
end

using_GBG_rules = 1;%if 1, we use the "zone assignment idea", otherwise we use the closest
%cab and we also place a cab higher up in the zone queue if a cab miss

using_priority_placement = 0; %if a cab is bailed it is placed first in queue

if using_priority_placement
    
    if ~using_GBG_rules
        error('GBG rule must be used when using priority rule!')
    end
    
    fprintf(1, '   Using priority placement upon bailed customer.\n');
end

if using_GBG_rules
    
    fprintf(1, '   This simulation use Taxi Göteborg zone rules.\n');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%t_total      = tic();

n            = length(b); %number of nodes (one dimension) from data b

n_tot        = size(Dists, 2);
total_hours  = 2; %12, will affect spawn speed
zones_sink   = zeros(n_zones, n_zones);
zones_source = zeros(n_zones, n_zones);

edgedistance = 50; %m

ms2kmh       = 3600/1e3;
block_i      = 1; %for missed customers average array
block_start  = 1;
block_end    = 1;
customer_waiting_average = [];

%Make sure the duration of the cab driving from A to B
%distance between A and B is edgedistance*n
maxdist      = ceil(n/3); %number of edges from center of city to edge is kind of far so all chauffeur are bailing
edgedist     = 10; % , 5 => ~61 Km/h, 5.8 =>66.9km/h, 6 => 55.2 km/h, 7 => 49km/h
%8=>43.4 km/h, 9=>39km/h
%n*edgedistance/t*ms2kmh


%edgedistance*n*
%speed = edgedist, we need to calculate how fast a cab is...

speedconv    = 1e3/(60*60)/edgedist;%convert between real world speed (km/h) to visualization speed (m/s)
%spawnspeed   = 1/500; %1 per 100 seconds
%spawnspeed = 0.0231; %fixed
average_spawn_speed = 0; %if we calculate the average spawn speed

%pic_nr       = 1;
%number of customers per cab should be on average 20

if average_spawn_speed
    average_customers = spawnspeed*total_hours*60*60/n_cabs;
    average_customers = 20;
    spawnspeed = average_customers/(total_hours*60*60)*n_cabs;
    
    %n_cabs = spawnspeed*total_hours*60*60/average_customers;
    %n_cabs = average_customers*n_cabs/(total_hours*60*60)
    %n_cabs = ceil(n_cabs);
    
    average_customers = spawnspeed*total_hours*60*60/n_cabs;
    fprintf(1, 'Adjusted spawnspeed to spawn one customer per %d s to get the average customer serving %d per cab.\n', 1/spawnspeed, average_customers );
end

if TEST_SPREAD
    fprintf(1, 'SPREAD MODE\n');
    spawnspeed = 0;
end


%{

if average_customers >25 || average_customers < 15
error('Number of customers served in average is outside the range what is deemed normal.')
end
%}

%fprintf(1, 'Average number of customers per cab: %d\n', average_customers);


%These values overrides all speed vars
%not used:
%{
cab_drive_speed    = 30; %km/h
cab_onroute_speed  = 50;
cab_free_speed     = 40;
%}

colors         = 0.6*eye(3) + 0*(eye(3) == 0);
colors(4, 1:3) = [0.6, 0.6, 0]; %A steal
colors(5, 1:3) = [0.1, 0, 0]; %Waited for more than 10 minutes inside a zone
delta          = edgedist; %the frequency of the polling of a new cab

hrs            = 0;
%tic %used for simulation speed

influence_distance = 2; %the farthest distance a customer is looking for another cab while waiting
%This should be small, since the cab "jumps" to the position when it finds a
%customer.

%The simulation is scaled to km and hrs to better emulate the real world

blink = 1;%used to visualize a steal
ver   = 3.14159;

fprintf(1, '_______________________________________________________________________\n\n');

%printspeed = 0.0051;

%Intro

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%load('Taxi_data2.mat')%make sure this is loaded ok

t = 0; % We use seconds as the smallest time unit, to get a physically feasible simulation

if verbose
    disp([' n = ', num2str(n)])
    
    if n/n_zones ~= floor(n/n_zones)
        disp('Increase size of n_zones or graph to get optimal zone size.')
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Return advice in print that the number of taxis should be scaled %
% with the number of zones the number of edges in each zone should %
% be at least 5 (check).                                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if verbose
    fprintf(1, 'waiting for you to adjust window size...\n');
    fprintf(1, 'Starting simulation.\n');
end

if inputs && n_cabs~=2
    %error('Number of cabs when allowing inputs must be 2');
    disp('Changed number of cabs to 2')
    n_cabs      = 2;
    refreshrate = 5;
    spawnspeed  = 1/1000;
end

%n_taxiGBG   = 10; %number of cabs from 'taxi Göteborg'

%spawnspeed  = 1; %customers per second, currently not used
erased_data = 0; %denotes data that has been deleted


if ~control_to_outside %if we use this matlab code to create data only
    display_C   = 0;
    display_Q   = 0;
    display_T   = 0;
    
    display_sleep        = 0;
    display_missed       = 0;
    display_progress     = 0;
    display_wait         = 0;
    display_stat         = 0; %statistics
    display_dists        = 0; %distances customers wish to drive
    display_bailtimes    = 0;
    display_timezone     = 0;
    display_paths        = 0; %for fun
    display_mileageq     = 0;
    display_cwaiting     = 0;
    %display_orders       = 1; %pickups and drop-offs
    
    display_zones_flow   = 1;%will display sink and source
    %display_zones_source = 1;
    %display_zones_sink   = 1;
    
else
    display_C         = 0;
    display_Q         = 0;
    display_T         = 0;
    
    display_sleep     = 0;
    display_missed    = 0;
    display_progress  = 0;
    display_wait      = 0;
    display_stat      = 0;
    display_dists     = 0;
    display_bailtimes = 0;
    display_timezone  = 0;
    display_paths     = 0;
    display_mileageq  = 0;
    display_cwaiting  = 0;
    %display_orders = 0;
    
    display_zones_source = 0;
    display_zones_sink   = 0;
    
    display_zones_flow   = 0;
    
    verbose = 0;
end

clear('paths') %A buffer for visualisation and just driving around

for i=1:n_cabs
    paths(i).path    = []; %starting the struct
    paths(i).elapsed = 1;
    paths(i).total   = 0; %must be computed before useage in waking cabs and must be smaller than elapsed 21/11
    paths(i).pathMod = [1; 2]; %optimization
end

if speedup
    spAMzones = cache_zones();
end

clear('neighbours') %A buffer for neighbours for each customer

for i=1:n_cust
    neighbours(i).nodes    = []; %starting the struct
end


%{
if spawnspeed~=floor(spawnspeed)
    error('spawn speed must be an integer')
end
%}

if verbose
    disp('Spawn speed is not used at this time.')
end

[b2, zone_nodes, n2] = unique(ZoneID(1:n_tot), 'first');
%pick the nodes where the zones start, for the idle movements of the cars
%nice trick

%say Q(1, 5) = 4 => zone 1 has cab number 5 at place 4 in the queue
Q = zeros(n_zones^2, n_cabs); %Queue matrix
%Q(1, i) = 4  => cab i is at place 4 in the queue in zone 1

T = zeros(15, n_cabs); %Taxi matrix

%See "List_of_macros" for the explanation of the indices of T, Q and C
%Macros:
T_state         = 12;

T_state_onroute = 1;
T_state_driving = 2;
T_state_free    = 3;


C = zeros(7, n_cust); %Customer matrix

%The simulation is driven by time, the speed of customer spawning is
%governed by <spawnspeed>
%T(1, :)      = 1;              %randNode2(n_cabs); %generate random nodes for the n_cabs cabs
if TEST_SPREAD
    T(1, :) = ones(1, n_cabs);
else
    T(1, :) = randNode2(n_cabs);
end

T(T_state, :) = T_state_free;   %Cab is vacant
T(3:4, :)     = Mod2ID(T(1, :));%store the coordinates, 17/11~12
T(12, :)      = T_state_free;   %added 21/11
T(5, :)       = 0;              %all cabs are awake

%fig1 = figure;
pad    = 1.2;
[M, N] = size(T);
%axis([1-pad, M+pad, 1-pad, N+pad])


%drawnow
%{
figure
fig_T = text(0, 0.5, '', 'FontName', 'FixedWidth');

figure
fig_Q = text(0, 0.5, '', 'FontName', 'FixedWidth');
%}
%close all

if display_sleep
    fig3 = figure;
    hold on
    fig_sleep     = plot(0*1:n_cabs, 'k-o', 'linewidth', 2);
    fig_time      = plot([1, n_cabs], [1, 1], 'r:', 'linewidth', 1);
    title('Cab sleep plot')
    xlabel('Cab')
    ylabel('Time (s)')
end

if display_progress
    fig4 = figure;
    hold on
    fig_total     = plot(0*1:n_cabs,'k-o', 'linewidth', 2);
    fig_elapsed   = plot(0*1:n_cabs, 'r:', 'linewidth', 1);
    title('Cab progress plot')
    xlabel('Cab')
    ylabel('Time (s)')
end

missed_customers = [];
marked           = [];

if display_missed
    fig6 = figure;
    hold on
    fig_missed = plot([1,2], 'k', 'linewidth', 2);
    %fig_marked = plot([1, 2], [1, 2], 'rx', 'linewidth', 3);%to mark a change in rules
    fig_marked = stem([1, 2], [1, 2], '-', 'color', [0.3, 0.5, 0.3], 'linewidth', 1)
    
    title('Missed customers')
    xlabel('t')
    ylabel('Frequency')
end

if display_wait
    fig7 = figure;
    hold on
    %fig_wait     = plot(0*1:n_cabs, 'k-o', 'linewidth', 2);
    
    fig_wait = hist(customer_waiting)
    title('Cab waiting in zones plot')
    xlabel('Cab')
    ylabel('Wait (s)')
end

customer_buffer_history = [1,1];

if display_stat
    fig8 = figure;
    fig_stat = plot([1, 2], customer_buffer_history, 'linewidth', 4)
    
    %set(gca,'XTickLabel', {'Customer buffer', '2', '3'})
    %axis([0, 2, 0, n_cust])
    xlabel('t')
    ylabel('Number of customers')
end

customers_distances = [1];

if display_dists
    fig9 = figure;
    fig_dists = plot(customers_distances, 'k', 'linewidth', 3)
    
    xlabel('nr')
    ylabel('Customers distances')
end


bail_times = [];

if display_bailtimes
    fig10 = figure;
    fig_bailtime = plot(customers_distances/60, 'k', 'linewidth', 3)
    
    ylabel('Bail time (minutes)')
    xlabel('#')
end

in_current_zone = [];

if display_timezone
    fig11 = figure;
    fig_timezone = plot([1], 'k', 'linewidth', 3)
    
    ylabel('Zone time (s)')
    xlabel('Cab')
end

idle_mileage    = [];
driving_mileage = [];

if display_mileageq
    fig12 = figure;
    hold on
    fig_idle    = plot([1], 'b', 'linewidth', 2) %idle
    fig_driving = plot([1], 'g', 'linewidth', 3) %driving customer
    legend('Passive driving (idle)', 'Active driving (driving customer)')
    
    ylabel('Total mileage')
    xlabel('t')
end

customer_waiting = [];

if display_cwaiting
    fig13    = figure;
    fig_cwait = plot([1, 1], [1, 1], 'k');
    title('Waiting time for customers')
end


if display_zones_flow
    fig14 = figure;
    colormap(bone)
    fig_zones_source = imagesc(zones_source);
    fig15 = figure;
    colormap(bone)
    fig_zones_sink = imagesc(zones_sink);
end

    
%{
fig5 = figure;
hold on

fig_Qplot   = plot(0*1:n_zones, 'r:', 'linewidth', 1);
title('Queue')
xlabel('Q')
ylabel('Number of cabs')
%}

if ~control_to_outside
    
    fig1 = figure;
    hold on
        disp('Paused...')
    pause

    
    %draw the paths in the city, 9/12
    if display_paths
        
        fig_paths = [];
        
        for i = 1:n_cabs
            fig_paths(i) = plot([1], 'k', 'linewidth', 1);
        end
    end
    
    
    City_VIS
    
    axis off
    hold on
    set(gcf, 'renderer', 'opengl')
    
    if cab_IDs
        g = [];
        for i = 1:n_cabs
            g(i) = text(T(4, i), T(3, i), num2str(i), 'Color', [1, 1, 1], 'Backgroundcolor', [0, 0, 0]);
        end
    else
        
        fig_cars1  = plot(0*T(4, :)', 0*T(3, :)', 'sr', 'linewidth', 2);
        fig_cars2  = plot(0*T(4, :)', 0*T(3, :)', 'sg', 'linewidth', 2);
        fig_cars3  = plot(0*T(4, :)', 0*T(3, :)', 'sb', 'linewidth', 2);
    end
    
    
    %fig_cabIDs    = plot(0*T(1, :), 0*T(1, :), 'o', 'linewidth', 3);%several paths
    
    
    fig_cars_from = plot(0*C(1, :), 0*C(1, :), 'o', 'linewidth', 3, 'color', [0.6, 0, 0]);
    fig_cars_to   = plot(0*C(1, :), 0*C(2, :), 'rx', 'linewidth', 3);
    
    %reuse for study of Brownian movement
    fig_path      = plot(0*T(1, :), 0*T(1, :), 'b:', 'linewidth', 3);%several paths
    
    h = title({'Taxi cab simulation ver 4'},'FontName', 'Georgia','fontsize', 14);
    
    
    %grid on
    %fig_customers     = plot(0*C(3, :), 0*T(4, :), 'bs');
    
    coords = zeros(n_cust, 4);%coordinates for 'from' and 'to'
    %axis([0, n, 0, n])
    
    if display_C
        figure
        C_fig = imagesc(C);
        title('C')
    end
    
end

%C_fig = imshow(C)
if verbose
    disp('Simulation was initiated')
end

CustomerID = -1; %used to index C


%Enqueue all the cabs
for i = 1:n_cabs
    if inputs
        fprintf(1, 'Please enter cab position %d\n', i);
        xy = ginput(1);
        yx = [xy(2); xy(1)];
        T(1, i) = NodeID(yx);
    else
        %T(1, i) = 1;
    end
    
    Q = enqueue_cab(i, Q);
end

%erase above
zones = ZoneID(T(1:2, :));


if display_Q
    figure
    Q_fig = imagesc(Q);
    title('Q')
end


k = [];
set(gcf, 'keypress', 'k=get(gcf,''currentchar'');');

if ~control_to_outside
    using_GBG_rules = 1;
    using_priority_placement = 0;
    
    drawnow
    %pause
    
    spawnspeed = 0.0231;%fixed
end

t = 1;
%tic
while t <= total_hours*60*60 %12 hours of simulation
    
    t = t + 1; %step in time, step in time...
    
    if safe
        if isempty( find(Q == 1) ) && ~isempty( find(Q > 1) )
            Q
            error('The elements of Q is inconsistent.')
        end
    end
    
    %if verbose
    if mod(t, 500) == 0
        if verbose
            fprintf(1, ' ====================== (t = %i) ====================== \n', t);
            %time = sec2clock(t);
        end
    end
    %end
    
    if ~control_to_outside
        if mod(t, 200)==0
            set(h, 'String', sprintf('Time: %s', secs2hms(t)))
        end
    end
    
    %    pause(0.02)
    
    %CUSTOMER SPAWNING
    if mod(t, ceil(1/spawnspeed)) == 0
        
        number_of_spawned_customers = number_of_spawned_customers+1;
        
        CustomerID  = CustomerID + 1; %This variable may only be altered here
        CID         = CustomerID;
        CID         = mod(CID, n_cust) + 1;%buffer limit is n_cust customers
        
        if C(1, CID) ~= 0
            error('The customer buffer <C> is too small. Stopping the simulation.');
        end
        
        if verbose
            fprintf(1, '*Customer %i was spawned\n', CID);
        end
        
        
        if verbose
            %disp('Select a node to spawn a customer')
        end
        
        if inputs
            fprintf(1, 'Please input the start position of the customer\n');
            xy = ginput(1);
            yx = [xy(2); xy(1)];
            startNode = NodeID(yx);
        else
            %{
if ~control_to_outside
                startNode = customer_vector(number_of_spawned_customers, 1);
            end
            %}
            %Customer list is the fixed customer buffer
            if customer_list
                startNode = customer_vector(number_of_spawned_customers+20, 1);
            else
                startNode  = randNode2('hotspot', hotspot_source);
            end
        end
        
        C(1, CID)  = startNode;
        tmp = (ZoneID(startNode));%added 14/12~12
        %ind = sub2ind(size(zones_source), tmp(1));
        zones_source(tmp) = zones_source(tmp) + 1;
        
        
        C(4, CID) = t;
        if verbose
            disp('Added start node');
        end
        
        C(5, CID) = t; %wake up immediately to actively look for a cab
    end
    
    %end
    
    %*********************************************************************
    %*                       CUSTOMERS WAKE-UP
    %*********************************************************************
    indices = find(C(5, :) == t); %Awake the customers
    
    for i = indices %iterate the customers
        
        if C(2, i) == 0 %Target node (means that a cab...) has not been assigned yet
            
            %Early test: can we figure out if there are any cabs vacant?
            vacantcabs = find( T(12, :) == 3 ); %we can replace with binary?
            
            if numel(vacantcabs) == 0
                if verbose
                    fprintf(1, 'The number of vacant cabs is 0, try again later...\n');
                end
                
                C(5, i) = t + 1*60; %try again later, added 23/11
            else
                if verbose
                    fprintf(1, 'Attempting to fetch a cab for customer %d. Looking', i);
                end
                
                node_from = C(1, i);
                cabID     = find_cab(node_from, maxdist, using_GBG_rules);
                
                if cabID == 0 %we could not find a cab (could happen if the cab driver is also not interested)
                    C(5, i) = t + 100;
                    if verbose
                        fprintf(1, '...unsuccessful.\n');
                    end
                else %we found a cab
                    if verbose
                        fprintf(1, '...successful.\n');
                    end
                    
                    customerID = i;
                    %endNode           = randNode2(C(1, customerID), 1); %create destination
                    %{
if ~control_to_outside
                        endNode = customer_vector(number_of_spawned_customers, 2);
                    end
                    %}
                    
                    if customer_list
                        endNode = customer_vector(number_of_spawned_customers, 2);
                    else
                        endNode = randNode2(C(1, customerID), 'hotspot', hotspot_sink); %16/12~12
                    end
                    
                    
                    C(2, customerID)  = endNode;
                    
                    tmp = (ZoneID(endNode));%added 14/12~12
                    %ind = sub2ind(size(zones_sink), tmp(1), tmp(2));
                    zones_sink(tmp) = zones_sink(tmp) + 1;
                    
                    
                    %C(4, customerID)  = t;%added 20/11
                    
                    customers_distances(end+1) = Dists(C(1,customerID), C(2, customerID));
                    
                    
                    if verbose
                        fprintf(1, 'Requested node <%i to %i>\n', node_from, endNode);
                    end
                    
                    %C(3, customerID) = cabID; %added 19/11
                    T(13, cabID) = customerID;
                    
                    
                    if verbose
                        fprintf(1, '\\Cab %d was assigned to customer %d\n', cabID, customerID);
                    end
                    
                    Q                    = dequeue_cab(cabID, Q);
                    [d pred]             = shortest_paths(spAM, T(1, cabID)); %fixed bug 21/11, 22/11
                    tmp_path             = path_from_pred(pred, C(1, customerID)); %fixed bug cabID 20/11
                    total_duration       = edgedist*length(tmp_path); %floor(cab_drive_speed*dist/speedconv);
                    %T(7, cabID)          = T(7, cabID) + edgedist*length(tmp_path); %real distance traveled
                    paths(cabID).path    = tmp_path;
                    
                    if speedup
                        paths(cabID).pathMod = Mod2ID(tmp_path);%cache
                    end
                    
                    paths(cabID).elapsed = 0;
                    paths(cabID).total   = total_duration; %must be the same as T(5,i)
                    %duration_mins = ceil(total_duration/60)
                    
                    %Todo: return time instead of binary
                    bt                   = bail_time();
                    bail_times(end+1)    = bt;
                    %fix bt
                    C(5, customerID)     = t + bt; %the customer is very eager to get a cab hence wakes up immediately, 26/11
                    T(5, cabID)          = t + total_duration; %added 22/11, bugfix 23/11, duration??4/12
                    
                    if verbose
                        fprintf(1, 'Cab %d will be awaken at t = %d\n', cabID, T(5, cabID));
                    end
                    
                    T(12, cabID)         = 1; %The cab is now driving to the customer 23/11
                end
            end
            
            %If the customer wakes up (initiated by the "bail time") and the
            %target node has been assigned to, we need to actively look around
            %for a cab.
            
            %!!BAILING!!
        else %if T(14, cabID) == 0 %changed 6/12, 23:22, cabID~=0 & T(14, cabID) == 0 %added cabID thing 5/12, bugfix 5/12,%C(6, i) == 0 % The target node has been assigned (initialized) but
            %We go through the cabs in the zone and choose the one that is closest
            %fprintf(1, 'Under construction\n');
            
            if speedup
                if numel(neighbours(i).nodes)==0 %the buffer is empty
                    
                    neighbours(i).nodes = find( Dists(C(1, i), :) <= influence_distance);
                end
                candidateNodes = neighbours(i).nodes;
            else
                candidateNodes = find( Dists(C(1, i), :) <= influence_distance);
            end
            
            cabs = find(sum(Q)); %added 20/11, or use any(Q)
            cabs = cabs(randperm(length(cabs))); %randomize, so we do not favor a certain index
            
            cab = 0;
            %Look for the cab...
            for j = 1:length(cabs)
                for k = 1:length(candidateNodes)
                    if T(1, cabs(j)) == candidateNodes(k)
                        cab = cabs(j);
                        break
                    end
                end
            end
            
            if cab == 0
                if verbose
                    %fprintf(1, '%s The customer is actively looking for other cabs...\n', padding);
                end
                
                C(5, i) = t + delta; %t_delta; %check as much as necessary, 26/11
                
            else %found cabs, pick randomly from them
                
                if verbose
                    fprintf(1, 'Found candidate: %d for customer %d\n', cab, i);
                end
                
                %Todo: We should make sure than the cheater arrives faster than
                %the assigned cab
                
                %reset path so it stops at the customer
                
                %Spirit of truth: cut that b*tch off!
                the_path = paths(cab).path;
                paths(cab).total   = edgedist*length(the_path);
                paths(cab).elapsed = paths(cab).total;
                
                cab_progress     = length(the_path)*paths(cab).elapsed/paths(cab).total;
                
                %since the distance of a close cab is almost always smaller than the distance left to travel
                %for the assigned cab, we can do this
                cabID        = cab; %30/11
                T(13, cabID) = i;%changed 14->13, 7/12
                T(5, cabID)  = t + 50; %wake almost immediately, updated 30/11
                
                if verbose
                    fprintf(1, 'Cab %d will be awaken at t = %d\n', cabID, T(5, cabID));
                end
                
                T(12, cabID) = 1;
                
                %Todo: add information about the cab?!
                
                %this customer bailed?
                %Pick the cheater cab, was also assigned
                the_cheated_cabID = find((1:size(T,2)~=cabID).*T(13, :) == i);
                %added7/12
                
                T(15, the_cheated_cabID) = cabID;%this cab has been cheated by cabID
                
                if verbose
                    if numel(the_cheated_cabID) > 1
                        the_cheated_cabID
                        error('cheated on several cabs')
                        fprintf(1, ',Customer %d cheated on cab %d\n', i, the_cheated_cabID);
                    end
                end
                
                Q            = dequeue_cab(cabID, Q); %added 30/11, cab is not available for other customers
                
                %Reset path, 1/12
                if verbose
                    fprintf(1, ' ::: Customer managed to find cab %d, wakes up at t = %d\n', cabID, T(5, cabID));
                end
            end
        end
    end
    
    %wake up to arrive at target node or to arrive at the position where the
    %customer is
    %We use the indices are cab numbers, because they are ordered in that
    %way
    
    %*********************************************************************
    %*                          CABS WAKE-UP
    %*********************************************************************
    
    indices = find(T(5, :) == t); %Wake up taxi cabs, now decisions has to be made
    
    if verbose && ~isempty(indices)
        fprintf(1, '^ Waking up cab %d\n', indices);
    end
    
    if safe
        if all(T(5, :)~=0) && any(T(5, :) == t-1)%print once if there is a risk a cab is a zombie
            warning('Zombie warning')
            fprintf(1, '===> Cab %d may have become a zombie?!\n', find(T(5, :) == t-1));
            %error('One of the cabs has become a zombie')
        end
    end
    
    %Driving the customer to the destination...
    for i = indices %cab ID
        
        if verbose
            fprintf(1, 't = %d\n', t);
        end
        
        % padding = repmat(' ', 1, i);
        padding = ' ';
        %Modified 6/12
        %CID = [T(13, i), T(14, i)];
        %CID = unique( CID(CID > 0) );
        %CID = T(13, i);
        %if there are several IDs in CID,
        
        
        %OK, 3/12
        if length(CID)>1
            warning('CID contains several IDS')
        end
        
        if ~isempty(CID)
            
            if T(12, i) == 1 %Arrived to customer
                if T(15, i) == 0 %customer associated with cab has not bailed yet
                    
                    CID = T(13, i); %added 6/12
                    cheat = find(T(15, :) == T(13, i));
                    C(5, CID) = 0; %we do not want to wake up the customer anymore
                    
                    %if the cab was assigned to another cab, set the appropriate field as "bailed"
                    %I'm here
                    
                    if verbose
                        fprintf(1, '%s Customer ID: %d\n', padding, CID)
                    end
                    
                    customer_waiting(end+1) = t - C(4, CID); %waiting time
                    
                    %Not picked up any customer (real) or already picked up the
                    %customer (cheater)
                    %C(6, CID) == 0 || C(6, CID) == i %The customer has not been picked up OR it has been picked up by this cab
                    
                    if verbose
                        fprintf(1, '%s The Cab has arrived to the customer\n', padding);
                    end
                    
                    T(12, i)  = 2; %must change state because the cab is now onroute to the target node
                    T(9, i)   = T(9, i) + 1; %we have added one customer
                    T(14, i)  = CID; %19/11, if cheat then this will not matter, fetched cabs, seen from the customer
                    
                    %Create the path of nodes from customers position C(1, CID) to the destination C(2, CID)
                    %This information is used to vosualize the path of the cabs
                    %if verbose
                    %    fprintf(1, '%s Path: %d -> Node %d\n', padding, C(1, CID), C(2, CID));
                    %end
                    
                    [d pred]         = shortest_paths(spAM, C(1, CID));
                    tmp_path         = path_from_pred(pred, C(2, CID));
                    
                    paths(i).path    = tmp_path;
                    
                    if speedup
                        paths(i).pathMod = Mod2ID(tmp_path); %cache
                    end
                    
                    total_duration   = edgedist*length(tmp_path); %edgedist?%floor(cab_drive_speed*dist/speedconv);
                    T(7, i)          = T(7, i) + length(tmp_path)*edgedist; %total time driving to customer
                    
                    T(5, i)          = t + total_duration; %time until cab must wake up again, bugfix 23/11
                    
                    if verbose
                        fprintf(1, 'Cab %d will be awaken at t = %d\n', i, T(5, i));
                    end
                    
                    paths(i).elapsed = 0;
                    paths(i).total   = total_duration;
                else %my customer bailed
                    
                    if verbose
                        fprintf(1, '<BAILED> My customer bailed with cab %d\n', T(15, i));
                    end
                    
                    %The cab can only be cheated if T(12,i)=1
                    %if T(14, i) ~= CID %Code for the cab which customer had bailed with another cab
                    %find the bailee
                    bailed = find(T(13, :) == CID);
                    
                    %Wake me up again later and requeue me, so I can go to
                    %work.
                    
                    if rand < 0.3 %70% of the time a customer will be reachble by cell phone
                        
                        T(8, i) = T(8, i) + 1; % miss
                        T(5, i) = t + 10*60; %10 minutes punishment
                        
                        if verbose
                            fprintf(1, '%s 10 minutes of punishment (will be awaken at t = %d)\n', padding, T(5,i));
                        end
                    else
                        
                        T(8, i) = T(8, i) + 1;
                        T(5, i) = t + 1*60; %1 minute punishment
                        
                        if verbose
                            fprintf(1, '%s 1 minute of punishment (will be awaken at t = %d)\n', padding, T(5,i));
                        end
                    end
                    
                    
                    %if verbose
                    %    fprintf(1, '%s -Clearing customer ID field %d\n', padding, CID);
                    %end
                    %mod 6/12
                    %  C(:, CID)   = C(:, 1)*0; %we need to erase the data after the bailed cab notices it
                    %  neighbours(CID).nodes=[];%5/12
                    
                    T(13:15, i) = 0;
                    
                    if verbose
                        fprintf(1, '%s -Clearing temporary cab data\n');
                    end
                    
                    T(12, i)    = 3; %free, but will not be reintroduced into the simulation until I'm requeued
                    Q           = enqueue_cab(i, Q);%is this necessary or can this be handled with the waking up sequence?
                    %queue in priority
                    
                    if using_priority_placement
                        
                        if verbose
                            fprintf(1, '+Priority placement applied to cab %d\n', i);
                        end
                        Q = enqueue_priority(i, Q);
                    end
                    
                    
                end
                
            elseif T(12, i) == 2 %19/11~12
                
                CID = T(14, i);
                
                if verbose
                    fprintf(1, 'CID:%d\n', CID);
                    fprintf(1, 'Cab arrives with customer\n');
                    fprintf(1, '%s Cab %d has arrived with customer %d and will be free in a couple of moments\n', padding, i, CID);%bugfix 23/11
                end
                
                %disp('>>> The cab will soon be free')
                T(5, i)    = t + 2*60; %wake me up later
                
                if verbose
                    fprintf(1, 'Cab %d will be awaken at t = %d\n', i, T(5, i));
                    
                    fprintf(1, '%s ^Waking up cab %d at t = %d\n', padding, i, T(5, i));
                end
                
                total_duration   = edgedist*length(tmp_path); %edgedist?%floor(cab_drive_speed*dist/speedconv);
                T(7, i)   = T(7, i) + total_duration;
                T(12, i)   = 3; %it is now free, but still waits
                
                %TEST, 4/12
                %if T(13, i) == T(14, i) %C(3, CID) == C(6, CID) %was not bailed, free to erase customer data
                C(:, CID) = C(:, 1)*0;%we need to erase the data AFTER the bailed cab notices it
                neighbours(CID).nodes = [];%5/12
                
                %T(15, i)=1%bailed
                
                if verbose
                    fprintf(1, '%s -Clearing customer ID field %d\n', padding, CID);
                    fprintf(1, '%s -Clearing temporary cab data\n', padding)
                end
                %end
                
                index = find( (1:size(T,2) ~= i).*T(13, :) == CID); %added must differ from i 7/12
                %if index is NULL, then we dont need to assign any value to
                
                Q = enqueue_cab(i, Q); %added 29/11
                
                %The cab that was cheated on
                %if the cab was cheating, the cab that was cheated must be
                %set
                
                if safe
                    if verbose
                        warning('Found several indices for assigned cab')
                        index
                    end
                end
                
                if verbose
                    fprintf(1, 'Setting bail field on cab %d\n', index);
                    %fprintf(1, '%s +Setting bail field for cab %d\n', padding, index);
                    fprintf(1, '%s -Erasing cab data for cab %d\n', padding, i);
                end
                
                %must erase data
                T(14, i) = 0;
                T(13, i) = 0;
                T(15, index) = CID; %right? added 7/12
                
                T(2, i)      = T(2, i) + paths(i).elapsed; %how far we drove
                
                if verbose
                    fprintf(1, '%s Total distance (seconds) driving customer: %d \n', padding, T(2,i));
                end
                
                %Reset path, 1/12
                paths(i).elapsed = 1;
                paths(i).total   = 0;
                
                if verbose
                    fprintf(1, '%s Requeued cab %d\n', padding, i);
                    %fprintf(1, '%s Cab %d was Enqueued in zone %d.\n', padding, CID, z);
                end
                
                %Todo: queue the cab to the zone
                if safe
                    if verbose
                        if abs( diff(Mod2ID(T(1, i)) - Mod2ID(C(2, CID))) ) > 1
                            error('The cab has arrived with the customer but the target position is not correct')
                        end
                    end
                end
            end
        end %must be here 19/11~12
    end
    
    %Update position for the cabs in the plot (update using interpolation and stuff)
    
    %Merged codes to update positions
    cabs_driving_or_onroute = find( T(12, :) == 1 | T(12, :) == 2 );%driving to or with a customer
    
    %i or CID?
    for i = cabs_driving_or_onroute
        
        paths(i).elapsed = paths(i).elapsed + 1;%cab_onroute_speed*speedconv; %step in time...
        
        the_path      = paths(i).path;
        cab_progress  = length(the_path)*paths(i).elapsed/paths(i).total; %progress, fixed bug 19/11
        progress_edge = ceil(cab_progress);
        
        if progress_edge <= length(the_path)
            
            %speedup here
            if speedup
                T(3:4, i) = paths(i).pathMod(:, progress_edge);
            else
                T(3:4, i) = Mod2ID(the_path(progress_edge));
            end
            T(1, i)   = the_path(progress_edge); %must update where we are now 23/11
        end
    end
    
    %Zone driving behavior:
    cabs_free = find( T(12, :) == 3 & T(5, :) < t ); %The cab is free and not asleep
    
    for i = cabs_free
        
        %The cab is just driving within his zone
        %at some point, the driver will switch zone, but this is not implemented
        
        %Todo: fix speed when driving within zone 21/11
        
        if paths(i).elapsed >= paths(i).total %create a new path
            if verbose
                %fprintf(1, 'Creating new path for cab %d in zone %d\n', i, ZoneID(T(1,i)));
            end
            
            %fprintf(1, 'Cab %d is driving within zone %d\n', i, ZoneID(T(1,i)));
            
            %TODO: add the time and distance we drove (to statistics)
            paths(i).elapsed = 0;
            
            %Todo:Use a more powerful idle driving routine, 26/11
            %*********************************************************
            [new_path, zone_changes] = idle_driving(i, 2);
            
            %T(7, i)   = T(7, i) + edgedistance*length(new_path);%we approximate the distance we will travel with this
            
            %zone_changed is used to know if the driving engine switched
            %zone
            paths(i).zone_changes = zone_changes;%a vector of when the zones changes in the path (indices)
            paths(i).zone_index   = 1; %the zone I'm in now is the first index
            
            paths(i).total   = edgedist*length(new_path); %the time
            paths(i).path    = new_path;
            paths(i).pathMod = Mod2ID(paths(i).path); %cache
            
        end
        
        %Todo: add statistics to T, 27/11
        
        the_path         = paths(i).path;
        cab_progress     = length(the_path)*paths(i).elapsed/paths(i).total; %progress, fixed bug 19/11, removed edgedist
        progress_edge    = ceil(cab_progress);
        
        paths(i).elapsed = paths(i).elapsed + 1;%cab_free_speed*speedconv;%testing, 5/12
        T(7, i) = T(7, i) + length(the_path)*1/paths(i).total; %stämmer detta?
        
        %we should let the cab move to the designated zone and then zero
        
        
        %todo: queue cab when we change into a new zone
        
        %Traveling within and between zones (written 27/11~12)
        if length(paths(i).zone_changes) > paths(i).zone_index %> 8/12 ~12
            
            if progress_edge == paths(i).zone_changes(paths(i).zone_index) %if the index is correct, then we know the zone has changed
                
                Q = dequeue_cab(i, Q); %We remove the cab from the previous zone
                Q = enqueue_cab(i, Q); %We enqueue the cab in the current zone
                
                if verbose
                    fprintf(1, 'Cab %d switched a zone, now enqueued in zone %d.\n', i, find(Q(:, i)));
                end
                
                T(6, i) = 0; %time we have been in the zone is reset
                paths(i).zone_index = paths(i).zone_index + 1; %progressed the zone change (in one go, there might be several zone changes)
            end
        end
        
        if progress_edge > 0 && progress_edge <= length(the_path) %must update, added progress_edge>0 28/11
            
            if speedup
                T(3:4, i) = paths(i).pathMod(:, progress_edge);
            else
                T(3:4, i) = Mod2ID(the_path(progress_edge));
            end
            
            T(1, i)   = the_path(progress_edge); %22/11
            
            T(6, i)   = T(6, i) + 1;%correct
        end
        
        %compute t_delta, the polling frequency
        %Figure out the overlapping window of time. All are driving
        %with the same speed, but the offset they start differs.
    end
    
    %the interpolated coordinates should be relative to the position we are now
    %for all cabs that are on the look out, update cab
    %use node ids instead of coordinates?
    if ~control_to_outside
        if mod(t, refreshrate) == 0
            
            if display_Q
                set(Q_fig, 'cdata', Q);
            end
            
            if display_C
                set(C_fig, 'cdata', C);
            end
            
            coords(:, 1:2) = Mod2ID(C(1, :))';
            coords(:, 3:4) = Mod2ID(C(2, :))';
            
            %Important: coordinates are in (y,x)
            
            set(fig_cars_from, 'xdata', coords(:, 2), 'ydata', coords(:, 1));
            set(fig_cars_to, 'xdata', coords(:, 4), 'ydata', coords(:, 3));%bugfix 23/11
            blink = mod(blink+1, 2);
            
            if cab_IDs
                %set(fig_cars, 'xdata', T(4, :), 'ydata', T(3, :));
                
                for i = 1:n_cabs
                    %find(T(13, i)==T(14, i));%CID = T(13, i);
                    %cheated_cab = find(T(13, :) ~= T(15, i));
                    bgcol = colors(1, :);
                    fgcol = [1, 1, 1];
                    %{
                if T(15, i) > 0 %T(13, i) ~= T(14, i) && T(13, i) ~= 0 && T(14, i) ~= 0
                    
                    %bgcol = colors(4,:);
                    %bgcol = blink*colors(4, :);
                    fgcol = (1-blink)*[1, 1, 1];
                else
                    %}
                    bgcol = colors(T(12, i), :);
                    %    end
                    
                    %The heat of the cab
                    %{
                if T(6, i) > 30*60;
                    fgcol(1) = 0;
                else
                    fgcol(1) = 1-T(6, i)/(30*60);
                end
                    %}
                    
                    set(g(i), 'Position', [T(4, i), 0.5 + T(3, i)], 'Backgroundcolor', bgcol, 'Color', fgcol, 'horizontalalignment','center');
                    
                    
                    
                    % set(g(i), 'Position', [T(4, i), 0.5 + T(3, i)], 'Backgroundcolor', [d, 0, 0],'horizontalalignment','center');
                end
            else %only squares
                %this must be faster than above, picking the cabs
                %and going through them in "blocks"
                
                tmp = find( T(12, :) == 1 );
                set(fig_cars1, 'xdata', T(4, tmp), 'ydata', T(3, tmp));
                tmp = find( T(12, :) == 2 );
                set(fig_cars2, 'xdata', T(4, tmp), 'ydata', T(3, tmp));
                tmp = find( T(12, :) == 3 );
                set(fig_cars3, 'xdata', T(4, tmp), 'ydata', T(3, tmp));
                
            end
        end
    end
    %end
    %set(fig_cars, {'Position'}, [T(4,:), T(3,:)], 'String', num2str(1:n_cabs))%?
    
    %{
        cur_coord = T(3:4, 1);
        distance = sqrt((pre_coord(1) - cur_coord)^2 + (cur_coord(1)-cur_coord(2))^2);

        pre_coord = T(3:4, 1)
    %}
    %set(fig2, 'Title', ['Speed cab 1:', num2str()])
    
    %{
    for i=1:n_cabs
        tmp(i) = paths(i).total/edgedist - paths(i).elapsed;
    end
    
    fprintf(1, 'range: [%d, %d]\n', min(tmp), max(tmp));
    %}
    
    if mod(t, 60*60) == 0
        if verbose
            fprintf(1, '                Simulation at %d hours\n', hrs);
            hrs = hrs+1;
            fprintf(1, '                Simulation speed %f (simulation/real) \n', hrs*60*60/toc);
            fprintf(1, 'Serving %d cabs an hour\n', ceil( sum(T(9, :))/hrs ));
            fprintf(1, 'Total number of spawned customers %d.\n', number_of_spawned_customers);
        end
        %toc
    end
    
    
    if mod(t, 200)==0
        if display_stat
            %set(fig_stat, 'ydata', [sum(C(1, :)>0)]);
            customer_buffer_history(end+1) = sum(C(1, :)>0);
            set(fig_stat, 'xdata', 1:length(customer_buffer_history), 'ydata', customer_buffer_history);
        end
        
        if display_dists
            
            set(fig_dists, 'ydata', sort(edgedistance*customers_distances));
        end
        
        %Det räcker att ta ut sista värdet i <Experiment_battery>
        idle_mileage(end+1) = sum( T(7, :));
        driving_mileage(end+1) = sum( T(2, :));
        missed_customers(end+1) = sum(T(8, :));
        
    end
    
    if ~control_to_outside
        
        if mod(t, refreshrate) == 0
            
            if display_sleep
                set(fig_sleep, 'ydata', T(5, :));
                set(fig_time, 'ydata', [t, t]);
            end
            
            if display_progress
                set(fig_elapsed, 'ydata', [paths(:).elapsed]);
                set(fig_total, 'ydata', [paths(:).total]);
            end
            
            if display_wait
                set(fig_wait, 'xdata', size(T(6,:)), 'ydata', T(6,:));
                %      set(fig_wait, 'xdata', 1:length(customer_waiting), 'ydata', customer_waiting);
            end
            
            if display_missed
                set(fig_missed, 'ydata', missed_customers);
                set(fig_marked, 'xdata', marked, 'ydata', max(missed_customers) + 0*marked);%to see when I pushed the button
            end
            
            if display_bailtimes
                set(fig_bailtime, 'ydata', sort(bail_times/60));
            end
            
            
            if display_timezone
                set(fig_timezone, 'ydata', T(6, :));
            end
            
            
            if display_zones_flow
                
                set(fig_zones_source, 'cdata', zones_source);
                
                set(fig_zones_sink, 'cdata', zones_sink);
            end
            
            if display_mileageq
                ws = 10;
                
                tmp = smooth(diff(idle_mileage), ws/length(idle_mileage), 'loess');
                set(fig_idle, 'ydata', tmp);
                tmp = smooth(diff(driving_mileage), ws/length(driving_mileage), 'loess');
                set(fig_driving, 'ydata', tmp);
                
                %set(fig_mileageq, 'ydata', Mileage_quotient);
            end
            
            
            if display_cwaiting
                
                %vi borde ta average per 200 sekunder istället
                %set(fig_cwait, 'ydata',  smooth(customer_waiting, 3, 'moving'), 'xdata', 1:length(customer_waiting));
                
                %ws = 50;%we need this to be smooth because it is each customer
                %A = smooth(diff(idle_mileage), ws/length(idle_mileage), 'loess');
                
                block_end = length(customer_waiting);
                customer_waiting_average(block_i) = mean(customer_waiting(block_start:block_end));
                %tmp = smooth(customer_waiting, ws/length(customer_waiting), 'loess');
                
                set(fig_cwait, 'ydata',  sort(customer_waiting_average), 'xdata', 1:length(customer_waiting_average));
                %set(fig_driving, 'ydata', driving_mileage);
                
                block_i = block_i+1;
                block_start = block_end+1;
                %block_end depends on how many customers has been served
                %during 1/refreshrate seconds.
                
                %set(fig_mileageq, 'ydata', Mileage_quotient);
            end
            
            %{
            if display_orders
            set(fig_orders, 'xdata', orders(1,:), 'ydata', orders(2,:), 'color', [0.3, 0.3, 0.3]);
            
            end
            %}
            
            if display_paths
                
                for i = 1:n_cabs
                    
                    tmppath = Mod2ID(paths(i).path);
                    %cab_progress = ceil( length(paths(i).path)*paths(i).elapsed/paths(i).total );
                    
                    %if length(tmppath) >= cab_progress
                    %    tmpppath = tmppath(1:cab_progress);
                    %end
                    col = [0, 0, 0];
                    %{
    if paths(i).elapsed == 1
        col=[1,0,0];
    end
                    %}
                    set(fig_paths(i), 'xdata', tmppath(2,:), 'ydata', tmppath(1, :), 'color',col);% [length(tmppath)/100, 0, 0])
                end
            end
            
            drawnow
        end
    end
    
    if mod(t, 100) == 0
        
        servespeed = sum(T(9, :))/t;
        
        if verbose
            %fprintf(1, 'serving speed (1 customer per): %1.2f, spawn speed: %1.2f seconds\n', 1/servespeed, 1/spawnspeed);
        end
        
        if adaptive_customer_spawnage
            if servespeed > spawnspeed && 1/spawnspeed < 1000
                spawnspeed = spawnspeed/2;
            else
                spawnspeed = spawnspeed*2;
            end
        end
        
        %fprintf(1, 'Spawnspeed %d\n', 1/spawnspeed);
        %['Number of customers served per s:', num2str( )]
    end
    
    if safe
        %checking Q
        for i=1:size(Q, 1)
            if max( diff(unique(Q(i, :))) ) > 1
                error('Inconsistencies found in Q.')
            end
        end
    end
    
    %input handling
    if ~isempty(k)
        if strcmp(k, 'g')
            using_GBG_rules = -using_GBG_rules + 1;
            fprintf(1,'GBG rules? %d\n', using_GBG_rules);
            marked(end+1) = length(missed_customers);
        end
        
        if strcmp(k, 'p')
            using_priority_placement = -using_priority_placement + 1;
            fprintf(1, 'Priority placement? %d\n', using_priority_placement);
            marked(end+1) = length(missed_customers);
        end
        
        if strcmp(k, '*')
            if hotspot_source < 1
                hotspot_source = hotspot_source + 0.1;
            end
            fprintf(1, 'Hotspot source value increased to %d\n', hotspot_source);
        end
        
        if strcmp(k, '/')
            if hotspot_source > 0
                hotspot = hotspot_source - 0.1;
            end
            
            fprintf(1, 'Hotspot source value decreased to %d\n', hotspot_source);
        end
        
        
        if strcmp(k, '+')
            if hotspot_sink < 1
                hotspot_sink = hotspot_sink + 0.1;
            end
            
            fprintf(1, 'Hotspot sink value increased to %d\n', hotspot_sink);
        end
        
        if strcmp(k, '-')
            if hotspot_sink > 0
                hotspot_sink = hotspot_sink - 0.1;
            end
            
            fprintf(1, 'Hotspot sink value decreased to %d\n', hotspot_sink);
            
        end
        k = [];
    end
end %while


disp('Simulation has ended.')

zones_source = rot90(zones_source);
zones_sink   = rot90(zones_sink);

customers_distances;
customer_waiting;
number_of_spawned_customers;

fprintf(1, 'Data:\n');
idle_mileage;
driving_mileage;
missed_customers;

%T(7,:)*edgedistance
%Summary

%toc(t_total)

if ~control_to_outside
    
    %axis off
    reply = input('Do you wish to save the results? Y/N [Y]: ', 's');
    
    if isempty(reply)
        reply = 'Y';
    end
    
    if strcmp(reply,'N')
        return
    end
    
    savefile = 'run_1.mat';
    
    %save to a unique file name:
    
    i=1;
    while exist(savefile, 'file')
        i        = i+1;
        savefile = ['run_', num2str(i),'.mat'];
    end
    
    save(savefile, 'T', 'C', 'using_GBG_rules', 'using_priority_placement')
    disp(['The results were saved as:', savefile, '.'])
    
end

