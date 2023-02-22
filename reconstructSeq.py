# -*- coding: utf-8 -*-
"""
Created on Thu Feb  9 10:54:44 2023

@author: Alessio.Mereghetti
"""

import sys
# List of MADX keywords of elements that are used to compute relative distances
cumTypes_magLayOut=["SBEND","QUADRUPOLE","SEXTUPOLE","KICKER","HKICKER","VKICKER","RFCAVITY"]
# List of MADX keywords of elements that should appear in output sequence
wrtTypes_magLayOut=["SBEND","QUADRUPOLE","SEXTUPOLE","KICKER","HKICKER","VKICKER","MONITOR","HMONITOR","VMONITOR","MARKER","RFCAVITY"]

class MyElement():
    def __init__(self):
        self.Name=None
        self.Type=None
        self.Len="0.0"
    @staticmethod
    def FromEleDeclaration(tmpLine):
        '''
        Parses a single ASCII line of an element declaration file and extract the essential info
        
        Parameters
        ----------
        tmpLine : string
            Element declaration to be crunched, e.g.:
                S0_001A_MBS: SBEND, L=LMB,  ANGLE = ANGLEMB, E1 = EsMB, E2 = EsMB, K0 := K0MB, K1 = 0, K2 = 0,  Fint=0.50, HGAP = 0.036;

        Returns
        -------
        new : MyElement instance
            Instance of the parsed element with the essential info.

        '''
        new=MyElement()
        new.Name=(tmpLine.split(":")[0]).strip()
        new.Type=(((tmpLine.split(":")[1]).split(";")[0]).split(",")[0]).strip()
        if (new.Type!="MARKER"):
            eleDef=(tmpLine[tmpLine.find(":"):tmpLine.find(";")]).strip()
            myLength=None
            for myField in eleDef.split(","):
                if ((myField.strip()).startswith("L")):
                    myLength=((myField.strip()).split("=")[1]).strip()
                    break
            if (myLength is None):
                sys.exit("Unable to get length of element: %s"%(tmpLine.strip()))
            new.Len=myLength
        return new
    @staticmethod
    def FromTFSTable(tmpLine,iColName=0,iColType=1,iColL=2):
        new=MyElement()
        new.Name=((tmpLine.split()[iColName]).strip()).strip('"')
        new.Type=((tmpLine.split()[iColType]).strip()).strip('"')
        new.Len=(tmpLine.split()[iColL]).strip()
        return new

def ParseTFS_synchro(iFileName,myDiscardNames=["_APE","_EN","_EX","_UP"]):
    '''
    Parses a MADX TFS file and extracts the list of elements.
    The function is taylored for the synchro, and the crunched element list MUST start with an MBS!

    Parameters
    ----------
    iFileName : string
        File name with fullpath.

    Returns
    -------
    EleList : list of MyElement
        List of elements contained in the file.

    '''
    EleList=[]
    try:
        iFile=open(iFileName,"r")
    except:
        sys.exit("unable to find file named:",iFileName)
    print("getting element list from file %s ..."%(iFileName))
    iCols={"NAME":-1,"KEYWORD":-1,"L":-1}
    lParse=False
    for line in iFile.readlines():
        tmpLine=(line.strip()).upper()
        if ( tmpLine.startswith("@") or tmpLine.startswith("$") ):
            continue
        elif ( tmpLine.startswith("*") ):
            # acquire header
            for id,myField in enumerate(tmpLine.split()):
                for myColName in iCols.keys():
                    if ( myField.strip()==myColName ):
                        iCols[myColName]=id-1
            # check necessary columns are there
            for myColName,myId in iCols.items():
                if (myId==-1):
                    sys.exit("unable to find column %s in TFS file!"%(myColName))
        else:
            # active line
            if ( "_001A_MBS" in tmpLine and "_001A_MBS_" not in tmpLine ):
                lParse=True
            if (lParse):
                tmpEl=MyElement.FromTFSTable(tmpLine,iColName=iCols["NAME"],iColType=iCols["KEYWORD"],iColL=iCols["L"])
                # discard aperture markers
                lFound=False
                for myDiscardName in myDiscardNames:
                    if ( myDiscardName in tmpEl.Name ):
                        lFound=True
                        break
                if ( not lFound ):
                    EleList.append(tmpEl)
    iFile.close()
    print("...aquired",len(EleList),"elements;")
    return EleList

def ParseEleDeclaration_synchro(iFileName):
    '''
    Parses a MADX file with the element declaration and extracts the list of elements.
    The function is taylored for the synchro, and the crunched element list MUST start with an MBS!

    Parameters
    ----------
    iFileName : string
        File name with fullpath.

    Returns
    -------
    EleList : list of MyElement
        List of elements contained in the file.

    '''
    EleList=[]
    try:
        iFile=open(iFileName,"r")
    except:
        sys.exit("unable to find file named:",iFileName)
    print("getting element list from file %s ..."%(iFileName))
    lParse=False
    for line in iFile.readlines():
        tmpLine=(line.strip()).upper()
        if ( "_001A_MBS" in tmpLine ):
            lParse=True
        if (lParse):
            if ( len(tmpLine)>0 and not tmpLine.startswith("!")):
                # active line
                EleList.append(MyElement.FromEleDeclaration(tmpLine))
    iFile.close()
    print("...aquired",len(EleList),"elements;")
    return EleList

def WriteHeader(oFile):
    oFile.write(
'''
! DEFINISCO LA SEQUENZA DEGLI ELEMENTI DEL SINCROTRONE

SYNCHRO_L=(5964.2/2+1674.2+3424.2+2374.2+4624.2/2)/1000*4+16*(LMB_MagLayout+ds_corr);
! SYNCHRO_L= 77.64808033;
! value, SYNCHRO_L;
! stop;
SL0=(5.9642-2*dd_corr)*0+(1.6742-2*dd_corr)*0+(3.4242-2*dd_corr)*0+(2.3742-2*dd_corr)*0+(4.6242-2*dd_corr)*0;
SL1=(5.9642-2*dd_corr)*1+(1.6742-2*dd_corr)*0+(3.4242-2*dd_corr)*0+(2.3742-2*dd_corr)*0+(4.6242-2*dd_corr)*0;
SL2=(5.9642-2*dd_corr)*1+(1.6742-2*dd_corr)*1+(3.4242-2*dd_corr)*0+(2.3742-2*dd_corr)*0+(4.6242-2*dd_corr)*0;
SL3=(5.9642-2*dd_corr)*1+(1.6742-2*dd_corr)*1+(3.4242-2*dd_corr)*1+(2.3742-2*dd_corr)*0+(4.6242-2*dd_corr)*0;
SL4=(5.9642-2*dd_corr)*1+(1.6742-2*dd_corr)*1+(3.4242-2*dd_corr)*1+(2.3742-2*dd_corr)*1+(4.6242-2*dd_corr)*0;
SL5=(5.9642-2*dd_corr)*1+(1.6742-2*dd_corr)*1+(3.4242-2*dd_corr)*1+(2.3742-2*dd_corr)*1+(4.6242-2*dd_corr)*1;
SL6=(5.9642-2*dd_corr)*1+(1.6742-2*dd_corr)*1+(3.4242-2*dd_corr)*1+(2.3742-2*dd_corr)*2+(4.6242-2*dd_corr)*1;
SL7=(5.9642-2*dd_corr)*1+(1.6742-2*dd_corr)*1+(3.4242-2*dd_corr)*2+(2.3742-2*dd_corr)*2+(4.6242-2*dd_corr)*1;
SL8=(5.9642-2*dd_corr)*1+(1.6742-2*dd_corr)*2+(3.4242-2*dd_corr)*2+(2.3742-2*dd_corr)*2+(4.6242-2*dd_corr)*1;
SL9=(5.9642-2*dd_corr)*2+(1.6742-2*dd_corr)*2+(3.4242-2*dd_corr)*2+(2.3742-2*dd_corr)*2+(4.6242-2*dd_corr)*1;
SLA=(5.9642-2*dd_corr)*2+(1.6742-2*dd_corr)*3+(3.4242-2*dd_corr)*2+(2.3742-2*dd_corr)*2+(4.6242-2*dd_corr)*1;
SLB=(5.9642-2*dd_corr)*2+(1.6742-2*dd_corr)*3+(3.4242-2*dd_corr)*3+(2.3742-2*dd_corr)*2+(4.6242-2*dd_corr)*1;
SLC=(5.9642-2*dd_corr)*2+(1.6742-2*dd_corr)*3+(3.4242-2*dd_corr)*3+(2.3742-2*dd_corr)*3+(4.6242-2*dd_corr)*1;
SLD=(5.9642-2*dd_corr)*2+(1.6742-2*dd_corr)*3+(3.4242-2*dd_corr)*3+(2.3742-2*dd_corr)*3+(4.6242-2*dd_corr)*2;
SLE=(5.9642-2*dd_corr)*2+(1.6742-2*dd_corr)*3+(3.4242-2*dd_corr)*3+(2.3742-2*dd_corr)*4+(4.6242-2*dd_corr)*2;
SLF=(5.9642-2*dd_corr)*2+(1.6742-2*dd_corr)*3+(3.4242-2*dd_corr)*4+(2.3742-2*dd_corr)*4+(4.6242-2*dd_corr)*2;
! value, SL0, SL1, SL2, SL3, SL4, SL5, SL6, SL7, SL8, SL9, SLA, SLB, SLC, SLD, SLE, SLF;
! value SYNCHRO_L;
! stop;

muxl: sequence, l = SYNCHRO_L;
! AM: insert a convenient marker
START_SEQ: MARKER, at = 0;

\n'''
        )
    
def WriteFooter(oFile):
    oFile.write(
'''
! -------------------------------
! AM: insert a convenient marker
END_SEQ: MARKER, at = SYNCHRO_L;
endsequence;

\n'''
)

def WriteMBS(oFile,MBSname):
    cellID=MBSname[1]
    cellN=int(cellID,16)
    posString="SL%1s+LMB*(%2i+1/2)"%(cellID,cellN)
    oFile.write("\n")
    oFile.write("! -------------------------------\n")
    oFile.write("%11s, at = %s ;\n"%(MBSname,posString))
    oFile.write("! -------------------------------\n")
    return cellID,cellN

def EleList2Seq_synchro(EleList,oFileName,lRelDists=True,lMagLayout=True,
         cumTypes=cumTypes_magLayOut, wrtTypes=wrtTypes_magLayOut):
    '''
    This function crunches the element list (including drifts) to produce the respective .seq
    The position of the elements in the sequence is absolut (i.e. there is no "FROM=" statement),
        but the distances are expressed as:
            <MBS_absolute_position>+<relative_distance>
        where <relative_distance> can be expressed 
    The function is taylored for the synchro, and the crunched element list MUST start with an MBS!

    Parameters
    ----------
    EleList : list of MyElement
        List of elements contained in the file.
    oFileName : string
        Name of file with sequence declaration - to be written.
    lRelDists : boolean, optional
        False: relative distances (for locating each element) are given wrt to end of MB - FULL cumulative.
        True: relative distances (for locating each element) are given wrt to previous element belonging to the list cumTypes.
        The default is True.
    lMagLayout : boolean, optional
        False: relative distances (for locating each element) are given expressed including the string "+dd_synch-dd_corr".
        True: relative distances (for locating each element) are given in asbolute, i.e. NOT including the string "+dd_synch-dd_corr".
        The default is True.
    cumTypes : array of strings, optional
        List of MADX keywords of elements that are used to compute relative distances.
        If None, this array is set identical to wrtTypes
        The default is cumTypes_magLayOut.
    wrtTypes : array of strings, optional
        List of MADX keywords of elements that should appear in output sequence.
        The default is wrtTypes_magLayOut.

    Returns
    -------
    None.
    
    To write a .seq file with element locations given as cumulative position wrt start of cell:
        EleList2Seq_synchro(EleList,oFileName,lRelDists=False)
    
    To write a .seq file with element locations given so as to compare directly against technical drawing of magnetic layout:
        EleList2Seq_synchro(EleList,oFileName)

    To write a .seq file with element locations given as shifts with respect to the immediately preceeding ones:
        EleList2Seq_synchro(EleList,oFileName,cumTypes=None)

    '''
    if ( cumTypes is None ):
        cumTypes=wrtTypes
    try:
        oFile=open(oFileName,"w")
    except:
        sys.exit("errore when opening file named:",oFileName)
        
    WriteHeader(oFile)
    
    print("converting element list into sequence saved in %s file..."%(oFileName))
    for tmpElement in EleList:
        # active element
        if ("_001A_MBS" in tmpElement.Name):
            # new cell:
            cellID,cellN=WriteMBS(oFile,tmpElement.Name)
            Lcumul=0.0
            LcumLast=Lcumul
            if (lMagLayout):
                posStringBase="SL%1s+LMB* %2i     "%(cellID,cellN+1)
            else:
                posStringBase="SL%1s+LMB* %2i     +dd_synch-dd_corr"%(cellID,cellN+1)
            if (lRelDists):
                posString=posStringBase
        else:
            if (tmpElement.Len=="dd_synch-dd_corr".upper()):
                if (lMagLayout):
                    Lcumul=Lcumul+0.2181
                    LcumLast=LcumLast+0.2181
            else:
                Lcumul=Lcumul+float(tmpElement.Len)/2
                LcumLast=LcumLast+float(tmpElement.Len)/2
            if (tmpElement.Type in wrtTypes):
                if (lRelDists):
                    posString=posStringBase
                    if (LcumLast>0):
                        posString="%s+%10.6f"%(posString,LcumLast)
                    oFile.write("%11s, at = %s; ! %10.6f \n"%(tmpElement.Name.lower(),posString,Lcumul))
                else:
                    posString="%s+%10.6f"%(posStringBase,Lcumul)
                    oFile.write("%11s, at = %s;\n"%(tmpElement.Name.lower(),posString))
            if (lRelDists):
                if (tmpElement.Type in cumTypes):
                    LcumLast=0.0
                    posStringBase=posString
            if (tmpElement.Len!="dd_synch-dd_corr".upper()):
                Lcumul=Lcumul+float(tmpElement.Len)/2
                LcumLast=LcumLast+float(tmpElement.Len)/2
                
    WriteFooter(oFile)
    
    print("...done.")
    oFile.close()
    
if ( __name__=="__main__" ):
    # generation
    # iFileName="synchro/sequences/cnao-elem-BDI-v3.ele"
    # oFileName="synchro/sequences/synchro.seq"
    # verification
    iFileName="synchro/extraction_geometry.tfs"
    oFileName="test.seq"
    if (iFileName.endswith(".ele")):
        EleList=ParseEleDeclaration_synchro(iFileName)
    elif (iFileName.endswith(".tfs")):
        EleList=ParseTFS_synchro(iFileName)
    else:
        sys.exit("not able to crunch file %s"%(iFileName))
    # generation
    # # OFFICIAL FORMAT: element locations given as shifts with respect to the previous one
    # EleList2Seq_synchro(EleList,oFileName,lMagLayout=False)
    # # ALTERNATIVE FORMAT 1: element locations given as shifts with respect to the immediately preceeding one
    # EleList2Seq_synchro(EleList,oFileName,lMagLayout=False,cumTypes=None)
    # # ALTERNATIVE FORMAT 2: element locations given as cumulative position wrt start of cell
    # EleList2Seq_synchro(EleList,oFileName,lMagLayout=False,lRelDists=False)
    # verification
    # dump sequence for comparison to MagLayout:
    EleList2Seq_synchro(EleList,oFileName)
    