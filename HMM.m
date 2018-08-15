classdef HMM < matlab.mixin.Copyable
    properties
        n_state
        states
        ppi % startprob
        a % state transition matrix
        %current observation prob
 
    end
    
    methods
        function observation_prob = compute_observation_prob(obj, observations, n_observation)
            N = obj.n_state;
            T = n_observation;
            b = zeros(N,T);
            for t = 1:T
                for i = 1:N
                    b(i,t) = obj.states{i}.prob(observations.sample(t));
                end
            end
            observation_prob = b;
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
                logbeta(:,t) = logsumexp(log(obj.a) + log(b(:,t+1)) + logbeta(:,t+1),2);
            end
        end
        
        function [logviterbip, viterbi_path] = log_viterbi(obj, b)
            T = size(b,2);
            N = obj.n_state;
            logviterbip = zeros(N,T);
            logviterbip(:,1) = log(obj.ppi) + log(b(:,1));
            viterbi_path = num2cell([1:N]'); 
            
            for t = 2:T
                [logviterbip(:,t),max_ind] = max(logviterbip(:,t-1) + log(obj.a) + log(b(:,t+1)),[],2);
                for c = 1:N
                    viterbi_path{c,t} = [viterbi_path{max_ind(c),t-1}, c];
                end
            end
                
        end
        
        function [loggamma, logepsilon] = log_expectation(obj, b, logalpha, logbeta)
            N = obj.n_state;
            T = size(b,2);
            loggamma = logalpha + logbeta - logsumexp(logalpha + logbeta, 1);
            logepsilon = reshape(logalpha,[N,1,T]) + reshape(log.a,[N,N,1]) + reshape(log(b),[1,N,T]) + reshape(logbeta,[N,1,T]);
            logepsilon = logepsilon./logsumexp(logsumexp(reshape(logalpha,[N,1,T]) + reshape(log.a,[N,N,1]) + reshape(log(b),[1,N,T]) + reshape(logbeta,[N,1,T]),1),2);
        end
        
        function maximization(obj, loggammas, logepsilons, observations, n_samples)
            % loggammas n_samples x size(loggamma)
            obj.ppi = reshape(squeeze(sum(exp(loggammas(:,:,1),1))/n_samples),[N,1]);
            obj.a = squeeze(exp(logsumexp(logsumexp(logepsilons,1),4) - logsum(logsumexp(loggammas,1),3)));
            for i = 1:obj.n_state
                cur_state = obj.states{i};
                cur_state.updateparam(loggammas,observations);
            end
            
        end
        
        
    end
end