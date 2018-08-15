function X = initialmating_features(force, torque, encoder, current, velocity, screwdrivertip, time)
window_size = 10;

kf = [force(end-window_size+1:end,3); ones([window_size,1])]\time(end-window_size+1:end);
zforce_gradient = kf(1);

kd = [screwdrivertip(end-window_size+1:end); ones([window_size,1])]\time(end-window_size+1:end);
tip_gradient = kd(1);

zforce_change = max(force(end-window_size+1:end,3)) - min(force(end-window_size+1:end,3));

X{1} = [zforce_gradient; tip_gradient];
X{2} = [zforce_change; tip_gradient];

end