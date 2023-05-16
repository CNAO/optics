% {}~
% template analysis script

% %% include Matlab library
% pathToLibrary="../../../MatLabTools";
% addpath(genpath(pathToLibrary));

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% parse .tfs summary table and plot stuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% clear all;

whatScan="MUX";
otherMu="MUY";
eleScan="X3_011B_VWN";
beam="P320";
dmu=10; % [degs]
i0=1; % take i0-th matched point with same phase advance as nominal as reference value
% outputFolder="../output_p030_MUX_free_10p0degs";
outputFolder="../output";
iFileNameCurrentSummary=sprintf("%s/summary_currents.tfs",outputFolder);
iFileNameOpticsSummary=sprintf("%s/%s_summary_optics.tfs",outputFolder,lower(eleScan));
iFileNameRepOpticsSummary=sprintf("%s/rep_summary_optics.tfs",outputFolder);
myTitle=sprintf("%s scan at %s - ISO3 (XPR) - %s",whatScan,LabelMe(eleScan),beam);

% acquire currents
[summaryData,summaryHead,MagNames,iMagNames]=ParseTfsTableCurrent(iFileNameCurrentSummary);
% acquire optics
scannedOptics=ParseTfsTable(iFileNameOpticsSummary,'optics',"SCAN");
[ colNames, colUnits, colFacts, mapping, readFormat ] = ...
        GetColumnsAndMappingTFS("optics","SCAN");
iID=mapping(find(strcmp(colNames,'ID')));
iMU=mapping(find(strcmp(colNames,whatScan)));
iMUX=mapping(find(strcmp(colNames,"MUX")));
iMUY=mapping(find(strcmp(colNames,"MUY")));
ioMU=mapping(find(strcmp(colNames,otherMu)));
zeroPos=find([scannedOptics{:,iID}' 0]==0);
sortedIDs=NaN(size(summaryData,1),1); iLast=0;
for ii=1:length(zeroPos)-1
    myRange=zeroPos(ii):zeroPos(ii+1)-1;
    [~,mySortedIDs]=sort(scannedOptics{iMU}(myRange)); % sort by phase advance
    nPoints=length(mySortedIDs);
    sortedIDs(1+iLast:nPoints+iLast)=mySortedIDs+iLast;
    iLast=iLast+nPoints;
end
nPoints=length(sortedIDs);
% selMagnets=MagNames;
allMagnets=[
    "H2_012A_QUE"
    "H2_016A_QUE"
    "H2_022A_QUE"
    "HE_018A_QUE"
    "HE_020A_QUE"
    "HE_023A_QUE"
    "HE_025A_QUE"
    ];
allLGENs=[
    "P7-008A-LGEN"
    "P7-009A-LGEN"
    "P7-010A-LGEN"
    "PX-001A-LGEN"
    "PX-002A-LGEN"
    "PX-003A-LGEN"
    "PX-004A-LGEN"
    ];
[selMagnets,ia,ib]=intersect(allMagnets,MagNames);
nDataSets=length(selMagnets);

%% plot
% - preparatory stuff
labels=LabelMe(selMagnets);
% - actually plot
figure();
cm=colormap(jet(nDataSets));
yyaxis left;
lFirst=true;
for ii=1:length(labels)
    if (~lFirst), hold on; end
    plot(1:nPoints,summaryData(sortedIDs,iMagNames(ib(ii))),".-","Color",cm(ii,:));
    if (lFirst), lFirst=false; end
end
ylabel("I [A]");
yyaxis right;
plot(1:nPoints,scannedOptics{iMUX}(sortedIDs)*360,"k*-",1:nPoints,scannedOptics{iMUY}(sortedIDs)*360,"r*-");
ylabel("\phi [degs]");
yyaxis left;
title(myTitle);
legend([labels' "MUX" "MUY"],"Location","best");
grid on; xlabel("ID []");

%%
return;

%% create QA file 
[~,iQAsorted]=sort(scannedOptics{iMU}); 
mu0=scannedOptics{iMU}(zeroPos(1)); % nominal phase advance
iMU0s_QA=find(mu0-dmu/(360*2)<scannedOptics{iMU}(iQAsorted) & scannedOptics{iMU}(iQAsorted)<mu0+dmu/(360*2));
if (length(iMU0s_QA)>1)
    % erase elements from iQAsorted
    iQAsorted(iMU0s_QA(2:end))=[];
end
if (i0==0)
    % currents at nominal phase advance are those from TM
    iQAsorted(iMU0s_QA(1))=zeroPos(1);
else
    % currents at nominal phase advance are those from i0
    iMU0s=find(mu0-dmu/(360*2)<scannedOptics{iMU} & scannedOptics{iMU}<mu0+dmu/(360*2) & scannedOptics{iID}~=0);
    iQAsorted(iMU0s_QA(1))=iMU0s(i0);
end
nPointsQA=length(iQAsorted);
MyData=NaN(nDataSets+1,3*nPointsQA);
iCol=0; iWritten=0; lWash=false;
for ii=1:nPointsQA
    % skip repetitions
    if (ii>1)
        if (all(abs(summaryData(iQAsorted(ii),iMagNames(ib))')==abs(summaryData(iQAsorted(ii-1),iMagNames(ib))')))
            continue;
        elseif (scannedOptics{iMU}(iQAsorted(ii))*360<=MyData(end,iWritten))
            continue;
        end
    end
    if (iWritten>0)
        % check if washing is needed
        lWash=any(abs(summaryData(iQAsorted(ii),iMagNames(ib))')<abs(MyData(1:nDataSets,iWritten)));
    end
    if (lWash)
        iCol=iCol+1; MyData(1:nDataSets,iCol)=350.0;
        iCol=iCol+1; MyData(1:nDataSets,iCol)=0.0;
    end
    iCol=iCol+1; MyData(1:nDataSets,iCol)=abs(summaryData(iQAsorted(ii),iMagNames(ib))');
    MyData(nDataSets+1,iCol)=scannedOptics{iMU}(iQAsorted(ii))*360;
    iWritten=iCol;
end
% wash at the end anyway
iCol=iCol+1; MyData(1:nDataSets,iCol)=350.0;
iCol=iCol+1; MyData(1:nDataSets,iCol)=0.0;
% remove useless NaNs
MyData(:,iCol+1:end)=[];
% write scan
CC=cell(size(MyData,1)+1,size(MyData,2)+2);
CC(1,2)=cellstr("Property"); CC(2:end,2)=cellstr("CCV"); 
CC(2:end,1)=cellstr([allLGENs(ia)' "PHASE"]);
CC(2:end,3:end)=num2cell(MyData);
CC(1,3:end)=num2cell(1:size(MyData,2));
writecell(CC,sprintf("../output/QAcurrents%sscan.xlsx",whatScan));

%% create .tfs for simulating back tunes
headers=compose("%s_A",allLGENs(ia));
headerTypes=strings(1,length(headers));
headerTypes(:)="%le";
FileName="../output/applied_currents.tfs";
myTitle=sprintf("%s,%s,%s",eleScan,whatScan,beam);
myTable=abs(summaryData(:,iMagNames(ib)));
ExportMADXtable(FileName,myTitle,myTable,headers,headerTypes);

%% compare matched and reproduced optics
% - acquired reproduced optics
repOptics=ParseTfsTable(iFileNameRepOpticsSummary,'optics',"SCAN");
% - actually plot
figure();
subplot(2,1,1);
iCol=mapping(find(strcmp(colNames,'BETX')));
plot(1:nPoints,scannedOptics{iCol},"ro-",1:nPoints,repOptics{iCol},"m*-");
hold on;
iCol=mapping(find(strcmp(colNames,'BETY')));
plot(1:nPoints,scannedOptics{iCol},"bo-",1:nPoints,repOptics{iCol},"c*-");
ylabel("\beta [m]"); grid on; xlabel("ID []");
legend(["\beta_x matched" "\beta_x rep" "\beta_y matched" "\beta_y rep"]);
subplot(2,1,2);
iCol=mapping(find(strcmp(colNames,'MUX')));
plot(1:nPoints,scannedOptics{iCol}*360,"ro-",1:nPoints,repOptics{iCol}*360,"m*-");
hold on;
iCol=mapping(find(strcmp(colNames,'MUY')));
plot(1:nPoints,scannedOptics{iCol}*360,"bo-",1:nPoints,repOptics{iCol}*360,"c*-");
ylabel("\mu [m]"); grid on; xlabel("ID []");
legend(["\mu_x matched" "\mu_x rep" "\mu_y matched" "\mu_y rep"]);
