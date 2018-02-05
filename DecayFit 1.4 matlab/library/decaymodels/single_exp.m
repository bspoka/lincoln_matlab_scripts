%% FOR IMPLEMENTING YOUR OWN MODEL RENAME FILE AND CHANGE THE 6 PARTS WRITTEN IN CAPITAL:

function I = single_exp(variables)  %% 1) SET NAME OF MODEL SAME AS FILENAME
I = [];

% Export variable names and default values:
variable_names = {'tau /ns'};  %% 2) PARAMETER NAMES
default_par = [...  %% 3) DEFAULT PARAMETER VALUES: [START1 'LOWER BOUND1' 'UPPER BOUND1'; START2 'LOWER BOUND2' 'UPPER BOUND2';...]
    4 0 25];
model = 'I(t) = exp(-t/tau)';  %% 4) FIT MODEL TO BE DISPLAYED IN NanoTime
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
tau = variables(1);  %% 5) EXTRACT PARAMETER VALUES FROM VARIABLES INPUT

% Action:
I = exp(-t/tau);  %% 6) DECAY MODEL

