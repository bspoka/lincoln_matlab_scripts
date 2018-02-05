function [filename, pathname, filterindex] = uiputfile3(handles, fileID, FilterSpec, DialogTitle, DefaultName)
%UIPUTFILE3 Standard save file dialog box which remembers last opened folder
%   UIPUTFILE3 is a wrapper for Matlab's UIPUTFILE function which adds the
%   ability to remember the last folder opened.  UIPUTFILE3 stores
%   information about the last folder opened in a mat file which it looks
%   for when called.
%
%   UIPUTFILE3 can only remember the folder used if the current directory
%   is writable so that a mat file can be stored.  Only successful file
%   selections update the folder remembered.  If the user cancels the file
%   dialog box then the remembered path is left the same.
%
%   Input:
%    handles     - handles structure of the main window
%    fileID      - 'settings','session','data','results'...
%    FilterSpec  - file filter specification
%    DialogTitle - title of dialog box
%    DefaultName - default filename
%
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
if nargin<3
    FilterSpec = [];
end
if nargin<4
    DialogTitle = handles.name;
end
if nargin<5
    DefaultName = 'name';
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
end

% Open uiputfile
cd(lastDir); % load folder to open dialog box in
[filename, pathname, filterindex] = uiputfile(FilterSpec, DialogTitle, DefaultName); % call uigetfile with arguments passed from uigetfile2 function
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
