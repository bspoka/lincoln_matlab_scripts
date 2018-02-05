function updateGlobal(handles)
% Updates the global listboxes and tables
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

if strcmp(get(handles.GlobalFit,'State'),'off')
    return
end

% Get parameter names
modelnames = cellstr(get(handles.FitModelsListbox,'String'));
modelchoice = get(handles.FitModelsListbox,'Value');
modelname = modelnames(modelchoice);
fun = str2func(modelname{:});
fun(0);
parnames = getappdata(0,'varname'); % get variable names from selected function

% Turn on all Global handles
set([handles.DecaysListbox handles.IRFsListbox handles.decays handles.IRFs],'ForegroundColor','red')
set(handles.parameters,'String','Parameters (Global list selection):')
set([handles.GlobalAddPushbutton handles.GlobalRemovePushbutton handles.GlobalList handles.GlobalDataListbox...
    handles.PickGlobalParText handles.GlobalParListbox],'Visible','on')
set([handles.ImportDistCheckbox handles.DynamicAvgRadiobutton handles.StaticAvgRadiobutton handles.DistWindow...
    handles.DistTextbox handles.TruncateTextbox handles.TruncateEditbox handles.DAdistListbox...
    handles.Colortext2 handles.Colortext4 handles.Colortext1 handles.Colortext3 handles.TwoDviewCheckbox],'Visible','off')
cla(handles.DistWindow)

% Set Global par listbox
set(handles.GlobalParListbox,'String',parnames)
defaultglobalparselect = get(handles.GlobalParListbox,'UserData');
set(handles.GlobalParListbox,'Value',defaultglobalparselect{get(handles.FitModelsListbox,'Value'),1})

% Get data
decaynames = get(handles.DecaysListbox,'String');
IRFnames = get(handles.IRFsListbox,'String');
Global = get(handles.GlobalList,'UserData');
globalnames = get(handles.GlobalDataListbox,'String');
if (isempty(globalnames)) || (isempty(Global))
    return
elseif ischar(globalnames)
    globalnames = cellstr(globalnames);
end

% Determine all decay and IRF indices
run = 1;
for i = 1:size(globalnames,1)
    % Find index ']+[' in string
    f = globalnames{i,1};
    for j = 3:length(f)-3
        temp = f(j:j+2);
        if strcmp(temp,']+[')
            center = j+1; % Index of '+'
            break
        end
    end
    
    decayname = f(2:center-2);
    IRFname = f(center+2:end-1);

    decayindex = find(strcmp(decaynames,decayname));
    IRFindex = find(strcmp(IRFnames,IRFname));
    
    if (~isempty(decayindex)) && (~isempty(IRFindex))
        Global(run).index = [decayindex(1) IRFindex(1)];
        run = run+1;
        % Delete if either decay or IRF has been deleted
    else Global(run) = [];
        set(handles.GlobalDataListbox,'Value',1)
    end
    
end
if isempty(Global)
    return
end
% Remove combinations that are listed twice
if length(Global) > 1
    indices = [];
    for i = length(Global):-1:2        
        indexi = Global(i).index;
        for j = 1:i-1
            indexj = Global(j).index;
            if isequal(indexi,indexj)
                indices = [indices; i];
                break
            end
        end
    end
    Global(indices) = [];
end

%  n={Global.names}'
%  i={Global.index}'
%  p={Global.pars}'
% Global(end).names
% Global(end).index
% Global(end).pars
setappdata(0,'Global',Global)
updateParTable(handles)
updateShiftTable(handles)
set(handles.GlobalList,'UserData',Global)
set(handles.GlobalDataListbox,'String',{Global.names}')
