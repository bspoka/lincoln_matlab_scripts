function [lags, acf] = cross_corr_dll(ch1,ch2, start_time, stop_time, coarseness, offset_lag)

num_ch1 = int32(numel(ch1));
num_ch2 = int32(numel(ch2));
acf = zeros(1, 1024);
lags = zeros(1, 1024);
acf_length = int32(zeros(1, 2));

tic()
[~, ~, acf, lags, acf_length] = calllib('corr_funcs',...
    'picoquant_photons_in_bins', ch1, ch2, num_ch1, num_ch2, start_time,...
    stop_time, coarseness, offset_lag, acf, lags, acf_length);
toc()

reg = (acf_length(1)+1):(acf_length(2));

lags = lags(reg);
acf = acf(reg);

end