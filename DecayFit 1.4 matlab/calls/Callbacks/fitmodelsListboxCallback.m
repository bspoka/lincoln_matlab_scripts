function fitmodelsListboxCallback(handles)
% Callback for selection in fit models listbox
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

modelnames = cellstr(get(handles.FitModelsListbox,'String'));
name = modelnames(get(handles.FitModelsListbox,'Value'));

fun = str2func(name{:});
fun(0);
varnames = getappdata(0,'varname'); % get variable names from selected function
modelstring = getappdata(0,'model');
set(handles.ParTable,'RowName',varnames)
set(handles.ModelText,'String',modelstring)

updateParTable(handles)

if strcmp(get(handles.GlobalFit,'State'),'off')
    
    if strcmp(name,'FRET')
        set([handles.ImportDistCheckbox handles.DynamicAvgRadiobutton handles.StaticAvgRadiobutton handles.DistWindow],'Visible','on')
        if get(handles.ImportDistCheckbox,'Value') == 1
            set([handles.DistTextbox handles.DAdistListbox handles.TruncateTextbox handles.TruncateEditbox handles.TwoDviewCheckbox],'Visible','on')
        else set([handles.DistTextbox handles.DAdistListbox handles.TruncateTextbox handles.TruncateEditbox handles.TwoDviewCheckbox],'Visible','off')
        end
        plotdist(handles)
        
    elseif strcmp(name,'lifetime_dist') || (strcmp(name,'single_exp')) || (strcmp(name,'double_exp')) || (strcmp(name,'triple_exp')) || (strcmp(name,'four_exp'))
        set([handles.ImportDistCheckbox handles.DynamicAvgRadiobutton handles.StaticAvgRadiobutton...
            handles.DistTextbox handles.TruncateTextbox handles.TruncateEditbox handles.DAdistListbox...
            handles.Colortext2 handles.Colortext4 handles.Colortext1 handles.Colortext3 handles.TwoDviewCheckbox],'Visible','off')
        set(handles.DistWindow,'Visible','on')
        plotlifetimes(handles)
        
    else set([handles.ImportDistCheckbox handles.DynamicAvgRadiobutton handles.StaticAvgRadiobutton handles.DistWindow...
            handles.DistTextbox handles.TruncateTextbox handles.TruncateEditbox handles.DAdistListbox...
            handles.Colortext2 handles.Colortext4 handles.Colortext1 handles.Colortext3 handles.TwoDviewCheckbox],'Visible','off')
        cla(handles.DistWindow)
    end
    
    set([handles.DecaysListbox handles.IRFsListbox handles.decays handles.IRFs],'ForegroundColor','black')
    set(handles.parameters,'String','Parameters:')
    set([handles.GlobalAddPushbutton handles.GlobalRemovePushbutton handles.GlobalList handles.GlobalDataListbox...
        handles.PickGlobalParText handles.GlobalParListbox],'Visible','off')
    
    % Global fit settings
elseif strcmp(get(handles.GlobalFit,'State'),'on')
    updateGlobal(handles)
end

updateplot(handles)
