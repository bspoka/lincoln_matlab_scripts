function updatedecays(handles)
% Updates decays listbox
%
%    Input:
%     handles   - handles structure of the main window
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

decays = get(handles.decays,'UserData'); % Loaded decays
if isempty(decays) % If there are no decays loaded
    set(handles.DecaysListbox,'String',' ','Value',1)
    return
end

% Make string list
namelist = {decays(:).name}';

% Update listbox string
set(handles.DecaysListbox,'String',namelist)

