function plotlifetimes(handles)
% Updates the lifetime bar-plots for non-FRET models (small axes window)
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

set(handles.Stop,'State','off') % Turn off stop-button

modelnames = get(handles.FitModelsListbox,'String'); % All fit model names
modelchoice = get(handles.FitModelsListbox,'Value'); % Selected fit model
modelname = modelnames(modelchoice); % Name of selected fit model

% If selected model is not one of the following, return
if ((~strcmp(modelname,'lifetime_dist')) && (~strcmp(modelname,'single_exp'))...
        && (~strcmp(modelname,'double_exp')) && (~strcmp(modelname,'triple_exp'))...
        && (~strcmp(modelname,'four_exp'))) || (strcmp(get(handles.GlobalFit,'State'),'on'))
    return
end
reset(handles.DistWindow) % Reset axes
cla(handles.DistWindow)

% Data to plot
pars = get(handles.ParTable,'data'); % Parameter values in the par table
parnames = get(handles.ParTable,'rowname'); % Parameter names
decaychoices = get(handles.DecaysListbox,'Value'); % Selected decays
decays = get(handles.decays,'UserData'); % Loaded decays

% Plot type:
plottype = get(handles.Edit_ParPlotSettings,'UserData');

xmax = []; % For setting xlim in final plot
ylab = 'Fraction'; % y-label
for i = 1:length(decaychoices) % Loop all selected decays
    
    if strcmp(modelname,'single_exp') % If selected model is single-exponential
        if i == 1 % First decay
            bar(handles.DistWindow,pars(1,i),1,0.15, 'r') % Red bar-plot
        else
            bar(handles.DistWindow, pars(1,i), 1, 0.15, 'FaceColor',decays(decaychoices(i)).color) % Bar plot with same color as decay
        end
        xmax = [xmax; pars(1,i)*2]; % max x-value (ns)
        
    elseif strcmp(modelname,'double_exp') % If selected model is double-exponential
        if strcmp(plottype,'aw') % Amplitude-weighted plot
            if i == 1 % First decay
                bar(handles.DistWindow,pars([2 3],i),[pars(1,i) (1-pars(1,i))],0.05, 'r') % Red bar-plot
            else
                bar(handles.DistWindow,pars([2 3],i),[pars(1,i) (1-pars(1,i))],0.05, 'FaceColor',decays(decaychoices(i)).color) % Bar plot with same color as decay
            end
        elseif strcmp(plottype,'iw') % Intensity weighted plot
            sum = pars(1,i)*pars(2,i)+(1-pars(1,i))*pars(3,i); % Weighted sum of lifetimes
            if i == 1 % First decay
                bar(handles.DistWindow,pars([2 3],i),[pars(1,i)*pars(2,i)/sum  (1-pars(1,i))*pars(3,i)/sum],0.05, 'r') % Red bar plot
            else
                bar(handles.DistWindow,pars([2 3],i),[pars(1,i)*pars(2,i)/sum  (1-pars(1,i))*pars(3,i)/sum],0.05, 'FaceColor',decays(decaychoices(i)).color) % Bar plot with same color as decay
            end
            ylab = 'Fraction (int.)'; % y-label
        end
        xmax = [xmax; max(pars([2 3],i))+min(pars([2 3],i))]; % max ns
        
    elseif strcmp(modelname,'triple_exp') % Triple-exponential decay model
        if strcmp(plottype,'aw') % Amplitude-weighted plot
            if i == 1 % First decay
                bar(handles.DistWindow,pars([2 4 6],i),pars([1 3 5],i),0.1, 'r') % Red bar-plot
            else
                bar(handles.DistWindow,pars([2 4 6],i),pars([1 3 5],i),0.1, 'FaceColor',decays(decaychoices(i)).color) % Bar plot with same color as decay
            end
        elseif strcmp(plottype,'iw') % Intensity weighted plot
            sum = pars(1,i)*pars(2,i)+pars(3,i)*pars(4,i)+pars(5,i)*pars(6,i); % Weighted sum of decays
            if i == 1 % first decay
                bar(handles.DistWindow,pars([2 4 6],i),[pars(1,i)*pars(2,i)/sum  pars(3,i)*pars(4,i)/sum  pars(5,i)*pars(6,i)/sum],0.1, 'r') % Red bar-plot
            else
                bar(handles.DistWindow,pars([2 4 6],i),[pars(1,i)*pars(2,i)/sum  pars(3,i)*pars(4,i)/sum  pars(5,i)*pars(6,i)/sum],0.1, 'FaceColor',decays(decaychoices(i)).color)
            end
            ylab = 'Fraction (int.)'; % y-label
        end
        xmax = [xmax; max(pars([2 4 6],i))+min(pars([2 4 6],i))]; % max ns
        
    elseif strcmp(modelname,'four_exp') % Four-exponential decay model
        if strcmp(plottype,'aw') % Amplitude-weighted plot
            if i == 1 % First decay
                bar(handles.DistWindow,pars([2 4 6 8],i),pars([1 3 5 7],i),0.2, 'r') % Red barplot
            else
                bar(handles.DistWindow,pars([2 4 6 8],i),pars([1 3 5 7],i),0.2, 'FaceColor',decays(decaychoices(i)).color)
            end
        elseif strcmp(plottype,'iw') % Intensity weighted plot
            sum = pars(1,i)*pars(2,i)+pars(3,i)*pars(4,i)+pars(5,i)*pars(6,i)+pars(7,i)*pars(8,i); % Weighted sum of lifetimes
            if i == 1 % First decay
                bar(handles.DistWindow,pars([2 4 6 8],i),[pars(1,i)*pars(2,i)/sum  pars(3,i)*pars(4,i)/sum  pars(5,i)*pars(6,i)/sum  pars(7,i)*pars(8,i)/sum],0.2, 'r')
            else
                bar(handles.DistWindow,pars([2 4 6 8],i),[pars(1,i)*pars(2,i)/sum  pars(3,i)*pars(4,i)/sum  pars(5,i)*pars(6,i)/sum  pars(7,i)*pars(8,i)/sum],0.2, 'FaceColor',decays(decaychoices(i)).color)
            end
            ylab = 'Fraction (int.)'; % y-label
        end
        xmax = [xmax; max(pars([2 4 6 8],i))+min(pars([2 4 6 8],i))]; % max ns
        
    elseif strcmp(modelname,'lifetime_dist') % Gaussian lifetime-distribution plot
        % Parameters
        a1 = pars(strcmp(parnames,'a1'),i); % Weight of Gaussian1
        t1 = pars(strcmp(parnames,'<t1> /ns'),i); % Center of Gaussian1
        FWHM1 = pars(strcmp(parnames,'FWHM1 /ns'),i); % Width of Gaussian 1
        ts1 = linspace(t1-FWHM1*1.5,t1+FWHM1*1.5,99)'; % time-grid of Gaussian1        
        t2 = pars(strcmp(parnames,'<t2> /ns'),i); % Center of Gaussian2
        FWHM2 = pars(strcmp(parnames,'FWHM2 /ns'),i); % Width of Gaussian2
        ts2 = linspace(t2-FWHM2*1.5,t2+FWHM2*1.5,99)'; % Time-grid of Gaussian2
        
        % Distribution
        ts = linspace(min([ts1; ts2]),max([ts1; ts2]),100); % Combined time-grid 
        P = a1*normpdf(ts,t1,FWHM1/2.3548) + (1-a1)*normpdf(ts,t2,FWHM2/2.3548); % Combined probability distribution
        
        % Remove points below 0 ns
        P(ts<0) = []; 
        ts(ts<0) = [];
        
        % Plot Gaussian dist
        if i == 1 % First decay
            plot(handles.DistWindow,ts,P,'r') % Plot in red
        else plot(handles.DistWindow,ts,P, 'Color',decays(decaychoices(i)).color) % Plot in same color as decay
        end
        
        % Get limits
        xlimits = get(handles.DistWindow,'xlim');
        xmax = [xmax; xlimits(2)];
    end
    
    hold(handles.DistWindow,'on')
end

% Set axes properties
xlim(handles.DistWindow,[0 max(xmax)])
xlabel(handles.DistWindow,'tau /ns')
ylabel(handles.DistWindow,ylab)
set(handles.DistWindow,'YTick',[])

% Update UI context menu
updateUIcontextMenus(handles.figure1,handles.DistWindow)
