/****************************************************************
 *
 * $Source: /pv/CvsTree/pv/gen/src/prg/methods/DtiEpi/DtiEpi.c,v $
 *
 * Copyright (c) 1999-2005
 * Bruker BioSpin MRI GmbH
 * D-76275 Ettlingen, Germany
 *
 * All Rights Reserved
 *
 * $Id: DtiEpi.c,v 1.7.2.1 2009/07/08 08:54:31 dgem Exp $
 *
 ****************************************************************/

method DtiEpi_topup
{

/****************************************************************/
/*	TYPE DEFINITIONS					*/
/****************************************************************/

#include "ta_config.h" 

#include "bruktyp.h"
#include "acqumtyp.h"
#include "recotyp.h" 
#include "subjtyp.h" 
#include "acqutyp.h"
#include "methodTypes.h"
#include "Visu/VisuTypes.h"
#include "adjManagerDefs.h"
#include "adjManagerTypes.h"

/****************************************************************/
/*	PARAMETER DEFINITIONS					*/
/****************************************************************/


/*--------------------------------------------------------------*
 * Include external definitions for parameters in the classes
 * ACQU ACQP GO GS RECO RECI PREEMP CONFIG
 *--------------------------------------------------------------*/
#include "proto/acq_extern.h"
#include "proto/subj_extern.h"
#include "proto/visu_extern.h"

/*--------------------------------------------------------------*
 * Include references to the standard method parameters
 *--------------------------------------------------------------*/
#include "proto/pvm_extern.h"
#include "proto/adj_extern.h"

/*--------------------------------------------------------------*
 * Include references to any method specific parameters
 *--------------------------------------------------------------*/

#include "methodFormat.h"
#include "parsTypes.h"
#include "parsDefinition.h"

/****************************************************************/
/*	RE-DEFINITION OF RELATIONS				*/
/****************************************************************/

#include "callbackDefs.h"

/****************************************************************/
/*	PARAMETER CLASSES					*/
/****************************************************************/
#include "methodClassDefs.h"
#include "seqApiClassDefs.h"
#include "modulesClassDefs.h"
#include "parsLayout.h"

};

/****************************************************************/
/*	E N D   O F   F I L E					*/
/****************************************************************/
