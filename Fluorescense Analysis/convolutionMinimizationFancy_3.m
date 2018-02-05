function [residual, fit_func]  = convolutionMinimizationFancy_3(nonlinear_parameters, irf, ...
    decay_experimental, model_name, time_axis, scatter, irf_shift)

global linear_parameters
global irf_fwhm_ns

if irf_shift && scatter
    irf_shift_ns = nonlinear_parameters(end);
    ampl = nonlinear_parameters(end-2);
    scat = nonlinear_parameters(end-1);
elseif irf_shift && ~scatter
    irf_shift_ns = nonlinear_parameters(end);
    ampl = nonlinear_parameters(end-2);
    scat = 0;
else
    ampl = nonlinear_parameters(end-2);
    irf_shift_ns = nonlinear_parameters(end);
    scat = 0;
end
    

gaussfnc = @(time, amp, sigma, tau) amp.*exp(-(time-tau).^2./(2*sigma).^2);
irf = gaussfnc(time_axis, decay_experimental, irf_fwhm_ns, irf_shift_ns); %generate irf


% Make m x 3 matrix containing each exponential decay component (linear system of equations)
switch model_name
    case decayModels.tripleExponential
        n_param = 3;
    case decayModels.doubleExponential
        n_param = 2;
    case decayModels.singleExponential
        n_param = 1;
    otherwise
        n_param = 0;
        disp('Only triple exponential fitting is supported');
end

linear_system = zeros(numel(decay_experimental),n_param);
for ind = 1:n_param
    linear_system(:,ind) = ampl*(fftfilt(irf,exp(-time_axis/nonlinear_parameters(ind)))+scat.*irf);
end

% Do the linear regression using lsqlin
Aeq = ones(1, n_param); % Equality constraints: a1 + a2 + a3 = 1 (Aeq*LP = beq)
beq = 1;       % Equality constraints: a1 + a2 + a3 = 1
options = optimset('lsqlin');
options = optimset(options,'LargeScale','off','Display','off');
start_linear = linear_parameters;
upper_linear = ones(1, numel(start_linear)).*100000;
lower_linear = ones(1, numel(start_linear)).*0;

weights = 1./sqrt(decay_experimental);
lin_optimized = lsqlin((linear_system.*repmat(weights',1,n_param)),(decay_experimental.*weights),[],[],Aeq,beq,...
    lower_linear,upper_linear,start_linear,options); % Optimize linear parameters

linear_parameters = lin_optimized;
fit_func = linear_system*lin_optimized;
residual = (fit_func' - decay_experimental).*weights;

end



