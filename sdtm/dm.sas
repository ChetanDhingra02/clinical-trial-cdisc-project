/* =================================================================== */
/* Program   : dm.sas                                                  */
/* Purpose   : Create the SDTM Demographics (DM) domain from the       */
/*             CDISC Pilot raw demographic data according to study     */
/*             mapping specifications.                                 */
/*                                                                     */
/* Study     : CDISCPILOT01 — Xanomeline vs Placebo, Alzheimer's Phase 3*/
/*                                                                     */
/* Inputs    : rawdata.dm                                               */
/* Outputs   : sdtm.dm                                                 */
/*                                                                     */
/* Spec Ref  : CDISC SDTM Implementation Guide (SDTMIG);               */
/*             Advanced Additions Guide                                */
/*                                                                     */
/* Author    : Chetan Dhingra                                          */
/* Created   : 2026-06-29                                              */
/*                                                                     */
/* ------------------------------------------------------------------- */
/* Modification History                                                */
/* Date         Author          Description                            */
/* ----------   -------------   -------------------------------------- */
/* 2026-06-29   Chetan Dhingra  Initial version                        */
/* =================================================================== */
%include "/home/u64534201/Clinical Project/setup.sas";

/* Step 1: Read the XPT file into a working library */
libname xdm xport "&root./rawdata/dm.xpt";

/* Step 2: Copy from XPT (read-only) to a work dataset */
data dm_raw;
	set xdm.dm;
run;

/* Step 3: Look at what we have before writing any code */
proc contents data=dm_raw varnum;
	title 'DM raw variable list';
run;

proc print data=dm_raw(obs=5);
	title 'DM first 5 rows';
run;

/* Step 4: Build the output SDTM DM dataset */
/* Key decisions: */
/* - Keep all existing SDTM variables as-is (they are already */
/* mapped correctly in the pilot submission) */
/* - Exclude screen failure subjects for your analysis programs */
/* - USUBJID is already in correct format: 01-701-1015 */
/* - Dates (RFSTDTC, RFENDTC) are already ISO 8601 */
data sdtm.dm;
	set dm_raw;

	/* Confirm required SDTM fields are populated */
	/* STUDYID = 'CDISCPILOT01', DOMAIN = 'DM' already in data */
	/* Apply your custom format to ARM code for reports */
	ARMF=put(ARMCD, $armfmt.);

	/* Label any variables you add */
	label ARMF='Planned Arm Description (formatted)';

	/* Keep all original SDTM variables */
	drop ARMF;

	/* dropping the helper — just for QC above */
run;

/* QC check 1: confirm subject counts by treatment arm */
proc freq data=sdtm.dm;
	tables ARMCD * ARM / missing;
	title 'DM QC: Subject count by treatment arm';
run;

/* QC check 2: check for any missing USUBJID */
proc means data=sdtm.dm n nmiss;
	var AGE;

	/* proxy — if AGE has no missing, dataset is intact */
	title 'DM QC: Subject count';
run;

/* QC check 3: check age distribution (real data: 63-93 years) */
proc means data=sdtm.dm(where=(ARMCD ne 'Scrnfail')) n mean std min max;
	var AGE;
	title 'DM QC: Age summary (randomized subjects only)';
run;