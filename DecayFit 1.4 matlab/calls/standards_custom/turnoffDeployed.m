function turnoffDeployed(handles)
% Turns off some features for the deployed version
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

if ~isdeployed
    return
end

s = get(handles.Help_DevelopersMenu,'Label');
set(handles.Help_DevelopersMenu,...
    'Enable','Off',...
    'Label', sprintf('%s (only MATLAB version)',s))
