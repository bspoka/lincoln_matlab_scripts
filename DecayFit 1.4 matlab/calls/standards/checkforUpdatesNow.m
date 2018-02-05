function checkforUpdatesNow(handles, checkURL)
% Checks for updates now. Callback for check for updates now.. in the help
% menu of the GUI.
%
%    Input:
%     handles   - handles structure of the main window. Must contain fields
%                 name, version, and website
%     checkURL  - URL to check for latest software version
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

name = handles.name; % Current version of software
CurrentVersion = handles.version; % Current version of software
website = handles.website; % Software's website

% Check for updates.
hWaitbar = mywaitbar(0,'Checking for updates...', 'name', name);
[LatestVersion,URLstatus] = urlread(checkURL); % Returns the latest version html as a string. 'Timeout',5 is only implemented from R2013
try delete(hWaitbar), end

if URLstatus == 0
    
    mymsgbox('Could not connect to server.')

elseif URLstatus~=0 && str2double(CurrentVersion)<str2double(LatestVersion) % If current version is older than newest version
    % Open update dialog
    choice = myquestdlg(sprintf(...
        'Wohoo! There is a newer version of %s available:\n\n  Current version: %s\n  Latest version:  %s\n',name, CurrentVersion, LatestVersion), ...
        'Update available', ...
        ' Go to website ',' Go to website ');
    
    % Handle response
    if isempty(choice)
        return
        
    elseif strcmpi(choice,' Go to website ')
        
        try
            state = web(website,'-browser'); % try opening the url in the default browser
            if state~=0 % If unsuccessfull
                mymsgbox(sprintf('Internet action unsuccessful. Open page manually in your browser:\n\n%s',website))
            end
            
        catch err % If there was an error trying to open browser
            mymsgbox(sprintf('Internet action unsuccessful. Open page manually in your browser:\n\n%s',website))
        end
    end
    
elseif URLstatus~=0 && str2double(CurrentVersion)>=str2double(LatestVersion) % If current version is older than newest version

    mymsgbox(sprintf('Wohoo! You already have the latest version of %s...',name))

end
