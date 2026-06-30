/* =================================================================== */
/* Table   : 14.3.4                                                    */
/* Title   : Laboratory Shift Table — Baseline to Post-Baseline         */
/* Dataset : rawdata/adlbc.xpt                                         */
/* Pop     : Safety Population (SAFFL='Y')                              */
/* Notes   : BNRIND=baseline category ANRIND=post-baseline category    */
/*           Liver function tests: ALT AST BILI ALP GGT                */
/* Author  : Chetan Dhingra                                            */
/* Created : 2026-06-30                                                */
/* =================================================================== */

%include "/home/u64534201/Clinical Project/setup.sas";
libname xlbc xport "&root./rawdata/adlbc.xpt";

data adlbc;
	set xlbc.adlbc;
run;

data liver_post;
	set adlbc;
	where PARAMCD in ('ALT', 'AST', 'BILI', 'ALP', 'GGT') and ANL01FL='Y' and 
		SAFFL='Y' and strip(ANRIND) ne '';
run;

data liver_post;
	set liver_post;
	length BNRIND_LBL ANRIND_LBL $10;

	if BNRIND='N' then
		BNRIND_LBL='Normal';
	else if BNRIND='H' then
		BNRIND_LBL='High';
	else if BNRIND='L' then
		BNRIND_LBL='Low';
	else
		BNRIND_LBL='Missing';

	if ANRIND='N' then
		ANRIND_LBL='Normal';
	else if ANRIND='H' then
		ANRIND_LBL='High';
	else if ANRIND='L' then
		ANRIND_LBL='Low';
run;

proc sort data=liver_post nodupkey;
    by PARAMCD TRTP BNRIND_LBL ANRIND_LBL USUBJID;
run;

proc freq data=liver_post noprint;
	by PARAMCD;
	tables TRTP * BNRIND_LBL * ANRIND_LBL / out=shift_counts;
run;

ods pdf file="&root./output/t_14_3_4_lab_shift.pdf" style=journal;
ods listing close;
%set_titles(tbl=Table 14.3.4, heading=Laboratory Shift Table — Baseline to 
	Post-Baseline, pgm=t_lab_shift.sas);
footnote3 'N=Normal H=High L=Low per laboratory normal reference ranges.';
footnote4 
	'Liver function tests: ALT AST BILI ALP GGT. Safety Population (SAFFL=Y).';

proc report data=shift_counts nowd style(header)=[background=lightgray 
		font_weight=bold];
	column PARAMCD TRTP BNRIND_LBL ANRIND_LBL COUNT;
	define PARAMCD / group 'Lab Test' width=8;
	define TRTP / group 'Treatment' width=22;
	define BNRIND_LBL / group 'Baseline Status' width=14;
	define ANRIND_LBL / group 'Post-Baseline Status' width=16;
	define COUNT / sum 'N Subjects' width=10;
run;

ods pdf close;
ods listing;
title;
footnote;