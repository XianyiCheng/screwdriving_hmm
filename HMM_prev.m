classdef HMM_prev  < matlab.mixin.Copyable
    
    properties
        n_state
        %n_observation
        startprob % n_state x 1, the start state probabilities
        transmat % n_state x n_state, the state transition matrix
        states % the cell array which includes state structs
        %observations %  the cell array which includes observations
        %alpha % n_state x n_observation, alpha(i, t) = P(o1...ot^state = i)
        %beta % beta(i, t) = P(ot+1...oT^state = i)
        %viterbi_prob % n_state x n_observation
        %viterbi_path
        max_iter % maximum steps for baum-welch algorithm
        tol
    end
    
    methods 
        
        function obj = HMM()
        end
        
        function alpha_ = forward(obj)
            alpha_ = zeros( obj.n_state, obj.n_observation);
            t = 1;
            for i = 1:obj.num_state
                alpha_(i,t) = obj.states{i}.prob(obj.observations{t})*obj.startprob(i);
            end
            
            for t = 2:obj.n_observation
                for j = 1:obj.num_state
                    prob_j = 0;
                    for i = 1:obj.num_state
                        %alpha_(j,t) = alpha_(j,t) + ...
                        %   obj.transmat(i,j)* obj.states{j}.prob(obj.observations{t})*alpha_(i,t);
                        prob_j = prob_j +  obj.transmat(i,j)*alpha_(i,t);
                    end
                    alpha_(j,t) = prob_j * obj.states{j}.prob(obj.observations{t});
                end
            end
            
            %obj.alpha = alpha_;
        end
        
        function beta_ = backward(obj)
            beta_ = zeros(obj.n_state, obj.n_observation);
            beta_(:,end) = 1;
            
            for mt = 1:n_observations
                t = obj.n_observation - mt;
                for i = 1:obj.n_state
                    for j = 1:obj.n_state
                        beta_(i,t) = beta_(i,t) + obj.transmat(i,j)*obj.states{j}.prob(obj.observations{t})*beta_(j,t+1);
                    end
                end
            end
        end
        
        function [v_prob, path] = viterbi(obj)
            v_prob =  zeros( obj.n_state, obj.n_observation);
            path = cell(obj.n_state, obj.n_observation);
            t = 1;
            for i = 1:obj.n_state
                v_prob(i,t) = obj.states{i}.prob(obj.observations{t})*obj.startprob(i);
                path{i}{t} = i;
            end

            for t = 2:obj.n_observation
                for j = 1:obj.n_state
                    [maxprev_prob, maxprev] = max(v_prob(:,t-1).*obj.transmat(:,j));
                    v_prob(j,t) = maxprev_prob*obj.states{j}.prob(obj.observations{t});
                    path{j}{t} = [path{maxprev}{t-1}, j];
                end
            end

        end

        function [gamma, epsilon] = bw_expectation(obj)
            %expectation
            gamma = obj.alpha./sum(obj.alpha);
            epsilon = zeros(obj.n_observation, obj.n_state, obj.n_state);
            for t = 1:obj.n_observation - 1
                for i = 1:obj.n_state
                    for j = 1:obj.n_state
                        epsilon(t, i, j) = obj.alpha(i,t)*obj.transmat(i,j)*obj.states{j}.prob(obj.observations{t})*obj.beta(j, t+1);
                    end
                end
            end

            %maximization
            %startprob = gamma(:,1);
            %transmat = sum(epsilon,3)./sum(gamma,2);
            end
        end
        
end
    
    
    
    
    
    
    
    
    
    
    
    
    