classdef observation < matlab.mixin.Copyable
    properties
        time
        force
        torque
        encoder
        current
        velocity
        screwdrivertip
    end
    
    methods
        function obj = observation(rundata, freq)
            
            if nargin < 2
                freq = 100;
            end
            obj.freq = freq;
            obj.time = 0:1/freq:rundata.duration;
            force_padded = [rundata.wrench.force(1,:);rundata.wrench.force;rundata.wrench.force(end,:)];
            torque_padded = [rundata.wrench.torque(1,:);rundata.wrench.torque;rundata.wrench.torque(end,:)];
            obj.force = interp1([0;rundata.wrench.time;rundata.duration], force_padded, obj.time);
            obj.torque = interp1([0;rundata.wrench.time;rundata.duration], torque_padded, obj.time);
            
            tip = rundata.screwdrivertip();
            obj.screwdrivertip = interp1([0,tip.time], [tip.z(1);tip.z], obj.time);
            obj.screwdrivertip(isnan(obj.screwdrivertip)) = max(tip.z(end));
            
            screwdriver = interp1([0,rundata.screwdriver.time], [[0,0,0];rundata.screwdriver.position, ...
                rundata.screwdriver.current, rundata.screwdriver.velocity], obj.time);
            obj.encoder = screwdriver(:,1);
            obj.encoder(isnan(obj.encoder)) = rundata.screwdriver.position(end);
            obj.encoder = obj.encoder/(2048*4);  
            obj.current = screwdriver(:,2);
            obj.current(isnan(obj.current)) = 0;
            obj.velocity = screwdriver(:,3);
            obj.velocity(isnan(obj.velocity)) = 0;
            
        end
        
        function observation_i = sample(obj, timestep, sample_rate)
            % get first n (n = timestep) samples for observation
            % sample rate: frequency for each sample, 10 Hz as default
            if nargin < 3
                sample_rate = 10;
            end
            
            n = obj.freq/sample_rate;
            observation_i = obj;
        
            observation_i.time(timestep*n+1:end) = [];
            observation_i.force(timestep*n+1:end) = [];
            observation_i.torque(timestep*n+1:end) = [];
            observation_i.encoder(timestep*n+1:end) = [];
            observation_i.current(timestep*n+1:end) = [];
            observation_i.velocity(timestep*n+1:end) = [];
            observation_i.screwdrivertip(timestep*n+1:end) = [];
     
        end
        
    end
    
end