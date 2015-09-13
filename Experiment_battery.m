
%A battery of tests to produce the results for the project in the course
%"Simulation of Complex Systems"
%Matz JB 13/12~12

%The tests that we run, available:
% * 1 Cabs (increase the number of cabs)
% * 2 Presentation (showing how the rules affect the number of missed customers)
% * 3 Hotspot, modifying a hotspot to show how the rules are affected and how
%   the flow is changed

global using_GBG_rules using_priority_placement n_cabs spawnspeed customer_vector n_cust ...
    idle_mileage driving_mileage missed_customers customer_waiting

close all
 %number_of_cabs = [10, 20, 30, 50, 70, 100]; %ceil(linspace(2, 50, N));
customer_list = 1; %if we wish to repeat tests with the same customers
color_red   = [0.85, 0.2, 0.2];
color_green = [0.2, 0.8, 0.2];
color_blue  = [0.2, 0.2, 0.85];
colrs       = [color_red; color_green; color_blue];
symbols     = {'s-', 'o--', '^-'};
runs_label    = {'Cabs', 'Presentation', 'Hotspot'};

control_to_outside = 1; %communicates if variables are set outside of Taxi_sim4 or not
runs          = []; %the tests that we will run
vis           = [1,2,3];%[1, 2, 3]; %which tests do we want to visualize (if the results are stored)
n_cabs        = 50;

for h = 1:length(runs)
    fprintf(1, 'Tests in this session: %s\n', runs_label{h});
end

fprintf(1, 'Starting tests:');
pause(2)


spawnspeed = 0.0231;%fixed
fprintf(1, 'Spawnspeed: 1 customer per %fs\n', 1/spawnspeed);


%Testing how the system works when we increase the number of cabs (takes a long time)
%We get
%1. the number of cabs that is ok to use for GBG rules
%2. We show that the variation is not large, so we can generally tell
%something about a rule based on one value

%N = 10; %number of samples

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  Showing relationship between the number of cabs in the simulation and
%%%  the customer waiting and driving
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
idle1    = [];
    driving1 = [];
    missed1  = [];
    waiting1 = [];
    
if any(runs == 1)
    %We do not have to repeat the tests because the results are fairly
    %stable and reproducible.
    
    fprintf(1, '    Running cab test 1:\n');
    
    hotspot_source = 0;
    hotspot_sink   = 0;
    
    %number_of_cabs = [10, 20, 30, 50, 70, 100]; %ceil(linspace(2, 50, N));
    
    
    %we should create a customer list once and for all and use it for all the
    %different cab comparisons
    
    
    %reps = 1; %repetitions, we don't need this, just mention it
    %mode = 1; %which modes do we want in our trials?
    modes = 3;%the rules
    
    tic
    hotspot_source = 0;
    hotspot_sink   = 0;
    
    customer_list            = 1; %Bugging?, will not work atm, if we want to read the customer spawn positions from a buffer
    using_priority_placement = 0;
    using_GBG_rules          = 0;
    
    
    idle1    = zeros(length(number_of_cabs), modes);
    driving1 = zeros(length(number_of_cabs), modes);
    missed1  = zeros(length(number_of_cabs), modes);
    waiting1 = zeros(length(number_of_cabs), modes);
    
    for mode = 1:modes %the rules
        %I planned on using several modes for this test, but we don't need
        %to now
        if mode == 1
            using_GBG_rules = 1;
        elseif mode == 2
            using_priority_placement = 0;
            using_GBG_rules = 0;
        elseif mode == 3
            using_GBG_rules = 1;
            using_priority_placement = 1;
        end
        
        %for rep = 1:reps
        
        %Create customer list for each repetition but keep the tests
        %identical with different number of cabs
        
        customer_vector  = sink_source_function();
        
        
        
        for ii = 1:length(number_of_cabs)
            
            try
                n_cabs = number_of_cabs(ii);
                fprintf(1, 'Number of cabs %d (rep %d)\n', n_cabs, rep);
                
                Taxi_sim4
                
                idle1(ii,  mode)   = idle_mileage(end);
                driving1(ii, mode) = driving_mileage(end);
                missed1(ii, mode)  = missed_customers(end);
                waiting1(ii, mode) = sum(customer_waiting); %updated 18/12
                
            catch exp
                warning('An error occured...')
                disp(exp)
                
                idle1(ii, mode)    = 0;
                driving1(ii, mode) = 0;
                missed1(ii,  mode)  = 0;
                waiting1(ii, mode) = 0;
            end
            
            %   end
            
            
        end
    end
    
    toc
end


if any(runs==1) || any(vis==1)
    %%
    %Waiting time
    figure
    hold on
    
    for iii = 1:3
        plot(number_of_cabs, log10(waiting1(:, iii)), symbols{iii}, 'color', colrs(iii, :), 'linewidth', 2, 'MarkerEdgeColor', colrs(iii, :), 'MarkerFaceColor', colrs(iii, :));
    end
    
    
    %plot(number_of_cabs, log10(waiting1), 'O-', 'linewidth', 2)
    title('Customer waiting time')
    xlabel('Number of cabs in system')
    ylabel('Time log_{10}(s)')
    
    title_mod(1)
    set(gca, 'XGrid', 'on')
    set(gca, 'XTick', number_of_cabs )
    legend('GBG rule', 'Rule 1', 'Rule 2')
    
    %%
    %Missed customers
    figure
    hold on
    for iii = 1:3
        plot(number_of_cabs, missed1(:, iii), symbols{iii}, 'color', colrs(iii, :), 'linewidth', 2, 'MarkerEdgeColor', colrs(iii, :), 'MarkerFaceColor', colrs(iii, :));
    end
    %plot(number_of_cabs, log10(missed1), 'O-', 'linewidth', 2)
    title('Occurance of missed customers')
    xlabel('Number of cabs in system')
    ylabel('Missed customers')
    
    title_mod(1)
    set(gca, 'XGrid', 'on')
    set(gca, 'XTick', number_of_cabs )
    legend('GBG rule', 'Rule 1', 'Rule 2')
    
    %%
    %Idle driving
    figure
    hold on
    
    for iii = 1:3
        plot(number_of_cabs, idle1(:, iii), symbols{iii}, 'color', colrs(iii, :), 'linewidth', 2, 'MarkerEdgeColor', colrs(iii, :), 'MarkerFaceColor', colrs(iii, :));
    end
    
    %    plot(number_of_cabs, idle1, 'O-', 'linewidth', 2)
    title('Idle driving')
    xlabel('Number of cabs in system')
    ylabel('Distance (scaled units)')
    title_mod(1)
    set(gca,'XGrid','on')
    set(gca,'XTick',number_of_cabs )
    legend('GBG rule', 'Rule 1', 'Rule 2')
    
    %%
    %Driving
    figure
    hold on
    
    for iii = 1:3
        plot(number_of_cabs, driving1(:, iii), symbols{iii}, 'color', colrs(iii, :), 'linewidth', 2, 'MarkerEdgeColor', colrs(iii, :), 'MarkerFaceColor', colrs(iii, :));
    end
    
    %plot(number_of_cabs, driving1', 'O-', 'linewidth', 2)
    title('Driving')
    xlabel('Number of cabs in system')
    ylabel('Distance (scaled units)')
    %legend('Run 1', 'Run 2')
    title_mod(1)
    set(gca,'XGrid','on')
    set(gca,'XTick',number_of_cabs )
    legend('GBG rule', 'Rule 1', 'Rule 2')
    
end


%Presentation of the rules, we use 50 cabs.
%We store all the customers' data in a cold run and then let run the
%simulation on each rule and compare the missed customers, waiting time and
%driving and idle.
if any(runs==2)
    
    if numel(customer_waiting)==0
        warning('Customer waiting was not initiated')
    else
        
        n_cabs = 50;
        mode = 1;
        
        if mode == 1
            using_GBG_rules = 1;
        elseif mode == 2
            using_GBG_rules = 0;
        elseif mode == 3
            using_GBG_rules = 1;
            using_priority_placement = 1;
            
        end
        
        hotspot_source = 0;
        hotspot_sink   = 0;
        
        Taxi_sim4
        
        waiting2 = customer_waiting;
        
        
        %hotspot_source = 0;
        %hotspot_sink   = 0;
        
        %customer_vector = sink_source_function();
        %This test runs several pairwise identical runs so we can compare
        %between the three rules
    end
end

if any(vis==2)
    figure
    hist(waiting2, 20)
    title('Customer waiting time')
    xlabel('time (s)')
    ylabel('Occurance')
    title_mod(1)
    
end


%Hotspot test
%We will modify the hotspot strength and see what we can see in terms of
%missed customers and waiting time.
%We run the simulation cold first, saving the customer data for the
%increasing and decreasing hotspot. Then we try the different rules and
%compare.
%Create new values from the discretized translated unit circle.
tic
if any(runs == 3)
    clc
    fprintf(1, 'Running test 3\n');
    
    %customer_vector = sink_source_function();%here?
    customer_list    = 0; %we need to update the source sink for each loop...
    idle3     = [];
    driving3  = [];
    missed3   = [];
    waiting3  = [];
    n_cabs    = 50; %20 seems to be optimal
    
    %Notice that we need to use the same hotspot values for one hotspot situation
    for hotspot_index = 1:length(hotspot_values)
        
        tmp = hotspot_values(hotspot_index, :);
        
        hotspot_source = tmp(1);
        hotspot_sink   = tmp(2);
        
        
        for rule = 1:3
            
            
            
            %describe sink and source hotspot probability
            
            
            using_priority_placement = 0;
            using_GBG_rules = 0;
            
            if rule == 1
                using_GBG_rules = 1;
            elseif rule == 2
                using_GBG_rules = 0;
            elseif rule == 3
                using_GBG_rules = 1;
                using_priority_placement = 1;
                
            end
            
            fprintf(1, '---Rule: %d\n', rule);
            fprintf(1, '---Source: %.1f, Sink: %.1f\n', hotspot_source, hotspot_sink);
            
            Taxi_sim4
            
            %We take the last element because it is accumulated sum
            %if we want to know the change we can use diff
            idle3(hotspot_index, rule)    = idle_mileage(end);%sum(idle_mileage);
            driving3(hotspot_index, rule) = driving_mileage(end);
            missed3(hotspot_index, rule)  = missed_customers(end);
            waiting3(hotspot_index, rule) = sum(customer_waiting);
        end
        
        fprintf(1, '%.1f Percent done\n ', 100*hotspot_index/length(hotspot_values));
    end
    toc
end

if any(vis==3)
    
    
    
    
    %Missed customers>>
    figure
    hold on
    for iii=1:3
        plot(missed3(:, iii), symbols{iii}, 'color', colrs(iii,:), 'linewidth', 2, 'MarkerEdgeColor', colrs(iii,:), 'MarkerFaceColor', colrs(iii,:));
    end
    
    legend('GBG rule', 'Rule 1', 'Rule 2')
    legend_best_fit
    title('Occurance of missed customers')
    xlabel('Hotspot')
    ylabel('Number of customers')
    set(gca,'XGrid','on')
    set(gca,'YGrid','off')
    title_mod(0)
    
    %%
    %Waiting time>>
    figure
    hold on
    
    for iii = 1:3
        plot((waiting3(:, iii)), symbols{iii}, 'color', colrs(iii,:), 'linewidth', 2, 'MarkerEdgeColor', colrs(iii,:), 'MarkerFaceColor', colrs(iii,:));
    end
    
    set(gca,'XGrid','on')
    set(gca,'YGrid','off')
    
    legend('GBG rule', 'Rule 1', 'Rule 2')
    legend_best_fit
    title('Customer waiting time')
    xlabel('Hotspot')
    ylabel('Time (s)')
    title_mod(0)
    
    %%
    %Idle time>>
    figure
    hold on
    
    for iii = 1:3
        plot(idle3(:, iii), symbols{iii}, 'color', colrs(iii, :), 'linewidth', 2, 'MarkerEdgeColor', colrs(iii, :), 'MarkerFaceColor', colrs(iii, :));
    end
    
    set(gca,'XGrid','on')
    set(gca,'YGrid','off')
    
    legend('GBG rule', 'Rule 1', 'Rule 2')
    legend_best_fit
    title('Idle driving')
    xlabel('Hotspot')
    ylabel('Distance (scaled units)')
    title_mod(0)
    
end


%Test how the customer spawn speed affect missing customers, idle time etc.
if any(runs==4)
    %Constants:No hotspots, 50 cabs
    %variable:
    
    modes=3;
    customer_list            = 1; %Bugging?, will not work atm, if we want to read the customer spawn positions from a buffer
    using_priority_placement = 0;
    using_GBG_rules          = 0;
    spawn_speed_inv = [100, 50, 30];%spawn speed
    
    idle4    = zeros(modes, length(spawn_speed_inv));
    driving4 = zeros(modes, length(spawn_speed_inv));
    missed4  = zeros(modes, length(spawn_speed_inv));
    waiting4 = zeros(modes, length(spawn_speed_inv));
    
    for mode = 1:modes %the rules
        %I planned on using several modes for this test, but we don't need
        %to now
        if mode == 1
            using_GBG_rules = 1;
        elseif mode == 2
            using_GBG_rules = 0;
        elseif mode == 3
            using_GBG_rules = 1;
            using_priority_placement = 1;
            
        end
        
        %for rep = 1:reps
        
        %Create customer list for each repetition but keep the tests
        %identical with different number of cabs
        
        customer_vector  = sink_source_function();
        spawnspeed = 0.0231;%fixed
        
        n_cabs=50;
        
        
        for ss = 1:length(spawn_speed_inv)
            
            spawnspeed = 1/spawn_speed_inv(ss);
            
            try
                
                fprintf(1, 'Customers are created each %d seconds\n', spawn_speed_inv(ss));
                
                Taxi_sim4
                
                idle4(mode, ss)   = idle_mileage(end);
                driving4(mode, ss) = driving_mileage(end);
                missed4(mode, ss)  = missed_customers(end);
                waiting4(mode, ss) = sum(customer_waiting); %updated 18/12
                
            catch exp
                warning('An error occured...')
                disp(exp)
                rethrow(exp)
                idle4(mode, ss)    = 0;
                driving4(mode, ss) = 0;
                missed4(mode, ss)  = 0;
                waiting4(mode, ss) = 0;
            end
            
            %   end
            
            
        end
    end
    
end


if any(vis==4)
    
    
    figure
    hold on
    
    for mode = 1:3
        %for ss = 1:length(spawn_speed_inv)
        plot(spawn_speed_inv, waiting4(mode, ss), symbols{mode}, 'color', colrs(mode, :), 'linewidth', 2, 'MarkerEdgeColor', colrs(mode, :), 'MarkerFaceColor', colrs(mode, :));
    end
    %end
    
    set(gca,'XGrid','on')
    set(gca,'YGrid','off')
    
    legend('GBG rule', 'Rule 1', 'Rule 2')
    legend_best_fit
    title('Customer waiting time')
    xlabel('Spawn speed')
    ylabel('Time (s)')
    title_mod(0)
    
    
    %%
    
    figure
    hold on
    
    for mode = 1:3
        %   for ss = 1:length(spawn_speed_inv)
        plot(spawn_speed_inv, missed4, symbols{mode}, 'color', colrs(mode, :), 'linewidth', 2, 'MarkerEdgeColor', colrs(mode, :), 'MarkerFaceColor', colrs(mode, :));
    end
    %end
    
    set(gca,'XGrid','on')
    set(gca,'YGrid','off')
    
    legend('GBG rule', 'Rule 1', 'Rule 2')
    legend_best_fit
    title('Missed customers')
    xlabel('Spawn speed')
    ylabel('Time (s)')
    title_mod(0)
    
end
%customer waiting time borde man plott med procent eller nåt

%%%%%%%%%%%%%%%%%%%
%%% A map of the visited nodes in a normal setting
%%%%%%%%%%%%%%%%%%%%%%%


%
% Show how a hotspot changes the above
%


%%%%%%%%%%%%%%%%%%%
%%% A map of the visited nodes in the hot spot situation
%%%%%%%%%%%%%%%%%%%%%%%
