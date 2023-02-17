/*
 *******************************************************************
 *
 * $Source: /bscl/CvsTree/bscl/gen/config/proto.head,v $
 *
 * Copyright (c) 1995
 * BRUKER ANALYTISCHE MESSTECHNIK GMBH
 * D-76287 Rheinstetten, Germany
 *
 * All Rights Reserved
 *
 *
 * $State: Exp $
 *
 *******************************************************************
 */

#ifndef _P_
#	if defined(HAS_PROTO) || defined(__STDC__) || defined(__cplusplus)
#		define _P_(s) s
#	else
#		define _P_(s) ()
#	endif
#endif

/* /opt/PV5.1/prog/parx/pub/DtiEpi_topup/initMeth.c */
void initMeth _P_((void));
/* /opt/PV5.1/prog/parx/pub/DtiEpi_topup/loadMeth.c */
void loadMeth _P_((const char *));
/* /opt/PV5.1/prog/parx/pub/DtiEpi_topup/SliceSel.c */
void SliceSelectionParsVisibility _P_((YesNo));
void InitSliceSelection _P_((YesNo));
double SliceSelectionLimits _P_((PVM_RF_PULSE_TYPE *const , const double, const double, const double, double *const ));
YesNo UpdateSliceSelectionGradients _P_((const double, const double, const double, double));
void ExcSliceRephTimeRange _P_((void));
void ExcSliceRephTimeRel _P_((void));
void ExcSliceGradRange _P_((void));
void ExcSliceGradRel _P_((void));
void ExcSliceGradLimRange _P_((void));
void ExcSliceGradLimRel _P_((void));
void ExcSliceRephGradRange _P_((void));
void ExcSliceRephGradRel _P_((void));
void ExcSliceRephGradLimRange _P_((void));
void ExcSliceRephGradLimRel _P_((void));
void SliceGradStabTimeRange _P_((void));
void SliceGradStabTimeRel _P_((void));
/* /opt/PV5.1/prog/parx/pub/DtiEpi_topup/Phase3D.c */
void Phase3DEncodingParsVisibility _P_((YesNo));
void InitPhase3DEncoding _P_((YesNo));
double Phase3DEncodingLimits _P_((int, double, double));
void UpdatePhase3DGradients _P_((int, double, double));
void Phase3DGradDurRange _P_((double));
void Phase3DGradDurRel _P_((void));
void Phase3DGradLimRange _P_((void));
void Phase3DGradLimRel _P_((void));
void Phase3DGradRange _P_((void));
void Phase3DGradRel _P_((void));
/* /opt/PV5.1/prog/parx/pub/DtiEpi_topup/RFPulses.c */
void BwScaleRange _P_((void));
void BwScaleRel _P_((void));
void InitRFPulses _P_((void));
YesNo UpdateRFPulses _P_((YesNo, char *));
void ExcPulseEnumRel _P_((void));
void ExcPulseRange _P_((void));
void ExcPulseRel _P_((void));
void DeriveGainsRange _P_((void));
void DeriveGainsRel _P_((void));
/* /opt/PV5.1/prog/parx/pub/DtiEpi_topup/parsRelations.c */
void backbone _P_((void));
double CalcEchoDelay _P_((void));
void UpdateEchoTime _P_((double));
void UpdateRepetitionTime _P_((void));
void LocalFrequencyOffsetRels _P_((void));
void InplaneGeometryRel _P_((void));
void SliceGeometryRel _P_((void));
void ShowAllParsRange _P_((void));
void ShowAllParsRel _P_((void));
void RepetitionTimeRange _P_((void));
void RepetitionTimeRel _P_((void));
void AveragesRange _P_((void));
void AveragesRel _P_((void));
void RepetitionsRange _P_((void));
void RepetitionsRel _P_((void));
void EchoTimeRange _P_((void));
void EchoTimeRel _P_((void));
void GradStabTimeRange _P_((void));
void GradStabTimeRel _P_((void));
void ExcPulseAngleRelation _P_((void));
void EffSwRange _P_((void));
void EffSwRel _P_((void));
void PackDelRange _P_((void));
void PackDelRel _P_((void));
void InitDs _P_((void));
void HandleDs _P_((int));
void FitFunctionNameRange _P_((void));
void FitFunctionNameRel _P_((void));
void ConstrainReadOffset _P_((void));
void MinPrepRepTimeRange _P_((void));
void MinPrepRepTimeRel _P_((void));
void NSegmentsRels _P_((void));
void NSegmentsRange _P_((void));
/* /opt/PV5.1/prog/parx/pub/DtiEpi_topup/BaseLevelRelations.c */
void SetBaseLevelParam _P_((void));
void SetBasicParameters _P_((void));
void SetFrequencyParameters _P_((void));
void SetGradientParameters _P_((void));
void SetPpgParameters _P_((void));
void SetInfoParameters _P_((void));
void SetMachineParameters _P_((void));
void PrintTimingInfo _P_((void));
void SetDiffImageLabels _P_((const int, const int, const int, const double *, const int, YesNo));
/* /opt/PV5.1/prog/parx/pub/DtiEpi_topup/RecoRelations.c */
void SetRecoParam _P_((int));
void DeriveReco _P_((void));
int PowerOfTwo _P_((int));
/* /opt/PV5.1/prog/parx/pub/DtiEpi_topup/deriveVisu.c */
void deriveVisu _P_((void));
/* /opt/PV5.1/prog/parx/pub/DtiEpi_topup/adjust.c */
void SetAdjustmentRequests _P_((void));
void HandleAdjustmentRequests _P_((void));
void AdjustmentCounterRels _P_((void));
void HandleAdjustmentResults _P_((void));
