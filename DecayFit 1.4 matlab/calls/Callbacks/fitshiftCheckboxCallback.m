function fitshiftCheckboxCallback(handles)
% Callback for pressing the fit shift checkbox
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

choice = get(handles.FitShiftCheckbox,'Value');
if choice == 1
    set(handles.ShiftTable2,'Visible','on')
elseif choice == 0
    set(handles.ShiftTable2,'Visible','off')
end
