classdef RecordType
    %enum of data record types
   enumeration
      Generic, H5Stream, HT3, PTU
   end
   %Generic -- dummy record type contains no functionality
   %H5Stream -- T2 or T3 photon record stream from LV program
   %HT3 -- old format T3 picoquant data
   %PTU -- new format T2 or T3 picoquant data
end