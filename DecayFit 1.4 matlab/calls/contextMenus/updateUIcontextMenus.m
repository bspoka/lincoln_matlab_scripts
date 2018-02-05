function updateUIcontextMenus(mainhandle, ax)
% Creates the ui context menus for a given axes
%
%     Input:
%      mainhandle    - handle to the main window
%      ax            - handles to the axes (or graph objects in ax)
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

% Check input
if nargin<2 ...
        || (isempty(mainhandle) || ~ishandle(mainhandle))...
        || isempty(ax)
    return
end

% Update context menu for all input axes handles
for i = 1:length(ax)
    
    % Handle i
    h = ax(i);
        
    % Create uicontext menu
    cm = uicontextmenu;
    
    % Create menu items
    uimenu(cm,'Label','Copy figure to clipboard.','Callback',{@copyfigtoclipboard, mainhandle, h})
    uimenu(cm,'Label','Copy data to clipboard.','Callback',{@copydatatoclipboard, mainhandle, h})
    uimenu(cm,'Label','Open in new figure window.','Callback',{@newfigwindow, mainhandle, h})
    uimenu(cm,'Label','Set axis limits.','Callback',{@setaxlimits, mainhandle, h})
    
    % Update context menu
    try 
        set(h, 'uicontextmenu',cm)
        
    catch err
        
        % Make sure its the current axes
        try
            if isprop(h,'Type') && strcmpi(get(h,'type'),'axes')
                figure(get(h,'parent'))
                axes(h)
            end
        end
        try
            set(h, 'uicontextmenu',cm)
        end
    end
end
