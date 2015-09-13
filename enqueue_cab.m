
function q = enqueue_cab(cab, q)  
global T

z        = ZoneID(T(1, cab));
q(z, cab) = max( q(z, :) ) + 1;%bug fix 29/11