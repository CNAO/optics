% {}~
% template analysis script

%% include Matlab library
pathToLibrary="..\..\..\MatLabTools";
addpath(genpath(pathToLibrary));

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% show single optics files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% files
opticsFileName="../linez_lgen_optics.tfs";
geometryFileName="../linez_lgen_geometry.tfs";
rMatrixFileName="../linez_lgen_rmatrix.tfs";

%% acquire data
optics = ParseTfsTable(opticsFileName,'optics');
[Qx,Qy,Chrx,Chry,Laccel,headerNames,headerValues] = ...
    ParseTfsTableHeader(opticsFileName);
geometries = ParseTfsTable(geometryFileName,'geometry');
rMatrix = ParseTfsTable(rMatrixFileName,'rMatrix');

%% show the optics
myTitle="Line Z (sala 1) - Carbon - 30mm";
ShowOptics(optics,geometries,myTitle,Laccel,Qx,Qy,Chrx,Chry);
ShowRmatrix(rMatrix,geometries,myTitle);

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compare different optics files (in principle also different geometries)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% files
labels=[
    "reference"
    "new"
    ];
myTitle="Line T (sala s) - Carbon - 30mm";
opticsFileNames=[ ...
    "linet_lgen_optics.tfs" ...
    "../linet_lgen_optics.tfs" ...
    ];
geometryFileNames=[ ...
    "linet_lgen_geometry.tfs" ...
    "../linet_lgen_geometry.tfs" ...
    ];

%% acquire data
optics = ParseTfsTable(opticsFileNames,'optics');
[Qx,Qy,Chrx,Chry,Laccel,headerNames,headerValues] = ...
    ParseTfsTableHeader(opticsFileNames);
geometries = ParseTfsTable(geometryFileNames,'geometry');

%% show the optics
CompareOptics(optics,labels,geometries,"CO",myTitle);
CompareOptics(optics,labels,geometries,"BET",myTitle);
CompareOptics(optics,labels,geometries,"D",myTitle);
