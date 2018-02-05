function savedataTemplate(handles, data)
% Saves data-structure to a file to be used as template when importing data
%
%    Input:
%     handles   - handles structure of the main window
%     data      - template data structure
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

try % Delete data
    dataTemplate = data(end);
    dataTemplate.data = [];
    dataTemplate.rawdata = [];
    dataTemplate.name = '';
end

% Sort fields
dataTemplate = orderfields(dataTemplate);

try
    % Save file with settings structure
    dataTemplateFile = fullfile(handles.workdir,'calls','stateSettings','data.template');
    save(dataTemplateFile,'dataTemplate');
catch err
    fprintf('Error when trying to save default data template:\n\n %s',err.message)
end
