/****************************************************************
 *
 * $Source: /pv/CvsTree/pv/gen/src/prg/methods/DtiEpi/deriveVisu.c,v $
 *
 * Copyright (c) 2005-2008
 * Bruker BioSpin MRI GmbH
 * D-76275 Ettlingen, Germany
 *
 * All Rights Reserved
 *
 * $Id: deriveVisu.c,v 1.1.4.7 2010/03/05 13:38:52 anba Exp $
 *
 ****************************************************************/
static const char resid[] = "$Id: deriveVisu.c,v 1.1.4.7 2010/03/05 13:38:52 anba Exp $ (C) 2005-2008 Bruker BioSpin MRI GmbH";

#define DEBUG		0
#define DB_MODULE	1
#define DB_LINE_NR	1

/*:=INFO=:*******************************************************
 * Description :
 *   This file contains method dependant derivation of the 
 *   visu overlay values.
 *::=info=:******************************************************/

/****************************************************************/
/****************************************************************/
/*		I N T E R F A C E   S E C T I O N		*/
/****************************************************************/
/****************************************************************/

/****************************************************************/
/*		I N C L U D E   F I L E S			*/
/****************************************************************/

#include "machine.h"
/*--------------------------------------------------------------*
 * system include files...
 *--------------------------------------------------------------*/

/*--------------------------------------------------------------*
 * ParaVision include files...
 *--------------------------------------------------------------*/
#include "generated/VisuIds.h"

/*--------------------------------------------------------------*
 * local include files...
 *--------------------------------------------------------------*/
#include "method.h"

/****************************************************************/
/*		E X T E R N A L   F U N C T I O N S		*/
/****************************************************************/

/****************************************************************/
/*		E X T E R N A L   V A R I A B L E S		*/
/****************************************************************/

/****************************************************************/
/*		G L O B A L   V A R I A B L E S			*/
/****************************************************************/

/****************************************************************/
/****************************************************************/
/*	I M P L E M E N T A T I O N   S E C T I O N		*/
/****************************************************************/
/****************************************************************/

/****************************************************************/
/*		L O C A L   D E F I N I T I O N S		*/
/****************************************************************/

/****************************************************************/
/*	L O C A L   F U N C T I O N   P R O T O T Y P E S	*/
/*			forward references			*/
/****************************************************************/

/****************************************************************/
/*		L O C A L   V A R I A B L E S			*/
/****************************************************************/

/****************************************************************/
/*		G L O B A L   F U N C T I O N S			*/
/****************************************************************/


/*:=MPB=:=======================================================*
 *
 * Global Function: deriveVisu
 * Description:
 *	DTI dependant visu creation.
 * Interface:							*/
void 
deriveVisu(void)
/*:=MPE=:=======================================================*/
{
  DB_MSG (("Entered deriveVisu()"));

  /* Standard Visu Derivation */
  ParxRelsParRelations("VisuDerivePars", Yes);

  const int nrep = PVM_NRepetitions;
  const int ndiff = PVM_DwNDiffExp;

  /* Set name of Movie loop */
  PTB_VisuSetMovieLoopName("diffusion");

  if (1 < nrep)
  {
    /* Divide Movie loop into diffusion and cycles loop. */
    PTB_VisuInsertLoop(
      PV_IDL_CONSTANT(visuid_framegroup_MOVIE),
      PV_IDL_CONSTANT(visuid_framegroup_CYCLE),
      nrep, "repetitions");
    PTB_VisuDecreaseFGLen( PV_IDL_CONSTANT(visuid_framegroup_MOVIE), ndiff);

    char * comments = (char *)malloc(20*(MAX_OF(nrep, ndiff))*sizeof(char));

    for (int i = 0; i < ndiff; ++i)
      strcpy(&comments[i*20], ACQ_movie_descr[i]);

    PTB_VisuSetFGElementComment(
      PV_IDL_CONSTANT(visuid_framegroup_MOVIE), comments, ndiff, 20);

    for (int i = 0; i < nrep; ++i)
      sprintf(&comments[i*20], "R %d", i+1);

    PTB_VisuSetFGElementComment(
      PV_IDL_CONSTANT(visuid_framegroup_CYCLE), comments, nrep, 20);

    free(comments);
  }

  /* To support the correct derivation of visu files for Pv3 images
     the parameter must be tested whether they have a value.
  */
  if (ParxRelsParHasValue("PVM_EpiNEchoes"))
      VisuAcqEchoTrainLength = PVM_EpiNEchoes;

  if (ParxRelsParHasValue("SW_h") && 
      ParxRelsParHasValue("PVM_EncMatrix") && 0.0 < SW_h)
	  VisuAcqPixelBandwidth = SW_h/(double)PVM_EncMatrix[0];

  DB_MSG (("Leave deriveVisu()"));
}


/****************************************************************/
/*		L O C A L   F U N C T I O N S			*/
/****************************************************************/


/****************************************************************/
/*		E N D   O F   F I L E				*/
/****************************************************************/
