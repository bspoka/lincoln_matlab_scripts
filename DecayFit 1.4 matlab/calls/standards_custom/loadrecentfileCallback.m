function mainhandles = loadrecentfileCallback(hObject,event,type,mainhandle,file)
% Callback for loading a recent file from the file menu in the main window
%
%    Input:
%     hObject      - handle to the menu item
%     event        - eventdata
%     type         - 'session' 'data'
%     mainhandle   - handle to the main window
%     file         - fullfilepath. Cell array if type movie
%
%    Output:
%     mainhandles  - handles structure of the main window
%

% --- Copyrights (C) ---
%
% Copyright (C)  Søren Preus, Ph.D.
% http://www.fluortools.com
%
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
%
%     The GNU General Public License is found at
%     <http://www.gnu.org/licenses/gpl.html>.

% Get mainhandles structure
mainhandles = guidata(mainhandle);

if strcmpi(type,'session')
    
    % Check if session file exist
    if ~exist(file,'file')
        mymsgbox(sprintf('The filepath seems to be broken:\n\n   %s   \n\nYou must load the file manually.',file))
        return
    end
    
    % Load a recent session
    mainhandles = opensession(mainhandles,file);
    
elseif strcmpi(type,'data')
    
    % Check if files exist
    dir = fileparts(file{1,1});
    for i = 1:size(file,2)
        
        % Path to file
        filepath = file{1,i};
        if isempty(filepath)
            break
        end
        
        if ~exist(filepath,'file')
            mymsgbox(sprintf('There seems to be a broken filepath to:\n\n   %s   \n\nYou must load the file(s) manually.',filepath))
            return
        end
    end
    
    % Load a recent movie
    mainhandles = guidata(mainhandle);
    
    % Turn on waitbar
    if size(file,2)>1
        hWaitbar = mywaitbar(0,'Loading files. Please wait...','name','DecayFit');
    else
        hWaitbar = mywaitbar(0,'Loading file. Please wait...','name','DecayFit');
    end
    try setFigOnTop([]), end % Sets the waitbar so that it is always in front
    
    dir = fileparts(file{1,1});
    filenames = {};
    for i = 1:size(file,2)
        
        % Path to file
        filepath = file{1,i};
        if isempty(filepath)
            break
        end
        
        % Load file i
        loaddata(mainhandles,'abs',filepath);
        
        % Split path and name
        [~,NAME,EXT] = fileparts(filepath);
        filenames{1,i} = [NAME EXT];
        
        % Update waitbar
        waitbar(i/size(file,2))
    end
    
    % Update recent files list
    updateRecentFiles(mainhandles, dir, filenames, 'data');
    
    % Delete waitbar
    try delete(hWaitbar),end
end
