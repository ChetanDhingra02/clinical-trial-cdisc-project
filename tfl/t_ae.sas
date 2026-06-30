/* =================================================================== */
/* Program   : t_ae.sas                                                */
/* Purpose   : Generate the Treatment-Emergent Adverse Events summary  */
/*             table by System Organ Class and treatment group.        */
/*                                                                     */
/* Study     : CDISCPILOT01 — Xanomeline vs Placebo, Alzheimer's Phase 3*/
/*                                                                     */
/* Inputs    : adam.adae, adam.adsl                                    */
/* Outputs   : output/t_14_3_1_ae.pdf                                  */
/*                                                                     */
/* Spec Ref  : Statistical Analysis Plan (SAP);                        */
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

/* Denominator: number of subjects per treatment arm */
proc freq data=adam.adsl(where=(SAFFL='Y')) noprint;
	tables TRT01P / out=denom(rename=(COUNT=n_arm TRT01P=TRTA));
run;

/* One record per subject per SOC (avoid double-counting) */
proc sort data=adam.adae(where=(TRTEMFL='Y' and SAFFL='Y')) out=ae_unique 
		nodupkey;
	by USUBJID TRTA AEBODSYS;
run;

/* Count subjects with each SOC by treatment arm */
proc sql;
	create table ae_counts as select a.TRTA, a.AEBODSYS, count(distinct a.USUBJID) 
		as n_subj from ae_unique a group by a.TRTA, a.AEBODSYS;
quit;

/* Add percentage using denominator */
proc sql;
	create table ae_display as select a.*, b.n_arm, a.n_subj / b.n_arm * 100 as 
		pct format=5.1 from ae_counts a left join denom b on a.TRTA=b.TRTA order by 
		a.AEBODSYS, a.TRTA;
quit;

ods pdf file="&root./output/t_14_3_1_ae.pdf" style=journal;
ods listing close;
%set_titles(tbl=Table 14.3.1, heading=Summary of Treatment-Emergent Adverse 
	Events by System Organ Class, pgm=t_ae.sas);

proc report data=ae_display nowd style(header)=[background=lightgray 
		font_weight=bold];
	column AEBODSYS TRTA n_subj pct;
	define AEBODSYS / group 'System Organ Class' width=38;
	define TRTA / group 'Treatment' width=22;
	define n_subj / sum 'n' width=8;
	define pct / mean '%' width=8 format=5.1;
run;

ods pdf close;
ods listing;