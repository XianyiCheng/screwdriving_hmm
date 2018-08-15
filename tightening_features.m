function X = tightening_features(force, torque, encoder, current, velocity, screwdrivertip, time)
    window_size = 10;
    kt = [encoder(end-window_size+1:end); ones([window_size,1])]\torque(end-window_size+1:end);
    torque_angle_gradient = kt(1);
    
    kc = [current(end-window_size+1:end); ones([window_size,1])]\time(end-window_size+1:end);
    current_gradient = kc(1);
    
    screwdrivertip_mean = mean(screwdrivertip(end-window_size+1:end));
    
    X = [torque_angle_gradient; current_gradient; screwdrivertip_mean]; 

end