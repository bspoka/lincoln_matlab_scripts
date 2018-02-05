function mainhandles = checkJava(mainhandles, requiredHeap)
% Checks that current allocated java heap space is not lower than
% recommended
%
%    Input:
%     mainhandles   - handles structure of the main window. Settings
%                     structure must have field .startup.javaMessage
%     requiredHeap  - amount required. Default = 200
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
if nargin<2 || isempty(requiredHeap)
    requiredHeap = 250;
end

% Check setting about checking
if isdeployed || ~mainhandles.settings.startup.javaMessage 
    return
end

% Current java memory
maxJava = java.lang.Runtime.getRuntime.maxMemory*9.5367*10^-7;

if maxJava<requiredHeap % If computer has less than 200 MB available memory for Java
    
    % Message about low java
    message = sprintf(['Note that you have limited amount of memory available for Java objects (%.0f MB).'...
        '\nThis is a setting that can be changed in MATLAB and is related to the amount of RAM on your computer.'...
        '\n\nIt is recommended that you increase the Java Heap Size in MATLAB to at least %.0f MB to avoid memory-related problems.'],...
        maxJava,...
        requiredHeap...
        );
    
    % Message to show about how to change heap space
    MATLABversion = version('-release'); % Version
    if (str2num(MATLABversion(1:4))>=2010)
        message = sprintf('%s\nYou can increase the Java Heap Memory from the Preferences menu in MATLAB.',message);
    else
        message = sprintf('%s\nFor instructions on how to increase the memory setting in your MATLAB version, Google: ''matlab java heap size''.',message);
    end
    
    % Display message box about low Java memory
    name = 'Limited Java memory';
    prompt = {message '';...
        'Please don''t remind me again' 'choice'};
    formats = struct('type', {}, 'style', {}, 'items', {}, ...
        'format', {}, 'limits', {}, 'size', {});
    formats(2,1).type   = 'text';
    formats(4,1).type   = 'check';
    DefAns.choice = 0;
    options.CancelButton = 'off';
    
    % Open dialog
    answer = myinputsdlg(prompt, name, formats, DefAns, options);
    
    % Put attention back to GUI. This is important in order not to
    % crash in some versions of MATLAB
    state = get(mainhandles.figure1,'Visible');
    figure(mainhandles.figure1)
    set(mainhandles.figure1,'Visible',state)
    
    % Update according to answer
    if answer.choice
        mainhandles.settings.startup.javaMessage = 0; % Store the choice of whether to show this message again
        updatemainhandles(mainhandles)
        saveDefaultSettings(mainhandles, mainhandles.settings)
    end
end
