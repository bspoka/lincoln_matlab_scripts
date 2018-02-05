function hf = mymsgbox(varargin)
% Displays a message box with custom logo and title. Same use as msgboxsms.
%
%   Type help msgbox for info on use
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

% Defaults
if nargin<1
    varargin{1} = 'Empty info message'
end
if nargin<2
    varargin{2} = 'DecayFit';
end

% Message box
h = msgbox(varargin{:});
updatelogo(h) % Sets message box logo

% Output handle
if nargout>0
    hf = h;
end
