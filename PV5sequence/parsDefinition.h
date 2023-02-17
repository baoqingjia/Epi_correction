/****************************************************************
 *
 * $Source: /pv/CvsTree/pv/gen/src/prg/methods/DtiEpi/parsDefinition.h,v $
 *
 * Copyright (c) 2001-2003
 * Bruker BioSpin MRI GmbH
 * D-76275 Ettlingen, Germany
 *
 * All Rights Reserved
 *
 * $Id: parsDefinition.h,v 1.7.2.4 2009/10/23 09:24:29 dgem Exp $
 *
 ****************************************************************/



/****************************************************************/
/* INCLUDE FILES						*/
/****************************************************************/

#include "Phase3DPars.h"
#include "SliceSelPars.h"
#include "RFPulsePars.h"

/* adjustment interface */
int parameter {relations AdjustmentCounterRels;} AdjustmentCounter;

double parameter OneRepTime;

int parameter 
{
  display_name "Number of Segments";
  relations NSegmentsRels;
} NSegments;

YesNo parameter
{
  display_name "Show Noneditable Pars";
  relations ShowAllParsRel;
}ShowAllPars;

double parameter
{
  display_name "Gradient Stabilization Time";
  relations GradStabTimeRel;
  units "ms";
  format "%f";
}GradStabTime;





/*
 *  parameters to pass information between different 
 *  routines. Since only the method may change their value,
 *  they are redirected to the backbone routine.
 */

double parameter
{
  relations backbone;
} MinTE1;

double parameter
{
  relations backbone;
}MinTE2;



double parameter
{
  display_name "Echo Time";
  units "ms";
  format "%.2f";
  relations EchoTimeRel;
} EchoTime;

double parameter
{
  display_name "Delay Between Volumes";
  format "%.2f";
  units "ms";
  relations PackDelRel;
} PackDel;


int parameter 
{
  display_name "Dummy Scans";
  relations backbone;
} NDummyScans;



char parameter
{
  display_name "Fit Function Name:";
  relations FitFunctionNameRel;
}FitFunctionName[32];


double parameter
{
  display_name "Min. Prep. Repetition Time";
  relations MinPrepRepTimeRel;
  units "ms";
  format "%.3f";
}MinPrepRepTime;


YesNo parameter
{
  display_name "Topup Epi";
  relations backbone;
}TopUp;
int parameter topupc;
int parameter RealRepeat;


/****************************************************************/
/*	E N D   O F   F I L E					*/
/****************************************************************/

