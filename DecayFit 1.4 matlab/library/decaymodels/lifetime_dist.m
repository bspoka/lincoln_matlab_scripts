%% FOR IMPLEMENTING YOUR OWN MODEL RENAME FILE AND CHANGE THE 6 PARTS WRITTEN IN CAPITAL

function I = lifetime_dist(variables)  %% 1) SET NAME OF MODEL SAME AS FILENAME
I = [];
% Export variable names and default values:
variable_names = {'a1';'<t1> /ns';'FWHM1 /ns';'<t2> /ns';'FWHM2 /ns'};  %% 2) PARAMETER NAMES
default_par = [...  %% 3) DEFAULT PARAMETER VALUES: [START1 'LOWER BOUND1' 'UPPER BOUND1'; START2 'LOWER BOUND2' 'UPPER BOUND2';...]
    0.8 0 1;... % a1 start value, lower bound, upper bound
    2 0 25;... % ...
    0.5 0 5;...
    5 0 25;...
    1 0 5];
model = 'I(t) = a1*sum[ P1(t)*exp(-t/ti) ] + (1-a1)*sum[ P2(t)*exp(-t/ti) ]';  %% 4) FIT MODEL TO BE DISPLAYED IN NanoTime
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
t1 = variables(2);
FWHM1 = variables(3);
t2 = variables(4);
FWHM2 = variables(5);

%---- Action ----%

% Make 15 equally spaced lifetimes of each component
ts1 = linspace(t1-FWHM1*1.5,t1+FWHM1*1.5,15);
ts2 = linspace(t2-FWHM2*1.5,t2+FWHM2*1.5,15);
P1 = normpdf(ts1,t1,FWHM1/2.3548)'; % Make Gaussian on taus 1
P2 = normpdf(ts2,t2,FWHM2/2.3548)'; % Make Gaussian on taus 2
P1(ts1<=0) = []; % Remove points with negative R
P2(ts2<=0) = [];
ts1(ts1<=0) = []; % Remove points with negative R
ts2(ts2<=0) = [];

I1 = exp(-t*(1./ts1))*P1;
I2 = exp(-t*(1./ts2))*P2;
I = a1*I1 +(1-a1)*I2;


