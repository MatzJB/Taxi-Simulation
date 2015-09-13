
%Replaced <sort_zones> because the sorting could be used outside of this
%function.

%Matz JB 26/11~12, updated 27/11
%The function returns a matrix of the distances (first column) from 
%<node_from> to every zone (as indicated by the second column).

function zonesdists = zones_distances(node_from)

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
