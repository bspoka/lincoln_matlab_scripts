function mainhandles = myguidebox(mainhandles, name, textstr, id)
% Creates a user guide info box with a checkbox for not showing box again
% in the future
%
%      Input:
%       mainhandles   - handles structure of the main window
%       name          - title of box
%       textstr       - info text string
%       id            - field name of relevant infobox in settings.infobox
%                       structure
%
%      Output:
%       mainhandles   - ...
%
%      Example:
%       % Display userguide info box
%       textstr = sprintf(['You have activated the pixel selection tool. How to select background pixels manually:\n\n'...
%       '  1) Using the activated crosshair, point at the first pixel of interest.\n'...
%       'The intensity and FRET traces are automatically updated according to the new background pixels.\n\n ']);
%       set(mainhandles.mboard, 'String',textstr)
%       mainhandles = myguidebox(mainhandles, 'Set background pixels', textstr, 'backgroundPixels');


% --- Copyrights (C) ---
%
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

if nargin<4
    return
end

% Show message in message board no matter what
set(mainhandles.mboard, 'String',textstr)

if ~isfield(mainhandles.settings.infobox, id) || ~mainhandles.settings.infobox.(id)
    return
end

% Prepare dialog
prompt = {textstr '';...
    'Don''t show this box again ' 'choice'};
formats = struct('type', {}, 'style', {}, 'items', {}, ...
    'format', {}, 'limits', {}, 'size', {});
formats(2,1).type   = 'text';
formats(4,1).type   = 'check';
DefAns.choice = 0;
options.CancelButton = 'off';

% Open dialog
answer = myinputsdlg(prompt, name, formats, DefAns, options);

% Store the choice of whether to show this message again
if answer.choice
    % Update current settings structure
    mainhandles.settings.infobox.(id) = 0;
    updatemainhandles(mainhandles)
    
    % Update default settings structure file
    settings = loadDefaultSettings(mainhandles, mainhandles.settings); % Current default settings
    settings.infobox.(id) = 0;
    saveDefaultSettings(mainhandles, settings)
end
