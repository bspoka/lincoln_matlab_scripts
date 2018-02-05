function [mainhandles, choseReturn] = checkforMATLAB(mainhandles, minVersionDate, requiredVersion)
% Checks for compatibility between current and required MATLAB version
%
%    Input:
%     mainhandles      - handles structure of the main window
%     minVersionData   - date of required release
%     requiredVersion  - Version required. Default: R2010a
%
%    Output:
%     handles          - ..
%     choseReturn      - 0/1
%

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

% Default
choseReturn = 0;

% Setting about checking
if isdeployed || ~mainhandles.settings.startup.checkMATLAB
    return
end

% Default
if isdeployed
    return
end
if nargin<2 || isempty(minVersionDate)
    minVersionDate = '25-Jan-2010';
end
if nargin<3 || isempty(requiredVersion)
    requiredVersion = 'R2010a';
end

% Check if current version is older than allowed
matlabVersion = ver( 'MATLAB' );
if datenum( matlabVersion.Date ) < datenum( minVersionDate )
    
    % Message to show
    message = sprintf('Sorry, you appear to be using an older version of MATLAB %s.\nThis program requires MATLAB release %s or above.',...
        matlabVersion.Release, requiredVersion);
    
    % Dialog
    reply = myquestdlg(message, 'MATLAB version',' Continue at own risk ', ' Close ', ' Close ');
    if strcmpi(reply,' Close ')
        choseReturn = 1;
    end
    
    % Put attention back to GUI. This is important in order not to crash in
    % some versions of MATLAB
    state = get(mainhandles.figure1,'Visible');
    figure(mainhandles.figure1) 
    set(mainhandles.figure1,'Visible',state)
    
else
    
    % Save setting about not checking for this again. This is in order to
    % avoid delay times on GUI startup when the license is server-based
    mainhandles.settings.startup.checkMATLAB = 0;
    saveDefaultSettings(mainhandles, mainhandles.settings)
    
end
