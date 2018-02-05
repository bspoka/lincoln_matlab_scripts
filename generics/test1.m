clear all;
addpath(genpath('C:\Users\bspok\Dropbox (MIT)\LincolnData\Sophie_Boris\Matlab_Scripts'));
fpath = 'C:\Users\bspok\Dropbox (MIT)\LincolnData\Sophie_Boris\180109\inas_1480nm_lifetime_1.hdf5';
irf_path = 'C:\Users\bspok\Dropbox (MIT)\LincolnData\Sophie_Boris\180109\irfs\irf_1064nm_64ps.hdf5';
panda = PhotonRecordsFileClass(fpath);
panda.readTMode();
resltn = panda.readResolution();
irf = PhotonRecordsFileClass(irf_path);
%%
data = PhotonStream(panda);
plot_result = false;
lifetime = data.getLifetime(plot_result);
lifetime_smooth = data.smoothLifetime([], 32, true);
lifetime_subBack = data.subtractLifetimeBackground([], [], plot_result);
lifetime_norm = data.normalizeLifetime([], 'max', true);

irf_data = PhotonStream(irf);
irf_decay = irf_data.getLifetime(plot_result);
irf_sub = irf_data.subtractLifetimeBackground(irf_decay, [], plot_result);
irf_norm = irf_data.normalizeLifetime(irf_sub, 'max', true);
%%
folder_path = 'C:\Users\bspok\Dropbox (MIT)\LincolnData\Sophie_Boris\180109';
lifes = {'inas_1284nm_lifetime.hdf5'; 'inas_1360nm_lifetime.hdf5'; 'inas_1412nm_lifetime.hdf5';... 
    'inas_1489nm_lifetime.hdf5'; 'inas_1480nm_lifetime.hdf5'};

clf;hold on;
plot_result = false;
for ind = 1:numel(lifes)
    fname = fullfile(folder_path, lifes{ind});
    
    panda = PhotonRecordsFileClass(fname);
    data = PhotonStream(panda);
    lifetime = data.getLifetime(plot_result);
    lifetime_smooth = data.smoothLifetime(lifetime, 16, plot_result);
    lifetime_subBack = data.subtractLifetimeBackground(lifetime_smooth, [], plot_result);
    lifetime_norm = data.normalizeLifetime(lifetime_subBack, 'max', plot_result);
    plot(lifetime_norm.time_axis, lifetime_norm.decay);
    set(gca, 'yscale', 'log')
    drawnow;
    
end

%% Rough Fitting
global irf_fwhm_ns
reg = 1:30000;
irf_fwhm_ns = 0.1;
irf_shift_ns = -0.356;
model_name = decayModels.tripleExponential;
scatter = true;
irf_shift = true;

%Gaussian function for fake news IRF
gaussfnc = @(time, amp, sigma, tau) amp.*exp(-(time-tau).^2./(2*sigma).^2);
time_axis = lifetime.time_axis(reg);
irf = gaussfnc(time_axis, max(lifetime.decay), irf_fwhm_ns, irf_shift_ns); %generate irf
decay_experimental  = lifetime.decay(1:numel(irf))+1;
irf =irf(reg);
decay_experimental = decay_experimental(reg);

%default fitting parameters
tau_lower = 1E-6;
amp_lower = 0;
start = [0.1, 1, 0.1, 1, 0.1, 1]; 
lower = [amp_lower, tau_lower, amp_lower,tau_lower,amp_lower,tau_lower];
upper = [1E6, 1E6, 1E6, 1E6, 1E6, 1E6];
switch model_name
    case decayModels.tripleExponential
        n_param = 6;
    case decayModels.doubleExponential
        n_param = 4;
    case decayModels.singleExponential
        n_param = 2;
    otherwise 
        n_param = 0;
end
start = start(1:n_param);
lower = lower(1:n_param);
upper = upper(1:n_param);
        
%rough nonlinear optimization across all paramaters (linear and nonlinear)
rough_params = fminsearchbnd(@ (model_parameters)...
    convolutionMinimizationRough(model_parameters, irf, decay_experimental, model_name, time_axis),...
    start, lower, upper,...
    optimset('MaxFunEvals',5000,'MaxIter',5000,'TolFun',0.0001,'TolX', 0.0001,'Display','off'));

%evalute one more time to get the last result out
[~, conv_irf_model, amp_ratio] = convolutionMinimizationRough(rough_params, irf, ...
    decay_experimental, model_name, time_axis);

clf
hold on
plot(time_axis, decay_experimental);
plot(time_axis, conv_irf_model, '.r')
set(gca, 'yscale', 'log', 'ylim',...
    [min(decay_experimental)*0.9, max(decay_experimental)*1.1], 'xlim', [-100, 3500])

%% Better fitting
% in this part the linear paramaters (amplitudes of the exponentials) are
% fitted separately from the nonlinear paramaters (decay lifetimes). 

global linear_parameters

linear_parameters = rough_params(1:2:end); %amplitudes
nonlinear_parameters = [rough_params(2:2:end), amp_ratio, 0, irf_shift_ns]; %decay times, global multiplier
nonlinear_lower = [lower(2:2:end), 0,  0, irf_shift_ns];
nonlinear_upper = [upper(2:2:end), inf,  0, irf_shift_ns];

if scatter
    nonlinear_parameters(end-1) = 1; %decay times, global multiplier
    nonlinear_lower(end-1) = 0;
    nonlinear_upper(end-1) = inf;
end

if irf_shift
    nonlinear_parameters(end) = irf_shift_ns; %decay times, global multiplier
    nonlinear_lower(end) = min(time_axis);
    nonlinear_upper(end) =  max(time_axis);
end

%nonlinear optimization (linear performed within)
[NLpars,~,~,~,~,~,jacobian] = lsqnonlin(@(nonlinear_parameters)...
    convolutionMinimizationFancy_3(nonlinear_parameters, irf, decay_experimental,...
    model_name, time_axis, scatter, irf_shift),nonlinear_parameters, nonlinear_lower, nonlinear_upper,...
    optimset('Display', 'off'));

[residual, fit_func]  = convolutionMinimizationFancy_3(NLpars, irf, ...
    decay_experimental, model_name, time_axis, scatter, irf_shift);

%confidence intervals for the nonlinear paramaters
ci = nlparci(NLpars,residual,'jacobian',jacobian); 
lin_p = zeros(1, numel(NLpars));
lin_p(1:numel(linear_parameters)) = linear_parameters;
lin_p = lin_p./max(lin_p);
fit_coeffs = [ci(:, 1), NLpars', ci(:, 2), lin_p']

clf
hold on
plot(time_axis, decay_experimental);
plot(time_axis, fit_func, '.r');
set(gca, 'yscale', 'log', 'ylim', [10^1, 10^5], 'xlim', [-100, 3500])

%%
x = [20, 40, 60, 120, 180];
y = [42.626, 95.494, 86.23, 117.07, 95.28];
y1 = [147.134, 213.26, 216.68, 256.7, 261.543];
y2 = [0.35, 0.401, 0.189, 0.368, 0.159];
plot(x,y2)
