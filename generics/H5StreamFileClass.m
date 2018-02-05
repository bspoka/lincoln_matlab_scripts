classdef H5StreamFileClass < PhotonRecordsFileClass
    
    properties
        record_type RecordType
        fileinfo
        file_path
    end
    
    methods 
        function obj = H5StreamFileClass(h5_filepath)
            if nargin > 0
                obj.file_path = h5_filepath;
                obj.fileinfo = h5info(h5_filepath);
                obj.getRecordType();
            end
        end
    end
    
    methods (Access = protected)
        
     function record_type = getRecordType(obj) 
         record_type = RecordType.H5Stream;
         obj.record_type  = record_type;
     end
     
     %%Read a chunk of the hdf5 file data (reads columsn of the data)
     function data = readData(obj, start_position, data_length, prompt_overwrite)
            dset_size = obj.readH5DsetSize('photon_records');
            if ~isempty(start_position)
                if (start_position+data_length) > dset_size(1)
                    data_length = dset_size(1)-start_position;
                end
                start_inds = [start_position, 1];
                length_inds = [data_length, dset_size(2)];
                stride_inds = ones(1, 2);
            else
                start_inds = [];length_inds = []; stride_inds = [];
            end
                
            data = readH5PhotonStream(obj, '/photon_records', start_inds,...
                length_inds, stride_inds);
     end
     
     function meta = readMetadataByName(obj, meta_name)
            switch meta_name
                case PicoQHeader.Resolution
                    meta_string = 'resolution';
                case PicoQHeader.SyncRate
                     meta_string = 'sync_rate';
                case PicoQHeader.Mode
                     record_size = obj.readH5DsetSize('photon_records');
                     meta = record_size(2);
                     return;
                otherwise
                    meta_string = '';
            end
            
            index_cells = strfind({obj.fileinfo.Attributes.Name}, meta_string);
            meta_indx = find(not(cellfun('isempty', index_cells)), 1);
            if ~isempty(meta_indx)
                meta = (obj.fileinfo.Attributes(meta_indx).Value);
            else
                meta = [];
                fprintf('Specified attribute does not exist...\n');
            end
                
     end
     
    end
    
    methods (Access = private)
        function data = readH5PhotonStream(obj, dataset_name, start_index, data_length, data_stride)
            switch obj.record_type
                case RecordType.H5Stream
                    all_data = h5read(obj.file_path, dataset_name,...
                        start_index, data_length, data_stride); %[1, 1], [100, 3], [1, 1]
                    tmode = size(all_data, 2); %%T2 or T3
                    
                    data = PhotonDataClass();
                    if tmode == 2
                        data.Channels = all_data(:, 1);
                        data.Times = all_data(:, 2);
                    elseif tmode == 3
                        resolution = double(obj.readMetadataByName(PicoQHeader.Resolution));
                        data.Channels = all_data(:, 1);
                        data.Syncs = all_data(:, 2);
                        data.Times = all_data(:, 3).*resolution;
                    else
                        disp('Unrecognized photon_record mode (neither T2 or T3...)\n');
                    end
                otherwise
                    data = PhotonDataClass();
            end
        end
        
        %%retrives the size of a dataset by name
        function dset_size = readH5DsetSize(obj, dset_name)
            index_cells = strfind({obj.fileinfo.Datasets.Name}, dset_name);
            dset_indx = find(not(cellfun('isempty', index_cells)));
            if ~isempty(dset_indx)
                dset_size = obj.fileinfo.Datasets(dset_indx).Dataspace.Size;
            else
                fprintf(strcat(dset_name, 'dataset does not exist...\n'));
            end
        end
    end
    
end

    