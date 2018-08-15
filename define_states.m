
%model: diag(A [X, 1]') = 0  <=> sum(A.*[X,1], 2) = 0

model_approach = [ones(13,1),zeros(13,1)];
state_approach = state('approach', model_approach, @approach_features);

model_tightening = [ones(3,1),[-ta_gradient;-current_gradient; -screwheadheight]];
state_tightening = state('tightening', model_tightening, @tightening_features);

model_crosstightening = [ones(3,1),[-cross_ta_gradient;-cross_current_gradient; -crosstipheight]];
state_crossthreadtightening = state('crossthread_tightening', model_tightening, @tightening_features);

model_stop = [1;1];
state_stop = state('stop', model_stop, @stop_features);

model_holefinding = [1];
state_holefinding = state('hole_finding', model_holefinding, @holefinding_features);

model_initialmating{1} = [1, -mating_fz_gradient; 1, -mating_tip_gradient];
model_initialmating{2} = [1, -mating_fz_drop;1, -sharp_tip_gradient];
state_intialmating = state('intial_mating', model_initialmating, @initialmating_features);

model_rundown = [1, -rundown_fz_gradient; 1, -rundown_tip_gradient; 1, -motor_freq; 1, -motor_freq];
state_rundown = state('rundown', model_rundown, @rundown_features);

noscrewforce = -2;
model_noscrew = [1,-1; 1, -noscrewforce];
state_noscrew = state('noscrew', model_noscrew, @noscrewspin_features);