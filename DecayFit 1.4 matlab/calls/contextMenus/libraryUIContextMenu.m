function libraryUIContextMenu(mainhandle, fcn)
% Create ui context menu for library function
%
%    Input:
%     mainhandle  - handle to the main window
%     fcn         - library function handle
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
% Makes an UI context menu (right click menu) for the image axes
%
%    Input:
%     handles   - handles structure of the main window

% Make menu
cmenu = uicontextmenu;
uimenu(cmenu,...
    'label', 'About this function...',...
    'callback', {@doc, fun2str(fcn)})
%     'callback', {@libraryAboutFcnCallback, fun2str(fcn)})
% uimenu(cmenu,'label','menu2')
% u=uimenu(cmenu,'label','menu3');
% uimenu(u,'label','sub_menu31')
% uimenu(u,'label','sub_menu32')

% Set menu as context menu for the plotted image
% if isfield(handles,'imageHandle') && ~isempty(handles.imageHandle) && ishandle(handles.imageHandle)
%     set(handles.imageHandle,'uicontextmenu',cmenu)
% end

return
%%
% Get mainhandles structure
if isempty(mainhandle) || ~ishandle(mainhandle)
    mainhandle = getappdata(0,'mainhandle');
end
mainhandles = guidata(mainhandle);

if isempty(mainhandles.data)
    set(mainhandles.mboard, 'String','No data loaded.')
    return
end

% File selection dialog
prompt = {'Select files' 'filechoices';...
    'Create new image(s)' 'makeNew'};
name = sprintf('Run library fcn: %s', func2str(fcn));

formats = prepareformats;
formats(2,1).type = 'list';
formats(2,1).items = {mainhandles.data(:).name}';
formats(2,1).limits = [0 2];
formats(2,1).size = [300 400];
formats(2,1).style = 'listbox';
formats(4,1).type = 'check';

DefAns.filechoices = get(mainhandles.FilesListbox,'Value');
DefAns.makeNew = mainhandles.settings.library.makeNew;

options.ButtonNames = {' Run ' ' Cancel '};

%--------------- Open dialog box --------------%
[answer, cancelled] = myinputsdlg(prompt, name, formats, DefAns, options);
if cancelled == 1
    return
end

% Save selected option
filechoices = answer.filechoices;
mainhandles.settings.library.makeNew = answer.makeNew;
updatemainhandles(mainhandles)

% Check number of images prior operation
nbefore = length(mainhandles.data);
imageOld = mainhandles.data(filechoices).imageData;
%% Call function
message = '';
try
    
    % Image data cell array
    imageData = cell(length(filechoices),1);
    for i = 1:length(filechoices)
        imageData{i} = mainhandles.data(filechoices(i)).imageData;
    end
    
    % First try as cell
    imageNew = fcn( imageData );
    
    % Make sure it is a cell array
    if ~iscell(imageNew)
        imageNew = {imageNew};
    end
    
    % Check that number of inputs matches number of outputs
    if mainhandles.settings.library.makeNew && length(imageNew)~=length(imageData)
        mainhandles.settings.library.makeNew = 1;
    end
        
    % Store new image
    for i = 1:length(imageNew)
        if length(imageNew)==length(filechoices)
            file = filechoices(i);
        else
            file = filechoices(1);
        end
        mainhandles = updateThisImage(mainhandles, imageNew{i});
    end
    
catch err
    
    % Then try as numeric arrays
    try
        % Loop all selected images
        n = 0;
        for i = 1:length(filechoices)
            file = filechoices(i);
            
            % Process image
            try
                imageNew = fcn(mainhandles.data(file).imageData);
            catch err
                message = sprintf('%s\n Error when processing %s:\n %s',message,mainhandles.data(file).name,err.message);
                continue
            end
            if ~iscell(imageNew)
                imageNew = {imageNew};
            end
            
            % Store processed images
            for j = 1:length(imageNew)
                
                %             try
                mainhandles = updateThisImage(mainhandles, imageNew{j});
                %             end
                
                % Count
                n = n+1;
            end
        end
        
        % check if any processing was made
        if n==0
            rethrow(err)
        end
        
    catch err
        % Show error in message board
        set(mainhandles.mboard,'String', sprintf('Error when running library function:\n %s',err.message) );
        return
    end
end

% Update Listbox
if mainhandles.settings.library.makeNew
    updateFilesListbox(mainhandles.figure1)
    nnew = length(mainhandles.data)-nbefore;
    set(mainhandles.FilesListbox,'Value',length(mainhandles.data)+1-nnew:length(mainhandles.data))
end

% Update image
mainhandles = updateImageAxes(mainhandles.figure1);

% Show message
if ~isempty(message)
    set(mainhandles.mboard,'String',message)
end

%%

% % Update
% message = '';
% n = 0;
% for i = 1:length(filechoices)
%     
%     % Run specified library function, fcn
%     file = filechoices(i);
%     try
%         % First try to send colormap too
%         imageNew = fcn( mainhandles.data(file).imageData, mainhandles.data(file).colormap );
%         
%     catch
%         % Then try without colormap
%         try
%             imageNew = fcn( mainhandles.data(file).imageData );
%             
%         catch err
%             % Message to show in messageboard
%             message = sprintf('%s\n Error when running file %s:\n %s',message,mainhandles.data(file).name,err.message);
%             continue
%         end
%     end
%     
%     % Store result
%     if mainhandles.settings.library.makeNew
%         
%         % Make new file item
%         filename = sprintf('%s: %s', name, mainhandles.data(file).name);
%         mainhandles = storeData(mainhandles,imageNew,[],filename,pwd,[],mainhandles.data(file).frameRate);
%         
%     else
%         % Overwrite existing image data
%         mainhandles.data(file).imageData = imageNew;
%         updatemainhandles(mainhandles)
%     end
%     
%     % Processed images
%     n = n+1;
% end
% 
% % Return if no images were processed
% if n==0
%     set(handles.mboard,'String',message)
%     return
% end
% 
% % Display message
% if ~isempty(message)
%     set(handles.mboard,'String',message)
% end
% 
% % Update Listbox
% if mainhandles.settings.library.makeNew
%     updateFilesListbox(mainhandles.figure1)
%     set(mainhandles.FilesListbox,'Value',length(mainhandles.data)+1-n)
% end
% 
% % Update image
% mainhandles = updateImageAxes(mainhandles.figure1);

    function mainhandles = updateThisImage(mainhandles, imageNew)
        % Store result
        if mainhandles.settings.library.makeNew
            
            % Make new file item
            filename = sprintf('%s: %s', name, mainhandles.data(file).name);
            mainhandles = storeData(mainhandles,imageNew,[],filename,pwd,[],mainhandles.data(file).frameRate);
            
        else
            % Overwrite existing image data
            mainhandles.data(file).imageData = imageNew;
            updatemainhandles(mainhandles)
        end
    end
end