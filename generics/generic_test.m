clear;
fpath  = 'C:\Users\bspoka\Google Drive\Lincoln_Data\Sophie_Boris\2017\10\171030\inas_onFringe_Dither_stream.hdf5';
inst = PhotonRecordsFileClass(fpath);

a = inst.readDataChunk(1000, Inf);

%%
resltn = inst.readResolution();

%%
clear;
fpath  = 'C:\Users\bspoka\Google Drive\h-BN_Boris_Hendrik\Hendrik\171214_hBN_sparse_sample_4K\defect3_g2.ht3';
inst = PhotonRecordsFileClass(fpath);
a = inst.readDataChunk(10, 100000);


%%
addpath(genpath('C:\Users\bspoka\Google Drive\Lincoln_Data\Sophie_Boris\Matlab_Scripts'))
clear;
fpath  = 'C:\Users\bspoka\Google Drive\Lincoln_Data\Sophie_Boris\Matlab_Scripts\generics\inas_1360nm_g2_stream.ptu';
inst = PhotonRecordsFileClass(fpath);
inst.readAllData;