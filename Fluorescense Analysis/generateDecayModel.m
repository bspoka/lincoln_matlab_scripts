function model_decay = generateDecayModel(model_name, model_paramaters, time_axis)

%%lifetime decay models
switch model_name
    case decayModels.singleExponential
        tau = model_paramaters(2);
        a1 = model_paramaters(1);
        model_decay = a1.*exp(-time_axis./tau);
        
    case decayModels.doubleExponential
        a1 = model_paramaters(1);
        t1 = model_paramaters(2);
        t2 = model_paramaters(3);
        
        model_decay = a1.*exp(-time_axis./t1) + (1-a1).*exp(-time_axis./t2);
        
    case decayModels.tripleExponential
        a1 = model_paramaters(1);
        t1 = model_paramaters(2);
        a2 = model_paramaters(3);
        t2 = model_paramaters(4);
        a3 = model_paramaters(5);
        t3 = model_paramaters(6);
        sum_amps = (a1+a2+a3);
        
        model_decay = a1./sum_amps.*exp(-time_axis./t1) + a2./sum_amps.*...
            exp(-time_axis./t2)+ a3./sum_amps.*exp(-time_axis./t3);
        
    case decayModels.quadrupleExponential
        a1 = model_paramaters(1);
        t1 = model_paramaters(2);
        a2 = model_paramaters(3);
        t2 = model_paramaters(4);
        a3 = model_paramaters(5);
        t3 = model_paramaters(6);
        a4 = model_paramaters(7);
        t4 = model_paramaters(8);
        sum_amps = (a1+a2+a3+a4);
        
        model_decay = a1./sum_amps.*exp(-time_axis./t1) + a2./sum_amps.*...
            exp(-time_axis./t2)+ a3./sum_amps.*exp(-time_axis./t3) + ...
            a4./sum_amps.*exp(-time_axis./t4);
        
    otherwise
        disp('Unsupported lifetime decay model...')
        
        
end