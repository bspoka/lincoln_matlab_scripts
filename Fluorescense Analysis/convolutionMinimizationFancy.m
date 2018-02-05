function resfull = convolutionMinimizationFancy_3(nonlinear_parameters, irf, ...
    decay_experimental, model_name, time_axis)

global linear_parameters

weights = 1./sqrt(decay_experimental);

ampl = nonlinear_parameters(end);

% Make m x 3 matrix containing each exponential decay component
sim = zeros(numel(decay_experimental),3);
for ind = 1:3
        sim(:,ind) = I0*(fftfilt(irf,exp(-time_axis/nonlinear_parameters(ind))));
end

% Do the linear regression using lsqlin
Aeq = [1 1 1]; % Equality constraints: a1 + a2 + a3 = 1 (Aeq*LP = beq)
beq = 1;       % Equality constraints: a1 + a2 + a3 = 1

options = optimset('lsqlin');
options = optimset(options,'LargeScale','off','Display','off');

Lpars = lsqlin((sim.*repmat(weights',1,3)),(decay_experimental_global.*weights),[],[],Aeq,beq,...
    [0,0,0],[1, 1, 1],[0.1,0.1,0.1],options); % Optimize linear parameters

fit = sim*Lpars;
resfull = (fit' - decay_experimental_global).*weights;

end

sim = zeros(length(decay),3);
for i = 2:2:6
    if get(handles.IncludeScatterCheckbox,'Value') == 0
        sim(:,i/2) = I0*fftfilt(IRF,exp(-t/p(i)));
    else
        a = p(end-1);
        sim(:,i/2) = I0*( (1-a)*fftfilt(IRF,exp(-t/p(i))) + a*IRF );
    end
end

% Do the linear regression using lsqlin
Aeq = [1 1 1]; % Equality constraints: a1 + a2 + a3 = 1 (Aeq*LP = beq)
beq = 1;       % Equality constraints: a1 + a2 + a3 = 1
lowerLP = getappdata(0,'lowerLP');
upperLP = getappdata(0,'upperLP');
startLP = getappdata(0,'startLP');

options = optimset('lsqlin');
options = optimset(options,'LargeScale','off','Display','off');

Lpars = lsqlin(sim.*repmat(weights,1,3),decay.*weights,[],[],Aeq,beq,lowerLP,upperLP,startLP,options); % Optimize linear parameters


