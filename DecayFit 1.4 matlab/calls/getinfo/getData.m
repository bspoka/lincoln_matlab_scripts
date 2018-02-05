function [decays, IRFs, fits] = getSpectra(handles)
% Returns the currently loaded data
%
%    Input:
%     handles    - handles structure of the main window
%
%    Output:
%     decays     - loaded decays
%     IRFs       - loaded IRFs
%     fits       - fits
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

% Data is currently stored as user data in individual gui objects.
decays = get(handles.decays, 'UserData'); % Loaded absorption spectra
IRFs = get(handles.IRFs, 'UserData'); % Loaded emission spectra
fits = get(handles.fits, 'UserData'); % Loaded absorption baselines

