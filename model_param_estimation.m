function [model, covar] = model_param_estimation(s, state_observations, freq, sample_rate)
% s: state    
% only for sum(A.*[X,1], 2) = 0
    if nargin < 3
        sample_rate = 10;
        freq = 100;
    end
    sample_n = freq/sample_rate;
    
    if s.n_model > 1
        %
        X = cell(s.n_model,1);
        model = cell(s.n_model,1);
        covar = cell(s.n_model,1); 
        for k = 1:numel(state_observations)
            state_observation= state_observations{k};
            if isempty( state_observation)
                continue;
            end
            T = numel(state_observation.time)/sample_n;
            for t = 1:T
                features = s.get_features(state_observation.sample(t));
                for i = 1:s.n_model
                    X{i} = [X{i};features{i}'];
                end
            end
        end
        for i = 1:s.n_model
            for k = 1:size(X{i},2)
                A = [X{i}(:,k), ones(size(X{i}(:,k)))];
                %[~,~,V] = svd(A);
                %x = V(:,end)';
                %x = x/x(1);
                x = [1, -mean(X{i}(:,k))];
                err = A*x';
                variance = var(err);
                %x = x/variance;
                model{i} = [model{i};x];
                covar{i} = [covar{i};variance];
                
            end
        end
        
    else
        X = [];
        for k = 1:numel(state_observations)
            state_observation= state_observations{k};
            if isempty( state_observation)
                continue;
            end
            T = numel(state_observation.time)/sample_n;
            for t = 1:T
                features = s.get_features(state_observation.sample(t));
                for i = 1:s.n_model
                    X = [X;features'];
                end
            end
        end
        model = [];
        covar= [];
        for k = 1:size(X,2)
            A = [X(:,k), ones(size(X(:,k)))];
            %[~,~,V] = svd(A);
            %x = V(:,end)';
            %x = x/x(1);
            x = [1, -mean(X(:,k))];
            err = A*x';
            variance = var(err);
            covar = [covar; variance];
            %x = x/variance;
            model = [model;x];
        end
    end
end