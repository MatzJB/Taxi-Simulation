%Takes a vector of coordinates 2xn where n is the number of coordinates in
%mod^2
%History:
% 10/11 ~12 fixed non-integer inputs
%
function mod2 = NodeID(yx)

global b Dists n

%New
%n_tot   = size(Dists, 2);
%n       = size(b, 2);
n_tot = n;
npc     = (n + 1)/2; %nodes per column

if n_tot==0
    error('n is zero');
end

if nargin > 1 || nargin==0
    error('Wrong number of arguments.');
elseif nargin == 1
    
    i = 2*floor(yx(1, :)/2) + 1; %snap to correct coordinate
    j = 2*floor(yx(2, :)/2) + 1;
    
    mod2 = round( (i-1)/2*npc + (j+1)/2 );
    return;
end
end

