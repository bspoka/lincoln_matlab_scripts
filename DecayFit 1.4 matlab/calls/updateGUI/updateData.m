function updateData(handles, decays, IRFs, fits)
% Updates the userdata storing spectral datasets
%
%    Input:
%     handles - handles structure of the main window
%     decays  - decays structure
%     IRFs    - IRF structure
%     fits    - fits structure
%

% --- Copyrights (C) ---
%
% This file is part of:
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

if nargin>=2 && isstruct(decays)
    set(handles.decays,'UserData',decays)
    updatedecays(handles)
end
if nargin>=3 && isstruct(IRFs)
    set(handles.IRFs,'UserData',IRFs)
    updateIRFs(handles)
end
if nargin>=4 && isstruct(fits)
    set(handles.fits,'UserData',fits)
end
