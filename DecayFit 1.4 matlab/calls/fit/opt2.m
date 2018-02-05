function res = opt2(pars) 
% Full optimization using lsqcurvefit. [pars] is [X; a; I0]. Returns y_sim,
% lsqcurvefit optimizes sum of residuals
%
%    Input:
%     pars   - model parameters
%
%    Output:
%     res    - residuals
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
p_index = getappdata(0,'p_index');
p = getappdata(0,'pars');
p(p_index) = pars;

% Get data
decay = getappdata(0,'decay');
handles = getappdata(0,'handles');
IRF = getappdata(0,'IRF');
weights = getappdata(0,'weights');
tail = getappdata(0,'tail');

I0 = p(end);
if get(handles.IncludeScatterCheckbox,'Value') == 1
    a = p(end-1);
    p = p(1:end-2);
else p = p(1:end-1); % Pars is parameter values sent to decay function
end

% Simulate fits
fun = getappdata(0,'fun');
sim = fun(p); % Simulated decay (decay-function selected in the "Fit model"-list)

% FFT convolution
convolved = fftfilt(IRF,sim);

% Include scatter
if get(handles.IncludeScatterCheckbox,'Value') == 1
    convolved = (1-a)*convolved + a*IRF;
end
% convolved = I0*convolved.*weights;
convolved = I0*convolved;

resfull = ( convolved - decay ).*weights;
res = ( convolved(tail:end) - decay(tail:end) ).*weights(tail:end);

setappdata(0,'fit',convolved)
setappdata(0,'resfull',resfull)
