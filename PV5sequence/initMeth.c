/****************************************************************
 *
 * $Source: /pv/CvsTree/pv/gen/src/prg/methods/DtiEpi/initMeth.c,v $
 *
 * Copyright (c) 2002-2003
 * Bruker BioSpin MRI GmbH
 * D-76275 Ettlingen, Germany
 *
 * All Rights Reserved
 *
 *
 * $Id: initMeth.c,v 1.11.2.6 2009/10/23 09:24:19 dgem Exp $
 *
 ****************************************************************/

static const char resid[] = "$Id: initMeth.c,v 1.11.2.6 2009/10/23 09:24:19 dgem Exp $ (C) 2002-2003 Bruker BioSpin MRI GmbH";

#define DEBUG		0
#define DB_MODULE	0
#define DB_LINE_NR	0




#include "method.h"


/*:=MPB=:=======================================================*
 *
 * Global Function: initMeth
 *
 * Description: This procedure is implicitly called when this
 *	method is selected.
 *
 * Error History: 
 *
 * Interface:							*/

void initMeth()
/*:=MPE=:=======================================================*/
{
  int dimRange[2] = { 2,3 };
  int lowMat[3]   = { 16, 16, 8 };
  int upMat[3]    = { 512, 512, 256 };



  DB_MSG(( "--> initMeth\n" ));

  /*
   * Set Version number of current method
   */

  PTB_VersionRequirement(Yes, 20070101,"");


  /* initialize the Preemphasis group */
  STB_InitPreemphasis();



  /*
   * ShowParam initialization
   */

  ShowAllParsRange();

  /*
   *  initialization of PVM_Nuc1
   */

  STB_InitNuclei(1);

  /*
   *  initialize local gradient parameter 
   */

  GradStabTimeRange();

  /*
   *  init 3D phase encoding parameters
   */


  Phase3DGradLim     = 57.0;
  InitPhase3DEncoding(ShowAllPars);

  ParxRelsMakeNonEditable("Phase3DGradDur"); /* ,ReadDephTime"); */

  
  /*
   * Slice selection parameter initialization
   */
  
  ExcSliceGradLim     = 100.0;
  ExcSliceRephGradLim = 100.0;

  InitSliceSelection(ShowAllPars);

  PackDelRange();

  /* 
   * RF Pulse initialization
   */
  
  InitRFPulses();
  ParxRelsShowInEditor("PVM_ExcPulseAngle");


  /* segments */
  NSegmentsRange();


  /* 
   * Initialisation of modules 
   */


  STB_InitEncoding();
  STB_InitEpi(UserSlope, No_navigators);
  STB_InitFatSupModule();
  STB_InitTriggerModule();
  STB_InitSatSlicesModule();
  STB_InitTrajectory();
  ParxRelsMakeNonEditable("PVM_TrajectoryMeasurement");

  STB_InitDiffusionPreparation(Yes);



  /*
   *  init inplane geometry parameters
   */

  STB_InitStandardInplaneGeoPars(2,dimRange,lowMat,upMat,No);


  /*
   *  init slice geometry parameters
   */

  STB_InitSliceGeoPars(0,0,0);

  /* 
   * init spectroscopy parameters (no csi)
   */

  PTB_SetSpectrocopyDims( 0, 0 );


  /*
   *  initialize standard imaging parameters NA TR TE
   */

  MinPrepRepTimeRange();
  EffSwRange();
  STB_InitDigPars();

  RepetitionTimeRange();
  AveragesRange();
  RepetitionsRange();
  EchoTimeRange();

  ParxRelsMakeNonEditable("MinPrepRepTime");
  ParxRelsShowInFile("MinPrepRepTime");

  /* initialize dummy scans */

  InitDs();


  /* initialize isa fit function name */

  FitFunctionNameRange();

  ParxRelsMakeNonEditable("PVM_MinEchoTime");
  ParxRelsHideInFile("PVM_MinEchoTime");
 

  if(ParxRelsParHasValue("TopUp") == No)
    TopUp = Yes;

  topupc=2;
  /* 
   * Once all parameters have initial values, the backbone is called
   * to assure they are consistent 
   */
  
  ParxRelsHideClassInEditor("ScanEditorInterface");

  backbone();
 

  DB_MSG(( "<-- initMeth\n" ));

}



/****************************************************************/
/*		E N D   O F   F I L E				*/
/****************************************************************/


