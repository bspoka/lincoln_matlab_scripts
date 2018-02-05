function [settings_new, message, err] = loadSettings(settings_old, filepath)
% The settings structures must be structures with two children levels. E.g.
% settings.view.green = 1 and NOT settings.viewgreen = 1
%
%    Input:
%     settings_old    - current settings structure
%     filepath        - path to the settings structure to be loaded
%   
%    Output:
%     settings_new    - new settings structure with field values overwrited
%                      by the loaded settings file
%     message         - string displaying a potential warning
%

% --- Copyrights (C) ---
%
% Copyright (C)  Søren Preus, Ph.D.
% <http://www.fluortools.com>
%
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
%
%     The GNU General Public License is found at
%     <http://www.gnu.org/licenses/gpl.html>.

% Defaults
settings_new = settings_old;
message = '';
err = [];

try % Open default settings from file
    
    temp = load(filepath,'-mat'); % Open settings file at filepath
    
    % Load settings
    if ~isfield(temp,'settings')
        message = 'Incorrect settings file selected.';
        return
    end
    settings_loaded = temp.settings; % Loaded settings structure
    
    % Load
    settings_new = loadSettingsStructure(settings_old, settings_loaded);

catch err
    message = err.message;
end
