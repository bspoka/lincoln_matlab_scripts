function freq_axis = get_freq_axis(stage_positions, pos_unit, axis_unit)
            
            retro_factor = 2;
            
            switch pos_unit
                
                case 'mm'
                    cm_divisor = 10; %%stage positions should be in cm
                    step = abs(stage_positions(2)-stage_positions(1))/cm_divisor;
                    step_size = retro_factor*step;
                    fs = 1./step_size; %%sampling frequency
                otherwise
                    fprintf('Not supported length scale\n');
            end
            
            freq =linspace(-fs/2, fs/2, numel(stage_positions)); %%frequency axis in cm^-1
            %freq =linspace(0, fs, numel(stage_positions));
            switch axis_unit
                case 'ev'
                    freq_axis = freq./8065.54; %%frequency axis in eV
                case 'wavenum'
                    freq_axis = freq;
                case 'nm'
                    freq_axis = 1E7./freq;
                case 'mev'
                    freq_axis = (freq./8065.54)*1000; %%frequency axis in meV
                otherwise
                    fprintf('Not supported energy scale\n');
                    freq_axis = [];
            end
            
        end