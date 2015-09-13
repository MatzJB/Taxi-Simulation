%Matz JB 2012
%22/11 Visualisation of the "Matrix"

%figure
%axis off
axis([-1 n+2 -1 n+2]) %intervals with padding
hold off
hold on

step  = (n-1)/n_zones;
pad   = offset;%offset+0.2;
scale = 1;

showzones      = 1;
showids        = 0;%id of nodes

shownodes      = 0;
showzoneids    = 0;
showzonelabels = 0;
showlinks      = 0;

%fixed error with an exact edge by dividing i with n+1

%ZoneID returns the zone you are in. <FIXED>
%zoneID = @(i, j)  1 + n_zones*(floor( i/(n+1)*n_zones) ) + floor( j/(n+1)*n_zones ); %this code is correct and must be 
%used because the variables in ZoneID is not setup before run


%floor(i/n*n_zones + j/n_zones);
%Testing the zoneID code (9/11)

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
            if showzonelabels
            text(i*(step) - step/2, j*(step) - step/2, num2str(ZoneID(NodeID([j*step; i*step]) )), 'fontsize', 20, 'color', [1, 0.4, 0.9], 'HorizontalAlignment', 'center')
            end
            %text(i*(step) - step/3, j*(step) - step/3, num2str(ZoneID(NodeID(floor( [j*step, i*step]' )))), 'fontsize', 25, 'color', [0.9, 0.2, 0.7], 'HorizontalAlignment', 'center')
            %text(i*(step) - step/3, j*(step) - step/3, num2str(zoneID(j*step, i*step)), 'fontsize', 25, 'color', [0.9, 0.2, 0.7], 'HorizontalAlignment', 'center')
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
if showlinks

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
        plot(x, y, 'b.', 'MarkerSize', 3, 'MarkerFaceColor', [0 0 0]);%, 'MarkerEdgeColor', [0 0 0]) %the edges coordinates
    end
    
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
