function X = noscrewspin_features(force, torque, encoder, current, velocity, screwdrivertip, time, window_size)
    if nargin < 8
    window_size = 10;
    end

 
%screwlength = 4;	
iftipneg = sum(screwdrivertip<0) > 0;
%{
t =     0<screwdrivertip & screwdrivertip<screwlength-1;
fz = mean(force(t,3));
if isnan(fz)
    fz = -100;
end
    %}

period = 75;
sampling_rate = 100;
if numel(force(:,3)) < 2*period
    fz = force(:,3) - movmean(force(:,3),period);
else
    fz = force(end - period*2 + 1:end,3) - movmean(force(end - period*2 + 1:end,3),period);
end
    L = numel(fz);
    f = sampling_rate*(0:(L/2))/L;

    px = abs(fft(fz)/L);
    px = px(1:L/2+1);
    px(2:end-1) = 2*px(2:end-1);
    [~, indx] = max(px);
    freq_z = f(indx);



X = [iftipneg; freq_z];
end