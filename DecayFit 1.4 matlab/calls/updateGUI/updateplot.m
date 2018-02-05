function updateplot(handles)
% Updates the decay plot axes and associated residuals
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

%% Initialize

% Turn off stop button
set(handles.Stop,'State','off')

% Reset axes
reset(handles.DecayWindow), reset(handles.ResWindow)
cla(handles.DecayWindow), cla(handles.ResWindow)

% Turn off message boxes
set(handles.ChiSqTextbox,'Visible','off') % Turn off chi-square textbox
set(handles.GlobalChiSqTextbox,'Visible','off') % Turn off global chi-square textbox
set(handles.MultiResText,'Visible','off') % Turn off message for multi-residuals plot
warning('off','MATLAB:Axes:NegativeDataInLogAxis') % Turn off warning about negative data in log-plot

% Get data
decays = get(handles.decays,'UserData'); % Loaded decays
IRFs = get(handles.IRFs,'UserData'); % Loaded IRFs
fits = get(handles.fits,'UserData'); % Fitted decays
modelchoice = get(handles.FitModelsListbox,'Value'); % Selected model

%% Plot

fit = []; % Initialize
leg = cell(1); leg(1) = []; % Legend
if strcmp(get(handles.GlobalFit,'State'),'off') % If fitting one decay at a time
    IRFchoice = get(handles.IRFsListbox,'Value'); % Selected IRF
    decaychoice = get(handles.DecaysListbox,'Value'); % Selected decay
    set(handles.GlobalListSelectionTextbox,'Visible','off') % Turn off global textbox
    
    %-------------- Plot data -----------%
    % Plot IRF
    if ~isempty(IRFs) && ~isempty(IRFchoice)
        IRF = IRFs(IRFchoice).data; % Data of selected IRF
        
        t = IRF(:,1); % Time vector
        I = IRF(:,2); % Intensity vector
        %         I = I-IRFs(IRFchoice).zero;
        %         I(I<0) = 0;
        
        % IRF shift:
        shifttable = get(handles.ShiftTable,'data'); % Shift table
        shift = shifttable(1); % Shift value
        L = shifttable(2);  % Interpolation factor
        ti = interp1(t,1:1/L:size(t,1))'; % Put in extra t's
        I = interp1(t,I,ti,'spline'); % Interpolate
        I = circshift(I,shift); % Shift IRF
        I = I(1:L:end); % Reduce to original size
        
        % Plot
        plot(handles.DecayWindow,t,I,'b','LineWidth',1.5)
        hold(handles.DecayWindow,'on')
        
        leg{end+1} = 'IRF'; % Legend entry
    end
    
    % Plot decay
    if (~isempty(decays)) && (~isempty(decaychoice))
        for i = 1:length(decaychoice) % Loop all selected decays
            decay = decays(decaychoice(i)).data; % Decay i
            
            % Plot
            if i == 1 % If first decay, plot in red
                plot(handles.DecayWindow,decay(:,1),decay(:,2),'r','LineWidth',1.5), hold(handles.DecayWindow,'on')
            else % Plot next decays in individual colors
                plot(handles.DecayWindow,decay(:,1),decay(:,2),'Color',decays(decaychoice(i)).color,'LineWidth',1.5), hold(handles.DecayWindow,'on')
            end
            
            % Legend
            if length(decaychoice)==1 % If there is only one decay, legend is just "decay"
                leg{end+1} = 'Decay';
            else % If there are more than one decay, legend is the filename
                leg{end+1} = decays(decaychoice(i)).name;
                % Replace all '_' with '\_' to avoid legend subscripts
                n = leg{end};
                run = 0;
                for k = 1:length(n)
                    run = run+1;
                    if n(run)=='_'
                        n = sprintf('%s\\%s',n(1:run-1),n(run:end));
                        run = run+1;
                    end
                end
                leg{end} = n;
            end
        end
    end
    
    % Plot fit
    for i = 1:length(decaychoice) % Loop all selected decays
        fit = fits(decaychoice(i),IRFchoice,modelchoice).decay; % Fit of selected decay
        if ~isempty(fit)
            if strcmp(get(handles.Tools_OnlyTailfit,'Label'),'Only show tailfit region') % Show full interval
                plot(handles.DecayWindow,fit(:,1),fit(:,2),'k','LineWidth',1.5), hold(handles.DecayWindow,'on')
            elseif strcmp(get(handles.Tools_OnlyTailfit,'Label'),'Show full fit') % Only show tailfit interval
                
                % Set tail start
                tail = fits(decaychoice(i),IRFchoice,1).tail; % Tail fit start time
                if isempty(tail) % "Tail-start" is the first time-point if it hasn't been set
                    tail = 1;
                else
                    [~,tail] = min(abs(fit(:,1)-tail));
                end
                
                % Plot fit
                plot(handles.DecayWindow,fit(tail:end,1),fit(tail:end,2),'k','LineWidth',1.5), hold(handles.DecayWindow,'on')
            end
            
            % Legend
            if i == 1 % If only one, legend entry is 'Fit'
                leg{end+1} = 'Fit';
            elseif i > 1 % If more than one, legend entry is 'Fits'
                leg{end} = 'Fits';
            end
            
            % Turn on multiresiduals messagebox
            if length(decaychoice)>1
                set(handles.MultiResText,'Visible','on')
            end
        end
    end
    
    % Plot residual
    if length(decaychoice)==1 % Only show res if a single decay is selected
        res = fits(decaychoice,IRFchoice,modelchoice).res; % Residual of selected fit
        xlimits = get(handles.DecayWindow,'xlim'); % x-limits of decay window
        
        % Plot
        if ~isempty(res)
            if strcmp(get(handles.Tools_OnlyTailfit,'Label'),'Only show tailfit region') % Plot entire interval
                plot(handles.ResWindow,res(:,1),res(:,2),'r'), hold(handles.ResWindow,'on')
            elseif strcmp(get(handles.Tools_OnlyTailfit,'Label'),'Show full fit') % Plot only tailfit region
                plot(handles.ResWindow,res(tail:end,1),res(tail:end,2),'r'), hold(handles.ResWindow,'on')
            end
            plot(handles.ResWindow,xlimits,[0 0],'k')
        end
    end
    
    % Set axis limits
    ylimits = get(handles.DecayWindow,'ylim');
    if ylimits(2) > 100;
        ylimits(1) = 1; % Set lower intensity value to 1, because it's log-scale
        set(handles.DecayWindow,'ylim',ylimits)
    end
    
    % Show Chi-square value
    if length(decaychoice) == 1 % Only show chi-square if a single decay is selected
        ChiSq = fits(decaychoice,IRFchoice,modelchoice).ChiSq; % Chi-square value
        if ~isempty(ChiSq) % Update chi-square textbox
            set(handles.ChiSqTextbox,'Visible','on','String',sprintf('Chi-square = %.3f',ChiSq),'FontName','Arial')
        else set(handles.ChiSqTextbox,'Visible','off','String','','FontName','Arial')
        end
    end
    
    % Show scatter value
    if length(decaychoice) == 1 % Only show if a single decay is selected
        if get(handles.IncludeScatterCheckbox,'Value') == 1
            a = fits(decaychoice,IRFchoice,modelchoice).scatter; % Fitted scatter value
            set(handles.ScatterAtextbox,'String', sprintf('%0.2f%%',a*100) ) % Update scatter textbox
        end
    else set(handles.ScatterAtextbox,'String',' ')
    end
    
    
    %------------------- Global fit plotting -----------------%
elseif strcmp(get(handles.GlobalFit,'State'),'on')
    % Chosen data
    Global = get(handles.GlobalList,'UserData'); % Decays in global fit
    globalchoice = get(handles.GlobalDataListbox,'Value'); % Selected decays in global listbox
    if (isempty(globalchoice)) || (isempty(Global)) % If no decays are selected
        set(handles.GlobalDataListbox,'Value',1)
        return
    end
    decaychoice = Global(globalchoice).index(1); % Selected decays
    IRFchoice = Global(globalchoice).index(2); % Selected IRFs
    set(handles.GlobalListSelectionTextbox,'Visible','on')
    
    %-------------- Plot data -----------%
    % Plot IRF
    if ~isempty(IRFs)
        IRF = IRFs(IRFchoice).data; % Selected IRF data
        
        t = IRF(:,1); % IRF time-grid
        I = IRF(:,2); % IRF intensity vector
        %         I = I-IRFs(IRFchoice).zero;
        %         I(I<0) = 0;
        
        % IRF shift:
        shifttable = get(handles.ShiftTable,'data'); % Shift table data
        shift = shifttable(1); % Shift value
        L = shifttable(2);  % Interpolation factor
        ti = interp1(t,1:1/L:size(t,1))'; % Put in extra t's
        I = interp1(t,I,ti,'spline'); % Interpolate
        I = circshift(I,shift); % Shift IRF
        I = I(1:L:end); % Reduce to original size
        
        % Plot
        plot(handles.DecayWindow,t,I,'b','LineWidth',1.5), hold(handles.DecayWindow,'on')
        
        % Legend entry
        leg{end+1} = 'IRF';
    end
    
    % Plot decay
    if ~isempty(decays)
        decay = decays(decaychoice).data; % Selected decay data
        
        % Plot
        plot(handles.DecayWindow,decay(:,1),decay(:,2),'r','LineWidth',1.5), hold(handles.DecayWindow,'on')
        
        % Legend entry
        leg{end+1} = 'Decay';
    end
    
    % Plot fit
    try fit = Global(globalchoice).fits{modelchoice,1}; % If there is a fit of the selected decay
        if strcmp(get(handles.Tools_OnlyTailfit,'Label'),'Only show tailfit region') % If plotting entire interval
            plot(handles.DecayWindow,fit(:,1),fit(:,2),'k','LineWidth',1.5), hold(handles.DecayWindow,'on')
        elseif strcmp(get(handles.Tools_OnlyTailfit,'Label'),'Show full fit') % If plotting only tail-fit region
            
            % Set tail start
            tail = fits(decaychoice,IRFchoice,1).tail; % Tailfit start-time
            if isempty(tail) % If there is not tail-fit start specified, use first time-point
                tail = 1;
            else
                [~,tail] = min(abs(fit(:,1)-tail));
            end
            
            % Plot
            plot(handles.DecayWindow,fit(tail:end,1),fit(tail:end,2),'k','LineWidth',1.5), hold(handles.DecayWindow,'on')
        end
        % Legend entry
        leg{end+1} = 'Fit';
    catch err % Typically if there is not fit of selected decay
        if strcmp(err.identifier,'MATLAB:badsubscript')
            %             fprintf('No fit of selected decay')
        end
    end
    
    % Set axis limits
    ylimits = get(handles.DecayWindow,'ylim');
    if ylimits(2) > 100; % Set lower limit to 1 in log-plot
        ylimits(1) = 1;
        set(handles.DecayWindow,'ylim',ylimits)
    end
    
    % Plot residual
    try
        res = Global(globalchoice).res{modelchoice,1}; % Residual of selected decay
        xlimits = get(handles.DecayWindow,'xlim'); % ns-limits
        if ~isempty(res)
            % Plot in residual window
            if strcmp(get(handles.Tools_OnlyTailfit,'Label'),'Only show tailfit region') % Plot entire interval
                plot(handles.ResWindow,res(:,1),res(:,2),'r'), hold(handles.ResWindow,'on')
            elseif strcmp(get(handles.Tools_OnlyTailfit,'Label'),'Show full fit') % Plot only tailfit region
                plot(handles.ResWindow,res(tail:end,1),res(tail:end,2),'r'), hold(handles.ResWindow,'on')
            end
            plot(handles.ResWindow,xlimits,[0 0],'k') % Plot zero-line
            
            % Set fonts
            set(handles.ResWindow,'fontname','Arial')
            ylabel(handles.ResWindow,'Res.','fontname','Arial')
            
            %     figure(2)
            %     autocorr(res(:,2),round(size(res,1)/2) ,[],[])
        end
    catch err
        % If there is no res
    end
    
    % Show Chi-square value
    try
        ChiSq = Global(globalchoice).ChiSq(modelchoice,1);
        ChiSqGlob = get(handles.GlobalDataListbox,'UserData');
        if ~isempty(ChiSq)
            set(handles.ChiSqTextbox,'Visible','on','String',sprintf('Chi-square = %.3f',ChiSq),'FontName','Arial')
        else set(handles.ChiSqTextbox,'Visible','off','String','','FontName','Arial')
        end
        if length(ChiSqGlob)>=modelchoice
            set(handles.GlobalChiSqTextbox,'Visible','on','String',sprintf('(Global chi-square = %.3f)',ChiSqGlob(modelchoice,1)),'FontName','Arial')
        else set(handles.GlobalChiSqTextbox,'Visible','off','String','','FontName','Arial')
        end
    catch err
        %          err
        % If there is no ChiSq
    end
    
    % Show scatter value
    if get(handles.IncludeScatterCheckbox,'Value') == 1
        try
            a = Global(globalchoice).scatter(modelchoice,1);
            set(handles.ScatterAtextbox,'String', sprintf('%0.2f%%',a*100) )
        catch err
            % If there is no scatter
        end
    end
    
end

%% Set legend and axes

% Axis limits
% Temporary fix
try
    % Get data from plot
    axesObjs = get(handles.DecayWindow, 'Children');  %axes handles
    ydata = get(axesObjs, 'YData');
    if ~iscell(ydata)
        ydata = {ydata};
    end
    
    % Determine min and max
    ymax = 1;
    for i = 1:length(ydata)
        if max(ydata{i})>ymax
            ymax = max(ydata{i});
        end
    end
    if ymax<=2
        ymin = 1e-4;
    else
        ymin = 2;
    end
    
    % Get data from plot
    axesObjs = get(handles.DecayWindow, 'Children');  %axes handles
    ydata = get(axesObjs, 'YData');
    xdata = get(axesObjs, 'XData');
    if ~iscell(ydata)
        ydata = {ydata};
        xdata = {xdata};
    end
    
    % Determine min and max
    ymin = 0;
    ymax = 1;
    for i = 1:length(ydata)
        if max(ydata{i}(:))>ymax
            ymax = max(ydata{i}(:));
        end
    end
    if ymin==0
        ymin = 2;
    end
    if ymax<=ymin
        ymin = 1e-3;
    end
    
    ymax = 2*ymax;
    
    if ~isempty(handles.settings.view.ylimits) && handles.settings.view.locklims...
            && handles.settings.view.ylimits(1)<ymax/2 && handles.settings.view.ylimits(2)>ymin
        ymin = handles.settings.view.ylimits(1);
        ymax = handles.settings.view.ylimits(2);
    end
    
    % Set limits
%     axis(handles.DecayWindow,[xmin xmax ymin ymax]);
%     ylim(handles.DecayWindow,[ymin ymax])
end
% catch err
%     
%     try
%         if (~isempty(fit)) && (~isempty(decays)) && (~isempty(IRFs)) % If both decay, IRF, and fit are loaded
%             axis(handles.DecayWindow,[0 decay(end,1)+decay(1,1) 2 2*max(decay(:,2))]);
%         elseif (isempty(fit)) && (~isempty(decays)) && (~isempty(IRFs))
%             axis(handles.DecayWindow,[0 decay(end,1)+decay(1,1) 2 2*max(decay(:,2))]);
%         elseif (~isempty(fit)) && (~isempty(decays)) && (isempty(IRFs))
%             axis(handles.DecayWindow,[0 decay(end,1)+decay(1,1) 2 2*max(decay(:,2))]);
%         elseif (~isempty(fit)) && (isempty(decays)) && (~isempty(IRFs))
%             axis(handles.DecayWindow,[0 IRF(end,1)+IRF(1,1) 2 2*max(IRF(:,2))]);
%         elseif (isempty(fit)) && (isempty(decays)) && (~isempty(IRFs))
%             axis(handles.DecayWindow,[0 IRF(end,1)+IRF(1,1) 2 2*max(IRF(:,2))]);
%         elseif (isempty(fit)) && (~isempty(decays)) && (isempty(IRFs)); % If only decay
%             axis(handles.DecayWindow,[0 decay(end,1)+decay(1,1) 2 2*max(decay(:,2))]);
%         end
%     end
% end

% Legend
if strcmp(get(handles.Legend,'State'),'on')
    if (~isempty(fit)) || (~isempty(decays)) || (~isempty(IRFs))
        legend(handles.DecayWindow,leg)
    elseif (~isempty(fit)) && (isempty(decays)) && (isempty(IRFs)); % If only fit
        legend(handles.DecayWindow,'Simulated') % If only decay is loaded
    end
end

%% Finalize plots

% Plot time-interval
try ti = decays(decaychoice).ti;
    ylims = get(handles.DecayWindow,'ylim');
    plot(handles.DecayWindow,[ti(1);ti(1)],[ylims(1);ylims(2)], 'linewidth',2, 'color',[0,0,0]), hold(handles.DecayWindow,'on')
    plot(handles.DecayWindow,[ti(2);ti(2)],[ylims(1);ylims(2)], 'linewidth',2, 'color',[0,0,0])
catch err
    %'no time-interval specified'
end

% Plot decay zero line
try zero = decays(decaychoice).zero;
    if zero~=0
        xlim = get(handles.DecayWindow,'xlim');
        plot(handles.DecayWindow,[xlim(1);xlim(2)],[zero;zero], 'linewidth',2, 'color',[1,0.8,0.8]), hold(handles.DecayWindow,'on')
    end
catch
end

% Plot IRF zero line
try zero = IRFs(IRFchoice).zero;
    if zero~=0
        xlim = get(handles.DecayWindow,'xlim');
        plot(handles.DecayWindow,[xlim(1);xlim(2)],[zero;zero], 'linewidth',2, 'color',[0.8,0.8,1]), hold(handles.DecayWindow,'on')
    end
catch
end

% Plot tailfit start time
try tail = fits(decaychoice,IRFchoice,1).tail;
    if ~isempty(tail)
        ylims = get(handles.DecayWindow,'ylim');
        plot(handles.DecayWindow,[tail(1);tail(1)],[ylims(1);ylims(2)],'--', 'linewidth',2, 'color',[0.8,0.8,0.8]), hold(handles.DecayWindow,'on')
    end
catch
end

% Set axes properties
set(handles.ResWindow,'fontname','Arial')
ylabel(handles.ResWindow,'Res.','fontname','Arial')
if handles.settings.view.logscale
    set(handles.DecayWindow,'YScale','log','fontname','Arial','YTick',[1 100 10000])
end
xlabel(handles.DecayWindow,'Time /ns','fontname','Arial')
ylabel(handles.DecayWindow,'Intensity','fontname','Arial')

drawnow % Update

%% Update UI context menu

updateUIcontextMenus(handles.figure1,handles.DecayWindow)
updateUIcontextMenus(handles.figure1,handles.ResWindow)
% Reset message board
% set(handles.mboard,'String','')

