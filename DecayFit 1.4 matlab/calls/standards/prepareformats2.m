function formats = prepareformats2(~)
% Initializes formats structure for inputsdlg2

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

formats = struct('type', {}, 'style', {}, 'items', {}, ...
    'format', {}, 'limits', {}, 'size', {},...
    'span', {}, 'unitsloc', {}, 'margin', {},...
    'callback', {}, 'required', {}, 'enable', {},...
    'labelloc', {});
