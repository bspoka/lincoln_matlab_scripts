function [corr_nnorm, lags] = cross_corr_nnorm(ch1,ch2, lags, offset_lag)
%ch1, ch2: photon arrivals for T2 data, sync numbers for T3 data
% lags: array of lags in ch1, ch2 time units (can be arbitrary spacing)
% offset_lag: offset for ch1

tic
fprintf('Correlating Data...\n');
corr_nnorm = photons_in_bins(ch1, ch2, lags, offset_lag);
fprintf('Done\n')
toc

end


function acf = photons_in_bins(ch1, ch2, lag_bin_edges, offset_lag)
           %%Counts the number of photons in the photon stream bins
           %%according to a prescription from Ted Laurence: Fast flexible
           %%algirthm for calculating photon correlation, Optics Letters,
           %%31,829,2006
           num_ch1 = numel(ch1);
           n_edges = numel(lag_bin_edges);
           low_inds = ones(1, n_edges-1);
           low_inds(1) = 2;
           max_inds = ones(1, n_edges-1);
           acf = zeros(1, n_edges-1);
           ch2 = ch2+offset_lag;
           for phot_ind = 1:num_ch1
               bin_edges = ch1(phot_ind)+lag_bin_edges+offset_lag;
               
               for k = 1:n_edges-1
                   while low_inds(k) <= numel(ch2) && ch2(low_inds(k)) < bin_edges(k)
                       low_inds(k) = low_inds(k)+1;
                   end
                   
                   while max_inds(k) <= numel(ch2) && ch2(max_inds(k)) <= bin_edges(k+1)
                       max_inds(k) = max_inds(k)+1;
                   end
                   
                   low_inds(k+1) = max_inds(k);
                   acf(k) = acf(k)+(max_inds(k)-low_inds(k));
               end
           end
       end