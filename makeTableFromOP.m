% {}~

%% include Matlab library
pathToLibrary="..\MatLabTools";
addpath(genpath(pathToLibrary));

%% user settings
beamPart="PROTON"; % select beam particle: proton, carbon
machine="XPRX1"; % select machine: synchro, Line[T-Z]/Sala[3-1], XPRX[1-4]/ISO[1-4]; LEBT and MEBT to come 
config="TM"; % select configuration: TM, RFKO
source="LGEN"; % source: RampGen or LGEN
LGENsCheck=[]; % subset to check, otherwise all - eg [ "P6-006A-LGEN" "P6-007A-LGEN" "P6-008A-LGEN" "P6-009A-LGEN" ];
filters=["NaN" "0"]; % filter PSs where all CyCo show "NaN" or "0"
lCurrents=true; % advice: synchro=false, HEBT=true

%% main
switch upper(source)
    case "RAMPGEN"
        % MADX can already crunch the table contained in the table
        % used by RAMPGEN; hence, this script simply adjustes the
        % format of the table to that used by MADX
        switch upper(machine)
            case "SYNCHRO"
                switch beamPart
                    case "PROTON"
                        % protons - RM and RFKO are basically the same, LFalbo
                        rampFileName="P:\Accelerating-System\Accelerator-data\Area dati MD\00Rampe\MatlabRampGen2.8\INPUT\CSV-TRATTAMENTI\Protoni.csv"; 
                        RampGen2MADX(rampFileName,"synchro\RampGen\TM_Protons.tfs");
                    case "CARBON"
                        if ( strcmp(config,"RFKO") )
                            rampFileName="P:\Accelerating-System\Accelerator-data\Area dati MD\00Rampe\MatlabRampGen2.8\INPUT\CorrSest-MachinePhotoCarbRFKO.xlsx";
                            RampGen2MADX(rampFileName,"synchro\RampGen\CorrSest-MachinePhotoCarbRFKO.tfs","Foglio1");
                        else
                            rampFileName="P:\Accelerating-System\Accelerator-data\Area dati MD\00Rampe\MatlabRampGen2.8\INPUT\CSV-TRATTAMENTI\Carbonio.csv"; 
                            RampGen2MADX(rampFileName,"synchro\RampGen\TM_Carbon.tfs");
                        end
                    otherwise
                        error("no source of data available for %s %s %s %s",machine,source,beamPart,config);
                end % switch: RAMPGEN, SYNCHRO, beamPart
            otherwise
                error("no source of data available for %s %s %s %s",machine,source,beamPart,config);
        end % switch: machine
    case "LGEN"
        [cyCodes,ranges,Eks,Brhos,currents,fields,kicks,psNames,FileNameCurrents]=AcquireLGENValues(beamPart,machine,config,filters);
        if ( length(cyCodes)==0 )
            error("no data loaded!");
        else
            % save to MADX
            [filepath,tmpName,ext] = fileparts(FileNameCurrents);
            switch upper(machine)
                case "SYNCHRO"
                    MADXFileName=sprintf("synchro\\LGEN\\%s.tfs",tmpName);
                case {"LINEZ","SALA1","LINEV","SALA2V","LINEU","SALA2H","LINET","SALA3",...
                        "XPRX1","ISO1","XPRX2","ISO2","XPRX3","ISO3","XPRX4","ISO4"} 
                    MADXFileName=sprintf("HEBT\\LGEN\\%s.tfs",tmpName);
                otherwise
                    error("no source of data available for %s %s %s %s",machine,source,beamPart,config);
            end
            if ( lCurrents )
                save2MADXTable(ranges,Eks,Brhos,currents,psNames,MADXFileName,lCurrents);
            else
                save2MADXTable(ranges,Eks,Brhos,kicks,psNames,MADXFileName,lCurrents);
            end
        end
    otherwise
        error("no source of data available for %s %s %s %s",machine,source,beamPart,config);    
end
fprintf("...done.\n");

return

%% functions

function save2MADXTable(ranges,Eks,Brhos,myTable,psNames,MADXFileName,isCurrent)
    myTitle="myTable";
    % SAVE FILE FOR MADX
    nPSs=length(psNames);
    % prepare header
    headers=strings(1,nPSs+3);
    headers(1)="range_mm";
    headers(2)="Ek_MeVN";
    headers(3)="Brho_Tm";
    if ( isCurrent==1)
        headers(4:end)=psNames+"_A";
    else
        for jj=1:nPSs
            [pQ,unit,name]=LGENname2pQ(psNames{jj});
            [kickName,kickUnit]=DecodeKickName(name);
            headers(3+jj)=sprintf("%s_%s",string(psNames(jj)),kickName);
        end
    end
    % prepare header type
    headerTypes=strings(1,nPSs+3);
    headerTypes(:)="%le";
    % export MADX table
    bigTable=zeros(length(ranges),length(psNames)+3);
    bigTable(:,1)=ranges;
    bigTable(:,2)=Eks;
    bigTable(:,3)=Brhos;
    bigTable(:,4:end)=myTable(1:end,:);
    ExportMADXtable(MADXFileName,myTitle,bigTable,headers,headerTypes);
end
