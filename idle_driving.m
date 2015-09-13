%Matz JB 26/11, **First version**

%This function governs all the idle driving done by a cab. The function is called
%when new paths are needed. The new paths are based on data contained in T
%and Q. Because the new path is based on current time. As <len> is
%increased, the quality of the paths are decreased.


function [path, zones] = idle_driving(cabID, len)

global T Q n_zones spAM

path  = [];
zones = [];

%RULES:
%If I have waited >30 mins (4 cabs are before me) and driving to another zone
%will get me a better position, then I will move to another zone. I will choose
%the zone closest to me.

%Additional data: We need to know for how long the cab has been in the
%different zones.


%If the position 'm in the current zone is >5 and I will find another zone
%better
node_1 = T(1, cabID);

z = find( Q(:, cabID) ); %cabID is in zone...
pos = 5; %A cahuffeur can tolerate to be in place <=pos in a queue

%If I'm at place >5 and there are zones where I will get a better position
too_crowded = Q(z, cabID) >= pos && min(max(Q')) <= pos;
too_slow    = T(6, cabID) > 30*60;
%test        = T(6, cabID) > 400;

%New ideas (5/12~12)
if too_crowded && T(6, cabID) > 10*60% || too_slow && Q(z, cabID) >= 3
    
    %disp('XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX')
    %T(6, cabID)
    
    %    if T(6, cabID) > 30*60 %Todo:more than 30 mins
    
    
    %disp('---------------------------------> Lets go to another zone, ok?')
    %combine zone number, distance and population of each zone
    zone = find( Q(:, cabID) > 0);
    population = [1:n_zones^2; max(Q')]';
    
    zonesdists = zones_distances(node_1);
    zonesdata = ([zonesdists, max(Q')']);
    minpop = min(zonesdata(3, :));%bugfix
    
    %Note: We cannot only pick the exact minimum populated zones and the
    %distance, we need to evaluate the better placement by moving into
    %the new zone and use distance as a secondary value.
    
    ids = find(zonesdata(:, 3) <= pos-1);%the new zone must be better
    
    %cands = sortrows(zonesdata(ids, :), 2);
    
    %{
        if isempty(cands)
            %zonesdata = ([zonesdists, max(Q')'])
            warning('No candidate zones found')
            return
        end
    %}
    %we ignore distance
    
    %mindist = cands(1, 2); %min distance element
    %ids = find(zonesdata(:,2) == mindist);
    candidate_zones = zonesdata(ids, 1); %pick out the zones numbers of the candidates
    
    if numel(candidate_zones)==0
        %disp('Found no candidate zones, skipping...')
        return
    end
    
    num_cands = length(candidate_zones);
    new_zone = candidate_zones(ceil(num_cands*rand));
    
    
    [d, pred] = shortest_paths(spAM, node_1);
    path = path_from_pred(pred, Zone2Node(new_zone));
    
    zones = find(diff(ZoneID(path)));
    %      fprintf(1, 'Cab %d leaves zone %d for zone %d\n', cabID, )
    return
    
    %   end
end

%Every other case
%drive within the zone
%disp('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Lets go within the zone shall we')

%find a path to the new zone that does not lend us to get stuck, will we
%ever?
%{
      while  sum(full(spAMtmp(node_2,:))) < 2 %all(full(spAMtmp(node_2, :))==0) %node_2 does not have any neighbours
                disp('*')
                node_2 = corners( ceil(rand*length(corners)) );%pick any target corner
                [d pred] = shortest_paths(spAM, node_1);%we must cross other zones
                
                path = path_from_pred(pred, node_2);
            end
            
            fprintf(1, 'The entrance node %d has %d neighbours.\n', node_2, sum(full(spAMtmp(node_2,:))))
            %To draw the path to the next zone
            coords = Mod2ID(path);
            allcoords = [allcoords, coords];
            set(newplot, 'xdata', coords(2, :), 'ydata', coords(1, :), 'linewidth', 2);
            
            node_1 = node_2; %the new node within the zone
%}



%I hope there are no special cases where we get stuck
path  = path_within_zone(node_1, len);
zones = ZoneID(node_1);

