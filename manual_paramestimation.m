%%
dataset = Dataset('/home/xianyi/Dropbox/Screw/new_matlab_tools/test/run_3', 'labels.json')

%%
rundata = dataset.load(53);
o = observation(rundata);

i =14;
labeled_o{i}.data = o;
o.plot()
%%
close all;
labeled_o{i}.approach_t = [1,11];
%labeled_o{i}.intialmating_t = [12 15];
labeled_o{i}.holefinding_t = [12 20];
labeled_o{i}.intialmating_t_2 = [21 21];
labeled_o{i}.rundown_t = [22 30];
%labeled_o{i}.tighting_t = [116 117];
labeled_o{i}.crosstighting_t = [31 37];

obs.approach{i} = o.crop(labeled_o{i}.approach_t);
%obs.intialmating{i} = o.crop(labeled_o{i}.intialmating_t);
obs.holefinding{i} = o.crop(labeled_o{i}.holefinding_t);
obs.intialmating_2{i} = o.crop(labeled_o{i}.intialmating_t_2);
obs.rundown{i} =  o.crop(labeled_o{i}.rundown_t);
%obs.tightening{i} = o.crop(labeled_o{i}.tighting_t);
obs.crosstightening{i} = o.crop(labeled_o{i}.crosstighting_t);
obs
%%
[model_approach, covar_approach] = model_param_estimation(state_approach,obs.approach);
[model_intialmating,  covar_intialmating] = model_param_estimation(state_intialmating,obs.intialmating);
[model_intialmating_2, covar_intialmating_2] = model_param_estimation(state_intialmating,obs.intialmating_2);
[model_rundown, covar_rundown] = model_param_estimation(state_rundown, obs.rundown);
[model_tightening, covar_tightening] = model_param_estimation(state_tightening, obs.tightening);
[model_crosstighting,covar_crosstightening] = model_param_estimation(state_crossthreadtightening, obs.crosstightening);
[model_noscrew, covar_noscrew] = model_param_estimation(state_noscrew,obs.noscrew);
[model_holefinding, covar_holefinding] = model_param_estimation(state_holefinding,obs.holefinding);