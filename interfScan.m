classdef interfScan < handle
    
    properties
        filepath
        data
        all_data
        stage_positions
        data_ft
        data_fit
        data_plot
        freq
        energy_unit
    end
    
    
    methods
        %%Constructor for the class
        function obj = interfScan(filePath, channel_to_read, anti_flag)
            obj.filepath = filePath;
            if ~isempty(channel_to_read)
                readData(obj, channel_to_read);
            elseif(~isempty(anti_flag))
                obj.all_data = h5read(obj.filepath, '/scan_data');
                sum1 = sum(obj.all_data(:, 1:2), 2);
                sum2 = sum(obj.all_data(:, 3:4), 2);
                obj.data = sum1-sum2;
                pos = h5read(obj.filepath, '/stage_positions');
                obj.stage_positions = pos(1:numel(obj.data));
            else
                obj.all_data = h5read(obj.filepath, '/scan_data');
                obj.data = mean(obj.all_data, 2);        
                pos = h5read(obj.filepath, '/stage_positions');
                obj.stage_positions = pos(1:numel(obj.data));
                
            end
        end
        
        %%reads channel data from hdf5 file
        function readData(obj, channel)
            obj.all_data = h5read(obj.filepath, '/scan_data');
            obj.data = obj.all_data(:, channel);        
            pos = h5read(obj.filepath, '/stage_positions');
            obj.stage_positions = pos(1:numel(obj.data));
            
        end
        
        %%normalizes the data to 1 and subs background
        function normData(obj, background_region)
            
            x = (1:numel(background_region))';
            linfit = polyfit(x, obj.data(background_region), 1);
            back_sub= obj.data-polyval(linfit, 1:numel(obj.data))';
            norm_data = back_sub./max(back_sub);
            obj.data = norm_data;        
        end
        
        %%gaussian data smoothing
        function smoothData(obj, smooth_factor)
            smooth_data = smooth(obj.data, smooth_factor);
            obj.data = smooth_data;        
        end
        
        %%plots fft of the channel
        function plotFFT(obj, energy_unit, energy_range, plot_options, smooth_factor)
            obj.energy_unit = energy_unit;
            freq_axis = get_fft_axis(obj, obj.stage_positions, 'mm', energy_unit);
            ft = fftshift(fft(obj.data));
            plot_region = findIndexRegion(obj, freq_axis, energy_range);
            ft_to_plot = ft(plot_region);
            if nargin > 2 
                if strcmp(plot_options, 'norm')
                    ft_to_plot = ft_to_plot./max(ft_to_plot);
                end
                
                if nargin > 4
                    ft_to_plot = smooth(abs(ft_to_plot), smooth_factor);
                end
            end
            obj.data_ft = ft;
            obj.data_plot = ft_to_plot;
            obj.freq = freq_axis(plot_region);
            plot(freq_axis(plot_region)', abs(ft_to_plot), 'linewidth', 2)
        end
        
        %fits a region of the fft to a gaussian
        function gaussFitFFT(obj, fit_region)
            
            fit_indices = findIndexRegion(obj, obj.freq, fit_region);
            x = obj.freq(fit_indices)';
            y = abs(obj.data_plot);
            mindata = min(y);
            y = y-mindata;

            lb = [1.*max(y), 0, 0];
            ub = [1.05.*max(y), 10, 10];
            obj.data_fit = fit(x, y, 'gauss1', 'Lower', lb, 'Upper', ub);
            
            plot(x, obj.data_fit(x)+mindata, '*r');
            peak_en = obj.data_fit.b1;
            fwhm_gauss = 2.35482/sqrt(2)*obj.data_fit.c1;
            red_bound = freqConv(obj, peak_en-fwhm_gauss/2,...
                obj.energy_unit, 'nm');
            blue_bound = freqConv(obj, peak_en+fwhm_gauss/2,...
                obj.energy_unit, 'nm');
            
            fwhm_nm = red_bound-blue_bound;
            fprintf('FWHM is %.5f nm \n', fwhm_nm);
            
        end
        
        %finds the indices of the array values between bounds
        function region = findIndexRegion(obj, array, bounds)
            [minval, xlow] = min(abs(array-bounds(1)));
            [minval, xhigh] = min(abs(array-bounds(2)));
            if xlow < xhigh
                region = xlow:xhigh;
            else
                region = xhigh:xlow;
            end
        end
        
        %%Determines the frequency axis of the fft
        function freq_axis = get_fft_axis(obj, stage_positions, pos_unit, axis_unit)
            
            retro_factor = 2;
            
            switch pos_unit
                
                case 'mm'
                    cm_divisor = 10; %%stage positions should be in cm
                    step = abs(stage_positions(2)-stage_positions(1))/cm_divisor;
                    step_size = retro_factor*step;
                    fs = 1./step_size; %%sampling frequency
                otherwise
                    fprintf('Not supported length scale\n');
            end
            
            freq =linspace(-fs/2, fs/2, numel(stage_positions)); %%frequency axis in cm^-1
            %freq =linspace(0, fs, numel(stage_positions));
            switch axis_unit
                case 'ev'
                    freq_axis = freq./8065.54; %%frequency axis in eV
                case 'wavenum'
                    freq_axis = freq;
                case 'nm'
                    freq_axis = 1E7./freq;
                otherwise
                    fprintf('Not supported energy scale\n');
                    freq_axis = [];
            end
            
        end
        
        %%frequency conversion
        function freq_out = freqConv(obj, freq, unit_in, unit_out)
            
            switch unit_in
                case 'nm'
                    c = 2.99792458E17; %%nm/s
                    h = 4.135667516E-15; %%eV/s plancks;
                    switch unit_out
                        case 'nm'
                            freq_out = freq;
                        case 'hz'
                            freq_out = 2.*pi.*c./freq;
                        case 'ev'
                            freq_out = c.*h./freq;
                        case 'wavenum'
                            freq_out = 1E7./freq;
                        otherwise
                            fprintf('Unsupported conversion\n');
                    end
                    
                case 'ev'
                    c = 2.99792458E17; %%nm/s
                    h = 4.135667516E-15; %%eV/s plancks;
                    switch unit_out
                        case 'nm'
                            freq_out = c.*h./freq;
                        case 'hz'
                            freq_out = 2.417990504024E14.*freq;
                        case 'ev'
                            freq_out = freq;
                        case 'wavenum'
                            freq_out = freq.*8065.54;
                        otherwise
                            fprintf('Unsupported conversion\n');
                    end
                    
                case 'wavenum'
                    switch unit_out
                        case 'wavenum'
                            freq_out = freq;
                        case 'nm'
                            freq_out = 1E7./freq;
                        case 'ev'
                            freq_out = freq./8065.54;
                        case 'hz'
                            %freq_out =
                        otherwise
                            fprintf('Unsupported conversion\n');
                    end
                    
                otherwise
                    fprintf('Unsupported UNits\n');
                    
                    
            end

end
        
    end
    
    
end
