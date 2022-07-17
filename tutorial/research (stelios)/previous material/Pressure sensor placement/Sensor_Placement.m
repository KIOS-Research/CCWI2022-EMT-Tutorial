try 
d.unload
catch ERR
end 
fclose all;clear class;clear;clc;close all;
addpath(genpath(pwd));

%% Choose Network
[inpname,dispname] = enterNetwork([]);
d=epanet(inpname);

Sen_filename = [pwd,'\saved_sim\SensitivityMat_',dispname,'.mat'];
if isfile(Sen_filename)
% File exists:
loadSen = input(sprintf('\nLoad saved Sensitivity Matrix? (1=yes / 0=no): '));
else
% File does not exist:
loadSen = 0;
end
nj = double(d.getNodeJunctionCount);
nn = double(d.getNodeCount);
reservInd = d.getNodeReservoirIndex;
switch loadSen
    
case 0 % Calculate Sensitivity matrix
%% Calculate healthy states in extended time simulation:
d.setTimeSimulationDuration(24*60*60) % greater weight to low demand hours
d.setTimePatternStart(0) %in seconds
allParameters=d.getComputedTimeSeries;
P0 = allParameters.Pressure';
P0(d.getNodeReservoirIndex,:)=[];
Dem0 = allParameters.Demand';
simSteps = size(P0,2);

%% Create Augmented-time Sensitivity Matrix
%%% Simulate all leakages and get all scenarios pressures
leak_mag_desir=mean(mean(Dem0(Dem0>0)));
mean_pressure = mean(mean(P0(P0>0)));
leak_emit = leak_mag_desir/sqrt(mean_pressure);
emit0=d.getNodeEmitterCoeff;
S = zeros(nj,nj);
for leak=1:nj
    clc
    disp('Calculating Sensitivity Matrix...')
    disp(['Simulating leakage ',num2str(leak),' out of ',num2str(nj)])
    emit=zeros(size(emit0));
    emit(leak)=leak_emit; % set emitter coefficient (leakage) value
    d.setNodeEmitterCoeff(emit);
    allParameters=d.getComputedTimeSeries;
    P = allParameters.Pressure';
    P(d.getNodeReservoirIndex,:)=[];
    Dem = allParameters.Demand';
    leak_mag = Dem(leak,:)-Dem0(leak,:);
    Stmp=(P-P0)./(leak_mag);
    rmax = max(abs(Stmp),[],1);
    Stmp = abs(Stmp)./rmax;
    S(:,leak) = max(Stmp')'; % --> main difference in max-min Sensitivity!!!
end
save(['saved_sim\SensitivityMat_',dispname],'S')

case 1 % Load residual matrix
    load(['saved_sim\SensitivityMat_',dispname])
otherwise
    disp('Wrong option selected')
    return
end

%% Place sensors
sensors=7;
for i=sensors
% sensors=[6]; %sensor numbers to be checked
exist_sens_ind=[];%double(d.getNodeIndex({'R-1'}));
% exist_sens_ind=d.getNodeIndex({'14','63','114','399','572','302','662'});
% exist_sens_ind=d.getNodeIndex({'35','236','1023','289'}); % 131
% exist_sens_ind=d.getNodeIndex({'4','134','302','662','410'}); % 133

[res{i},fvalSenTr(i)] = SolveEnum2GA(S,nj,i,exist_sens_ind)
% [res,fvalSenTr] = SolveMultiObjGA(S,nj,sensors,exist_sens_ind)

% save(['saved_sim\tempResults_',dispname,datestr(now, '_yyyy-mm-dd_HH-MM-SS')])
end

%% Display solution
% [~,idx] = sort(fvalSenTr(:,1)); % sort just the first column
% sortedmat = fvalSenTr(idx,:);
% close all
% plot(1-sortedmat)
% legend('min Sen','mean Sen')
% grid on
% 
% keyboard
for i=sensors
    u=res{i};
    Sm = S(u>0,:);
    Smax = max(Sm);
    cost(1,i) = min(Smax);        
    cost(2,i) = mean(Smax);
end
plot(1:max(sensors),cost)
legend('min cost','mean cost')

for sol=sensors
u=res{sol};
sensors = length(find(u>0.1));
sens_ind = find(u>0.1);

%%% Plot sensors:
d.plot
legend('off')
coor=d.getNodeCoordinates;
x=coor{1}(sens_ind);y=coor{2}(sens_ind);
plot(x,y,'o','LineWidth',2,'MarkerEdgeColor','r','MarkerFaceColor','r','MarkerSize',14)
fontweight='bold';
fontsize=11;
for i=1:length(sens_ind)
text(x(i)-5,y(i),d.getNodeNameID{sens_ind(i)},'Color','black','FontWeight',fontweight,'Fontsize',fontsize)
end
title(['Sensors:',num2str(sensors)])
tightfig()

end

%% Save and unload
% save(['saved_sim\Results_',dispname,datestr(now, '_yyyy-mm-dd_HH-MM-SS')])
d.unload
% run Display_Results.m
