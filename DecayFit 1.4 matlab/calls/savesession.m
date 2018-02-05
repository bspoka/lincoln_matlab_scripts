function handles = savesession(handles,as)
% Saves DecayFit session
%
%   Input:
%    handles  - handles structure
%    as       - binary parameter determining whether to force open file dialog
%
%   Output:
%    handles  - ..

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

if nargin<2
    as = 0;
end

set(handles.Stop,'State','off')

% Data
state.decays.UserData = get(handles.decays,'UserData');
state.DecaysListbox.Value = get(handles.DecaysListbox,'Value');
state.IRFs.UserData = get(handles.IRFs,'UserData');
state.IRFsListbox.Value = get(handles.IRFsListbox,'Value');
state.FitModelsListbox.String = get(handles.FitModelsListbox,'String');
state.FitModelsListbox.Value = get(handles.FitModelsListbox,'Value');
state.fits.UserData = get(handles.fits,'UserData');

% Settings
state.main.settings = handles.settings;

% Scatter and CI
state.CIestimateCheckbox.Value = get(handles.CIestimateCheckbox,'Value');
state.IncludeScatterCheckbox.Value = get(handles.IncludeScatterCheckbox,'Value');
state.ScatterAtextbox.String = get(handles.ScatterAtextbox,'String');

% Shift
state.ShiftTable.UserData = get(handles.ShiftTable,'UserData');
state.FitShiftCheckbox.Value = get(handles.FitShiftCheckbox,'Value');
state.ShiftTable2.data = get(handles.ShiftTable2,'data');
state.ShiftTable2.Visible = get(handles.ShiftTable2,'Visible');

% FRET
state.DistWindow.visibility = get(handles.DistWindow,'Visible');
state.ImportDistCheckbox.visibility = get(handles.ImportDistCheckbox,'Visible');
state.ImportDistCheckbox.value = get(handles.ImportDistCheckbox,'Value');
state.DynamicAvgRadiobutton.visibility = get(handles.DynamicAvgRadiobutton,'Visible');
state.StaticAvgRadiobutton.visibility = get(handles.StaticAvgRadiobutton,'Visible');
state.TruncateTextbox.visibility = get(handles.TruncateTextbox,'Visible');
state.TruncateEditbox.visibility = get(handles.TruncateEditbox,'Visible');
state.TruncateEditbox.String = get(handles.TruncateEditbox,'String');
state.DAdistListbox.visibility = get(handles.DAdistListbox,'visible');
state.DistTextbox.visibility = get(handles.DistTextbox,'visible');
state.DistTextbox.UserData = get(handles.DistTextbox,'UserData');
state.DAdistListbox.String = get(handles.DAdistListbox,'String');
state.DAdistListbox.Value = get(handles.DAdistListbox,'Value');

% Various
state.mboard.String = get(handles.mboard,'String');
state.Tools_ChiSqSurf.UserData = get(handles.Tools_ChiSqSurf,'UserData');
state.figure1.Positions = get(handles.figure1,'Position');
state.Edit_ParPlotSettings.UserData = get(handles.Edit_ParPlotSettings,'UserData');

% Global
state.GlobalList.UserData = get(handles.GlobalList,'UserData');
state.GlobalDataListbox.String = get(handles.GlobalDataListbox,'String');
state.GlobalDataListbox.Value = get(handles.GlobalDataListbox,'Value');
state.GlobalParListbox.UserData = get(handles.GlobalParListbox,'UserData');
state.GlobalParListbox.Value = get(handles.GlobalParListbox,'Value');
state.Tools_GlobalFit.Tag = get(handles.Tools_GlobalFit,'Tag');

% Toolbar
state.GlobalFit.State = get(handles.GlobalFit,'State');
state.Legend.State = get(handles.Legend,'State');
state.ZoomIn.State = get(handles.ZoomIn,'State');
state.ZoomOut.State = get(handles.ZoomOut,'State');
state.DataCursor.State = get(handles.DataCursor,'State');

% Plot
state.DecayWindow.xlim = get(handles.DecayWindow,'xlim');
state.ResWindow.xlim = get(handles.ResWindow,'xlim');
state.DecayWindow.ylim = get(handles.DecayWindow,'ylim');
state.ResWindow.ylim = get(handles.ResWindow,'ylim');
leg = findobj(gcf,'Type','axes','Tag','legend'); % Legend handle
if isempty(leg)
    state.DecayWindow.legend = '';
elseif length(leg) == 1
    state.DecayWindow.legend = get(leg(1),'String');
end

% Open figures
updateFIGhandles(handles)
handles = guidata(handles.figure1);
% Save open figures
if length(handles.figures) == 0
    state.figures = [];
else
    for i = 1:length(handles.figures)
        % Save temp figure
        hgsave(handles.figures{i},'temp.fig')
        
        % Load temp figure into structure
        d = load('temp.fig','-mat');
        state.figures{i} = d;
        
        % Delete traces
        delete('temp.fig')
    end
end

% Save to file
ok = 1;
if ~isempty(handles.filename) && ~as
    try
        filename = handles.filename;
        save(filename,'state');
        ok = 0;
    catch err
        ok = 1;
    end
end
if ok
    [filename,dir,chose] = uiputfile3(handles,'session',...
        {'*.decaySession;*.mat' 'DecayFit Session';'*.*' 'All files'},...
        'Save session as',...
        'name.decaySession');
    
%     [filename, dir, chose] = uiputfile2_session({'*.decaySession;*.mat','Save DecayFit Session As','name.decaySession');
    if chose == 0
        return
    end
    filename = fullfile(dir,filename);
    save(filename,'state');
    
    % Update recent files
    updateRecentFiles(handles,dir,filename,'session');
    
end

% Update
handles.filename = filename;
guidata(handles.figure1,handles)
set(handles.mboard,'String',sprintf('Project saved to:\n%s\n',filename))
set(handles.figure1,'name',sprintf('DecayFit - Time-Resolved Fluorescence Decay Analysis. Session: %s',handles.filename))
