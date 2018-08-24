
%model: diag(A [X, 1]') = 0  <=> sum(A.*[X,1], 2) = 0

%model_approach = [ones(12,1),zeros(12,1)];
state_approach = state('approach', model_approach, 1,@approach_features, covar_approach);

%model_tightening = [ones(3,1),[-ta_gradient;-current_gradient; -screwheadheight]];
state_tightening = state('tightening', model_tightening,1, @tightening_features, covar_tightening);

%model_crosstightening = [ones(3,1),[-cross_ta_gradient;-cross_current_gradient; -crosstipheight]];
state_crossthreadtightening = state('crossthread_tightening', model_crosstightening, 1,@tightening_features, covar_crosstightening);

model_stop = [1;1];
state_stop = state('stop', model_stop, 1,@stop_features, [0.0001, 0; 0 0.0001]);

%model_holefinding = [1];
state_holefinding = state('hole_finding', model_holefinding,1, @holefinding_features, covar_holefinding);

%model_initialmating{1} = [1, -mating_fz_gradient; 1, -mating_tip_gradient];
%model_initialmating{2} = [1, -mating_fz_drop;1, -sharp_tip_gradient];
state_intialmating = state('initial_mating', model_initialmating,2, @initialmating_features, covar_initalmating);

motor_freq = 1.3245;
%model_rundown = [1, -rundown_fz_gradient; 1, -rundown_tip_gradient; 1, -motor_freq; 1, -motor_freq];
state_rundown = state('rundown', model_rundown,1, @rundown_features, covar_rundown);

%noscrewforce = -2;
%model_noscrew = [1,-1; 1, -noscrewforce];
state_noscrew = state('noscrew', model_noscrew, 1,@noscrewspin_features, covar_noscrew);

states = {state_approach, state_holefinding, state_intialmating, state_rundown, ...
    state_tightening, state_crossthreadtightening, state_noscrew, state_stop};
