function X = tightening_features(force, torque, encoder, current, velocity, screwdrivertip, time, window_size)
    if nargin < 8
    window_size = 10;
    end
    kt = [encoder(end-window_size+1:end), ones([window_size,1])]\torque(end-window_size+1:end,3);
    torque_angle_gradient = kt(1);
    
    kc = [time(end-window_size+1:end), ones([window_size,1])]\current(end-window_size+1:end);
    current_gradient = kc(1);
    
    screwdrivertip_mean = mean(screwdrivertip(end-window_size+1:end));
    
    %X = [torque_angle_gradient; current_gradient; screwdrivertip_mean]; 
X = [torque_angle_gradient; screwdrivertip_mean]; 
end