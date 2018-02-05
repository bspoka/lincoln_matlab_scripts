function updateGUImenus(handles)
% Updates checkmarks etc. in the GUI menus, depending on chosen settings.
%
%    Input:
%     handles   - handles structure of the main window
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

% Help menu
if handles.settings.startup.checkforUpdates==1
    set(handles.Help_CheckForUpdatesStartup, 'Checked','on')
else
    set(handles.Help_CheckForUpdatesStartup, 'Checked','off')
end
if handles.settings.close.sendstats==1
    set(handles.Help_SendUsageStats, 'Checked','on')
else
    set(handles.Help_SendUsageStats, 'Checked','off')
end

% View menu
if handles.settings.view.logscale
    set(handles.View_Logscale,'Checked','on')
else
    set(handles.View_Logscale,'Checked','off')
end

% % Disable some features if it's a deployed application
% if isdeployed
%     set(handles.Help_DevelopersMenu, 'Enable','Off', 'Label','For developers (enabled in MATLAB version)')
%     set(handles.File_ImportFromWorkspace, 'Enable','Off', 'Label','From MATLAB workspace (enabled in MATLAB version)')
%     set(handles.File_Export_Workspace, 'Enable','Off', 'Label','To MATLAB workspace (enabled in MATLAB version)')
% end
