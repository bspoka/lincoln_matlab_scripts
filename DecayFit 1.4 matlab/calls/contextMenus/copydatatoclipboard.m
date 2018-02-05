function copydatatoclipboard(hObject, event, mainhandle, ax)
% Callback for copying plotted data to clipboard
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

%% Get data

data = {};
dataObjs = get(ax, 'Children');
if isempty(dataObjs)
    return
end

% Get x- and y-data of plots in ax
for i = 1:length(dataObjs)
    
    % Handle graph object
    obj = dataObjs(i);
    
    if ~isprop(obj,'xdata') || ~isprop(obj,'ydata')
        % Graph obj must have data. This is not true for e.g. rectangles
        continue
        
    elseif isprop(obj,'FaceVertexCData')
        % Bar plot data requires special treatment
        
        % Get x and y data. These are the four corners of the bars.
        x = get(obj,'XData');
        y = get(obj,'YData');
        temp = [x(:) y(:)];
        
        % Interpret x and y coordinates
        temp(temp(:,2)==0,:) = []; % Remove all bottom coordinates
        
        % y is every second element
        y = temp(1:2:end,2);
        
        % x is the average of every two consecutive elements
        x = temp(:,1);
        x = reshape(x,2,length(x)/2);
        x = mean(x);
        
        % All coordinates
        data{i} = [x(:) y(:)];        
        
    else
        
        % Regulay x,y plot
        x = get(obj,'xdata');
        y = get(obj,'ydata');
        
        % Try to get z-data (not available for some plot types)
        z = [];
        try
            z = get(obj,'zdata'); % Not available from bar plots
        end
        
        % Collect
        if isempty(z)
            data{i} = [x(:) y(:)];
        else
            data{i} = [x(:) y(:) z(:)];
        end
    end
end

if isempty(data)
    return
end

% Initialize data array
r = 0; % Longest data set
c = 0; % Number of columns
for i = 1:length(data)
    if isempty(data{i})
        continue
    end
    
    if size(data{i},1)>r
        r = size(data{i},1);
    end
    
    c = c+size(data{i},2);
end

% If no data is to be exported, just return
if r==0 || c==0
    return
end

%% Copy data

% Pre-allocate
x = nan(r,c);

% Insert data in x
idx1 = 1;
for i = 1:length(data)
    if isempty(data{i})
        continue
    end
    
    idx2 = idx1-1+size(data{i},2);
    x(1:size(data{i},1),idx1:idx2) = data{i};
    idx1 = idx2+1;
end

% Copy x to clipboard
copy(x);

% Show message
mainhandles = myguidebox(mainhandles,'Great success!','Data copied to clipboard. Paste it e.g. into Excel or Origin.','copydatatoclipboard');
