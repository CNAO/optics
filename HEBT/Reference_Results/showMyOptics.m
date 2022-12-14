% {}~
% template analysis script

%% include Matlab library
pathToLibrary="..\..\..\MatLabTools";
addpath(genpath(pathToLibrary));

%% files
% % original optics
% opticsFileName="..\lineu_example_optics.tfs";
% geometryFileName="..\lineu_example_geometry.tfs";
% rMatrixFileName="..\lineu_example_rmatrix.tfs";
% optics of short line
opticsFileName="..\example_short_optics.tfs";
geometryFileName="..\example_short_geometry.tfs";
rMatrixFileName="..\example_short_rmatrix.tfs";

%% acquire data
optics = ParseTfsTable(opticsFileName,'optics');
[Qx,Qy,Chrx,Chry,Laccel,headerNames,headerValues] = ...
    ParseTfsTableHeader(opticsFileName);
geometry = ParseTfsTable(geometryFileName,'geometry');
rMatrix = ParseTfsTable(rMatrixFileName,'rMatrix');

%% show the optics
myTitle="Line U (sala 2H) - Carbon - 270mm";
ShowOptics(optics,geometry,myTitle,Laccel,Qx,Qy,Chrx,Chry);
ShowRmatrix(rMatrix,geometry,myTitle);
