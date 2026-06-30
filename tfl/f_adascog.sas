/* =================================================================== */
/* Figure  : 11.2                                                      */
/* Title   : Mean Change from Baseline in ADAS-Cog(11) Total Score     */
/* Dataset : adam.adqsadas                                             */
/* Param   : ACTOT — primary efficacy endpoint                         */
/* Pop     : Efficacy Population (EFFFL='Y')                            */
/* Notes   : Two panels — observed data and LOCF-imputed               */
/*           Positive CHG = cognitive worsening                         */
/* Author  : Chetan Dhingra                                            */
/* Created : 2026-06-30                                                */
/* =================================================================== */

%include "/home/u64534201/Clinical Project/setup.sas";

/* ── Panel 1: Observed data only (DTYPE='') ── */
proc means data=adam.adqsadas
    (where=(PARAMCD='ACTOT' and ANL01FL='Y' and DTYPE='' and EFFFL='Y')) 
		noprint;
	class TRTP TRTPN AVISITN AVISIT;
	var CHG;
	output out=chg_obs n=n mean=mean std=std lclm=ci_lo uclm=ci_hi;
run;

data chg_obs_plot;
	set chg_obs;
	where _TYPE_=15 and AVISITN > 0;
	analysis='Observed Data Only';
run;

/* ── Panel 2: LOCF-imputed (all ANL01FL='Y') ── */
proc means data=adam.adqsadas
    (where=(PARAMCD='ACTOT' and ANL01FL='Y' and EFFFL='Y')) noprint;
	class TRTP TRTPN AVISITN AVISIT;
	var CHG;
	output out=chg_locf n=n mean=mean std=std lclm=ci_lo uclm=ci_hi;
run;

data chg_locf_plot;
	set chg_locf;
	where _TYPE_=15 and AVISITN > 0;
	analysis='LOCF Imputed';
run;

/* ── Output PDF ── */
ods pdf file="&root./output/f_11_2_adascog.pdf" style=journal;
ods listing close;
%set_titles(tbl=Figure 11.2, heading=Mean Change from Baseline in ADAS-Cog(11) 
	Score, pgm=f_adascog.sas);
title4 'Panel A: Observed Data Only';
footnote3 
	'Positive change = cognitive worsening. Efficacy Population (EFFFL=Y).';

proc sgplot data=chg_obs_plot;
	band x=AVISITN upper=ci_hi lower=ci_lo / group=TRTP transparency=0.55;
	series x=AVISITN y=mean / group=TRTP markers lineattrs=(thickness=2);
	refline 0 / axis=y lineattrs=(pattern=shortdash color=gray) 
		label='No change from baseline';
	xaxis label='Visit Week' values=(8 16 24) integer;
	yaxis label='Mean Change from Baseline in ADAS-Cog(11)';
	keylegend / title='Treatment Arm';
run;

title4 'Panel B: LOCF-Imputed (primary analysis)';
footnote3 
	'LOCF = Last Observation Carried Forward. Positive change = worsening.';

proc sgplot data=chg_locf_plot;
	band x=AVISITN upper=ci_hi lower=ci_lo / group=TRTP transparency=0.55;
	series x=AVISITN y=mean / group=TRTP markers lineattrs=(thickness=2);
	refline 0 / axis=y lineattrs=(pattern=shortdash color=gray) 
		label='No change from baseline';
	xaxis label='Visit Week' values=(8 16 24) integer;
	yaxis label='Mean Change from Baseline in ADAS-Cog(11)';
	keylegend / title='Treatment Arm';
run;

ods pdf close;
ods listing;
title;
footnote;