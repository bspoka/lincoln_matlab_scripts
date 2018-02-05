function updateImageAxesUIcontextmenu(handles)
% Makes an UI context menu (right click menu) for the image axes
%
%    Input:
%     handles   - handles structure of the main window
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

% Make menu
cmenu = uicontextmenu;
uimenu(cmenu,...
    'label', 'Copy to clipboard (Ctrl+X)',...
    'callback', @copytoClipboard)
uimenu(cmenu,...
    'label', 'Save to file (Ctrl+E)',...
    'callback', {@savecurrentImage, handles})
% uimenu(cmenu,'label','menu2')
% u=uimenu(cmenu,'label','menu3');
% uimenu(u,'label','sub_menu31')
% uimenu(u,'label','sub_menu32')

% Set menu as context menu for the plotted image
if isfield(handles,'imageHandle') && ~isempty(handles.imageHandle) && ishandle(handles.imageHandle)
    set(handles.imageHandle,'uicontextmenu',cmenu)
end
