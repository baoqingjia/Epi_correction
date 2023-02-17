/* ***************************************************************
 *
 * $Source: /pv/CvsTree/pv/gen/src/prg/methods/DtiEpi/BaseLevelRelations.c,v $
 *
 * Copyright (c) 2003-2009
 * Bruker BioSpin MRI GmbH
 * D-76275 Ettlingen, Germany
 *
 * All Rights Reserved
 *
 *
 * $Id: BaseLevelRelations.c,v 1.12.2.11 2010/03/08 13:23:40 dgem Exp $
 *
 * ***************************************************************/

static const char resid[] = "$Id: BaseLevelRelations.c,v 1.12.2.11 2010/03/08 13:23:40 dgem Exp $ (C) 2003-2009 Bruker BioSpin MRI GmbH";


#define DEBUG		0
#define DB_MODULE	0
#define DB_LINE_NR	0




#include "method.h"

void SetBaseLevelParam( void )
{

  DB_MSG(("-->SetBaseLevelParam\n"));

  SetBasicParameters();
  
  
  if( PVM_ErrorDetected == Yes )
  {
    UT_ReportError("SetBaseLevelParam: Error in function call!");
    return;
  }
  
  SetFrequencyParameters();
  
  if( PVM_ErrorDetected == Yes )
  {
    UT_ReportError("SetBaseLevelParam: In function call!");
    return;
  }
  
  SetPpgParameters();

  if( PVM_ErrorDetected == Yes )
  {
    UT_ReportError("SetBaseLevelParam: In function call!");
    return;
  }
  
  SetGradientParameters();
  
  if( PVM_ErrorDetected == Yes )
  {
    UT_ReportError("SetBaseLevelParam: In function call!");
    return;
  }
  
  SetInfoParameters();
  
  if( PVM_ErrorDetected == Yes )
  {
    UT_ReportError("SetBaseLevelParam: In function call!");
    return;
  }
  
  
  SetMachineParameters();
  
  if( PVM_ErrorDetected == Yes )
  {
    UT_ReportError("SetBaseLevelParam: In function call!");
    return;
  }
  
  /* multiple receivers */
  if(Yes==ATB_SetMultiRec())
  {
    ATB_SetPulprog("DtiEpi_topup.4ch");
  }


  ATB_EpiSetBaseLevel();
  ATB_SetFatSupBaselevel();
  ATB_SetSatSlicesBaseLevel();
  ATB_SetTriggerBaseLevel();
  ATB_DwAcq(ACQ_O1_list,
	    GTB_NumberOfSlices( PVM_NSPacks, PVM_SPackArrNSlices ),
	    ExcSliceGrad,No);


  PrintTimingInfo();

  DB_MSG(("<--SetBaseLevelParam\n"));
  

}

void SetBasicParameters( void )
{
  int spatDim, specDim;
  int nSlices;


  DB_MSG(("-->SetBasicParameters\n"));
    
  /* ACQ_dim */

  spatDim = PTB_GetSpatDim();
  if( PVM_ErrorDetected == Yes )
  {
    UT_ReportError("SetBasicParameters: In function call!");
    return;
  }
  
  specDim = PTB_GetSpecDim();
  if( PVM_ErrorDetected == Yes )
  {
    UT_ReportError("SetBasicParameters: In function call!");
    return;
    }
  
  ACQ_dim = spatDim + specDim;
  ParxRelsParRelations("ACQ_dim",Yes);
  
  /* ACQ_dim_desc */
  
  ATB_SetAcqDimDesc( specDim, spatDim, NULL );
  if( PVM_ErrorDetected == Yes )
  {
    UT_ReportError("SetBasicParameters: In function call!");
    return;
  }
  
  /* ACQ_size */
  ACQ_size[0] = PVM_EpiNSamplesPerScan*2;
  ACQ_size[1] = PVM_EpiNShots;
  if(ACQ_dim>2)
    ACQ_size[2] = PVM_EncMatrix[2];

  /* NSLICES */
  
  nSlices = GTB_NumberOfSlices( PVM_NSPacks, PVM_SPackArrNSlices );
  if( PVM_ErrorDetected == Yes )
  {
    UT_ReportError("SetBasicParameters: In function call!");
    return;
  }
  
  ATB_SetNSlices( nSlices );
  if( PVM_ErrorDetected == Yes )
  {
    UT_ReportError("SetBasicParameters: In function call!");
    return;
  }
  
  /* NR */
  
  ATB_SetNR( PVM_NRepetitions*PVM_DwNDiffExp);
  if( PVM_ErrorDetected == Yes )
  {
    UT_ReportError("SetBasicParameters: In function call!");
    return;
  }
  
  /* NI */
  
  ATB_SetNI( nSlices);
  if( PVM_ErrorDetected == Yes )
  {
    UT_ReportError("SetBasicParameters: In function call!");
    return;
  }
  
  
  /* AVERAGING */


  switch(PVM_MotionSupOnOff)
  {
  default:
  case Off:
    ATB_SetNA( PVM_NAverages );
    if( PVM_ErrorDetected == Yes )
    {
      UT_ReportError("SetBasicParameters: In function call!");
      return;
    }
    ATB_SetNAE( 1 );
    if( PVM_ErrorDetected == Yes )
    {
      UT_ReportError("SetBasicParameters: In function call!");
      return;
    }
    break;
  case On:
    ATB_SetNAE( PVM_NAverages );
    if( PVM_ErrorDetected == Yes )
    {
      UT_ReportError("SetBasicParameters: In function call!");
      return;
    }
    ATB_SetNA( 1 );
    if( PVM_ErrorDetected == Yes )
    {
      UT_ReportError("SetBasicParameters: In function call!");
      return;
    }
    break;
  }
 
  
  /* ACQ_ns */
  
  ACQ_ns_list_size = 1;
  ParxRelsParRelations("ACQ_ns_list_size",Yes);

  ACQ_ns_list[0] = 1;

  
  NS = ACQ_ns = ACQ_ns_list[0];
  
  
  
  /* NECHOES */
  
  NECHOES = 1;
  
  
  /* ACQ_obj_order */
  
  PARX_change_dims("ACQ_obj_order",NI);
  
  ATB_SetAcqObjOrder( nSlices, PVM_ObjOrderList, 1, 1 );
  if( PVM_ErrorDetected == Yes )
  {
    UT_ReportError("SetBasicParameters: In function call!");
    return;
  }
  
  
  /* DS 
   * dummy scans programmed explicitely in the ppg without signal acquisition
   * therefore DS is set ot zero and L[1] is used instead 
   */
  
  DS = 0; 
  L[1] = NDummyScans;
  L[2] = ACQ_dim>2? ACQ_size[2]:1;

  /* no dummy acquisition during measurement in case of restricted
     dataflow
  */

  ACQ_DS_enabled = No;
  
  
  ATB_DisableAcqUserFilter();
  if( PVM_ErrorDetected == Yes )
  {
    UT_ReportError("SetBasicParameters: In function call!");
    return;
  }

  ATB_SetAcqScanSize( One_scan );
  if( PVM_ErrorDetected == Yes )
  {
    UT_ReportError("SetBasicParameters: In function call!");
    return;
  }
  
  
  DB_MSG(("<--SetBasicParameters\n"));
}

void SetFrequencyParameters( void )
{
  int nslices;

  DB_MSG(("-->SetFrequencyParameters\n"));


  ATB_SetNuc1(PVM_Nucleus1);
   
  sprintf(NUC2,"off");
  sprintf(NUC3,"off");
  sprintf(NUC4,"off");
  sprintf(NUC5,"off");
  sprintf(NUC6,"off");
  sprintf(NUC7,"off");
  sprintf(NUC8,"off");
  
  ATB_SetNucleus(PVM_Nucleus1);
  
  
  if( PVM_ErrorDetected == Yes )
  {
    UT_ReportError("SetFrequencyParameters: In function call!");
    return;
  }

  /* setting of SW_h, DSPFIRM, DIGMOD and AQ_mod */
  
  ATB_SetDigPars();  
  
  ACQ_O1_mode = BF_plus_Offset_list;
  ParxRelsParRelations("ACQ_O1_mode",Yes);
  
  ACQ_O2_mode = BF_plus_Offset_list;
  ParxRelsParRelations("ACQ_O2_mode",Yes);
  
  ACQ_O3_mode = BF_plus_Offset_list;
  ParxRelsParRelations("ACQ_O3_mode",Yes);
  
  O1 = 0.0;
  O2 = 0.0;
  O3 = 0.0;
  O4 = 0.0;
  O5 = 0.0;
  O6 = 0.0;
  O7 = 0.0;
  O8 = 0.0;
  
  nslices = GTB_NumberOfSlices( PVM_NSPacks, PVM_SPackArrNSlices );
  if( PVM_ErrorDetected == Yes )
  {
    UT_ReportError("SetFrequencyParameters: In function call!");
    return;
  }
  
  ATB_SetAcqO1List( nslices,
                    PVM_ObjOrderList,
                    PVM_SliceOffsetHz );
  if( PVM_ErrorDetected == Yes )
  {
    UT_ReportError("SetFrequencyParameters: In function call!");
    return;
  }

  
  ATB_SetAcqO1BList( nslices,
                     PVM_ObjOrderList,
                     PVM_ReadOffsetHz);
  
  
  ATB_SetRouting();
  
  if( PVM_ErrorDetected == Yes )
  {
    UT_ReportError("SetFrequencyParameters: In function call!");
    return;
  }
  
  
  
  DB_MSG(("<--SetFrequencyParameters\n"));
}


void SetGradientParameters( void )
{
  int spatDim, dim, i;

  DB_MSG(("-->SetGradientParameters\n"));
  
  
  ATB_SetAcqPhaseFactor( 1 );
  if( PVM_ErrorDetected == Yes )
  {
    UT_ReportError("SetGradientParameters: In function call!");
    return;
  }
  
  
  spatDim = PTB_GetSpatDim();
  
  dim = PARX_get_dim("ACQ_phase_encoding_mode", 1 );
  
  if( dim != spatDim )
  {
    PARX_change_dims("ACQ_phase_encoding_mode", spatDim );
  }
  
  ACQ_phase_encoding_mode[0] = Read;
  ACQ_phase_encoding_mode[1] = Linear;
  if(spatDim==3)
  {
    ACQ_phase_encoding_mode[2] = User_Defined_Encoding;
    ACQ_spatial_size_2 = PVM_EncMatrix[2];
    ParxRelsCopyPar("ACQ_spatial_phase_2","PVM_EncValues2");
  }

  ParxRelsParRelations("ACQ_phase_encoding_mode",Yes);
  
  dim = PARX_get_dim("ACQ_phase_enc_start", 1 );
  
  if( dim != spatDim )
  {
    PARX_change_dims("ACQ_phase_enc_start", spatDim );
  }
  
  for( i=0; i<spatDim; i++ )
  {
    ACQ_phase_enc_start[i] = -1;
  }
  
  
  ATB_SetAcqGradMatrix( PVM_NSPacks, PVM_SPackArrNSlices,
                        PtrType3x3 PVM_SPackArrGradOrient[0],
                        PVM_ObjOrderList );
  
  if( PVM_ErrorDetected == Yes )
  {
    UT_ReportError("SetGradientParameters: In function call!");
    return;
  }
  
  
  ACQ_scaling_read  = 1.0;
  ACQ_scaling_phase = 1.0;
  ACQ_scaling_slice = 1.0;
  
  ACQ_rare_factor = 1;
  
  ACQ_grad_str_X = 0.0;
  ACQ_grad_str_Y = 0.0;
  ACQ_grad_str_Z = 0.0;
  
  strcpy(GRDPROG, "");
  
  int sign= PVM_DiffPrepMode==2 ? -1:1;



  ATB_SetAcqTrims( 3,
                   ExcSliceGrad,                     /* t0 */             
                   -ExcSliceRephGrad,                /* t1 */
                   sign*Phase3DGrad                  /* t2 */         
  ); /* inverted sign for DoubleSpinEcho mode */
  

  if( PVM_ErrorDetected == Yes )
  {
    UT_ReportError("SetGradientParameters: In function call!");
    return;
  }
  
  DB_MSG(("<--SetGradientParameters\n"));

}

void SetPpgParameters( void )
{
  double riseT,igwT;
  int slices;
  DB_MSG(("-->SetPpgParameters\n"));
  
  if( 0 == ParxRelsParHasValue("ACQ_trigger_enable") )
  {
    ACQ_trigger_enable = No;
  }
  
  if( 0 == ParxRelsParHasValue("ACQ_trigger_reference") )
  {
    ACQ_trigger_reference[0] = '\0';
  }
  
  if( 0 == ParxRelsParHasValue("ACQ_trigger_delay") )
  {
    ACQ_trigger_delay = 0;
  }
  
  ParxRelsParRelations("ACQ_trigger_reference",Yes);
  
  
  ACQ_vd_list_size=1;
  PARX_change_dims("ACQ_vd_list",1);
  ACQ_vd_list[0] = 1e-6;
  ParxRelsParRelations("ACQ_vd_list",Yes);
  
  ACQ_vp_list_size=1;
  PARX_change_dims("ACQ_vp_list",1);
  ACQ_vp_list[0] = 1e-6;
  ParxRelsParRelations("ACQ_vp_list",Yes);
  
  
  ATB_SetPulprog("DtiEpi_topup.ppg");

  slices = GTB_NumberOfSlices( PVM_NSPacks, PVM_SPackArrNSlices );
  igwT   = CFG_InterGradientWaitTime();
  riseT  = CFG_GradientRiseTime();


  D[0]  = ((PVM_RepetitionTime - PVM_MinRepetitionTime)/slices 
            + riseT+igwT)/1000.0;
  D[1]  = (SliceGradStabTime + riseT)/1000.0;
  D[4]  = (riseT + igwT)/1000.0;
  D[2]  = (ExcSliceRephTime - riseT)/1000.0;
  D[3]  = (riseT + igwT)/1000.0;

  D[5]  = PackDel/1000.0;


  L[0]= PVM_EpiNShots;

  
  /* set shaped pulses     */
  sprintf(TPQQ[0].name,ExcPulse.Filename);
  if(PVM_DeriveGains == Yes)
  {
    TPQQ[0].power  = ExcPulse.Attenuation;
  }
  TPQQ[0].offset = 0.0;
  
 
  ParxRelsParRelations("TPQQ",Yes);
  
  /* set duration of pulse, in this method P[0] is used          */
  P[0] = ExcPulse.Length * 1000;

  ParxRelsParRelations("P",Yes);
  
  
  DB_MSG(("<--SetPpgParameters\n"));
}





void SetInfoParameters( void )
{
  int slices, i, spatDim, nrep;
  
  DB_MSG(("-->SetInfoParameters\n"));
  
  spatDim = PTB_GetSpatDim();
  nrep = NR;

  if( PVM_ErrorDetected == Yes )
  {
    UT_ReportError("SetInfoParameters: In function call!");
    return;
  }
  
  ATB_SetAcqMethod();
  
  ATB_SetAcqFov( Spatial, spatDim, PVM_Fov, PVM_AntiAlias );
  if( PVM_ErrorDetected == Yes )
  {
    UT_ReportError("SetInfoParameters: In function call!");
    return;
  }
  
  ACQ_flip_angle = PVM_ExcPulseAngle;
  
  PARX_change_dims("ACQ_echo_time",1);

  ACQ_echo_time[0] = EchoTime;
  
  PARX_change_dims("ACQ_inter_echo_time",1);
  ACQ_inter_echo_time[0] = PVM_EchoTime;
  
  PARX_change_dims("ACQ_repetition_time",1);
  ACQ_repetition_time[0] = PVM_RepetitionTime;
  
  PARX_change_dims("ACQ_recov_time",1);
  ACQ_recov_time[0] =  
    PVM_RepetitionTime - ExcPulse.Length/2;

  /* calculation of ACQ_time_points */
  PARX_change_dims("ACQ_time_points",nrep);
  ACQ_time_points[0] = 0;
  for(i=1; i<nrep; i++)
    ACQ_time_points[i] = OneRepTime * i; 
  
  PARX_change_dims("ACQ_inversion_time",1);
  ACQ_inversion_time[0] = PVM_InversionTime;
  

  strcpy(ACQ_fit_function_name,FitFunctionName);


  ATB_SetAcqSliceAngle( PtrType3x3 PVM_SPackArrGradOrient[0],
			PVM_NSPacks );
  
  ACQ_slice_orient = Arbitrary_Oblique;
  
  ACQ_slice_thick = PVM_SliceThick;
  
  slices = GTB_NumberOfSlices( PVM_NSPacks, PVM_SPackArrNSlices );
  if( PVM_ErrorDetected == Yes )
  {
    UT_ReportError("SetInfoParameters: In function call!");
    return;
  }
  
  PARX_change_dims("ACQ_slice_offset",slices);
  PARX_change_dims("ACQ_read_offset",slices);
  PARX_change_dims("ACQ_phase1_offset",slices);
  PARX_change_dims("ACQ_phase2_offset",slices);
  
  for(i=0;i<slices;i++)
  {
    ACQ_slice_offset[i]  = PVM_SliceOffset[i];
    ACQ_read_offset[i]   = PVM_ReadOffset[i];
    ACQ_phase1_offset[i] = PVM_Phase1Offset[i];
    ACQ_phase2_offset[i] = PVM_Phase2Offset[i];
  }
  
  ACQ_read_ext = (int)PVM_AntiAlias[0];
  
  PARX_change_dims("ACQ_slice_sepn", slices==1 ? 1 : slices-1);
  
  if( slices == 1 )
  {
    ACQ_slice_sepn[0] = 0.0;
  }
  else
  {
    for( i=1; i<slices;i++ )
    {
      ACQ_slice_sepn[i-1]=PVM_SliceOffset[i]-PVM_SliceOffset[i-1];
    }
  }
  
  ATB_SetAcqSliceSepn( PVM_SPackArrSliceDistance,
                       PVM_NSPacks );
  
  
  
  ATB_SetAcqPatientPosition();
  
  ATB_SetAcqExpType( Imaging );
  
  ACQ_n_t1_points = 1;
  
  if( ParxRelsParHasValue("ACQ_transmitter_coil") == No )
  {
    ACQ_transmitter_coil[0] = '\0';
  }
  
  if( ParxRelsParHasValue("ACQ_contrast_agent") == No )
  {
    ACQ_contrast_agent[0] = '\0';
  }
  
  if( ParxRelsParHasValue("ACQ_contrast") == No )
  {
    ACQ_contrast.volume = 0.0;
    ACQ_contrast.dose = 0.0;
    ACQ_contrast.route[0] = '\0';
    ACQ_contrast.start_time[0] = '\0';
    ACQ_contrast.stop_time[0] = '\0';
  }
  
  ParxRelsParRelations("ACQ_contrast_agent",Yes);
  
  ACQ_position_X = 0.0;
  ACQ_position_Y = 0.0;
  ACQ_position_Z = 0.0;

  PARX_change_dims("ACQ_temporal_delay",1);
  ACQ_temporal_delay[0] = 0.0;
  
  ACQ_RF_power = 0;
  
  ACQ_flipback = No;
  
  // initialize ACQ_n_echo_images ACQ_echo_descr
  //            ACQ_n_movie_frames ACQ_movie_descr
  ATB_ResetEchoDescr();
  ATB_ResetMovieDescr();

  SetDiffImageLabels(PVM_DwAoImages,
                     PVM_DwNDiffDir,
                     PVM_DwNDiffExpEach,
                     PVM_DwEffBval,
                     PVM_NRepetitions,
                     No);
  
  
  DB_MSG(("<--SetInfoParameters\n"));
  
}

void SetMachineParameters( void )
{
  DB_MSG(("-->SetMachineParameters\n"));

  /* setting of DIGMOD,DSPFIRM,AQ_mod done in frequency par setting routine */
 
  if( ParxRelsParHasValue("ACQ_word_size") == No )
  {
    ACQ_word_size = _32_BIT;
  }
  
  
  DE = DE < 6.0 ? 6.0: DE;
    
  PAPS = QP;
  
  ACQ_BF_enable = Yes;
  
  DB_MSG(("<--SetMachineParameters\n"));
}


void PrintTimingInfo(void)
{
  double te,tr;

  DB_MSG(("-->PrintTimingInfo\n"));

  te=(P[0])/2000.0+(D[4]+D[2]+D[3])*1000.0+PVM_DwModEchDel+PVM_EpiEchoDelay;
      


  tr = (P[0]/1000.0 + 0.024 + (D[0]+D[1]+D[2]+D[3]+D[4])*1000.0
	+ PVM_FatSupModuleTime
	+ PVM_DwModDur + PVM_EpiModuleTime-PVM_EpiEchoDelay)*NSLICES+PackDel;
  

  DB_MSG(("te: %f  soll: %f  diff %f\n",
	  te,EchoTime,te-EchoTime));

  DB_MSG(("tr: %f  soll: %f  diff %f\n",tr,PVM_RepetitionTime,
	  fabs(tr-PVM_RepetitionTime)));


  DB_MSG(("<--PrintTimingInfo\n"));
  
}

void SetDiffImageLabels(const int na0,
                        const int nd,
                        const int nbpd,
                        const double *bval,
                        const int nr,
                        YesNo EchoLoop)
{
  int ndiffexp;
  int i,j,k,l,tsl;
  char buffer[200];

  ndiffexp=na0+nd*nbpd;
  tsl = ndiffexp*nr;
  
  DB_MSG(("-->SetDiffImageLabels"));
  DB_MSG(("na0 = %d\nnd = %d\nnpbd= %d\n"
          "ndiffexp = %d\ntsl=%d\n"
          "nr=%d",
          na0,nd,nbpd,ndiffexp,tsl,nr));

  switch(EchoLoop)
  {
    default:
    case No:
      ACQ_n_echo_images = 1;
      ACQ_n_movie_frames = tsl;
      PARX_change_dims("ACQ_movie_descr",tsl,20);
      PARX_change_dims("ACQ_echo_descr",1,20);      
      for(l=0;l<nr;l++)
      {
        for(i=0;i<na0;i++)
        {
          sprintf(buffer,"A0 %d B %.0f",i+1,bval[i]);
          buffer[19]='\0';
          strncpy(ACQ_movie_descr[l*ndiffexp+i],buffer,20);
        }
        for(k=na0,i=0; i<nd ; i++)
        {
          for(j=0;j<nbpd;j++,k++)
          {
            sprintf(buffer,"Dir %d B %.0f",i+1,bval[k]);
            buffer[19]='\0';
            strncpy(ACQ_movie_descr[l*ndiffexp+k],buffer,20);
          }
        }
      }
      break;
    case Yes:
      ACQ_n_echo_images = tsl;
      ACQ_n_movie_frames = 1;
      PARX_change_dims("ACQ_movie_descr",1,20);
      PARX_change_dims("ACQ_echo_descr",tsl,20);      
      for(l=0;l<nr;l++)
      {
        for(i=0;i<na0;i++)
        {
          sprintf(buffer,"A0 %d B %.0f",i+1,bval[i]);
          buffer[19]='\0';
          strncpy(ACQ_echo_descr[l*ndiffexp+i],buffer,20);
        }
        
        for(k=na0,i=0; i<nd ; i++)
        {
          for(j=0;j<nbpd;j++,k++)
          {
            sprintf(buffer,"Dir %d B %.0f",i+1,bval[k]);
            buffer[19]='\0';
            strncpy(ACQ_echo_descr[l*ndiffexp+k],buffer,20);
          }
        }
      }
      break;
  }

}
