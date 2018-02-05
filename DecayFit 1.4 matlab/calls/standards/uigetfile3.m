function [filename, pathname, filterindex] = uigetfile3(handles, fileID, FilterSpec, DialogTitle, DefaultName, MultiSelect)
%UIGETFILE3 Standard open file dialog box which remembers last opened folder
%   UIGETFILE3 is a wrapper for Matlab's UIGETFILE function which adds the
%   ability to remember the last folder opened.  UIGETFILE3 stores
%   information about the last folder opened in a mat file which it looks
%   for when called.
%
%   UIGETFILE3 can only remember the folder used if the current directory
%   is writable so that a mat file can be stored.  Only successful file
%   selections update the folder remembered.  If the user cancels the file
%   dialog box then the remembered path is left the same.
%
%   The information file is saved to:
%   handles.workdir/calls/lastUsedDir/fileID.lastdir
%
%   Input:
%    handles       - handles structure of the main window. Must contain a
%                    field name workdir
%    fileID        - 'settings','session','data','results',etc...
%    FilterSpec    - file filter specification. Default
%    DialogTitle   - title of dialog box. Default: handles.name
%    DefaultName   - default filename. Default: 'name'
%    MultiSelect   - 'on'/'off'. Default: 'off'
%

% --- Copyrights (C) ---
%
% Copyright (C) 2014  Søren Preus, FluorTools.com
%
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
%
%     The GNU General Public License is found at
%     <http://www.gnu.org/licenses/gpl.html>.


% Defaults
if nargin<3 || isempty(FilterSpec)
    FilterSpec = [];
end
if nargin<4 || isempty(DialogTitle)
    DialogTitle = handles.name;
end
if nargin<5 || isempty(DefaultName)
    DefaultName = 'name';
end
if nargin<6 || isempty(MultiSelect)
    MultiSelect = 'off';
end

% name of mat file to save last used directory information
lastDirMat = fullfile(handles.workdir, 'calls', 'lastUsedDir', sprintf('%s.lastdir',fileID));

% save the present working directory
savePath = pwd;

% set default dialog open directory to the present working directory
lastDir = savePath;

% load last data directory
if exist(lastDirMat, 'file') ~= 0

    % lastDirMat mat file exists, load it
    load('-mat', lastDirMat)
    
    % check if lastDataDir variable exists and contains a valid path
    if (exist('lastUsedDir', 'var')==1) && (exist(lastUsedDir, 'dir')==7)
        % set default dialog open directory
        lastDir = lastUsedDir;
    end
    
    % check if lastUsedFile variable exists and contains a valid string
    if exist('lastUsedFile', 'var')==1 && ischar(lastUsedFile)
        % set default filename
        DefaultName = lastUsedFile;
    end
end

% Call uigetfile
cd(lastDir); % load folder to open dialog box in
[filename, pathname, filterindex] = uigetfile(FilterSpec, DialogTitle, DefaultName, 'MultiSelect',MultiSelect); % call uigetfile with arguments passed from uigetfile2 function
cd(savePath); % change path back to original working folder

% if the user did not cancel the file dialog then update lastDirMat mat
% file with the folder used
if ~isequal(filename,0) && ~isequal(pathname,0)

    try
        % save last folder used to lastDirMat mat file
        lastUsedDir = pathname;
        lastUsedFile = filename;
        save(lastDirMat, 'lastUsedDir', 'lastUsedFile');
    catch
        % error saving lastDirMat mat file, display warning, the folder
        % will not be remembered
        disp(['Warning: Could not save file ''', lastDirMat, '''']);
    end
    
end
