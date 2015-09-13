%Cache adjacency matrix of all zones


function spAMzones = cache_zones()

global spAM n_zones


%clear('spAMzones') %A buffer for visualisation and just driving around

fprintf(1, 'Initializing cache: spAMzones\n');
N = n_zones^2;

for i = 1:N
    spAMzones(i).adj   = spAM; %init
end


for current_zone = 1:N
    
    all_nodes        = 1:length(spAM);
    
    spAMtmp = spAMzones(current_zone).adj;
    
    node_keepers     = all_nodes( find(ZoneID(all_nodes) == current_zone) ); %the node ids that are involved in the current zone
    complement_nodes = setdiff(all_nodes, node_keepers);
    
    spAMtmp(complement_nodes, :) = 0; %Take out all elements with the nodes specified
    spAMtmp(:, complement_nodes) = 0;
    spAMzones(current_zone).adj = spAMtmp;
    
    if mod(current_zone, 2)==0
        fprintf(1, '.');
    end
end

fprintf(1, 'done\n');




