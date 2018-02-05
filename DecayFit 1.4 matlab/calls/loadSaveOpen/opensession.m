function handles = opensession(handles,filepath)
% Callback for opening an existing session
%
%    Input:
%     handles  - handles structure of the main window
%     filepath - fullfilepath
%
%    Output:
%     handles  - ..
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

% Default
if nargin<2 || isempty(filepath)
    filepath = [];
end

set(handles.Stop,'State','off')

% File dialog
if isempty(filepath)

    % Dialog
    [filename,dir,chose] = uigetfile3(handles,'session',...
        {'*.decaySession;*.mat' 'DecayFit Session';'*.*' 'All files'},...
        'Open DecayFit Session',...
        'name.decaySession', 'on');
    if chose == 0
        return
    end
    
else
    
    % Input file
    [dir, name, ext] = fileparts(filepath);
    filename = [name ext];
end

temp = load(fullfile(dir,filename),'-mat');
if ~myIsField(temp,'state')
    set(handles.mboard,'String',sprintf(...
        'No correct DecayFit session selected. A correct session is an .m file containing a structure named state.'))
    return
end
state = temp.state;

% Data
% try
    % Settings
    if isfield(state,'main') && isfield(state.main,'settings')
        handles.settings = loadSettingsStructure(handles.settings, state.main.settings);
    end
    
    % Data
    decays = importdataStructure(handles, state.decays.UserData);
    IRFs = importdataStructure(handles, state.IRFs.UserData);
    
    set(handles.decays,'UserData',decays);
    updatedecays(handles)
    set(handles.IRFs,'UserData',IRFs);
    updateIRFs(handles)
    set(handles.DecaysListbox,'Value',state.DecaysListbox.Value);
    set(handles.IRFsListbox,'Value',state.IRFsListbox.Value);
    set(handles.FitModelsListbox,'String',state.FitModelsListbox.String);
    set(handles.FitModelsListbox,'Value',state.FitModelsListbox.Value);
    set(handles.fits,'UserData',state.fits.UserData);
    
    % Scatter and CI
    set(handles.CIestimateCheckbox,'Value',state.CIestimateCheckbox.Value);
    set(handles.IncludeScatterCheckbox,'Value',state.IncludeScatterCheckbox.Value);
    set(handles.ScatterAtextbox,'String',state.ScatterAtextbox.String);
    
    % Shift
    set(handles.ShiftTable,'UserData',state.ShiftTable.UserData);
    set(handles.FitShiftCheckbox,'Value',state.FitShiftCheckbox.Value);
    set(handles.ShiftTable2,'data',state.ShiftTable2.data);
    set(handles.ShiftTable2,'Visible',state.ShiftTable2.Visible);
    
    % FRET
    set(handles.DistWindow,'Visible',state.DistWindow.visibility);
    set(handles.ImportDistCheckbox,'Visible',state.ImportDistCheckbox.visibility);
    set(handles.ImportDistCheckbox,'Value',state.ImportDistCheckbox.value);
    set(handles.DynamicAvgRadiobutton,'Visible',state.DynamicAvgRadiobutton.visibility);
    set(handles.StaticAvgRadiobutton,'Visible',state.StaticAvgRadiobutton.visibility);
    set(handles.TruncateTextbox,'Visible',state.TruncateTextbox.visibility);
    set(handles.TruncateEditbox,'Visible',state.TruncateEditbox.visibility);
    set(handles.TruncateEditbox,'String',state.TruncateEditbox.String);
    set(handles.DAdistListbox,'visible',state.DAdistListbox.visibility);
    set(handles.DistTextbox,'visible',state.DistTextbox.visibility);
    set(handles.DistTextbox,'UserData',state.DistTextbox.UserData);
    set(handles.DAdistListbox,'String',state.DAdistListbox.String);
    set(handles.DAdistListbox,'Value',state.DAdistListbox.Value);
    
    % Global
    set(handles.GlobalList,'UserData',state.GlobalList.UserData);
    set(handles.GlobalDataListbox,'String',state.GlobalDataListbox.String);
    set(handles.GlobalDataListbox,'Value',state.GlobalDataListbox.Value);
    set(handles.GlobalParListbox,'UserData',state.GlobalParListbox.UserData);
    set(handles.GlobalParListbox,'Value',state.GlobalParListbox.Value);
    set(handles.Tools_GlobalFit,'Tag',state.Tools_GlobalFit.Tag);
    set(handles.GlobalFit,'State',state.GlobalFit.State);
    updateGlobal(handles)
    
    % Toolbar
    set(handles.Legend,'State',state.Legend.State);
    set(handles.ZoomIn,'State',state.ZoomIn.State);
    set(handles.ZoomOut,'State',state.ZoomOut.State);
    set(handles.DataCursor,'State',state.DataCursor.State);
    
    % Opened figure
    if length(state.figures) > 0
        for i = 1:length(state.figures)
            try hgS_070000 = state.figures{i}.hgS_070000; % Current name
                save('temp.fig','hgS_070000')
            catch err
                hgS_080000 = state.figures{i}.hgS_080000 % Name in later MATLAB version?
                save('temp.fig','hgS_080000')
            end
            f = openfig('temp.fig');
            handles.figures{end+1} = f;
        end
        delete('temp.fig')
        guidata(handles.figure1,handles); % Update handles structure
    end
    
    % Update
    updateShiftTable(handles)
    fitmodelsListboxCallback(handles) % Also update ParTable
    updateplot(handles)
    
    % Various
    set(handles.Tools_ChiSqSurf,'UserData',state.Tools_ChiSqSurf.UserData);
    set(handles.mboard,'String',state.mboard.String);
%     set(handles.figure1,'Position',state.figure1.Positions);
    set(handles.Edit_ParPlotSettings,'UserData',state.Edit_ParPlotSettings.UserData);
    handles.filename = fullfile(dir,filename);
    guidata(handles.figure1,handles)
    
% catch err
%     set(handles.mboard,'String',sprintf('Import failed.\nThe selected file was either from a different DecayFit version or it was not a DecayFit session.'))
% end

set(handles.Stop,'State','off')
set(handles.RunStatus,'BackgroundColor','blue')
set(handles.RunStatusTextbox,'String','Waiting')

% Update recent files
updateRecentFiles(handles,dir,filename,'session');
