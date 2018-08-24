function X = stop_features(force, torque, encoder, current, velocity, screwdrivertip, time, window_size)
    if nargin < 8
    window_size = 10;
    end    
X = [mean(current(end - window_size + 1:end)); mean(velocity(end - window_size + 1:end))];
end