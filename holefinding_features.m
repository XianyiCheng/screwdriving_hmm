function X = holefinding_features(force, torque, encoder, current, velocity, screwdrivertip, time, window_size)
    if nargin < 8
    window_size = 10;
    end

tipchange = screwdrivertip(end-window_size+1) - screwdrivertip(end);

X = [tipchange];
end