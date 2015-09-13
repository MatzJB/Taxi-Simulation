%Matz JB
%This code finds a customer (simulating a switchboard)
%First we need to check the current zone, does it do that?

function cab = find_cab(node_from, maxdist, using_GBG_rules)

global n_zones Q T Dists

n_cabs = size(T, 2);

%Better to do the checking here otherwise we get too many if-statements

cab = 0;

if using_GBG_rules
    zonesdists = sort_zones(node_from);
    
    %Pick out the first cabs, at most one from each zone
    zonesdists = permute_zone_candidates(zonesdists); %permute the zones, but keep the distance order
    zonesdists = sortrows(zonesdists, 2); %bug fix 7/12
    %filter out all the cabs that are #1 in queue in every zone
    %pick the cabs in order of distance from the customers' position
    %if several of the zones are at the same distance, choose the zone
    %at random.
    
    candidate_cab = [];
    cabID         = 0;
    
    for j=1:size(zonesdists, 1)
        %Check the zones for cabs in the order presented in 'zonesdists',
        %if the distances are equal we pick at random from each distance.
        zone          = zonesdists(j, 1);
        candidate_cab = find( Q(zone, :) == 1 ); %pick out the number one cab in the zones closest to the customer, and move outward
        
        if numel(candidate_cab) > 0 % cannot be other than 1 or 0 cabs in position 1 in one zone
            cabID    = candidate_cab;
            zone_index = j;
            break;
        end
    end
    
    cab = cabID;
    
    %We can add the cab behavior if the customer is too far away
    %if the distance (in zones) between cab and customer is too much, skip it
    
    %This occurs 90% of the time, totally randomly chosen percentage
    if rand < 0.9 && zonesdists(zone_index, 1) > maxdist
        cab = 0; %not interested
        disp(' ====> customer is too far, bailing.');
    end
    
    
else %our proposed rule (rule 1)
    %pick the cab that is closest
    
    %use binary instead...
    isqueued = any(Q);
    tmp = [1:n_cabs; Dists(node_from, T(1, :))]';
    
    %We pick the closest cab, the possibility that two cabs are at the same
    %distance is small, so we do not permute as above.
    
    candidates = sortrows(tmp, 2);
    
    for i = 1:length(candidates)
        ccab = candidates(i, 1);
        if isqueued(ccab)
            cab = ccab;
            return;
        end
    end
    
    
    %same rule of distance as the GBG rule
    if rand < 0.9 && Dists(node_from, T(1, cab)) > maxdist
        cab = 0; %not interested
        fprintf(1,'Cab %d decided the customer is too far, bailed\n', cab);
    end
    
end
