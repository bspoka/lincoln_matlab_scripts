classdef PTUFileClass < PhotonRecordsFileClass
    
    properties
        record_type RecordType
        file_path
        header
        header_size
        photons_filename
    end
    
    methods 
        function obj = PTUFileClass(file_path)
            if nargin > 0
                obj.file_path = file_path;
                obj.readPTUHeader();
                obj.getRecordType();
            end
        end
    end
    
    methods (Access = protected)
        
     function record_type = getRecordType(obj) 
         record_type = RecordType.PTU;
         obj.record_type  = record_type;
     end
     
     function data = readData(obj, start_position, data_length, prompt_overwrite)
         [PATHSTR,NAME,~] = fileparts(obj.file_path);
         obj.photons_filename = fullfile(PATHSTR, strcat(NAME, '.photons'));
         
         if ~exist(obj.photons_filename, 'file')
             obj.PTUtoDotPhotons();
         else
             if prompt_overwrite
                 button = questdlg('Replace existing .photons file?');
                 if strcmp(button, 'Yes')
                     obj.PTUtoDotPhotons();
                 end
             else
                 obj.PTUtoDotPhotons();
             end
         end     
         true_photons = readDotPhotonsFile(obj, obj.photons_filename,...
             start_position, data_length);
         data = PhotonDataClass();
         data.Channels = true_photons(1, :);
         data.Syncs = true_photons(2, :);
         data.Times = true_photons(3, :);
         
     end
      
     function meta = readMetadataByName(obj, meta_name)
            switch meta_name
                case PicoQHeader.Resolution
                    meta = obj.header.MeasDesc_Resolution*1E12; %resolution in ps
                case PicoQHeader.SyncRate
                     meta = obj.header.TTResult_SyncRate;
                otherwise
                    meta = [];
            end               
     end
     
    end
    
    methods (Access = private)
        function readPTUHeader(obj)
            obj.header=struct();
            
            tyEmpty8      = hex2dec('FFFF0008');
            tyBool8       = hex2dec('00000008');
            tyInt8        = hex2dec('10000008');
            tyBitSet64    = hex2dec('11000008');
            tyColor8      = hex2dec('12000008');
            tyFloat8      = hex2dec('20000008');
            tyTDateTime   = hex2dec('21000008');
            tyFloat8Array = hex2dec('2001FFFF');
            tyAnsiString  = hex2dec('4001FFFF');
            tyWideString  = hex2dec('4002FFFF');
            tyBinaryBlob  = hex2dec('FFFFFFFF');
            % RecordTypes
                   
            fid = fopen(obj.file_path, 'r');
            Magic = fread(fid, 8, '*char');
            if not(strcmp(Magic(Magic~=0)','PQTTTR'))
                error('Magic invalid, this is not an PTU file.');
            end
            Version = fread(fid, 8, '*char');
            while 1
                % read Tag Head
                TagIdent = fread(fid, 32, '*char'); % TagHead.Ident
                TagIdent = (TagIdent(TagIdent ~= 0))'; % remove #0 and more more readable
                TagIdx = fread(fid, 1, 'int32');    % TagHead.Idx
                TagTyp = fread(fid, 1, 'uint32');   % TagHead.Typ
                % TagHead.Value will be read in the
                % right type function
                if TagIdx > -1
                    EvalName = [TagIdent '(' int2str(TagIdx + 1) ')'];
                else
                    EvalName = TagIdent;
                end
                EvalName = regexprep(EvalName, '(', '_');
                EvalName = regexprep(EvalName, ')', '');

                %fprintf(1,'\n   %-40s', EvalName);
                % check Typ of Header
                switch TagTyp
                    case tyEmpty8
                        fread(fid, 1, 'int64');
                        obj.header.(EvalName) = '<Empty>';
                    case tyBool8
                        TagInt = fread(fid, 1, 'int64');
                        if TagInt==0
                            obj.header.(EvalName) = false;
                        else
                            obj.header.(EvalName) = false;
                        end
                    case tyInt8
                        TagInt = fread(fid, 1, 'int64');
                        obj.header.(EvalName) = TagInt;
                    case tyBitSet64
                        TagInt = fread(fid, 1, 'int64');
                        obj.header.(EvalName) = TagInt;
                    case tyColor8
                        TagInt = fread(fid, 1, 'int64');
                        obj.header.(EvalName) = TagInt;
                    case tyFloat8
                        TagFloat = fread(fid, 1, 'double');
                        obj.header.(EvalName) = TagFloat;
                    case tyFloat8Array
                        TagInt = fread(fid, 1, 'int64');
                        obj.header.(EvalName) = TagInt;
                        fseek(fid, TagInt, 'cof');
                    case tyTDateTime
                        TagFloat = fread(fid, 1, 'double');
                        obj.header.(EvalName) = datestr(datenum(1899,12,30)+TagFloat);
                    case tyAnsiString
                        TagInt = fread(fid, 1, 'int64');
                        TagString = fread(fid, TagInt, '*char');
                        TagString = (TagString(TagString ~= 0))';
                        if TagIdx > -1
                           EvalName = [TagIdent '{' int2str(TagIdx + 1) '}'];
                        end
                        obj.header.(EvalName) = TagString;
                    case tyWideString
                        % Matlab does not support Widestrings at all, just read and
                        % remove the 0's (up to current (2012))
                        TagInt = fread(fid, 1, 'int64');
                        TagString = fread(fid, TagInt, '*char');
                        TagString = (TagString(TagString ~= 0))';
                        if TagIdx > -1
                            EvalName = [TagIdent '{' int2str(TagIdx + 1) '}'];
                        end
                        obj.header.(EvalName) = TagString;
                    case tyBinaryBlob
                        TagInt = fread(fid, 1, 'int64');
                        obj.header.(EvalName) = TagInt;
                        fseek(fid, TagInt, 'cof');
                    otherwise
                        error('Illegal Type identifier found! Broken file?');
                end
                if strcmp(TagIdent, 'Header_End')
                    break
                end
            end
            obj.header_size = ftell(fid);
            fclose(fid);         
        end
        
        function PTUtoDotPhotons(obj)
            % RecordTypes
            rtPicoHarpT3     = hex2dec('00010303');% (SubID = $00 ,RecFmt: $01) (V1), T-Mode: $03 (T3), HW: $03 (PicoHarp)
            rtPicoHarpT2     = hex2dec('00010203');% (SubID = $00 ,RecFmt: $01) (V1), T-Mode: $02 (T2), HW: $03 (PicoHarp)
            rtHydraHarpT3    = hex2dec('00010304');% (SubID = $00 ,RecFmt: $01) (V1), T-Mode: $03 (T3), HW: $04 (HydraHarp)
            rtHydraHarpT2    = hex2dec('00010204');% (SubID = $00 ,RecFmt: $01) (V1), T-Mode: $02 (T2), HW: $04 (HydraHarp)
            rtHydraHarp2T3   = hex2dec('01010304');% (SubID = $01 ,RecFmt: $01) (V2), T-Mode: $03 (T3), HW: $04 (HydraHarp)
            rtHydraHarp2T2   = hex2dec('01010204');% (SubID = $01 ,RecFmt: $01) (V2), T-Mode: $02 (T2), HW: $04 (HydraHarp)
            
            switch obj.header.TTResultFormat_TTTRRecType
                case rtPicoHarpT3
                    fprintf(1,'PicoHarp T3 data\n');
                    obj.ReadPT3;
                case rtPicoHarpT2
                    fprintf(1,'PicoHarp T2 data\n');
                    %obj.ReadPT2;
                case rtHydraHarpT3
                    fprintf(1,'HydraHarp V1 T3 data\n');
                    %ReadHT3(1);
                case rtHydraHarpT2
                    fprintf(1,'HydraHarp V1 T2 data\n');
                    %ReadHT2(1);
                case {rtHydraHarp2T3}
                    fprintf(1,'HydraHarp V2 T3 data\n');
                    obj.ReadHT3(2);
                case {rtHydraHarp2T2}
                    fprintf(1,'HydraHarp V2 T2 data\n');
                    ReadHT2(2);
                otherwise
                    error('Illegal RecordType!');
            end
           
        end
        
        %% Read PicoHarp T3
        function ReadPT3(obj)
            batch_length = 1E6;
            fid=fopen(obj.file_path, 'r');
            fseek(fid, obj.header_size, 'bof');
            photon_fid = fopen(obj.photons_filename, 'w');
            true_photons = zeros(3, batch_length);
            disp('Converting .PTU database to a .photons file...');

            ofltime = 0;
            WRAPAROUND=65536;
            k = 1;
            for i=1:obj.header.TTResult_NumberOfRecords
                RecNum = i;
                T3Record = fread(fid, 1, 'ubit32');     % all 32 bits:
                %   +-------------------------------+  +-------------------------------+
                %   |x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|  |x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|
                %   +-------------------------------+  +-------------------------------+
                nsync = bitand(T3Record,65535);       % the lowest 16 bits:
                %   +-------------------------------+  +-------------------------------+
                %   | | | | | | | | | | | | | | | | |  |x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|
                %   +-------------------------------+  +-------------------------------+
                chan = bitand(bitshift(T3Record,-28),15);   % the upper 4 bits:
                %   +-------------------------------+  +-------------------------------+
                %   |x|x|x|x| | | | | | | | | | | | |  | | | | | | | | | | | | | | | | |
                %   +-------------------------------+  +-------------------------------+
                truensync = ofltime + nsync;
                if (chan >= 1) && (chan <=4)
                    dtime = bitand(bitshift(T3Record,-16),4095);
                    %GotPhoton(truensync, chan, dtime);  % regular count at Ch1, Rt_Ch1 - Rt_Ch4 when the router is enabled
                    true_photons(:, k) = [chan, truensync, dtime];
                    k =  k+1;
                    if k > batch_length 
                        fwrite(photon_fid, true_photons, 'uint64');
                        true_photons = zeros(3, batch_length);
                        k = 1;
                    end
                else
                    if chan == 15 % special record
                        markers = bitand(bitshift(T3Record,-16),15); % where these four bits are markers:
                        %   +-------------------------------+  +-------------------------------+
                        %   | | | | | | | | | | | | |x|x|x|x|  | | | | | | | | | | | | | | | | |
                        %   +-------------------------------+  +-------------------------------+
                        if markers == 0                           % then this is an overflow record
                            ofltime = ofltime + WRAPAROUND;         % and we unwrap the numsync (=time tag) overflow
                            %GotOverflow(1);
                        else                                    % if nonzero, then this is a true marker event
                            %GotMarker(truensync, markers);
                        end
                    else
                        fprintf(fpout,'Err ');
                    end
                end
            end
            
            if k > 1
                fwrite(photon_fid, true_photons(:, 1:k-1), 'uint64');
            end
            fclose(photon_fid);
            fclose(fid);
        end
        
        function ReadPT2(obj)
            batch_length = 1E6;
            fid=fopen(obj.file_path, 'r');
            fseek(fid, obj.header_size, 'bof');
            photon_fid = fopen(obj.photons_filename, 'w');
            true_photons = zeros(2, batch_length);
            disp('Converting .PTU database to a .photons file...');
            ofltime = 0;
            WRAPAROUND=210698240;
            
            k = 1;
            for i=1:obj.header.TTResult_NumberOfRecords
                RecNum = i;
                T2Record = fread(fid, 1, 'ubit32');
                T2time = bitand(T2Record,268435455);             %the lowest 28 bits
                chan = bitand(bitshift(T2Record,-28),15);      %the next 4 bits
                timetag = T2time + ofltime;
                if (chan >= 0) && (chan <= 4)
                    true_photons(:, k) = [chan, timetag];
                    k =  k+1;
                    if k > batch_length 
                        fwrite(photon_fid, true_photons, 'uint64');
                        true_photons = zeros(2, batch_length);
                        k = 1;
                    end
                else
                    if chan == 15
                        markers = bitand(T2Record,15);  % where the lowest 4 bits are marker bits
                        if markers==0                   % then this is an overflow record
                            ofltime = ofltime + WRAPAROUND; % and we unwrap the time tag overflow
                            %GotOverflow(1);
                        else                            % otherwise it is a true marker
                            %GotMarker(timetag, markers);
                        end
                    else
                        fprintf(fpout,'Err');
                    end
                end
                % Strictly, in case of a marker, the lower 4 bits of time are invalid
                % because they carry the marker bits. So one could zero them out.
                % However, the marker resolution is only a few tens of nanoseconds anyway,
                % so we can just ignore the few picoseconds of error.
            end
            
             if k > 1
                fwrite(photon_fid, true_photons(:, 1:k-1), 'uint64');
            end
            fclose(photon_fid);
            fclose(fid);
        end
        
        function ReadHT3(obj, Version)
            batch_length = 1E6;
            fid=fopen(obj.file_path, 'r');
            fseek(fid, obj.header_size, 'bof');
            photon_fid = fopen(obj.photons_filename, 'w');
            true_photons = zeros(3, batch_length);
            disp('Converting .PTU database to a .photons file...');
            OverflowCorrection = 0;
            T3WRAPAROUND = 1024;
            
            k = 1;
            for i = 1:obj.header.TTResult_NumberOfRecords
                RecNum = i;
                T3Record = fread(fid, 1, 'ubit32');     % all 32 bits:
                %   +-------------------------------+  +-------------------------------+
                %   |x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|  |x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|
                %   +-------------------------------+  +-------------------------------+
                nsync = bitand(T3Record,1023);       % the lowest 10 bits:
                %   +-------------------------------+  +-------------------------------+
                %   | | | | | | | | | | | | | | | | |  | | | | | | |x|x|x|x|x|x|x|x|x|x|
                %   +-------------------------------+  +-------------------------------+
                dtime = bitand(bitshift(T3Record,-10),32767);   % the next 15 bits:
                %   the dtime unit depends on "Resolution" that can be obtained from header
                %   +-------------------------------+  +-------------------------------+
                %   | | | | | | | |x|x|x|x|x|x|x|x|x|  |x|x|x|x|x|x| | | | | | | | | | |
                %   +-------------------------------+  +-------------------------------+
                channel = bitand(bitshift(T3Record,-25),63);   % the next 6 bits:
                %   +-------------------------------+  +-------------------------------+
                %   | |x|x|x|x|x|x| | | | | | | | | |  | | | | | | | | | | | | | | | | |
                %   +-------------------------------+  +-------------------------------+
                special = bitand(bitshift(T3Record,-31),1);   % the last bit:
                %   +-------------------------------+  +-------------------------------+
                %   |x| | | | | | | | | | | | | | | |  | | | | | | | | | | | | | | | | |
                %   +-------------------------------+  +-------------------------------+
                
                if special == 0   % this means a regular input channel
                    true_nSync = OverflowCorrection + nsync;
                    %  one nsync time unit equals to "syncperiod" which can be
                    %  calculated from "SyncRate"
                    true_photons(:, k) = [channel, true_nSync, dtime];
                    k =  k+1;
                    if k > batch_length 
                        fwrite(photon_fid, true_photons, 'uint64');
                        true_photons = zeros(3, batch_length);
                        k = 1;
                    end
                else    % this means we have a special record
                    if channel == 63  % overflow of nsync occured
                        if (nsync == 0) || (Version == 1) % if nsync is zero it is an old style single oferflow or old Version
                            OverflowCorrection = OverflowCorrection + T3WRAPAROUND;
                            %GotOverflow(1);
                        else         % otherwise nsync indicates the number of overflows - THIS IS NEW IN FORMAT V2.0
                            OverflowCorrection = OverflowCorrection + T3WRAPAROUND * nsync;
                            %GotOverflow(nsync);
                        end
                    end
                    if (channel >= 1) && (channel <= 15)  % these are markers
                        true_nSync = OverflowCorrection + nsync;
                        %GotMarker(true_nSync, channel);
                    end
                end
            end
            if k > 1
                fwrite(photon_fid, true_photons(:, 1:k-1), 'uint64');
            end
            fclose(photon_fid);
            fclose(fid);
        end
        
        function ReadHT2(obj, Version)
            batch_length = 1E6;
            fid=fopen(obj.file_path, 'r');
            fseek(fid, obj.header_size, 'bof');
            photon_fid = fopen(obj.photons_filename, 'w');
            true_photons = zeros(2, batch_length);
            disp('Converting .PTU database to a .photons file...');
            
            OverflowCorrection = 0;
            T2WRAPAROUND_V1=33552000;
            T2WRAPAROUND_V2=33554432; % = 2^25  IMPORTANT! THIS IS NEW IN FORMAT V2.0
            
            k = 1;
            for i=1:obj.header.TTResult_NumberOfRecords
                RecNum = i;
                T2Record = fread(fid, 1, 'ubit32');     % all 32 bits:
                %   +-------------------------------+  +-------------------------------+
                %   |x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|  |x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|
                %   +-------------------------------+  +-------------------------------+
                dtime = bitand(T2Record,33554431);   % the last 25 bits:
                %   +-------------------------------+  +-------------------------------+
                %   | | | | | | | |x|x|x|x|x|x|x|x|x|  |x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|
                %   +-------------------------------+  +-------------------------------+
                channel = bitand(bitshift(T2Record,-25),63);   % the next 6 bits:
                %   +-------------------------------+  +-------------------------------+
                %   | |x|x|x|x|x|x| | | | | | | | | |  | | | | | | | | | | | | | | | | |
                %   +-------------------------------+  +-------------------------------+
                special = bitand(bitshift(T2Record,-31),1);   % the last bit:
                %   +-------------------------------+  +-------------------------------+
                %   |x| | | | | | | | | | | | | | | |  | | | | | | | | | | | | | | | | |
                %   +-------------------------------+  +-------------------------------+
                % the resolution in T2 mode is 1 ps  - IMPORTANT! THIS IS NEW IN FORMAT V2.0
                timetag = OverflowCorrection + dtime;
                if special == 0   % this means a regular photon record
                    true_photons(:, k) = [channel+1, timetag];
                    k =  k+1;
                    if k > batch_length 
                        fwrite(photon_fid, true_photons, 'uint64');
                        true_photons = zeros(3, batch_length);
                        k = 1;
                    end
                else    % this means we have a special record
                    if channel == 63  % overflow of dtime occured
                        if Version == 1
                            OverflowCorrection = OverflowCorrection + T2WRAPAROUND_V1;
                            %GotOverflow(1);
                        else
                            if(dtime == 0) % if dtime is zero it is an old style single oferflow
                                OverflowCorrection = OverflowCorrection + T2WRAPAROUND_V2;
                                %GotOverflow(1);
                            else         % otherwise dtime indicates the number of overflows - THIS IS NEW IN FORMAT V2.0
                                OverflowCorrection = OverflowCorrection + T2WRAPAROUND_V2 * dtime;
                                %GotOverflow(dtime);
                            end
                        end
                    end
                    if channel == 0  % Sync event
                        true_photons(:, k) = [channel, timetag];
                        k =  k+1;
                        if k > batch_length
                            fwrite(photon_fid, true_photons, 'uint64');
                            true_photons = zeros(3, batch_length);
                            k = 1;
                        end
                    end
                    if (channel >= 1) && (channel <= 15)  % these are markers
                        %GotMarker(timetag, channel);
                    end
                end
            end
            
            if k > 1
                fwrite(photon_fid, true_photons(:, 1:k-1), 'uint64');
            end
            fclose(photon_fid);
            fclose(fid);
        end
        
        
        function true_photons = readDotPhotonsFile(obj, photons_filename, start_position, data_length)
            photon_fid = fopen(photons_filename, 'r');
            if isempty(start_position)
                start_position = 0;
            end
            if isempty(data_length)
                data_length = Inf;
            end
            
            switch obj.header.Measurement_Mode
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

    