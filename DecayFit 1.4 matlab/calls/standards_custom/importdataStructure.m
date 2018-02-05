function [outputdata, message] = importdataStructure(mainhandles, inputdata)
% Corrects data structure so that fields in input data
% match the fields of the current software version data structure. Missing
% fields will be pouplated by default values. Excess fields will be removed
%
%     Input:
%      mainhandles   - handles structure of the main window
%      inputdata     - data structure to import
%      onlytraces    - Don't import raw movie data
%
%     Output:
%      outputdata   - formatted data structure
%      message      - potential warning about version compatibility
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

%% Initialize
message = '';
outputdata = inputdata;

%% Load data template file
dataTemplateFile = fullfile( mainhandles.workdir, 'calls', 'stateSettings', 'data.template' );

% Open default data template file
temp = load(dataTemplateFile, '-mat');
if ~isfield(temp,'dataTemplate')
    set(mainhandles.mboard, ...
        'String', sprintf('OBS!\n%s (%s).\n%s',...
        'The data-template file does not contain a data structure template',...
        dataTemplateFile,...
        'If the session is from a previous software version, compatibility-related errors may occur.'))
    return
end

%% Import data

% Load data template.
datatemplate = temp.dataTemplate; % Template data structure

% Sort so the order of fields match
datatemplate = orderfields(datatemplate);

% If there is no data in input data, make default structure
if isempty(inputdata)
    outputdata = storeData([]); % Initializes data structure
    outputdata(1) = [];
    return
else
    inputdata = orderfields(inputdata);
end


% Fields
loadedFields = fieldnames(inputdata); % Fields in loaded data structure
correctFields = fieldnames(datatemplate); % Fields in template data structure

% If structures are not equal
if ~isequal(loadedFields,correctFields)
    message = sprintf(...
        'OBS!\n%s',...
        'The loaded session is from a different software version. The program has tried to correct for this, but compatibility-related errors may occur.');
end

% Remove fields that are no longer used
removeFields = find( ~ismember(loadedFields,correctFields) );
for i = 1:length(removeFields)
    inputdata = rmfield( inputdata,loadedFields{removeFields(i)} );
end

% Add the fields that are not defined in the session file
    
% Add fields for all data items
temp = addfields(inputdata(1));
if length(inputdata)>1
    for i = 2:length(inputdata)
        temp(i) = addfields(inputdata(i));
    end
end
inputdata = temp;

% Output data structure
outputdata = orderfields(inputdata);

%% Nested

    function data = addfields(data)
        
        for j = 1:numel(correctFields)
            % Check all fields that are supposed to be there
            
            if ~isfield(data,correctFields{j} )
                
                % If correct field j is not a field in loaded data structure
                data.(correctFields{j}) = datatemplate.(correctFields{j});
                continue
            end
            
            % Check sub-field names within data.(loadedFields{i})
            if isstruct( datatemplate.(correctFields{j}) )
                
                % Check if field is supposed to be sub structure, but is not
                if ~isstruct( data.(correctFields{j}) )
                    data.(correctFields{j}) = datatemplate.(correctFields{j});
                    continue
                end
                
                % Sub fields
                correctsubFields = fieldnames( datatemplate.(correctFields{j}) );  % Subfieldnames
                loadedsubFields = fieldnames( data.(correctFields{j}) );
                
                % Remove subfields that are no longer used
                removeFields = find( ~ismember(loadedsubFields,correctsubFields) );
                for l = 1:length(removeFields)
                    data.(correctFields{j}) = rmfield( data.(correctFields{j}) , loadedsubFields{removeFields(l)});
                end
                
                % Add needed subfields
                for k = 1:numel(correctsubFields)
                    
                    if ~isfield( data.(correctFields{j}) , correctsubFields{k} )
                        
                        %                     if strcmpi( correctFields{j},'FRETpairs' )
                        %
                        %                         % If it's the FRETpairs field structure. Create
                        %                         % missing field and set it's value to [] in all
                        %                         % FRET pairs
                        %                         if ~isempty(inputdata(i).FRETpairs)
                        %
                        %                             inputdata(i).FRETpairs(end).(correctsubFields{k}) = [];
                        %
                        %                         else
                        %
                        %                             inputdata(i).FRETpairs(1).(correctsubFields{k}) = [];
                        %                             inputdata(i).FRETpairs(:) = [];
                        %                         end
                        %
                        %                     else
                        % If it's a field structure other than FRETpairs
                        data.(correctFields{j}).(correctsubFields{k}) = datatemplate.(correctFields{j}).(correctsubFields{k});
                        %                     end
                        
                    end
                    
                end
                
            else
                
                % If field is not supposed to be sub structure, but is
                if isstruct( data.(correctFields{j}) )
                    data.(correctFields{j}) = datatemplate.(correctFields{j});
                    continue
                end
                
            end
        end
        
    end
end