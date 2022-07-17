try 
d.unload
catch ERR
end 
fclose all;clear class;clear;clc;close all;
addpath(genpath(pwd));

%% Choose Network and simulation parameters
inpname='Hanoi_CMH_24h.inp';    
d=epanet(inpname);
demandTime = 0; % select demand hour to start simulate
simDuration = 24; % in hours
d.setTimeSimulationDuration(simDuration*60*60)
d.setTimePatternStart(demandTime*60*60) %in seconds
d.setTimeHydraulicStep(30*60)
d.setTimeReportingStep(30*60)
nn = double(d.getNodeCount);
nj = double(d.getNodeJunctionCount);
nl = double(d.getLinkCount);
elevations = double(d.getNodeElevations);
reservoirInd = double(d.getNodeReservoirIndex);
reservoir_link=find(d.NodesConnectingLinksIndex(:,1)==reservoirInd);

%% Get actual system states
allParameters=d.getComputedHydraulicTimeSeries;
H = allParameters.Head';
P = allParameters.Pressure';
Q = allParameters.Flow';
D = allParameters.Demand';
LinkStatus = allParameters.Status'; % flows, heads, pressures, demands
H(reservoirInd,:)=[]; % remove reservoir from node states
P(reservoirInd,:)=[];
D(reservoirInd,:)=[];
x = [Q; H; D]; %actual system state

%% Get measurements:
%%% measurement uncertainty:
flow_sigma = 0.1;
pres_sigma = 0.1;
dem_unc = 0.2;

%%% measurements (y) from all states:
% create measurements by adding gaussian noise to measured states
xn = [Q + (flow_sigma*Q) .* (sqrt(flow_sigma)*randn(size(Q)));
     H + (pres_sigma*P) .* (sqrt(pres_sigma)*randn(size(H)));
     D + (dem_unc*D)    .* (sqrt(dem_unc)*randn(size(D))) ];

%%% Select measured states index:
flow_meas_ind = reservoir_link; % flow measurements
pressure_sens_IDs ={'13','16','22','30'};
pres_meas_ind = double(d.getNodeIndex(pressure_sens_IDs)); % pressure measurements
dem_meas_ind = double(d.getNodeJunctionIndex); % demand measurements

%%% Identify measurements using C matrix: 
C1 = flow_meas_ind;
C2 = nl+pres_meas_ind;
C3 = nl+nj+dem_meas_ind;
C = zeros(1,(nl+nj+nj));
C([C1 C2 C3])=1;
C=diag(C);
C = C(any(C,2),:);

%%% Measurements:
y = C*xn; % measured state
xa = C*x; % actual state

%%% example plot:
plot(xa(30,:))
hold all
plot(y(30,:))
legend('Actual', 'Measured')
