classdef PhotonStream < handle
    
    properties
        photon_record PhotonRecordsFileClass
        current_figure
        last_result
    end
    
    methods
        %%------------------------ General Functions---------------------%%
        
        %%photon stram constructor takes object of PhotonRecordsFileClass
        %%class
        function obj = PhotonStream(photon_record)
            obj.photon_record = photon_record;
        end
        %%---------------------------------------------------------------%%
        
%         function [binned_data, bin_width] = binData(obj, bin_number)
%         end
        %%------------------------ Lifetime Functions--------------------%%
        %plot lifetime decay
        % Reads the t3 data from the photon_record file and plots a
        % histogram of pulse-relative photon arrival times
        function lifetime = getLifetime(obj, plot_result)
            switch obj.photon_record.readTMode() %first reads the acqusition mode
                case 3 %t3 mode
                    data = obj.photon_record.readAllData(); %reads all data into memory
                    resolution = obj.photon_record.readResolution(); %arrival time resolution
                    
                    %%putting the time_axis and the decay data into a
                    %%struct 
                    lifetime = struct();
                    time_axis = 0:resolution:max(data.Times); 
                    [lifetime.('decay'),  lifetime.('time_axis')] = histcounts(data.Times, time_axis);
                    
                    %shift the 'zero' of the time axis to the IRF (max of
                    %the decay) and setting the time axis to ns
                    [~, max_decay_ind] = max(lifetime.decay);
                    lifetime.time_axis = (lifetime.time_axis-lifetime.time_axis(max_decay_ind))./1000;
                    lifetime.time_axis = lifetime.time_axis(1:end-1);
                    
                    %simple baseline estimation
                    backg = mean(lifetime.decay(1:max_decay_ind-round(0.75*max_decay_ind)));
                                    
                    if nargin > 1
                        if plot_result
                            fig = figure();
                            fig.Units = 'inches';
                            fig.Position = [1, 1, 8, 8];
                            hold on
                            plot(lifetime.time_axis, lifetime.decay, 'linewidth', 2);
                            %plot(lifetime.time_axis, ones(1, numel(lifetime.time_axis)).*backg, ...
                            %    '--k', 'linewidth', 2);
                            set(gca, 'fontsize', 14, 'yscale', 'log');
                            xlabel('Time (ns)');
                            box on; grid on;
                            title('Raw lifetime data')
                        end
                    end
                    
                case 2 %data is T2 -->error 
                    lifetime = struct();
                    disp('Cannot plot lifetime with T2 data...');
                otherwise %data is neither T2 or T3 --> error
                    lifetime = struct();
                    disp('Cannot plot lifetime...');
            end
            
            obj.last_result = lifetime;      
        end
        
        %%subtracts background from the lifetime data by finding the mean
        %%of the photon count distribution to the left of the IRF, fitting
        %%it to a gaussian and subtracting from the lifetime.
        function lifetime = subtractLifetimeBackground(obj, lifetime, ...
                backg_range, plot_result)
            if nargin > 1
                if isempty(lifetime)
                    lifetime = obj.last_result;
                end
                
                [~, max_decay_ind] = max(lifetime.decay);
                
                %%if custom background region is not specified
                if isempty(backg_range)
                    %%take 75% of the data to the left of the IRF for
                    %%background
                    backg_range = 1:max_decay_ind-round(0.75*max_decay_ind);
                end
                
                %%histograms and fits the background counts distribution
                backg_region = lifetime.decay(backg_range);
                [n, counts] = histcounts(backg_region); 
                gfit = fit((counts(1:end-1))', n', 'gauss1'); % fits background to gaussian
                lifetime.decay = lifetime.decay-gfit.b1;
                lifetime.decay(lifetime.decay < 0) = 0; %negative values turn to zero
                
                if plot_result  
                    fig = figure();
                    fig.Units = 'inches';
                    fig.Position = [1, 1, 12, 8];
                    
                    subplot(2,3,1)
                        plot(lifetime.time_axis(backg_range), backg_region);
                        title('Background region');
                        ylabel('Counts')
                        xlabel('Time (ns)')
                        grid on; box on;
                        %set(gca, 'fontsize', 14);

                    subplot(2,3,4)
                        hold on
                        plot((counts(1:end-1))', n', '-*');
                        plot(gfit);
                        xlabel('Background Counts');
                        ylabel('Count Frequency');
                        title('Background histogram fit');
                        grid on; box on;
                        %set(gca, 'fontsize', 14);
                    
                    subplot(2,3, [2:3,5:6])
                        hold on
                        plot(lifetime.time_axis, lifetime.decay, 'linewidth', 2);
                        set(gca, 'fontsize', 14, 'yscale', 'log');
                        xlabel('Time (ns)');
                        title('Background-Subtracted Lifetime');
                        box on; grid on;
                end
                       
            end
            obj.last_result = lifetime;
        end
        
        %%normalized the lifetime either to the maximum or by area
        function lifetime = normalizeLifetime(obj, lifetime, method,...
                plot_result)
            if nargin > 1
                if isempty(lifetime)
                    lifetime = obj.last_result;
                end
                
                %%default normalization is to the maximum
                if isempty(method)
                    method = 'max';
                end
                
                switch method
                    case 'max' 
                        [max_decay, ~] = max(lifetime.decay);
                        lifetime.decay = lifetime.decay./max_decay;
                    case 'area'
                        curve_area = trapz(lifetime.decay); %integral of the lifetime curve
                        lifetime.decay = lifetime.decay./curve_area;
                    otherwise %--> error
                        lifetime.decay = [];
                        disp('Unsupported normalization method... (max or area)');
                end
                
                if plot_result
                    fig = figure();
                    fig.Units = 'inches';
                    fig.Position = [1, 1, 8, 8];
                    plot(lifetime.time_axis, lifetime.decay, 'linewidth', 2);
                    set(gca, 'fontsize', 14, 'yscale', 'log');
                    if strcmp(method, 'max')
                        set(gca, 'ylim', [0, 1],...
                        'ytick', [0, 1], 'yticklabel', {'0', '1'});
                    end
                    xlabel('Time (ns)');
                    title('Normalized Lifetime');
                    box on; grid on;
                end
                
            end
            obj.last_result = lifetime;
        end
        
        %%smoothes the lifetime with a moving average filter
        function lifetime = smoothLifetime(obj, lifetime, smooth_length,...
                plot_result)
            if nargin > 1
                if isempty(lifetime)
                    lifetime = obj.last_result;
                end
                
                %%default normalization is to the maximum
                if isempty(smooth_length)
                    smooth_length = 1;
                end
                
                lifetime.decay = smooth(lifetime.decay, smooth_length);           
                
                if plot_result
                    fig = figure();
                    fig.Units = 'inches';
                    fig.Position = [1, 1, 8, 8];
                    plot(lifetime.time_axis, lifetime.decay, 'linewidth', 2);
                    set(gca, 'fontsize', 14, 'yscale', 'log');
                    xlabel('Time (ns)');
                    title('Smoothed Lifetime');
                    box on; grid on;
                end
                
            end
            obj.last_result = lifetime;
        end
        %%---------------------------------------------------------------%%
        
    end
    
end
