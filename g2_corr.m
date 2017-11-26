function [corr, lag_bin_edges] = g2_corr(ch1,ch2, ps_range, num_points, offset_lag)

lag_bin_edges = zeros(1, num_points);
dbin = ps_range/num_points;
num_negative_bins = floor(num_points/2);
for ind = 1:num_points
    curr_bin = ind-num_negative_bins;
    lag_bin_edges(ind) = dbin*curr_bin;
end

% neg_bins = linspace(-ps_range, 0, round(num_points./2));
% dbin = abs(neg_bins(2)-neg_bins(1));
% pos_bins = (1:(num_points-numel(neg_bins))).*dbin;
% lag_bin_edges = [neg_bins pos_bins];

tic
fprintf('Correlating Data...\n');
corr = photons_in_bins(ch1, ch2, lag_bin_edges, offset_lag);
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