function mainhandles = restoreInternalSettings(mainhandles)
% Restore all internal settings as defaults on startup
%
%     Input:
%      mainhandles  - handles structure of the main window
%
%     Output:
%      mainhandles  - ..
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

% Default settings filepath
defaultSettingsFile = fullfile(mainhandles.workdir,'calls','stateSettings','default.settings'); 

% Delete file
delete(defaultSettingsFile)

% Message box
mymsgbox(sprintf(['Internal settings are now restored as defaults. Changes will take effect from next startup.']))
