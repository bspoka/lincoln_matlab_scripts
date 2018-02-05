function newSession(fh, program, workdir)
% Function for creating a new instance of the current figure
%
%    Input:
%     fh        - handle to figure
%     program   - string with name of program (.m)
%     workdir   - the directory of the program file
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

cd(workdir) % Change directory to working directory
guiPosition = get(fh,'Position'); % Get the current position of the GUI
close(fh); % Close the old GUI
set( eval(program), 'Position',guiPosition); % Open new GUI and set its position
