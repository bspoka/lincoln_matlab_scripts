classdef HT3FileClass < PhotonRecordsFileClass
    
    properties
        record_type RecordType
        file_path
        header
        header_size
    end
    
    methods 
        function obj = HT3FileClass(file_path)
            if nargin > 0
                obj.file_path = file_path;
                obj.readHT3Header();
                obj.getRecordType();
            end
        end
    end
    
    methods (Access = protected)
        
     function record_type = getRecordType(obj) 
         record_type = RecordType.HT3;
         obj.record_type  = record_type;
     end
     
     function data = readData(obj, start_position, data_length, prompt_overwrite)
         [PATHSTR,NAME,~] = fileparts(obj.file_path);
         photons_filename = fullfile(PATHSTR, strcat(NAME, '.photons'));
         
         if ~exist(photons_filename, 'file')
             obj.ht3toDotPhotons(photons_filename);
         else
             if prompt_overwrite
                 button = questdlg('Replace existing .photons file?');
                 if strcmp(button, 'Yes')
                     obj.ht3toDotPhotons(photons_filename);
                 end
             else
                 obj.ht3toDotPhotons(photons_filename);
             end
         end     
         true_photons = readDotPhotonsFile(obj, photons_filename, start_position, data_length);
         data = PhotonDataClass();
         data.Channels = true_photons(1, :);
         data.Syncs = true_photons(2, :);
         data.Times = true_photons(3, :);
         
     end
      
     function meta = readMetadataByName(obj, meta_name)
            switch meta_name
                case PicoQHeader.Resolution
                    meta = obj.header.Resolution;
                case PicoQHeader.SyncRate
                     meta = obj.header.SyncRate;
                otherwise
                    meta = [];
            end               
     end
     
    end
    
    methods (Access = private)
        function readHT3Header(obj)
            % read the ASCI and binary obj.header of the photon stream file
            % code adapted from Picoquant GmBH, Germany.
            
            fid=fopen(obj.file_path, 'r');
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %
            % ASCII file obj.header
            %
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            Ident = char(fread(fid, 16, 'char'));            
            FormatVersion = deblank(char(fread(fid, 6, 'char')'));                        
            CreatorName = char(fread(fid, 18, 'char'));            
            CreatorVersion = char(fread(fid, 12, 'char'));            
            FileTime = char(fread(fid, 18, 'char'));            
            CRLF = char(fread(fid, 2, 'char'));           
            Comment = char(fread(fid, 256, 'char'));
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %
            % Binary file obj.header
            %
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % The binary file obj.header information is indentical to that in HHD files.
            % Note that some items are not meaningful in the time tagging modes
            % therefore we do not output them.
            
            NumberOfCurves = fread(fid, 1, 'int32');
            BitsPerRecord = fread(fid, 1, 'int32');            
            ActiveCurve = fread(fid, 1, 'int32');          
            MeasurementMode = fread(fid, 1, 'int32');            
            SubMode = fread(fid, 1, 'int32');           
            Binning = fread(fid, 1, 'int32');            
            Resolution = fread(fid, 1, 'double');            
            Offset = fread(fid, 1, 'int32');            
            Tacq = fread(fid, 1, 'int32');
            StopAt = fread(fid, 1, 'uint32');
            StopOnOvfl = fread(fid, 1, 'int32');
            Restart = fread(fid, 1, 'int32');
            DispLinLog = fread(fid, 1, 'int32');
            DispTimeAxisFrom = fread(fid, 1, 'int32');
            DispTimeAxisTo = fread(fid, 1, 'int32');
            DispCountAxisFrom = fread(fid, 1, 'int32');
            DispCountAxisTo = fread(fid, 1, 'int32');
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            for i = 1:8
                DispCurveMapTo(i) = fread(fid, 1, 'int32');
                DispCurveShow(i) = fread(fid, 1, 'int32');
            end            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            for i = 1:3
                ParamStart(i) = fread(fid, 1, 'float');
                ParamStep(i) = fread(fid, 1, 'float');
                ParamEnd(i) = fread(fid, 1, 'float');
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%      
            RepeatMode = fread(fid, 1, 'int32');
            RepeatsPerCurve = fread(fid, 1, 'int32');
            Repaobjime = fread(fid, 1, 'int32');
            RepeatWaiobjime = fread(fid, 1, 'int32');
            ScriptName = char(fread(fid, 20, 'char'));
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %
            %          Hardware information obj.header
            %
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            
            HardwareIdent = char(fread(fid, 16, 'char'));
            HardwarePartNo = char(fread(fid, 8, 'char'));     
            HardwareSerial = fread(fid, 1, 'int32');            
            nModulesPresent = fread(fid, 1, 'int32');
            
            for i=1:10
                ModelCode(i) = fread(fid, 1, 'int32');
                VersionCode(i) = fread(fid, 1, 'int32');
            end
            
            BaseResolution = fread(fid, 1, 'double');            
            InputsEnabled = fread(fid, 1, 'ubit64');
            InpChansPresent  = fread(fid, 1, 'int32');            
            RefClockSource  = fread(fid, 1, 'int32');            
            ExtDevices  = fread(fid, 1, 'int32');            
            MarkerSeobjings  = fread(fid, 1, 'int32');
            SyncDivider = fread(fid, 1, 'int32');            
            SyncCFDLevel = fread(fid, 1, 'int32');            
            SyncCFDZeroCross = fread(fid, 1, 'int32');            
            SyncOffset = fread(fid, 1, 'int32');
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %
            %          Channels' information obj.header
            %
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            for i=1:InpChansPresent
                InputModuleIndex(i) = fread(fid, 1, 'int32');
                InputCFDLevel(i) = fread(fid, 1, 'int32');
                InputCFDZeroCross(i) = fread(fid, 1, 'int32');
                InputOffset(i) = fread(fid, 1, 'int32');
            end
                     
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %
            %                Time tagging mode specific obj.header
            %
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            for i=1:InpChansPresent
                InputRate(i) = fread(fid, 1, 'int32');
            end            
            SyncRate = fread(fid, 1, 'int32');            
            StopAfter = fread(fid, 1, 'int32');            
            StopReason = fread(fid, 1, 'int32');            
            ImgHdrSize = fread(fid, 1, 'int32');            
            nRecords = fread(fid, 1, 'uint64');
            
            % Special obj.header for imaging. How many of the following ImgHdr array elements
            % are actually present in the file is indicated by ImgHdrSize above.
            % Storage must be allocated dynamically if ImgHdrSize other than 0 is found.
            
            ImgHdr = fread(fid, ImgHdrSize, 'int32');  % You have to properly interpret ImgHdr if you want to generate an image
            
            % The obj.header section end after ImgHdr. Following in the file are only event records.
            % How many of them actually are in the file is indicated by nRecords in above.
            
            obj.header_size=ftell(fid); %obj.header size is current byte read in .ht3 file            
            %wrapping the obj.header info into a struct array for clarity.
            
            obj.header=struct();
            obj.header.('Ident')=Ident;
            obj.header.('FormatVersion')=FormatVersion;
            obj.header.('CreatorVersion')=CreatorVersion;
            obj.header.('Comment')=Comment;
            obj.header.('BitsPerRecord')=BitsPerRecord;
            obj.header.('FileTime')=FileTime;
            obj.header.('CRLF')=CRLF;
            obj.header.('NumberOfCurves')=NumberOfCurves;
            obj.header.('MeasurementMode')=MeasurementMode;
            obj.header.('SubMode')=SubMode;
            obj.header.('Binning')=Binning;
            obj.header.('Resolution')=Resolution;
            obj.header.('Offset')=Offset;
            obj.header.('Tacq')=Tacq;
            obj.header.('StopAt')=StopAt;
            obj.header.('StopOnOvfl')=StopOnOvfl;
            obj.header.('Restart')=Restart;
            obj.header.('DispLinLog')=DispLinLog;
            obj.header.('DispTimeAxisFrom')=DispTimeAxisFrom;
            obj.header.('DispTimeAxisTo')=DispTimeAxisTo;
            obj.header.('DispCountAxisFrom')=DispCountAxisFrom;
            obj.header.('HardwareIdent')=HardwareIdent;
            obj.header.('HardwarePartNo')=HardwarePartNo;
            obj.header.('HardwareSerial')=HardwareSerial;
            obj.header.('nModulesPresent')=nModulesPresent;
            obj.header.('BaseResolution')=BaseResolution;
            obj.header.('InputsEnabled')=InputsEnabled;
            obj.header.('InpChansPresent')=InpChansPresent;
            obj.header.('ExtDevices')=ExtDevices;
            obj.header.('RefClockSource')=RefClockSource;
            obj.header.('SyncDivider')=SyncDivider;
            obj.header.('SyncDivider')=SyncDivider;
            obj.header.('SyncCFDLevel')=SyncCFDLevel;
            obj.header.('SyncCFDZeroCross')=SyncCFDZeroCross;
            obj.header.('SyncOffset')=SyncOffset;
            obj.header.('SyncDivider')=SyncDivider;
            obj.header.('SyncDivider')=SyncDivider;
            obj.header.('SyncDivider')=SyncDivider;
            obj.header.('SyncRate')=SyncRate;
            obj.header.('nRecords')=nRecords;
            
            %Channels information obj.header.
            for i=1:InpChansPresent
                obj.header.(strcat('channel_',num2str(i)))=struct('InputModuleIndex',InputModuleIndex(i),'InputCFDLevel',InputCFDLevel(i),'InputCFDZeroCross',InputCFDZeroCross(i),'InputOffset',InputOffset(i));
            end
            
            fclose(fid);
            
        end
        
        function ht3toDotPhotons(obj, photons_filename)
            batch_length = 1E6;
            fid=fopen(obj.file_path, 'r');
            fseek(fid, obj.header_size, 'bof');
            photon_fid = fopen(photons_filename, 'w');
            disp('Converting .ht3 database to a .photons file...');
            switch obj.header.MeasurementMode
                case 2
                    cnt_OFL=0;                    %just counters
                    OverflowCorrection = 0;
                    T2WRAPAROUND=33554432;                              % = 2^25  IMPORTANT! THIS IS NEW IN FORMAT V2.0
                    true_photons = zeros(2, batch_length);
                    
                    while ~feof(fid)
                        batch=fread(fid,batch_length,'ubit32');%reading in a multiple of 32 bit registers
                        k=0;%true photon counting variable
                        for i=1:numel(batch)%looping over all records in batch
                            
                            %read and decode the 32 bit register of the ith record
                            dtime = bitand(batch(i),33554431);   % the last 25 bits:
                            channel = bitand(bitshift(batch(i),-25),63);   % the next 6 bits:
                            special = bitand(bitshift(batch(i),-31),1);   % the last bit:
                            truetime = OverflowCorrection + dtime;
                            
                            if special == 0   % this means a true 'photon' arrival event.
                                k=k+1;%counting the real photons that we see.
                                true_photons(:, k) = [channel, truetime];
                            else    % this means we have a special record; the 'record' is not a 'photon'
                                
                                if channel == 63  % overflow of dtime occured
                                    if(dtime==0) % if dtime is zero it is an old style single oferflow
                                        OverflowCorrection = OverflowCorrection + T2WRAPAROUND;
                                        cnt_OFL=cnt_OFL+1;
                                    else         % otherwise dtime indicates the number of overflows - THIS IS NEW IN FORMAT V2.0
                                        OverflowCorrection = OverflowCorrection + T2WRAPAROUND*dtime;
                                        cnt_OFL=cnt_OFL+dtime;
                                    end
                                end
                            end
                        end
                        fwrite(photon_fid, true_photons(:, 1:k), 'uint64');
                    end              
                case 3
                    OverflowCorrection = 0;
                    T3WRAPAROUND=1024;                                  %if overflow occured, the true n_sync is n_sync+1024
                    true_photons = zeros(3, batch_length);
                    
                    while ~feof(fid)
                        batch=fread(fid,batch_length,'ubit32');          %reading in a multiple of 32 bit registers
                        k=0;                                            %true photon counting variable
                        for i=1:numel(batch)                                 %looping over all records in batch
                            
                            %read and decode the 32 bit register of the ith record
                            nsync = bitand(batch(i),1023);                  %the lowest 10 bits of the ith photon
                            dtime = bitand(bitshift(batch(i),-10),32767);   %the next 15 bits
                            channel = bitand(bitshift(batch(i),-25),63);    %the next 6 bits:%0-4
                            special = bitand(bitshift(batch(i),-31),1);     %the last bit:% MSB - for overflow handling
                            
                            if special == 0                                 %this means a true 'photon' arrival event.
                                true_nSync = OverflowCorrection + nsync;
                                %one nsync time unit equals to "syncperiod" which can be calculated from "SyncRate"
                                time =dtime*obj.header.Resolution;
                                k=k+1;                                      %counting the real photons that we see.
                                true_photons(:, k) = [channel, true_nSync, time];
                                
                            else                                            %this means we have a special record; the 'record' is not a 'photon'
                                if channel == 63                            %overflow of nsync occured
                                    if(nsync==0)                            %if nsync is zero it is an old style single oferflow
                                        OverflowCorrection = OverflowCorrection + T3WRAPAROUND;
                                    else                                    %otherwise nsync indicates the number of overflows - THIS IS NEW IN FORMAT V2.0
                                        OverflowCorrection = OverflowCorrection + T3WRAPAROUND*nsync;
                                    end
                                end
                            end
                            
                        end
                        fwrite(photon_fid, true_photons(:, 1:k), 'uint64');
                    end

                otherwise
                    true_photons = [];
                    
            end
            disp('Done!');
            fclose(fid);
            fclose(photon_fid);

        end
        
        function true_photons = readDotPhotonsFile(obj, photons_filename, start_position, data_length)
            photon_fid = fopen(photons_filename, 'r');
            if isempty(start_position)
                start_position = 0;
            end
            if isempty(data_length)
                data_length = Inf;
            end
            
            switch obj.header.MeasurementMode
                 case 2
                     fseek(photon_fid, start_position*16, 'bof');
                     true_photons = double(fread(photon_fid, [2, data_length], 'uint64'));
                 case 3
                     fseek(photon_fid, start_position*24, 'bof');
                     true_photons = double(fread(photon_fid, [3, data_length], 'uint64'));
                 otherwise
                     true_photons = [];
            end
            fclose(photon_fid);
        end
        
        
    end
    
end

    