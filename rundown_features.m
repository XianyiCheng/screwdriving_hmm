function X = rundown_features(force, torque, encoder, current, velocity, screwdrivertip, time, window_size)

if nargin < 8
window_size = 10;
end

sampling_rate = 100; % Hz

kf = [time(end-window_size+1:end), ones([window_size,1])]\force(end-window_size+1:end,3);
zforce_gradient = kf(1);
%{
if numel(force(:,3)) <2*window_size
    zforce_gradient = 0;
else
    zforce_gradient = mean(force(end-window_size+1:end,3)) - mean(force((end-2*window_size+1):(end-window_size),3));
    zforce_gradient = zforce_gradient/(window_size/sampling_rate);
end
%}
kd = [time(end-window_size+1:end), ones([window_size,1])]\screwdrivertip(end-window_size+1:end);
tip_gradient = kd(1);

period = 75;
length_cor =  2*period;
if numel(force(:,1)) < length_cor
    fx = force(:,1) - movmean(force(:,1),period);
    fy = force(:,2) - movmean(force(:,2),period);
else
    fx = force(end - length_cor + 1:end,1) - movmean(force(end - length_cor + 1:end,1),period);
    fy = force(end - length_cor + 1:end,2) - movmean(force(end - length_cor + 1:end,2),period);
end
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

if abs(freq_y - 1.325) < 2
    freq_y = 1.3333;
end
if abs(freq_x - 1.325) < 2
    freq_x = 1.3333;
end

X = [zforce_gradient; tip_gradient; freq_x; freq_y];

end