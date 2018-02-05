function settings_default = loadDefaultSettings(handles, settings_internal)
% Attempts to load the default settings structure from a stored .settings
% file located at workdir/calls/stateSettings/default.settings. The
% fields of the loaded settings structure (i.e. the defaults) will replace
% the corresponding fields in the settings_internal structure. If there is
% no default settings file a new one is created.
%
%     Input:
%      handles           - handles structure of the main window
%      settings_internal - the internal settings structure which is defined
%                          initially within the program (in
%                          internalSettingsStructure.m)
%
%     Output:
%      settings_default  - new settings structure with field values defined
%                          in the default settings file
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
settings_default = settings_internal;

% Filepath
filepath = fullfile(handles.workdir,'calls','stateSettings','default.settings');

% Load settings structure from file
[settings_default message err] = loadSettings(settings_internal, filepath);

% Display message in message board
if ~isempty(err)
    if ~strcmpi(err.identifier,'MATLAB:load:couldNotReadFile')
        if isdeployed
            set(handles.mboard,'String',message)
        else
            mymsgbox(message)
        end
    end
end

% Display message about error and try resaving default settings file
if ~isempty(err)
%     try
        
        % If it was because the defaults-file was not found try to make a new
        if strcmp(err.identifier,'MATLAB:load:couldNotReadFile')
            
            % Save file with settings structure
            saveSettings(settings_internal, filepath)
            
            % Display message
            set(handles.mboard,'String',sprintf(...
                'Welcome to DecayFit!\n\nA default settings file has been created at:\n%s',...
                filepath))
%             set(handles.mboard,'String',sprintf(...
%                 'OBS! The default settings file was not found at: %s.\n\nInternal defaults are used instead and a new default settings file has been created.',...
%                 filepath))
            
        else
            
            set(handles.mboard,'String',sprintf(...
                'OBS!\nMATLAB through an error when trying to load the default settings file (%s).\nInternal defaults are used instead.\nError: %s',...
                filepath, err.message))
            
        end
%     end

end

