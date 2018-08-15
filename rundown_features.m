function X = rundown_features(force, torque, encoder, current, velocity, screwdrivertip, time)

window_size = 10;
sampling_rate = 100; % Hz

kf = [force(end-window_size+1:end,3); ones([window_size,1])]\time(end-window_size+1:end);
zforce_gradient = kf(1);

kd = [screwdrivertip(end-window_size+1:end); ones([window_size,1])]\time(end-window_size+1:end);
tip_gradient = kd(1);

period = 75;
if numel(force(:,1)) < 2*period + 1
    freq_x = 0;
    freq_y = 0;
else
    fx = force(end - period*2:end,1) - movmean(force(end - period*2:end,1),period);
    fy = force(end - period*2:end,2) - movmean(force(end - period*2:end,2),period);

    L = numel(fx);
    f = sampling_rate*(0:(L/2))/L;

    px = abs(fft(fx)/L);
    px = px(1:L/2+1);
    px(2:end-1) = 2*px(2:end-1);
    [~, indx] = max(px);
    freq_x = f(indx);

    py = abs(fft(fy)/L);
    py = py(1:L/2+1);
    py(2:end-1) = 2*py(2:end-1);
    [~, indy] = max(py);
    freq_y = f(indy);
end

X = [zforce_gradient; tip_gradient; freq_x; freq_y];

end