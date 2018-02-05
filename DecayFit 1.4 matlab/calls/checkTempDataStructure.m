function temp = checkTempDataStructure(temp)
% Check if structure temp contains a data-field with numeric data of length
% > 10
%
%   Input:
%    temp  - structure formed by importdata
%
%   Output:
%    temp  - ..
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

if isstruct(temp) % Check input data field
    if ~myIsField(temp,'data') % If there is a data field
        fnames = fieldnames(temp);
        if length(fnames)==1 % If there is only one field, set it to data
            temp.data = getfield(temp, fnames{1});
        end
    end
else error
end
if isnumeric(temp)
    error
end

% If length of data vector is <10 it is likely because the data was
% not read correctly
if size(temp.data,1)<10
    error
end
 