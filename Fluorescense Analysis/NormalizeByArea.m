%normalizes lifetime by area nuder the curve
function norm_array = NormalizeByArea(time,lifetime, baseline_region)
    %time -- x-axis of the lifetime trace
    %lifetime -- lifetime y-values
    %baseline_region -- index region of the lifetimes for baseline subtraction
    
    if isempty(baseline_region)
        baseline_region = 1:10;
    end
    lifetime = lifetime-mean(lifetime(baseline_region));
    norm_array = lifetime./trapz(time,lifetime);
    %norm_array = lifetime./max(lifetime);
end