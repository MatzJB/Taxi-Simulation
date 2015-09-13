%Matz JB 10/11 ~12
%Returns the lower left corner node of the given zone.

function node = Zone2Node(zone)

global n_zones b

n          = size(b, 2);
zone_width = (n+1)/2/n_zones; %width of zone
node       = mod(zone-1, n_zones)*zone_width + floor((zone-1)/n_zones)*zone_width*n_zones*zone_width + 1;



