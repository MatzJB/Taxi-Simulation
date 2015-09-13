%Matz JB
%23/11 ~12
%Generic function to dequeue any cab from Q
%Removed the need for dequeue_at

function q = dequeue_cab(cab, q)

z              = find( q(:, cab) > 0 ); %only one value

if numel(z) > 1
    error('At least one column in Q contains more than one value.')
end

cab_placement  = q(z, cab); %bugfix 25/11 01:29

if numel(cab_placement)==0
    
   error('Queue is in error.') 
end

q(z, :)        = q(z, :) - (q(z, :) > cab_placement);
q(z, cab)      = 0;

