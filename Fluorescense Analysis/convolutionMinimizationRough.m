function [chi_squared, conv_irf_model, amp_ratio] = convolutionMinimizationRough(model_parameters, irf, ...
    decay_experimental, model_name, time_axis)

%%model_paramaters --> array of model coefficients
%%irf --> experimental (or fakenews) irf
%%decay_experimental --> experimental lifetime
%%model_name --> name of the model specified by decayModels enum (i.e. decayModels.singleExponential)
%%time_axis --> time axis of the experimental lifetime (should be the same as irf)

decay_model = generateDecayModel(model_name, model_parameters, time_axis); %% generate decay model
conv_irf_model = fftfilt(irf,decay_model); %%fft convolution of irf and decay model

%this amplitude ratio fixes the maximum of the fit to the maximum of the
%decay data (will be floated in the next steps)
amp_ratio = max(decay_experimental)/max(conv_irf_model);
conv_irf_model = amp_ratio*conv_irf_model;

%%minimizing chi^2 (weighted squared residual)
weights = 1./sqrt(decay_experimental);
chi_squared = sum(((decay_experimental-conv_irf_model).*weights).^2 ...
    /numel(decay_experimental)); % Reduced chi square

end