function handles = updateuse(handles,id)
% Update usage stats
%
%    Input:
%     handles   - handles structure of the main window
%     id        - fieldname to update in use structure
%
%    Output:
%     handles   - ..
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

% Update counter
try
    handles.use.(id) = handles.use.(id)+1;
    updatemainhandles(handles)
end