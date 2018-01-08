function ht3tohdf5(file_path)

buffer_size = 1E6;
[header, header_size] = get_ht3_v2_header(file_path);
[pathstr,name,~] = fileparts(file_path);

fid=fopen(file_path);                           %open the binary photon stream file
fseek(fid,header_size,'bof');                       %skip over the header to the photon data


hdf_file = fullfile(pathstr, strcat(name, '.hdf5')); %output hdf_file
h5create(hdf_file,'/header/sync_rate',1, 'Datatype', 'double');
h5write(hdf_file,'/header/sync_rate', header.SyncRate);
h5create(hdf_file,'/header/mode',1, 'Datatype', 'double');
h5write(hdf_file,'/header/mode', header.MeasurementMode);
h5create(hdf_file,'/header/binning',1, 'Datatype', 'double');
h5write(hdf_file,'/header/binning', header.Binning);
h5create(hdf_file,'/header/resolution',1, 'Datatype', 'double');
h5write(hdf_file,'/header/resolution', header.Resolution);
h5create(hdf_file,'/header/offset',1, 'Datatype', 'double');
h5write(hdf_file,'/header/offset', header.Offset);
h5create(hdf_file,'/header/tacq',1, 'Datatype', 'double');
h5write(hdf_file,'/header/tacq', header.Tacq);
h5create(hdf_file,'/header/sync_divider',1, 'Datatype', 'double');
h5write(hdf_file,'/header/sync_divider', header.SyncDivider);
h5create(hdf_file,'/header/base_resolution',1, 'Datatype', 'double');
h5write(hdf_file,'/header/base_resolution', header.BaseResolution);

switch header.MeasurementMode

    % reading in t3 data
    case 3
        h5create(hdf_file,'/photon_records',[1 Inf],'ChunkSize',[1 10000], 'Datatype', 'uint64');
        h5create(hdf_file,'/channels',[1 Inf],'ChunkSize',[1 10000],'Datatype', 'uint8');
        h5create(hdf_file,'/syncs',[1 Inf],'ChunkSize',[1 10000], 'Datatype', 'uint64');

        
        syncperiod = 1E9/header.SyncRate;                     %syncperiod in nanoseconds
        OverflowCorrection = 0;
        T3WRAPAROUND=1024;                                  %if overflow occured, the true n_sync is n_sync+1024
        true_photons=zeros(3,length(buffer_size));          %initialize an array to store true_photon records.
        total_photons = 1;
        while 1 %while true

            batch=fread(fid,buffer_size,'ubit32');          %reading in a multiple of 32 bit registers
            lbatch=length(batch);

            k=0;                                            %true photon counting variable
            for i=1:lbatch                                 %looping over all records in batch

                %read and decode the 32 bit register of the ith record
                nsync = bitand(batch(i),1023);                  %the lowest 10 bits of the ith photon
                dtime = bitand(bitshift(batch(i),-10),32767);   %the next 15 bits
                channel = bitand(bitshift(batch(i),-25),63);    %the next 6 bits:%0-4
                special = bitand(bitshift(batch(i),-31),1);     %the last bit:% MSB - for overflow handling

                if special == 0                                 %this means a true 'photon' arrival event.
                    true_nSync = OverflowCorrection + nsync;
                    %one nsync time unit equals to "syncperiod" which can be calculated from "SyncRate"
                    time =dtime*header.Resolution;
                    k=k+1;                                      %counting the real photons that we see.
                    true_photons(:,k)=[channel;true_nSync;time];%writing the true photon to an array.
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
            h5write(hdf_file,'/photon_records', uint64(true_photons(3,1:k)), [1, total_photons], [1,k]);
            h5write(hdf_file,'/channels', uint8(true_photons(1,1:k)), [1, total_photons], [1,k]);
            h5write(hdf_file,'/syncs', uint64(true_photons(2,1:k)), [1, total_photons], [1,k]);

            total_photons = total_photons+k;
            %fwrite(fpout,true_photons(:,1:k),'uint64');         %writing the true photons to the output file in binary.

            %break the while loop when we have reached the end of the
            %.ht3 file.
            if lbatch <buffer_size
                break
            end

        end
        fclose(fid);

        %% for t2 data
    case 2
        h5create(hdf_file,'/photon_records',[1 Inf],'ChunkSize',[1 10000], 'Datatype', 'uint64');
        h5create(hdf_file,'/channels',[1 Inf],'ChunkSize',[1 10000],'Datatype', 'uint8');

        cnt_OFL=0;                    %just counters
        OverflowCorrection = 0;
        T2WRAPAROUND=33554432;                              % = 2^25  IMPORTANT! THIS IS NEW IN FORMAT V2.0

        true_photons=zeros(2,length(buffer_size));          %initialize an array to store true_photon records.

        fid=fopen(file_path);%opdn the binary .ht2 file

        fseek(fid,header_size,'bof');%skip over the header to the photon data
        total_photons = 1;
        while 1 %while true

            batch=fread(fid,buffer_size,'ubit32');%reading in a multiple of 32 bit registers
            lbatch=length(batch);


            k=0;%true photon counting variable
            for i=1:lbatch%looping over all records in batch

                %read and decode the 32 bit register of the ith record
                dtime = bitand(batch(i),33554431);   % the last 25 bits:
                channel = bitand(bitshift(batch(i),-25),63);   % the next 6 bits:
                special = bitand(bitshift(batch(i),-31),1);   % the last bit:
                truetime = OverflowCorrection + dtime;

                if special == 0   % this means a true 'photon' arrival event.
                    k=k+1;%counting the real photons that we see.
                    true_photons(:,k)=[channel;truetime]; %writing the true photon to a binary array.

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
            h5write(hdf_file,'/photon_records', uint64(true_photons(3,1:k)), [1, total_photons], [1,k]);
            h5write(hdf_file,'/channels', uint8(true_photons(1,1:k)), [1, total_photons], [1,k]);
            total_photons = total_photons+k;


            %break the while loop when we have reached the end of the
            %.ht2 file.
            if lbatch <buffer_size
                break
            end

        end
        fclose(fid);
end

end


function [header, header_size] = get_ht3_v2_header(file_path)
% read the ASCI and binary header of the photon stream file
% code adapted from Picoquant GmBH, Germany.

fid=fopen(file_path, 'r');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% ASCII file header
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Ident = char(fread(fid, 16, 'char'));

FormatVersion = deblank(char(fread(fid, 6, 'char')'));

if not(strcmp(FormatVersion,'2.0'))
    fprintf(1,'\n\n      Warning: This program is for version 2.0 only. Aborted.');
    STOP;
end

CreatorName = char(fread(fid, 18, 'char'));

CreatorVersion = char(fread(fid, 12, 'char'));

FileTime = char(fread(fid, 18, 'char'));

CRLF = char(fread(fid, 2, 'char'));

Comment = char(fread(fid, 256, 'char'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Binary file header
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% The binary file header information is indentical to that in HHD files.
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
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i = 1:3
    ParamStart(i) = fread(fid, 1, 'float');
    ParamStep(i) = fread(fid, 1, 'float');
    ParamEnd(i) = fread(fid, 1, 'float');
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

RepeatMode = fread(fid, 1, 'int32');
RepeatsPerCurve = fread(fid, 1, 'int32');
Repaobjime = fread(fid, 1, 'int32');
RepeatWaiobjime = fread(fid, 1, 'int32');
ScriptName = char(fread(fid, 20, 'char'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%          Hardware information header
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


HardwareIdent = char(fread(fid, 16, 'char'));

HardwarePartNo = char(fread(fid, 8, 'char'));

HardwareSerial = fread(fid, 1, 'int32');

nModulesPresent = fread(fid, 1, 'int32');

for i=1:10
    ModelCode(i) = fread(fid, 1, 'int32');
    VersionCode(i) = fread(fid, 1, 'int32');
end;

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
%          Channels' information header
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
%                Time tagging mode specific header
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

% Special header for imaging. How many of the following ImgHdr array elements
% are actually present in the file is indicated by ImgHdrSize above.
% Storage must be allocated dynamically if ImgHdrSize other than 0 is found.

ImgHdr = fread(fid, ImgHdrSize, 'int32');  % You have to properly interpret ImgHdr if you want to generate an image

% The header section end after ImgHdr. Following in the file are only event records.
% How many of them actually are in the file is indicated by nRecords in above.

header_size=ftell(fid); %header size is current byte read in .ht3 file
fclose(fid);

%wrapping the header info into a struct array for clarity.

header=struct();
header.('Ident')=Ident;
header.('FormatVersion')=FormatVersion;
header.('CreatorVersion')=CreatorVersion;
header.('Comment')=Comment;
header.('BitsPerRecord')=BitsPerRecord;
header.('FileTime')=FileTime;
header.('CRLF')=CRLF;
header.('NumberOfCurves')=NumberOfCurves;
header.('MeasurementMode')=MeasurementMode;
header.('SubMode')=SubMode;
header.('Binning')=Binning;
header.('Resolution')=Resolution;
header.('Offset')=Offset;
header.('Tacq')=Tacq;
header.('StopAt')=StopAt;
header.('StopOnOvfl')=StopOnOvfl;
header.('Restart')=Restart;
header.('DispLinLog')=DispLinLog;
header.('DispTimeAxisFrom')=DispTimeAxisFrom;
header.('DispTimeAxisTo')=DispTimeAxisTo;
header.('DispCountAxisFrom')=DispCountAxisFrom;
header.('HardwareIdent')=HardwareIdent;
header.('HardwarePartNo')=HardwarePartNo;
header.('HardwareSerial')=HardwareSerial;
header.('nModulesPresent')=nModulesPresent;
header.('BaseResolution')=BaseResolution;
header.('InputsEnabled')=InputsEnabled;
header.('InpChansPresent')=InpChansPresent;
header.('ExtDevices')=ExtDevices;
header.('RefClockSource')=RefClockSource;
header.('SyncDivider')=SyncDivider;
header.('SyncDivider')=SyncDivider;
header.('SyncCFDLevel')=SyncCFDLevel;
header.('SyncCFDZeroCross')=SyncCFDZeroCross;
header.('SyncOffset')=SyncOffset;
header.('SyncDivider')=SyncDivider;
header.('SyncDivider')=SyncDivider;
header.('SyncDivider')=SyncDivider;
header.('SyncRate')=SyncRate;
header.('nRecords')=nRecords;

%Channels information header.
for i=1:InpChansPresent
    header.(strcat('channel_',num2str(i)))=struct('InputModuleIndex',InputModuleIndex(i),'InputCFDLevel',InputCFDLevel(i),'InputCFDZeroCross',InputCFDZeroCross(i),'InputOffset',InputOffset(i));
end

end
