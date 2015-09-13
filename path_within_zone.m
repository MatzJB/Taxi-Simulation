%The function returns a path that is within a zone, provided the node
%belongs to the zone.
%The finns skarvar mellan varje sekvens av pather, detta kan simulera att
%bilen vänder 22/11
%8/12 added speedup when copying spAM

function the_path = path_within_zone(node_1, len)

global spAM n_zones n spAMzones speedup

the_path     = [];
zone_width   = n_zones/2;
coords       = ones(2, 2);
allcoords    = [];
current_zone = ZoneID(node_1);
%Setup the four corners:
LowerCornerNode = Zone2Node(current_zone);

zone_width = (n+1)/2/n_zones; %Width of zone

a_corner = Mod2ID(LowerCornerNode);         % fetch lower left corner
b_corner = a_corner + [0; 2*zone_width-2];  % upper left
c_corner = b_corner + [2*zone_width-2; 0];  % upper right
d_corner = a_corner + [2*zone_width-2; 0];  % lower right

corners  = NodeID([a_corner, b_corner, c_corner, d_corner]);

if ~all( ZoneID(corners) == current_zone )
    error('Zone ID error')
end

if speedup
%Retrieve sparse adjacency matrix from cache (8/12~12)
spAMtmp = spAMzones(current_zone).adj; %cached zone adjacency matrix
else

%Retrieve the nodes in the zone and erase from spAM

all_nodes        = 1:length(spAM);
node_keepers     = all_nodes( find(ZoneID(all_nodes) == current_zone) ); %the node ids that are involved in the current zone
complement_nodes = setdiff(all_nodes, node_keepers);

spAMtmp = spAM;

spAMtmp(complement_nodes, :) = 0; %Take out all elements with the nodes specified
spAMtmp(:, complement_nodes) = 0;
end

node_2 = node_1;


for i=1:len
    
    %Om det inte finns en explicit path från shortest_paths så vet
    %vi att noderna inte finns i spAMtmp, d.v.s. utanför zonen.
    while node_1==node_2 || ZoneID(node_2)~=current_zone || length(the_path)==1
        
        %Generate a point on the square, the next point should be far
        %away from the previous point. We use the "four corner"
        %method to randomly create walks within the zone.
        
        node_2 = corners( ceil(rand*length(corners)) );
        
        if mod(i, 5)==0 %Random node inside of the zone
            yx = [(c_corner(1) - a_corner(1))*rand + a_corner(1);...
                (b_corner(2) - a_corner(2))*rand + a_corner(2)];
            node_2 = NodeID(yx);
        end
        
        %If shortest path cannot find a way, then it returns nothing?
        [d, pred] = shortest_paths(spAMtmp, node_1);
        tmp_path = path_from_pred(pred, node_2);
    end
    
    the_path = [the_path, tmp_path];
    
    node_1 = node_2;
end
