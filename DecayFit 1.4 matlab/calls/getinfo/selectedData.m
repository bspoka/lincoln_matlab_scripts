function [Dchoices, Ichoices, Mchoice] = selectedData(handles)
% Returns selected spectra (listbox selection). Use selectedabs etc for
% selected spectra using data cursor.
%
%    Input:
%     handles       - handles structure of the main window
%
%    Output:
%     Dchoices      - selected decays
%     Ichoices      - selected IRF
%     baseMchoices  - selected model
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

Dchoices = get(handles.DecaysListbox,'Value'); % Selected absorption spectra
Ichoices = get(handles.IRFsListbox,'Value'); % Chosen emission spectra
Mchoice = get(handles.FitModelsListbox,'Value');
