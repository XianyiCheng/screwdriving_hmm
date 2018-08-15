function X = approach_features(force, torque, encoder, current, velocity, screwdrivertip, time)
    % signals: timesteps x N 
    X = [mean(force)'; mean(torque)'; var(force)'; var(torque)'];
end