function updateParTable(handles)
% Updates the parameter table
%
%   Input:
%    handles   - handles structure of the main window
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

set(handles.Stop,'State','off') % Turn stop button off

fits = get(handles.fits,'UserData'); % Fitted decays
modelchoice = get(handles.FitModelsListbox,'Value'); % Selected fit model
if strcmp(get(handles.GlobalFit,'State'),'off') % If fitting one decay at a time
    decaychoices = get(handles.DecaysListbox,'Value'); % Selected decays
    IRFchoice = get(handles.IRFsListbox,'Value'); % Selected IRFs
    decays = get(handles.decays,'UserData'); % Loaded decays
    
    if length(decaychoices) > 1 % If there are more than one decay selected
        temp = fits(decaychoices(1),IRFchoice,modelchoice).pars; % Fit parameters of first fit
        partable = zeros(size(temp,1),length(decaychoices)); % Pre-allocate parameter table values
        ColumnNames = cell(1); % Column names
        for i = 1:length(decaychoices) % Loop the selected decays
            temp = fits(decaychoices(i),IRFchoice,modelchoice).pars; % Fit parameters of decay i
            partable(:,i) = temp(:,1); % Add to parameter table array
            ColumnNames{i} = decays(decaychoices(i)).name; % Set column name
        end
        set(handles.ParTable,'ColumnName',ColumnNames,'ColumnWidth','auto') % Update column names
%         set(handles.parameters,'String',sprintf('Parameters: (%s)',decays(decaychoice(1)).name))
    else
        partable = fits(decaychoices,IRFchoice,modelchoice).pars; % Parameter table data array
%         set(handles.parameters,'String','Parameters:')
        set(handles.ParTable,'ColumnName',{'Value';'min'; 'max'},'ColumnWidth',{50,50,50}) % Update column names
    end
    
elseif strcmp(get(handles.GlobalFit,'State'),'on') % If global fitting is activated
    Global = get(handles.GlobalList,'UserData'); % Global decays
    globalchoice = get(handles.GlobalDataListbox,'Value'); % Selected decays in global listbox
    if (isempty(globalchoice)) || (isempty(Global)) % If there are no global decays selected
        set(handles.GlobalDataListbox,'Value',1) % Global decay listbox value
        set(handles.ParTable,'data',[]) % Partable is empty
        return
    end
    partable = Global(globalchoice).pars{modelchoice,1}; % Parameter values to put in partable
    set(handles.ParTable,'ColumnName',{'Value';'min'; 'max'},'ColumnWidth',{50,50,50}) % Set column names
    set(handles.parameters,'String','Parameters:')
end

% Update partable data
set(handles.ParTable,'data',partable)

