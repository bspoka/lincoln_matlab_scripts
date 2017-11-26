%Interferogram FFT 
%Load Interferogram
Interf_Data=load('C:\Users\so26588\Documents\Sophie_Boris\170803\broadband_calibration.txt');

N_FT=8049;
evtowavenum=8056.6;

Position_Spacing=-mean(mean(diff(Interf_Data(:,1:2))));
Ave_Interf_Trunc=Interf_Data(:,3)-mean(Interf_Data(:,3));
Max_Frequency=1./(4*Position_Spacing)/10;
Freq_Vec=linspace(0,2*Max_Frequency,N_FT);
FT_Interf=abs(fft(Ave_Interf_Trunc,N_FT));
FT_Interf_Smooth=smooth(FT_Interf);
Wave_Range=[800 1800]
Energy_Range=1./Wave_Range*1e7./evtowavenum;
[r E_Index_1]=min(abs(Freq_Vec-Energy_Range(2)));
[r E_Index_2]=min(abs(Freq_Vec-Energy_Range(1)));

plot(1./Freq_Vec(E_Index_1:E_Index_2),FT_Interf(E_Index_1:E_Index_2)./max(FT_Interf(E_Index_1:E_Index_2)))

%%
freq = linspace(-Max_Frequency/2, Max_Frequency/2, N_FT);

plot(freq, FT_Interf)

%plot(Ave_Interf_Trunc)

%%
% clear
% i1=load('C:\Users\so26588\Documents\Sophie_Boris\170803\broadband_calibration.txt');
% i2=load('C:\Users\so26588\Documents\Sophie_Boris\170803\broadband_calibration.txt');
% 
% ishift = circshift(i2, 6, 1);
% 
% clf
% hold on
% plot(i1(:, 3));
% plot(ishift(:, 3));
% 
% %%
% 
% pth = 'C:\Users\so26588\Documents\Sophie_Boris\170720\circle.jpg';
% 
% circ = imread(pth);
% 
% circ1 = double(circ(4:483, 4:485, 1));
% 
% ft = fftshift(fftshift(fft(fft(circ1, [], 1), [], 2), 1), 2);
% 
% 
