function resfull = convolutionMinimizationFancy(model_parameters)

global irf_global
global decay_experimental_global
global time_axis_global

weights = 1./sqrt(decay_experimental_global);
p  = model_parameters;

I0 = 1;

% Make m x 3 matrix containing each exponential decay component
sim = zeros(numel(decay_experimental_global),3);
for i = 1:3
        a = 0.5;
        sim(:,i) = I0*( (1-a)...
            .*fftfilt(irf_global,exp(-time_axis_global/p(i))) + a.*irf_global );
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

