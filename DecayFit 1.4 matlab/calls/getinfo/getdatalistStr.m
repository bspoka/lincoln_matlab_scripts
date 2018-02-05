function listStr = getdatalistStr(decays,IRFs)
% Returns string for data listboxes
%
%    Input:
%     decays   - decays structure
%     IRFs     - IRF structure
%
%    Output:
%     listStr  - string to populate listbox
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

% Get items for the file selection dialog listbox
if (~isempty(decays)) && (isempty(IRFs)) % If only decays are loaded
    listStr = {decays(:).name};
    for i = 1:size(listStr,2)
        listStr{1,i} = sprintf('Decay: %s',listStr{1,i});
    end
    
elseif (isempty(decays)) && (~isempty(IRFs)) % If only IRFs are loaded
    listStr = {IRFs(:).name};
    for i = 1:size(listStr,2)
        listStr{1,i} = sprintf('IRF: %s',listStr{1,i});
    end
    
elseif (~isempty(decays)) && (~isempty(IRFs)) % If both decays and IRFs are loaded
    plotsD = {decays(:).name};
    plotsI = {IRFs(:).name};
    for i = 1:size(plotsD,2)
        plotsD{1,i} = sprintf('Decay: %s',plotsD{1,i});
    end
    for i = 1:size(plotsI,2)
        plotsI{1,i} = sprintf('IRF: %s',plotsI{1,i});
    end
    listStr = {plotsD{:}, plotsI{:}};
    
else
    return
end
