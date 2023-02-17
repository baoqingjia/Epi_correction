#define DEBUG		0
#define DB_MODULE	0
#define DB_LINE_NR	0



#include "method.h"


/*------------------------------------------------------------
 *
 * Definition of group initialiszation and update routines
 *
 *----------------------------------------------------------*/

void SliceSelectionParsVisibility(YesNo showAllPars)
{
  const char *const editable = "ExcSliceRephTime";      
                               

  const char *const nonedit  = "ExcSliceGrad,"	       
                               "SliceGradStabTime,"
	 		       "ExcSliceGradLim,"     
	 		       "ExcSliceRephGrad,"    
	 		       "ExcSliceRephGradLim";

  DB_MSG(("-->SliceSelectionParsVisibility\n"));

  ParxRelsMakeEditable(editable);
  ParxRelsShowInEditor(editable);
  ParxRelsShowInFile(editable);




  switch(showAllPars)
  {
    default:
    case No:
      ParxRelsHideInEditor(nonedit);
      break;
    case Yes:
      ParxRelsShowInEditor(nonedit);
  }

  ParxRelsMakeNonEditable(nonedit);
  ParxRelsHideInFile(nonedit);

  DB_MSG(("<--SliceSelectionParsVisibility\n"));
  return;
}


void InitSliceSelection(YesNo showAllPars)
{
  DB_MSG(("-->InitSliceSelection\n"));

  SliceGradStabTimeRange();
  ExcSliceRephTimeRange();
  ExcSliceGradRange();
  ExcSliceGradLimRange();
  ExcSliceRephGradRange();
  ExcSliceRephGradLimRange();


  SliceSelectionParsVisibility(showAllPars);

  DB_MSG(("<--InitSliceSelection\n"));
}

double SliceSelectionLimits(PVM_RF_PULSE_TYPE *const excPulse,
			    const double bwscale,
			    const double gradStabTime,
			    const double gradCalConst,
			    double *const sliceRatio)

{
  
  double  minSlThk;
  double  sliceIntegral,rephIntegral;
  double  riseT;
  
  DB_MSG(("-->SliceSelectionLimits\n"));
  

  /*
   *  range check of arguments
   */

  STB_CheckRFPulse(excPulse);


  SliceGradStabTime = gradStabTime;
  SliceGradStabTimeRange();
  

  if(gradCalConst <= 0.0)
  {
    UT_ReportError("SliceSelectionLimits: illegal value "
		   "of argument 4\n");
    return -1.0;

  }



  /*
   * step 1: calculate exc slice integrals and minSlThk
   */
 
  riseT = CFG_GradientRiseTime();
  


  ExcSliceRephTimeRange();
  ExcSliceGradLimRange();
  ExcSliceRephGradLimRange();

  sliceIntegral = 
    excPulse->Length              *
    excPulse->TrimRephase/100.0   *
    excPulse->RephaseFactor/100.0 +/* dephasing of excPulse */
    + riseT/2.0    ;               /* dephasing of ramp down*/

  rephIntegral  = ExcSliceRephTime - riseT; 

  *sliceRatio    = sliceIntegral / rephIntegral;

  minSlThk = MRT_MinSliceThickness(excPulse->Bandwidth*bwscale/100,
				   *sliceRatio,
				   ExcSliceGradLim,
				   ExcSliceRephGradLim,
				   gradCalConst);



		
  DB_MSG(("<--SliceSelectionLimits\n"));
  return minSlThk;
}

YesNo UpdateSliceSelectionGradients(const double slthk,
				    const double sliceRatio,
				    const double excPulseBW,
				    double gradCalConst)
{
  DB_MSG(("-->UpdateSliceSelectionGradients\n"));

  /*
   *  range check of arguments
   */

  if(slthk <= 0.0)
  {
    UT_ReportError("UpdateSliceSelectionGradients: "
		   "Illegal value of argument 1\n");
    return No;

  }


  if(excPulseBW < 0.0)
  {
    UT_ReportError("UpdateSliceSelectionGradients: "
		   "Illegal value of argument 3\n");
    return No;

  }

    
  if(gradCalConst <= 0.0)
  {
    UT_ReportError("UpdateSliceSelectionGradients: "
		   "Illegal value of argument 5\n");
    return No;

  }

  /*
   * update of slice spoiling gradients
   */

 
  ExcSliceGrad     = MRT_SliceGrad(excPulseBW,slthk,gradCalConst);
  ExcSliceRephGrad = sliceRatio * ExcSliceGrad;


  if((ExcSliceGrad - ExcSliceGradLim)>1.0e-3)
  {
    UT_ReportError("UpdateSliceSelectionGradients: "
		   "ExcSliceGrad exceeded maximum!\n");
    return No;

  }

  ExcSliceGrad = MIN_OF(ExcSliceGrad,ExcSliceGradLim);


  if((ExcSliceRephGrad - ExcSliceRephGradLim)>1.0e-3)
  {
    UT_ReportError("UpdateSliceSelectionGradients: "
		   "ExcSliceRephGrad exceeded maximum!\n");
    return No;

  }

  ExcSliceRephGrad = MIN_OF(ExcSliceRephGrad,ExcSliceRephGradLim);

  DB_MSG(("-->UpdateSliceSelectionGradients\n"));
  return Yes;
}


/*------------------------------------------------------------
 *
 * Definition of range checking routines and default relations
 *
 *-----------------------------------------------------------*/


void ExcSliceRephTimeRange(void)
{
  double min;
  DB_MSG(("-->ExcSliceRephTimeRange\n"));

  min = 2*CFG_GradientRiseTime() + 
        CFG_InterGradientWaitTime();

  if(ParxRelsParHasValue("ExcSliceRephTime")==No)
  {
    ExcSliceRephTime = MAX_OF(1.5,min);
  }
  else
  {
    ExcSliceRephTime = MAX_OF(ExcSliceRephTime,min);
  }


  DB_MSG(("<--ExcSliceRephTimeRange\n"));
  return;
}	  

void ExcSliceRephTimeRel(void)	  
{
  DB_MSG(("-->ExcSliceRephTimeRel\n"));

  ExcSliceRephTimeRange();
  backbone();
 
  DB_MSG(("<--ExcSliceRephTimeRel\n"));
  return;
}	  




void ExcSliceGradRange(void)		  
{
  DB_MSG(("-->ExcSliceGradRange\n"));

  if(ParxRelsParHasValue("ExcSliceGrad") == No)
  {
    ExcSliceGrad = 1.0e-6;
  }
  else
  {
    ExcSliceGrad = MAX_OF(1.0e-6,ExcSliceGrad);
    ExcSliceGrad = MIN_OF(100.0,ExcSliceGrad);
  }

  DB_MSG(("<--ExcSliceGradRange\n"));
  return;
}	  

void ExcSliceGradRel(void)		  
{
  DB_MSG(("-->ExcSliceGradRel\n"));

  ExcSliceGradRange();
  backbone();

  DB_MSG(("<--ExcSliceGradRel\n"));
  return;
}	  

void ExcSliceGradLimRange(void)	  
{
  DB_MSG(("-->ExcSliceGradLimRange\n"));

  if(ParxRelsParHasValue("ExcSliceGradLim") == No)
  {
    ExcSliceGradLim = 1.0e-6;
  }
  else
  {
    ExcSliceGradLim = MAX_OF(1.0e-6,ExcSliceGradLim);
    ExcSliceGradLim = MIN_OF(100.0,ExcSliceGradLim);
  }



  DB_MSG(("<--ExcSliceGradLimRange\n"));
  return;
}	  

void ExcSliceGradLimRel(void)	  
{
  DB_MSG(("-->ExcSliceGradLimRel\n"));

  ExcSliceGradLimRange();
  backbone();

  DB_MSG(("<--ExcSliceGradLimRel\n"));
  return;
}	  

void ExcSliceRephGradRange(void)	  
{
  DB_MSG(("-->ExcSliceRephGradRange\n"));

  if(ParxRelsParHasValue("ExcSliceRephGrad") == No)
  {
    ExcSliceRephGrad = 1.0e-6;
  }
  else
  {
    ExcSliceRephGrad = MAX_OF(1.0e-6,ExcSliceRephGrad);
    ExcSliceRephGrad = MIN_OF(100.0,ExcSliceRephGrad);
  }

  DB_MSG(("<--ExcSliceRephGradRange\n"));
  return;
}	  

void ExcSliceRephGradRel(void)	  
{
  DB_MSG(("-->ExcSliceRephGradRel\n"));

  ExcSliceRephGradRange();
  backbone();

  DB_MSG(("<--ExcSliceRephGradRel\n"));
  return;
}	  

void ExcSliceRephGradLimRange(void)	  
{
  DB_MSG(("-->ExcSliceRephGradLimRange\n"));

  if(ParxRelsParHasValue("ExcSliceRephGradLim") == No)
  {
    ExcSliceRephGradLim = 1.0e-6;
  }
  else
  {
    ExcSliceRephGradLim = MAX_OF(1.0e-6,ExcSliceRephGradLim);
    ExcSliceRephGradLim = MIN_OF(100.0,ExcSliceRephGradLim);
  }

  DB_MSG(("<--ExcSliceRephGradLimRange\n"));
  return;
}	  

void ExcSliceRephGradLimRel(void)	  
{
  DB_MSG(("-->ExcSliceRephGradLimRel\n"));

  ExcSliceRephGradLimRange();
  backbone();

  DB_MSG(("<--ExcSliceRephGradLimRel\n"));
  return;
}	  

	  


void SliceGradStabTimeRange(void)
{
  DB_MSG(("-->SliceGradStabTimeRange\n"));

  if(ParxRelsParHasValue("SliceGradStabTime") == No)
  {
    SliceGradStabTime = 0.0;
  }
  else
  {
    SliceGradStabTime = MAX_OF(SliceGradStabTime,0.0);
  }

  DB_MSG(("<--SliceGradStabTimeRange\n"));
  return;
}

void SliceGradStabTimeRel(void)
{
  DB_MSG(("-->SliceGradStabTimeRel\n"));

  SliceGradStabTimeRange();
  backbone();

  DB_MSG(("<--SliceGradStabTimeRel\n"));


}

