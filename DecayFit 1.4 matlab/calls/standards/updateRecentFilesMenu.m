function updateRecentFilesMenu(mainhandles)
% Updates the recent files list in the main file menu
%
%     Input:
%      mainhandles   - handles structure of the main window
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

%% Initialize

% Delete previous menu items
prevh = get(mainhandles.File_RecentSessionsMenu, 'Children');
delete(prevh)
prevh = get(mainhandles.File_RecentFilesMenu, 'Children');
delete(prevh)

% Load recent files list
lastdirfile = fullfile(mainhandles.workdir,'calls','lastUsedDir','recentfiles.lastdir');

% Check existence
if exist(lastdirfile,'file')
    load(lastdirfile,'-mat');
else
    insertEmpty([mainhandles.File_RecentSessionsMenu mainhandles.File_RecentFilesMenu])
    return
end

% If there are no stored files
if (~exist('sessions','var') || ~exist('datafiles','var')) ...
        || (isempty(sessions) && isempty(datafiles))
    insertEmpty([mainhandles.File_RecentSessionsMenu mainhandles.File_RecentFilesMenu])
    return
end

%% Session files

if ~isempty(sessions)
    for i = 1:size(sessions,1)
        [path,filename,ext] = fileparts(sessions{i});
        
        mh = uimenu(mainhandles.File_RecentSessionsMenu,...
            'Label', filename,...
            'Callback', {@loadrecentfileCallback, 'session', mainhandles.figure1, sessions{i}} );
    end
    
else
    insertEmpty(mainhandles.File_RecentSessionsMenu)
end

%% Data files

if ~isempty(datafiles)

    for i = 1:size(datafiles,1)
        
        % First file
        [path,name,ext] = fileparts(datafiles{i,1});
        name = [name ext]; % Add suffix
        
        if size(datafiles,2)>1
            
            % If item i contains more than one file
            for j = 2:size(datafiles,2)
                if isempty(datafiles{i,j})
                    break
                end
                
                [path,filename,ext] = fileparts(datafiles{i,j});
                name = sprintf('%s; %s',name,[filename ext]);
            end
        end
        
        mh = uimenu(mainhandles.File_RecentFilesMenu,...
            'Label', name,...
            'Callback', {@loadrecentfileCallback, 'data', mainhandles.figure1, datafiles(i,:)} );
    end
    
else
    insertEmpty(mainhandles.File_RecentFilesMenu)
end

end

function insertEmpty(h)
% Insert a disabled menu item under h called 'empty'

for i = 1:length(h)
    mh = uimenu(h(i),...
        'Label', '<empty>',...
        'enable', 'off');
end

end