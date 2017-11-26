classdef photonStream < handle
    
    properties
        filepath
        data
        channel_data
        unique_channels
        corr_data
      
    end
    
    methods
        
        function obj = photonStream(filepath)
            obj.filepath = filepath;
            readData(obj);
        end
        
        %%reads all data from photon stream
        function readData(obj)
            obj.data = h5read(obj.filepath, '/photon_records');
        end
        
        %select a particular channel from stream
        function splitChannels(obj)
            obj.unique_channels = unique(obj.data(:, 1));
            
            obj.channel_data = cell(1, numel(obj.unique_channels));
            for ind = 1:numel(obj.unique_channels)
                ch_inds = find(obj.data(:, 1) == obj.unique_channels(ind));
                obj.channel_data{ind} = obj.data(ch_inds, 2);
            end
        end
        
        %%combines channels in the photon stream
        
        %%cross correlate two channels
        function data_corr = crossCorrelate(obj, channels, start_time, stop_time, coarseness, offset_lag)
            
            ch1 = obj.channel_data{channels(1)+1};
            ch2 = obj.channel_data{channels(2)+1};

            [corr_norm, lags] = cross_corr(ch1,ch2, start_time, stop_time, coarseness, offset_lag);
            
            %plot(lags, corr_norm-1);
            %set(gca, 'xscale', 'log');
            obj.corr_data = struct('corr', corr_norm-1, 'lags', lags);  
            data_corr = obj.corr_data;
        end
        
        function [N,edges] = binChannel(obj, channel_num, bin_width)
            if isempty(channel_num)
                dat = obj.data(:, 2);
            else
                dat = obj.channel_data{channel_num+1};
            end
            tag_range = range(dat);
            num_bins = round(tag_range/bin_width);
            time_bins = linspace(dat(1), dat(end), num_bins);
            [N,edges] = histcounts(dat,time_bins);
            
            %plot(edges, N);
            
        end
        
        
    end
    
    
end