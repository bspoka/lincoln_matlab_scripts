function saveSettings(settings, filename)
% Saves the settings structure to filename
%
%    Input:
%     settings   - settings structure of the program (usually
%                  handles.settings)
%     filename   - path+file to be saved
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

% Default is the usual default settings folder
if nargin<2
    filename = fullfile(pwd,'calls','stateSettings','default.settings');
end

save(filename,'settings'); % Save file
