function handles = newwindowCallback(handles)
% Callback for opening graph in new figure window
%
%    Input:
%     handles   - handles structure of the main window
%
%    Output:
%     handles   - ..
%

% --- Copyrights (C) ---
%
% This file is part of:
% DecayFit - Time-Resolved Emission Decay Analysis Software
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

% Open new figure window
hfig = copywindow(handles, handles.DecayWindow);
updatelogo(hfig)

% Save figure handle
handles.figures{end+1} = hfig;
updatemainhandles(handles)

% Update stats
handles = updateuse(handles,'newwindow');
