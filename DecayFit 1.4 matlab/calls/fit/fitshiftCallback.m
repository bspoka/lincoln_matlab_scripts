function fitshiftCallback(handles)
% Callback for fit with shift as optimization variable
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

% Get data
fits = get(handles.fits,'UserData');
decays = get(handles.decays,'UserData');
IRFs = get(handles.IRFs,'UserData');
decaychoices = get(handles.DecaysListbox,'Value');
IRFchoice = get(handles.IRFsListbox,'Value');
modelchoice = get(handles.FitModelsListbox,'Value');
if isempty(decays) || isempty(IRFs)
    set(handles.mboard,'String',sprintf(...
        'No decay input\n'))
    return
end

% For loop over all selected decays
for k = 1:length(decaychoices)
    decaychoice = decaychoices(k);
    
    decay = decays(decaychoice);
    tr = decay.data(:,1); % 'r' is for "raw"
    decayr = decay.data(:,2);
    IRFr = IRFs(IRFchoice);
    
    % Cut all data to within IRF's time-range so that interpolation can be done
    while IRFr.data(1,1) > tr(1)
        decayr = decayr(2:end);
        tr = tr(2:end);
    end
    while IRFr.data(end,1) < tr(end)
        decayr = decayr(1:end-1);
        tr = tr(1:end-1);
    end
    
    % Grid IRF onto t.decay
    IRFr = interp1(IRFr.data(:,1),IRFr.data(:,2),tr,'spline');
    IRFr(IRFr<0) = 0;
    
    % Initialize
    shifttable = get(handles.ShiftTable,'data');
    shifttable2 = get(handles.ShiftTable2,'data');
    L = shifttable(2);  % Interpolation factor
    %     vars = get(handles.ParTable,'data');
    vars = fits(decaychoice,IRFchoice,modelchoice).pars;
    parlength = size(vars,1) + 1 + get(handles.IncludeScatterCheckbox,'Value');
    shifts = shifttable2(1):shifttable2(2);
    chisqs = zeros(1,length(shifts));
    allpars = zeros(parlength,length(shifts));
    allfits{1,length(shifts)} = [];
    allres = allfits;
    run = 1;
    
    % Set parameters
    fits = get(handles.fits,'UserData');
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
    p_index = find(lower~=upper); % Indices of parameters to optimize send from user
    c_index = find(lower==upper); % Indices of constants send form user
    start(c_index) = lower(c_index); % Pars contains all parameter value, both constants and non-constants
    pars = [start lower upper];
    
    % Get fits type
    model = cellstr(get(handles.FitModelsListbox,'String'));
    model = model(get(handles.FitModelsListbox,'Value'));
    fun = str2func(model{:});
    
    % Set status bar to running
    set(handles.RunStatus,'BackgroundColor','red')
    set(handles.RunStatusTextbox,'String','Running')
    pause(0.001)
    
    for shift = shifts
        if strcmp(get(handles.Stop,'State'),'on')
            set(handles.Stop,'State','off')
            myprogressbar(1)
            return
        end
        
        % IRF shift
        ti = interp1(tr,1:1/L:size(tr,1))'; % Put in extra t's
        IRF = interp1(tr,IRFr,ti,'spline'); % Interpolate
        IRF = circshift(IRF,shift); % Shift IRF
        IRF = IRF(1:L:end); % Reduce to original size
        IRF(IRF<0) = 0;
        
        % Get time-interval
        try ti = decays(decaychoice).ti;
            if isempty(ti)
                ti = [t(1) t(end)];
            end
        catch err
            ti = [tr(1) tr(end)];
        end
        [~,t1] = min(abs(tr(:)-ti(1)));
        [~,t2] = min(abs(tr(:)-ti(2)));
        
        % Set data
        t = tr(t1:t2);
        decay = decayr(t1:t2);
        IRF = IRF(t1:t2);
        
        % Subtract baseline
        IRF = IRF-IRFs(IRFchoice).zero;
        decay = decay-decays(decaychoice).zero;
        IRF(IRF<0) = 0;
        decay(decay<0) = 0;
        
        % Set tail start
        tail = fits(decaychoice,IRFchoice,1).tail;
        if isempty(tail)
            tail = 1;
        else
            [~,tail] = min(abs(t(:)-tail));
        end
        
        %--------------------------------------%
        %------------- Optimize ---------------%
        %--------------------------------------%
        varians = smooth(decay,10); varians(varians < 1) = 1; weights = 1./sqrt(varians); % Weighting in lsqnonlin is 1/st.dev which in Poisson stats is 1/sqrt(counts)
        setappdata(0,'decay',decay), setappdata(0,'IRF',IRF), setappdata(0,'t',t)
        setappdata(0,'weights',weights), setappdata(0,'handles',handles), setappdata(0,'fun',fun)
        setappdata(0,'tail',tail)
        
        % First do rough optimization with Imax(fit) constrained at Imax(decay):
        start = pars(p_index,1);
        lower = pars(p_index,2);
        upper = pars(p_index,3);
        setappdata(0,'pars',pars(1:end-1,1)), setappdata(0,'p_index',p_index(1:end-1))
        X = fminsearchbnd(@opt1,start(1:end-1), lower(1:end-1), upper(1:end-1),...
            optimset('MaxFunEvals',2500,'MaxIter',500,'TolFun',0.05, 'TolX', 0.05));
        pars(p_index,1) = [X; getappdata(0,'I0')];
        setappdata(0,'pars',pars(:,1)), setappdata(0,'p_index',p_index)
        
        % Then optimize all parameters using above as start guesses.
        % Full optimization algorithm depends on fits.
        if (~strcmp(model{:},'triple_exp')) && (~strcmp(model{:},'four_exp'))
            start = pars(p_index,1);
            [X,ChiSq,res] = lsqnonlin(@opt2,start,lower,upper, optimset('MaxFunEvals',5000,'Display','off')); % Implicit data weighting using lsqcurvefit
            pars(p_index,1) = X;
            fit = getappdata(0,'fit');
            
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
            
            % Linear parameters optimized in opt2t.
            p_indexLP = [1 3 5];
            startLP = pars(p_indexLP,1);  setappdata(0,'startLP',startLP)
            lowerLP = pars(p_indexLP,2);  setappdata(0,'lowerLP',lowerLP)
            upperLP = pars(p_indexLP,3);  setappdata(0,'upperLP',upperLP)
            
            % Optimize non-linear parameters, including scatter and I0
            [NLpars,ChiSq] = lsqnonlin(@opt2t,startNLP,lowerNLP,upperNLP,optimset('Display', 'off'));
            
            % Call one final time to get the final linear parameters
            [res, Lpars, fit] = opt2t(NLpars);
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
            
            % Linear parameters optimized in opt2t.
            p_indexLP = [1 3 5 7];
            startLP = pars(p_indexLP,1);  setappdata(0,'startLP',startLP)
            lowerLP = pars(p_indexLP,2);  setappdata(0,'lowerLP',lowerLP)
            upperLP = pars(p_indexLP,3);  setappdata(0,'upperLP',upperLP)
            
            % Optimize non-linear parameters, including scatter and I0
            [NLpars,ChiSq] = lsqnonlin(@opt2q,startNLP,lowerNLP,upperNLP,optimset('Display', 'off'));
            
            % Call one final time to get the final linear parameters
            [res, Lpars, fit] = opt2q(NLpars);
            pars(p_indexLP,1) = Lpars;
            pars(p_indexNLP,1) = NLpars;
        end
        %--------------------------------------%
        %--------------------------------------%
        %--------------------------------------%
        
        % Store fits
        chisqs(1,run) = ChiSq/length(decay);
        allpars(:,run) = pars(:,1);
        fit = fit+decays(decaychoice).zero;
        allfits{1,run} = [t fit];
        res = getappdata(0,'resfull');
        allres{1,run} = [t res]; %Weighted residual
        
        % Update progressbar:
        frac = run/(shifttable2(2)-shifttable2(1)+2);
        myprogressbar(frac);
        run = run+1;
        
    end
    
    % Optimized parameter values:
    [ChiSq,index] = min(chisqs);
    shift = shifts(index);
    pars = allpars(:,index);
    fit = allfits{:,index};
    res = allres{:,index};
    
    %-------- Update results --------%
    
    
    % Store fit
    fits(decaychoice,IRFchoice,modelchoice).decay = fit;
    fits(decaychoice,IRFchoice,modelchoice).res = res;
    fits(decaychoice,IRFchoice,modelchoice).ChiSq = ChiSq;
    if get(handles.IncludeScatterCheckbox,'Value') == 1
        fits(decaychoice,IRFchoice,modelchoice).pars(:,1) = pars(1:end-2,:);
        set(handles.ScatterAtextbox,'String', sprintf('%0.2f%%',pars(end-1,1)*100) )
        fits(decaychoice,IRFchoice,modelchoice).scatter = pars(end-1,1);
    else
        fits(decaychoice,IRFchoice,modelchoice).pars(:,1) = pars(1:end-1,:);
        set(handles.ScatterAtextbox,'String','')
    end
    set(handles.fits,'UserData',fits)
    
    % Store shift value
    shifttable(1) = shift;
    shifts = get(handles.ShiftTable,'UserData');
    shifts{decaychoice,IRFchoice} = shifttable;
    set(handles.ShiftTable,'data',shifttable)
    set(handles.ShiftTable,'UserData',shifts)
    set(handles.ShiftSlider,'Value',shifttable(1))
    
    % Update plot
    updateplot(handles)
    
    % Estimate confidence intervals from the Jacobi matrix by running a new fit
    if get(handles.CIestimateCheckbox,'Value') == 1
        set(handles.FitShiftCheckbox,'Value',0)
        fitCallback(handles)
        set(handles.FitShiftCheckbox,'Value',1)
    end
end

updateParTable(handles)
updateShiftTable(handles)
plotdist(handles)
plotlifetimes(handles)

% Set status bar to finished
myprogressbar(1);
set(handles.RunStatus,'BackgroundColor','green')
set(handles.RunStatusTextbox,'String','Finished')
set(handles.Stop,'State','off')
