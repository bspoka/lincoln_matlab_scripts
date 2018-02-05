function plotdist(handles)
% Plot D-A distribution in lifetime window
%
%    Input:
%     handles  - handles structure of the main window
%

% --- Copyrights (C) ---
%
% This file is part of:
% DecayFit - Time-Resolved Fluorescence Decay Analysis Software
% Copyright (C) 2013  Søren Preus, www.fluortools.com
%
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
%
%     The GNU General Public License is found at
%     <http://www.gnu.org/licenses/gpl.html>.

set(handles.Stop,'State','off') % Turn off stop button

% Gaussian dist:
modelchoice = get(handles.FitModelsListbox,'String');
if (~strcmp(modelchoice{get(handles.FitModelsListbox,'Value')},'FRET')) || (strcmp(get(handles.GlobalFit,'State'),'on'))
    return
end
reset(handles.DistWindow)
cla(handles.DistWindow)
set([handles.Colortext1 handles.Colortext2 handles.Colortext3 handles.Colortext4],'Visible','off')

decays = get(handles.decays,'UserData');
decaychoices = get(handles.DecaysListbox,'Value');
partable = get(handles.ParTable,'data');
parnames = get(handles.ParTable,'rowname');

for i = 1:length(decaychoices)
    pars = partable(:,i);
    
    Rm = pars(strcmp(parnames,'R-mean /Å'));
    FWHM = pars(strcmp(parnames,'FWHM /Å'));
    r = linspace(Rm-FWHM*1.5,Rm+FWHM*1.5,100)';
    P = normpdf(r,Rm,FWHM/2.3548);
    P(r<0) = [];
    r(r<0) = [];
    if i == 1
        plot(handles.DistWindow,r,P,'r')
    else
        plot(handles.DistWindow,r,P, 'Color',decays(decaychoices(i)).color)        
    end
    xlabel(handles.DistWindow,'R')%,'fontsize',10.67,'fontname','Arial')
    set(handles.DistWindow,'YTick',[])
    hold(handles.DistWindow,'on')
end

% Imported dist:
if get(handles.ImportDistCheckbox,'Value') == 0
    return
end
dists = get(handles.DistTextbox,'UserData');
if isempty(dists)
    return
end
dist = dists{get(handles.DAdistListbox,'Value')};

% Truncate ends
T = str2double(get(handles.TruncateEditbox,'String'));
while min(dist(:,2))/max(dist(:,2)) < (100-T)/100
    dist(dist(:,2)==min(dist(:,2)),:) = [];
end
dist = [dist(:,1) abs(dist(:,2)/min(dist(:,2)))];
set(handles.DistTextbox,'UserData',dists)


% Make grid for plot
Rmean = sum(dist(:,1).*dist(:,2))/sum(dist(:,2)); % Mean of imported
dist(:,1) = dist(:,1)-Rmean; % Move so that mean is at 0
% [X,Y] = meshgrid(r,dist(:,1));
Z = P*dist(:,2)';

% Interpolate:
xi = linspace(min(dist(:,1)), max(dist(:,1)), 90);% length(dist(:,1))*50);
yi = linspace(min(r), max(r), 90);%length(r)*50);
[xi,yi] = meshgrid(xi,yi);
zi = interp2(dist(:,1),r,Z,xi,yi);


% Do the plotting
if get(handles.TwoDviewCheckbox,'Value') == 0
    R = xi+yi;
    Rs = reshape(R,numel(R),1); %split into x and y
    Ps = reshape(zi,numel(zi),1);
    numBins = 50;
    binEdges = linspace(min(Rs), max(Rs), numBins+1);
    [~,whichBin] = histc(Rs, binEdges);
    for i = 1:numBins
        flagBinMembers = (whichBin == i);
        binMembers     = Ps(flagBinMembers);
        binSum(i)      = sum(binMembers);
    end
    bins = binEdges(1:end-1)+((binEdges(2)-binEdges(1))/2); % Center of each bin
    Rc = bins; % R combined
    Pc = binSum; % P combined
    
    % Do the plotting
    Rmean1 = sum(r.*P/sum(P)); % Mean of Gaussian
    Rmean2 = sum(dist(:,1).*dist(:,2))/sum(dist(:,2)); % Mean of imported
    dist(:,1) = dist(:,1) - (Rmean2-Rmean1); % Move imported into Gaussian mean
    dist(dist(:,1)<0,:) = [];
    
    bar(handles.DistWindow,Rc,Pc/trapz(Rc,Pc),'b','LineStyle','none','BarWidth',1), hold(handles.DistWindow,'on')
    bar(handles.DistWindow,dist(:,1),dist(:,2)/trapz(dist(:,1),dist(:,2)),'g','LineStyle','none','BarWidth',1), hold(handles.DistWindow,'on') % Plot imported
    plot(handles.DistWindow,Rc,Pc/trapz(Rc,Pc),'k','LineWidth',1)
    
    plot(handles.DistWindow,r,P/trapz(r,P),'r','LineWidth',1) % Plot Gaussian
    
    xlabel(handles.DistWindow,'R','fontname','Arial')%,'fontsize',10.67
    set(handles.DistWindow,'YTick',[])
    set([handles.Colortext1 handles.Colortext2 handles.Colortext3 handles.Colortext4],'Visible','on')
    set(handles.Colortext1,'BackgroundColor',[0 1 0])
    set(handles.Colortext3,'BackgroundColor',[0 0 1])

    % 2D surface
elseif get(handles.TwoDviewCheckbox,'Value') == 1
    hold(handles.DistWindow,'off')
    mesh(handles.DistWindow,xi,yi,zi)
    view(handles.DistWindow,[0,90])
    axis(handles.DistWindow,'tight')
    xlabel(handles.DistWindow,'(+) R-linker /Å')
    ylabel(handles.DistWindow,'(+) R-molecule /Å')
    
    return
end

% Update UI context menu
updateUIcontextMenus(handles.figure1,handles.DistWindow)
