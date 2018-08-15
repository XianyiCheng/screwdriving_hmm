function X = stop_features(force, torque, encoder, current, velocity, screwdrivertip, time)
window_size = 10;    
X = [mean(current(end - window_size + 1:end)); mean(velocity(end - window_size + 1:end))];
end