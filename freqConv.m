function freq_out = freqConv(freq, unit_in, unit_out)

switch unit_in
    case 'nm'
        c = 2.99792458E17; %%nm/s
        h = 4.135667516E-15; %%eV/s plancks;
        switch unit_out
            case 'nm'
                freq_out = freq;
            case 'hz'
                freq_out = 2.*pi.*c./freq;
            case 'ev'
                freq_out = c.*h./freq;
            case 'wavenum'
                freq_out = 1E7./freq;
            otherwise
                fprintf('Unsupported conversion\n');
        end
        
    case 'ev'
        c = 2.99792458E17; %%nm/s
        h = 4.135667516E-15; %%eV/s plancks;
        switch unit_out
            case 'nm'
                freq_out = c.*h./freq;
            case 'hz'
                freq_out = 2.417990504024E14.*freq;
            case 'ev'
                freq_out = freq;
            case 'wavenum'
                freq_out = freq.*8065.54;
            otherwise
                fprintf('Unsupported conversion\n');
        end
        
    case 'wavenum'
        switch unit_out
            case 'wavenum'
                freq_out = freq;
            case 'nm'
                freq_out = 1E7./freq;
            case 'ev'
                freq_out = freq./8065.54;
            case 'hz'
                %freq_out = 
            otherwise
                fprintf('Unsupported conversion\n');
        end
        
    otherwise
        fprintf('Unsupported UNits\n');

        
end

end