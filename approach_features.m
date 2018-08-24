function X = approach_features(force, torque, encoder, current, velocity, screwdrivertip, time, window_size)
    % signals: timesteps x N 
    
    
if nargin < 8
    window_size = 10;
end

X = [mean(force(end - window_size + 1:end, :))'; var(force(end - window_size + 1:end, :))'];
end