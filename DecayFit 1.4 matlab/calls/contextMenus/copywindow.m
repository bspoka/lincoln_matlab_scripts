function hfig = copywindow(handles,ax,vis)
% Copies the graph window to a new figure window and returns it's handle
%
%    Input:
%     handles    - handles structure of the main window
%     vis        - 0/1 whether to show figure, or make it hidden
%
%    Output:
%     hfig       - handle to the created window
%

% --- Copyrights (C) ---
%
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
if nargin<2
    ax = gca;
end
if nargin<3
    vis = 1;
end

%% Make figure

hfig = figure;%('units','characters','position',fpos);
set(hfig,'color', 'white')
if ~vis
    set(hfig,'Visible','off')
end
updatelogo(hfig)
% setpixelposition(hfig,[fpos])

% Copy axes and legends into new figure
if isequal(ax,handles.ResWindow) || isequal(ax,handles.DecayWindow)
    copyDecayWindow()
elseif isequal(ax,handles.DistWindow)
    copyDistWindow()
end

% Rename window
decays = get(handles.decays,'UserData'); % Loaded decays
decaychoices = get(handles.DecaysListbox,'Value'); % Selected decays
if (~isempty(decays)) && (~isempty(decaychoices))
    name = decays(decaychoices(1)).name; % Name of selected decay 1
    for i = 1:length(decaychoices)-1
        name = sprintf('%s; %s',name,decays(decaychoices(i+1)).name);
    end
    set(hfig,'name',name)
end

% % Set position
% setlegendprops(handles,l,handles.settings.export.labelsize)

% Move fig to center
if vis
    movegui(hfig,'center')
end

% set(ax1,'units','normalized') % Allow auto-resize
% set(ax2,'units','normalized')
if isdeployed
    set(hfig,'Toolbar','figure');
end

%% Nested

    function copyDecayWindow()
        
        ax1 = subplot(4,1,1); % Prepare residual axis
        ax2 = subplot(4,1,2:4); % Prepare decay axis
        
        copyaxes(handles.ResWindow,ax1,true);
        copyaxes(handles.DecayWindow,ax2,true);
        
        % Limits
        xlim(ax1,get(handles.ResWindow,'xlim'))
        ylim(ax1,get(handles.ResWindow,'ylim'))
        xlim(ax2,get(handles.DecayWindow,'xlim'))
        ylim(ax2,get(handles.DecayWindow,'ylim'))
        
        %% Set figure properties according to settings
        
        % Size ans position
        setpixelposition(hfig,[100 100 handles.settings.export.width handles.settings.export.height])
        
        % Get line objects
        h = findobj(hfig,'type','line');
        for i = 1:length(h)
            set(h(i),'linewidth',handles.settings.export.linewidth)
        end
        
        % labels
        ax = allchild(hfig);
        ax = findobj(ax,'type','ax');
        pos = [];
        [x y] = axscalefactors(handles.settings.export.labelsize); % Axes scale factors
        y = y-0.05; % Add some more
        x = x-0.01;
        for i = length(ax):-1:1%length(ax)
            set(ax(i),'FontSize',handles.settings.export.labelsize)
            
            % Set figure and ax sizes
            %     set(ax(i),'ActivePositionProperty','OuterPosition')%,'OuterPosition',[0 0 1 1])
%             if i == length(ax)
%                 setFigSize(ax(i))
%             end
%             
%             % Set outposition
%             set(ax(i),'OuterPosition',[0.02 0.025 x y])
%             
%             % Store position to detect common size
%             if isempty(pos)
%                 pos = getpixelposition(ax(i));%get(ax(i),'Position');
%             else
%                 pos(end+1,:) = getpixelposition(ax(i));%get(ax(i),'Position');
%             end
            
            % Set labels
            h = get(ax(i),'xlabel');
            set(h,'FontSize',handles.settings.export.labelsize)
            
            h = get(ax(i),'ylabel');
            set(h,'FontSize',handles.settings.export.labelsize)
            
        end
        
        %% Legend
        
        leg = findobj(handles.figure1,'Type','axes','Tag','legend'); % Legend handle
        
        % Update legend
        if ~isempty(leg)
            legend(ax2,get(leg,'String'))
        end
        
        % Rename window
        decays = get(handles.decays,'UserData'); % Loaded decays
        decaychoices = get(handles.DecaysListbox,'Value'); % Selected decays
        if (~isempty(decays)) && (~isempty(decaychoices))
            name = decays(decaychoices(1)).name; % Name of selected decay 1
            for i = 1:length(decaychoices)-1
                name = sprintf('%s; %s',name,decays(decaychoices(i+1)).name);
            end
            set(hfig,'name',name)
        end
        
        % Update legend
        if ~isempty(leg)
            legend(ax2,get(leg,'String'))
        end
    end

    function copyDistWindow()
        ax1 = gca; % Abs ax
        
        % Copy axes and legends into new figure
        copyaxes(ax,ax1,true);
        
        s = getpixelposition(ax);
        s(3:4) = round(s(3:4)*4);
        setpixelposition(hfig,s)
        set(ax1,'units','normalized','outerposition',[0 0 0.95 0.95])
        
    end

    function setFigSize(ax)
        fpos = getpixelposition(hfig);
        apos = getpixelposition(ax);
        d = [handles.settings.export.width handles.settings.export.height] - apos(3:4);
        pos2 = [fpos(1:2) fpos(3)-d(1) fpos(4)-d(2)];
        setpixelposition(hfig,round(pos2))
    end
end