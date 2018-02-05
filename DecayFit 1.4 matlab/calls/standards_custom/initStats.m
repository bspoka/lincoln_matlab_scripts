function use = initStats()
% Initializes usage stats field
%
%    Input:
%     handles  - handles structure of the main window
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

if ismac
    m = [];
else
    m = memory;
end

use = struct(...
    'settings', [],...
    'computer', computer,...
    'memory', m,...
    'version', ver,...
    'HelpMenu_About', 0,...
    'Help_OnlineDocumentation', 0,...
    'Help_CheckUpdates', 0,...
    'Help_CheckForUpdatesStartup', 0,...
    'Help_Developers_SendHandles', 0,...
    'Help_Developers_mfile', 0,...
    'Help_Developers_figfile', 0);