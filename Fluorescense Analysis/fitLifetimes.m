function fitLifetimes(handles)
%
try
       
    % Get data
    fits = get(handles.fits,'UserData');
    decays = get(handles.decays,'UserData');
    IRFs = get(handles.IRFs,'UserData');
    decaychoices = get(handles.DecaysListbox,'Value');
    IRFchoice = get(handles.IRFsListbox,'Value');
    modelchoice = get(handles.FitModelsListbox,'Value');
    
    
    % For loop over all selected decays
    for k = 1:length(decaychoices)
        decaychoice = decaychoices(k);
        
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
        
        % Set parameters
        vars = fits(decaychoice,IRFchoice,modelchoice).pars;
        if get(handles.IncludeScatterCheckbox,'Value') == 1 % [partable; scatter; I0]
            scatter = fits(decaychoice,IRFchoice,modelchoice).scatter;
            start = [vars(:,1); scatter; 0.1];
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
        
        % Get fits
        model = cellstr(get(handles.FitModelsListbox,'String'));
        model = model(modelchoice);
        fun = str2func(model{:});
        
        % Set status bar to running
        set(handles.RunStatus,'BackgroundColor','red')
        set(handles.RunStatusTextbox,'String','Running')
        pause(0.001)
        
        %--------------------------------------%
        %------------- Optimize ---------------%
        %--------------------------------------%
        varians = smooth(decay,10); varians(varians < 1) = 1; weights = 1./sqrt(varians); % Weighting in lsqnonlin is 1/st.dev which in Poisson stats is 1/sqrt(counts)
        setappdata(0,'weights',weights), setappdata(0,'handles',handles), setappdata(0,'fun',fun)
        setappdata(0,'decay',decay), setappdata(0,'IRF',IRF), setappdata(0,'t',t)
        setappdata(0,'tail',tail)
        
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
        if (~strcmp(model{:},'triple_exp')) && (~strcmp(model{:},'four_exp'))
            start = pars(p_index,1);
            [X,ChiSq,res,~,~,~,jacobian] = lsqnonlin(@opt2,start,lower,upper, optimset('MaxFunEvals',5000,'Display','off')); % Implicit data weighting using lsqcurvefit
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
            [NLpars,ChiSq,~,~,~,~,jacobian] = lsqnonlin(@opt2t,startNLP,lowerNLP,upperNLP,optimset('Display', 'off'));
            
            % Call one final time to get the final linear parameters
            [res, Lpars, fit] = opt2t(NLpars);
            pars(p_indexLP,1) = Lpars;
            pars(p_indexNLP,1) = NLpars;
            
            X = NLpars;  p_index = p_indexNLP;  % Fot the ci estimation
            
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
            [NLpars,ChiSq,~,~,~,~,jacobian] = lsqnonlin(@opt2q,startNLP,lowerNLP,upperNLP,optimset('Display', 'off'));
            
            % Call one final time to get the final linear parameters
            [res, Lpars, fit] = opt2q(NLpars);
            pars(p_indexLP,1) = Lpars;
            pars(p_indexNLP,1) = NLpars;
            
            X = NLpars;  p_index = p_indexNLP;  % Fot the ci estimation
        end
        %--------------------------------------%
        %--------------------------------------%
        %--------------------------------------%
        
        % Estimate confidence intervals
        if get(handles.CIestimateCheckbox,'Value') == 1
            set(handles.RunStatusTextbox,'String','Estimates 95% confidence intervals...')
            pause(0.001)
            try
                ci = nlparci(X,res,'jacobian',jacobian);
                parnames = get(handles.ParTable,'rowname');
                output = sprintf('Confidence intervals estimated from Jacobian matrix:\n');
                if get(handles.IncludeScatterCheckbox,'Value') == 1
                    for i = 1:size(ci,1)-2
                        output = sprintf('%s\n%s:  %f - %f\n',output,parnames{p_index(i)},ci(i,:));
                    end
                    output = sprintf('%sScatter:  %f%% - %f%%\n',output,ci(end-1,:)*100);
                else
                    for i = 1:size(ci,1)-1
                        output = sprintf('%s%s:  %f - %f\n',output,parnames{p_index(i)},ci(i,:));
                    end
                end
                output = sprintf('%s\nRun chi-square surfaces for true confidence intervals.\n',output);
                display(output)
                set(handles.mboard,'String',output)
            catch err
                if strcmp(err.identifier,'MATLAB:nomem')
                    set(handles.mboard,'String',sprintf(...
                        'Not enough memory to do CI esimations\n'))
                end
            end
        end
        
        % Store fit
        fit = fit+decays(decaychoice).zero;
        res = getappdata(0,'resfull');
        fits(decaychoice,IRFchoice,modelchoice).decay = [t fit];
        fits(decaychoice,IRFchoice,modelchoice).res = [t res];
        fits(decaychoice,IRFchoice,modelchoice).ChiSq = ChiSq/length(decay);
        if get(handles.IncludeScatterCheckbox,'Value') == 1
            fits(decaychoice,IRFchoice,modelchoice).pars = pars(1:end-2,:);
            set(handles.ParTable,'data',pars(1:end-2,:))
            set(handles.ScatterAtextbox,'String', sprintf('%0.2f%%',pars(end-1,1)*100) )
            fits(decaychoice,IRFchoice,modelchoice).scatter = pars(end-1,1);
        else
            fits(decaychoice,IRFchoice,modelchoice).pars = pars(1:end-1,:);
            set(handles.ParTable,'data',pars(1:end-1,:))
            set(handles.ScatterAtextbox,'String','')
        end
        set(handles.fits,'UserData',fits)
        
        % Update plot
        updateplot(handles)
    end
    
    updateParTable(handles)
    updateShiftTable(handles)
    plotdist(handles)
    plotlifetimes(handles)
    
    % Turn interface back on
    set(InterfaceObj,'Enable','on')
    
    % Set status bar to finished
    set(handles.RunStatus,'BackgroundColor','green')
    set(handles.RunStatusTextbox,'String','Finished')
    set(handles.Stop,'State','off')
    
catch err
    set(handles.mboard,'String',err.message)
end
