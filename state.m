classdef state  < matlab.mixin.Copyable
    properties
        name
        model % AX = 0
        n_model % if n_model = 1, gaussian; n_model > 1, gmm
        feature_extraction % a function handle which extract features
        prob_param
        
    end
    
    methods
        
        function obj = state(name,model,n_model,feature_extraction, covar)
            obj.name = name;
            obj.n_model = n_model;
            obj.model = model;
            obj.feature_extraction = feature_extraction;
            if obj.n_model > 1
                % gmm
                for i =1:obj.n_model
                    obj.prob_param.c{i} = 1/obj.n_model;
                    obj.prob_param.mean{i} = zeros(size(model{i},1),1);
                    obj.prob_param.covar{i} = covar; %eye(size(model{i},1));
                end
            else
                obj.prob_param.mean = zeros(size(model,1),1);
                obj.prob_param.covar = covar; %eye(size(model,1));
            end
        end
        
        function X = get_features(obj, o)
            X = obj.feature_extraction(o.force, o.torque, o.encoder, o.current, o.velocity, o.screwdrivertip, o.time);
        end
        
        function error = model_residual(obj, observation, window_size)
            o = observation;
            X = obj.feature_extraction(o.force, o.torque, o.encoder, o.current, o.velocity, o.screwdrivertip, o.time, window_size);
            if obj.n_model > 1
                error = cell(obj.n_model,1);
                for i = 1:obj.n_model
                    error{i} = sum(obj.model{i}.*[X{i},ones(size(X{i}))], 2);
                end
            else
                error = sum(obj.model.*[X,ones(size(X))], 2);
            end
        end
        
        function [p, err] = prob(obj, observation, window_size)
             err = obj.model_residual(observation, window_size);
             p = sum(obj.prob_m(err));
        end
        
        function p = prob_m(obj, err)
             if obj.n_model > 1
                %gmm
                %p=zeros(obj.n_model,1);
                for i = 1:obj.n_model
                    p(:,i) =  obj.prob_param.c{i}*mvnpdf(err{i}',obj.prob_param.mean{i}',obj.prob_param.covar{i});
                end
            else
                %gaussian
                p = mvnpdf(err',obj.prob_param.mean',obj.prob_param.covar); 
             end
        end
        
        function updateparam(obj, loggammas, observations) 
            % loggammas n_sample cell: n_state x n_timesteps
            % observations n_sample cell
            T = numel(loggammas); % num of timesteps
            gammas = exp(loggammas);
            sum_gammas = sum(gammas);
            
            if obj.n_model > 1
                %gmm
                x = cell(obj.n_model,1);
                prob = zeros(obj.n_model,T);
                for t = 1:T
                    err = obj.model_residual(observations.sample(t));
                    prob(:,t) = obj.prob_m(err);
                    for i = 1:obj.n_model
                        x{i} = [x{i}, err{i}];
                    end
                end
                
                n_gammas = gammas*(prob./sum(prob,2)); % n_model x T
                
                for i = 1:obj.n_model
                    gammas_i = n_gammas(i,:);
                    obj.prob_param.mean{i} = sum(gammas_i.*x{i}, 2)/sum(gammas_i);
                    u = sqrt(gammas_i).*(x - obj.prob_param.mean{i});
                    obj.prob_param.covar{i} =  u*u'/sum(gammas_i);
                    obj.prob_param.c{i} = sum(gammas_i)/sum_gammas;
                end
                
            else
                %gaussian
                x1 = obj.model_residual(observations{1});
                x = zeros(size(x1,1),T);
                x(:,1) = x1;
                for t = 2:T
                    x = obj.model_residual(observations{t});
                end
                obj.prob_param.mean = sum(gammas.*x, 2)/sum_gammas;
                u = sqrt(gammas).*(x - obj.prob_param.mean);
                obj.prob_param.covar =  u*u'/sum_gammas;
            end            
        end
        
    end
    
end