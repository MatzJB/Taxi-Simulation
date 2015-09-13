%Matz JB
%Tested 18/1~12
%takes a node or coordinate and returns the zone ID
%it will also take several coordinates and return a vector with zones

function zone = ZoneID(node_1)

global n_zones n

n_tot = n;
npc     = (n + 1)/2; %nodes per column

if n_tot==0
    error('n is zero');
end

if ~all( round(node_1)==node_1 )
    error('ZoneID: A node should be an integer.')
end


if nargin > 1 || nargin==0
    error('Wrong number of arguments.');
elseif nargin == 1
    
    node_1 = node_1';%added floor 9/11~12
    ij = [2*floor( (2*node_1-1)/(n+1) ) + 1, mod(2*node_1-1, n+1)]';
    
    i = ij(1, :);
    j = ij(2, :);
    zone = 1 + n_zones*( floor( i/(n+1)*n_zones) ) + floor( j/(n+1)*n_zones );
    return;
    
elseif size(node_1, 1)==2 %a vector of coordinates
    
    i = (node_1(1, :));
    j = (node_1(2, :));
    
    zone = 1 + n_zones*( floor( i/(n+1)*n_zones) ) + floor( j/(n+1)*n_zones );
    return;
end
end


