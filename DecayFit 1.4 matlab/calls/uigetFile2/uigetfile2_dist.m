function [filename, pathname, filterindex] = uigetfile2_dist(varargin)

%UIGETFILE2 Standard open file dialog box which remembers last opened folder
%   UIGETFILE2 is a wrapper for Matlab's UIGETFILE function which adds the
%   ability to remember the last folder opened.  UIGETFILE2 stores
%   information about the last folder opened in a mat file which it looks
%   for when called.
%
%   UIGETFILE2 can only remember the folder used if the current directory
%   is writable so that a mat file can be stored.  Only successful file
%   selections update the folder remembered.  If the user cancels the file
%   dialog box then the remembered path is left the same.
%
%   Usage is the same as UIGETFILE.
%
%
%   See also UIGETFILE, UIPUTFILE, UIGETDIR.
%
%   Written by Chris J Cannell and Aditya Gadre
%   Contact ccannell@mindspring.com for questions or comments.
%   12/05/2005
%
%
% --- Copyrights (C) ---
%
% This file is part of:
% DecayFit - Time-Resolved Fluorescence Decay Analysis Software
% Copyright (C) 2013  S�ren Preus, www.fluortools.com
%
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
%
%     The GNU General Public License is found at
%     <http://www.gnu.org/licenses/gpl.html>.

% name of mat file to save last used directory information
lastDirMat = fullfile(getappdata(0,'workdirDecayFit'),'calls','lastUsedDir','lastUsedDistDir.mat');

% save the present working directory
savePath = pwd;
% set default dialog open directory to the present working directory
lastDir = savePath;
% load last data directory
if exist(lastDirMat, 'file') ~= 0
    % lastDirMat mat file exists, load it
    load('-mat', lastDirMat)
    % check if lastDataDir variable exists and contains a valid path
    if (exist('lastUsedDir', 'var') == 1) && ...
            (exist(lastUsedDir, 'dir') == 7)
        % set default dialog open directory
        lastDir = lastUsedDir;
    end
    
    % check if lastUsedFile variable exists and contains a valid string
    if (exist('lastUsedFile', 'var') == 1) && ischar(lastUsedFile) && ...
            length(varargin)>=3
        % set default filename
        varargin{3} = lastUsedFile;
    end
end

% load folder to open dialog box in
cd(lastDir);
% call uigetfile with arguments passed from uigetfile2 function
[filename, pathname, filterindex] = uigetfile(varargin{:});
% change path back to original working folder
cd(savePath);

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
