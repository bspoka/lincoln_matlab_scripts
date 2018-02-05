function loaddata(handles,choice,filepath)
% Load data into decay and IRF structure
%
%    Input:
%     handles   - handles structure of the main window
%     choice    - 'IRF', 'Decay' or 'Wizard'
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

% Default
if nargin<2 || isempty(choice)
    choice = 'decay';
end
if nargin<3 || isempty(filepath)
    filepath = [];
end

% File
if isempty(filepath)
    
    % Open file dialog
    fil = {'*.txt;*.dat;*.csv' 'ASCII files'; '*.*' 'All files'};
    if strcmpi(choice,'IRF')
        [filename, dir, chose] = uigetfile3(handles,'data',fil,'Load IRFs',' ','on');
        %         [filename, dir, chose] = uigetfile2_data({'*.txt;*.dat;*.csv'},'Load IRFs','MultiSelect','on');
    else
        [filename, dir, chose] = uigetfile3(handles,'data',fil,'Load decays',' ','on');
        %         [filename, dir, chose] = uigetfile2_data({'*.txt;*.dat;*.csv'},'Load decays','MultiSelect','on');
    end
    if chose == 0
        return
    end
    
else
    
    % Use input filepath
    [dir, name, ext] = fileparts(filepath);
    filename = [name ext];
end

% Import data
if iscell(filename) % If multiple files are selected
    nfiles = size(filename,2);
else nfiles = 1;
    filename = {filename};
end

decays = get(handles.decays,'UserData'); % Loaded decays
IRFs = get(handles.IRFs,'UserData'); % Loaded IRFs
defMessage = 0; % Show message about new default settings
choice = []; % Choice of whether to shift time-vector so that it starts at zero
choice2 = [];
for i = 1:nfiles % Loop all selected files
    name = filename{i}; % Name string of file i
    input_filename = fullfile(dir,name); % Full path of file i
    
    % Initialize new data structure field
    tempvector = storeData(decays, [], name(1:end-4), handles);
    tempvector(:) = [];
    
    % first try automatic import
    try
        if strcmpi(choice,'wizard') % If forcing import wizard from the file menu, skip trying
            error
        end
        
        % Automatic import
        temp = importdata(input_filename);
        
        % Check if input temp structure has a data field
        if isstruct(temp)
            temp = checkTempDataStructure(temp);
            
            % Only use imported data
            temp = temp.data;
        end
        
    catch err % If first automated attempt failed
        
        try % Then try using default no. of headerlines
            if strcmpi(choice,'wizard') % If forcing import wizard from the file menu, skip trying
                error
            end
            
            % Automatic import
            temp = importdata(input_filename, '\t', handles.settings.loaddata.nheaderlines+1);
            
            % Check if input temp structure has a data field
            if isstruct(temp)
                % Check if input temp structure has a data field
                temp = checkTempDataStructure(temp);
                
                % Only use imported data
                temp = temp.data;
            end
            
        catch % If second automated import failed, open import wizard
            % Open import wizard
            temp = uiimport(input_filename);
            
            % Check input data field
            if isempty(temp)
                return
            elseif ~myIsField(temp,'data') % There must be a fieldname data
                fnames = fieldnames(temp);
                if length(fnames)==1
                    temp.data = getfield(temp, fnames{1});
                else
                    set(handles.mboard,'String',sprintf(...
                        'Import wizard failed. Make sure number of header lines is specified correctly and that import contains a fieldname ''data'' of class ''double''\n'))
                    return
                end
            end
            if ~isnumeric(temp.data)
                set(handles.mboard,'String',sprintf(...
                    'Input data not understood. Make sure that import contains a fieldname ''data'' with class ''double''\n'))
                return
            end
            
            % Save no. of headerlines as default
            if myIsField(temp,'textdata')
                handles.settings.loaddata.nheaderlines = size(temp.textdata,1); % New no. of headerlines
                %                 handler.settings.loaddata.delimiter = delimiter; % New delimiter
                guidata(handles.figure1,handles) % Update handles structure
                saveDefaultSettings(handles); % Save settings structure to file
                
                defMessage = 1;
            end
            
            % Only use imported data
            temp = temp.data;
        end
    end
    
    % If there is no data
    if isempty(temp)
        continue
    end
    
    % Columns
    ncolumns = size(temp,2); % Number of columns
    x = []; % Initialize time-vector
    y = []; % Initialize counts-vector
    for c = 1:ncolumns % Loop all columns
        
        % Detect column type. If more than 99% of the values in vector c
        % are increasing or decreasing (compared to the value just before),
        % assume it's an x vector
        vec = temp(:,c); % Data vector c
        vec(isnan(vec)) = []; % Remove all nan
        if (length( find(diff(vec)>0) ) >= round(0.95*length(vec)))  ||  (length( find(diff(vec)<0) ) >= round(0.95*length(vec)))
            x = vec; % Interpret column c as time-vector
            x(isnan(x)) = []; % Remove NaN
            y = []; % Reset y-data
        else
            y = vec; % Interpret column c as intensity vector
            y(isnan(y)) = []; % Remove NaN
        end
        
        % Check x,y data
        if ~isnumeric(x) || ~isnumeric(y) || ismember(1,isnan(x)) || ismember(1,isnan(y)) || isempty(y)
            continue % Also if only an x-vector is detected, this will continue to next column
        end
        
        % If time-vector must be defined
        if isempty(x) || length(x)~=length(y)
            nschannel = str2double(...
                myinputdlg(sprintf('Enter ns/channel: '),'DecayFit',1,{num2str(handles.settings.data.nschannel)}) ); % Open dialog for setting time vector
            if isempty(nschannel) || ~isnumeric(nschannel) % Check input
                return
            end
            
            x = linspace(0,nschannel*(length(y)-1),length(y))'; % New time vector
            
            % Update default nschannel value
            handles.settings.data.nschannel = nschannel;
            guidata(handles.figure1,handles) % Update handles structure
            saveDefaultSettings(handles); % Save current settings structure to a file
        end
        
        % Set all negative values to zero
        if ~handles.settings.data.negatives
            y(y<0) = 0;
        end
        
        % Turn off log-scale
        if (min(y(:))<=0 || max(y(:))<=1) && handles.settings.view.logscale
            handles.settings.view.logscale = 0;
            updatemainhandles(handles)
            updateGUImenus(handles)
        end
        
        % Put [x y] into temporary data structure
        if length(x)>10
            
            % Check if time starts at zero
            if x(1)>=1 || x(1)<0
                if isempty(choice)
                    choice = myquestdlg(sprintf(['The time vector does not start at t = 0, which is recommended.\n\n '...
                        'Do you wish to shift the vector so that it starts at t = 0?\n ']),...
                        'Shift time vector',...
                        ' Yes ', ' No ', ' Yes ');
                end
                if strcmpi(choice,' Yes ');
                    x = x-x(1);
                end
            end
            
            % Check time units
            if max(x(:))<1e-2
                if isempty(choice2)
                    
                    % Ask to multiply time
                    factor = str2double(...
                        myinputdlg(sprintf(['OBS: The largest time in %s is %.5g.\n\n'...
                        'Do you wish to multiply the time vector to make it in units of ns (the program default)?\n\n'...
                        'Yes, multiply time by a factor:'],name,max(x(:))),...
                        'Time units',...
                        1,...
                        {num2str(handles.settings.loaddata.multiplytime)}));
                    
                    if ~isempty(factor) && isnumeric(factor) % Check input
                        
                        % Update default default value
                        handles.settings.loaddata.multiplytime = factor;
                        updatemainhandles(handles)
                        saveDefaultSettings(handles); % Save current settings structure to a file
                        
                        choice2 = ' Yes ';
                    else
                        
                        choice2 = ' No ';
                    end
                    
                end
                
                if strcmpi(choice2,' Yes ');
                    x = double(x)*double(handles.settings.loaddata.multiplytime);
                end
            end
            
            % Create new data item
            if ncolumns>2
                name = sprintf('%s;Column%i',name(1:end-4),c);
            else
                name = name(1:end-4);
            end
            tempvector = storeData(tempvector, [x(:) y(:)], name, handles);
        end
    end
    
    % Put in decays and IRFs structure
    if ~isempty(tempvector)
        if strcmpi(choice,'IRF')
            IRFs(end+1:end+length(tempvector)) = tempvector;
        else
            decays(end+1:end+length(tempvector)) = tempvector;
        end
    end
end

%% Save default data structure format to file
% (for software version compatibility)

savedataTemplate(handles, tempvector(end));

%% Update

% Show message
if defMessage
    % Display messagebox about new defaults
    mymsgbox(sprintf('%s\n\n%s',...
        'Note that these import settings (no. of headerlines) are now used as defaults when attempting automated data import in the future.',...
        'To restore original settings go to the File menu.'),...
        'New settings saved')
end

% Update data structures
set(handles.decays,'UserData',decays)
set(handles.IRFs,'UserData',IRFs)

% Update
updatedecays(handles) % Update decay listbox
updateIRFs(handles) % Update IRF listbox

% Set listbox selections values
if length(decays)>=1
    set(handles.DecaysListbox,'Value',length(decays)-nfiles+1:length(decays))
else
    set(handles.DecaysListbox,'Value',1)
end

if length(IRFs)>=1
    set(handles.IRFsListbox,'Value',length(IRFs))
else
    set(handles.IRFsListbox,'Value',1)
end

updateplot(handles) % Update plot
updateParTable(handles) % Update parameter table

% Update recent files
updateRecentFiles(handles,dir,filename,'data');

