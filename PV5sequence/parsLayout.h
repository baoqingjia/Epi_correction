/* ***************************************************************
 *
 * $Source: /pv/CvsTree/pv/gen/src/prg/methods/DtiEpi/parsLayout.h,v $
 *
 * Copyright (c) 2003
 * Bruker BioSpin MRI GmbH
 * D-76275 Ettlingen, Germany
 *
 * All Rights Reserved
 *
 * $Id: parsLayout.h,v 1.9.2.4 2009/10/23 09:24:36 dgem Exp $
 *
 ****************************************************************/

/****************************************************************/
/*	PARAMETER CLASE_EPIS				       	*/
/****************************************************************/

#include "Phase3DLayout.h"
#include "SliceSelLayout.h"
#include "RFPulseLayout.h"



/*--------------------------------------------------------------*
 * Definition of the PV class...
 *--------------------------------------------------------------*/

parclass
{
  ShowAllPars;
  MinPrepRepTime;
  GradStabTime;
  Phase3DEncoding;
  SliceSelection;
  DigitizerPars;
  FitFunctionName;
}
attributes
{
  display_name "Sequence Details";
}SequenceDetails;


parclass
{
  NDummyScans;
  PVM_TriggerModule;
  Trigger_Parameters;
  PVM_FatSupOnOff;
  Fat_Sup_Parameters;
  PVM_FovSatOnOff;
  Sat_Slices_Parameters;

} Preparation;

parclass
{
  PVM_EchoTime1;       /* to  be stored in method file */ 
  PVM_EchoTime;    
  PVM_NEchoImages; 
}ScanEditorInterface; 
 


parclass
{
  Method;
  PVM_EffSWh;
  TopUp;
  EchoTime;
  PVM_MinEchoTime;
  NSegments;
  PVM_RepetitionTime;
  PackDel;
  PVM_NAverages;
  PVM_NRepetitions;
  PVM_ScanTimeStr;
  PVM_DeriveGains;
  Diffusion;
  Encoding;
  EPI_Parameters;
  /* Trajectory_Parameters; */
  RF_Pulses;
  Nuclei;
  SequenceDetails;
  StandardInplaneGeometry;
  StandardSliceGeometry;
  Preparation;
  Preemphasis;
  ScanEditorInterface; 
  Method_RecoOptions;
} MethodClass;


/****************************************************************/
/*	E N D   O F   F I L E					*/
/****************************************************************/

