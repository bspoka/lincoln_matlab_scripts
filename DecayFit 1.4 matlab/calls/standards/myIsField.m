function isFieldResult = myIsField (inStruct, fieldName) 
% Check if fieldname exists in structure
%
%    Input:
%     inStruct  - name of the structure or an array of structures to search
%     fieldName - name of the field for which the function searches
%
%    Output:
%     1/0
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

% Default:
isFieldResult = 0;

% Loop through the fields of the structure
f = fieldnames(inStruct(1));
for i=1:length(f)
    
    if(strcmp(f{i},strtrim(fieldName)))
        
        isFieldResult = 1;
        return;
    
    elseif isstruct(inStruct(1).(f{i}))
        
        % If sub-field is empty, make it length 1
        if isempty(inStruct(1).(f{i}));
            temp = inStruct(1).(f{i});
            f2 = fieldnames(temp);
            if isempty(f2)
                return
            end
                
            temp(1).(f2{1}) = 1;
            inStruct(1).(f{i}) = temp;
        end
        
        % Check existence in subfield
        isFieldResult = myIsField(inStruct(1).(f{i}), fieldName);
        if isFieldResult
            return;
        end
        
    end
    
end
