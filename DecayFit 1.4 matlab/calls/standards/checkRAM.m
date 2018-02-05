function mainhandles = checkRAM(mainhandles, requiredRAM)
% Checks current and recommended RAM
%
%    Input:
%     mainhandles   - handles structure of the main window. Settings
%                     structure must have field .startup.memoryMessage and
%                     handles.name
%     requiredRAM   - amount recommended. Default = 12000
%
%    Output:
%     mainhandles   - ...
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
if nargin<2 || isempty(requiredRAM)
    requiredRAM = 200;
end

% Check setting about checking
if ~mainhandles.settings.startup.memoryMessage % Check memory allocated for MATLAB variables
    return
end

% Current RAM
temp = memory;
mem = temp.MemAvailableAllArrays*9.5367*10^-7;

if mem<requiredRAM % If computer has less than 15 GB available memory
    
    % Display message box about slow computer
    name = 'RAM may be inadequate';
    prompt = {...
        sprintf(['You have a limited amount of RAM (%.0f MB) available for %s on this computer.\n\n'...
        'The recommended amount is >%.0f MB but depends on the size of your raw data.\n%s\n\n%s'],...
        mem,...
        mainhandles.name,...
        requiredRAM,...
        'You may therefore experience memory-related problems if not upgrading.',...
        'You can use the Memory menu to regularly clear raw data from RAM after extracting the intensity traces.') '';...
        'Please don''t remind me again, I am happy about my computer' 'choice'};
    formats = struct('type', {}, 'style', {}, 'items', {}, ...
        'format', {}, 'limits', {}, 'size', {});
    formats(2,1).type   = 'text';
    formats(4,1).type   = 'check';
    DefAns.choice = 0;
    options.CancelButton = 'off';
    
    % Open dialog
    answer = inputsdlg(prompt, name, formats, DefAns, options);
    
    % Put attention back to GUI. This is important in order not to
    % crash in some versions of MATLAB
    state = get(mainhandles.figure1,'Visible');
    figure(mainhandles.figure1)
    set(mainhandles.figure1,'Visible',state)
    
    % Update choice
    if answer.choice
        mainhandles.settings.startup.memoryMessage = 0; % Store the choice of whether to show this message again
        updatemainhandles(mainhandles)
        saveDefaultSettings(mainhandles, mainhandles.settings)
    end
end
