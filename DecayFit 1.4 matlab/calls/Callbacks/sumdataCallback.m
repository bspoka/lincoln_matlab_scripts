function sumdataCallback(handles,choice)
% Callback for summing data
%
%    Input:
%     handles   - handles structure of the main window
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

decays = get(handles.decays,'UserData'); % Loaded decays
IRFs = get(handles.IRFs,'UserData'); % Loaded IRFs
if length(decays)+length(IRFs)<2
    set(handles.mboard,'String','You must load at least two data sets before merging.')
    return
end

if strcmpi(choice,'sum')
    title = 'Merge data sets';
    [decaychoices,IRFchoices,ndecays,nIRFs] = onelistboxselection(handles,'Merge data sets','Select data: ','multi');

    % Open data selection dialog
    if length(decaychoices)+length(IRFchoices)<2
        return
    end
    
else
    title = 'Subtract data sets';
    [choices1, choice2] = subtractSelectionDlg();    
end


% Check data lengths
lengths = [];
for i = 1:length(decaychoices)
    lengths = [lengths size(decays(decaychoices(i)),1)]; % Length of decay i
end
for i = 1:length(IRFchoices)
    lengths = [lengths size(IRFs(IRFchoices(i)),1)]; % Length of IRF i
end

% If data is not of equal length, display dialog and return
if length(unique(lengths))>1
    mymsgbox('Selected data sets are not of equal lengths')
    return
end

if ~isempty(decaychoices) % If decays are selected, make a new summed decay item
    % Perform operation
    name = sprintf('Sum: %s',decays(decaychoices(1)).name); % Name of new decay
    data = decays(decaychoices(1)).data; % Data of new
    zero = decays(decaychoices(1)).zero;
    if length(decaychoices)>1
        for i = 2:length(decaychoices) % Sum selected decays
            name = sprintf('%s+%s',name,decays(decaychoices(i)).name); % Update name string
            data(:,2) = data(:,2)+decays(decaychoices(i)).data(:,2); % Summed data
            zero = zero+decays(decaychoices(i)).zero; % Sum zeros
        end
    end
    for i = 1:length(IRFchoices) % Sum selected IRFs
        name = sprintf('%s+%s',name,IRFs(IRFchoices(i)).name); % Update name string
        data(:,2) = data(:,2)+IRFs(IRFchoices(i)).data(:,2); % Sum data
        zero = zero+IRFs(IRFchoices(i)).zero; % Sum zeros
    end
    
    % Update decays structure
    decays = storeData(decays,data,name,handles);
    decays(end).zero = zero;
    
else
    % Perform operation
    name = sprintf('Sum: %s',IRFs(IRFchoices(1)).name); % Name of new decay
    data = IRFs(IRFchoices(1)).data; % Data of new
    zero = IRFs(IRFchoices(1)).zero;
    for i = 2:length(IRFchoices) % Sum selected decays
        name = sprintf('%s+%s',name,IRFs(IRFchoices(i)).name); % Update name string
        data(:,2) = data(:,2)+IRFs(IRFchoices(i)).data(:,2); % Summed data
        zero = zero+IRFs(IRFchoices(i)).zero; % Sum zeros
    end
    
    % Update data structure
    IRFs = storeData(IRFs,data,name,handles);
    IRFs(end).zero = zero;
end

% Update data structures
set(handles.decays,'UserData',decays)
set(handles.IRFs,'UserData',IRFs)

% Update GUI
updatedecays(handles)
updateIRFs(handles)

%% Nested
    function [choices1 choice2] = subtractSelectionDlg()
        % Initialize
        choices1 = []; % Selected spectra
        choice2 = []; % Selected baselines
        
        % If there are only two loaded, use those
        if length(decays)==1 && length(IRFs)==1
            choices1 = 1;
            choice2 = 1;
            return
        end
        
        %--- Prepare choose plot dialog box ----%
        prompt = {'Select data' 'selection1';...
            'Select background to subtract' 'selection2'};
        name = title;%'Select spectra for: Spectra1 - Spectra2';
        
        formats = struct('type', {}, 'style', {}, 'items', {}, ...
            'format', {}, 'limits', {}, 'size', {});
        
        formats(2,1).type = 'list';
        formats(2,1).style = 'listbox';
        formats(2,1).items = getdatalistStr(decays,IRFs);
        formats(2,1).size = [200 300];
        formats(2,1).limits = [0 2]; % multi-select
        
        formats(2,3).type = 'list';
        formats(2,3).style = 'listbox';
        formats(2,3).items = getdatalistStr(decays,IRFs);
        formats(2,3).size = [200 300];
        formats(2,3).limits = [0 1]; % multi-select
        
        options.CancelButton = 'on';
        
        % Default selection is the currently selected data sets
        DefAns.selection1 = get(handles.DecaysListbox,'Value');
        DefAns.selection2 = get(handles.DecaysListbox,'Value');
        if length(DefAns.selection2)>1
            DefAns.selection2 = DefAns.selection2(1);
        end
        
        [answer, cancelled] = myinputsdlg(prompt, name, formats, DefAns, options); % Open dialog box
        if cancelled == 1
            return
        end
        
        % Result
        choices1 = answer.selection1;
        choice2 = answer.selection2;
    end
end