%Todo: change name to Node2Mod (11/11~12)

%Tested: 18/1~12
%Argument is a node or a vector of nodes

%mod2ID = @(node) [2*floor( (2*node-1)./(n+1) ) + 1, mod(2*node-1, n+1)]; %node to mod^2 coordinate
%18/1 - Added extra test to return NaN when applicable for scalar and
%       vector arguments
%23% coverage to

function yx = Mod2ID(node)

global n Dists
%b Dists n_zones

n_tot   = size(Dists, 2);
%n       = length(b);
npc     = (n + 1)/2; %nodes per column

%if node is zero or larger than n_tot then NaN only for the nodes that
%apply (also work for vector argument)
node = (node <= n_tot).*node;
node = node./node.*node;

if n_tot==0
    error('n is zero');
end

if nargin > 1 || nargin==0
    error('Wrong number of arguments.');
elseif nargin == 1
    if size(node, 1) == 1
        yx = [2*floor( (2*node'-1)./(n+1) ) + 1, mod(2*node'-1, n+1)]'; %node to mod^2 coordinate
        return
    end
end


end