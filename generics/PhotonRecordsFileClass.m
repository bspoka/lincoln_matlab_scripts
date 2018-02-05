classdef PhotonRecordsFileClass < handle
    
    properties
        delegate
    end
    
    methods
         %%Constructor
         function obj = PhotonRecordsFileClass(file_path)
             if nargin > 0
                 [~,~,EXT] = fileparts(file_path);
                 switch EXT
                     case {'.h5', '.hdf5', '.H5', '.HDF5'}
                         obj.delegate = H5StreamFileClass(file_path);
                     case {'.ht3'; '.HT3'}
                         obj.delegate = HT3FileClass(file_path);
                     case {'.ptu'; '.PTU'}
                         obj.delegate = PTUFileClass(file_path);
                     otherwise
                         obj.delegate = PhotonRecordsFileClass();
                 end
             end
         end
         
         %public function returns all data
         function data = readAllData(obj)
             %data -- returned PhotonDataClass object with all data 
             prompt_overwrite = true;
             data = obj.delegate.readData([], [], prompt_overwrite);
         end
         
         function convertToPhotonsFile(obj)
             %data -- returned PhotonDataClass object with all data 
             prompt_overwrite = false;
             obj.delegate.readData(1, 1, prompt_overwrite);
         end
         
          %public function returns a data chunk
         function data = readDataChunk(obj,  start_position, data_length)
             %start_position -- data start index or position
             %data_length -- length of the data entries to read
             %data -- returned PhotonDataClass object with a chunk ofdata
             data = obj.delegate.readData(start_position, data_length);
         end
         
         %read picoquant resolution
         function resltn = readResolution(obj)
             resltn = obj.delegate.readMetadataByName(PicoQHeader.Resolution);
         end
         
         %read picoquant sync rate
         function sync_rate = readSyncRate(obj)
             sync_rate = obj.delegate.readMetadataByName(PicoQHeader.SyncRate);
         end
         
         function tmode = readTMode(obj)
            tmode = obj.delegate.readMetadataByName(PicoQHeader.Mode);
         end
         
         
    end
    
    methods  (Access = protected)
        function  record_type = getRecordType(obj)
            %record type of RecordType enum
            record_type = RecordType.Generic;
        end
        
        %%delegate function for reading all photon data   
        function data = readData(obj, ~, ~, ~)
            data = PhotonDataClass();
        end
        %%delegate to read all of metadata
        function meta = readMetadataByName(obj, ~)
            meta = [];
        end
            
    end
    
    
end

