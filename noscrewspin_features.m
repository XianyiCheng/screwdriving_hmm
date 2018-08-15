function X = noscrewspin_features(force, torque, encoder, current, velocity, screwdrivertip, time)
screwlength = 4;	
iftipneg = sum(screwdrivertip<0) > 0;
t =     time(0<screwdrivertip & screwdrivertip<screwlength-1);
fz = mean(force(t,3));
X = [iftipneg; fz];
end