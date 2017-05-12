
global n b n_zones Dists spAM

clc
%clear all
close all
%clear
whitebg('white')
%addpath('C:\Users\Matz\Desktop\Simulation of Complex

%addpath('/home/matz/Documents/My Dropbox/Dropbox/Dropbox/Projects/Simulation of Complex Systems/Project/kod/matlab_bgl');
addpath('C:\Users\Matz\Dropbox\Dropbox\Projects\Simulation of Complex Systems\Project\kod\matlab_bgl')
addpath('C:\Users\Matz\Dropbox\Dropbox\Projects\Simulation of Complex Systems\Project\kod\legend_best_fit')

ver                 = 0.651; %version of this script
%"pain thresholds" for visualization and calculation, gives a warning or
%disables displaying data
n_painthreshold     = 253;
n_plotpainthreshold = 255;%for a moderate laptop:150, for a pretty good desktop: 250

%Dimensions:
n           = 151; %final:213?... 141, %default:55, dimension for matrix b. The number of nodes is then ( (n+1)/2 )^2, n should be odd
n_zones     = 7; %7 is ok, 13 works, 15 does not work, final: 10 %7, n_zones^2 zones. Should be gcd( (n+1)/2, n_zones ) == n_zones
%global n_zones, n
Dists       = [];
%global Dists

for m = n:2:(n+20)
    if gcd( (m + 1)/2, n_zones ) == n_zones
        n = m;
        disp(['Changed n to ', num2str(n), ', which is the nearest multiple of n_zones.']);
        break;
    end
end


%{
if mod((2*n-1),n_zones)~=0
    disp('To get zonesID to work 2*n mod n_zones must be 0.')
    return
end
%}

disp('overriding size constraints')

%Visualization variables:
res           = 10; %resolution of color
shownodes     = 0;  %Show nodes as black dots
showids       = 0;  %Show id numbers for each node
showzones     = 1;  %show zones along with colored areas
showzoneids   = 0;  %show zone ids for each node
calcdistances = 1;

if ~calcdistances
    disp('  Warning: [Not calculating distances...]')
end

showAM      = 0;
showM2      = 0;

offset      = 1; %The distance of each edge, default: 1
ant         = 0; %creation of edges using an ant

if n<7
    disp('Dimension of lattice matrix must be larger than 6.')
    return
end

if mod(n, 2) == 0
    disp('Dimension of lattice matrix must be odd.')
    return
end

%D = [1, 0; 0, 2]; %empty graph with buildings
%axis square

disp(['Taxi cab simulator version ', num2str(ver)]);
disp(' by Matz JB 2011-2012');

disp(['Number of nodes: ', num2str(((n+1)/2)^2), '.']);%bug
disp(['Number of zones: ', num2str(n_zones^2)])


if n>n_painthreshold %takes a minute
    
    memory
    
    reply = input('Warning: Very large data sets are being created, are you sure you want to continue with the calculations? Y/N [N]: ', 's');
    
    if isempty(reply)
        reply = 'N';
    end
    
    if reply=='N'
        return;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CREATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%mod^2 matrix creation
D    = [1, 0; 0, 0.8];%0.8 because everywhere there is 0, we use for edges, 0.8 is unused, but important to define for that reason.
b    = repmat(D, n);
b    = b(1:n, 1:n); %get the submatrix

mall = b;

%probabilities of "oneway street" and "not a node"
pnotnode     = 0.08; %percentation node removal
poneway      = 0.25; % percentage of one-way street
disp(['One way street variable was set to:', num2str(100*poneway,2),'%']);
edge_value   = 0.6;%the value of a double directed edge (default)

%Directions of the edge
dir_value_SW = 0.2; %South/West
dir_value_NE = 0.3; %North/East

%mall0       = edge_value*(mall==0);%the street matrix, creates a full
%matrix
%b           = mall + mall0;
b            = mall;
%OBS: The building part of the code is responsible of removing lone nodes and edges that link to nothing.

removed      = 0;%number of removed nodes

%We won't remove from the rim of the graph, to make it easier for us. Remove only the nodes
%that has at least 2 adjacent nodes.

%The code below is now obsolete, use my new rules to ensure reachability

%The city should have:
%* a long street
%* a couple of one way streets

%Rule 1, step through each node and add at least two new neighbours. This
%ensures that each node can be reached from every other nodes.


%Start the reachability condition by adding edges surrounding the city
range         = 2:2:n-1;
b(1, range)   = edge_value;
b(range, 1)   = edge_value;
b(range, end) = edge_value;
b(end, range) = edge_value;


format compact

simon = imshow(b);
%There is a probability that the code does not create a perfect city
%...
%assume a frame around the city is connected, we start from 2...end-1
for i=3:2:n-1
    for j=3:2:n-1
        
        %look in a cross around the current node and add at leat two edges
        
        if 1%b(i, j) ~= 0 %a node
            %randomly choose two directions
            
            %0 right, 1 up, 2 left 3 down
            %n_edges = 2 + round(2*rand); %how many edges
            n_edges   = 3;
            prev_dirs = [];%must be guaranteed unique
                 
            for k=1:n_edges %create double direction edges
                %fprintf(1, '-');
                %[1,1]
                %ensure the prev_dirs are all unique
                while sum(prev_dirs) < k
                    
                    dir = round(3*rand);
                    prev_dirs(dir + 1) = 1;
                end
                
                if dir==0
                    b(i, j+1) = edge_value; %right neighbour
                elseif dir==1
                    b(i-1, j) = edge_value; %upper neighbour
                elseif dir==2
                    b(i, j-1) = edge_value; %left neighbour
                elseif dir==3
                    b(i+1, j) = edge_value; %bottom neighbour
                else
                    disp('   An error with the edges occured')
                end
                %pause
                set(simon, 'cdata', b(end:-1:1,:))
            end
            
            if sum(prev_dirs)<2
                error('Num')
            end
            
        end
    end
end


%create the connections and visualize, store in C

%traverse the matrix and only put an edge between two '1':s
%More precisely, where a 3-vector of b ((3x1) or (1x3)) has the sum of 2

%We only traverse with an "ant", because we want a connected graph
%the function of the pattern could be described as: 1 mod(j,2)==0 &&
%mod(i,2) or mod(i,2)*mod(j,2)

%This makes it very simple to create the sparse matrix even, because we
%only need to create connections to the coordinates mod(i,2)*mod(j,2)
%which would be the neighbours (i+1,j) (i-1,j) (i,j-1) (i,j+1) given i and
%j are even.


f     = zeros(n, n);
steps = 0;%number of steps the ant will travel

%coordinates for stepping in the matrix
x     = 1;
y     = 1;
%we go through this trouble to get a connected "grid graph "
%previous_direction = [0, 0];%the previous imaginary direction, we don't want to travel

%City_VIS

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% VISUALIZATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%mod^2 visualization
%The new code is in City_VIS


if showM2
    figure
    colormap(summer(10))
    imagesc(b)
end

figure
%axis off
axis([-1 n+2 -1 n+2]) %intervals with padding
hold off
hold on

step  = (n-1)/n_zones;
pad   = offset;%offset+0.2;
scale = 1;
%fixed error with an exact edge by dividing i with n+1

%ZoneID returns the zone you are in. <FIXED>
zoneID = @(i, j)  1 + n_zones*(floor( i/(n+1)*n_zones) ) + floor( j/(n+1)*n_zones ); %this code is correct and must be 
%used because the variables in ZoneID is not setup before run


%VISUALIZE ZONES:
if showzones
    for i=1:n_zones
        for j=1:n_zones
            
            s = fill([(i-1)*step, i*step, i*step, (i-1)*step, (i-1)*step]*scale + pad,...
                [j*step, j*step, (j-1)*step, (j-1)*step, j*step]*scale + pad,...
                [1, 0.7 + 0.3*(mod(i, 2) + mod(j, 2))/2, 1]);
            
            
            set(s, 'edgecolor', 'none')
            %we cannot use ZoneID because Dists is not defined yet? i
            %believe I fixed it with the correct globals
            text(i*(step) - step/3, j*(step) - step/3, num2str(ZoneID(NodeID([j*step; i*step]) )), 'fontsize', 25, 'color', [0.9, 0.2, 0.7], 'HorizontalAlignment', 'center')
            
            %i=>y, j=>y
        end
    end
end



%axis off
[u, v, w] = find(b); %find the coordinates of the streets
%u - row, v - column, w - value

cols   = sum( sum(b == 1) );%the sum of 1's are the number of nodes

npc = (n+1)/2; %nodes per column
%NodeID returns the identity of a node given its coordinates
nodeID = @(i, j) (i-1)/2*npc + (j+1)/2; %(y,x)


%VISUALIZE LATTICE GRAPH:
%OBS: u is row but it is here treated as x coordinate (horizontal)
if n <= n_plotpainthreshold
    
    %title('Taxi Cab simulation graph', 'fontsize', 14)
    
    for i=1:length(u)
        linkcolor = [0 0 0];
        
        if w(i) == edge_value || w(i) == dir_value_NE || w(i) == dir_value_SW  %if edge
            if w(i) == dir_value_NE %directed edge
                linkcolor = [0.8 0 0];
            elseif w(i)== dir_value_SW %directed edge
                linkcolor = [0 0 0.6];
            elseif w(i) == edge_value %two directed edge
                linkcolor = [0 0 0];
            end
            
            if mod(u(i), 2) == 1 %horizontal link
                if w(i) == dir_value_NE %create an arrow
                    arrowv([v(i)-offset, u(i), 0], [v(i)+offset, u(i), 0], 15, linkcolor)
                elseif w(i) == dir_value_SW
                    arrowv([v(i)+offset, u(i), 0], [v(i)-offset, u(i), 0], 15, linkcolor)
                elseif w(i) == edge_value
                    line([v(i) - offset, v(i) + offset], [u(i), u(i)], 'linewidth', 1, 'color', linkcolor)
                end
            end
            
            if mod(u(i), 2) == 0 %vertical link
                if w(i) == dir_value_NE
                    arrowv([v(i), u(i)-offset, 0], [v(i), u(i)+offset, 0], 15, linkcolor)
                elseif w(i) == dir_value_SW
                    arrowv([v(i), u(i)+offset, 0], [v(i), u(i)-offset, 0], 15, linkcolor)
                elseif w(i) == edge_value
                    line([v(i), v(i)], [u(i)-offset, u(i)+offset], 'linewidth', 1, 'color', linkcolor)
                end
            end
        end
    end
    
    
    [y, x] = find(b == 1);
    hold on
    if shownodes
        plot(x, y, 'bo', 'MarkerSize', 3, 'MarkerFaceColor', [0 0 0]);%, 'MarkerEdgeColor', [0 0 0]) %the edges coordinates
    end
    
end

%be careful of the nodes axes
hold on
%VISUALIZE THE NODES:
if showids
    %add text to the nodes
    for i=1:length(u)
        if w(i)==1 %node
            text(v(i) + offset*0.4, u(i) + offset*0.4, num2str( nodeID(u(i), v(i))) ,'fontsize', 7, 'clipping', 'on');%, 'BackgroundColor', [.7 .9 .7])
            
        end
    end
end
hold on

if showzoneids
    for i=1:length(u)
        if w(i)==1 %node
            text(v(i) + offset*0.2, u(i) + offset*0.2, num2str(zoneID(u(i),v(i))));
        end
    end
end

spAM   = sparse(1:((n+1)/2)^2, 1:((n+1)/2)^2, 0); %sparse adjacency matrix

disp(['Number of edges: ', num2str( numel(find(b==1)), 2)]);
disp('Adjacency matrix is being built...')
%disp('Code below is not verified:')

%CONVERT TO ADJACENCY MATRIX:

for i=1:size(u, 1)
    
    if w(i) == edge_value || w(i) == dir_value_NE || w(i) == dir_value_SW  %if edge
        
        if mod(u(i), 2) == 1%horizontal
            from   = nodeID(u(i), v(i)-1);
            to     = nodeID(u(i), v(i)+1);
            
            if w(i) == dir_value_NE %right
                spAM(to, from) = 1;%link one direction
            elseif w(i) == dir_value_SW %left
                spAM(from, to) = 1;
            elseif w(i) == edge_value%double direction
                spAM(from, to) = 1;
                spAM(to, from) = 1;
            end
        end
        
        if mod(u(i), 2) == 0 %vertical
            from   = nodeID(u(i)-1, v(i));
            to     = nodeID(u(i)+1, v(i));
            
            if w(i)==dir_value_NE %up
                spAM(from, to) = 1;
            elseif w(i)==dir_value_SW %down
                spAM(to, from) = 1;
            else
                spAM(from, to) = 1;
                spAM(to, from) = 1;
            end
        end
    end
end

%if n>20
if showAM
    figure(3)
    spy(spAM)
end


spAM(length(spAM), length(spAM)) = 1; %last node is looped on self, just so we get a quadratic matrix because the library requires it

if calcdistances
    
    disp('Calculating all distances...');
    
    tic
    
    disp('testing to store the distances in a uint8 matrix')
    Dists  = johnson_all_sp(spAM);%distances between every node using single precision, test that this work, could use single
    
    
    disp(['Johnson algorithm took: ', num2str(toc,2),' seconds to finish.']);
    %[x, y] = find(Dists~=Inf); %throw Ds away and just use the
    %spDists  = sparse([x, y]);%if the element is 0
    %creating a sparse matrix is not worth it because memory runs out.
    
    disp(['Number of distances generated: ', num2str(numel(Dists) ,2), '.']);
    disp(['Memory of dists:', num2str( prod(size(Dists))*8/10^6 ,2), 'MB'])
    
    nrnodes = (n+1)/2;
    
    if all(size(spAM)==[nrnodes, nrnodes].^2)
        disp('The size of spAM is correct ')
    else
        disp(['The size of spAM (', num2str(size(spAM)), ') is not correct.'])
    end
    
   
    figure(4)

    imagesc(Dists)
    
    if max(max(Dists))==Inf
        error('I found a potential error with the Dists matrix, returned Inf for some nodes.')
    end
    
    disp(['dim of Dists:', num2str(size(Dists, 2))])
end


return

