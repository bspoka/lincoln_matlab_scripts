function data = storeData(data, newData, name, handles)
% Defines all required data fields and puts newData into data structure
%
%    Input:
%     data       - Current decays, IRFs...
%     newData    - new raw data
%     name       - name of new file
%     handles    - handles structure of the main window
%
%    Output:
%     data       - updated data structure
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

% Default
if nargin<2
    newData = [];
end
if nargin<3
    name = [];
end
if nargin<4
    handles = getappdata(0,'mainhandles');
end

% Initialize
if isempty(data)
    data(1).data = newData;
else
    data(end+1).data = newData;
end

% Color (avoid too bright)
c = pickcolor();

% Add other required fields
data(end).name = name; % Name ID string
data(end).rawdata = data(end).data; % Raw data
data(end).ti = []; % Time-interval used in fit
data(end).zero = 0; % Zero-line counts
data(end).color = c; % Color of decay

% Sort fields
data = orderfields(data);
