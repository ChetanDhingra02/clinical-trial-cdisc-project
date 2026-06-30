/* =================================================================== */
/* Program   : adsl.sas                                                */
/* Purpose   : Create the ADaM Subject-Level Analysis Dataset (ADSL)   */
/*             by deriving subject-level analysis variables from the   */
/*             SDTM domains for use in efficacy and safety analyses.   */
/*                                                                     */
/* Study     : CDISCPILOT01 — Xanomeline vs Placebo, Alzheimer's Phase 3*/
/*                                                                     */
/* Inputs    : sdtm.dm, sdtm.vs                                        */
/* Outputs   : adam.adsl                                               */
/*                                                                     */
/* Spec Ref  : CDISC ADaM Implementation Guide (ADaM IG);              */
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

data adam.adsl;
	set sdtm.dm;

	/* Exclude screen failure subjects — they were not randomized */
	if ARMCD='Scrnfail' then
		delete;

	/* ---- Treatment variables ---- */
	/* TRT01P: planned treatment description (same as ARM) */
	TRT01P=ARM;

	/* TRT01PN: numeric treatment code */
	/* These values match the real pilot ADSL exactly */
	TRT01PN=.;

	if ARMCD='Pbo' then
		TRT01PN=0;

	if ARMCD='Xan_Lo' then
		TRT01PN=54;

	if ARMCD='Xan_Hi' then
		TRT01PN=81;

	/* Actual treatment = same as planned for this study */
	TRT01A=TRT01P;
	TRT01AN=TRT01PN;

	/* ---- Population flags ---- */
	/* SAFFL: all randomized subjects received treatment */
	SAFFL='Y';

	/* ITTFL: all randomized subjects are in intent-to-treat */
	ITTFL='Y';

	/* EFFFL: efficacy population — simplified here as all ITTFL */
	/* In the real ADSL, 20 subjects have EFFFL='N' due to */
	/* having no post-baseline efficacy assessments */
	EFFFL='Y';

	/* ---- Treatment dates from DM reference dates ---- */
	/* RFSTDTC and RFENDTC are already ISO 8601 in DM */
	/* Convert to SAS numeric dates for calculations */
	TRTSDT=input(RFSTDTC, yymmdd10.);
	TRTEDT=input(RFENDTC, yymmdd10.);
	format TRTSDT TRTEDT yymmdd10.;

	/* Treatment duration in days */
	if TRTSDT ne . and TRTEDT ne . then
		TRTDUR=TRTEDT - TRTSDT + 1;

	/* ---- Age group: elderly Alzheimer's trial population ---- */
	/* Real ADSL has: <65 (33 subj), 65-80 (144 subj), >80 (77 subj) */
	AGEGR1=' ';

	if AGE < 65 then
		AGEGR1='<65';
	else if 65 <=AGE <=80 then
		AGEGR1='65-80';
	else if AGE > 80 then
		AGEGR1='>80';
	AGEGR1N=.;

	if AGEGR1='<65' then
		AGEGR1N=1;

	if AGEGR1='65-80' then
		AGEGR1N=2;

	if AGEGR1='>80' then
		AGEGR1N=3;
	label TRT01P='Planned Treatment for Period 01' 
		TRT01PN='Planned Treatment for Period 01 (N)' 
		TRT01A='Actual Treatment for Period 01' 
		TRT01AN='Actual Treatment for Period 01 (N)' SAFFL='Safety Population Flag' 
		ITTFL='Intent-to-Treat Population Flag' EFFFL='Efficacy Population Flag' 
		TRTSDT='Date of First Exposure to Treatment' 
		TRTEDT='Date of Last Exposure to Treatment' 
		TRTDUR='Total Treatment Duration (Days)' AGEGR1='Pooled Age Group 1' 
		AGEGR1N='Pooled Age Group 1 (N)';
run;

/* QC: confirm 254 subjects, 3 treatment arms */
proc freq data=adam.adsl;
	tables TRT01P * TRT01PN;
	title 'ADSL QC: Treatment arm counts — expect 86 / 84 / 84';
run;

proc means data=adam.adsl n mean std min max;
	var AGE TRTDUR;
	title 'ADSL QC: Age and treatment duration summary';
run;