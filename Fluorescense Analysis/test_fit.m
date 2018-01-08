clear;

data = dlmread('C:\Users\bspoka\Google Drive\Lincoln_Data\Sophie_Boris\Matlab_Scripts\Fluorescense Analysis\SandraLifetimes_processed.dat');
clf
hold on
time = data(:, 1);
plot(data(:, 2));
plot(data(:, 3));
%%

reg = 4300:11500;

time = data(reg, 1);
irf_norm = NormalizeByArea(time, data(reg, 2), 1:10);
lifetime_norm = NormalizeByArea(time, data(reg, 3), 1:10);

irfshift = -40;
decay_times = [1, 1];
amplitudes = [1, 1];
coeffs = [irfshift, decay_times, amplitudes];
num_exponentials = numel(decay_times);
[resid, lifetime_trace] = minimize_me(coeffs,irf_norm,time,lifetime_norm,num_exponentials);

clf
hold on
plot(time, lifetime_norm)
plot(time, irf_norm)
plot(time, lifetime_trace)

%%
fit_coeffs = fminsearch(@(coeffs) minimize_me(coeffs,irf_norm,time,lifetime_norm,num_exponentials),coeffs);
[resid, lifetime_trace, irf_shifted] = minimize_me(fit_coeffs,irf_norm,time,lifetime_norm,num_exponentials);

clf
hold on
plot(time, lifetime_norm)
%plot(time, irf_shifted)
plot(time, lifetime_trace)
set(gca, 'yscale', 'log')

