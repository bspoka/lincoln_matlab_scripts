function settings = internalSettingsStructure(~)
% Initializes the settings structure and its internal defaults
%
%    Input:
%     none
%
%    Output:
%     settings   - internal settings structure of the program
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

settings.startup = struct(... % Settings associated with startup
    'checkMATLAB', 1,...
    'checkToolbox', 1,...
    'javaMessage', 1,...
    'checkforUpdates', 1,... % Check for updates upon startup
    'maxdecays', 50,...
    'maxIRFs', 30);
settings.infobox = struct(...
    'sendstats', 1); % Send stats on closing
settings.close = struct(...
    'sendstats', 1);
settings.loaddata = struct(... % Settings associated with loading data
    'delimiter', '\t',... % Default delimiter attempted if automated import failed
    'nheaderlines', 1,... % No.of headerlines attempted if automated import failed
    'multiplytime', 1e9);
settings.data = struct(... % Settings associated with data
    'nschannel', 1,... % Default value in the ns/channel dialog
    'negatives', 1); % Allow negative values
settings.view = struct(...
    'logscale', 1,... % Plot in log-scale
    'ylimits', [],... % Default y-limits
    'locklims', 0,... % Lock limits at specified value
    'backcolor', [1 1 1],...
    'fontsize', 12);
settings.export = struct(...
    'width', 500,...
    'height', 500,...
    'linewidth', 2,...
    'labelsize', 12);