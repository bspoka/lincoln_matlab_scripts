function updateFIGhandles(handles)
% Updates handles to opened figure
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

% Check to see which figure windows are still open
for i = 1:length(handles.figures)
    try
        f = get(handles.figures{i});
    catch err
        if strcmp(err.identifier,'MATLAB:class:InvalidHandle')
            handles.figures(i) = []
        end
    end
end
guidata(handles.figure1,handles)

