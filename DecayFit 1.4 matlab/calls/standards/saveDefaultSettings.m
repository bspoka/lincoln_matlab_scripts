function saveDefaultSettings(mainhandles, settings)
% Saves the settings structure to a file located in stateSettings subfolder
%
%    Input:
%     mainhandles   - handles structure of the main window
%     settings      - default settings structure to save
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

% Default is the current settings structure
if nargin<2
    settings = mainhandles.settings;
end

% File to be saved
defaultSettingsFile = fullfile(mainhandles.workdir,'calls','stateSettings','default.settings'); 

% Saves settings structure to .mat file
saveSettings(settings, defaultSettingsFile) 

% update messageboard
set(mainhandles.mboard,'String',sprintf('Default settings saved to:\n%s\n',defaultSettingsFile)) 

