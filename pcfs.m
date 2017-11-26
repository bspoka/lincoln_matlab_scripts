classdef pcfs < handle
    
    properties
        filepath
        file_info
        num_delays
        photon_mode
        step_data
        corr_data
        stage_positions
    end
    
    methods
        
        %%pcfs constructor
        function obj = pcfs(filepath)
            obj.filepath = filepath;
            hdf_info = h5info(filepath);
            obj.file_info = hdf_info.Attributes;
            obj.photon_mode = hdf_info.Attributes(8).Value{1};
            obj.stage_positions = h5read(filepath, '/stage_positions');
            obj.num_delays = numel(obj.stage_positions);

            b = blanks(5);
            
            [path_str,path_name,path_ext] = fileparts(filepath);
            fprintf(strcat('File Name: \t',path_name, '\n')); %%file name
            fprintf(strcat('Date Created: \t',b, hdf_info.Attributes(1).Value{1},'\n')); %date created%
            fprintf(strcat('Number of Steps: \t', num2str(hdf_info.Attributes(4).Value),'\n')); %interferometers steps%
            fprintf(strcat('Data Mode: \t',b, hdf_info.Attributes(8).Value{1},'\n')); %T2 or T3%
            fprintf(strcat('Notes: \t', hdf_info.Attributes(9).Value{1},'\n'));
        end
        

        %retrives photon stream data from one interferometer step
        function step_data = step(obj, num_step)
            dset_path = strcat('/data/pos', num2str(num_step, '%05d'), '/');
            switch obj.photon_mode
                case 'T2'
                    photon_data = h5read(obj.filepath, strcat(dset_path, 'photon_records'));
                    channel_data = h5read(obj.filepath, strcat(dset_path, 'channels'));
                    obj.step_data = struct('channels', channel_data, 'times', photon_data);
                    step_data = obj.step_data;
                case 'T3'
                otherwise 
                    fprintf('Unsupported data format... \n');
            end
        end
        
        
        %bin delay step
        function [N,edges] = binStep(obj, num_step, channel_num, bin_width)
            dset_path = strcat('/data/pos', num2str(num_step, '%05d'), '/');
            switch obj.photon_mode
                case 'T2'
                  photon_data = h5read(obj.filepath, strcat(dset_path, 'photon_records'));
                  channel_data = h5read(obj.filepath, strcat(dset_path, 'channels')); 
                  if isempty(channel_num)
                       dat = double(photon_data);
                  else
                      ch_inds = find(channel_data == channel_num);
                      dat = double(photon_data(ch_inds));
                  end
                       tag_range = range(obj,dat);
                       num_bins = round(tag_range/bin_width);
                       time_bins = linspace(dat(1), dat(end), num_bins);
                       [N,edges] = histcounts(dat,time_bins);
                       edges = edges(1:(end-1));
                case 'T3'
                otherwise
            end            
        end
        
        %%cross correlate two channels
        function corrStep(obj, num_step, channels, start_time, stop_time, coarseness, offset_lag)
            if ~isempty(num_step)
                corr_chan = corrChan(obj, num_step, channels, start_time, stop_time, coarseness, offset_lag);
                obj.corr_data = struct('corr', corr_chan.corr, 'lags', corr_chan.lags);
            else
                ww = waitbar(0, 'Correlating...');
                for ind = 0:obj.num_delays-1
                     corr_chan = corrChan(obj, ind, channels, start_time, stop_time, coarseness, offset_lag);
                     if ind == 0
                         corr_2d = zeros(obj.num_delays, numel(corr_chan.lags));
                     end
                     corr_2d(ind+1, :) = corr_chan.corr;
                     waitbar(ind/(obj.num_delays-1));
                end
                close(ww)
                obj.corr_data = struct('corr', corr_2d, 'lags', corr_chan.lags);
            end
        end
        
        function plotCorr(obj, en_offset)
            fig_corr = figure;
            fig_corr.Units = 'normalized';
            fig_corr.OuterPosition = [0 0 1 1];
            while ishghandle(fig_corr)
                try
                subplot(2,2, [1, 3])
                semilogx(obj.corr_data.lags*(1E-12), 1-obj.corr_data.corr);
                xlabel('Lag Time (s)')
                box on
                grid on
                h = impoint();
                pos = getPosition(h);
                [c index] = min(abs(obj.corr_data.lags*(1E-12)-pos(1)));
                delete(h);

                
                subplot(222)
                plot(obj.stage_positions, obj.corr_data.corr(:, index), 'linewidth', 2);
                xlabel('Stage Position (mm)')
                box on
                grid on
                
                subplot(224)
                n = ceil(obj.num_delays/2+en_offset);
                freq_axis = get_fft_axis(obj, 'mm', 'ev');
                ft = abs(fftshift(fft(obj.corr_data.corr(:, index))));
                plot(freq_axis, ft, 'linewidth', 2);
                xlabel('Energy Separation (mm)')
                box on
                grid on
                catch
                end
                
            end
        end
            
    end
    
    methods (Access = private)
        function rng = range(obj, arr)
            rng = max(arr)-min(arr);
        end
        
         function corr_chan = corrChan(obj, num_step, channels, start_time, stop_time, coarseness, offset_lag)
                dset_path = strcat('/data/pos', num2str(num_step, '%05d'), '/');
                switch obj.photon_mode
                    case 'T2'
                      photon_data = h5read(obj.filepath, strcat(dset_path, 'photon_records'));
                      channel_data = h5read(obj.filepath, strcat(dset_path, 'channels')); 
                      dat = double(photon_data);
                    case 'T3'
                    otherwise
                end
                
                if (~isempty(channels))
                ch_inds = find((channel_data == channels(1))|(channel_data == channels(2)));
                %ch2_inds = find(channel_data == channels(2));
                ch1 = dat(ch_inds);
                ch2 = dat(ch_inds);
                else
                    ch1 = dat;
                    ch2 = dat;
                end

                [corr_norm, lags] = cross_corr(ch1,ch2, start_time, stop_time, coarseness, offset_lag);
                corr_chan = struct('corr', corr_norm-1, 'lags', lags);
         end
        
         %%Determines the frequency axis of the fft
        function freq_axis = get_fft_axis(obj, pos_unit, axis_unit)
            
            retro_factor = 2;
            
            switch pos_unit
                
                case 'mm'
                    cm_divisor = 10; %%stage positions should be in cm
                    step = abs(obj.stage_positions(2)-obj.stage_positions(1))/cm_divisor;
                    step_size = retro_factor*step;
                    fs = 1./step_size; %%sampling frequency
                otherwise
                    fprintf('Not supported length scale\n');
            end
            
            freq =linspace(-fs/2, fs/2, numel(obj.stage_positions)); %%frequency axis in cm^-1
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
        
    end

    
end