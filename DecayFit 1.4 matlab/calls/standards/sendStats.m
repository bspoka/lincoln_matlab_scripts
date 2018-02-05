function handles = sendStats(handles, count)
% Sends stats on program usage on closing
%
%    Input:
%     handles   - handles structure of the main window
%     count     - number of times program has been run
%
%    Output:
%     handles   - ..
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

%% Info dialog

if handles.settings.infobox.sendstats
    try
        handles = presentDlg(handles);
    end
    
    % Turn attention back to figure
    figure(handles.figure1)
    
end

%% Send stats

% Only send if allowed to
if ~handles.settings.close.sendstats
    return
end

try
    
    % Info
    usage = handles.use;
    usage.settings = handles.settings;
    usage.name = handles.name;
    usage.version = handles.version;
    usage.count = count; % Number of times program has been run
    
    [decays IRFs] = getData(handles);
    usage.nDecays = length(decays);
    usage.nIRFs = length(IRFs);
    
    % Setup prefs
    setpref('Internet','SMTP_Server','mail.fluortools.com');
    setpref('Internet','E_mail','decayfit@user.com')
    
    % Send info
    tempfile = fullfile(handles.workdir,'temp.mat');
    save(tempfile,'usage')
    try
        sendmail('spreus@fluortools.com',...
            'DecayFit usage stats',...
            ' ',...
            tempfile)
    end
    
    % Clean up
    delete(tempfile)
end

%% Nested

    function handles = presentDlg(handles)
        
        % Ask if it's ok
        message = sprintf(['You can help improve this free software by sending your usage statistics.\n\n'...
            '  - The program only collects info on how many times a given button is pressed, nothing else. \n'...
            '  - You are 100%% anonymous.\n'...
            '  - Stats are uploaded every time the program closes.\n'...
            '  - There is no delay time in program performance.\n\n'...
            'This settings can be turned on/off at any time from the Help menu.']);
        name = 'Send stats';
        
        % Prepare dialog
        prompt = {message '';...
            '' 'sendsts';...
            'Don''t show this box again ' 'choice'};
        formats = prepareformats();
        formats(2,1).type   = 'text';
        formats(4,1).type = 'list';
        formats(4,1).style = 'popupmenu';
        formats(4,1).items = {'Send stats'; 'Don''t send'};
        formats(6,1).type   = 'check';
        
        DefAns.sendsts = 1;
        DefAns.choice = 0;
        
        options.CancelButton = 'off';
        options.ButtonNames = {'OK'};
        
        % Open dialog
        [answer cancelled] = myinputsdlg(prompt, name, formats, DefAns, options);
        
        % Answer
        if cancelled || answer.sendsts==2
            
            % User pressed no
            if answer.choice
                
                % Sure box 1
                answer = myquestdlg('Why not help improve a free software when there is absolutely nothing to loose?',...
                    'Why not?',...
                    'Distrust', 'I don''t know', ' OK, send the damn stats! ',...
                    ' OK, send the damn stats! ');
                
                % Sure box 2
                if strcmpi(answer,' OK, send the damn stats! ')
                    sendsts = 1;
                    
                elseif strcmpi(answer,'Distrust')
                    answer = myquestdlg('I cross my heart.',...
                        'Not trusting?',...
                        'Still no', ' OK, send the damn stats! ',...
                        ' OK, send the damn stats! ');
                    sendsts = checkAnswer(answer);
                    
                elseif strcmpi(answer,'I don''t know')
                    answer = myquestdlg('Then you should press OK.',...
                        'You don''t know?',...
                        'Still no', ' OK, send the damn stats! ',...
                        ' OK, send the damn stats! ');
                    sendsts = checkAnswer(answer);
                end
                
                % Don't show message again
                handles.settings.infobox.sendstats = 0;
                
            else
                sendsts = 0;
            end
            
        else
            % User pressed ok
            handles.settings.infobox.sendstats = 0;
            sendsts = 1;
        end
        
        % Update default settings structure file
        handles.settings.close.sendstats = sendsts;
        updatemainhandles(handles)
        saveDefaultSettings(handles)
    end

    function sendsts = checkAnswer(answer)
        if strcmpi(answer,' OK, send the damn stats! ')
            sendsts = 1;
        else
            mymsgbox('Alright then, but remember that this setting can be turned on/off from the help menu at any time should you change your mind.')
            sendsts = 0;
        end
    end

end