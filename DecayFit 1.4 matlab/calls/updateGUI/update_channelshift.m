function update_channelshift(handles)
% Updates the channel shift textbox
%
%    Input:
%     handles  - handles structure of the main window
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

% Get shift values
shifttable = get(handles.ShiftTable,'data'); % Shift table data
shift = shifttable(1); % Shift value
L = shifttable(2); % Interpolation parameter
channelshift = shift/L; % Shift in channels

% Update
set(handles.ChannelShiftTextbox,'String',channelshift) % Update textbox string
set(handles.Stop,'State','off') % Turn off stop button
