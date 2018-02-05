function handles = exportfigclipboardSettings(handles)
% Callback for setting options for figure export
%
%    INput:
%     handles  -handles structure
%
%    Output:
%     handles 
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

% Get info on screen size
p = get(0,'units');
set(0,'units','pixels')
s = get(0,'screensize');
set(0,'units',p)

% Prepare dialog
prompt = {sprintf('Figure width (pixels, max %i):  ',round(s(3))) 'width';...
    sprintf('Figure height (pixels, max %i):  ',round(s(4))) 'height';...
    'Text size' 'labelsize';...
    'Line widths' 'linewidth'};
formats = prepareformats();
name = 'Copy figure settings';

formats(2,1).type = 'edit';
formats(2,1).format = 'integer';
formats(3,1).type = 'edit';
formats(3,1).format = 'integer';
formats(4,1).type = 'edit';
formats(4,1).format = 'integer';
formats(5,1).type = 'edit';
formats(5,1).format = 'integer';

% Default answers
DefAns.width = handles.settings.export.width;
DefAns.height = handles.settings.export.height;
DefAns.labelsize = handles.settings.export.labelsize;
DefAns.linewidth = handles.settings.export.linewidth;

[answer cancelled] = myinputsdlg(prompt,name,formats,DefAns);
if cancelled
    return
end

% Update
handles.settings.export.width = answer.width;
handles.settings.export.height = answer.height;
handles.settings.export.labelsize = answer.labelsize;
handles.settings.export.linewidth = answer.linewidth;
updatemainhandles(handles)

% Update stats
handles = updateuse(handles,'Settings_ExportFigClipboard');
