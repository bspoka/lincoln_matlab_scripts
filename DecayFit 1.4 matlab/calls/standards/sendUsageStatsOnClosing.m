function handles = sendUsageStatsOnClosing(handles)
% Callback for ticking whether to usage stats on closing in the help
% menu of the program
%
%    Input:
%     handles  - handles structures of the main window. Must have a field
%     with closing.sendstats and .workdir
%
%    Output:
%     handles  - ..
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

% Current defaults
settings_internal = internalSettingsStructure(); % Internal defaults
settings_default = loadDefaultSettings(handles, settings_internal); % Load default settings from file

% Update handles structure
if handles.settings.close.sendstats==0
    handles.settings.close.sendstats = 1;
    settings_default.close.sendstats = 1;
else
    handles.settings.close.sendstats = 0;
    settings_default.close.sendstats = 0;
end

% Update handles structures and default settings
updatemainhandles(handles)
updateGUImenus(handles)
defaultSettingsFile = fullfile(handles.workdir, 'calls', 'stateSettings', 'default.settings'); % File to be saved
saveSettings(settings_default, defaultSettingsFile) % Saves settings structure to file
