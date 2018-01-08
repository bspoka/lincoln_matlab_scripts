clear all;
addpath(genpath('C:\Users\bspoka\Google Drive\Lincoln_Data\Sophie_Boris\Matlab_Scripts'));
%%%-------------------FTP Settings-------------------%%%
ll_server = 'ftp.ll.mit.edu';
ll_login = 'anonymous';
ll_password = 'shnekElefant';
ll_root = '/outgoing/Sophie_Boris';
ftp_listing_file = 'ftp_listing.xlsx'; %should be in ll_root
%%%--------------------------------------------------%%%

%%retrieve ftp_listing.xlsx into current directory
ll_ftp_handle = ftp(ll_server, ll_login, ll_password);
pasv(ll_ftp_handle)
cd(ll_ftp_handle, ll_root);
mget(ll_ftp_handle, ftp_listing_file, pwd);
disp(ll_ftp_handle);
close(ll_ftp_handle);

%% Copy all files from directories in the ftp_listing to a local folder

copy_directory = pwd; %default is current directory
[~,~, ftp_listing] = xlsread(ftp_listing_file);

ll_ftp_handle = ftp(ll_server, ll_login, ll_password);
pasv(ll_ftp_handle)
cd(ll_ftp_handle, ll_root);
for ind = 2:size(ftp_listing, 1)
    
    folder_name = num2str(ftp_listing{ind, 1});
    if strcmp(folder_name,  'NaN')
    else
        file_ind = 0;
        cd(ll_ftp_handle, strcat(ll_root, '/', folder_name));
        file_name = num2str(ftp_listing{ind+file_ind, 2});
        while ~strcmp(file_name, 'NaN') && ((ind+file_ind) <= size(ftp_listing, 1))
            fprintf(strcat('Transferring: \t', file_name));
            copy_path = fullfile(copy_directory, folder_name);
            try
                mget(ll_ftp_handle, file_name, copy_path);
                fprintf('\t Success! \n');
            catch
                fprintf('\t FAIL! \n');
            end
            
            file_ind = file_ind+1;
            try
                file_name = num2str(ftp_listing{ind+file_ind, 2});
            catch
            end

        end
    end
end
close(ll_ftp_handle);