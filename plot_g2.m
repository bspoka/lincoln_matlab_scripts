clear
hdf_path = 'C:\Users\bspoka\Dropbox (MIT)\h-BN_Boris_Hendrik\Hendrik\171214_hBN_sparse_sample_4K\defect3_g2.hdf5';
chans = [0, 1];
num_pulses = 5; %% number of pulses to view in g2
num_points = 100;%% time bins 

try
    t_mode = h5read(hdf_path, '/header/mode');
    photon_arrivals = double(h5read(hdf_path, '/photon_records'));
    syncs = double(h5read(hdf_path, '/syncs'));
    channels = h5read(hdf_path, '/channels');
    sync_rate = h5read(hdf_path, '/header/sync_rate');
catch
    try
        data = h5read(hdf_path, '/photon_records');
        resolution = h5readatt(hdf_path, '/', 'resolution');
        t_mode = size(data, 2);
        if t_mode == 3
            photon_arrivals = data(:, 3).*resolution;
            syncs = data(:, 2);
            sync_rate = 1.5E6;
        else
            photon_arrivals = data(:, 2);
        end
        channels = data(:, 1);
        
    catch
        fprintf('Unsupported file Format\n');
    end
end

bins = linspace(min(photon_arrivals), max(photon_arrivals), 500);
[n, edges] = histcounts(photon_arrivals, bins);
[nmax, nmax_ind] = max(n);
semilogy(edges(1:end-3)-edges(nmax_ind), n(1:end-2));



speriod = 1/sync_rate.*1E12;

ps_range = speriod.*num_pulses;
ch1_inds = channels == chans(1);
ch2_inds = channels == chans(2);

if t_mode == 3
    ch1 = syncs(ch1_inds).*speriod+photon_arrivals(ch1_inds);
    ch2 = syncs(ch2_inds).*speriod+photon_arrivals(ch2_inds);
    clear photon_arrivals
    clear syncs
    clear channels
else
     ch1 = photon_arrivals(ch1_inds);
     ch2 = photon_arrivals(ch2_inds);
end

[lags, acf] = g2_corr_dll(ch1,ch2, ps_range, num_points, 0);
[lags, acf1] = g2_corr_dll(ch2,ch1, ps_range, num_points, 0);

plot(lags, (acf+acf1)./2);
%plot(lags, acf);