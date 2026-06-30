/* =================================================================== */
/* Program   : vs.sas                                                  */
/* Purpose   : Create the SDTM Vital Signs (VS) domain from the        */
/*             CDISC Pilot raw vital signs data according to study     */
/*             mapping specifications.                                 */
/*                                                                     */
/* Study     : CDISCPILOT01 — Xanomeline vs Placebo, Alzheimer's Phase 3*/
/*                                                                     */
/* Inputs    : rawdata.vs                                              */
/* Outputs   : sdtm.vs                                                 */
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

/* Read XPT file */
libname xvs xport "&root./rawdata/vs.xpt";

data sdtm.vs;
	set xvs.vs;

	/* All variables are already correctly structured: */
	/* VSTESTCD: SYSBP DIABP PULSE HEIGHT WEIGHT TEMP */
	/* VSPOS: SUPINE or STANDING */
	/* VSBLFL: 'Y' on baseline records (VISITNUM = 3.0) */
	/* VSDTC: already ISO 8601 date string */
	/* VSSTRESN: the standardized numeric result — used as AVAL */
run;

/* QC: record count by test and visit */
proc freq data=sdtm.vs;
	tables VSTESTCD;
	title 'VS QC: Records per test type';
run;

/* QC: confirm baseline records look right */
proc print data=sdtm.vs(where=(VSBLFL='Y') obs=10);
	var USUBJID VSTESTCD VSPOS VSSTRESN VISIT VISITNUM VSDTC;
	title 'VS QC: Sample baseline records (VSBLFL=Y) — should all show
BASELINE visit';
run;

/* QC: check SYSBP range — expect roughly 100-200 mmHg */
proc means data=sdtm.vs(where=(VSTESTCD='SYSBP')) n mean std min max;
	var VSSTRESN;
	title 'VS QC: Systolic blood pressure summary';
run;