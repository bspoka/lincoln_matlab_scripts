function varargout = DecayFit(varargin) %% Initializes the GUI
% DECAYFIT - Time-Resolved Fluorescence Decay Analysis Software
%
% Requirements:
%   MATLAB with the following toolboxes:
% 	. Statistics Toolbox
% 	. Optimization Toolbox (possibly also Global Optimization Toolbox)
% 	. Curvefitting Toolbox
% 	. Signal Processing Toolbox
%
%
% To run DecayFit, run DecayFit.m:
%
%   1) Open MATLAB
%   2) Make this folder your current directory
%   3) In the command window type: DecayFit
%   4) Press enter
%
%
% - Examples data can be found in the data folder.
% - To add your own fit model follow the steps described in one
%   of the existing models located in: library/decaymodels
% - For documentation, a compiled version, updates and related software go to:
%    www.fluortools.com
%
%
% - Tested in
% 	MATLAB R2012a (win7 64-bit).
%
% - Please report bugs and suggestions to me at: spreus@gmail.com
%
%
%----------------------
% --- Copyrights (C) ---
% ----------------------
%
% DecayFit - Time-Resolved Intensity Decay Analysis Software
% Copyright (C)  Søren Preus, Ph.D.
% http://www.fluortools.com
%
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
%
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
%
%     The GNU General Public License is found at
%     <http://www.gnu.org/licenses/gpl.html>.
%
% Last Modified by GUIDE v2.5 14-Apr-2014 22:55:28

% Set the path to the DecayFit workdir if it is stored from previous session
workdir = getappdata(0,'workdirDecayFit');
if ~isempty(workdir)
    try cd(workdir), end
end

%--- Add the subfolders of the program to the MATLAB search path ---%
addpath(pwd) % Adds the current directory (installation directory)
addpath(genpath(fullfile(pwd,'calls'))) % Adds the calls subdirectory and its subfolders
addpath(genpath(fullfile(pwd,'library'))) % Adds the library subdirectory and its subfolders

%---
% Display splash screen if 1) running MATLAB version 2010a or above, 2) if
% its not a deployed GUI version, and 3) splash hasn't been loaded already
%---
try
    % Open splash screen
    MATLABversion = version('-release');
    s = getappdata(0,'DecayFitSplashHandle');
    if (str2num(MATLABversion(1:4))>=2010) && isempty(s)
        s = SplashScreen('DecayFit','splash.png',...
            'ProgressBar', 'on', ...
            'ProgressPosition', 5, ...
            'ProgressRatio', 0.0 );
%         s.addText( 30, 50, 'DecayFit', 'FontSize', 30, 'Color', [0 0 0.6] )
%         s.addText( 30, 80, 'Time-Resolved Fluorescence Decay Software', 'FontSize', 14, 'Color', [0.2 0.2 0.5] )
%         s.addText( 300, 270, 'Loading...', 'FontSize', 18, 'Color', 'white' )
        s.addText( 300, 375, 'Loading...', 'FontSize', 18, 'Color', 'white' )
        
        setappdata(0,'DecayFitSplashHandle',s) % Point to splashScreen handle in order to delete it when GUI opens
    end
    
    % Set progressbar of splash screen
    progTot = 13; % Total number of times the main function is being called upon startup. Application dependent.
    
    % Running parameter counting how many times the main function has been called
    prog = getappdata(0,'DecayFitSplashCounter');
    if isempty(prog)
        prog = 1;
    else
        prog = prog+1;
    end
    
    % Ratio used for progressbar of splashScreen
    if prog/progTot>1
        progbar = 0;
        prog = 0;
    else
        progbar = prog/progTot;
    end
    
    % Update
    set(s,'ProgressRatio', progbar) % Update progress bar
    setappdata(0,'DecayFitSplashCounter',prog) % Update counter
end

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @DecayFit_OpeningFcn, ...
    'gui_OutputFcn',  @DecayFit_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end

function DecayFit_OpeningFcn(hObject, eventdata, handles, varargin) %% This function is run right before the GUI is made visible. Structures are initialized here
% Software specifications
handles.workdir = getcurrentdir; % Root directory
handles.name = 'DecayFit'; % Short name
handles.website = 'http://www.fluortools.com/software/decayfit'; % Homepage
handles.version = '1.4'; % This version. Must be string.
handles.splashScreenHandle = getappdata(0,'DecayFitSplashHandle'); % Handle to the splash screen running on startup

% Update above settings
updatemainhandles(handles)
setappdata(0, 'workdirDecayFit',handles.workdir) % It is necessary also to send workdir to appdata

% Version
MATLABversion = version('-release'); % This will be used below

% Create required folders on system path
ok = createFolders(handles);
if ~ok
    deleteSplashScreen(handles.splashScreenHandle) % Delete the splash screen
    try delete(hObject), end % Delete window object
    return
end

% Set position, title and logo. Turn off visibility.
initGUI(handles.figure1, 'DecayFit - Time-Resolved Emission Decay Analysis', 'center');

% Settings
settings = internalSettingsStructure(); % Initialize settings structure with internal values
handles.settings = loadDefaultSettings(handles, settings); % Load default settings from file

% Settings that should not be changed

% Initialize data structure
decays = storeData([]);
decays(1) = []; % Make 1x0 struct array

% Same for IRF
IRFs = decays;

% Update structures in userdata
updateData(handles,decays,IRFs)

% Initialize fits structure
models = cellstr(get(handles.FitModelsListbox,'String')); % Start choice
nomodels = size(models,1); % Number of models
maxdecays = handles.settings.startup.maxdecays; % Maximum no. of decays in loaded into program
maxIRFs = handles.settings.startup.maxdecays; % Maximum no. of IRFs loaded into program
fits(maxdecays,maxIRFs,nomodels).decay = []; % Fits has 3D indexing: (m,n,p) = (decay,IRF,decaymodel)
fits(maxdecays,maxIRFs,nomodels).res = []; % Residual
fits(maxdecays,maxIRFs,nomodels).ChiSq = []; % Chi-square value
fits(maxdecays,maxIRFs,nomodels).pars = []; % Optimized parameter values
fits(maxdecays,maxIRFs,nomodels).tail = []; % Tail fit start point
fits(maxdecays,maxIRFs,nomodels).scatter = []; % Scatter value
[fits.scatter] = deal(0); % Set all scatter values to 0

% Default parameters values
defaultglobalparselect = cell(1);
for i = 1:nomodels
    name = models(i); % Name of model
    fun = str2func(name{:}); % Model function
    fun(0); % Run function in order to return default values
    defaults = getappdata(0,'defaults'); % Get default values returned by the function
    [fits(:,:,i).pars] = deal(defaults); % All initial parameters values
    
    defaultglobalparselect{i,1} = 1:size(defaults,1); % Insert default parameter values
end
set(handles.fits,'UserData',fits); % Update

% Set shifts
set(handles.ShiftTable,'UserData',repmat({[0 10]},maxdecays,maxIRFs)) % Initialize for 20 decays and IRFs. If more is added, they will be added later
update_channelshift(handles) % Update shift textbox

% Set global structure
Global.names = [];
Global.pars = [];
Global.index = [];
Global.shifts = [];
Global.fits = [];
Global.res = [];
Global.decays = [];
Global.IRFs = [];
Global.t = [];
Global.weights = [];
Global.ChiSq = [];
Global.scatter = [];
Global(1) = [];
set(handles.GlobalList,'UserData',Global); % Update structure
set(handles.GlobalParListbox,'UserData',defaultglobalparselect) % Update default global parameter selection

% Set distributions
dists = cell(1); % Distributions
dists(1) = [];
set(handles.DistTextbox,'UserData',dists) % Update distributions

handles.filename = ''; % Session filename

% Default chi-square surface parameters
threshold = 1.1;
stepsize = 0.01;
minsteps = 10;
set(handles.Tools_ChiSqSurf,'UserData',[threshold; stepsize; minsteps])

% Default parameter plot window settings:
set(handles.Edit_ParPlotSettings,'UserData','aw') % Amplitude-weighted

% Window handles

% GUI object handles
handles.recentsessionsMenu = []; % Handle to the recent session files menu in the file menu of the main window
handles.recentmoviesMenu = []; % Handle to the recent movie files menu in the file menu of the main window

% Update recent files menus. Must be positioned after the recent
updateRecentFilesMenu(handles)

% Choose default command line output
handles.output = hObject;

% Update handles structure
updatemainhandles(handles)

% Set some GUI settings
setGUIappearance(handles.figure1)

% Check the MATLAB version. Must be positioned after settings
[handles, choseReturn] = checkforMATLAB(handles,'25-Jan-2010','2010a');
if choseReturn % If user does not whish to continue without proper version
    deleteSplashScreen(handles.splashScreenHandle) % Delete the splash screen
    try delete(hObject), end % Delete window object
    return
end

% Check toolboxes
handles = checkforToolboxes(handles,'curve_fitting_toolbox','optimization_toolbox','signal_toolbox','statistics_toolbox');

% Check allocated Java heap space
handles = checkJava(handles,250);

% Check screen resolution. Must be positioned after handles.output.
handles = checkScreenResolution(handles);

% Check for updates. Position this as the final before deleting splash
handles = checkforUpdates(handles, 'https://dl.dropboxusercontent.com/u/11755763/latest%20version%20of%20decayfit.html');

% Set some GUI properties
updateGUImenus(handles) % Updates menu checkmarks etc. Must be put after checkforUpdates.
updateToolbar(handles) % Updates the toolbar toggle states

% Turn off some things if its deployed
turnoffDeployed(handles);

% Initialize usage stats
handles.use = initStats();

% Initialize axes
linkaxes([handles.DecayWindow handles.ResWindow],'x')
xlabel(handles.DecayWindow,'Time /ns','FontUnits','normalized')
ylabel(handles.DecayWindow,'I(t)','FontUnits','normalized')
xlabel(handles.ResWindow,'','FontUnits','normalized')
ylabel(handles.ResWindow,'Res.','FontUnits','normalized')
xlabel(handles.DistWindow,'tau /ns','FontUnits','normalized')
ylabel(handles.DistWindow,'Fraction','FontUnits','normalized')

% Update plot
updateplot(handles)
plotlifetimes(handles)

% Choose default command line output for ae
handles.output = hObject;

% Figure handles
handles.figures = cell(1);
handles.figures(1) = [];

% Update handles structure
% [state,handles] = savestate(handles); % Save current GUI state
% handles.state1 = state; % GUI state 1
% handles.state2 = state; % GUI state 2
updatemainhandles(handles)

% Set color of GUI objects so that they match background
backgrColor = get(handles.figure1,'Color'); % Get the GUI background color
set(findobj(handles.figure1, '-property', 'BackgroundColor','-not','BackgroundColor','white','-not','-property','data'),...
    'BackgroundColor',backgrColor) % Set the background color to the same as the figure background color
set(handles.RunStatus,'BackgroundColor','blue') % Set the color of the status bar back to blue

% Delete splash screen
deleteSplashScreen(handles.splashScreenHandle)

function varargout = DecayFit_OutputFcn(hObject, ~, handles) %% This function returns handles.output (varargout) to the command line. Is not used by DecayFit.
% Get default command line output from handles structure
varargout{1} = [];
if ~isempty(handles)
    varargout{1} = handles.output;
end

function figure1_CloseRequestFcn(hObject, ~, handles) %% Runs when the GUI (i.e. handles.figure1) is closed
% Aims to delete all data and handles used by the program before closing:
% Aims to delete all data and handles used by the program before closing

% Number of times the program has been run
try count = runCounter(handles); end

% Send usage statistics
try 
    handles = sendStats(handles, count); 
end

% Suggest donation
try handles = suggestDonation(handles, count); end

% Save default settings
try saveDefaultSettings(handles,handles.settings); end

% Delete splash screen created by the main function which is run before closing:
try
    splashScreenHandle = getappdata(0,'aeSplashHandle');
    if (~isempty(splashScreenHandle)) && isvalid(splashScreenHandle)
        delete(splashScreenHandle)
    end
end

% Close figure windows
for i = 1:length(handles.figures)
    try delete(handles.figures{i}), end
end

% Delete all fields in the handles structure (data, settings, etc.)
try cla(handles.DecayWindow), end
try cla(handles.ResWindow), end
try handles = []; end
try handles.figure1 = hObject; end
try handles.output = []; end
try guidata(hObject,handles), end

% Delete the GUI
try delete(hObject); end

% Remove search paths:
workdir = getappdata(0,'workdirDecayFit');
if ~isempty(workdir)
    try rmpath(genpath(fullfile(workdir,'calls'))), end % Removes the calls subdirectory and its subfolders
    try rmpath(genpath(fullfile(workdir,'library'))), end % Removes the calls subdirectory and its subfolders
    try rmpath(workdir), end % Removes the installation directory
end

% Remove appdata stored by program
try rmappdata(0,'DecayFitSplashHandle'), end
try rmappdata(0,'DecayFitSplashCounter'), end
try rmappdata(0,'varname'), end
try rmappdata(0,'defaults'), end
try rmappdata(0,'model'), end
try rmappdata(0,'fits'), end
try rmappdata(0,'workdirDecayFit'), end

% --------------------------------------------------------------------
% ----------------- Callback-functions start hereafter ---------------
% - Tip: Fold all code for an overview (Ctrl+= on american keyboard) -
% --------------------------------------------------------------------

% --------------------------------------------------------------------
% ----------------------------- Menus --------------------------------
% --------------------------------------------------------------------

function FileMenu_Callback(hObject, ~, handles) %% The file menu

function File_SessionMenu_Callback(hObject, ~, handles) %% The session menu from the FileMenu

function File_Restart_Callback(hObject, ~, handles) %% New session from the file menu
workdir = getappdata(0,'workdirDecayFit');
cd(workdir)
guiPosition = get(gcbf,'Position'); %get the position of the GUI
close(gcbf); %close the old GUI
set(DecayFit,'Position',guiPosition); %set the position for the new GUI

function File_SaveProject_Callback(hObject, ~, handles) %% Save session from the file menu
handles = savesession(handles,0);

function File_SaveProjectAs_Callback(hObject, ~, handles) %% Save session as... from the file menu
handles = savesession(handles,1);

function File_LoadProject_Callback(hObject, ~, handles) %% Load session from the file menu
handles = opensession(handles);

function File_DataMenu_Callback(hObject, ~, handles) %% The Data menu from the File menu

function File_LoadDecay_Callback(hObject, ~, handles) %% Load decay from the file menu
loaddata(handles,'decay');

function File_LoadIRF_Callback(hObject, ~, handles) %% Load IRF from the file menu
loaddata(handles,'IRF')

function File_ImportWizard_Callback(hObject, ~, handles) %% Force opening an import-wizard
loaddata(handles,'wizard')

function File_Data_Settings_Callback(hObject, eventdata, handles)
% Prepare dialog box
prompt = {'Allow negative intensities' 'negatives'};
name = 'Import data settings';

% Handles formats
formats = struct('type', {}, 'style', {}, 'items', {}, ...
    'format', {}, 'limits', {}, 'size', {});
formats(2,1).type = 'check';

% Default answers:
DefAns.negatives = handles.settings.data.negatives;

% Open input dialogue and get answer
[answer, cancelled] = myinputsdlg(prompt, name, formats, DefAns); % Open dialog box
if cancelled == 1
    return
end

% Update handles structure
handles.settings.data.negatives = answer.negatives;
updatemainhandles(handles)

function File_ExportMenu_Callback(hObject, ~, handles) %% The Export menu from the File menu

function File_ExportFit_Callback(hObject, ~, handles) %% Export fits to ASCII from the file menu
modelchoice = get(handles.FitModelsListbox,'Value');

if strcmp(get(handles.GlobalFit,'State'),'off')
    IRFchoice = get(handles.IRFsListbox,'Value');
    decaychoices = get(handles.DecaysListbox,'Value');
    decays = get(handles.decays,'UserData');
    
    output = '';
    for i = 1:length(decaychoices)
        decaychoice = decaychoices(i);
        
        % Get fit
        fits = get(handles.fits,'UserData');
        fit = fits(decaychoice,IRFchoice,modelchoice).decay;
        res = fits(decaychoice,IRFchoice,modelchoice).res;
        ChiSq = fits(decaychoice,IRFchoice,modelchoice).ChiSq;
        scatter = fits(decaychoice,IRFchoice,modelchoice).scatter;
        
        if (isempty(fit)) || (isempty(res))
            set(handles.mboard,'String',sprintf(...
                'No fit found of decay %s\n',decays(decaychoice(i)).name))
            continue
        end
        
        try
            file = exportfit(handles,decaychoice,IRFchoice,modelchoice,fit,res,scatter,ChiSq,[]);
        catch err
            set(handles.mboard,'String',sprintf('Export failed of decay %s.',decays(decaychoice(i)).name))
        end
        
        output = sprintf('%sFit saved to: %s..\n',output,file);
        
    end
    set(handles.mboard,'String',sprintf(...
        '%s\nYou may want to view export in WordPad rather than Notepad.\n',output))
    
else
    Global = get(handles.GlobalList,'UserData');
    globalchoice = get(handles.GlobalDataListbox,'Value');
    if (isempty(globalchoice)) || (isempty(Global))
        set(handles.GlobalDataListbox,'Value',1)
        return
    end
    decaychoice = Global(globalchoice).index(1);
    IRFchoice = Global(globalchoice).index(2);
    
    % Get fit
    fit = Global(globalchoice).fits{modelchoice,1}; % If there is a fit of the selected decay
    res = Global(globalchoice).res{modelchoice,1};
    scatter = Global(globalchoice).scatter(modelchoice,1);
    
    if (isempty(fit)) || (isempty(res))
        set(handles.mboard,'String',sprintf(...
            'No fit found\n'))
        return
    end
    
    ChiSq = Global(globalchoice).ChiSq(modelchoice,1);
    ChiSqGlob = get(handles.GlobalDataListbox,'UserData');
    ChiSqGlob = ChiSqGlob(modelchoice,1);
    
    try
        file = exportfit(handles,decaychoice,IRFchoice,modelchoice,fit,res,scatter,ChiSq,ChiSqGlob);
    catch err
        set(handles.mboard,'String','Export failed.')
    end
    
    set(handles.mboard,'String',sprintf(...
        'Fit saved to: %s..\n\nYou may want to view export in WordPad rather than Notepad.\n',file))
end

function File_SaveFig_Callback(hObject, ~, handles) %% Save figure from the file menu
% Open a dialog for specifying export properties
settings = export_fig_dlg;
if isempty(settings)
    return
end

% Turn on waitbar
hWaitbar = waitbar(1,'Exporting figure. Please wait...','name','DecayFit');

% Copy to new window
hfig = copywindow(handles);
set(hfig,'visible','off','color','white')

% Export figure
try
    eval(settings.command) % This will run export_fig with settings specified in export_fig_dlg
    
catch err
    fprintf('Error message from export_fig: %s', err.message)
    
    % Delete figure
    try delete(hfig), end
        
    % Delete waitbar
    try delete(hWaitbar), end
    
    % Show error message
    if strcmp(err.message,'Ghostscript not found. Have you installed it from www.ghostscript.com?')
        if (strcmp(settings.format,'pdf')) || (strcmp(settings.format,'eps'))
            msgbox(sprintf('%s%s%s%s',...
                'Exporting figures to vector formats (pdf and eps) requires that ghostscript is installed on your computer. ',...
                'Install it from www.ghostscript.com. ',...
                'Exporting to eps additionally requires pdftops, from the Xpdf suite of functions. ',...
                'You can download this from:  http://www.foolabs.com/xpdf'),'Ghostscript missing')
        else
            msgbox('Ghostscript not found. Have you installed it from www.ghostscript.com?','Ghostscript missing')
        end
    elseif strcmp(err.message,'pdftops executable not found.')
        msgbox(sprintf('%s%s',...
            'Exporting to eps requires pdftops, from the Xpdf suite of functions. ',...
            'You can download this from:  http://www.foolabs.com/xpdf. You could also export to the other vector format, pdf.'),'pdftops missing')
    end
    
end

% Delete figure
try delete(hfig), end

% Imititate click in listbox
DecaysListbox_Callback(handles.DecaysListbox,[],handles)

% Delete waitbar
try delete(hWaitbar), end

function File_ResetSettings_Callback(hObject, eventdata, handles)
handles.settings = internalSettingsStructure();
updatemainhandles(handles)
saveDefaultSettings(handles, handles.settings)
updateGUImenus(handles)

function File_RecentFilesMenu_Callback(hObject, eventdata, handles)

function File_RecentSessionsMenu_Callback(hObject, eventdata, handles)

function EditMenu_Callback(hObject, ~, handles) %% The Edit menu

function Edit_EditPlot_Callback(hObject, ~, handles) %% Edit plot from the edit menu
if strcmp(get(handles.PlotEdit,'State'),'on')
    set(handles.PlotEdit,'State','off')
elseif  strcmp(get(handles.PlotEdit,'State'),'off')
    set(handles.PlotEdit,'State','on')
end

function Edit_RenameData_Callback(hObject, ~, handles) %% Rename data from the edit menu
renamedataCallback(handles)

function Edit_NewWindow_Callback(hObject, ~, handles) %% Plot in new window from the edit menu
handles = newwindowCallback(handles);

function Edit_ParPlotSettings_Callback(hObject, ~, handles) %% The parameter plot settings dialog from the edit menu
% Prepare dialog box
prompt = {'2-4 exponentials lifetime plot: ' 'plot'};
name = 'Lifetime plot ';

% Handles formats
formats = struct('type', {}, 'style', {}, 'items', {}, ...
    'format', {}, 'limits', {}, 'size', {});
formats(2,1).type = 'list';
formats(2,1).style = 'radiobutton';
formats(2,1).items = {'Amplitude-weighted components  '; 'Intensity-weighted components  '};

% Default answers:
plottype = get(handles.Edit_ParPlotSettings,'UserData');
if strcmp(plottype,'aw')
    defaults = 1;
elseif strcmp(plottype,'iw')
    defaults = 2;
end
DefAns.plot = defaults;

% Open input dialogue and get answer
[answer, cancelled] = myinputsdlg(prompt, name, formats, DefAns); % Open dialog box
if cancelled == 1
    return
end

% Result
if answer.plot == 1
    plottype = 'aw'; % Amplitude-weighted plot
elseif answer.plot == 2
    plottype = 'iw'; % Intensity-weighted plot
end

set(handles.Edit_ParPlotSettings,'UserData',plottype)
plotlifetimes(handles)

function Edit_ExportFigClipboard_Callback(hObject, eventdata, handles)
copyfigtoclipboard([],[],handles.figure1,handles.DecayWindow);

% Update stats
handles = updateuse(handles,'Edit_ExportFigClipboard');

function Edit_ExportDataClipboard_Callback(hObject, eventdata, handles)
copydatatoclipboard([],[],handles);

function View_PlotMenu_Callback(hObject, ~, handles) %% The plot menu

function View_ZoomIn_Callback(hObject, ~, handles) %% The zoom in menu button
z = zoom(gcf);
if strcmp(get(handles.ZoomIn,'State'),'off')
    set(z,'Direction','in','Enable','on')
else
    set(z,'Direction','in','Enable','off')
end

function View_ZoomOut_Callback(hObject, ~, handles) %% The zoom out menu button
z = zoom(gcf);
if strcmp(get(handles.ZoomOut,'State'),'off')
    set(z,'Direction','out','Enable','on')
else
    set(z,'Direction','out','Enable','off')
end

function View_DataCursor_Callback(hObject, ~, handles) %% The data cursor menu button
if strcmp(get(handles.DataCursor,'State'),'off')
    datacursormode on
else datacursormode off
end

function View_Legend_Callback(hObject, ~, handles) %% The legend menu button
if strcmp(get(handles.Legend,'State'),'off')
    set(handles.Legend,'State','on')
elseif strcmp(get(handles.Legend,'State'),'on')
    set(handles.Legend,'State','off')
end

function ViewMenu_Callback(hObject, eventdata, handles)

function View_AxisLimits_Callback(hObject, eventdata, handles)
% Prepare dialog box
prompt = {'x min:' 'xmin';...
    'x max:' 'xmax';...
    'y min:' 'ymin';...
    'y max:' 'ymax';...
    'Lock at this y-scale' 'locklims'};
name = 'Set axis scale';

% Handles formats
formats = struct('type', {}, 'style', {}, 'items', {}, ...
    'format', {}, 'limits', {}, 'size', {});
formats(2,1).type   = 'edit';
formats(2,1).format = 'float';
formats(2,1).size = 80;
formats(2,2).type   = 'edit';
formats(2,2).format = 'float';
formats(2,2).size = 80;
formats(3,1).type   = 'edit';
formats(3,1).format = 'float';
formats(3,1).size = 80;
formats(3,2).type   = 'edit';
formats(3,2).format = 'float';
formats(3,2).size = 80;
formats(5,1).type = 'check';

% Default answers:
xlims = get(handles.DecayWindow,'xlim');
ylims = get(handles.DecayWindow,'ylim');

DefAns.xmin = xlims(1);
DefAns.xmax = xlims(2);
DefAns.ymin = ylims(1);
DefAns.ymax = ylims(2);
DefAns.locklims = handles.settings.view.locklims;

% Open input dialogue and get answer
[answer, cancelled] = myinputsdlg(prompt, name, formats, DefAns); % Open dialog box
if cancelled == 1
    return
end
xlimsNew = sort([answer.xmin answer.xmax]);
ylimsNew = sort([answer.ymin answer.ymax]);

% Set axis limits
xlim(handles.DecayWindow,xlimsNew)
ylim(handles.DecayWindow,ylimsNew)
xlim(handles.ResWindow,xlimsNew)

% Lock axes settings
handles.settings.view.locklims = answer.locklims;
handles.settings.view.ylimits = ylimsNew;
handles.settings.view.xlimits = xlimsNew;
guidata(handles.figure1,handles) % Update handles structure

function View_Logscale_Callback(hObject, eventdata, handles)
% New setting
handles.settings.view.logscale = abs(handles.settings.view.logscale-1);    

% Update
updatemainhandles(handles)
updateGUImenus(handles)
updateplot(handles)

function Settings_Menu_Callback(hObject, eventdata, handles)

function Settings_ExportFigClipboard_Callback(hObject, eventdata, handles)
handles = exportfigclipboardSettings(handles);

function Tools_SetChannelTime_Callback(hObject, ~, handles) %% Set channel time from the tools menu
decays = get(handles.decays,'UserData'); % Loaded decays
IRFs = get(handles.IRFs,'UserData'); % Loaded IRFs

% Open a data selection dialog
[decaychoices,IRFchoices,ndecays,nIRFs] = onelistboxselection(handles,'Set channel time','Select data: ','multi');
if isempty(decaychoices) && isempty(IRFchoices)
    return
end

% Input dialog box
nschannel = str2double(...
    myinputdlg(sprintf('Enter ns/channel: '),'DecayFit',1,{num2str(handles.settings.data.nschannel)}) ); % Open dialog for setting time vector
if isempty(nschannel) || ~isnumeric(nschannel) % Check input
    return
end

% Do decays
for i = 1:length(decaychoices)
    vectorlength = size(decays(decaychoices(i)).data,1); % Length of decay i
    t = linspace(0,nschannel*(vectorlength-1),vectorlength)'; % New time
    decays(decaychoices(i)).data(:,1) = t; % Update data structure
end
% Do IRFs
for i = 1:length(IRFchoices)
    vectorlength = size(IRFs(IRFchoices(i)).data,1); % Length of decay i
    t = linspace(0,nschannel*(vectorlength-1),vectorlength)'; % New time
    IRFs(IRFchoices(i)).data(:,1) = t; % Update data structure
end

% Set new decay & IRF
set(handles.IRFs,'UserData',IRFs)
set(handles.decays,'UserData',decays)

% Update default nschannel value
handles.settings.data.nschannel = nschannel;
guidata(handles.figure1,handles) % Update handles structure
saveDefaultSettings(handles); % Save current settings structure to a file

updateplot(handles) % Update plot

function ToolsMenu_Callback(hObject, ~, handles) %% The Tools menu

function Tools_Fit_Callback(hObject, ~, handles) %% The fit shortcut in the tools menu
FitPushbutton_Callback(handles.FitPushbutton, [], handles)

function Tools_GaussianIRF_Callback(hObject, ~, handles) %% Make Gaussian IRF from the tools menu
gaussianIRFcallback(handles);

function Tools_SetTimeInterval_Callback(hObject, ~, handles) %% Set time interval item from the tools menu
[x,y] = ginput(2);
decays = get(handles.decays,'UserData');
if strcmp(get(handles.GlobalFit,'State'),'off')
    decaychoice = get(handles.DecaysListbox,'Value');
elseif strcmp(get(handles.GlobalFit,'State'),'on')
    Global = get(handles.GlobalList,'UserData');
    globalchoice = get(handles.GlobalDataListbox,'Value');
    if (isempty(Global)) || (isempty(globalchoice))
        return
    end
    decaychoice = Global(globalchoice).index(1);
end
if ~isempty(decays)
    for i = 1:length(decaychoice)
        decays(decaychoice(i)).ti = x;
    end
end
set(handles.decays,'UserData',decays)
% Update plot
PlotPushbutton_Callback(handles.FitPushbutton, [], handles)

function Tools_ReverseDecay_Callback(hObject, ~, handles) %% Reverse decays from the tools menu
decays = get(handles.decays,'UserData');
decaychoice = get(handles.DecaysListbox,'Value');
for i = 1:length(decaychoice)
    temp = decays(decaychoice(i)).data;
    temp(:,2) = fliplr(temp(:,2)')';
    decays(decaychoice(i)).data = temp;
end

set(handles.decays,'UserData',decays)
updateplot(handles)

function Tools_ReverseIRF_Callback(hObject, ~, handles) %% Reverse IRFs from the tools menu
IRFs = get(handles.IRFs,'UserData');
IRFchoice = get(handles.IRFsListbox,'Value');
temp = IRFs(IRFchoice).data;
temp(:,2) = fliplr(temp(:,2)')';
IRFs(IRFchoice).data = temp;

set(handles.IRFs,'UserData',IRFs)
updateplot(handles)

function Tools_Backgroundmenu_Callback(hObject, ~, handles) %% The background submenu from the tools menu

function Tools_DecayBackground_Callback(hObject, ~, handles) %% The decay background from the tools menu
[x,y] = ginput(1);
decays = get(handles.decays,'UserData');
decaychoice = get(handles.DecaysListbox,'Value');
if ~isempty(decays)
    for i = 1:length(decaychoice)
        decays(decaychoice(i)).zero = round(y);
    end
end
set(handles.decays,'UserData',decays)

updateplot(handles)

function Tools_IRFbackground_Callback(hObject, ~, handles) %% The IRF background from the tools menu
[x,y] = ginput(1);
IRFs = get(handles.IRFs,'UserData');
IRFchoice = get(handles.IRFsListbox,'Value');
if ~isempty(IRFs)
    IRFs(IRFchoice).zero = round(y);
end
set(handles.IRFs,'UserData',IRFs)

updateplot(handles)

function Tools_ResetBackgrounds_Callback(hObject, ~, handles) %% Reset backgrounds from the tools menu
decays = get(handles.decays,'UserData');
decaychoice = get(handles.DecaysListbox,'Value');
if ~isempty(decays)
    for i = 1:length(decaychoice)
        decays(decaychoice(i)).zero = 0;
    end
end
set(handles.decays,'UserData',decays)

updateplot(handles)

function Tools_Tailfitmenu_Callback(hObject, ~, handles) %% The tailfitting submenu from the tools menu

function Tools_Tailfit_Callback(hObject, ~, handles) %% Tailfit from the tools-tailfit menu
[x,y] = ginput(1);

fits = get(handles.fits,'UserData');
if strcmp(get(handles.GlobalFit,'State'),'off')
    decaychoice = get(handles.DecaysListbox,'Value');
    IRFchoice = get(handles.IRFsListbox,'Value');
elseif strcmp(get(handles.GlobalFit,'State'),'on')
    Global = get(handles.GlobalList,'UserData');
    globalchoice = get(handles.GlobalDataListbox,'Value');
    decaychoice = Global(globalchoice).index(1);
    IRFchoice = Global(globalchoice).index(2);
end
for i = 1:length(decaychoice)
    [fits(decaychoice(i),IRFchoice,:).tail] = deal(x);
end
set(handles.fits,'UserData',fits)

updateplot(handles)

function Tools_ResetTailfit_Callback(hObject, ~, handles) %% Reset tailfit from the tools-tailfit menu
fits = get(handles.fits,'UserData');
decaychoice = get(handles.DecaysListbox,'Value');
IRFchoice = get(handles.IRFsListbox,'Value');

for i = 1:length(decaychoice)
    fits(decaychoice(i),IRFchoice,:).tail = [];
end
set(handles.fits,'UserData',fits)
updateplot(handles)

function Tools_OnlyTailfit_Callback(hObject, ~, handles) %% Only show tailfit region from the tools-tailfit menu
if strcmp(get(handles.Tools_OnlyTailfit,'Label'),'Only show tailfit region')
    set(handles.Tools_OnlyTailfit,'Label','Show full fit')
elseif strcmp(get(handles.Tools_OnlyTailfit,'Label'),'Show full fit')
    set(handles.Tools_OnlyTailfit,'Label','Only show tailfit region')
end
updateplot(handles)

function Tools_AutoCorrelation_Callback(hObject, ~, handles) %% Plot autocorrelation of residual
decays = get(handles.decays,'UserData');
fits = get(handles.fits,'UserData');
modelchoice = get(handles.FitModelsListbox,'Value');
if strcmp(get(handles.GlobalFit,'State'),'off')
    decaychoice = get(handles.DecaysListbox,'Value');
    IRFchoice = get(handles.IRFsListbox,'Value');
    
    f = figure; plots = 0;
    updatelogo(f)
    for i = 1:length(decaychoice)
        res = fits(decaychoice(i),IRFchoice,modelchoice).res;
        if isempty(res)
            set(handles.mboard,'String',sprintf('No fit of %s',decays(decaychoice(i)).name))
            continue
        end
        
        % Calculate autocorrelation function
        [ACF,~,~] = autocorr(res(:,2),round(size(res,1)-1) ,[],[]);
        
        % Plot in new window
        set(f,'name','Autocorrelation Plot')
        ax = subplot(length(decaychoice),1,i);
        plot(ax,res(1:length(ACF)),ACF,'r'), hold(ax,'on')
        xlimits = get(handles.DecayWindow,'xlim');
        plot(ax, xlimits,[0 0],'k')
        xlabel(ax,'Correlation time /ns','FontSize',12,'fontname','Arial')
        ylabel(ax,'Autocorr.','FontSize',12,'fontname','Arial')
        set(gca,'FontSize',11,'fontname','Arial')
        % Legend:
        n = decays(decaychoice(i)).name;
        % Replace all '_' with '\_' to avoid legend subscripts
        run = 0;
        for k = 1:length(n)
            run = run+1;
            if n(run)=='_'
                n = sprintf('%s\\%s',n(1:run-1),n(run:end));
                run = run+1;
            end
        end
        legend(ax,n)
        
        plots = plots+1;
    end
    
    if plots == 0
        close(f)
    else
        % Save figure handle
        handles.figures{end+1} = f;
        guidata(handles.figure1,handles);
        updateFIGhandles(handles)
    end
    
elseif strcmp(get(handles.GlobalFit,'State'),'on')
    Global = get(handles.GlobalList,'UserData');
    globalchoice = get(handles.GlobalDataListbox,'Value');
    res = Global(globalchoice).res;
    if isempty(res)
        set(handles.mboard,'String','No fit of selected dataset')
        return
    end
    
    % Calculate autocorrelation function
    [ACF,~,~] = autocorr(res(:,2),round(size(res,1)-1) ,[],[]);
    
    % Plot in new window
    f = figure;
    updatelogo(f)
    set(f,'name',sprintf('Autocorrelation Plot: %s',decays(decaychoice(1)).name))
    plot(res(1:length(ACF)),ACF,'r'), hold(gca,'on')
    xlimits = get(handles.DecayWindow,'xlim');
    plot(xlimits,[0 0],'k')
    xlabel(gca,'Correlation time /ns','FontSize',12,'fontname','Arial')
    ylabel(gca,'Autocorr.','FontSize',12,'fontname','Arial')
    set(gca,'FontSize',11,'fontname','Arial')
    
    % Save figure handle
    handles.figures{end+1} = f;
    guidata(handles.figure1,handles);
    updateFIGhandles(handles)
end

function Tools_PlotRes_Callback(hObject, ~, handles) %% Plot multiple residuals from the tools menu
decays = get(handles.decays,'UserData');
decaychoice = get(handles.DecaysListbox,'Value');
IRFchoice = get(handles.IRFsListbox,'Value');
modelchoice = get(handles.FitModelsListbox,'Value');
fits = get(handles.fits,'UserData');

if length(decaychoice) < 2
    set(handles.mboard,'String',...
        'The residual is plotted above the decay window. The option you pressed is when plotting multiple decays simultaneously. Plot multiple decays simultaneously by holding down the Shift or Alt keys while selecting decays.')
    return
end

f = figure;
updatelogo(f)
for i = 1:length(decaychoice)
    res = fits(decaychoice(i),IRFchoice,modelchoice).res;
    xlimits = get(handles.DecayWindow,'xlim');
    if ~isempty(res)
        if strcmp(get(handles.Tools_OnlyTailfit,'Label'),'Only show tailfit region')
            ax = subplot(length(decaychoice),1,i);
            plot(ax,res(:,1),res(:,2),'r'), hold(ax,'on')
        elseif strcmp(get(handles.Tools_OnlyTailfit,'Label'),'Show full fit')
            % Set tail start
            fit = fits(decaychoice(i),IRFchoice,modelchoice).decay;
            tail = fits(decaychoice(i),IRFchoice,1).tail;
            if isempty(tail)
                tail = 1;
            else
                [~,tail] = min(abs(fit(:,1)-tail));
            end
            ax = subplot(length(decaychoice),1,i);
            plot(ax,res(tail:end,1),res(tail:end,2),'r'), hold(ax,'on')
        end
        plot(ax,xlimits,[0 0],'k')
        
        % Replace all '_' with '\_' to avoid legend subscripts
        name = decays(decaychoice(i)).name;
        n = name; run = 0;
        for k = 1:length(n)
            run = run+1;
            if n(run)=='_'
                n = sprintf('%s\\%s',n(1:run-1),n(run:end));
                run = run+1;
            end
        end
        name = n;
        legend(ax,sprintf('%s',name))
        ylabel(ax,'Res.','fontname','Arial')%,'fontsize',12
        xlabel(ax,'Time /ns','fontname','Arial') %,'fontsize',12
        set(ax,'fontname','Arial')%,'FontSize',11
    end
end

% Rename window
set(f,'name','Residuals of multi-decay plot','numbertitle','off')

% Save figure handle
handles.figures{end+1} = f;
guidata(handles.figure1,handles);
updateFIGhandles(handles)

function Tools_Stop_Callback(hObject, ~, handles) %% Stop running from the tools menu
set(handles.Stop,'State','on')

function Tools_ImportDistanceDistribution_Callback(hObject, ~, handles) %% Import distance distribution from the tools menu
[filename, dir, chose] = uigetfile2_dist({'*.txt;*.dat;*.csv'},'Import distance distribution');
if chose == 0
    return
end
input_filename = fullfile(dir,filename);

% Import data
dist = uiimport(input_filename);
if isempty(dist)
    return
end
dist = dist.data;

% Set new data
dists = get(handles.DistTextbox,'UserData');
DistList = get(handles.DAdistListbox,'String');
if isempty(DistList)
    dists{1} = dist;
    DistList{1,1} = filename(1:end-4);
else dists{end+1} = dist;
    DistList{end+1,1} = filename(1:end-4);
end
set(handles.DAdistListbox,'String',DistList)
set(handles.DAdistListbox,'Value',size(DistList,1))
set(handles.DistTextbox,'UserData',dists)

plotdist(handles)

function Tools_ChiSqSurfMenu_Callback(hObject, ~, handles) % The chi-square surface sub menu from the tools menu

function Tools_ChiSqSurfSetup_Callback(hObject, ~, handles) %% Chi-square surface setup menu
% Prepare dialog box
prompt = {'Chi-square (rel.) threshold value:' 'threshold';...
    'Stepsize (units of parameter):' 'stepsize';...
    'Minimum number of steps in either direction:' 'minsteps'};
name = 'Chi-Square surface calculation setup';

% Handles formats
formats = struct('type', {}, 'style', {}, 'items', {}, ...
    'format', {}, 'limits', {}, 'size', {});
formats(2,1).type   = 'edit';
formats(2,1).format = 'float';
formats(2,1).size = 80;
formats(4,1).type   = 'edit';
formats(4,1).format = 'float';
formats(4,1).size = 80;
formats(6,1).type   = 'edit';
formats(6,1).format = 'float';
formats(6,1).size = 80;

% Default answers:
defaults = get(handles.Tools_ChiSqSurf,'UserData');
DefAns.threshold = defaults(1);
DefAns.stepsize = defaults(2);
DefAns.minsteps = defaults(3);

% Open input dialogue and get answer
[answer, cancelled] = myinputsdlg(prompt, name, formats, DefAns); % Open dialog box
if cancelled == 1
    return
end
threshold = answer.threshold;
stepsize = answer.stepsize;
minsteps = answer.minsteps;

set(handles.Tools_ChiSqSurf,'UserData',[threshold; stepsize; minsteps])

function Tools_GlobalFit_Callback(hObject, ~, handles) %% Global fit from the tools menu
if strcmp(get(handles.Tools_GlobalFit,'Label'),'Single fit')
    set(handles.GlobalFit,'State','off')
elseif strcmp(get(handles.Tools_GlobalFit,'Label'),'Global fit')
    set(handles.GlobalFit,'State','on')
end

function Tools_SumData_Callback(hObject, ~, handles) %% Sum two or more data sets
sumdataCallback(handles);

function Tools_SubtractData_Callback(hObject, eventdata, handles)
subtractdataCallback(handles)

function HelpMenu_Callback(hObject, ~, handles) %% The Help menu

function Help_About_Callback(hObject, ~, handles) %% The about item from the Help menu
aboutProgram(handles)

function Help_OnlineDocumentation_Callback(hObject, ~, handles) %% Opens the online documentation in a browser window
myopenURL('www.fluortools.com/software/decayfit/documentation');

function Help_CheckUpdates_Callback(hObject, eventdata, handles)
checkforUpdatesNow(handles, 'https://dl.dropboxusercontent.com/u/11755763/latest%20version%20of%20decayfit.html'); % Returns the latest version html as a string. 'Timeout',5 is only implemented from R2013

function Help_CheckForUpdatesStartup_Callback(hObject, eventdata, handles)
handles = checkforUpdatesOnStartup(handles);

function Help_SendUsageStats_Callback(hObject, eventdata, handles)
handles = sendUsageStatsOnClosing(handles);

function Help_FeatureRequest_Callback(hObject, eventdata, handles)
myopenURL('https://docs.google.com/forms/viewform?hl=en_GB&id=1chrG5F3C16iD6B2x4wfPGspxXfaD64vt6YhxNJQEAW4');

function Help_BugReport_Callback(hObject, eventdata, handles)
myopenURL('https://docs.google.com/forms/d/1aSa-fEUOngtDDjCK0Dra5jnMZBufWRhbHc48dxiY-Lk/viewform');

function Help_Developers_SendHandles_Callback(hObject, eventdata, handles)
handlesWorkspace(handles)

% Update usage stat
handles = updateuse(handles, 'Help_Developers_SendHandles');

function Help_DevelopersMenu_Callback(hObject, eventdata, handles)

function Help_Developers_figfile_Callback(hObject, eventdata, handles)
guide DecayFit

function Help_Developers_mfile_Callback(hObject, eventdata, handles)
edit DecayFit

% --------------------------------------------------------------------
% ------------------------- Toolbar buttons --------------------------
% --------------------------------------------------------------------

function NewProject_ClickedCallback(hObject, ~, handles) %% The new session from the toolbar
File_Restart_Callback(handles.File_Restart, [], handles)

function OpenProject_ClickedCallback(hObject, ~, handles) %% The open existing project button in the toolbar
File_LoadProject_Callback(handles.File_LoadProject, [], handles)

function SaveProject_ClickedCallback(hObject, ~, handles) %% The save current project in the toolbar
File_SaveProject_Callback(handles.File_SaveProject, [], handles)

function GaussianIRF_ClickedCallback(hObject, ~, handles) %% The make Gaussian IRF button from the toolbar
Tools_GaussianIRF_Callback(handles.Tools_GaussianIRF, [], handles)

function Legend_OnCallback(hObject, ~, handles) %% The legend on button from the toolbar
% Old axis limits
Dxlim = get(handles.DecayWindow,'xlim');
Dylim = get(handles.DecayWindow,'ylim');
Rxlim = get(handles.ResWindow,'xlim');
Rylim = get(handles.ResWindow,'ylim');

updateplot(handles)

% Set to old limits:
set(handles.DecayWindow,'xlim',Dxlim);
set(handles.DecayWindow,'ylim',Dylim);
set(handles.ResWindow,'xlim',Rxlim);
set(handles.ResWindow,'ylim',Rylim);

function Legend_OffCallback(hObject, ~, handles) %% The legend off button in the toolbar
% Old axis limits
Dxlim = get(handles.DecayWindow,'xlim');
Dylim = get(handles.DecayWindow,'ylim');
Rxlim = get(handles.ResWindow,'xlim');
Rylim = get(handles.ResWindow,'ylim');

updateplot(handles)

% Set to old limits:
set(handles.DecayWindow,'xlim',Dxlim);
set(handles.DecayWindow,'ylim',Dylim);
set(handles.ResWindow,'xlim',Rxlim);
set(handles.ResWindow,'ylim',Rylim);

function PlotEdit_OnCallback(hObject, ~, handles) %% Turn on plot edit mode
plotedit('on')

function PlotEdit_OffCallback(hObject, ~, handles) %% Turn off plot edit mode
plotedit('off')

function NewWindow_ClickedCallback(hObject, ~, handles) %% The plot graph in new window button in the toolbar
Edit_NewWindow_Callback(handles.Edit_NewWindow, [], handles)

function SetTime_ClickedCallback(hObject, ~, handles) %% The set time interval toolbar button
Tools_SetTimeInterval_Callback(handles.Tools_SetTimeInterval, [], handles)

function ReverseDecay_ClickedCallback(hObject, ~, handles) %% The reverse decay button from the toolbar
Tools_ReverseDecay_Callback(handles.Tools_ReverseDecay, [], handles)

function ReverseIRF_ClickedCallback(hObject, ~, handles) %% The reverse IRF toolbar button
Tools_ReverseIRF_Callback(handles.Tools_ReverseIRF, [], handles)

function DecayBackground_ClickedCallback(hObject, ~, handles) %% The set decay background toolbar button
Tools_DecayBackground_Callback(handles.Tools_DecayBackground, [], handles)

function IRFbackground_ClickedCallback(hObject, ~, handles) %% The IRF background toolbar button
Tools_IRFbackground_Callback(handles.Tools_IRFbackground, [], handles)

function Tailfit_ClickedCallback(hObject, ~, handles) %% The tailfit time toolbar button
Tools_Tailfit_Callback(handles.Tools_Tailfit, [], handles)

function AutoCorr_ClickedCallback(hObject, ~, handles) %% The plot autocorrelation toolbar button
Tools_AutoCorrelation_Callback(handles.Tools_AutoCorrelation,[],handles)

function RunChiSqSurf_ClickedCallback(hObject, ~, handles) %% Run chi-square surface button in the toolbar
Tools_ChiSqSurf_Callback(handles.Tools_ChiSqSurf, [], handles)

function Fit_ClickedCallback(hObject, ~, handles) %% Fit decay toolbar button
FitPushbutton_Callback(handles.FitPushbutton, [], handles)

function GlobalFit_OnCallback(hObject, ~, handles) %% Activate global fitting toolbar button
set(handles.Tools_GlobalFit,'Label','Single fit')
set(handles.FitShiftCheckbox,'Value',0,'Enable','off')
set(handles.ShiftTable2,'Visible','off')
set(handles.GlobalListSelectionTextbox,'Visible','on')

updateGlobal(handles)
updateParTable(handles)
updateplot(handles)

function GlobalFit_OffCallback(hObject, ~, handles) %% Turn off global fitting
set(handles.Tools_GlobalFit,'Label','Global fit')
set(handles.FitShiftCheckbox,'Enable','on')
set([handles.GlobalDataListbox handles.GlobalParListbox handles.GlobalList handles.PickGlobalParText handles.GlobalListSelectionTextbox],'Visible','off')

fitmodelsListboxCallback(handles);
DecaysListbox_Callback(handles.DecaysListbox, [], handles)

function Stop_OnCallback(hObject, ~, handles) %% Stop calculation toolbar button
% Turn interface on
InterfaceObj = findobj(handles.figure1,'Enable','off');
set(InterfaceObj,'Enable','on');

% Set status bar to waiting
set(handles.RunStatus,'BackgroundColor','blue')
set(handles.RunStatusTextbox,'String','Waiting')

% --------------------------------------------------------------------
% ----------------------------- Fitting ------------------------------
% --------------------------------------------------------------------

function PlotPushbutton_Callback(hObject, ~, handles) %% The plot pushbutton callback
plotCallback(handles)

function FitPushbutton_Callback(hObject, ~, handles) %% The fit pushbutton callback
fitCallback(handles)

function Tools_ChiSqSurf_Callback(hObject, ~, handles) %% Run chi-square surface
chisqsurfCallback(handles)

%---------------------------------------------------------------------
%----------------------------- GUI objects ---------------------------
%---------------------------------------------------------------------

function DecaysListbox_Callback(hObject, ~, handles) %% Runs when changing the decay listbox selection
% If global fit, do nothing
if strcmp(get(handles.GlobalFit,'State'),'on')
    return
end

% Else, if single fit
decaychoice = get(handles.DecaysListbox,'Value'); % Selected decays
IRFchoice = get(handles.IRFsListbox,'Value'); % Selected IRF
if isempty(IRFchoice) % If there are no IRFs loaded
    set(handles.IRFsListbox,'Value',1)
elseif  isempty(decaychoice) % If there are no decays loaded
    set(handles.DecaysListbox,'Value',1)
end

% Update GUI
updateShiftTable(handles) % Update shift table
update_channelshift(handles) % Update channel shift textbox
updateParTable(handles) % Update parameter table
plotlifetimes(handles) % Update lifetime-plot axes
updateplot(handles) % Update decay plot
function DecaysListbox_CreateFcn(hObject, ~, handles) %% Runs when the decay listbox is created
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function IRFsListbox_Callback(hObject, ~, handles) %% Called when changing the IRF listbox selection
% If global fit, do nothing
if strcmp(get(handles.GlobalFit,'State'),'on')
    return
end

% Else
decaychoice = get(handles.DecaysListbox,'Value');
IRFchoice = get(handles.IRFsListbox,'Value');
if isempty(IRFchoice)
    set(handles.IRFsListbox,'Value',1)
elseif  isempty(decaychoice)
    set(handles.DecaysListbox,'Value',1)
end
updateShiftTable(handles)
update_channelshift(handles)
updateParTable(handles)
plotlifetimes(handles)
updateplot(handles)
function IRFsListbox_CreateFcn(hObject, ~, handles) %% Runs when the IRF listbox is created
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function FitModelsListbox_Callback(hObject, ~, handles) %% Runs when changing the fit model selection
fitmodelsListboxCallback(handles);
function FitModelsListbox_CreateFcn(hObject, ~, handles) %% Runs when the fit models listbox is created
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% Get functions located in library folder
f = what(sprintf('%s//library//decaymodels',getappdata(0,'workdirDecayFit')));
funs = cell(1);
for i = 1:length(f.m)
    funs{i} = f.m{i}(1:end-2);
end

% Arrange so that single_exp is first
temp = cell(1);
temp(1) = funs(strcmp(funs,'single_exp'));
temp(2) = funs(strcmp(funs,'double_exp'));
temp(3) = funs(strcmp(funs,'triple_exp'));
temp(4) = funs(strcmp(funs,'four_exp'));
temp(5) = funs(strcmp(funs,'FRET'));
temp(6) = funs(strcmp(funs,'lifetime_dist'));
funs(strcmp(funs,'single_exp')) = [];
funs(strcmp(funs,'double_exp')) = [];
funs(strcmp(funs,'triple_exp')) = [];
funs(strcmp(funs,'four_exp')) = [];
funs(strcmp(funs,'FRET')) = [];
funs(strcmp(funs,'lifetime_dist')) = [];
temp = [temp funs];

% Update listbox string
set(hObject,'String',temp)

function SwitchDecayPushbutton_Callback(hObject, ~, handles) %% Switch decay to IRF pushbutton callback
% Get current data
decays = get(handles.decays,'UserData');
decaychoice = get(handles.DecaysListbox,'Value');
IRFs = get(handles.IRFs,'UserData');
if (isempty(decaychoice)) || (isempty(decays))
    return
end

temp = decays;
for i = length(decaychoice):-1:1
    IRFs(end+1) = decays(decaychoice(i));
    temp(decaychoice(i)) = [];
end
decays = temp;

set(handles.decays,'UserData',decays)
set(handles.IRFs,'UserData',IRFs)
updatedecays(handles)
updateIRFs(handles)
set(handles.DecaysListbox,'Value',1)
set(handles.IRFsListbox,'Value',length(IRFs))
updateplot(handles)
function SwitchDecayPushbutton_CreateFcn(hObject, ~, handles) %% Runs when the button is created
set(hObject,'FontName','Symbol','String',char(174),'FontSize',12)

function SwitchIRFPushbutton_Callback(hObject, ~, handles) %% Switch IRF to decay pushbutton callback
% Get current data
IRFs = get(handles.IRFs,'UserData');
IRFchoice = get(handles.IRFsListbox,'Value');
decays = get(handles.decays,'UserData');
if (isempty(IRFchoice)) || (isempty(IRFs))
    return
end

temp = IRFs;
for i = length(IRFchoice):-1:1
    decays(end+1) = IRFs(IRFchoice(i));
    temp(IRFchoice(i)) = [];
end
IRFs = temp;

set(handles.decays,'UserData',decays)
set(handles.IRFs,'UserData',IRFs)
updatedecays(handles)
updateIRFs(handles)
set(handles.DecaysListbox,'Value',length(decays))
set(handles.IRFsListbox,'Value',1)
updateplot(handles)
function SwitchIRFPushbutton_CreateFcn(hObject, ~, handles) %% Runs when the pushbutton is creacted
set(hObject,'FontName','Symbol','String',char(172),'FontSize',12)

function AddDecayPushbutton_Callback(hObject, ~, handles) %% Add decay pushbutton callback
File_LoadDecay_Callback(handles.File_LoadDecay, [], handles)

function AddIRFPushbutton_Callback(hObject, ~, handles) %% Add IRF pushbutton callback
File_LoadIRF_Callback(handles.File_LoadIRF, [], handles)

function RemoveDecayPushbutton_Callback(hObject, ~, handles) %% Delete decay pushbutton callback
decays = get(handles.decays,'UserData');
decaychoice = get(handles.DecaysListbox,'Value');
if (isempty(decaychoice)) || (isempty(decays))
    return
end

decays(decaychoice) = [];

set(handles.decays,'UserData',decays)

% Remove fits with this decay
fits = get(handles.fits,'UserData');
try
    for i = 1:length(decaychoice)
        [fits(decaychoice(i),:,:)] = [];
    end
    fits(handles.settings.startup.maxdecays,handles.settings.startup.maxIRFs,length(get(handles.FitModelsListbox,'String'))).decay = [];
catch, end
set(handles.fits,'UserData',fits)

% Remove global pairs with this decay
if strcmp(get(handles.GlobalFit,'State'),'on')
    for i = 1:length(decaychoice)
        Global = get(handles.GlobalList,'UserData');
        indices = [];
        for i = 1:length(Global)
            index = Global(i).index(1);
            if index==decaychoice(i)
                indices(end+1) = i;
            end
        end
        Global(indices) = [];
    end
    set(handles.GlobalDataListbox,'String',{Global.names}')
    set(handles.GlobalDataListbox,'Value',1)
    set(handles.GlobalList,'UserData',Global)
end

% Update
updatedecays(handles)
if isempty(decays)
    set(handles.DecaysListbox,'Value',1)
elseif decaychoice(end)>length(decays)
    set(handles.DecaysListbox,'Value',length(decays))
end
updateParTable(handles)
updateGlobal(handles)
updateplot(handles)

function RemoveIRFpushbutton_Callback(hObject, ~, handles) %% Delete IRF pushbutton callback
IRFs = get(handles.IRFs,'UserData');
IRFchoice = get(handles.IRFsListbox,'Value');
if (isempty(IRFchoice)) || (isempty(IRFs))
    return
end

% Delete selected IRF
IRFs(IRFchoice) = [];
set(handles.IRFs,'UserData',IRFs)

% Remove fits with this IRF
fits = get(handles.fits,'UserData');
try 
    [fits(:,IRFchoice,:)] = [];
    fits(handles.settings.startup.maxdecays,handles.settings.startup.maxIRFs,length(get(handles.FitModelsListbox,'String'))).decay = [];
catch, end
set(handles.fits,'UserData',fits)

% Remove global pairs with this decay
if strcmp(get(handles.GlobalFit,'State'),'on')
    Global = get(handles.GlobalList,'UserData');
    indices = [];
    for i = 1:length(Global)
        index = Global(i).index(2);
        if index==IRFchoice
            indices(end+1) = i;
        end
    end
    Global(indices) = [];
    set(handles.GlobalDataListbox,'String',{Global.names}')
    set(handles.GlobalDataListbox,'Value',1)
    set(handles.GlobalList,'UserData',Global)
end

% Update
updateIRFs(handles)
if isempty(IRFs)
    set(handles.IRFsListbox,'Value',1)
elseif IRFchoice(end)>length(IRFs)
    set(handles.IRFsListbox,'Value',length(IRFs))
end
updateParTable(handles)
updateGlobal(handles)
updateplot(handles)

function ParTable_CellEditCallback(hObject, eventdata, handles) %% Runs when a change has been made in the parameter table
% hObject    handle to uitable8 (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
modelchoice = get(handles.FitModelsListbox,'Value');
if strcmp(get(handles.GlobalFit,'State'),'off')
    decaychoices = get(handles.DecaysListbox,'Value');
    IRFchoice = get(handles.IRFsListbox,'Value');
    fits = get(handles.fits,'UserData');
    if length(decaychoices) > 1
        for i = 1:length(decaychoices)
            decaychoice = decaychoices(i);
            temp = get(hObject,'data');
            fits(decaychoice,IRFchoice,modelchoice).pars(:,1) = temp(:,1);
        end
    else
        decaychoice = decaychoices(1);
        fits(decaychoice,IRFchoice,modelchoice).pars = get(hObject,'data');
    end
    set(handles.fits,'UserData',fits)
elseif strcmp(get(handles.GlobalFit,'State'),'on')
    Global = get(handles.GlobalList,'UserData');
    GlobalPars = get(handles.GlobalParListbox,'Value');
    
    if ismember(eventdata.Indices(1,1),GlobalPars)
        for i = 1:length(Global)
            Global(i).pars{modelchoice,1}(eventdata.Indices(1),eventdata.Indices(2)) = eventdata.NewData; % Set all global pars equal edited cell
        end
    else
        globalchoice = get(handles.GlobalDataListbox,'Value');
        if (isempty(Global)) || (isempty(globalchoice))
            return
        end
        Global(globalchoice).pars{modelchoice} = get(hObject,'data');
    end
    set(handles.GlobalList,'UserData',Global)
end

plotdist(handles)
plotlifetimes(handles)
updateGlobal(handles)
PlotPushbutton_Callback(hObject, [], handles)
function ParTable_CreateFcn(hObject, ~, handles) %% Runs when the parameter table is created

function FitShiftCheckbox_Callback(hObject, ~, handles) %% The fit shift checkbox callback
fitshiftCheckboxCallback(handles)

function ShiftTable_CellEditCallback(hObject, ~, handles) %% Runs when the shift table values have been altered
shifttable = get(hObject,'data');
if strcmp(get(handles.GlobalFit,'State'),'off')
    shifts = get(handles.ShiftTable,'UserData');
    shifts{get(handles.DecaysListbox,'Value'),get(handles.IRFsListbox,'Value')} = shifttable;
    set(handles.ShiftTable,'UserData',shifts)
elseif strcmp(get(handles.GlobalFit,'State'),'on')
    Global = get(handles.GlobalList,'UserData');
    globalchoice = get(handles.GlobalDataListbox,'Value');
    if (~isempty(Global)) && (~isempty(globalchoice))
        Global(globalchoice).shifts = shifttable;
    end
    set(handles.GlobalList,'UserData',Global)
    updateGlobal(handles)
end

set(handles.ShiftSlider,'Value',shifttable(1))

update_channelshift(handles)
updateplot(handles)

function ShiftSlider_Callback(hObject, ~, handles) %% The shift slider
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
value = get(hObject,'Value');

% Update shifttable
shifttable = get(handles.ShiftTable,'data');
shifttable(1) = value;
set(handles.ShiftTable,'data',shifttable)
ShiftTable_CellEditCallback(handles.ShiftTable, [], handles)
function ShiftSlider_CreateFcn(hObject, ~, handles) %% Runs when the shift slider is created
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function IncludeScatterCheckbox_Callback(hObject, ~, handles) %% The include scatter checkbox callback
set(handles.Stop,'State','off')

% ---------------------------- FRET menus ----------------------------

function DAdistListbox_Callback(hObject, ~, handles) %% The distribution listbox selection callback
plotdist(handles)
function DAdistListbox_CreateFcn(hObject, ~, handles) %% Runs when the distribution listbox is created
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function CIestimateCheckbox_Callback(hObject, ~, handles) %% The estimate CI checkbox callback

function ImportDistCheckbox_Callback(hObject, ~, handles) %% The use imported distribution callback
choice = get(hObject,'Value');
if choice == 1
    set([handles.DistTextbox handles.DAdistListbox handles.TruncateTextbox handles.TruncateEditbox handles.TwoDviewCheckbox],'Visible','on')
    plotdist(handles)
    Tools_ImportDistanceDistribution_Callback(handles.Tools_ImportDistanceDistribution, [], handles) % Open import wizard
elseif choice == 0
    set([handles.DistTextbox handles.DAdistListbox handles.TruncateTextbox handles.TruncateEditbox handles.TwoDviewCheckbox],'Visible','off')
    plotdist(handles)
    
end

function DynamicAvgRadiobutton_Callback(hObject, ~, handles) %% The use dynamic averaging radiobutton
if get(hObject,'Value') == 1
    set(handles.StaticAvgRadiobutton,'Value',0)
elseif get(hObject,'Value') == 0
    set(handles.StaticAvgRadiobutton,'Value',1)
end
PlotPushbutton_Callback(hObject, [], handles)

function StaticAvgRadiobutton_Callback(hObject, ~, handles) %% The use static averaging radiobutton
if get(hObject,'Value') == 1
    set(handles.DynamicAvgRadiobutton,'Value',0)
elseif get(hObject,'Value') == 0
    set(handles.DynamicAvgRadiobutton,'Value',1)
end
PlotPushbutton_Callback(hObject, [], handles)

function TruncateEditbox_Callback(hObject, ~, handles) %% The Truncate distribution editbox
T = str2double(get(hObject,'String'));
T = abs(T);
if T > 100
    T = 100;
end
set(hObject,'String',T)
plotdist(handles)
function TruncateEditbox_CreateFcn(hObject, ~, handles) %% Runs when the editbox is created
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function TwoDviewCheckbox_Callback(hObject, ~, handles) %% The 2D view checkbox callback
plotdist(handles)

% --------------------------- Global menus ---------------------------

function GlobalAddPushbutton_Callback(hObject, ~, handles) %% Add selected decay and IRF to global listbox button callback
decaychoices = get(handles.DecaysListbox,'Value');
IRFchoice = get(handles.IRFsListbox,'Value');
modelchoice = get(handles.FitModelsListbox,'Value');
decays = get(handles.decays,'UserData');
IRFs = get(handles.IRFs,'UserData');
fits = get(handles.fits,'UserData');
if (isempty(decaychoices)) || (isempty(IRFchoice)) || (isempty(decays)) || (isempty(IRFs))
    return
end

for i = 1:length(decaychoices)
    decaychoice = decaychoices(i);
    scatter = squeeze([fits(decaychoice,IRFchoice,:).scatter])';
    Global = get(handles.GlobalList,'UserData');
    
    if isempty(Global)
        Global(1).names = sprintf('[%s]+[%s]',decays(decaychoice).name,IRFs(IRFchoice).name);
        Global(1).index = []; % Will be updated by updateGlobalIndex
        Global(1).pars = {fits(decaychoice,IRFchoice,:).pars}';
        Global(1).shifts = get(handles.ShiftTable,'data');
        Global(1).scatter = scatter;
        Global(1).tail = fits(decaychoice,IRFchoice,1).tail;
    else
        Global(end+1,1).names = sprintf('[%s]+[%s]',decays(decaychoice).name,IRFs(IRFchoice).name);
        Global(end,1).index = []; % Will be updated by updateGlobalIndex
        Global(end,1).pars = {fits(decaychoice,IRFchoice,:).pars}';
        Global(end,1).shifts = get(handles.ShiftTable,'data');
        Global(end,1).scatter = scatter;
        Global(end,1).tail = fits(decaychoice,IRFchoice,1).tail;
    end
    
    set(handles.GlobalList,'UserData',Global)
    set(handles.GlobalDataListbox,'String',{Global.names})
end

updateGlobal(handles)
Global = get(handles.GlobalList,'UserData');
set(handles.GlobalDataListbox,'Value',length(Global))
updateplot(handles)

function GlobalRemovePushbutton_Callback(hObject, ~, handles) %% Remove selected pair from global list button callback
Global = get(handles.GlobalList,'UserData');
Globallist = get(handles.GlobalDataListbox,'String');
Globalchoice = get(handles.GlobalDataListbox,'Value');
if (isempty(Global)) || (isempty(Globallist)) || (isempty(Globalchoice))
    return
end

Global(Globalchoice) = [];
set(handles.GlobalDataListbox,'String',{Global.names}','Value',1)
set(handles.GlobalList,'UserData',Global)
updateGlobal(handles)
updateplot(handles)

function GlobalParListbox_Callback(hObject, ~, handles) %% Runs when a selection is made in the global parameter listbox
defaultglobalparselect = get(handles.GlobalParListbox,'UserData');
defaultglobalparselect{get(handles.FitModelsListbox,'Value'),1} = get(hObject,'Value');
set(handles.GlobalParListbox,'UserData',defaultglobalparselect)
updateplot(handles)
function GlobalParListbox_CreateFcn(hObject, ~, handles) %% Runs when the listbox is created
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function GlobalDataListbox_Callback(hObject, ~, handles) %% Runs when a selection is made in the global data listbox
updateGlobal(handles)
updateplot(handles)
function GlobalDataListbox_CreateFcn(hObject, ~, handles) %% Runs when the listbox is created
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --------------------------- Message board ---------------------------

function mboard_Callback(hObject, ~, handles) %% Runs when something is typed in the message board
decays = get(handles.decays,'UserData');
IRFs = get(handles.IRFs,'UserData');

input = get(hObject,'String');
try
    T = evalc(input);
    set(handles.mboard,'String',T)
catch err
end

% Update
set(handles.decays,'UserData',decays)
set(handles.IRFs,'UserData',IRFs)
updatedecays(handles)
updateIRFs(handles)
function mboard_CreateFcn(hObject, ~, handles) %% Runs when the message board is created
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
