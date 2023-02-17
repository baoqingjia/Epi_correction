/****************************************************************
 *
 * $Source: /pv/CvsTree/pv/gen/src/prg/methods/DtiEpi/RFPulses.c,v $
 *
 * Copyright (c) 2003
 * Bruker BioSpin MRI GmbH
 * D-76275 Ettlingen, Germany
 *
 * All Rights Reserved
 *
 *
 * $Id: RFPulses.c,v 1.4.2.2 2007/12/17 15:29:24 sako Exp $
 *
 ****************************************************************/


static const char resid[] = "$Id: RFPulses.c,v 1.4.2.2 2007/12/17 15:29:24 sako Exp $ (C) 2003 Bruker BioSpin MRI GmbH";

#define DEBUG		0
#define DB_MODULE	0
#define DB_LINE_NR	0



#include "method.h"


void BwScaleRange(void)
{
  DB_MSG(("-->BwScaleRange\n"));

  if(ParxRelsParHasValue("BwScale")==No)
  {
    BwScale=100.0;
  }
  else
  {
    BwScale=MAX_OF(MIN_OF(150,BwScale),50.0);
  }


  DB_MSG(("<--BwScaleRange\n"));
  return;
}

void BwScaleRel(void)
{
  DB_MSG(("-->BwScaleRel\n"));
  BwScaleRange();
  backbone();
  DB_MSG(("<--BwScaleRel\n"));
  return;
}

void InitRFPulses(void)
{
  DB_MSG(("-->InitRFPulses\n"));

  BwScaleRange();
  ExcPulseRange();
  DeriveGainsRange();
  STB_InitExcPulseEnum("ExcPulseEnum");

  DB_MSG(("<--InitRFPulses\n"));

  return;
}


YesNo UpdateRFPulses(YesNo deriveGains,char *nucleus)
{
  YesNo referenceAvailable;
  double referenceAttenuation=30;

  DB_MSG(("-->UpdateRFPulses\n"));
  
  if(deriveGains == Yes)
    referenceAvailable =
      STB_GetRefAtt(1,nucleus,&referenceAttenuation);
  else
    referenceAvailable = No;
  
  STB_UpdateRFPulse("ExcPulse",
		    &ExcPulse,
		    referenceAvailable,
		    referenceAttenuation);
  
  STB_UpdateExcPulseEnum("ExcPulseEnum",
			 &ExcPulseEnum,
			 ExcPulse.Filename,
			 ExcPulse.Classification);
  
  BwScaleRange();

  DB_MSG(("<--UpdateRFPulses\n"));

  return referenceAvailable;

}




void ExcPulseEnumRel(void)
{
  DB_MSG(("-->ExcPulsesEnumRel\n"));
  
  /* set the name and clasification of ExcPulse: */

  STB_UpdateExcPulseName("ExcPulseEnum",
			 &ExcPulseEnum,
			 ExcPulse.Filename,
			 &ExcPulse.Classification);
  
  /* call the method relations */
  backbone();
  
  DB_MSG(("<--ExcPulseEnumRel\n"));                                       
}



void ExcPulseRange(void)
{
  DB_MSG(("-->ExcPulseRange\n"));
  
  if(ParxRelsParHasValue("ExcPulse") == No)
  {
    STB_InitRFPulse(&ExcPulse,
		    "hermite.exc",
		    1.0,
		    90.0);
  }

  /* allowed clasification */
  
  switch(ExcPulse.Classification)
  {
    default:
      
      ExcPulse.Classification = LIB_EXCITATION;
      break;
    case LIB_EXCITATION:
    case PVM_EXCITATION:
    case USER_PULSE:
      break;
  }

  /* allowed angle for this pulse */
  
  ExcPulse.FlipAngle = MIN_OF(90.0,ExcPulse.FlipAngle);
  
  
  /* general verifiation of all pulse atributes  */
  
  STB_CheckRFPulse(&ExcPulse);
  
  DB_MSG(("<--ExcPulseRange\n"));
  
}




void ExcPulseRel(void)
{
  DB_MSG(("-->ExcPulseRel\n"));
  
  /*
   * Tell the request handling system that the parameter
   * ExcPulse has been edited 
   */
  
  UT_SetRequest("ExcPulse");
  
  /* Check the values of ExcPulse */
  
  ExcPulseRange();
  
  /* 
   * call the backbone; further handling will take place there
   * (by means of STB_UpdateRFPulse)  
   */
  
  backbone();
  
  DB_MSG(("<--ExcPulseRel\n"));
}




void DeriveGainsRange(void)
{
  DB_MSG(("-->DeriveGainsRange\n"));

  if(ParxRelsParHasValue("PVM_DeriveGains")==No)
  {
    PVM_DeriveGains = Yes;
  }
  else
  {
    switch(PVM_DeriveGains)
    {
    case No:
      break;
    default:
      PVM_DeriveGains = Yes;
    case Yes:
      break;
    }
  }


  DB_MSG(("<--DeriveGainsRange\n"));
  return;
}

void DeriveGainsRel(void)
{
  DB_MSG(("-->DeriveGainsRel\n"));

  DeriveGainsRange();
  backbone();

  DB_MSG(("<--DeriveGainsRel\n"));
  return;
}
