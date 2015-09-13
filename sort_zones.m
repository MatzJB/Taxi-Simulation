%obsolete
%Matz JB 26/11~12
%The function sorts the zones w.r.t. distance to a specific node and
%returns a matrix of the zone ids (second column) and the distances (first column)


function zonesdists = sort_zones(node_from)

global n_zones Q

allzones = 1:n_zones^2;
zonespos = Mod2ID( Zone2Node(allzones) ); %lower left corner of each zone
zone_tmp = ZoneID(node_from);
cpos     = Mod2ID( Zone2Node(zone_tmp) ); %Get lower left coner of the current zone

zonesdists = allzones'; %the distances to the zones
%Adding distances as the second column of zonesdists
for i=1:length(zonespos)
    zonesdists(i, 2) = abs(zonespos(1, i) - cpos(1)) + abs(zonespos(2, i) - cpos(2));%we only care about zone neighbours really
end

%sort the zone IDs w.r.t. distance
%zonesdists = sortrows(zonesdists, 2);
