function chisqsurfCallback(handles)
% Callback for calculating chi-square surface
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

try
    
    % Turn the interface off for processing.
    InterfaceObj = findobj(handles.figure1,'Enable','on');
    set(InterfaceObj,'Enable','off')
    set([handles.Stop handles.RunStatusTextbox],'Enable','on')
    
    if strcmp(get(handles.GlobalFit,'State'),'on')
        GlobalChiSqSurf(handles)
        set(InterfaceObj,'Enable','on')
        return
    end
    
    % First optimize:
    set(handles.FitShiftCheckbox,'Value',0)
    set(handles.CIestimateCheckbox,'Value',0)
    fitshiftCheckboxCallback(handles)
    fitCallback(handles)
    pause(0.001) % Allow table to be updated
    
    % Close if stop button has been pushed
    if strcmp(get(handles.Stop,'State'),'on')
        set(handles.Stop,'State','off')
        set(InterfaceObj,'Enable','on')
        return
    end
    
    % Surface setup parameters
    surfsetup = get(handles.Tools_ChiSqSurf,'UserData');
    threshold = surfsetup(1);
    stepsize = surfsetup(2);
    minsteps = surfsetup(3);
    
    % For loop over all selected decays
    decaychoices = get(handles.DecaysListbox,'Value');
    for k = 1:length(decaychoices)
        decaychoice = decaychoices(k);
        
        %--------------- Prepare data -----------------%
        % Get data
        fits = get(handles.fits,'UserData');
        IRFchoice = get(handles.IRFsListbox,'Value');
        modelchoice = get(handles.FitModelsListbox,'Value');
        decays = get(handles.decays,'UserData');
        IRFs = get(handles.IRFs,'UserData');
        if isempty(decays) || isempty(IRFs)
            set(handles.mboard,'String',sprintf(...
                'No decay input\n'))
            return
        end
        
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
        shifttable = get(handles.ShiftTable,'data');
        shift = shifttable(1);
        L = shifttable(2);  % Interpolation factor
        ti = interp1(t,1:1/L:size(t,1))'; % Put in extra t's
        IRF = interp1(t,IRF,ti,'spline'); % Interpolate
        IRF = circshift(IRF,shift); % Shift IRF
        IRF = IRF(1:L:end); % Reduce to original size
        IRF(IRF<0) = 0;
        
        % Subtract baseline of decay
        IRF = IRF-IRFs(IRFchoice).zero;
        decay = decay-decays(decaychoice).zero;
        IRF(IRF<0) = 0;
        decay(decay<0) = 0;
        
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
        
        %------------------------------------------%
        
        % Get model
        model = cellstr(get(handles.FitModelsListbox,'String'));
        model = model(get(handles.FitModelsListbox,'Value'));
        fun = str2func(model{:});
        
        % Set parameters
        vars = fits(decaychoice,IRFchoice,modelchoice).pars;
        if get(handles.IncludeScatterCheckbox,'Value') == 1 % [partable; scatter; I0]
            start = [vars(:,1); fits(decaychoice,IRFchoice,modelchoice).scatter; 0.1];
            lower = [vars(:,2); 0; 0];
            upper = [vars(:,3); 1; inf];
        else % [partable; I0]
            start = [vars(:,1); 0.1];
            lower = [vars(:,2); 0];
            upper = [vars(:,3); inf];
        end
        
        % Send parameters with equal lower and upper bounds as constants
        p_index_org = find(lower~=upper); % Indices of parameters to optimize send from user
        c_index_org = find(lower==upper); % Indices of constants send form user
        start(c_index_org) = lower(c_index_org); % Pars contains all parameter value, both constants and non-constants
        pars_org = [start lower upper];
        
        % Set status bar to running
        set(handles.RunStatus,'BackgroundColor','red')
        set(handles.RunStatusTextbox,'String','Running')
        pause(0.001)
        
        
        %-------------------------------------------------%
        %------------- Run chi-square surf ---------------%
        % Initialize
        parnames = get(handles.ParTable,'RowName');
        parnames{end+1} = 'Scatter';
        varians = smooth(decay,10); varians(varians < 1) = 1; weights = 1./sqrt(varians); % Weighting in lsqnonlin is 1/st.dev which in Poisson stats is 1/sqrt(counts)
        setappdata(0,'weights',weights), setappdata(0,'handles',handles), setappdata(0,'pars',pars_org)
        setappdata(0,'decay',decay), setappdata(0,'IRF',IRF), setappdata(0,'t',t)
        setappdata(0,'fun',fun), setappdata(0,'tail',tail)
        for i = 1:size(p_index_org,1)-1   % For i = num parameters to vary
            
            % Reset parameter values
            pars = pars_org;
            
            % Initialize ChiSq matrix
            ChiSq = fits(decaychoice,IRFchoice,modelchoice).ChiSq;
            ChiSqRel = 1;
            oldpar = pars_org(p_index_org(i)); % Previous value of parameter chipars(i)
            
            % ParChis is: [parametervalue ChiSq RelativeChiSq;...]
            ParChis = zeros(500,3);
            ParChis(1,:) = [oldpar ChiSq ChiSqRel];
            
            % Chi-surf parameters
            run = 1; some = 1; run2 = 2;
            f = figure;  fig = gca;
            set(f,'name',sprintf('Chi-square surface: %s',decays(decaychoice).name),'numbertitle','off')
            
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
                if newpar < pars_org(p_index_org(i),2)
                    newpar = pars_org(p_index_org(i),2);
                    some = 0;
                elseif newpar > pars_org(p_index_org(i),3)
                    newpar = pars_org(p_index_org(i),3);
                    bound = 1;
                end
                
                pars(p_index_org(i),:) = newpar; % New value of chis-surf parameter
                p_index = find(pars(:,2)~=pars(:,3));
                
                %--------------------------------------%
                %------------- Optimize ---------------%
                %--------------------------------------%
                
                % First do rough optimization with Imax constrained at Imax(decay):
                start = pars(p_index,1);
                lower = pars(p_index,2);
                upper = pars(p_index,3);
                setappdata(0,'pars',pars(1:end-1,1)), setappdata(0,'p_index',p_index(1:end-1))
                X = fminsearchbnd(@opt1,start(1:end-1), lower(1:end-1), upper(1:end-1),...
                    optimset('MaxFunEvals',2500,'MaxIter',500,'TolFun',0.05, 'TolX', 0.05,'Display','off'));
                
                pars(p_index,1) = [X; getappdata(0,'I0')];
                setappdata(0,'pars',pars(:,1)), setappdata(0,'p_index',p_index)
                
                % Then optimize all parameters using above as start guesses.
                % Full optimization algorithm depends on fits.
                if ~strcmp(model{:},'triple_exp')
                    start = pars(p_index,1) ;
                    [X,ChiSq] = lsqnonlin(@opt2,start,lower,upper, optimset('MaxFunEvals',5000,'Display','off')); % Implicit data weighting using lsqcurvefit
                    pars(p_index,1) = X;
                    
                    % For fitting triple-exponential decay, use partioned solver
                elseif strcmp(model{:},'triple_exp')
                    
                    % Linear parameters optimized by lsqlin, non-linear by lsqnonlin.
                    % Set up non-linear parameters (NLP)
                    if get(handles.IncludeScatterCheckbox,'Value') == 1
                        p_indexNLP = [p_index(p_index==2); p_index(p_index==4); p_index(p_index==6); p_index(p_index==7); p_index(p_index==8)];
                    else
                        p_indexNLP = [p_index(p_index==2); p_index(p_index==4); p_index(p_index==6); p_index(p_index==7)];
                    end
                    startNLP = pars(p_indexNLP,1);
                    lowerNLP = pars(p_indexNLP,2);
                    upperNLP = pars(p_indexNLP,3);
                    setappdata(0,'pt_index',p_indexNLP)
                    
                    % Set up linear parameters optimized inside opt2t.
                    p_indexLP = [1 3 5];
                    startLP = pars(p_indexLP,1);  setappdata(0,'startLP',startLP)
                    lowerLP = pars(p_indexLP,2);  setappdata(0,'lowerLP',lowerLP)
                    upperLP = pars(p_indexLP,3);  setappdata(0,'upperLP',upperLP)
                    
                    % Optimize non-linear parameters, including scatter and I0
                    [NLpars,ChiSq] = lsqnonlin(@opt2t,startNLP,lowerNLP,upperNLP,optimset('Display', 'off'));
                    
                    % Call one final time to get the final linear parameters
                    [~, Lpars, ~] = opt2t(NLpars);
                    pars(p_indexLP,1) = Lpars;
                    pars(p_indexNLP,1) = NLpars;
                    
                    % For fitting quadruple-exponential decay, use partioned solver
                elseif strcmp(model{:},'four_exp')
                    
                    % Linear parameters optimized by lsqlin, non-linear by lsqnonlin.
                    % Set up non-linear parameters (NLP)
                    if get(handles.IncludeScatterCheckbox,'Value') == 1
                        p_indexNLP = [p_index(p_index==2); p_index(p_index==4); p_index(p_index==6); p_index(p_index==8); p_index(p_index==9); p_index(p_index==10)];
                    else
                        p_indexNLP = [p_index(p_index==2); p_index(p_index==4); p_index(p_index==6); p_index(p_index==8); p_index(p_index==9)];
                    end
                    startNLP = pars(p_indexNLP,1);
                    lowerNLP = pars(p_indexNLP,2);
                    upperNLP = pars(p_indexNLP,3);
                    setappdata(0,'pt_index',p_indexNLP)
                    
                    % Set up linear parameters optimized inside opt2t.
                    p_indexLP = [1 3 5 7];
                    startLP = pars(p_indexLP,1);  setappdata(0,'startLP',startLP)
                    lowerLP = pars(p_indexLP,2);  setappdata(0,'lowerLP',lowerLP)
                    upperLP = pars(p_indexLP,3);  setappdata(0,'upperLP',upperLP)
                    
                    % Optimize non-linear parameters, including scatter and I0
                    [NLpars,ChiSq] = lsqnonlin(@opt2q,startNLP,lowerNLP,upperNLP,optimset('Display', 'off'));
                    
                    % Call one final time to get the final linear parameters
                    [~, Lpars, ~] = opt2q(NLpars);
                    pars(p_indexLP,1) = Lpars;
                    pars(p_indexNLP,1) = NLpars;
                end
                %--------------------------------------%
                %--------------------------------------%
                %--------------------------------------%
                
                ChiSq = ChiSq/length(decay);
                ChiSqRel = ChiSq/ParChis(1,2);
                ParChis(run2,:) = [newpar ChiSq ChiSqRel];
                
                % Stop if threshold has suceeded or set new parameters for next iteration
                if ((ChiSqRel>threshold) && (run>=minsteps)) || (bound==1)    % If threshold has been made
                    if strcmp(direction,'positive')
                        direction = 'negative';
                        pars = pars_org;
                        oldpar = pars_org(p_index_org(i),1);
                        run = 1;
                    elseif strcmp(direction,'negative')
                        some = 0;
                    end
                elseif (ChiSqRel>threshold) && (run<minsteps)  % If threshold has been made in less steps than 'minsteps'
                    pars = pars_org;
                    oldpar = pars_org(p_index_org(i),1);
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
                xlabel(fig,parnames{p_index_org(i)},'fontname','Arial')%,'fontsize',12
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
                    xlabel(fig,parnames{p_index(i)},'fontname','Arial')%,'fontsize',12
                    ylabel(fig,'Chi^2 / min(Chi^2)','fontname','Arial')%,'fontsize',12
                    drawnow
                    
                    set(handles.Stop,'State','off')
                    return
                end
                % Stop if ChiSq has not changed for a long time
                if run2 > minsteps
                    if var(ParChis(run2-minsteps:run2,2)) < 1e-5
                        break
                    end
                end
                run2 = run2+1;
            end
            
            % Refresh plot
            ParChis(ParChis(:,3)>2,:) = [];
            ParChis = sortrows(ParChis);
            xlimits = get(fig,'xlim');
            plot(fig,ParChis(ParChis(:,2)~=0,1),ParChis(ParChis(:,2)~=0,3),'k'), hold(fig,'on')
            plot(fig,xlimits,[1.05 1.05],'--r')
            xlabel(fig,parnames{p_index_org(i)},'fontname','Arial')%,'fontsize',12
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
        
    end
    
    % Turn interace back on
    set(InterfaceObj,'Enable','on')
    
    % Set status bar to finished
    set(handles.RunStatus,'BackgroundColor','green')
    set(handles.RunStatusTextbox,'String','Finished')
    
catch err
    set(handles.mboard,'String',err.message)
end
