function [residuals,ChiSqTot] = opt1glob(vars)
% Global optimization
%
%    Input:
%     vars
%
%    Output:
%     residuals   - residuals..
%     ChiSqTot    - Total chi-square
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

Global = getappdata(0,'Global');
pars_global = getappdata(0,'pars_global');
pars_global(getappdata(0,'pg_index2'),:) = vars;
pg_index = getappdata(0,'pg_index');
handles = getappdata(0,'handles');
nsamples = length(Global);
modelchoice = get(handles.FitModelsListbox,'Value');
ndatapoints = getappdata(0,'ndatapoints');
handles = getappdata(0,'handles');
model = cellstr(get(handles.FitModelsListbox,'String'));
model = model(get(handles.FitModelsListbox,'Value'));

residuals = zeros(ndatapoints,1); l = 1;
ChiSqTot = 0;
for i = 1:nsamples
    
    % Data
    setappdata(0,'t',Global(i).t)
    setappdata(0,'decay',Global(i).decays)
    setappdata(0,'IRF',Global(i).IRFs)
    setappdata(0,'weights',Global(i).weights)
    setappdata(0,'tail',Global(i).tail)
    
    % Parameters
    pars = Global(i).pars{modelchoice,1};
    pars(pg_index,1) = pars_global;
    pars(pg_index,2) = pars_global;
    pars(pg_index,3) = pars_global;
    p_index = find(pars(:,2)~=pars(:,3));
    
    start = pars(p_index,1);
    lower = pars(p_index,2);
    upper = pars(p_index,3);
    
    %---- First do rough optimization ----%
    setappdata(0,'pars',pars(1:end-1,1)), setappdata(0,'p_index',p_index(1:end-1))
    X = fminsearchbnd(@opt1,start(1:end-1), lower(1:end-1), upper(1:end-1),...
        optimset('MaxFunEvals',2500,'MaxIter',500,'TolFun',0.05, 'TolX', 0.05,'Display','off'));
    pars(p_index,1) = [X; getappdata(0,'I0')];
    %---- Then do full opt ----%
    setappdata(0,'pars',pars(:,1)), setappdata(0,'p_index',p_index)
    start = pars(p_index,1);
    [X,ChiSq,res] = lsqnonlin(@opt2,start,lower,upper, optimset('MaxFunEvals',5000,'Display','off')); % Optimziation of local parameters
    %--------------------------%
    fit = getappdata(0,'fit');
    res = getappdata(0,'resfull');
    pars(p_index,1) = X;
    Global(i).pars{modelchoice,1}(:,1) = pars(:,1);
    Global(i).ChiSq(modelchoice,1) = ChiSq/length(res);
    Global(i).fits{modelchoice,1} = [Global(i).t fit];
    Global(i).res{modelchoice,1} = [Global(i).t res];
    residuals(l:(l-1)+length(Global(i).t)) = res; %Sqrted? Weighted?
    if strcmp(model{:},'triple_exp')
        temp = Global(i).pars{modelchoice,1};
        Global(i).pars{modelchoice,1}(1,1) = temp(1,1)/(temp(1,1)+temp(3,1)+temp(5,1));
        Global(i).pars{modelchoice,1}(3,1) = temp(3,1)/(temp(1,1)+temp(3,1)+temp(5,1));
        Global(i).pars{modelchoice,1}(5,1) = temp(5,1)/(temp(1,1)+temp(3,1)+temp(5,1));
    elseif strcmp(model{:},'four_exp')
        temp = Global(i).pars{modelchoice,1};
        Global(i).pars{modelchoice,1}(1,1) = temp(1,1)/(temp(1,1)+temp(3,1)+temp(5,1)+temp(7,1));
        Global(i).pars{modelchoice,1}(3,1) = temp(3,1)/(temp(1,1)+temp(3,1)+temp(5,1)+temp(7,1));
        Global(i).pars{modelchoice,1}(5,1) = temp(5,1)/(temp(1,1)+temp(3,1)+temp(5,1)+temp(7,1));
        Global(i).pars{modelchoice,1}(7,1) = temp(7,1)/(temp(1,1)+temp(3,1)+temp(5,1)+temp(7,1));
    end
    
    l = l+length(Global(i).t);
    ChiSqTot = ChiSqTot+ChiSq/length(res);
    
end

iter = getappdata(0,'iter');
set(handles.RunStatusTextbox,'String',sprintf('Running global fit: %i iterations...',iter))
pause(0.0001)
setappdata(0,'iter',iter+1)

setappdata(0,'ChiSqTot',ChiSqTot/nsamples)
setappdata(0,'Global',Global)
