%% Visualises/plots time series for node pressures, water velocity and water flow.
%% This example contains: 
%% 
% * Load a network. 
% * Hydraulic analysis using ENepanet binary file. 
% * Change time-stamps from seconds to hours. 
% * Plot node pressures for specific nodes. 
% * Plot water velocity for specific links. 
% * Plot water flow for specific links. 
% * Unload library.
%% Clear - Start Toolkit

clear; close('all'); clc;
addpath(genpath(pwd));
disp('Paths Loaded.');

%%  Load a network

inpname = '../data/Net1.inp'; % codeocean
tmpinp = 'nettmp.inp';
copyfile(inpname, tmpinp);
d = epanet(tmpinp);

%%  Hydraulic analysis using ENepanet binary file (This function ignore events)

hyd_res = d.getComputedTimeSeries;
%%  Change time-stamps from seconds to hours

hrs_time = hyd_res.Time/3600;
%%  Plot node pressures for specific nodes 

node_indices = [1, 3, 5];
node_names = d.getNodeNameID(node_indices);
for i=node_indices
    figure;
    h1 = plot(hrs_time, hyd_res.Pressure(:,i));
    titletext = ['Pressure for the node id ', d.getNodeNameID{i}];
    title(titletext);
    xlabel('Time (hrs)'); 
    ylabel(['Pressure (', d.NodePressureUnits,')'])
    
    saveas(h1, ['../results/', titletext, '.png']); % codeocean
end

%%  Plot water flow for specific links

link_indices2 = [2, 3, 9];
for i=link_indices2
    figure;
    h2 = plot(hrs_time, hyd_res.Flow(:,i));
    titletext = ['Flow for the link id ', d.getLinkNameID{i}];
    title(titletext);
    xlabel('Time (hrs)'); 
    ylabel(['Flow (', d.LinkFlowUnits,')'])
    saveas(h2, ['../results/', titletext, '.png']); % codeocean
end

%% Highlight multiple links and nodes with different colors 

linkSet2 = d.getLinkNameID(link_indices2);
colorLinkSet2=repmat({'g'},1,length(linkSet2));
h3 = d.plot('highlightlink',[linkSet2],'colorlink',[colorLinkSet2]);
saveas(h3, ['../results/', titletext, '.png']); % codeocean

nodeSet1 = d.getNodeNameID(node_indices);
colorLinkSet1 = repmat({'r'},1,length(nodeSet1));
h4 = d.plot('highlightnode', nodeSet1,'colornode', colorLinkSet1);
saveas(h4, ['../results/', titletext, '.png']); % codeocean

%% Export flows to excel file
T = array2table(hyd_res.Flow, 'VariableNames', d.getLinkNameID);
writetable(T, '../results/flows.xlsx');

%%  Unload library.

d.unload