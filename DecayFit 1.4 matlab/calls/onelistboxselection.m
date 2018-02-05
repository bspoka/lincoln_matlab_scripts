function [decaychoice,IRFchoice,ndecays,nIRFs] = onelistboxselection(handles,title,text,multi)
% Opens a modal dialog with a data listbox allowing the user to select
% decays and/or IRFs
%
%   Input:
%    handles  - handles structure of the main window
%    title    - title of the dialog window
%    text     - text displayed right next to listbox
%    multi    - if 'multi' multi-selection is enabled
%
%   Output:
%    decaychoice - selected decays
%    IRFchoice   - selected IRFs
%    ndecays     - number of decays
%    nIRFs       - number of IRFs
%

% --- Copyrights (C) ---
%
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

% Initialize
decaychoice = []; % Chosen decays
IRFchoice = []; % Chosen IRFs
ndecays = 0; % Number of decays chosen
nIRFs = 0; % Number of IRFs chosen
decays = get(handles.decays,'UserData'); % Loaded decays
IRFs = get(handles.IRFs,'UserData'); % Loaded IRFs

% Default
if nargin<4
    multi = 'multi';
end

% Prepare dialog box
%--------- Get plots ---------%
plots = getdatalistStr(decays,IRFs);
%-------------------------------------%

%--- Prepare choose plot dialog box ----%
prompt = {text 'selection'}; % Item in dialog
name = title; % Title of dialog

formats = struct('type', {}, 'style', {}, 'items', {}, ...
    'format', {}, 'limits', {}, 'size', {}); % Initialize formats structure

formats(2,1).type = 'list';
formats(2,1).style = 'listbox';
formats(2,1).items = plots;
formats(2,1).size = [400 400];
if strcmp(multi,'multi')
    formats(2,1).limits = [0 2]; % multi-select
end
options.CancelButton = 'on';

[answer, cancelled] = myinputsdlg(prompt, name, formats, [], options); % Open dialog box
if cancelled == 1
    return
end
selection = {plots{answer.selection}}';
%---------------------------------------%

% Interpret selected data from dialog box
for i = 1:length(answer.selection)
    if (~isempty(decays)) && (answer.selection(i)<=length(decays))
        ndecays = ndecays+1;
        decaychoice(end+1) = answer.selection(i);
    elseif (isempty(decays))
        nIRFs = nIRFs+1;
        IRFchoice(end+1) = answer.selection(i);
    elseif (~isempty(decays)) && (answer.selection(i)>length(decays))
        nIRFs = nIRFs+1;
        IRFchoice(end+1) = answer.selection(i)-length(decays);
    end
end
