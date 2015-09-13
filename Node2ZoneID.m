%obsolete (16/11~12)
function zone = Node2ZoneID(node_1)

global b Dists

n_tot = size(Dists, 2);
n = length(b);

if n_tot==0
    error('n is zero');
end

if nargin > 1 | nargin==0
    error('Wrong number of arguments.');
elseif nargin == 1
    %ZoneID( Mod2ID(node_1) )
    
    npc    = (n + 1)/2; %nodes per column
nodeID = @(i, j) (i-1)/2*npc + (j+1)/2; %coordinate (y,x) in mod^2 to node ID
zoneID = @(i, j) 1 + n_zones*( floor( i/(n+1)*n_zones) ) + floor( j/(n+1)*n_zones ); %coordinate in mod^2 to zone ID
mod2ID = @(node) [2*floor( (2*node-1)./(n+1) ) + 1, mod(2*node-1, n+1)]; %node to mod^2 coordinate

    return;
end

end