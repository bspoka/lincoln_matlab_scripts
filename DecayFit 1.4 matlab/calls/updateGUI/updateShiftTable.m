function updateShiftTable(handles)
% Updates the shift table
%
%   Input:
%    handles   - handles structure of the main window
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

if strcmp(get(handles.GlobalFit,'State'),'off') % If fitting one decay at a time
    decaychoice = get(handles.DecaysListbox,'Value'); % Selected decays
    IRFchoice = get(handles.IRFsListbox,'Value'); % Selected IRF
    shifts = get(handles.ShiftTable,'UserData'); % All shifts
    shifttable = shifts{decaychoice(1),IRFchoice}; % Shift of the first of the selected decays
    
elseif strcmp(get(handles.GlobalFit,'State'),'on') % If global fitting is activated
    Global = get(handles.GlobalList,'UserData'); % Decays in global listbox
    globalchoice = get(handles.GlobalDataListbox,'Value'); % Selected decays in global listbox
    if (isempty(globalchoice)) || (isempty(Global)) % If there are no decays selected
        set(handles.GlobalDataListbox,'Value',1)
        return
    end
    shifttable = Global(globalchoice).shifts; % Shift value
end

% Update
set(handles.ShiftTable,'data',shifttable) % Update data in shift table
set(handles.ShiftSlider,'Value',shifttable(1)) % Update shift slider value
update_channelshift(handles) % Update channel shift textbox
