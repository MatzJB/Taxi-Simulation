%Returns the time (in seconds) a customer is willing to wait for a cab.
%This is the same function as the distance.
%The time returned must be at least 1.

function time = bail_time()

%data with times (mins)
%phat = gamfit(data)

%time = 15*60*percentage;

%phat 3.2447    1.2984
%time = 1;
%return
%time = gamrnd(3.244, 1.29, 1, 1); %TODO:the distance is for km, scale for edgedistance edges
%time = gamrnd(2.244, 1.29, 1, 1); %TODO:the distance is for km, scale for edgedistance edges

%Current:
%time = gamrnd(1.8961, 1.7261, 1, 1);
%time = time*60;
time = 1;

if time < 0
    time = 3; %as long as it is >0
    return
else
    return
end
