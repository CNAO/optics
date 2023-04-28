% {}~
% template analysis script

% %% include Matlab library
% pathToLibrary="..\..\MatLabTools";
% addpath(genpath(pathToLibrary));
% 
% %%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % show single optics files
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% %% files
% opticsFileName="../xpr_iso3_lgen_optics.tfs";
% geometryFileName="../xpr_iso3_lgen_geometry.tfs";
% rMatrixFileName="../xpr_iso3_lgen_rmatrix.tfs";
% 
% %% acquire data
% optics = ParseTfsTable(opticsFileName,'optics');
% [Qx,Qy,Chrx,Chry,Laccel,headerNames,headerValues] = ...
%     ParseTfsTableHeader(opticsFileName);
% geometries = ParseTfsTable(geometryFileName,'geometry');
% rMatrix = ParseTfsTable(rMatrixFileName,'rMatrix');
% 
% %% show the optics
% myTitle="ISO3 (XPR) - Proton - 30mm";
% ShowOptics(optics,geometries,myTitle,Laccel,Qx,Qy,Chrx,Chry);
% ShowRmatrix(rMatrix,geometries,myTitle);
% 
% %%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % compare different optics files (in principle also different geometries)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% %% files
% labels=[
%     "reference"
%     "new"
%     ];
% myTitle="ISO3 (XPR) - Proton - 30mm";
% opticsFileNames=[ ...
%     "../xpr_iso3_lgen_optics.tfs" ...
%     "../xpr_iso3_mod_lgen_optics.tfs" ...
%     ];
% geometryFileNames=[ ...
%     "../xpr_iso3_lgen_geometry.tfs" ...
%     "../xpr_iso3_mod_lgen_geometry.tfs" ...
%     ];
% 
% %% acquire data
% optics = ParseTfsTable(opticsFileNames,'optics');
% [Qx,Qy,Chrx,Chry,Laccel,headerNames,headerValues] = ...
%     ParseTfsTableHeader(opticsFileNames);
% geometries = ParseTfsTable(geometryFileNames,'geometry');
% 
% %% show the optics
% % CompareOptics(optics,labels,geometries,"CO",myTitle);
% CompareOptics(optics,labels,geometries,"BET",myTitle);
% % CompareOptics(optics,labels,geometries,"D",myTitle);

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compare different optics obtained via a scan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% clear all;

%% user settings
whatScan="MUX";
eleScan="X3_011B_VWN";
beam="P030";
opticsFileNames=[ ...
    "../output/xpr_iso3_lgen_optics.tfs" ...
    ];
geometryFileNames=[ ...
    "../output/xpr_iso3_lgen_geometry.tfs" ...
    ];

myTitle=sprintf("%s scan at %s - ISO3 (XPR) - %s",whatScan,LabelMe(eleScan),beam);
splitFiles=[sprintf("../output/xpr_iso3_Scan%s_%s_lgen_optics.tfs",whatScan,eleScan)];

%% split files
clear oFid;
for ii=1:length(splitFiles)
    fprintf("splitting file %s ...\n",splitFiles(ii));
    iFid = fopen(splitFiles(ii),"r");
    jj=0;
    while ~feof(iFid)
        tline = fgetl(iFid);
        if (startsWith(tline,"@ NAME"))
            jj=jj+1;
            if (exist("oFid","var"))
                fclose(oFid);
            end
            oFileName=strrep(splitFiles(ii),whatScan,sprintf("%s%03i",whatScan,jj));
            opticsFileNames=[opticsFileNames oFileName];
            fprintf("...saving data to file %s ...\n",oFileName);
            oFid=fopen(oFileName,"w");
        end
        fprintf(oFid,"%s\n",tline);
    end
    fclose(oFid);
end
% fclose(iFid);
fclose('all');

%% acquire data
optics = ParseTfsTable(opticsFileNames,'optics');
[Qx,Qy,Chrx,Chry,Laccel,headerNames,headerValues] = ...
    ParseTfsTableHeader(opticsFileNames);
geometries = ParseTfsTable(geometryFileNames,'geometry');

% build labels
labels=strings(length(opticsFileNames),1);
% - column mapping
[ colNames, colUnits, colFacts, mapping, readFormat ] = GetColumnsAndMappingTFS('optics');
idCol=mapping(find(strcmp(colNames,whatScan)));
% idColX=mapping(find(strcmp(colNames,"MUX")));
% idColY=mapping(find(strcmp(colNames,"MUY")));
for ii=1:length(opticsFileNames)
    idEle=find(contains(string(optics{ii,mapping(find(strcmp(colNames,"NAME")))}),eleScan));
    if (ii==1)
        labels(ii)=sprintf("%s=%g (ref)",whatScan,optics{ii,idCol}(idEle)*360);
    else
        labels(ii)=sprintf("%s=%g",whatScan,optics{ii,idCol}(idEle)*360);
    end
end

%% show the optics
if (strcmpi(whatScan,"MUX"))
    [~,sortedIDs]=sort(Qx); % sort by MUX value
else
    [~,sortedIDs]=sort(Qy); % sort by MUY value
end
% CompareOptics(optics(sortedIDs,:),labels(sortedIDs),geometries,"CO",myTitle);
CompareOptics(optics(sortedIDs,:),labels(sortedIDs),geometries,"BET",myTitle);
% CompareOptics(optics(sortedIDs,:),labels(sortedIDs),geometries,"D",myTitle);
