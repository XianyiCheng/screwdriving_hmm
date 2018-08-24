
%%
dataset = Dataset('/Users/xianyi/Dropbox/Screw/new_matlab_tools/test/run_5', 'labels.json')
n = 99*3;
%%
%h=waitbar(0,'loading observations');
parfor i = 1:dataset.total
    rundata = dataset.load(i);
    obs_set1{i+n} = observation(rundata);
    fprintf('%d th sample loaded \n',i);
    %waitbar((i)/dataset.total,h, [num2str(i), ' th sample']);
end
n = n + dataset.total;
%delete(h);
    