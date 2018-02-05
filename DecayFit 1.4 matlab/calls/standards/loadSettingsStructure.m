function settings_new = loadSettingsStructure(settings_old, settings_loaded)
% Load settings structure
%
%    Input:
%     settings_old    - current settings structure
%     settings_loaded - settings structure to load
%
%    Output:
%     settings_new    - new settings structure
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

% Load settings. This will not delete any old_settings not defined
% in the loaded settings file.
loadedFields = fieldnames(settings_loaded); % Field names in loaded setting structure
possibleFields = fieldnames(settings_old); % Field names in current settings structure

% If the fields in the current settings structure and the loaded
% settings structure are not equal, output a warning
% if ~isequal(loadedFields,possibleFields)
%     message = sprintf('%s\n%s. %s %s\n ',...
%         'OBS!','The settings file contains a different number of settings than what the current software version has',...
%         'This is likely because the settings file was saved by a previous software version.',...
%         'Only those settings specified in the file are loaded from file. The rest are internal defaults.')
% end

% Start overwriting field values in the settings structure
for i = 1:numel(loadedFields)
    loadedFields2 = fieldnames(settings_loaded.(loadedFields{i})); % To level settings field names
    for j = 1:numel(loadedFields2)
        settings_old.(loadedFields{i}).(loadedFields2{j}) = settings_loaded.(loadedFields{i}).(loadedFields2{j}); % Bottom level settings field names
    end
end

% New settings
settings_new = settings_old;
