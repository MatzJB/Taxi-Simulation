%randNode returns a mod^2-coordinate (x, y) based on input value (xy_1) and max distance
%allowed (dist). Minimum distance should be 3, the distribution is scaled
%to work for Dists.

%Updated 14/12~2:
%* We need a way to differ between startNode and endNode and if we use a hotspot or not


%randNode2() - Returns a (uni-) random point in the city.
%randNode2(num) - Returns <num> (uni-) random points in the city.
%randNode2('hotspot', prob) - Returns a random start point with a
%      probability <prob> to return a node within the center zone.
%randNode2(startNode, 'hotspot', prob) - Returns an end node given
%      <startNode> and <hotspot> probability. The probability
%      distribution is gamma distributed.

function node_2 = randNode2(node_1, hotspot, p, varargin)
global b Dists n_zones zoneids_cache speedup

n_tot = size(Dists, 2);
node_2 = 0;

if n_tot==0
    error('n is zero');
end

hotspot_zone = ceil(n_zones^2/2); %The hotspot zone

if nargin > 3
    error('Wrong number of arguments.');
end

if nargin == 0 %new uniformly random coordinate on mod^2 matrix
    node_2 = ceil( n_tot*rand );
    return
elseif nargin == 1 %one argument (scalar) returning a number of random coordinates
    node_2 = ceil( n_tot*rand(1, node_1) );
    return
elseif nargin==2 %two arguments (second arg if hotspot is used or not) returns a new node wrt distribution of distances (exponential)
    if strcmp(node_1, 'hotspot')
        if rand < hotspot
            
            if speedup
            hotspot_nodes = find(zoneids_cache == hotspot_zone);
            else
                hotspot_nodes = find(ZoneID(1:n_tot) == hotspot_zone); %Pick out the nodes within the hotspot zone
            end
            node_2 = hotspot_nodes(ceil(rand*length(hotspot_nodes))); %Choose one of them at random
            
        else %uniform random selection
            node_2 = ceil( n_tot*rand );
        end
        
        %start position hotspot with probability <hotspot>
        return
    else
        error('arg 1 option is not implemented')
    end
    
    
elseif nargin==3
    
    %Generate a short range that is exponentially distributed and pick
    %uniformly random from those, if none are available, choose from a larger
    %set. Give a warning if the set of available distances is small.
    %Hotspot used is the zone in the middle
    
    if strcmp(hotspot, 'hotspot')
        %{
        if ZoneID(node_1) == hotspot_zone %We wish to leave from the zone
            
            nonhotspot_nodes = find(ZoneID(1:n_tot) ~= hotspot_zone); %Pick out the nodes outside of the hotspot
            node_2 = nonhotspot_nodes(rand*length(nonhotspot_nodes));
            return;
        else
        %}
        
        muhat = 6.6903;
        %rand_distance = 5 + exprnd(muhat);%random distance following a exponential distribution.
        rand_distance = gamrnd(3, 2, 1, 1)*5; %was 5, TODO:the distance is for km, scale for edgedistance edges
        
        %The distance is at least 3 and follows the exponential distribution function after than
        v = [];
        scale = 1;%for higher probability of hit
        
        if node_1 == 0
            error('The first node cannot be zero');
        end
        
        %Create the diamond shaped "ring" of nodes
        while numel(v) == 0
            [u, v] = find( abs( rand_distance - Dists(node_1, :) ) <= scale ); %change to km
            scale = scale + 3;
        end
        
        %added hotspot 16/12~12
        tmp = [];
        %Choose any hotspot node in the ring, if any
        if rand < p
            
            tmp = find( hotspot_zone == ZoneID(v) ); %pick out elements from v that are hotspots

            if numel(tmp)~=0
                node_2 = v(tmp(ceil(rand*length(tmp))));%pick one of the hotspot nodes
                return;
            end
        end
        
        %There were no hotspot nodes. OBS: We know |v|>0
        node_2 = v(ceil(rand*length(v))); %randomly choose a node of the whole sample space, including the hotspot?
        return
        
        
        
        %compute the number of nodes
        %withint hotspot vs other points*P(hotspot)
        
        %weight the points using hotspot
        
        %{
        %we get the new node from v, u is 1 for all u
        id = ceil(rand*length(v));
        %id = ceil(0.5*length(v)); %this will not work!!
        node_2 = v(id);%choose a node from v
        %}
        
    else
        error('arg 2 option is not implemented')
    end
else
    error('You provided randNode2 with the wrong number of arguments.')
end
