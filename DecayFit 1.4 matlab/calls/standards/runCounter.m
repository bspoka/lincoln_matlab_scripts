function count = runCounter(handles)
% Counts number of times program has been run
%
%     Input:
%      handles   - handles structure of the main window
%
%     Output:
%      count     - counts..
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
count = 1;

try
    % Counter
    file = fullfile(handles.workdir,'calls','stateSettings','usage.stats');
    if ~exist(file,'file')
        save(file,'count')
        return
    end
    
    % Load counter
    temp = load(file,'-mat');
    count = temp.count;
    
    % Save new count
    count = count+1;
    save(file,'count')
end