function ChiSq = opt1(pars) 
% Rough optimization to get I0
%
%     Input:
%      pars   - model parameters
% 
%     Output:
%      ChiSq  - chi-square value
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
handles = getappdata(0,'handles');
decay = getappdata(0,'decay');
IRF = getappdata(0,'IRF');
weights = getappdata(0,'weights');
tail = getappdata(0,'tail');

if get(handles.IncludeScatterCheckbox,'Value') == 1
    a = p(end);
    p = p(1:end-1);
end

% Simulate fits
fun = getappdata(0,'fun');
sim = fun(p); % Simulated decay

% FFT convolution
convolved = fftfilt(IRF,sim);

% Include scatter
if get(handles.IncludeScatterCheckbox,'Value') == 1
    convolved = (1-a)*convolved + a*IRF;
end
I0 = max(decay)/max(convolved);
convolved = I0*convolved;

% Evaluate chi-square:
ChiSq = sum(((decay(tail:end)-convolved(tail:end)).*weights(tail:end)).^2/length(decay(tail:end))); % Reduced chi square
% ChiSq = sum(((decay-convolved).*weights).^2/length(decay)); % Reduced chi square

setappdata(0,'I0',I0)
