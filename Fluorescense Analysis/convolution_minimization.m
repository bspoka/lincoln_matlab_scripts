function chi_squared = convolution_minimization(irf, decay_experimental,...
    model_name, model_parameters)

decay_model = generateDecayModel(model_name, model_parameters);
conv_irf_model = fftfilt(irf,decay_model);

amp_ratio = max(decay_experimental)/max(conv_irf_model);
conv_irf_model = amp_ratio*conv_irf_model;

%%minimizing chi^2
chi_squared = sum(((decay_experimental-conv_irf_model).*weights).^2 ...
    /length(decay_experimental)); % Reduced chi square



end
