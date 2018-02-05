function I = FRET(variables)
I = [];
% Export variable names and default values:
variable_names = {'R0 /Å';'R-mean /Å';'FWHM /Å';'a1';'tauD1 /ns';'a2';'tauD2 /ns';'a3';'tauD3 /ns';'f';'b';'tauB'}; % Parameter names
default_par = [...
    55 55 55;...
    55 0 100;...
    20 0 50;...
    1 1 1;...
    4 4 4;... % tau start value, lower bound, upper bound
    0 0 0;...
    1 1 1;...
    0 0 0;...
    7 7 7;...
    0 0 0;...
    0 0 0;...
    7 7 7]; % ...
model = 'I(t) =(1-b)[ (1-f)P(R)*sum(ai*exp[(-t/tauDi)*(1+(R0/R)^6)]) + f*sum(ai*exp[-t/tauDi]) ] + b*exp(-t/tauB)'; % To be displayed in GUI
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
R0 = variables(1);
Rm = variables(2);
FWHM = variables(3);
a1 = variables(4);
tauD1 = variables(5);
a2 = variables(6);
tauD2 = variables(7);
a3 = variables(8);
tauD3 = variables(9);
f = variables(10);
b = variables(11);
tauB = variables(12);

% Make 15 equally spaced distances
Rs = linspace(Rm-FWHM*1.5,Rm+FWHM*1.5,15);
P = normpdf(Rs,Rm,FWHM/2.3548)'; % Make Gaussian on Rs
P(Rs<=0) = []; % Remove points with negative R
Rs(Rs<=0) = [];

handles = getappdata(0,'handles');

%---- Action ----%

% Static averaging:
if get(handles.StaticAvgRadiobutton,'Value') == 1
    I = a1*exp((-t/tauD1)*(1+(R0./Rs).^6)) + a2*exp((-t/tauD2)*(1+(R0./Rs).^6)) + a3*exp((-t/tauD3)*(1+(R0./Rs).^6));
    I = (1-b)*( (1-f)*I*P +  f*(a1*exp(-t/tauD1) + a2*exp(-t/tauD2) + a3*exp(-t/tauD3)))  +  b*exp(-t/tauB); % I is size [length(t)*length(Rs)]; P is size [length(Rs)*1]
    
% Dynamic averaging:
else
    I = (1-b)*( (1-f)*(a1*exp((-t/tauD1)*(1+(R0/Rm)^6)) + a2*exp((-t/tauD2)*(1+(R0/Rm)^6)) + a3*exp((-t/tauD3)*(1+(R0/Rm)^6)))...
        +  f*(a1*exp(-t/tauD1) + a2*exp(-t/tauD2) + a3*exp(-t/tauD3)))  +  b*exp(-t/tauB);
end



%---- Action for imported distribution ----%
if get(handles.ImportDistCheckbox,'Value') == 1
    dists = get(handles.DistTextbox,'UserData');
    if isempty(dists)
        return
    end
    dist = dists{get(handles.DAdistListbox,'Value')};

    Rmean = sum(dist(:,1).*dist(:,2))/sum(dist(:,2)); % Mean of imported
    dist(:,1) = dist(:,1)-Rmean;    % Move dist so that Rmean is 0
    Z = P*dist(:,2)';
    
    if length(P)<5
        return
    end

    % Interpolate Z onto xi and yi:
    xi = linspace(min(dist(:,1)), max(dist(:,1)), 99);% length(dist(:,1))*50);
    yi = linspace(min(Rs), max(Rs), 99);%length(Rs)*50);
    [xi,yi] = meshgrid(xi,yi);
    zi = interp2(dist(:,1),Rs,Z,xi,yi);
    
    % Calculate combined distribution
    R = xi+yi; % Combined distance of molecular + linker motion
    Rc = reshape(R,1,numel(R)); % combined Rs
    Pc = reshape(zi,numel(zi),1); % Combined Ps  ( dist2 = [Rc Pc] )
    Pc(Rc<0) = [];
    Rc(Rc<0) = [];

    % Bin combined distribution into numBins equally spaces R-bins
    numBins = 30;
    binEdges = linspace(min(Rc), max(Rc), numBins+1);
    [~,whichBin] = histc(Rc, binEdges);
    binSum = zeros(numBins,1);
    for i = 1:numBins
        flagBinMembers = (whichBin == i);
        binMembers     = Pc(flagBinMembers);
        binSum(i)      = sum(binMembers);
    end
    bins = binEdges(1:end-1)+((binEdges(2)-binEdges(1))/2); % Center of each bin
    Rc = bins; % R combined
    Pc = binSum; % P combined
    Pc = Pc/trapz(Rc,Pc);

    
    % Static averaging:
    if get(handles.StaticAvgRadiobutton,'Value') == 1
    I = a1*exp((-t/tauD1)*(1+(R0./Rc).^6)) + a2*exp((-t/tauD2)*(1+(R0./Rc).^6)) + a3*exp((-t/tauD3)*(1+(R0./Rc).^6));
    I = (1-b)*( (1-f)*I*Pc +  f*(a1*exp(-t/tauD1) + a2*exp(-t/tauD2) + a3*exp(-t/tauD3))) + b*exp(-t/tauB); % I is size [length(t)*length(Rs)]; P is size [length(Rs)*1]

    % Dynamic averaging:
    elseif get(handles.StaticAvgRadiobutton,'Value') == 0
        Rm = sum(Rc.*Pc/sum(Pc)); % Mean of combined
        I = (1-b)*( (1-f)*( a1*exp((-t/tauD1)*(1+(R0/Rm)^6)) + a2*exp((-t/tauD2)*(1+(R0/Rm)^6)) + a3*exp((-t/tauD3)*(1+(R0/Rm)^6)) )...
            +  f*( a1*exp(-t/tauD1) + a2*exp(-t/tauD2) + a3*exp(-t/tauD3) ) ) + b*exp(-t/tauB);
    end
    
end

% figure(5)
% set(gca,'YScale','log')
% figure(6)
% plot(Rs,P)

