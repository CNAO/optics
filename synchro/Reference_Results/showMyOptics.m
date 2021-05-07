% {}~

% template analysis script
% - include Matlab library
pathToLibrary="..\..\..\MatLabTools";
addpath(genpath(pathToLibrary));
opticsFileName="..\bumped_with_crystal\extraction_carbon_270mm_optics.tfs";
geometryFileName="..\bumped_with_crystal\extraction_carbon_270mm_geometry.tfs";
myTitle="TM - Carbon - 270 mm - bump at crystals and channelled beam";
emig=1.0E-06; % [m rad]
sigdpp=0.0; % []

% acquire data
optics = ParseTfsTable(opticsFileName,'optics');
[Qx,Qy,Chrx,Chry,Laccel,headerNames,headerValues] = ...
    ParseTfsTableHeader(opticsFileName);
geometry = ParseTfsTable(geometryFileName,'geometry');

% show the optics
ShowOptics(optics,geometry,myTitle,Laccel,Qx,Qy,Chrx,Chry);

% show beam envelop
ShowEnvelopAperture(optics,geometry,myTitle,Laccel,Qx,Qy,Chrx,Chry,emig,sigdpp);

% %
% f1=figure('Name','phase advance','NumberTitle','off');
% % - geometry
% ax1=subplot(2,1,1);
% PlotLattice(geometry);
% % - hor phase advance
% ax2=subplot(2,1,2);
% PlotOptics(optics,"MUX");
% grid on;
% linkaxes([ax1 ax2],'x');
% 
% %
% f1=figure('Name','sigmas','NumberTitle','off');
% % - geometry
% ax1=subplot(3,1,1);
% PlotLattice(geometry);
% xlim([0 Laccel]);
% % - hor sigma
% ax2=subplot(3,1,2);
% PlotOptics(optics,"SIGX",emig,sigdpp);
% grid on;
% % - ver sigma
% ax3=subplot(3,1,3);
% PlotOptics(optics,"SIGPX",emig,sigdpp);
% grid on;
% %
% linkaxes([ax1 ax2 ax3],'x');
