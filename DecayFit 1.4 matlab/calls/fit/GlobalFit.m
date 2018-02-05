function GlobalFit(handles) 
% Performs global fit
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

%% Initialize

% Get parameters
updateGlobal(handles)

Global = get(handles.GlobalList,'UserData'); % Get global information structure
modelchoice = get(handles.FitModelsListbox,'Value'); % Fit model
if isempty(Global)
    return
end
nsamples = length(Global); % Number of samples

%% Prepare data

% Remove previous data form global
Global = rmfield(Global,{'t','decays','IRFs','fits'});
Global().t = []; Global().decays = []; Global().IRFs = []; Global().fits = [];

% Get data
decays = get(handles.decays,'UserData');
IRFs = get(handles.IRFs,'UserData');
if isempty(decays) || isempty(IRFs)
    set(handles.mboard,'String',sprintf(...
        'No decay input\n'))
    return
end

% Prepare all decays and IRFs in global fit
fits = get(handles.fits,'UserData');
for i = 1:nsamples
    decaychoice = Global(i).index(1);
    IRFchoice = Global(i).index(2);
    decay = decays(decaychoice);
    t = decay.data(:,1);
    decay = decay.data(:,2);
    IRF = IRFs(IRFchoice);
    
    % Cut all data to within IRF's time-range so that interpolation can be done
    while IRF.data(1,1) > t(1)
        decay = decay(2:end);
        t = t(2:end);
    end
    while IRF.data(end,1) < t(end)
        decay = decay(1:end-1);
        t = t(1:end-1);
    end
    
    % Grid IRF onto t.decay
    IRF = interp1(IRF.data(:,1),IRF.data(:,2),t,'spline');
    IRF(IRF<0) = 0;
    
    % IRF shift:
    shifttable = Global(i).shifts;
    shift = shifttable(1);
    L = shifttable(2);  % Interpolation factor
    ts = interp1(t,1:1/L:size(t,1))'; % Put in extra t's
    IRF = interp1(t,IRF,ts,'spline'); % Interpolate
    IRF = circshift(IRF,shift); % Shift IRF
    IRF = IRF(1:L:end); % Reduce to original size
    IRF(IRF<0) = 0;
    
    % Subtract baselines
    decay = decay-decays(decaychoice).zero;
    IRF = IRF-IRFs(IRFchoice).zero;
    decay(decay<0) = 0;
    IRF(IRF<0) = 0;
    
    % Get time-interval
    try ti = decays(decaychoice).ti;
        if isempty(ti)
            ti = [t(1) t(end)];
        end
    catch err
        ti = [t(1) t(end)];
    end
    [~,t1] = min(abs(t(:)-ti(1)));
    [~,t2] = min(abs(t(:)-ti(2)));
    
    % Set data
    t = t(t1:t2);
    decay = decay(t1:t2);
    IRF = IRF(t1:t2);
    
    % Set tail start
    tail = fits(decaychoice,IRFchoice,1).tail;
    if isempty(tail)
        tail = 1;
    else
        [~,tail] = min(abs(t(:)-tail));
    end
    
    Global(i).t = t;
    Global(i).decays = decay;
    Global(i).IRFs = IRF;
    varians = smooth(decay,10); varians(varians < 1) = 1; weights = 1./sqrt(varians); % Weighting in lsqnonlin is 1/st.dev which in Poisson stats is 1/sqrt(counts)
    Global(i).weights = weights;
    Global(i).tail = tail;
end

%% Prepare fitting parameters

% Prepare global parameters
pg_index = get(handles.GlobalParListbox,'Value')'; % Indices of all global parameters, both constants and variables
start_global = zeros(length(pg_index),1);
lower_global = start_global;
upper_global = start_global;

% Determine start, lower and upper of global parameters
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

% Get fits
model = cellstr(get(handles.FitModelsListbox,'String'));
model = model(get(handles.FitModelsListbox,'Value'));
fun = str2func(model{:});

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

% Total no. of datapoints
ndatapoints = 0;
for i = 1:nsamples
    ndatapoints = ndatapoints+length(Global(i).t);
end
setappdata(0,'ndatapoints',ndatapoints)

% Set status bar to running
set(handles.RunStatus,'BackgroundColor','red')
set(handles.RunStatusTextbox,'String','Running global fit')
pause(0.001)
setappdata(0,'handles',handles)
setappdata(0,'Global',Global)

%% Optimize

start = pars_global(pg_index2,1);
lower = pars_global(pg_index2,2);
upper = pars_global(pg_index2,3);

setappdata(0,'pars_global',pars_global(:,1)), setappdata(0,'pg_index',pg_index), setappdata(0,'pg_index2',pg_index2)
setappdata(0,'fun',fun)
try
    setappdata(0,'iter',1)
    tic
    if ~isempty(pg_index)
        [X,~,res,~,~,~,jacobian] = lsqnonlin(@opt1glob,start,lower,upper,optimset('MaxFunEvals',10000,'Display', 'off'));
    else
        opt1glob(start);
    end
    
    % Estimate confidence intervals
    if get(handles.CIestimateCheckbox,'Value') == 1
        set(handles.RunStatusTextbox,'String','Estimates 95% confidence intervals...')
        pause(0.001)
        try    ci = nlparci(X,res,'jacobian',jacobian);
            parnames = get(handles.ParTable,'rowname');
            output = sprintf('\nConfidence intervals estimated from Jacobian matrix:');
            for i = 1:size(ci,1)
                output = sprintf('%s%s:  %f - %f\n',output,parnames{pg_index(i)},ci(i,:));
            end
            output = sprintf('%s\nRun chi-square surfaces for true confidence intervals.\n',output);
            set(handles.mboard,'String',output)
        catch err
            if strcmp(err.identifier,'MATLAB:nomem')
                set(handles.mboard,'String',sprintf(...
                    'Not enough memory to do CI esimations\n'))
            end
        end
    end
    
    % Get total ChiSq
    defaultChiSqGlob = get(handles.GlobalDataListbox,'UserData');
    defaultChiSqGlob(modelchoice,1) = getappdata(0,'ChiSqTot');
    set(handles.GlobalDataListbox,'UserData',defaultChiSqGlob)
    
    % Remove I0 and scatter from pars
    Global = getappdata(0,'Global');
    for i = 1:nsamples
        temp = Global(i).pars{modelchoice,1}; % Was updated in opt1glob
        if get(handles.IncludeScatterCheckbox,'Value') == 1
            Global(i).scatter(modelchoice,1) = temp(end-1,1);
            Global(i).pars{modelchoice,1} = temp(1:end-2,:);
        else
            Global(i).scatter(modelchoice,1) = 0;
            Global(i).pars{modelchoice,1} = temp(1:end-1,:);
        end
        
        % Add baseline to fits
        decaychoice = Global(i).index(1);
        Global(i).fits{modelchoice,1}(:,2) = Global(i).fits{modelchoice,1}(:,2) + decays(decaychoice).zero;
    end
    set(handles.GlobalList,'UserData',Global)
    
    % Update plotting
    updateGlobal(handles)
    updateParTable(handles)
    updateplot(handles)
    
    % Set status bar to finished
    set(handles.RunStatus,'BackgroundColor','green')
    set(handles.RunStatusTextbox,'String','Finished')
    
    
catch err
    % Set status bar to stopped
    set(handles.RunStatus,'BackgroundColor','cyan')
    set(handles.RunStatusTextbox,'String','Stopped prematurely')
    set(handles.mboard,'String',err.message)
end
