%Permutes the equal elements of the first column of the 'zone candidates
%matrix. The matrix is assumed to be sorted w.r.t the first column.
%We have to permute all the zones because we do not know which one has a
%cab in them.

function A = permute_zone_candidates(A)

A(end+1, :) = [-1, -1];%add an extra element to catch with our subsequence finder. The elements are unique (distance must be >0)

sub_start = 1;
sub_end   = 1;
sublength = 1;

for i=1:length(A)-1
    
    if A(i, 1) == A(i+1, 1)
        
        if sublength == 1
            sub_start = i;
        end
        
        sublength = sublength+1;
    end
    
    if A(i, 1) ~= A(i+1, 1) && sublength > 1
        sub_end   = i;
        %permute the rows from sub_start to sub_end
        A(sub_start:sub_end, :) = randperm(A(sub_start:sub_end, :));
        sublength = 1;%next sequence
        
        fprintf(1, 'Found a sequence from %i to %i\n', sub_start, sub_end);
    end
end

A = A(1:end-1, :);


%rearranges a matrix' rows according to pos
function A = randperm(A)

for i = 1:2*length(A) %switch a couple of elements randomly
    i           = mod(i, length(A)) + 1;
    tmp         = A(1, :);
    index       = floor(length(A)*rand) + 1; %we switch with a random element, except for the first
    A(1, :)     = A(index, :);
    A(index, :) = tmp;
end

