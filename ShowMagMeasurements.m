% {}~
% - include Matlab library
pathToLibrary="..\MatLabTools";
addpath(genpath(pathToLibrary));

%% user input
xlsFile="S:\Accelerating-System\Magnets\Magnetic Measurements\Frascati\HEBT\Misure\Quadrupoli\QHEBTSerie_Finale.xls";
xlsSheetName="IntegField";
xlsRange="A3:CF11";
magFamily="QHEBT";
Lmag=0.449; % [m]
Rcoil=32E-3; % [m]

%% parse file
[Is,Bs]=ParseMagMeasurements(xlsFile,xlsSheetName,xlsRange);
Bs=Bs/Rcoil;
nMagnets=size(Bs,2);
magNames=compose("%s#%02i",magFamily,1:nMagnets);

%% plot all
myNames=[ "U1_008A_QUE" "U1_014A_QUE" "U1_018A_QUE" "U2_006A_QUE" "U2_010A_QUE" "U2_016A_QUE" ];
% myNames="U1_008A_QUE";
myChoice=find(Names2IDs(myNames));
ShowValues(Is(:,myChoice),Bs(:,myChoice),compose("%s - %s",[myNames' magNames(myChoice)'])',"g [T/m]",true);

%% dump coefficients in file
SaveFitsToMADX(Is(:,myChoice),Bs(:,myChoice),myNames,"test.cmdx");

%% functions

function SaveFitsToMADX(Is,Bs,magNames,fileName)
    nMagnets=size(Bs,2);
    linFitRange=1:4;
    fileID=fopen(fileName,"w");
    for ii=1:nMagnets
        % linear fit
        pLin = polyfit(Is(linFitRange,ii),Bs(linFitRange,ii),1);
        fprintf(fileID,"! dedicated linear fit for %s\n",magNames(ii));
        DumpCoeff(fileID,magNames(ii),pLin);
        % fifth order fit
        pFif = polyfit(Is(:,ii),Bs(:,ii),5);
        fprintf(fileID,"! dedicated 5th order polynomial fit for %s\n",magNames(ii));
        DumpCoeff(fileID,magNames(ii),pFif);
        % 
        fprintf(fileID,"\n");
    end
    fclose(fileID);
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
        fprintf(fileID,"a%d_%s_%s=% 12.6E;\n",jj-1,myNam,magName,pp(length(pp)-jj+1));
    end
end

function IDs=Names2IDs(names)
    %% acquiring maps
    HEBT_QUEs=ParseMapping();
    %% actually getting IDs
    nMagnets=length(names);
    IDs=NaN(nMagnets,1);
    for ii=1:nMagnets
        if ( endsWith(names(ii),"QUE",'IgnoreCase',true) )
            myID=find(strcmpi(HEBT_QUEs,names(ii)));
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

function ShowValues(Is,Bs,magNames,yLab,lFit)
    if ( ~exist("yLab","var") ), yLab="g [T/m]"; end
    if ( ~exist("lFit","var") ), lFit=false; end
    nMagnets=size(Bs,2);
    if ( lFit )
        for ii=1:nMagnets
            ShowValuesActual(Is(:,ii),Bs(:,ii),magNames(ii),yLab,lFit);
        end
    else
        ShowValuesActual(Is,Bs,magNames,yLab,lFit);
    end
end

function ShowValuesActual(Is,Bs,magNames,yLab,lFit)
    nMagnets=size(Bs,2);
    figure();
    if ( nMagnets>1 )
        cm=colormap(parula(nMagnets));
        if (lFit), error("...only one magnet, if you want to fit!"); end
    else
        cm=[ 0 0 0 ]; % black
    end
    linFitRange=1:4;
    
    %% reference functions
    % - K1(I)=0.03258/(0.45*biro) *I_MagName
    Glin=@(x) 0.03258/0.45*x;
    Gfifth=@(x) -2.794551e-1         ...
                +9.32005e-2   *x     ...
                -4.26890e-4   *x.^2  ...
                +3.498485e-6  *x.^3  ...
                -1.1996845e-8 *x.^4  ...
                +1.3348656E-11*x.^5;

    %% show data
    for ii=1:nMagnets
        if (ii>1), hold on; end
        plot(Is(:,ii),Bs(:,ii),"*","Color",cm(ii,:));
    end
    % reference curves:
    Iref=linspace(min(Is,[],"all"),max(Is,[],"all"),100);
    hold on; plot(Iref,Glin(Iref),"r-",Iref,Gfifth(Iref),"b-");
    myLeg=[LabelMe(magNames) "ref (lin)" "ref (5^{th} order)"];
    % dedicated fits
    if ( lFit )
        for ii=1:nMagnets
            % linear fit
            pLin = polyfit(Is(linFitRange,ii),Bs(linFitRange,ii),1);
            yLin = polyval(pLin,Iref);
            % fifth order fit
            pFif = polyfit(Is(:,ii),Bs(:,ii),5);
            yFif = polyval(pFif,Iref);
            % show plots
            hold on; plot(Iref,yLin,"m-",Iref,yFif,"c-");
            myLeg=[myLeg "fit (lin)" "fit (5^{th} order)"];
        end
    end
    % general stuff
    grid(); xlabel("I [A]"); ylabel(yLab); legend(myLeg,"Location","best");

    %% show errors from fits
    if ( lFit )
        for ii=1:nMagnets
            figure();
            % reference fits
            plot(Is(linFitRange,ii),(Glin(Is(linFitRange,ii))./Bs(linFitRange,ii)-1)*100,"r.-");
            hold on;
            plot(Is(:,ii),(Gfifth(Is(:,ii))./Bs(:,ii)-1)*100,"b.-");
            % linear fit
            pLin = polyfit(Is(linFitRange,ii),Bs(linFitRange,ii),1);
            yLin = polyval(pLin,Is(linFitRange,ii));
            % fifth order fit
            pFif = polyfit(Is(:,ii),Bs(:,ii),5);
            yFif = polyval(pFif,Is(:,ii));
            % show plots
            plot(Is(linFitRange,ii),(yLin./Bs(linFitRange,ii)-1)*100,"m.-");
            hold on;
            plot(Is(:,ii),(yFif./Bs(:,ii)-1)*100,"c.-");
            myLeg=["ref (lin)" "ref (5^{th} order)" "fit (lin)" "fit (5^{th} order)"];
            % general stuff
            grid(); xlabel("I [A]"); ylabel("\Delta [%]"); legend(myLeg,"Location","best");
            title(LabelMe(magNames(ii)));
        end
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

function HEBT_QUEs=ParseMapping(xlsFile)
    if ( ~exist("xlsFile","var") ), xlsFile="mappingInstallationSlots.xlsx"; end
    fprintf("parsing file %s ...\n",xlsFile);
    myTab=readcell(xlsFile);
    
    fprintf("...assigning parsed data...\n");
    myHeads=string(myTab(1,:));
    for iCol=1:length(myHeads)
        switch upper(myHeads(iCol))
            case "HEBT_QUE"
                HEBT_QUEs=string(myTab(2:end,iCol));
                HEBT_QUEs=HEBT_QUEs(~ismissing(HEBT_QUEs));
        end
    end
    
    fprintf("...done.\n");
end