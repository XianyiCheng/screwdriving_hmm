classdef HMM < matlab.mixin.Copyable
    properties
        n_state
        states
        ppi % startprob
        a % state transition matrix
        %current observation prob
 
    end
    
    methods
        
        function obj = HMM(states, startprob, transmat)
            obj.states = states;
            obj.n_state = numel(states);
            obj.ppi = startprob;
            obj.a = transmat;
        end
        
        function [b, model_err] = compute_observation_prob(obj, observations, window_size, stride)
            N = obj.n_state;
            T = ceil((observations.time(end) * observations.freq - window_size)/stride);
            b = zeros(N,T);
            model_err = cell(N,1);
            for t = 1:T
                for i = 1:N
                    [b(i,t), err] = obj.states{i}.prob(observations.training_sample(t, window_size, stride), window_size);
                    if obj.states{i}.n_model > 1
                        if t == 1
                            model_err{i} = cell(obj.states{i}.n_model,1);
                        end
                        for k = 1:obj.states{i}.n_model
                            model_err{i}{k} = [model_err{i}{k}, err{k}];
                        end
                    else
                        model_err{i} = [model_err{i}, err];
                    end
                end
            end
        end
        
        function [logalpha, logbeta] = log_forwardbackward(obj, b)
            % b: the observation probability num_states x num_timesteps
            T = size(b,2);
            N = obj.n_state;
            
            logalpha = zeros(N,T);
            logalpha(:,1) = log(obj.ppi) + log(b(:,1));
            for t = 2:T
                %logalpha(:,t) = log(b(:,t)) + log(sum(exp(log(obj.a) + logalpha(:,t-1)),1))';
                logalpha(:,t) = log(b(:,t)) + logsumexp(log(obj.a) + logalpha(:,t-1),1)';
            end
            
            logbeta = zeros(N,T);
            logbeta(:,T) = 1;
            for mt = 1:T-1
                t = T-mt;
                logbeta(:,t) = logsumexp(log(obj.a) + log(b(:,t+1)') + logbeta(:,t+1)',2);
            end
        end
        
        function [logviterbip, viterbi_path] = log_viterbi(obj, b)
            T = size(b,2);
            N = obj.n_state;
            logviterbip = zeros(N,T);
            logviterbip(:,1) = log(obj.ppi) + log(b(:,1));
            viterbi_path = num2cell([1:N]'); 
            
            for t = 2:T
                [logviterbip(:,t),max_ind] = max(logviterbip(:,t-1) + log(obj.a) + log(b(:,t)'),[],1);
                for c = 1:N
                    viterbi_path{c,t} = [viterbi_path{max_ind(c),t-1}, c];
                end
            end
                
        end
        
        function [loggamma1,logsumepsilon, loggamma] = log_expectation(obj, b, logalpha, logbeta)
            N = obj.n_state;
            T = size(b,2);
            logepsilon = reshape(logalpha,[N,1,T]) + reshape(log(obj.a),[N,N,1]) + reshape(log(b),[1,N,T]) + reshape(logbeta,[1,N,T]);
            logepsilon = logepsilon - logsumexp(logsumexp(reshape(logalpha,[N,1,T]) + reshape(log(obj.a),[N,N,1]) + reshape(log(b),[1,N,T]) + reshape(logbeta,[1,N,T]),1),2);
            logepsilon(isnan(logepsilon)) = -Inf;
            loggamma = squeeze(logsumexp(logepsilon,2));
            loggamma1 = loggamma(:,1);
            %logsumgamma = logsumexp(loggamma,2);
            logsumepsilon = logsumexp(logepsilon,3);   
        end
        
        function maximization(obj, loggamma1s, loggammas, logsumepsilons, model_errs)
            % logsumepsilons size(logsumepsilon) x n_samples
            % loggamma1s n_state x n_samples
            % loggammas n_state x all_timesteps
            % model_errs  n_state cell of all time
            n_samples = size(loggamma1s,2);
            %loggammas = squeeze(logsumexp(logepsilons,2));
            %obj.ppi = exp(logsumexp(loggamma1s,2))/n_samples;
            loga = logsumexp(logsumepsilons,3) - logsumexp(logsumexp(logsumepsilons,3),2);
            loga(isnan(loga)) = -Inf;
            %obj.a = exp(loga);
            for i = 1:obj.n_state
                
                if i == 2 %|| i == 8 %|| i == 7 || i ==5 || i ==6
                    continue;
                end
                
                gammas_i = exp(loggammas(i,:));
                model_err_i = model_errs{i};
                if obj.states{i}.n_model > 1
                    %
                    p = obj.states{i}.prob_m(model_err_i); %p : n_timestep x n_model
                    p = p./sum(p,2);
                    p(isnan(p)) = 0;
                    for k = 1:obj.states{i}.n_model
                        loggammas_ik = loggammas(i,:)  + log(p(:,k)');
                        gammas_ik = exp(loggammas_ik);
                        sum_gammas_ik = exp(logsumexp(loggammas_ik));
                        mu = sum(model_err_i{k} .* gammas_ik, 2)./sum_gammas_ik ;
                        d = sqrt(gammas_ik).*(model_err_i{k} - mu);
                        sigma = (d*d')./sum_gammas_ik ;
                        sigma(isnan(sigma)) = 0;
                        obj.states{i}.prob_param.mean{k} = mu;
                        obj.states{i}.prob_param.covar{k} = (diag(diag(sigma)) + obj.states{i}.prob_param.covar{k})/2 ;
                        c = logsumexp(loggammas_ik) - logsumexp(loggammas(i,:));
                        c(isnan(c)) = -Inf;
                        obj.states{i}.prob_param.c{k} = exp(c);
                    end
                        
                else
                    sum_gammas_i = exp(logsumexp( loggammas(i,:)));
                    mu = sum(model_err_i .* gammas_i, 2)./sum_gammas_i;
                    mu(isnan(mu))=0;
                    d = sqrt(gammas_i).*(model_err_i - mu);
                    sigma = (d*d')./sum_gammas_i;
                    sigma(isnan(sigma)) = 1e-4;
                    sigma(sigma<1e-4) = 1e-4;
                    
                    obj.states{i}.prob_param.mean = mu;
                    obj.states{i}.prob_param.covar = diag(diag(sigma));% + obj.states{i}.prob_param.covar)/2;

                    %cur_state = obj.states{i};
                    %cur_state.updateparam(loggammas,model_errs{i});
                end
            end
            
        end
        
        function train(obj,observations, max_iter, tol)
            deltaP = Inf;
            n = 1;
            n_sample = numel(observations); % n_sample cell
            logPO_pre = log(0);
            while n < max_iter && deltaP > tol
                fprintf('iter %d : ', n);
                logPO = 0;
                loggamma1s = zeros(obj.n_state, n_sample);
                loggammas = [];
                logsumepsilons = zeros(obj.n_state, obj.n_state, n_sample);
                model_errs = cell(obj.n_state, 1);
                for k = 1:n_sample
                    o = observations{k};
                    [b, model_err] = obj.compute_observation_prob(o, 3, 3);
                    [logalpha, logbeta] = obj.log_forwardbackward(b);
                    [loggamma1s(:,k) ,logsumepsilons(:,:,k), loggamma] = obj.log_expectation(b, logalpha, logbeta);
                    loggammas = [loggammas, loggamma];
                    for i = 1:obj.n_state
                        if obj.states{i}.n_model > 1
                           if k == 1
                               model_errs{i} = cell(obj.states{i}.n_model,1);
                           end
                           for j = 1:obj.states{i}.n_model
                               model_errs{i}{j} = [model_errs{i}{j}, model_err{i}{j}];
                           end
                        else
                            model_errs{i} = [model_errs{i}, model_err{i}];
                        end
                    end
                    logPO = logPO + logsumexp(logalpha(:,end));
                end
                obj.maximization(loggamma1s, loggammas, logsumepsilons, model_errs);
                deltaP = logPO - logPO_pre;
                logPO_pre = logPO;
                fprintf('log observation prob: %f, change: %f \n',[logPO, deltaP]);
                n = n+1;
                
            end
        end
        
        function path = getpath(obj, o)
                [b, ~] = obj.compute_observation_prob(o,10,10);
                [viterbip,viterbipath] = obj.log_viterbi(b);
                [~,ind] = max(viterbip(:,end));
                path = viterbipath{ind,end}';
        end
           
        
        
    end
end