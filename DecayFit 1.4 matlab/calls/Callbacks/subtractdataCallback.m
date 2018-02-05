function sumdataCallback(handles)
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

% Open data selection dialog
[choices1 choice2] = selectionDlg();
if length(choices1)<1 || length(choice2)<1
    return
end

if choice2>length(decays)
    back = IRFs(choice2-length(decays));
else
    back = decays(choice2);
end

% Number of data sets prior operation
ndecays = length(decays);
nIRFs = length(IRFs);

% Check data lengths
l = size(back.data,1);
for i = 1:length(choices1)
    if (choices1(i)>ndecays && size(IRFs(choices1(i)-ndecays).data,1)~=l) ...
            || (choices1(i)<=ndecays && size(decays(choices1(i)).data,1)~=l)
        
        mymsgbox('Selected data sets are not of equal lengths')
        return
    end
end

for i = 1:length(choices1)
    if choices1(i)>ndecays
        d = IRFs(choices1(i)-ndecays);
    else
        d = decays(choices1(i));
    end
    
    % Perform operation
    name = sprintf('Subtracted: %s-%s', d.name,back.name); % Name of new decay
    d.data(:,2) = d.data(:,2)-back.data(:,2); % Data of new
    zero = d.zero-back.zero;
    
    % Update decays structure
    if choices1(i)>ndecays
        IRFs = storeData(IRFs,d.data,name,handles);
        IRFs(end).zero = zero;
    else
        decays = storeData(decays,d.data,name,handles);
        decays(end).zero = zero;
    end
    
end

% Update data structures
set(handles.decays,'UserData',decays)
set(handles.IRFs,'UserData',IRFs)

% Update GUI
updatedecays(handles)
updateIRFs(handles)

% Set selection to new data sets
if length(decays)>ndecays
    set(handles.DecaysListbox,'Value',ndecays+1:length(decays))
end
if length(IRFs)>nIRFs
    set(handles.IRFsListbox,'Value',nIRFs+1:length(IRFs))
end
updateplot(handles)

    function [choices1 choice2] = selectionDlg()
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
        name = 'Subtract background';%'Select spectra for: Spectra1 - Spectra2';
        
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