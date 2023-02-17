#define DEBUG		0
#define DB_MODULE	0
#define DB_LINE_NR	0



#include "method.h"

/*------------------------------------------------------
 * routines for parameter group initialization and 
 * update
 *-----------------------------------------------------*/

void Phase3DEncodingParsVisibility(YesNo visible)
{
  const char *const editable = \
    "Phase3DGradDur";
  const char *const nonedit  = \
    "Phase3DGrad,"
    "Phase3DGradLim";

    
  DB_MSG(("-->Phase3DEncodingParsVisibility\n"));

  ParxRelsShowInEditor(editable);
  ParxRelsShowInFile(editable);

  switch(visible)
  {
    default:
    case No:
      ParxRelsHideInEditor(nonedit);
      break;
    case Yes:
      ParxRelsShowInEditor(nonedit);

  }

  /*
   *  these parameters are derived, their value need not to
   *  be edited nor to be stored on disk for protocols
   */

  ParxRelsMakeNonEditable(nonedit);
  ParxRelsHideInFile(nonedit);



  DB_MSG(("-->Phase3DEncodingParsVisibility\n"));

}



void InitPhase3DEncoding(YesNo visible)
{
  DB_MSG(("-->Phase3DEncoding\n"));

  Phase3DGradDurRange(0.0);
  Phase3DGradRange();
  Phase3DGradLimRange();

  Phase3DEncodingParsVisibility(visible);

  DB_MSG(("<--Phase3DEncoding\n"));
  return;
}


double Phase3DEncodingLimits( int dpoints,
			      double gradStabTime,
			      double gradCalConst)
{

  double phaseInteg;
  
  DB_MSG(("-->Phase3DEncodingLimits\n"));

  /*
   *  range check of arguments
   */


  if(dpoints < CFG_MinImagingSpatialMatrixSize() ||
     dpoints > CFG_MaxImagingSpatialMatrixSize())
  {
    UT_ReportError("Phase3DEncodingLimits: "
		   "Illegal value of argument 1\n");
    return 0.0;

  }


  if(gradCalConst <= 0.0)
  {
    UT_ReportError("Phase3DEncodingLimits: "
		   "Illegal value of argument 2\n");
    return 0.0;
  }




  
  Phase3DGradDurRange(gradStabTime);
  Phase3DGradLimRange();


  phaseInteg = Phase3DGradDur - CFG_GradientRiseTime();

  DB_MSG(("<--Phase3DEncodingLimits\n"));

  return MRT_PhaseFov(phaseInteg,dpoints,Phase3DGradLim,gradCalConst);

}

void UpdatePhase3DGradients(int dpoints,
			    double fov,
			    double gradCalConst)
{
  DB_MSG(("-->UpdatePhase3DGradients\n"));
    
  if(dpoints < CFG_MinImagingSpatialMatrixSize() ||
     dpoints > CFG_MaxImagingSpatialMatrixSize())
  {
    UT_ReportError("UpdatePhase3DGradients: "
		   "Illegal value of argument 1\n");
    return;

  }


  if(fov <= 0.0)
  {
    UT_ReportError("UpdatePhase3DGradients: "
		   "Illegal value of argument 2\n");
    return;
  }

 
  if(gradCalConst <= 0.0)
  {
    UT_ReportError("UpdatePhase3DGradients: "
		   "Illegal value of argument 3\n");
    return;
  }

  Phase3DGrad = MRT_PhaseGrad( Phase3DGradDur - CFG_GradientRiseTime(),
			       dpoints,
			       fov,
			       gradCalConst );

  if((Phase3DGrad - Phase3DGradLim) > 1.0e-3)
  {
    UT_ReportError("UpdatePhase3DGradients: "
		   "Phase3DGrad exceeds its limits\n");

  }
 
  Phase3DGrad = MIN_OF(Phase3DGrad,Phase3DGradLim);

  DB_MSG(("<--UpdatePhase3DGradients\n"));

  return;

}



/*-----------------------------------------------
 * Range checking and default relation routines
 *----------------------------------------------*/



void Phase3DGradDurRange(double gradStabTime)
{
  double min;

  DB_MSG(("-->Phase3DGradDurRange\n"));

  gradStabTime = MAX_OF(0.0,gradStabTime);


  min = 2*CFG_GradientRiseTime()    + gradStabTime +
        CFG_InterGradientWaitTime();

  if(ParxRelsParHasValue("Phase3DGradDur")==No)
  {
    Phase3DGradDur = min;

  }
  else
  {
    Phase3DGradDur = MAX_OF(min,Phase3DGradDur);
  }


  DB_MSG(("<--Phase3DGradDurRange\n"));
  return;
}

void Phase3DGradDurRel(void)
{
  DB_MSG(("-->Phase3DGradDurRel\n"));

  Phase3DGradDurRange(0.0);
  backbone();

  DB_MSG(("<--Phase3DGradDurRel\n"));

}

void Phase3DGradLimRange(void)
{
  DB_MSG(("-->Phase3DGradLimRange\n"));

  if(ParxRelsParHasValue("Phase3DGradLim")==No)
  {
    Phase3DGradLim = 100.0;
  }
  else
  {
    Phase3DGradLim = MAX_OF(MIN_OF(100.0,Phase3DGradLim),1e-6);
  }

  DB_MSG(("<--Phase3DGradLimRange\n"));
  return;
}

void Phase3DGradLimRel(void)
{
  DB_MSG(("-->Phase3DGradLimRel\n"));

  Phase3DGradLimRange();
  backbone();

  DB_MSG(("<--Phase3DGradLimRel\n"));

}

void Phase3DGradRange(void)
{
  DB_MSG(("-->Phase3DGradRange\n"));

  if(ParxRelsParHasValue("Phase3DGrad")==No)
  {
    Phase3DGrad = 100.0;
  }
  else
  {
    Phase3DGrad = MAX_OF(MIN_OF(100.0,Phase3DGrad),1e-6);
  }

  DB_MSG(("<--Phase3DGradRange\n"));
  return;
}

void Phase3DGradRel(void)
{
  DB_MSG(("-->Phase3DGradRel\n"));

  Phase3DGradRange();
  backbone();

  DB_MSG(("<--Phase3DGradRel\n"));

}

