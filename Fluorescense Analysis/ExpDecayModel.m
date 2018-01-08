%generates an exponential decay model
function exp_decay = ExpDecayModel(time,num_exponentials,coeffs)
    %time -- x-axis of lifetime trace
    %num_exponentials -- number of exponential components in the model
    %coeffs -- exponential coefficients (amplitude, time pairs)
    
    switch num_exponentials 
        case 1
            exp_decay = exp(-time/coeffs(2));
        case 2
            exp_decay = coeffs(4).*exp(-time/coeffs(2))...
                + (coeffs(5)).*exp(-time/coeffs(3));    
        case 3
            exp_decay = coeffs(5).*exp(-time/coeffs(2))...
                + coeffs(6).*exp(-time/coeffs(3))...
                + coeffs(7).*exp(-time/coeffs(4));
    end
end