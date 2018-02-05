%% FOR IMPLEMENTING YOUR OWN MODEL RENAME FILE AND CHANGE THE 6 PARTS WRITTEN IN CAPITAL

function I = double_exp_uncon(variables)  %% 1) SET NAME OF MODEL SAME AS FILENAME
I = [];

% Export variable names and default values:
variable_names = {'a1';'a2';'t1 /ns';'t2 /ns'};  %% 2) PARAMETER NAMES
default_par = [...  %% 3) DEFAULT PARAMETER VALUES: [START1 'LOWER BOUND1' 'UPPER BOUND1'; START2 'LOWER BOUND2' 'UPPER BOUND2';...]
    -0.5 -1 1;...
    0.5 -1 1;...
    1 0 25;...
    6 0 25];
model = 'I(t) = a1*exp(-t/t1) + a2*exp(-t/t2)';  %% 4) FIT MODEL TO BE DISPLAYED IN NanoTime
setappdata(0,'varname',variable_names)
setappdata(0,'defaults',default_par)
setappdata(0,'model',model)

% Check input:
if variables==0
    return
elseif (nargin~=1) || (length(variables)~=size(variable_names,1))
    fprintf('Incorrect number of input arguments')
    return
end

% Get input:
t = getappdata(0,'t');
a1 = variables(1);  %% 5) EXTRACT PARAMETER VALUES FROM VARIABLES INPUT
a2 = variables(2);
t1 = variables(3);
t2 = variables(4);

% Action:
I = a1*exp(-t/t1)+a2*exp(-t/t2);  %% 6) DECAY MODEL
