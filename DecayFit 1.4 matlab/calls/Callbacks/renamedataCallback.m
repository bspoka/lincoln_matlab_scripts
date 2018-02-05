function renamedataCallback(handles)
% Callback for renaming data
%
%    Input:
%     handles  - handles structure of the main window
%

% --- Copyrights (C) ---
%
% This file is part of:
% DecayFit - Time-Resolved Emission Decay Analysis Software
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

% Get data
decays = get(handles.decays,'UserData'); % Loaded absorption spectra
IRFs = get(handles.IRFs,'UserData'); % Loaded emission spectra

% If there is no data loaded
if (isempty(decays)) && (isempty(IRFs))
    return
end

% Open selection dialog if there are too many spectra
if length(decays)+length(IRFs)>=15
    [decaychoice,IRFchoice,ndecays,nIRFs] = onelistboxselection(handles,'Rename data','Select data to rename: ','multi');
    decays_select = decays(decaychoice);
    IRFs_select = IRFs(IRFchoice);
else
    decays_select = decays;
    IRFs_select = IRFs;
    decaychoice = 1:length(decays);
    IRFchoice = 1:length(IRFs);
end

if isempty(decaychoice) && isempty(IRFchoice)
    return
end
   
% Prepare dialog box
name = 'Rename data';

% Make prompt structure
prompt = {'Decays:' ''};
for i = 1:length(decays_select)
    % Replace all '_' with '\_' to avoid toolbar_legend subscripts
    n = decays_select(i).name;
    run = 0;
    for k = 1:length(n)
        run = run+1;
        if n(run)=='_'
            n = sprintf('%s\\%s',n(1:run-1),n(run:end));
            run = run+1;
        end
    end
    prompt{end+1,1} = sprintf('%s:',n);
    prompt{end,2} = sprintf('decays%i',i);
end
if ~isempty(IRFs_select)
    prompt{end+1,1} = 'IRFs:';
    prompt{end,2} = '';
    for i = 1:length(IRFs_select)
        % Replace all '_' with '\_' to avoid toolbar_legend subscripts
        n = IRFs_select(i).name;
        run = 0;
        for k = 1:length(n)
            run = run+1;
            if n(run)=='_'
                n = sprintf('%s\\%s',n(1:run-1),n(run:end));
                run = run+1;
            end
        end
        prompt{end+1,1} = sprintf('%s:',n);
        prompt{end,2} = sprintf('IRFs%i',i);
    end
end

% Make formats structure
formats = struct('type', {}, 'style', {}, 'items', {}, ...
    'format', {}, 'limits', {}, 'size', {});
formats(1,1).type   = 'text';
for i = 1:length(decays_select)
    formats(end+1,1).type   = 'edit';
end
if ~isempty(IRFs_select)
    formats(end+1,1).type = 'text';
    for i = 1:length(IRFs_select)
        formats(end+1,1).type   = 'edit';
    end
end

% Make DefAns 
DefAns = [];
for i = 1:length(decays_select)
    DefAns.(sprintf('decays%i',i)) = decays_select(i).name;
end
if ~isempty(IRFs_select)
    for i = 1:length(IRFs_select)
        DefAns.(sprintf('IRFs%i',i)) = IRFs_select(i).name;
    end
end

% Open dialog box
[answer, cancelled] = myinputsdlg(prompt, name, formats, DefAns); 
if cancelled == 1
    return
end

% Rename data
for i = 1:length(decays_select)
    decays(decaychoice(i)).name = answer.(sprintf('decays%i',i));
end
if ~isempty(IRFs_select)
    for i = 1:length(IRFs_select)
        IRFs(IRFchoice(i)).name = answer.(sprintf('IRFs%i',i));
    end
end
set(handles.decays,'UserData',decays)
set(handles.IRFs,'UserData',IRFs)
updatedecays(handles)
updateIRFs(handles)
updateParTable(handles)
updateplot(handles)

% Update stats
handles = updateuse(handles,'Edit_RenameData');
