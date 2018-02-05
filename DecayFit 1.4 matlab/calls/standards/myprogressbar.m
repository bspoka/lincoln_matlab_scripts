function myprogressbar(varargin)
% progressbar, as usual, but sets a custom window logo
%
%   Input:
%    varargin  - input arguments normally sent directly to progressbar
%
%
% --- Copyrights (C) ---
%
% Copyright (C) 2014  Søren Preus, FluorTools.com
%
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
%
%     The GNU General Public License is found at
%     <http://www.gnu.org/licenses/gpl.html>.


% Open progressbar as usual
progressbar(varargin{:});

% Update progressbar logo
updatelogo(gcf)
