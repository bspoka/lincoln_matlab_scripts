function file = exportfit(handles,decaychoice,IRFchoice,modelchoice,fit,res,scatter,ChiSq,ChiSqGlob)
% Exports fits to ascii
%
%   Input:
%    handles      - handles structure of the main window
%    decaychoice  - decays to export
%    IRFchoices   - IRFs to export
%    modelchoice  - the fit model to export
%    fit          - Fitted spectrum
%    res          - Residual
%    scatter      - scatter
%    ChiSq        - Chi-square value
%    ChiSqGlobal  - Global chi-square
%
%   Output:
%    file         - output filename

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

model = get(handles.FitModelsListbox,'String'); % Models
model = model{modelchoice}; % Selected model
fits = get(handles.fits,'UserData'); % All fits
pars = fits(decaychoice,IRFchoice,modelchoice).pars; % Parameters
parrows = get(handles.ParTable,'rowname'); % Name of paramaters

% Get data
decays = get(handles.decays,'UserData'); % Loaded decays
IRFs = get(handles.IRFs,'UserData'); % Loaded IRFs
if (isempty(decays)) || (isempty(IRFs))
    set(handles.mboard,'String',sprintf(...
        'No decay input\n'))
    return
end
decay = decays(decaychoice);
t = decay.data(:,1);
decay = decay.data(:,2);
IRF = IRFs(IRFchoice);

% Get tail
fits = get(handles.fits,'UserData');
tail = fits(decaychoice,IRFchoice,1).tail;

%--------------- Prepare data -----------------%
% Cut all data to within IRF's time-range so that interpolation can be done
while IRF.data(1,1) > t(1)
    decay = decay(2:end);
    t = t(2:end);
end
while IRF.data(end,1) < t(end)
    decay = decay(1:end-1);
    t = t(1:end-1);
end

% Grid IRF onto t.decay
IRF = interp1(IRF.data(:,1),IRF.data(:,2),t,'spline');
IRF(IRF<0) = 0;

% IRF shift:
shifttable = get(handles.ShiftTable,'data');
shift = shifttable(1);
L = shifttable(2);  % Interpolation factor
ti = interp1(t,1:1/L:size(t,1))'; % Put in extra t's
IRF = interp1(t,IRF,ti,'spline'); % Interpolate
IRF = circshift(IRF,shift); % Shift IRF
IRF = IRF(1:L:end); % Reduce to original size
IRF(IRF<0) = 0;

% Subtract baseline:
IRF = IRF-IRFs(IRFchoice).zero;
decay = decay-decays(decaychoice).zero;
IRF(IRF<0) = 0;
decay(decay<0) = 0;

% Get time-interval
try ti = decays(decaychoice).ti;
    if isempty(ti)
        ti = [t(1) t(end)];
    end
catch err
    ti = [t(1) t(end)];
end
[~,t1] = min(abs(t(:)-ti(1)));
[~,t2] = min(abs(t(:)-ti(2)));

% Set data
t = t(t1:t2);
decay = decay(t1:t2);
IRF = IRF(t1:t2);


%------------ Save file -----------------%
[file, path, chose] = uiputfile2_results('*.txt;*.csv;*.dat','Export fit');
if chose == 0
    return
end
datafile = fullfile(path,file);

fileID = fopen(datafile,'w');
fprintf(fileID,'%%------------- Decay fit results summary -------------%%\n\n');
fprintf(fileID,'Fit by DecayFit v%s\n     %s\n\n',handles.version,date);
if strcmp(get(handles.GlobalFit,'State'),'on')
    fprintf(fileID,'Part of a global fit:\n');
end
fprintf(fileID,'Decay: %s\n',decays(decaychoice).name);
fprintf(fileID,'IRF: %s\n\n',IRFs(IRFchoice).name);
fprintf(fileID,'Fitted time-interval: %3.3f - %3.3f ns\n\n',ti);
fprintf(fileID,'Decay model: %s,   %s\n\n',model,get(handles.ModelText,'String'));
fprintf(fileID,'IRF background subtraction (counts): %i\n',IRFs(IRFchoice).zero);
fprintf(fileID,'Decay background subtraction (counts): %i\n\n',decays(decaychoice).zero);
if ~isempty(tail)
    fprintf(fileID,'Tailfit start time: %.3f\n\n',tail)
end
if strcmp(get(handles.GlobalFit,'State'),'off')
    fprintf(fileID,'Chi-square = %.3f\n\n',ChiSq);
else
    fprintf(fileID,'Chi-square = %.3f   (Global = %.3f)\n\n',ChiSq,ChiSqGlob);
end
fprintf(fileID,'Fit parameters:\n');
for i=1:size(pars,1)
    fprintf(fileID,'%s = %.5f\n',parrows{i,1},pars(i,1));
end
fprintf(fileID,'Shift: %.3f channels\n',shifttable(1)/shifttable(2));
fprintf(fileID,'Scatter: %.3f\n\n',scatter*100);
fprintf(fileID,'[t/ns]      [Decay]       [IRF]       [Fit]     [Residual]\n');
try
    dlmwrite(datafile,[t decay IRF fit(:,2) res(:,2)],'-append','delimiter', '\t','precision','%.5f');
catch err
    if strcmp(err.identifier,'MATLAB:catenate:dimensionMismatch')
        set(handles.mboard,'String',sprintf(...
            'Export failed. Please run fit again.\n'))
    end
    fclose(fileID);
    return
end
fclose(fileID);

set(handles.mboard,'String',sprintf(...
    'Fit saved to %s (you may want to view it in WordPad rather than Notepad)\n',file))
