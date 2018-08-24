classdef observation < matlab.mixin.Copyable
    properties
        time
        force
        torque
        encoder
        current
        velocity
        screwdrivertip
        freq
        position_error
        angular_error
    end
    
    methods
        function obj = observation(rundata, freq)
            
            if nargin < 2
                obj.freq = 100;
            else
                obj.freq = freq;
            end
            
            obj.position_error = rundata.position_error;
            obj.angular_error = rundata.angular_error;
            
            obj.time = [0:(1/obj.freq):rundata.duration]';
            
           [wrench_uniq_time, wrench_uniq_index] = unique(rundata.wrench.time);

            force_padded = [rundata.wrench.force(1,:);rundata.wrench.force(wrench_uniq_index,:);rundata.wrench.force(end,:)];
            torque_padded = [rundata.wrench.torque_trans(1,:);rundata.wrench.torque_trans(wrench_uniq_index,:);rundata.wrench.torque_trans(end,:)];
            obj.force = interp1([0;wrench_uniq_time;rundata.duration], force_padded, obj.time);
            obj.torque = interp1([0;wrench_uniq_time;rundata.duration], torque_padded, obj.time);
            obj.force(:,3) = -obj.force(:,3);
            obj.torque(:,3) = -obj.torque(:,3);
            
            tip = rundata.screwdrivertip();
            [tip_uniq_time, tip_uniq_index] = unique(tip.time);
            obj.screwdrivertip = interp1([0;tip_uniq_time], [tip.z(1);tip.z(tip_uniq_index)], obj.time);
            obj.screwdrivertip(isnan(obj.screwdrivertip)) = max(tip.z(end));
            
            [s_uniq_time, s_uniq_index] = unique(rundata.screwdriver.time);
            screwdriver = interp1([0;s_uniq_time], [[0,0,0];rundata.screwdriver.position(s_uniq_index), ...
                rundata.screwdriver.current(s_uniq_index), rundata.screwdriver.velocity(s_uniq_index)], obj.time);
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
            observation_i = copy(obj);
        
            observation_i.time(timestep*n+1:end) = [];
            observation_i.force(timestep*n+1:end,:) = [];
            observation_i.torque(timestep*n+1:end,:) = [];
            observation_i.encoder(timestep*n+1:end) = [];
            observation_i.current(timestep*n+1:end) = [];
            observation_i.velocity(timestep*n+1:end) = [];
            observation_i.screwdrivertip(timestep*n+1:end) = [];
        end
        
        function observation_i = training_sample(obj, timestep, window_size, stride)

            observation_i = copy(obj);
            end_step = stride*(timestep-1) + window_size + 1;
        
            observation_i.time(end_step:end) = [];
            observation_i.force(end_step:end,:) = [];
            observation_i.torque(end_step:end,:) = [];
            observation_i.encoder(end_step:end) = [];
            observation_i.current(end_step:end) = [];
            observation_i.velocity(end_step:end) = [];
            observation_i.screwdrivertip(end_step:end) = [];
        end
        
        function plot(obj)
            line_width = 1.5;
            
            figure('units','normalized','outerposition',[0 0 1 1])

            subplot(2,3,2);
            plot(obj.time, obj.current, 'LineWidth', line_width);
            %hold on
            %plot(obj.wrench.time, obj.wrench.torque(3,:), 'LineWidth', BagData.line_width);
           
            xlabel('Time (s)');
            ylabel('Current (A)');
            
            subplot(2,3,3);
            plot(obj.time, obj.velocity, 'LineWidth', line_width);
           
            xlabel('Time (s)');
            ylabel('Velocity (rpm)');
            
            tip = obj.screwdrivertip;
           subplot(2,3,1);
            plot(obj.time, obj.screwdrivertip, 'LineWidth', line_width);
            
            ylim([min(obj.screwdrivertip)-20, max(obj.screwdrivertip)+ 20]);
            xlabel('Time (s)');
            ylabel('screwdriver tip distance');
            
            subplot(2,3,4);
            p1 = plot(obj.time, obj.torque, 'LineWidth', line_width);
            
            xlabel('Time (s)');
            ylabel('Torque(Nm)');
            legend(p1,{'X','Y','Z'});
            
            subplot(2,3,5);
            p2 = plot(obj.time, obj.force, 'LineWidth', line_width);
            
            xlabel('Time (s)');
            ylabel('Force (N)');
            %legend(p2, {'X','Y','Z'});
            
            subplot(2,3,6);
            plot(obj.time, obj.encoder, 'LineWidth', line_width);
            xlabel('Time (s)');
            ylabel('motor encoder');

        end
        
        function plotlabel(obj, labels, window)
            if nargin < 3
                window = 10;
            end
            classes = {'approach'; 'hole finding';'initial mating';'rundown';...
    'tightening';'crosstightening'; 'no screw spinning';'stop'};
            colors = {'black'; 'yellow'; 'red'; 'green'; 'magenta'; 'cyan'; 'blue'; [1 0.5 0]; [1 0.4 0.6];'blue';'yellow'};
            obj.plot();
            hold on;
            subplot(2,3,5);
            yl = ylim;
            label_type = unique(labels);
            for i = 1:numel(label_type)
                all = find(labels == label_type(i));
                xmin = (min(all) - 1)*window/obj.freq;
                xmax = max(all)*window/obj.freq;
                x = [xmin,xmax,xmax,xmin];
                y = [yl(1), yl(1), yl(2), yl(2)];
                patch('Faces',[1 2 3 4],'Vertices',[x',y'],'FaceColor',colors{i},'EdgeColor','none','FaceAlpha',.2);
                text((xmin + xmax)/2, (yl(1) + yl(2))*0.1, classes{label_type(i)}, 'Rotation', 90,'FontSize',14);
                hold on;
                
            end
            hold off;
            
        end
        
        function observation_i = crop(obj, timesteps, sample_rate)
             % get crop samples for observation
            % sample rate: frequency for each sample, 10 Hz as default
            if nargin < 3
                sample_rate = 10;
            end
            
            timestep_start = timesteps(1);
            timestep_end = timesteps(2);
            
            n = obj.freq/sample_rate;
            observation_i = copy(obj);
            
            del_element = [1:((timestep_start-1)*n),(timestep_end*n+1):numel(obj.time)]; 
            
            observation_i.time(del_element) = [];
            observation_i.force(del_element,:) = [];
            observation_i.torque(del_element,:) = [];
            observation_i.encoder(del_element) = [];
            observation_i.current(del_element) = [];
            observation_i.velocity(del_element) = [];
            observation_i.screwdrivertip(del_element) = [];
        end
        
    end
    
end