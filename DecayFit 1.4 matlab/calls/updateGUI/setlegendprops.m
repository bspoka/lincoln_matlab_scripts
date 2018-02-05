function setlegendprops(handles,l, fontsize)
% Adjust legend
%
%    Input:
%     handles   - handles structure of the main window
%     l         - handle to legend
%     fontsize  - legend fontsize
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

% Default
if nargin<3
    fontsize = handles.settings.plot.fontsize;
end

% Properties
set(l, 'Color','none',...
    'TextColor', handles.settings.plot.axcolor,...
    'fontsize', fontsize)

% Box
if handles.settings.plot.legendbox
    set(l, ...
        'box', 'on',...
        'EdgeColor', handles.settings.plot.axcolor);
else
    set(l, 'box', 'off')
end
