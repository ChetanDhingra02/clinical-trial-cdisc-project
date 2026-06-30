/* =================================================================== */
/* Program   : advs.sas                                                */
/* Purpose   : Create the ADaM Vital Signs Analysis Dataset (ADVS)     */
/*             by deriving analysis variables from the SDTM VS domain  */
/*             for longitudinal vital signs analyses.                  */
/*                                                                     */
/* Study     : CDISCPILOT01 — Xanomeline vs Placebo, Alzheimer's Phase 3*/
/*                                                                     */
/* Inputs    : sdtm.vs, adam.adsl                                      */
/* Outputs   : adam.advs                                               */
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

/* Step 1: Sort both input datasets */
proc sort data=sdtm.vs;
	by USUBJID;
run;

proc sort data=adam.adsl;
	by USUBJID;
run;

/* Step 2: Merge VS with ADSL to add treatment and dates */
/* In the real ADVS, treatment variable is TRTP (not TRT01P) */
data advs_prep;
	merge sdtm.vs (in=inv) adam.adsl (keep=USUBJID TRT01P TRT01PN SAFFL TRTSDT 
		TRTEDT rename=(TRT01P=TRTP TRT01PN=TRTPN));
	by USUBJID;

	if inv;

	/* Keep only VS records that have a matching subject */
	/* AVAL: the analysis value — maps directly from VSSTRESN */
	AVAL=VSSTRESN;

	/* PARAMCD and PARAM: same as VSTESTCD and VSTEST */
	PARAMCD=VSTESTCD;
	PARAM=VSTEST;

	/* PARAMN: numeric order for sorting in tables */
	PARAMN=.;

	if VSTESTCD='SYSBP' then
		PARAMN=1;

	if VSTESTCD='DIABP' then
		PARAMN=2;

	if VSTESTCD='PULSE' then
		PARAMN=3;

	if VSTESTCD='WEIGHT' then
		PARAMN=4;

	if VSTESTCD='HEIGHT' then
		PARAMN=5;

	if VSTESTCD='TEMP' then
		PARAMN=6;

	/* AVISIT and AVISITN: analysis visit */
	AVISIT=propcase(VISIT);

	/* Convert 'WEEK 2' to 'Week 2' */
	AVISITN=VISITNUM;

	/* ADT: analysis date as a numeric SAS date */
	ADT=input(VSDTC, yymmdd10.);
	format ADT yymmdd10.;

	/* ADY: analysis day relative to treatment start */
	if ADT ne . and TRTSDT ne . then
		ADY=ADT - TRTSDT + (ADT >=TRTSDT);

	/* ABLFL: flag baseline records */
	/* Baseline = records where VSBLFL = 'Y' in the raw VS data */
	ABLFL=' ';

	if VSBLFL='Y' then
		ABLFL='Y';

	/* ATPT: timepoint description */
	ATPT=VSTPT;
	ATPTN=VSTPTNUM;
run;

/* Step 3: Extract baseline values per subject per parameter */
/* Use SUPINE position baseline for primary analysis */
/* (The real ADVS uses the last pre-treatment SUPINE reading) */
data baseline_vals;
	set advs_prep;
	where ABLFL='Y' and VSPOS='SUPINE';
	BASE=AVAL;
	keep USUBJID PARAMCD BASE;
run;

/* Handle cases where a subject has multiple baseline readings */
/* (multiple readings at BASELINE visit) — keep the last one */
proc sort data=baseline_vals nodupkey;
	by USUBJID PARAMCD;
run;

/* Step 4: Merge baseline back and derive CHG */
proc sort data=advs_prep;
	by USUBJID PARAMCD;
run;

data adam.advs;
	merge advs_prep (in=inall) baseline_vals;
	by USUBJID PARAMCD;

	if inall;

	/* CHG: change from baseline — only for post-baseline records */
	if ABLFL ne 'Y' and BASE ne . and AVAL ne . then
		CHG=AVAL - BASE;

	/* PCHG: percent change from baseline */
	if BASE ne 0 and BASE ne . and CHG ne . then
		PCHG=(CHG / BASE) * 100;

	/* ANL01FL: primary analysis flag */
	/* Set Y on post-baseline SUPINE records with non-missing AVAL*/
	ANL01FL=' ';

	if ABLFL ne 'Y' and AVAL ne . and VSPOS='SUPINE' then
		ANL01FL='Y';
	label AVAL='Analysis Value' BASE='Baseline Value' CHG='Change from Baseline' 
		PCHG='Percent Change from Baseline' ABLFL='Baseline Record Flag' 
		ANL01FL='Analysis Record Flag 01' PARAMCD='Parameter Code' PARAM='Parameter' 
		AVISIT='Analysis Visit' AVISITN='Analysis Visit (N)' TRTP='Planned Treatment' 
		TRTPN='Planned Treatment (N)' ADT='Analysis Date' ADY='Analysis Day';
run;

/* QC: CHG should be missing for all baseline records */
proc means data=adam.advs(where=(ABLFL='Y')) n nmiss;
	var CHG;
	title 'ADVS QC: CHG for baseline records — nmiss should equal N';
run;

/* QC: check derived values for SYSBP */
proc means data=adam.advs(where=(PARAMCD='SYSBP' and ANL01FL='Y')) n mean std 
		min max;
	class TRTP AVISIT;
	var AVAL BASE CHG;
	title 'ADVS QC: SYSBP analysis values by treatment and visit';
run;