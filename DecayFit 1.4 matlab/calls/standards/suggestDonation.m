function handles = suggestDonation(handles, count)
% Prompts the user for a donation if the program has been run a large
% number of times
%
%    Input:
%     handles   - handles structure of the main window
%     count     - number of times the program has been run
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

try
    
    % Frequency
    f = 10;
    
    % If count has reached frequency
    if f*round(double(count)/f) == count
        
        %% Dialog
        
        message = sprintf(['Hi there,\n\nYou seem to be using this software quite a lot. That''s great!\n\n'...
            'To keep maintaining it I need your help in one or more ways:\n'...
            '   1) Simply write a positive comment about your use of this software below and press send. You are 100%% anonymous.\n'...
            '   2) Make a donation, either you or your nearest leader. Follow the link below to learn more.\n'...
            '   3) Send your usage statistics, 100%% anonymously and 100%% automated. This setting can be turned on in the Help menu.\n'...
            '   4) Remember to cite the software properly as described on the website. Follow the link below to learn more.\n\n'...
            'Either one would mean a great deal to me.\n\n'...
            'All the best,\nSøren ']);
        
        fh = dialog('name','Want more?',...
            'UserData', 'Cancel',...
            'Visible', 'off');
        updatelogo(fh)
        
        h.text = uicontrol('Parent',fh,...
            'style', 'text',...
            'String', message,...
            'HorizontalAlignment',   'left');
        h.text2 = uicontrol('Parent',fh,...
            'style', 'text',...
            'String', 'Write a comment here and press send: ',...
            'HorizontalAlignment',   'left');
        h.edit = uicontrol('Parent',fh,...
            'style', 'edit',...
            'String', '',...
            'max', 2,...
            'BackgroundColor', [1 1 1],...
            'HorizontalAlignment',   'left');
        h.webbut = uicontrol('Parent',fh,...
            'style','pushbutton',...
            'String', ' Go to site ');
        h.closebut = uicontrol('Parent',fh,...
            'style','pushbutton',...
            'String', ' Close ');
        h.sendbut = uicontrol('Parent',fh,...
            'style','pushbutton',...
            'String', ' Send comment ');
        
        % Update handle structure
        h.fh = fh;
        guidata(h.fh,h)
        
        %% Size
        verspace = 5;
        horspace = 5;
        txtH = 210;
        txtW = 700;
        txtH2 = 22;
        txtW2 = txtW;
        edtH = 100;
        edtW = txtW;
        butW = 120;
        butH = 30;
        GUIwidth = 2*horspace+txtW;
        GUIheight = 5*verspace+butH+txtH+edtH+txtH2;
        setpixelposition(h.text,[horspace GUIheight-verspace-txtH txtW txtH])
        vpos = verspace+butH+verspace;
        setpixelposition(h.edit,[horspace vpos edtW edtH])
        setpixelposition(h.text2,[horspace vpos+edtH+verspace txtW2 txtH2])
        
        setpixelposition(h.sendbut,[GUIwidth-horspace-butW verspace butW butH])
        setpixelposition(h.closebut,[GUIwidth-2*butW-2*horspace verspace butW butH])
        setpixelposition(h.webbut,[GUIwidth-3*butW-3*horspace verspace butW butH])
        setpixelposition(h.fh, [100 100 GUIwidth GUIheight])
        movegui(h.fh,'center')
        
        %% Callbacks
        set([h.webbut h.closebut h.sendbut],'Callback',{@buttoncallback,h})
        
        %% Wait for buttonpress
        set(h.fh,'visible','on')
        uiwait(h.fh)
        
        % Close
        try delete(fh), end
        
        % Turn attention back to program
        figure(handles.figure1)
        
    end
    
end

end

function buttoncallback(hObject,event,h)
if strcmpi(get(hObject,'String'),' Go to site ')
    % Go to website
    myopenURL('http://www.fluortools.com/misc/donate')
    
elseif strcmp(get(hObject,'String'),' Send comment ')
    
    % Send message
    if isempty(get(h.edit,'string'))
        mymsgbox('Message box is empty.')
        return
    end
    
    % Setup prefs
    setpref('Internet','SMTP_Server','mail.fluortools.com');
    setpref('Internet','E_mail','decayfit@user.com')
    try
        sendmail('spreus@fluortools.com',...
            'DecayFit user feedback',...
            get(h.edit,'string'))
        
        mymsgbox('Thank you. Your comment was sent.')
    end
end

% Close
uiresume(gcbf);
end
