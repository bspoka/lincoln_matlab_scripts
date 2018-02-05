function [res,Lpars,fit] = opt2t(NLpars) 
% Optimization of non-linear pars in triple exponential decay
%
%    Input:
%     NLpars   - non-linear parameters
%
%    Output:
%     res      - residuals
%     Lpars    - linear parameters
%     fit      - fitted model
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

% Get parameter values
pt_index = getappdata(0,'pt_index');
p = getappdata(0,'pars');
p(pt_index) = NLpars;

% Get data
handles = getappdata(0,'handles');
IRF = getappdata(0,'IRF');
decay = getappdata(0,'decay');
t = getappdata(0,'t');
weights = getappdata(0,'weights');
tail = getappdata(0,'tail');
I0 = p(end);

% Make m x 3 matrix containing each exponential decay component
sim = zeros(length(decay),3);
for i = 2:2:6
    if get(handles.IncludeScatterCheckbox,'Value') == 0
        sim(:,i/2) = I0*fftfilt(IRF,exp(-t/p(i)));
    else
        a = p(end-1);
        sim(:,i/2) = I0*( (1-a)*fftfilt(IRF,exp(-t/p(i))) + a*IRF );
    end
end

% Do the linear regression using lsqlin
Aeq = [1 1 1]; % Equality constraints: a1 + a2 + a3 = 1 (Aeq*LP = beq)
beq = 1;       % Equality constraints: a1 + a2 + a3 = 1
lowerLP = getappdata(0,'lowerLP');
upperLP = getappdata(0,'upperLP');
startLP = getappdata(0,'startLP');

options = optimset('lsqlin');
options = optimset(options,'LargeScale','off','Display','off');

Lpars = lsqlin(sim.*repmat(weights,1,3),decay.*weights,[],[],Aeq,beq,lowerLP,upperLP,startLP,options); % Optimize linear parameters

fit = sim*Lpars;
resfull = (fit - decay).*weights;
res = (fit(tail:end) - decay(tail:end)).*weights(tail:end);

setappdata(0,'startLP',Lpars)
setappdata(0,'resfull',resfull)
