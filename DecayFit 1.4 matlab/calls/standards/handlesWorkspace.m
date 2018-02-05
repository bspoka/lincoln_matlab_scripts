function handlesWorkspace(handles)
% Callback for sending handles structure to MATLAB workspace
%
%    Input:
%     handles    - handle sstructure of the main window
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

mainhandles = handles; % Rename

assignin('base', 'mainhandles', handles) % Send to workspace
% fn_structdisp(mainhandles) % Displays details about the structure in the command window
set(handles.mboard, 'String','mainhandles structure was sent to workspace.') % Display message