function plotCallback(handles)
% Callback for pressing plot pushbutton
%
%    Input:
%     handles    - handles structure of the main window
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

set(handles.Stop,'State','off')

set(handles.RunStatus,'BackgroundColor','blue')
set(handles.RunStatusTextbox,'String','Waiting')

% Get fits and parameters
modelchoice = get(handles.FitModelsListbox,'Value');
choice = cellstr(get(handles.FitModelsListbox,'String'));
decaychoices = get(handles.DecaysListbox,'Value');
modelname = choice(modelchoice);
fun = str2func(modelname{:});
partable = get(handles.ParTable,'data');

% Get decay & IRF choice
if strcmp(get(handles.GlobalFit,'State'),'off')
    IRFchoice = get(handles.IRFsListbox,'Value');
    decaychoices = get(handles.DecaysListbox,'Value');
elseif strcmp(get(handles.GlobalFit,'State'),'on')
    Global = get(handles.GlobalList,'UserData');
    globalchoice = get(handles.GlobalDataListbox,'Value');
    if (isempty(globalchoice)) || (isempty(Global))
        set(handles.GlobalDataListbox,'Value',1)
        return
    end
    decaychoices = Global(globalchoice).index(1);
    IRFchoice = Global(globalchoice).index(2);
end

% Loop over all selected decays
for i = 1:length(decaychoices)
    decaychoice = decaychoices(i);
    vars = partable(:,i);
    
    % Get t
    decays = get(handles.decays,'UserData');
    IRFs = get(handles.IRFs,'UserData');
    if ~isempty(decays)
        decay = decays(decaychoice);
        t = decay.data(:,1);
    elseif ~isempty(IRFs)
        IRF = IRFs(IRFchoice);
        t = IRF.data(:,1);
    else
        t = linspace(0,50,2000)';
    end
    
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
    t = t(t1:t2);
    setappdata(0,'t',t)
    
    % Simulate decay
    setappdata(0,'handles',handles)
    I = fun(vars);
    
    % Convolve
    if ~isempty(IRFs)
        
        IRF = IRFs(IRFchoice);
        
        % Cut t to within IRF's time-range so that interpolation can be done
        while IRF.data(1,1) > t(1)
            I = I(2:end);
            t = t(2:end);
        end
        while IRF.data(end,1) < t(end)
            I = I(1:end-1);
            t = t(1:end-1);
        end
        
        % Grid IRF onto t.decay
        IRF = interp1(IRF.data(:,1),IRF.data(:,2),t,'spline');
        IRF(IRF<0) = 0;
        
        % IRF shift:
        shifttable = get(handles.ShiftTable,'data');
        shift = shifttable(1);
        L = shifttable(2);  % Interpolation factor
        ti = interp1(t,1:1/L:size(t,1))'; % Put in extra t's
        IRF = interp1(t,IRF,ti,'spline'); % Interpolate
        IRF = circshift(IRF,shift); % Shift IRF
        IRF = IRF(1:L:end); % Reduce to original size
        IRF(IRF<0) = 0;
        
        I = fftfilt(IRF,I); %FFT Convolution
        I = I*max(IRF)/max(I); % Set Imax(I) equal to Imax(IRF)
    end
    
    % Set new "fit"
    sim = [t I];
    if strcmp(get(handles.GlobalFit,'State'),'off')
        fits = get(handles.fits,'UserData');
        if isempty(IRFchoice)
            IRFchoice = 1;
            set(handles.IRFsListbox,'Value',1)
        elseif  isempty(decaychoice)
            decaychoice = 1;
            set(handles.DecaysListbox,'Value',1)
        end
        
        fits(decaychoice,IRFchoice,modelchoice).decay = sim;
        set(handles.fits,'UserData',fits)
        
    elseif strcmp(get(handles.GlobalFit,'State'),'on')
        Global(globalchoice).fits{modelchoice,1} = sim;
        set(handles.GlobalList,'UserData',Global)
        
    end
    
    updateplot(handles)
end

