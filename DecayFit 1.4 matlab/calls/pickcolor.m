function c = pickcolor(handles)
% Selects a random color and makes sure it is not too bright or too dark
% depending on plot background color
%
%    Input:
%     handles   - handles structure of the main window
%
%    Output:
%     c         - [r g b] double (0-1)
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

% Get handles structure
if nargin<1
    handles = getappdata(0,'mainhandles');
end

% Pick random color
c = [rand rand rand];

% Check brightness
try
    
    if sum(handles.settings.plot.backcolor)>1.5
        
        % Too bright
        while sum(c)>2.5
            c = [rand rand rand];
        end
        
    elseif sum(handles.settings.plot.backcolor)<1.5
        
        % Too dark
        while sum(c)<1
            c = [rand rand rand];
        end
    end
    
end