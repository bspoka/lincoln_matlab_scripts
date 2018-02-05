function myopenURL(URL)
% Attempts to load the URL in a browser window. If unsuccessful, a message
% box is displayed
%
%    Input:
%     URL       - internet address
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
    state = web(URL,'-browser');
    if state~=0 % If unsuccessfull
        mymsgbox(sprintf('Internet action unsuccessful. Open page manually in your browser:\n\n%s',URL))
    end
catch err
    mymsgbox(sprintf('Internet action unsuccessful. Open page manually in your browser:\n\n%s',URL))
end
