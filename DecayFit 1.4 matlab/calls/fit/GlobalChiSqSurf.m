function GlobalChiSqSurf(handles) 
% Performs global chi-square surface
%
%   Input:
%    handles  - handles structure of the main window
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

%% Initialize

if strcmp(get(handles.GlobalFit,'State'),'off')
    return
end

% Start by running a global fit
GlobalFit(handles), pause(0.001)

% Close if stop-button has been pushed
if strcmp(get(handles.Stop,'State'),'on')
    set(handles.Stop,'State','off')
    return
end

% Get data
Global = get(handles.GlobalList,'UserData');

% Prepare global parameters
pg_index = get(handles.GlobalParListbox,'Value')'; % Indices of all global parameters, both constants and variables
start_global = zeros(length(pg_index),1);
lower_global = start_global;
upper_global = start_global;

% Determine start, lower and upper of global parameters
% Get fits
model = cellstr(get(handles.FitModelsListbox,'String'));
modelchoice = get(handles.FitModelsListbox,'Value'); % Fit model
model = model(modelchoice);
nsamples = length(Global); % Number of samples
temps = zeros(nsamples,1); templ = temps; tempu = templ;
for i = 1:length(pg_index) % Run over all global parameters
    for j = 1:nsamples % Run over all samples
        temp = cell2mat(Global(j).pars(modelchoice,1)); % Input parameters matrix of decay i: [starts lowers uppers]
        temps(j,1) = temp(pg_index(i),1);
        templ(j,1) = temp(pg_index(i),2);
        tempu(j,1) = temp(pg_index(i),3);
    end
    start_global(i) = mean(temps); % Set start as mean of all specified inputs
    lower_global(i) = min(templ); % Set lower as min of all specified inputs
    upper_global(i) = max(tempu); % Set upper as max of all specified input
end

% Send parameters with equal lower and upper bounds as constants
pg_index2 = find(lower_global~=upper_global)'; % Indice-indices of global parameters to optimize send from user
cg_index2 = find(lower_global==upper_global)'; % Indices of global constants send form user
start_global(cg_index2) = lower_global(cg_index2);
pars_global = [start_global lower_global upper_global];  % Pars contains all global parameter values, both constants and non-constants

% Include scatter and I0
for i = 1:nsamples
    if get(handles.IncludeScatterCheckbox,'Value') == 1
        temp = [Global(i).pars{modelchoice,1}; Global(i).scatter(modelchoice,1) 0 1; 0.1 0 inf]; % Insert scatter and I0
        temp(pg_index,2:3) = [lower_global upper_global]; % Set new lower and upper global bounds
        Global(i).pars{modelchoice,1} = temp;
    else
        temp = [Global(i).pars{modelchoice,1} ; 0.1 0 inf]; % Insert I0
        temp(pg_index,2:3) = [lower_global upper_global]; % Set new lower and upper global bounds
        Global(i).pars{modelchoice,1} = temp;
    end
end

% Set status bar to running
set(handles.RunStatus,'BackgroundColor','red')
set(handles.RunStatusTextbox,'String','Running chi-square surface')
pause(0.001)
setappdata(0,'handles',handles)
setappdata(0,'Global',Global)

%% Optimize

% start = pars_global(pg_index2,1);
% lower = pars_global(pg_index2,2);
% upper = pars_global(pg_index2,3);
pg_index2_org = pg_index2';
pg_index_org = pg_index;
pars_global_org = pars_global;

%-------------------------------------------------%
%------------- Run chi-square surf ---------------%
% Initialize
parnames = get(handles.ParTable,'RowName');
parnames{end+1} = 'Scatter';

% Surface setup parameters
surfsetup = get(handles.Tools_ChiSqSurf,'UserData');
threshold = surfsetup(1);
stepsize = surfsetup(2);
minsteps = surfsetup(3);

for i = 1:size(pg_index2_org,1)   % For i = num parameters to vary
    % Check if surf is linear parameter
    if (strcmp(model{:},'triple_exp')) || (strcmp(model{:},'four_exp'))
        if (pg_index_org(pg_index2_org(i))==1) || (pg_index_org(pg_index2_org(i))==3) || (pg_index_org(pg_index2_org(i))==5) || (pg_index_org(pg_index2_org(i))==7)
            continue
        end
    end
    
    % Reset parameter values
    pars_global = pars_global_org;
    
    % Initialize ChiSq matrix
    ChiSq = get(handles.GlobalDataListbox,'UserData');
    ChiSq = ChiSq(modelchoice,1);
    ChiSqRel = 1;
    oldpar = pars_global_org(pg_index2_org(i),1); % Previous value of parameter chipars(i)
    
    % ParChis is: [parametervalue ChiSq RelativeChiSq;...]
    ParChis = zeros(500,3);
    ParChis(1,:) = [oldpar ChiSq ChiSqRel];
    
    % Chi-surf parameters
    run = 1; some = 1; run2 = 2;
    f = figure;  fig = gca;
    xlabel(fig,parnames{pg_index_org(i)},'fontname','Arial')%,'fontsize',12
    ylabel(fig,'Chi^2 / min(Chi^2)','fontname','Arial')%,'fontsize',12
    drawnow
    
    % Start with positive direction, then go to negative
    direction = 'positive';
    while some == 1
        if strcmp(direction,'positive')
            newpar = oldpar + stepsize; % New value of parameter chipars(i)
        elseif strcmp(direction,'negative')
            newpar = oldpar - stepsize; % New value of parameter chipars(i)
        end
        % If newpar is outside boundaries, set it to boundary and continue
        bound = 0;
        if newpar < pars_global_org(pg_index2_org(i),2)
            newpar = pars_global_org(pg_index2_org(i),2);
            some = 0;
        elseif newpar > pars_global_org(pg_index2_org(i),3)
            newpar = pars_global_org(pg_index2_org(i),3);
            bound = 1;
        end
        
        pars_global(pg_index2_org(i),:) = newpar; % New value of chis-surf parameter
        pg_index2 = find(pars_global(:,2)~=pars_global(:,3));
        
        %--------------------------------------%
        %------------- Optimize ---------------%
        %--------------------------------------%
        
        % First do rough optimization with Imax constrained at Imax(decay):
        start = pars_global(pg_index2,1);
        lower = pars_global(pg_index2,2);
        upper = pars_global(pg_index2,3);
        setappdata(0,'pars_global',pars_global(:,1)), setappdata(0,'pg_index',pg_index), setappdata(0,'pg_index2',pg_index2)
        
        setappdata(0,'iter',1)
        X = lsqnonlin(@opt1glob,start,lower,upper,optimset('MaxFunEvals',10000,'Display', 'off'));
        %--------------------------------------%
        %--------------------------------------%
        %--------------------------------------%
        
        ChiSq = getappdata(0,'ChiSqTot');
        ChiSqRel = ChiSq/ParChis(1,2);
        
        ParChis(run2,:) = [newpar ChiSq ChiSqRel];
        
        % Stop if threshold has suceeded or set new parameters for next iteration
        if ((ChiSqRel>threshold) && (run>=minsteps)) || (bound==1)    % If threshold has been made
            if strcmp(direction,'positive')
                direction = 'negative';
                pars_global = pars_global_org;
                oldpar = pars_global_org(pg_index2_org(i),1);
                run = 1;
            elseif strcmp(direction,'negative')
                some = 0;
            end
        elseif (ChiSqRel>threshold) && (run<minsteps)  % If threshold has been made in less steps than 'minsteps'
            pars_global = pars_global_org;
            oldpar = pars_global_org(pg_index2_org(i),1);
            stepsize = 0.1*stepsize;
        elseif (ChiSqRel<threshold) && (run<=minsteps)  % If threshold has not been made and steps < minsteps
            oldpar = newpar;
            run = run+1;
        elseif (ChiSqRel<threshold) && (run>minsteps)   % If threshold has not been made and steps > minsteps
            oldpar = newpar;
            run = run+1;
            stepsize = 1.1*stepsize;
        end
        
        % Refresh plot
        scatter(fig,ParChis(ParChis(:,2)~=0,1),ParChis(ParChis(:,2)~=0,3),'*')
        xlabel(fig,parnames{pg_index_org(i)},'fontname','Arial')%,'fontsize',12
        ylabel(fig,'Chi^2 / min(Chi^2)','fontname','Arial')%,'fontsize',12
        drawnow
        
        % Close if stop button has been pushed
        if strcmp(get(handles.Stop,'State'),'on')
            % Refresh plot
            ParChis(ParChis(:,3)>2,:) = [];
            ParChis = sortrows(ParChis);
            xlimits = get(fig,'xlim');
            plot(fig,ParChis(ParChis(:,2)~=0,1),ParChis(ParChis(:,2)~=0,3),'k'), hold(fig,'on')
            plot(fig,xlimits,[1.05 1.05],'--r')
            xlabel(fig,parnames{pg_index2(i)},'fontname','Arial')%,'fontsize',12
            ylabel(fig,'Chi^2 / min(Chi^2)','fontname','Arial')%,'fontsize',12
            drawnow
            
            set(handles.Stop,'State','off')
            return
        end
        
        run2 = run2+1;
        
        % Stop if ChiSq has not changed for a long time
        if run2 > minsteps
            if var(ParChis(run2-minsteps:run2,2)) < 1
                continue
            end
        end
    end
    
    % Refresh plot
    ParChis(ParChis(:,3)>2,:) = [];
    ParChis = sortrows(ParChis);
    xlimits = get(fig,'xlim');
    plot(fig,ParChis(ParChis(:,2)~=0,1),ParChis(ParChis(:,2)~=0,3),'k'), hold(fig,'on')
    plot(fig,xlimits,[1.05 1.05],'--r')
    xlabel(fig,parnames{pg_index2_org(i)},'fontname','Arial')%,'fontsize',12
    ylabel(fig,'Chi^2 / min(Chi^2)','fontname','Arial')%,'fontsize',12
    drawnow
    
    % Save figure handle
    handles.figures{end+1} = f;
    guidata(handles.figure1,handles);
    updateFIGhandles(handles)
end

%--------------------------------------------------%
%--------------------------------------------------%
set(handles.Stop,'State','off')

% Set status bar to finished
set(handles.RunStatus,'BackgroundColor','green')
set(handles.RunStatusTextbox,'String','Finished')

