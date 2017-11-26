function [lags, acf] = g2_corr_dll(ch1,ch2, ps_range, num_points, offset_lag)

num_ch1 = int32(numel(ch1));
num_ch2 = int32(numel(ch2));
acf = zeros(1, num_points);
lags = zeros(1, num_points);

tic()
[~, ~, acf, lags] = calllib('corr_funcs',...
    'picoquant_g2_corr', ch1, ch2, num_ch1, num_ch2, ps_range,...
    num_points, offset_lag, acf, lags);
toc()

end