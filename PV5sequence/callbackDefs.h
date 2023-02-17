
/* digitizer parameter and bandwidth update */
relations PVM_DigHandler backbone;

/* inplane geometry */
relations PVM_InplaneGeometryHandler  InplaneGeometryRel;

/* slice geometry: */
relations PVM_SliceGeometryHandler    SliceGeometryRel;
/* preemphasis */
relations PVM_PreemphasisHandler backbone;


relations PVM_EffSWh                  EffSwRel;


/* modules */
relations PVM_EncodingHandler         backbone;
relations PVM_EpiHandler              backbone;
relations PVM_FatSupHandler           backbone;
relations PVM_TriggerHandler          backbone;
relations PVM_DiffusionHandler        backbone;
relations PVM_SatSlicesHandler        backbone;
relations PVM_TrajectoryHandler       backbone;



relations PVM_RepetitionTime          RepetitionTimeRel;
relations PVM_NAverages               AveragesRel;
relations PVM_NRepetitions            RepetitionsRel;
relations PVM_EchoTime                backbone;
relations PVM_MinEchoTime             backbone;

relations PVM_AcquisitionTime         backbone;
relations PVM_NucleiHandler           backbone; 
relations PVM_DeriveGains             DeriveGainsRel;

/* 
 * parameters that are used but not shown in editor
 * only the method may change these parameters, they
 * are redirected to the backbone routine.
 */

relations PVM_MinRepetitionTime       backbone;
relations PVM_NEchoImages             backbone;

relations PVM_ExcPulseAngle           ExcPulseAngleRelation;

/*
 * Redirect reconstruction relations
 */

relations RecoUserUpdate              DeriveReco;

/*
 * Redirect relation for visu creation
 */
relations VisuDerivePars             deriveVisu;

/*
 *  handle method specific adjustments
 */
relations PVM_AdjHandler HandleAdjustmentRequests;
/* react on parameter adjustments */
relations PVM_AdjResultHandler HandleAdjustmentResults;
