function gaussianIRFcallback(handles)
% Callback for creating Gaussian IRF
%
%    Input:
%     handles   - handles structure of the main window
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

decays = get(handles.decays,'UserData');
IRFs = get(handles.IRFs,'UserData');
decaychoice = get(handles.DecaysListbox,'Value');
decaychoice = decaychoice(1);

% Prepare dialog box
prompt = {'FWHM /ps:' 'FWHM';'' '';...
    'Center /ns:' 'center';'' '';...
    'Time end /ns:' 'interval';'' '';...
    'No. of channels:' 'channels';'' '';...
    'Height /counts:' 'height';'' '';...
    'Name:' 'name'};
name = 'Make IRF';

% Handles formats
formats = struct('type', {}, 'style', {}, 'items', {}, ...
    'format', {}, 'limits', {}, 'size', {});
formats(1,1).type   = 'edit';
formats(1,1).format = 'float';
formats(1,1).size = 80;
formats(2,1).type = 'text'; % For separation
formats(3,1).type   = 'edit';
formats(3,1).format = 'float';
formats(3,1).size = 80;
formats(4,1).type = 'text'; % For separation
formats(5,1).type   = 'edit';
formats(5,1).format = 'float';
formats(5,1).size = 80;
formats(6,1).type = 'text'; % For separation
formats(7,1).type   = 'edit';
formats(7,1).format = 'float';
formats(7,1).size = 80;
formats(8,1).type = 'text'; % For separation
formats(9,1).type   = 'edit';
formats(9,1).format = 'float';
formats(9,1).size = 80;
formats(10,1).type = 'text'; % For separation
formats(11,1).type   = 'edit';
formats(11,1).format = 'text';
formats(11,1).size = 80;

% Default answers:
DefAns.FWHM = 90;
if ~isempty(decays) % Use default values from selected decay
    t = decays(decaychoice).data(:,1);
    I = decays(decaychoice).data(:,2);
    
    DefAns.center = t(I==max(I));
    DefAns.interval = t(end);
    DefAns.channels = length(t);
    DefAns.height = max(I);
else
    DefAns.center = 1;
    DefAns.interval = 50;
    DefAns.channels = 4000;
    DefAns.height = 10000;
end
DefAns.name = sprintf('IRF-%i',length(IRFs)+1);

% Open input dialogue and get answer
[answer, cancelled] = inputsdlg(prompt, name, formats, DefAns); % Open dialog box
if cancelled == 1
    return
end
FWHM = answer.FWHM/1000; % Gaussian FWHM in ns
center = answer.center; % Center of Gaussian
interval = answer.interval; % Time interval
channels = answer.channels; % No. of channels
height = answer.height; % Height in counts
name = answer.name; % Height in counts

% Make Gaussian
t = linspace(0,interval,channels)';
IRF = normpdf(t,center,FWHM/2.3548);
IRF = IRF/max(IRF)*height;

% Set new IRF
IRFs = storeData(IRFs,[t IRF],name,handles);

set(handles.IRFs,'UserData',IRFs)
updateIRFs(handles)
set(handles.IRFsListbox,'Value',length(IRFs))
updateplot(handles)