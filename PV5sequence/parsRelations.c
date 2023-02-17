/* ***************************************************************
 *
 * $Source: /pv/CvsTree/pv/gen/src/prg/methods/DtiEpi/parsRelations.c,v $
 *
 * Copyright (c) 2003-2009
 * Bruker BioSpin MRI GmbH
 * D-76275 Ettlingen, Germany
 *
 * All Rights Reserved
 *
 *
 * $Id: parsRelations.c,v 1.16.2.14 2010/03/19 07:51:18 dgem Exp $
 *
 ****************************************************************/


static const char resid[] = "$Id: parsRelations.c,v 1.16.2.14 2010/03/19 07:51:18 dgem Exp $ (C) 2003-2009 Bruker BioSpin MRI GmbH";


#define DEBUG		0
#define DB_MODULE	0
#define DB_LINE_NR	0




#include "method.h"



void backbone(void)
{

  double minFov[3];
  double minSliceThick,sliceThick,prepEchoTime,minte1;
  double sliceGradRatio;
  int dim,status,flag3d;


  DB_MSG(("-->backbone\n"));

  /* update of preemphasis; must take place before nuclei update */
  STB_UpdatePreemphasis();


  STB_UpdateNuclei(No);


  if(TopUp = Yes)
  {
     if(PVM_NRepetitions%2==1)
         PVM_NRepetitions=PVM_NRepetitions+1;
  }

RealRepeat=PVM_NRepetitions/2;

  /*
   *  update excitation and refocusing pulse
   */  
  UpdateRFPulses(PVM_DeriveGains,PVM_Nucleus1);

  PVM_ExcPulseAngle = ExcPulse.FlipAngle;

  /*
   * fix timing according to method specific constraints
   */

  Phase3DGradDur = ExcSliceRephTime;

  dim = PTB_GetSpatDim();


  /*
   *  calculate limits for read phase and slice
   */


  /* minFov[2] = 1e-3;  a 3d method */

  if(dim == 3)
  {
    ParxRelsShowClassInEditor("Phase3DEncoding");
    minFov[2] = Phase3DEncodingLimits(PVM_Matrix[2],
                                      GradStabTime,
                                      PVM_GradCalConst);
  }
  else
  {
    ParxRelsHideClassInEditor("Phase3DEncoding");
    minFov[2] = 1e-6;
  }


  minFov[0] = PVM_EffSWh/PVM_GradCalConst;
  minFov[1] = minFov[0]/16.0;  /* reasonable limit for epi */
  

  minSliceThick = SliceSelectionLimits(&ExcPulse,
                                       BwScale,
                                       GradStabTime,
                                       PVM_GradCalConst,
                                       &sliceGradRatio);

  
  /*
   *  update geometry parameters maximum anti alias is 1.0
   */




  STB_StandardInplaneGeoParHandler(minFov,2.0);

  /* 
   * First update of diffusion, just to know the total n.images (PVM_DwNDiffExp),
   * needed for the update of Epi. Arguments are set to values which cause no restrictions
   * of diffusion wieghting. The actual, correct update comes later. 
   */
  prepEchoTime = 1e6;
  sliceThick = 1e6;
 
  if(dim == 3) 
  {
    double min;

    min = MAX_OF(minFov[2], minSliceThick);
    minFov[2] = minSliceThick = min;
    PVM_SliceThick = PVM_Fov[2];
    flag3d = 1;
  }
  else
  {
    flag3d=0;
  }
 
  if(PVM_DwDirectScale == Yes)
    STB_UpdateSliceGeoPars(0,1,flag3d,minSliceThick);
  else
    STB_UpdateSliceGeoPars(0,flag3d,flag3d,minSliceThick);

  /* update encoding parameter class */

  /*** encoding */
  /* note: Grappa reference lines are disabled. Grappa coeeficients will be set
   * in a special adjustment. */

  STB_UpdateEncodingForEpi(PTB_GetSpatDim(),  /* total dimensions */
                           PVM_Matrix,        /* image size */ 
                           PVM_AntiAlias,     /* a-alias */
                           &NSegments,        /* segment size */
                           Yes,               /* ppi in 2nd dim allowed */
                           No,                /* ppi ref lines in 2nd dim allowed */
                           Yes);              /* partial ft in 2nd dim allowed */ 


  /* update epi module: */
  
  status = STB_EpiUpdate(dim, 
                         PVM_EncMatrix, 
                         PVM_AntiAlias,
                         PVM_Fov, 
                         minFov, 
                         &PVM_EffSWh, 
                         PVM_GradCalConst, 
                         GTB_NumberOfSlices( PVM_NSPacks, PVM_SPackArrNSlices ),
                         1,
                         NSegments,
                         PVM_EncCentralStep1,
                         PVM_EncPpiAccel1,
                         PVM_EncNReceivers);

  /* minFov is now known; we update geometry again */
  STB_StandardInplaneGeoParHandler(minFov,2.0);


  /*
   * Ultimate update of Diffusion 
   */

  minte1 =  CalcEchoDelay();
  prepEchoTime = EchoTime;

  sliceThick = 100*MAX_OF(PVM_SliceThick,minSliceThick)/BwScale;

  status = STB_UpdateDiffusionPreparation(&sliceThick,
                                          PVM_DeriveGains,
                                          PVM_Nucleus1,
                                          PtrType3x3 PVM_SPackArrGradOrient[0],
                                          minte1,
                                          PVM_EpiEchoDelay,
                                          &prepEchoTime);

  if(status == 1)
  {
    minSliceThick = BwScale*sliceThick/100.0;
  }

  /*
   * no read offset in EPI variants
   */
  ConstrainReadOffset();

  if(PVM_DwDirectScale == Yes)
    STB_UpdateSliceGeoPars(0,1,flag3d,minSliceThick);
  else
    STB_UpdateSliceGeoPars(0,flag3d,flag3d,minSliceThick);



  PVM_TrajectoryMeasurement = No; 
  STB_UpdateTrajectory(PVM_Matrix[0],PVM_NSPacks);

  if(dim == 3)
  {
    UpdatePhase3DGradients(PVM_Matrix[2],PVM_Fov[2],PVM_GradCalConst);
  }

  UpdateSliceSelectionGradients(PVM_SliceThick,
                                sliceGradRatio,
                                ExcPulse.Bandwidth*BwScale/100.0,
                                PVM_GradCalConst);

  STB_UpdateFatSupModule(PVM_Nucleus1);
  STB_UpdateSatSlicesModule(PVM_Nucleus1);




  /*
   *  calculate frequency offsets
   */

  LocalFrequencyOffsetRels();

  /*
   *  update sequence timing
   */

  HandleDs(PVM_EpiNShots);
  UpdateEchoTime(prepEchoTime);
  UpdateRepetitionTime();

  PVM_NEchoImages = 1;

  SetBaseLevelParam();
  SetRecoParam(PVM_EncPpiAccel1);
 
  STB_EpiCheckTrajectory(PVM_Fov[0],PVM_EncMatrix[0],PVM_EffSWh,PVM_SPackArrGradOrient[0][0]);
  SetAdjustmentRequests();


  DB_MSG(("<--backbone\n"));
  return;
}

/*-------------------------------------------------------
 * local utility routines to simplify the backbone 
 *------------------------------------------------------*/

double CalcEchoDelay(void)
{
  double riseTime, igwt,retVal;
  riseTime = CFG_GradientRiseTime();
  igwt     = CFG_InterGradientWaitTime();

  retVal = 
    ExcPulse.Length/2                   +
    riseTime   + igwt                   + /* min TE1/2 filling delay */
    ExcSliceRephTime                    +
    igwt;                                
 
  return retVal;
}

void UpdateEchoTime(double minechotime)
{

  DB_MSG(("-->UpdateEchoTime\n"));

 
  PVM_MinEchoTime = minechotime;
  EchoTime        = MAX_OF(PVM_MinEchoTime,EchoTime);

  /*
   * Set Echo Parameters for Scan Editor  
   */

  PVM_EchoTime = PVM_Matrix[0]*PVM_DigDw;  /* echo spacing */
  PVM_EchoTime1 = EchoTime;
  ParxRelsShowInEditor("PVM_EchoTime1,PVM_EchoTime,PVM_NEchoImages");
  ParxRelsShowInFile("PVM_EchoTime1,PVM_EchoTime,PVM_NEchoImages");
  ParxRelsMakeNonEditable("PVM_EchoTime1");
  ParxRelsMakeNonEditable("PVM_NEchoImages");



  DB_MSG(("<--UpdateEchoTime\n"));
  return;
}



void UpdateRepetitionTime(void)
{
  int nslices,dim;
  double TotalTime,slrept,mintr;
  double trigger,riseT,igwT;
  double trigger_s,trigger_v;

  DB_MSG(("-->UpdateRepetitionTime\n"));

  nslices = GTB_NumberOfSlices( PVM_NSPacks, PVM_SPackArrNSlices );
  
  trigger = STB_UpdateTriggerModule();
  if(PVM_TriggerMode == per_PhaseStep) /* per volume */
  {
    trigger_v=trigger;
    trigger_s=0.0;
  }
  else
  {
    trigger_v=0.0;
    trigger_s=trigger;
  }

  riseT   = CFG_GradientRiseTime();
  igwT    = CFG_InterGradientWaitTime();


  slrept =  
      0.024                                            +
      trigger_s                                        +
      PVM_FatSupModuleTime                             +
      PVM_FovSatModuleTime                             +
      SliceGradStabTime                                +
      riseT                                            +
      ExcPulse.Length                                  +
      riseT + igwT                                     +
      ExcSliceRephTime                                 +
      igwT                                             +
      PVM_DwModDur                                     +
      PVM_EpiModuleTime - PVM_EpiEchoDelay             +
      riseT+igwT;                                      /*min d0 */

  PVM_MinRepetitionTime = slrept * nslices + trigger_v + PackDel;

  MinPrepRepTimeRange();

  mintr = MinPrepRepTime * nslices + PackDel;

  PVM_RepetitionTime=MAX_OF(PVM_MinRepetitionTime,PVM_RepetitionTime);


  if(PVM_RepetitionTime < mintr)
  {
    PARX_sprintf("TR constrained by \"Min. Prep. Repetition"
		 " Time\" (%3.0f ms)",MinPrepRepTime);
    PVM_RepetitionTime = mintr;
  }

  TotalTime = PVM_RepetitionTime 
            * PVM_EpiNShots
            * PVM_NAverages *PVM_DwNDiffExp *  PVM_NRepetitions;

  dim = PTB_GetSpatDim();

  if(dim == 3)
  {
    TotalTime *= PVM_EncMatrix[2];
  }

  /* time for one repetition */
  OneRepTime =PVM_RepetitionTime * PVM_EpiNShots * PVM_NAverages / 1000.0;

  UT_ScanTimeStr(PVM_ScanTimeStr,TotalTime);
  ParxRelsShowInEditor("PVM_ScanTimeStr");
  ParxRelsMakeNonEditable("PVM_ScanTimeStr");

  DB_MSG(("<--UpdateRepetitionTime\n"));
  return;
}


void LocalFrequencyOffsetRels( void )
{
  int nslices;
  double readGrad;

  nslices = GTB_NumberOfSlices(PVM_NSPacks,PVM_SPackArrNSlices);



  readGrad = (PVM_EpiReadEvenGrad+PVM_EpiReadOddGrad)/2.0;


  MRT_FrequencyOffsetList(nslices,
			  PVM_EffReadOffset,
			  readGrad,
			  0.0, /* instead of PVM_GradCalConst, to set offsetHz to zero */
			  PVM_ReadOffsetHz );

  MRT_FrequencyOffsetList(nslices,
			  PVM_EffSliceOffset,
			  ExcSliceGrad,
			  PVM_GradCalConst,
			  PVM_SliceOffsetHz );

  if(PTB_GetSpatDim() == 3)
  {
    for(int i=0;i<nslices;i++)
      PVM_EffPhase2Offset[i] = -PVM_EffSliceOffset[i];
  }

}




/*-------------------------------------------------------
 *
 * local group parameter relations
 *
 *------------------------------------------------------*/

void InplaneGeometryRel(void)
{
  double minFov[3] = { 1.0e-6, 1.0e-6, 1.0e-6 };

  DB_MSG(("-->InplaneGeometryRel\n"));

  /* do not allow isotropic geometry */
  PVM_Isotropic = Isotropic_None;  

  STB_StandardInplaneGeoParHandler(minFov,2.0);

  switch(PTB_GetSpatDim())
  {
    case 3:
      PVM_AntiAlias[2] = 1.0;
    case 2:
      PVM_AntiAlias[1] = 1.0;
    case 1:
    default:
      break;
  }


  backbone();

  DB_MSG(("<--InplaneGeometryRel\n"));
  return;
}

void SliceGeometryRel(void)
{
  DB_MSG(("-->SliceGeometryRel\n"));

  if(PTB_GetSpatDim()==3)
  {    
    PVM_Fov[2] = PVM_SliceThick;
  }

  backbone();

  DB_MSG(("<--SliceGeometryRel\n"));
  return;
}

/*--------------------------------------------------------
 *
 * single parameter range checkers and relations
 *
 *-------------------------------------------------------*/


void ShowAllParsRange(void)
{
  DB_MSG(("-->ShowAllParsRange\n"));

  switch(ShowAllPars)
  {
    case Yes:
      break;
    default:
      ShowAllPars = No;
    case No:
      break;
  }

  DB_MSG(("<--ShowAllParsRange\n"));

}

void ShowAllParsRel(void)
{
  DB_MSG(("-->ShowAllParsRel\n"));

  ShowAllParsRange();

  SliceSelectionParsVisibility(ShowAllPars);
  if(PTB_GetSpatDim()==3)
  {
    Phase3DEncodingParsVisibility(ShowAllPars);
  }
  DB_MSG(("<--ShowAllParsRel\n"));
  return;
}

void RepetitionTimeRange(void)
{
  
  DB_MSG(("-->RepetitionTimeRange\n"));

  if(ParxRelsParHasValue("PVM_RepetitionTime")==No)
  {
    PVM_RepetitionTime = 500.0;

  }
  else
  {
    PVM_RepetitionTime = MAX_OF(1e-3,PVM_RepetitionTime);
  }

  
  DB_MSG(("<--RepetitionTimeRange\n"));
  return;
}

void RepetitionTimeRel(void)
{
  DB_MSG(("-->RepetitionTimeRel\n"));

  RepetitionTimeRange();
  backbone();

  DB_MSG(("<--RepetitionTimeRel\n"));
  return;
}

void AveragesRange(void)
{
  
  DB_MSG(("-->AveragesRange\n"));

  if(ParxRelsParHasValue("PVM_NAverages")==No)
  {
    PVM_NAverages = 1;

  }
  else
  {
    PVM_NAverages = MAX_OF(1,PVM_NAverages);
  }

  
  DB_MSG(("<--AveragesRange\n"));
  return;
}

void AveragesRel(void)
{
  DB_MSG(("-->AveragesRel\n"));

  AveragesRange();
  backbone();

  DB_MSG(("<--AveragesRel\n"));
  return;
}

void RepetitionsRange(void)
{
  
  DB_MSG(("-->RepetitionsRange\n"));

  if(ParxRelsParHasValue("PVM_NRepetitions")==No)
  {
    PVM_NRepetitions = 1;

  }
  else
  {
    PVM_NRepetitions = MAX_OF(1,PVM_NRepetitions);
  }

  
  DB_MSG(("<--RepetitionsRange\n"));
  return;
}

void RepetitionsRel(void)
{
  DB_MSG(("-->RepetitionsRel\n"));

  RepetitionsRange();
  backbone();

  DB_MSG(("<--RepetitionsRel\n"));
  return;
}



void EchoTimeRange(void)
{
  
  DB_MSG(("-->EchoTimeRange\n"));

  if(ParxRelsParHasValue("PVM_EchoTime")==No)
  {
    PVM_EchoTime = 20.0;

  }
  else
  {
    PVM_EchoTime = MAX_OF(1e-3,PVM_EchoTime);
  }

  
  DB_MSG(("<--EchoTimeRange\n"));
  return;
}

void EchoTimeRel(void)
{
  DB_MSG(("-->EchoTimeRel\n"));

  EchoTimeRange();
  backbone();

  DB_MSG(("<--EchoTimeRel\n"));
  return;
}


void GradStabTimeRange(void)
{
  double max;
  DB_MSG(("-->GradStabTimeRange\n"));

  max = CFG_GradientRiseTime();

  if(ParxRelsParHasValue("GradStabTime")==No)
  {
    GradStabTime = 0.0;
  }
  else
  {
    GradStabTime = MAX_OF(MIN_OF(max,GradStabTime),0.0);
  }
    


  DB_MSG(("<--GradStabTimeRange\n"));
  return;
  
}

void GradStabTimeRel(void)
{
  DB_MSG(("-->GradStabTimeRel\n"));

  GradStabTimeRange();
  backbone();

  DB_MSG(("-->GradStabTimeRel\n"));
  return;
}





void ExcPulseAngleRelation(void)
{
  DB_MSG(("-->ExcPulseAngleRelation"));

  ExcPulse.FlipAngle = PVM_ExcPulseAngle;
  ExcPulseRange();
  backbone();

  DB_MSG(("<--ExcPulseAngleRelation"));
}

void EffSwRange(void)
{

  DB_MSG(("-->EffSwRange\n"));

  if(ParxRelsParHasValue("PVM_EffSWh")==No)
  {
    PVM_EffSWh = 100000.0;
  }
  else
  {
    PVM_EffSWh = MAX_OF(  50000.0,PVM_EffSWh);
    PVM_EffSWh = MIN_OF(1000000.0,PVM_EffSWh);
  }


  DB_MSG(("<--EffSwRange\n"));
  return;
}

void EffSwRel(void)
{
  DB_MSG(("-->EffSwRel\n"));
  
  EffSwRange();
  backbone();

  DB_MSG(("<--EffSwRel\n"));

}


void PackDelRange(void)
{
  DB_MSG(("-->PackDelRange\n"));

  if(ParxRelsParHasValue("PackDel")==No)
  {
    PackDel = 0.001;
  }
  else
  {
    PackDel = MAX_OF(0.001,PackDel);
  }

  DB_MSG(("<--PackDelRange\n"));
  return;
}

void PackDelRel(void)
{
  DB_MSG(("-->PackDelRel\n"));
  PackDelRange();
  backbone();
  DB_MSG(("<--PackDelRel\n"));
  return;
}

/*==============================================================
 * relation of NDummyScans
 *==============================================================*/



void InitDs(void)
{
  DB_MSG(("-->InitDs"));

  HandleDs(1);

  DB_MSG(("<--InitDs"));
  return;
}


/* ***********************************************************************
   The effective number of dummy scans performed is a multiple of the
   number of segments 
   ********************************************************************* */

void HandleDs(int nshots)
{


  DB_MSG(("-->HandleDs"));

  nshots = MAX_OF(1,nshots);


  if(!ParxRelsParHasValue("NDummyScans") || NDummyScans < 1)
  {
    NDummyScans = 0;
  }


  
  DB_MSG(("-->HandleDs"));
  return;

} 

void FitFunctionNameRange(void)
{
  DB_MSG(("-->FitFunctionNameRange"));

  if(!ParxRelsParHasValue("FitFunctionName"))
  {
    strcpy(FitFunctionName,"dtraceb");
  }
  else
  {
    FitFunctionName[31]='\0';
  }

  DB_MSG(("<--FitFunctionNameRange"));

}
  

void FitFunctionNameRel(void)
{
  DB_MSG(("-->FitFunctionNameRel"));
  FitFunctionNameRange();
  backbone();
  DB_MSG(("<--FitFunctionNameRel"));
  return;
}


/*
 *  local function to constrain the read offset for slice packages
 */

void ConstrainReadOffset(void)
{
  int dim=0,i=0;
  double *offs, max;
  DB_MSG(("-->ConstrainReadOffset"));

  dim = PARX_get_dim("PVM_SPackArrReadOffset",1);
  offs = PVM_SPackArrReadOffset;

  max = (PVM_Fov[0]/2)*(PVM_AntiAlias[0]-1.0);
  max = MAX_OF(max, 0);

  for(i=0;i<dim;i++)
  {
    offs[i]=MAX_OF(offs[i], -max);
    offs[i]=MIN_OF(offs[i], max);
  }


  DB_MSG(("<--ConstrainReadOffset"));
  return;
}

/*
 *  relations for min preparation repetition time
 */

void MinPrepRepTimeRange(void)
{

  DB_MSG(("-->MinPrepRepTimeRange"));

  if(!ParxRelsParHasValue("MinPrepRepTime"))
  {
    MinPrepRepTime = 500.0;
  }
  else
  {
    MinPrepRepTime = MAX_OF(MinPrepRepTime,250.0);
  }


  DB_MSG(("<--MinPrepRepTimeRange"));
}

void MinPrepRepTimeRel(void)
{

  DB_MSG(("-->MinPrepRepTimeRel"));

  MinPrepRepTimeRange();
  backbone();

  DB_MSG(("<--MinPrepRepTimeRel"));
}


/* relations of NSegments */

void NSegmentsRels(void)
{
  NSegmentsRange();
  backbone();
}

void NSegmentsRange(void)
{
  if(!ParxRelsParHasValue("NSegments"))
    NSegments = 1;
  else
    NSegments = MAX_OF(1,NSegments);
}
