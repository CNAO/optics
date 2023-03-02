% {}~
% template analysis script

% %% include Matlab library
% pathToLibrary="..\..\..\MatLabTools";
% addpath(genpath(pathToLibrary));

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% parse .tfs summary table and plot stuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all;

whatScan="MUY";
eleScan="X3_011B_VWN";
iFileName=sprintf("../output/summary_%s_%s.tfs",eleScan,whatScan);
myTitle=sprintf("%s scan at %s - ISO3 (XPR) - Proton - 30mm",whatScan,LabelMe(eleScan));

summdaryData=readmatrix(iFileName,'HeaderLines',1,'Delimiter',',','FileType','text');

%% plot
% - preparatory stuff
nDataSets=7;
labels=LabelMe([
    "H2_012A_QUE" "H2_016A_QUE" "H2_022A_QUE" "HE_018A_QUE" "HE_020A_QUE" "HE_023A_QUE" "HE_025A_QUE"
    ]);
% - actually plot
figure();
cm=colormap(jet(length(labels)));
yyaxis left;
for ii=1:length(labels)
    if (ii>1), hold on; end
    plot(summdaryData(:,3),summdaryData(:,ii+3),".-","Color",cm(ii,:));
end
ylabel("I [A]");
yyaxis right;
plot(summdaryData(:,3),summdaryData(:,end-1),"k*-",summdaryData(:,3),summdaryData(:,end),"r*-");
ylabel("\phi [2\pi]");
yyaxis left;
title(myTitle);
legend([labels "MUX" "MUY"],"Location","best");
grid on; xlabel("ID []");
