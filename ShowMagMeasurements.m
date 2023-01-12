% {}~
% - include Matlab library
pathToLibrary="..\MatLabTools";
addpath(genpath(pathToLibrary));

%% user input
% - mag measurements
xlsFile="P:\Accelerating-System\Magnets\Magnetic Measurements\Frascati\HEBT\Misure\Quadrupoli\QHEBTSerie_Finale.xls";
xlsSheetName="IntegField";
xlsRange="A3:CF11";
magFamily="QHEBT";
Lmag=0.449; % [m]
Rcoil=32E-3; % [m]
% - mapping
xlsMappingFile="mappingInstallationSlots.xlsx";

%% parse files
% - magnetic measurements
[Is,Bs]=ParseMagMeasurements(xlsFile,xlsSheetName,xlsRange);
nMagnets=size(Bs,2);
magNames=compose("%s#%02i",magFamily,1:nMagnets);
%% - mapping
fprintf("parsing file %s ...\n",xlsMappingFile);
mapping=readtable(xlsMappingFile);
fprintf("...done.\n");

%% choose the magnets and fit the data
% myNames=[ "H2_012A_QUE" "H2_016A_QUE" "H2_022A_QUE" "H4_003A_QUE" "H4_007A_QUE" "H4_013A_QUE" ];
% myNames=[ "H5_005A_QUE" "H5_009A_QUE" "H5_015A_QUE" "V1_010A_QUE" "V1_014A_QUE" "V1_018A_QUE" "V1_022A_QUE" ];
% myNames=[ "T1_004A_QUE" "T1_013A_QUE" "T1_019A_QUE" "T2_005A_QUE" "T2_012A_QUE" "T2_018A_QUE" ];
% myNames=[ "U1_008A_QUE" "U1_014A_QUE" "U1_018A_QUE" "U2_006A_QUE" "U2_010A_QUE" "U2_016A_QUE" ];
myNames=[ "V1_037A_QUE" "V1_041A_QUE" "V1_047A_QUE" "V2_006A_QUE" "V2_010A_QUE" "V2_016A_QUE" ];
% myNames=[ "Z1_004A_QUE" "Z1_013A_QUE" "Z1_019A_QUE" "Z2_005A_QUE" "Z2_012A_QUE" "Z2_018A_QUE" ];
% myNames=[ "HE_018A_QUE" "HE_020A_QUE" "HE_023A_QUE" "HE_025A_QUE" ];
% myNames="Z1_019A_QUE";
% - parse mapping and get IDs of magnets
myChoice=Names2IDs(myNames,string(mapping.HEBT_QUE));

% - fit data (converted into T/m)
pp=missing();
%   linear fit:
pp=ExpandMat(pp,FitData(Is(:,myChoice),Bs(:,myChoice)./Rcoil,1)); % linear fit
pp=ExpandMat(pp,NaN(2,2));                                        % 2nd order polynomial fit
pp=ExpandMat(pp,NaN(2,2));                                        % 3rd order polynomial fit
pp=ExpandMat(pp,NaN(2,2));                                        % 4th order polynomial fit
pp=ExpandMat(pp,FitData(Is(:,myChoice),Bs(:,myChoice)./Rcoil,5)); % 5th order polynomial fit

% - Ref curves
ppRef=NaN(1,6,5);
%   linear fitting: K1(I)=0.03258/(0.45*biro) *I_MagName
iOrder=1; ppRef(1,1:iOrder+1,iOrder)=[ 0.03258/0.45 0.0 ];
iOrder=5; ppRef(1,1:iOrder+1,iOrder)=[ +1.3348656E-11 -1.1996845e-8 +3.498485e-6 -4.26890e-4 +9.32005e-2 -2.794551e-1 ];

% - show selected data (cross check)
ShowValues(Is(:,myChoice),Bs(:,myChoice),compose("%s - %s",[myNames' magNames(myChoice)'])',"B [T]",ppRef*Rcoil,pp*Rcoil);

%% show values and fits
ShowValues(Is(:,myChoice),Bs(:,myChoice)./Rcoil,compose("%s - %s",[myNames' magNames(myChoice)'])',"g [T/m]",ppRef,pp);

%% dump coefficients in file
% SaveFitsToMADX(pp,myNames,"fits_H2-H4.cmdx");
% SaveFitsToMADX(pp,myNames,"fits_H5-V1.cmdx");
% SaveFitsToMADX(pp,myNames,"fits_U1-U2.cmdx");
SaveFitsToMADX(pp,myNames,"fits_V1-V2.cmdx");
% SaveFitsToMADX(pp,myNames,"fits_T1-T2.cmdx");
% SaveFitsToMADX(pp,myNames,"fits_XPR.cmdx");
% SaveFitsToMADX(pp,myNames,"test.cmdx");

%% functions

function SaveFitsToMADX(pp,magNames,fileName)
    nMagnets=size(pp,1);
    nOrders=size(pp,3);
    fileID=fopen(fileName,"w");
    for ii=1:nMagnets
        for iOrder=1:nOrders
            if ( any(~isnan(pp(ii,1:iOrder+1,iOrder))) )
                fprintf(fileID,"! dedicated %s fit for magnet %s\n",MyOrderLeg(iOrder),magNames(ii));
                DumpCoeff(fileID,magNames(ii),pp(ii,1:iOrder+1,iOrder));
            end
        end
        fprintf(fileID,"\n");
    end
    fclose(fileID);
end

function [pp]=FitData(Is,Bs,iOrder)
    if (~exist("iOrder","var")), iOrder=1; end
    nMagnets=size(Bs,2);
    nData=size(Bs,1);
    if (iOrder==1)
        rangeFit=1:4;
    else
        rangeFit=1:nData;
    end
    pp=NaN(nMagnets,iOrder+1);
    for ii=1:nMagnets
        pp(ii,:)=polyfit(Is(rangeFit,ii),Bs(rangeFit,ii),iOrder);
    end
end

function myLeg=MyOrderLeg(iOrder)
    switch iOrder
        case 1
            myLeg="linear";
        case 2
            myLeg="2^{nd} order";
        case 3
            myLeg="3^{rd} order";
        otherwise
            myLeg=sprintf("%d^{th} order",iOrder);
    end
end

function DumpCoeff(fileID,magName,pp)
    switch length(pp)-1
        case 1
            myNam="LIN";
        case 5
            myNam="FIF";
        otherwise
            error("unknonw order!");
    end
    
    for jj=1:length(pp)
        fprintf(fileID,"a%d_%s_%s=% 22.16E;\n",jj-1,myNam,magName,pp(length(pp)-jj+1));
    end
end

function IDs=Names2IDs(names,mapList)
    nMagnets=length(names);
    IDs=NaN(nMagnets,1);
    for ii=1:nMagnets
        if ( endsWith(names(ii),"QUE",'IgnoreCase',true) )
            myID=find(strcmpi(mapList,names(ii)));
            if ( isempty(myID) )
                error("unable to identify MAGNET named %s!",names(ii));
            else
                IDs(ii)=myID;
            end
        else
            error("unable to identify LINE of magnet named %s!",names(ii));
        end
    end
end

function ShowValues(Is,Bs,magNames,yLab,ppRef,pp)
    if ( ~exist("yLab","var") ), yLab="g [T/m]"; end
    nMagnets=size(Bs,2);
    
    % actually plot
    figure();
    if ( exist("ppRef","var") )
        if ( exist("pp","var") )
            nMaxOrders=max(size(ppRef,3),size(pp,3));
        else
            nMaxOrders=size(ppRef,3);
        end
        cm=colormap(gcf,jet(nMaxOrders));
        % - reference curves (computed only once)
        Iref=linspace(min(Is,[],"all"),max(Is,[],"all"),100);
        yRefs=NaN(length(Iref),nMaxOrders);
        iLeg=0;
        for iOrder=1:nMaxOrders
            if ( any(~isnan(ppRef(1,1:iOrder+1,iOrder))) )
                yRefs(:,iOrder)=polyval(ppRef(1,1:iOrder+1,iOrder),Iref);
                iLeg=iLeg+1;
                myLeg(iLeg)=sprintf("ref (%s)",MyOrderLeg(iOrder));
            end
        end
        [nRows,nCols,lDispHor]=GetNrowsNcols(nMagnets*2,2); % display coupled plots
        % - plot
        iPlot=0;
        for ii=1:nMagnets
            
            % measured values of magnet
            Itmp=Is(:,ii); BsTmp=Bs(:,ii);
            
            % - absolute values
            iPlot=iPlot+1;
            subplot(nRows,nCols,iPlot);
            %   . measured values
            plot(Itmp,BsTmp,"k*");
            %   . ref curves
            for iOrder=1:nMaxOrders
                if ( any(~isnan(ppRef(1,1:iOrder+1,iOrder))) )
                    hold on; plot(Iref,yRefs(:,iOrder),":","Color",cm(iOrder,:));
                end
            end
            %   . fit curves
            if ( exist("pp","var") )
                yFits=NaN(length(Iref),nMaxOrders);
                for iOrder=1:nMaxOrders
                    if ( any(~isnan(pp(ii,1:iOrder+1,iOrder))) )
                        yFits(:,iOrder)=polyval(pp(ii,1:iOrder+1,iOrder),Iref);
                        hold on; plot(Iref,yFits(:,iOrder),"-","Color",cm(iOrder,:));
                        if (ii==1)
                            myLeg(end+1)=sprintf("fit (%s)",MyOrderLeg(iOrder));
                        end
                    end
                end
            end
            %   . general stuff
            grid(); xlabel("I [A]"); ylabel(yLab); legend(["data" myLeg],"Location","best");
            title(LabelMe(magNames(ii)));
            
            % - deltas
            iPlot=iPlot+1;
            subplot(nRows,nCols,iPlot);
            %   . measured values (to compute deltas)
            plot(NaN(),NaN(),"k*");
            %   . ref curves
            for iOrder=1:nMaxOrders
                if ( any(~isnan(ppRef(1,1:iOrder+1,iOrder))) )
                    hold on; plot(Itmp,(polyval(ppRef(1,1:iOrder+1,iOrder),Itmp)./BsTmp-1)*100,".:","Color",cm(iOrder,:));
                end
            end
            %   . fit curves
            if ( exist("pp","var") )
                for iOrder=1:nMaxOrders
                    if ( any(~isnan(pp(ii,1:iOrder+1,iOrder))) )
                        hold on; plot(Itmp,(polyval(pp(ii,1:iOrder+1,iOrder),Itmp)./BsTmp-1)*100,".-","Color",cm(iOrder,:));
                    end
                end
            end
            %   . general stuff
            grid(); xlabel("I [A]"); ylabel("\Delta [%]"); legend(["" myLeg],"Location","best");
            title(LabelMe(magNames(ii)));
            % ylim([-2 2]);
       end
    else
        % simply show data
        cm=colormap(gcf,jet(nMagnets));
        for ii=1:nMagnets
            if (ii>1), hold on; end
            plot(Is(:,ii),Bs(:,ii),"*","Color",cm(ii,:));
        end
        grid(); xlabel("I [A]"); ylabel(yLab); legend(LabelMe(magNames),"Location","best");
    end
    
end

function [Is,Bs]=ParseMagMeasurements(xlsFile,xlsSheetName,xlsRange)
    fprintf("parsing file %s, sheet name %s, range %s ...\n",xlsFile,xlsSheetName,xlsRange);
    
    myTab=readmatrix(xlsFile,"Sheet",xlsSheetName,"Range",xlsRange);
    nVals=size(myTab,1);
    nMagnets=size(myTab,2)/2;
    
    fprintf("...storing data...\n");
    Is=NaN(nVals,nMagnets); Bs=NaN(nVals,nMagnets);
    for ii=1:nMagnets
        Is(:,ii)=myTab(:,2*(ii-1)+1);
        Bs(:,ii)=myTab(:,2*ii);
    end
    fprintf("...acquired data for %d magnets with %d current values;\n",nMagnets,nVals);
    
    Is(ismissing(Is))=NaN();
    Bs(ismissing(Bs))=NaN();
end
