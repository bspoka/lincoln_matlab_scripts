function setaxlimits(hObject,event,mainhandle,ax)
% Callback for setting axis limits uicontext menu
%
%    Input:
%     hObject   - handle to the menu object
%     event     - unused eventdata
%     handles   - handles structure of the main window
%     ax        - handle to the axes with the context menu
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

%% Dialog

% Prepare dialog box
prompt = {...
    'x min: ' 'xmin';...
    'x max: ' 'xmax';...
    'y min: ' 'ymin';...
    'y max: ' 'ymax'};
name = 'Set axis limits';

% Handles formats
formats = struct('type', {}, 'style', {}, 'items', {}, ...
    'format', {}, 'limits', {}, 'size', {});
formats(2,1).type   = 'edit';
formats(2,1).format = 'float';
formats(2,1).size = 80;
formats(2,2).type   = 'edit';
formats(2,2).format = 'float';
formats(2,2).size = 80;
formats(3,1).type   = 'edit';
formats(3,1).format = 'float';
formats(3,1).size = 80;
formats(3,2).type   = 'edit';
formats(3,2).format = 'float';
formats(3,2).size = 80;

% Default answers:
% SExlim = get(handles.SEplot,'xlim');
% SEylim = get(handles.SEplot,'ylim');

x = get(ax,'xlim');
y = get(ax,'ylim');
DefAns.xmin = x(1);
DefAns.xmax = x(2);
DefAns.ymin = y(1);
DefAns.ymax = y(2);

% Open input dialogue and get answer
[answer, cancelled] = myinputsdlg(prompt, name, formats, DefAns); % Open dialog box
if cancelled == 1
    return
end

% Set axis limits
xlim(ax, [answer.xmin answer.xmax])
ylim(ax, [answer.ymin answer.ymax])

