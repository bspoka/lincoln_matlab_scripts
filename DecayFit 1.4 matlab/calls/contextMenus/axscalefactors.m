function [x y] = axscalefactors(fontsize)
% Used when rescaling axes to fit window
%
%    Input:
%     fontsize   - xlabel and ylabel fontsize
%
%    Output:
%     [x y]      - x and y scale factors
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

% Axes scale factor depends on label sizes
if fontsize<=10
    x = 0.98;
else
    x = 0.98-(fontsize-10)/100;
end
y = x-0.02;
