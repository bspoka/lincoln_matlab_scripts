function setFigOnTop(~)
% Sets current figure so that it is always on top (i.e. in front)
%

% --- Copyrights (C) ---
%
% Copyright (C)  S�ren Preus, Ph.D.
% http://www.fluortools.com
%
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
%
%     The GNU General Public License is found at
%     <http://www.gnu.org/licenses/gpl.html>.

try 
    frames = java.awt.Frame.getFrames();
    frames(end).setAlwaysOnTop(1);
end