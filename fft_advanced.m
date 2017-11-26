clear
data = load('C:\Users\so26588\Documents\Sophie_Boris\170803\broadband_calibration.txt');
%data50 = load('C:\Users\so26588\Documents\Sophie_Boris\170803\broadband_calibration_50nmBP.txt');

ch1 = data(:, 3);

retro_factor = 2; %moving stage by a certain distance doubles the actual displacement
step_size = retro_factor*2.18E-6;%stage step size in cm
fs = 1./step_size; %Sampling frequency

freq_axis =linspace(-fs/2, fs/2, numel(ch1)); %%frequency axis in cm^-1
freq_ev = freq_axis./8065.54; %%frequency axis in eV
ch1_ft = abs(fftshift(fft(ch1))); 

clf
hold on
plot(freq_ev, ch1_ft)
set(gca, 'xlim', [0, 1], 'ylim', [0 0.5E9]);

%%
data1 = load('C:\Users\so26588\Documents\Sophie_Boris\170803\broadband_calibration_50nmBP.txt');

ch1_50 = data1(1951:end, 3);
ch50_ft = abs(fftshift(fft(ch1_50)));

%%
y1 = ch1_ft(4100:4400);
y1 = y1- mean(y1(1:100));
x1 = freq_ev(4100:4400);

gfit = fit(x1', y1, 'gauss1');


plot(x1, y1, x1, gfit(x1))



