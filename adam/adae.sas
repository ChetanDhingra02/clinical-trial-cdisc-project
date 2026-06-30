/* =================================================================== */
/* Program   : adae.sas                                                */
/* Purpose   : Create the ADaM Adverse Events Analysis Dataset (ADAE)  */
/*             by deriving analysis variables from the SDTM AE domain  */
/*             for treatment-emergent adverse event analyses.          */
/*                                                                     */
/* Study     : CDISCPILOT01 — Xanomeline vs Placebo, Alzheimer's Phase 3*/
/*                                                                     */
/* Inputs    : sdtm.ae, adam.adsl                                      */
/* Outputs   : adam.adae                                               */
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

proc sort data=sdtm.ae;
	by USUBJID AESEQ;
run;

proc sort data=adam.adsl;
	by USUBJID;
run;

/* Step 1: Convert AE dates to numeric and merge ADSL */
data adae_prep;
	merge sdtm.ae (in=inae) adam.adsl (keep=USUBJID TRT01P TRT01PN SAFFL TRTSDT 
		TRTEDT rename=(TRT01P=TRTA TRT01PN=TRTAN));
	by USUBJID;

	if inae;

	/* Convert AE start date to numeric for comparison */
	/* Note: some AESTDTC values are partial (YYYY-MM only) */
	/* The real adae.sas handles this with imputation flag ASTDTF */
	if length(strip(AESTDTC))=10 then
		ASTDT=input(AESTDTC, yymmdd10.);
	else if length(strip(AESTDTC))=7 then
		do;

			/* Partial date: impute day as 01 */
			ASTDT=input(compress(AESTDTC||'-01'), yymmdd10.);
			ASTDTF='D';

			/* Imputation flag: D = day imputed */
		end;
	format ASTDT yymmdd10.;

	/* TRTEMFL: treatment-emergent if AE started on/after TRTSDT */
	TRTEMFL='N';

	/* default to N, not blank */
	if ASTDT >=TRTSDT > . then
		TRTEMFL='Y';

	/* ASTDY: AE start day relative to treatment start */
	if ASTDT ne . and TRTSDT ne . then
		do;

			if ASTDT >=TRTSDT then
				ASTDY=ASTDT - TRTSDT + 1;
			else
				ASTDY=ASTDT - TRTSDT;
		end;
	label TRTEMFL='Treatment Emergent Analysis Flag' ASTDT='Analysis Start Date' 
		ASTDTF='Analysis Start Date Imputation Flag' 
		ASTDY='Analysis Start Relative Day' TRTA='Actual Treatment' 
		TRTAN='Actual Treatment (N)';
run;

data adam.adae;
	set adae_prep;
run;

/* QC: should see 1,126 Y and 65 N in the real data */
proc freq data=adam.adae;
	tables TRTEMFL * TRTA / missing;
	title 'ADAE QC: Treatment-emergent flag by treatment arm';
run;