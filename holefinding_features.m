function X = holefinding_features(force, torque, encoder, current, velocity, screwdrivertip, time)
window_size = 10 % 0.1s
tipchange = max(screwdrivertip(end-window_size+1:end)) - min(screwdrivertip(end-window_size+1:end));

X = [tipchange];
end