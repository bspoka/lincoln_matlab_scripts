function [corr_norm, lags] = cross_corr(ch1,ch2, start_time, stop_time, coarseness, offset_lag)

cascade_start = floor(log2(start_time/10)-2);% if above 0, the algorithm skips the 2^start_cascade correlation times
[lag_bin_edges, lags, division_factor] = generate_log2_lags(stop_time, coarseness); % generates lags bins with log2 spacing

tic
fprintf('Correlating Data...\n');
corr = photons_in_bins(ch1, ch2, lag_bin_edges, ...
            cascade_start, coarseness, offset_lag);

num_ch1 = numel(ch1); num_ch2 = numel(ch2); %number of photons in each channel
ch1_max = ch1(end); ch2_max = ch2(end);
tcor = min(ch1_max, ch2_max-lags);
%tag_range = max(ch1_max, ch2_max)- min(ch1_min, ch2_min); %range of tags in the entire dataset
skip_lags = cascade_start*coarseness;
%%Normalization
corr_div = corr./division_factor(2:end);
corr_norm = 2.*(corr_div./tcor)./((num_ch1./ch1_max).*(num_ch2./ch2_max));
% corr_norm = 2.*corr_div.*tag_range./(tag_range-lags)...
%     .*ch1_max./(ch1_count.*ch2_count);

corr_norm = corr_norm(:, skip_lags:end);
lags = lags(skip_lags:end);

fprintf('Done\n')
toc

end

function [lag_bin_edges, lags, division_factor] = generate_log2_lags(t_end, coarseness)      
           %%Generates log2 spaced photon bins
           cascade_end = floor(log2(t_end/10)-2); % cascades are collections of lags with equal bin spacing 2^cascade
           nper_cascade = coarseness; % number of equal
           
           n_edges = cascade_end*nper_cascade;
           lag_bin_edges = zeros(1, n_edges); %lag bins
           
           for j = 1:n_edges
               if j == 1
                   lag_bin_edges(j) = 1;
               else
                   lag_bin_edges(j) = lag_bin_edges(j-1)+2^(floor((j-1)./nper_cascade));
               end
           end
           lags = diff(lag_bin_edges)./2+lag_bin_edges(1:end-1); %centers of the lag bins
           division_factor = kron(2.^(1:cascade_end), ones(1, nper_cascade)); %for normalization
end


function acf = photons_in_bins(ch1, ch2, lag_bin_edges, ...
               cascade_start, nper_cascade, offset_lag)
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
           
           for phot_ind = 1:num_ch1
               bin_edges = ch1(phot_ind)+lag_bin_edges+offset_lag;
               
               for k = cascade_start*nper_cascade:n_edges-1
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