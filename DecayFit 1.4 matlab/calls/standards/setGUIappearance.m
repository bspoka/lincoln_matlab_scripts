function setGUIappearance(hfig)
% Trims the GUI
%
%    Input:
%     hfig   - handle of the figure window
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

% Set color of GUI objects so that it matches background
backgrColor = get(hfig,'Color'); % Background color
set(findobj(hfig, '-property', 'BackgroundColor','-not','BackgroundColor','white','-not','-property','data'),...
    'BackgroundColor',backgrColor) % Set the background color of textboxes to the same as the figure background color

% Normalize font units of GUI object, so that they resize when resizing the
% GUI
MATLABversion = version('-release'); % For some reason setting Panel font units to normalized causes matlab R2010 to crash
if (str2num(MATLABversion(1:4))>=2012) 
%     set(findobj(hfig, '-property', 'FontUnits'),'FontUnits', 'normalized')
else
%     set(findobj(hfig, '-property', 'FontUnits', '-not','-property','BorderType'),'FontUnits', 'normalized')
end

