function [residual, lifetime_trace_norm, irf_shifted] = minimize_me(coeffs,irf_norm,time,lifetime_norm,num_exponentials)
    
    
    exp_decay = ExpDecayModel(time,num_exponentials,coeffs); %generates an exponential model
    
    [~, shift_dim] = max(size(irf_norm)); %irf shift dimension
    irf_shifted = circshift(irf_norm, round(coeffs(1)), shift_dim); %shifts the irf by coeffs(end)
    
    irf_conv_exp = conv(irf_shifted,exp_decay); %convolutes the irf with exponential model
    lifetime_trace = irf_conv_exp(1:ceil(length(irf_conv_exp)/2)); %takes half og the convolution
    lifetime_trace_norm = lifetime_trace./trapz(time,lifetime_trace);
    %lifetime_trace_norm = lifetime_trace./max(lifetime_trace);
    residual = sum((lifetime_norm-lifetime_trace_norm).^2);
    
end