/* =================================================================== */
/* Program   : ae.sas                                                  */
/* Purpose   : Create the SDTM Adverse Events (AE) domain from the     */
/*             CDISC Pilot raw adverse events data according to study  */
/*             mapping specifications.                                 */
/*                                                                     */
/* Study     : CDISCPILOT01 — Xanomeline vs Placebo, Alzheimer's Phase 3*/
/*                                                                     */
/* Inputs    : rawdata.ae                                              */
/* Outputs   : sdtm.ae                                                 */
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
libname xae xport "&root./rawdata/ae.xpt";

data sdtm.ae;
	set xae.ae;

	/* Key AE variables already present: */
	/* AETERM: verbatim term as reported */
	/* AEDECOD: MedDRA preferred term */
	/* AEBODSYS: MedDRA system organ class */
	/* AESEV: MILD / MODERATE / SEVERE */
	/* AESER: Y or N (only 3 Y records in this dataset) */
	/* AEREL: PROBABLE / REMOTE / POSSIBLE / NONE */
	/* AESTDTC: start date (ISO 8601, some may be partial YYYY-MM)*/
	/* AEENDTC: end date (may be blank if AE not resolved) */
run;

/* QC: severity distribution */
proc freq data=sdtm.ae;
	tables AESEV AESER AEREL;
	title 'AE QC: Severity and seriousness distribution';
run;

/* QC: top 10 body systems */
proc freq data=sdtm.ae order=freq;
	tables AEBODSYS;
	title 'AE QC: AE count by System Organ Class';
run;