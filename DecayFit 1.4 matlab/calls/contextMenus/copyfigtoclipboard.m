function copyfigtoclipboard(hObject,event,mainhandle,ax)
% Callback for copying figure to clipboard
%
%    Input:
%     hObject   - handle to the menu object
%     event     - unused eventdata
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

%% Initialize

if nargin<3 || isempty(mainhandle) || nargin<4
    mainhandle = getappdata(0,'mainhandle');
    mainhandles = guidata(mainhandle);
    return
end

% Get mainhandles structure
mainhandles = guidata(mainhandle);

% Check its an axes handle, elseif graph obj grap parent axes
if (~isprop(ax,'Type') || ~strcmpi(get(ax,'type'),'axes')) ...
        && ishghandle(ax)
    ax = get(ax,'parent');
end

if (~isprop(ax,'Type') || ~strcmpi(get(ax,'type'),'axes'))
    return
end

% Temporary window
hf = copywindow(mainhandles, ax, 0);
% set(hf,'Visible','off')

% % Set figure properties
% f = 1;%(handles.settings.export.labelsize/15);
% setpixelposition(hf,[100 100 handles.settings.export.width*f handles.settings.export.height*f])
% 
% % Get line objects
% h = findobj(hf,'type','line');
% for i = 1:length(h)
%     set(h(i),'linewidth',handles.settings.export.linewidth)
% end
% 
% % labels
% ax = allchild(hf);
% ax = findobj(ax,'type','ax');
% for i = 1:length(ax)
%     set(ax(i),'FontSize',handles.settings.export.labelsize)
%     h = get(ax(i),'xlabel');
%     axs = getpixelposition(ax(i));
%     setpixelposition(ax(i),[axs(1) axs(2)*2 axs(3) axs(4)/1.3])
% %     xlabel(ax(i),get(h,'string'),'FontSize',handles.settings.export.labelsize)
%     set(h,'FontSize',handles.settings.export.labelsize)
%     h = get(ax(i),'ylabel');
%     set(h,'FontSize',handles.settings.export.labelsize)
% end

% Pring temporary window
print(hf,'-dmeta');

% Delete temporaty window
try delete(hf), end

% Show message
set(mainhandles.mboard,'String','Figure copied to clipboard.')
