/* =================================================================== */
/* Program   : t_disposition.sas                                       */
/* Purpose   : Generate disposition summary table by treatment group    */
/*             using updated ADSL disposition and completion variables. */
/*                                                                     */
/* Study     : CDISCPILOT01 — Xanomeline vs Placebo, Alzheimer's Phase 3*/
/*                                                                     */
/* Inputs    : adam.adsl                                                */
/* Outputs   : output/t_14_1_2_disposition.pdf                          */
/*                                                                     */
/* Author    : Chetan Dhingra                                           */
/* Created   : 2026-06-29                                               */
/* =================================================================== */

%include "/home/u64534201/Clinical Project/setup.sas";

/* ------------------------------------------------------------------- */
/* Prepare safety population and create total-treatment duplicate rows  */
/* ------------------------------------------------------------------- */
data adsl_disp;
	length TRT01P $40;
	set adam.adsl;
	where SAFFL='Y';
	keep STUDYID USUBJID TRT01P TRT01PN SAFFL COMP24FL DISCONFL DCDECOD DSRAEFL 
		DTHFL;
run;

data adsl_for_count;
	set adsl_disp;
	output;
	TRT01PN=999;
	TRT01P='Total';
	output;
run;

/* ------------------------------------------------------------------- */
/* Denominators                                                        */
/* ------------------------------------------------------------------- */
proc sql;
	create table denom as select TRT01PN, TRT01P, count(distinct USUBJID) as denom 
		from adsl_for_count group by TRT01PN, TRT01P order by TRT01PN;
quit;

/* ------------------------------------------------------------------- */
/* Helper macro for table rows                                         */
/* ------------------------------------------------------------------- */
%macro count_row(out=, ord=, rowlbl=, condition=);
	proc sql;
		create table &out as select &ord as ord, "&rowlbl" as rowlbl length=100, 
			d.TRT01PN, d.TRT01P, count(distinct a.USUBJID) as n from denom as d left 
			join adsl_for_count as a on d.TRT01PN=a.TRT01PN %if %length(&condition) %then
				%do;
				and (&condition) %end;
		group by d.TRT01PN, d.TRT01P order by d.TRT01PN;
	quit;

%mend count_row;

/* ------------------------------------------------------------------- */
/* Main disposition rows                                               */
/* ------------------------------------------------------------------- */

%count_row(out=row010, ord=10, rowlbl=Subjects in Safety Population, 
	condition=);
%count_row(out=row020, ord=20, rowlbl=Completed Week 24, 
	condition=a.COMP24FL='Y');
%count_row(out=row030, ord=30, rowlbl=Discontinued from Study, 
	condition=a.DISCONFL='Y');
%count_row(out=row040, ord=40, rowlbl=Discontinued Due to Adverse Event, 
	condition=a.DSRAEFL='Y');
%count_row(out=row050, ord=50, rowlbl=Death, condition=a.DTHFL='Y');

/* ------------------------------------------------------------------- */
/* Primary discontinuation reason rows                                 */
/* ------------------------------------------------------------------- */
data row090;
	length rowlbl $100;
	set denom;
	ord=90;
	rowlbl='Primary Reason for Discontinuation';
	n=.;
	keep ord rowlbl TRT01PN TRT01P n;
run;

proc sort data=adsl_disp out=reason_values nodupkey;
	where DISCONFL='Y' and not missing(DCDECOD);
	by DCDECOD;
run;

data reason_list;
	length rowlbl $100;
	set reason_values(keep=DCDECOD);
	ord=100 + _N_;
	rowlbl=cats('  ', DCDECOD);
run;

proc sql;
	create table reason_shell as select r.ord, r.rowlbl, r.DCDECOD, d.TRT01PN, 
		d.TRT01P, d.denom from reason_list as r, denom as d order by r.ord, d.TRT01PN;
quit;

proc sql;
	create table reason_counts as select s.ord, s.rowlbl, s.TRT01PN, s.TRT01P, 
		count(distinct a.USUBJID) as n from reason_shell as s left join 
		adsl_for_count as a on s.TRT01PN=a.TRT01PN and a.DISCONFL='Y' and 
		a.DCDECOD=s.DCDECOD group by s.ord, s.rowlbl, s.TRT01PN, s.TRT01P order by 
		s.ord, s.TRT01PN;
quit;

/* ------------------------------------------------------------------- */
/* Combine all rows and create n (%) display values                    */
/* ------------------------------------------------------------------- */
data disp_counts;
	set row010 row020 row030 row040 row050 row090 reason_counts;
run;

proc sort data=disp_counts;
	by TRT01PN;
run;

proc sort data=denom;
	by TRT01PN;
run;

data disp_long;
	length value $20;
	merge disp_counts(in=incounts) denom(keep=TRT01PN denom);
	by TRT01PN;

	if incounts;

	if missing(n) then
		value=' ';
	else
		value=catx(' ', strip(put(n, 3.)), cats('(', strip(put(100*n/denom, 5.1)), 
			'%)'));
run;

proc sort data=disp_long;
	by ord rowlbl TRT01PN;
run;

proc transpose data=disp_long out=disp_wide(drop=_NAME_) prefix=T;
	by ord rowlbl;
	id TRT01PN;
	var value;
run;

/* ------------------------------------------------------------------- */
/* Output PDF                                                         */
/* ------------------------------------------------------------------- */
ods listing close;
ods pdf file="&root./output/t_14_1_2_disposition.pdf" style=journal;
%set_titles(tbl=Table 14.1.2, heading=Subject Disposition, 
	pgm=t_disposition.sas);

proc report data=disp_wide nowd headline headskip split='|';
	columns ord rowlbl T0 T54 T81 T999;
	define ord / order noprint;
	define rowlbl / display 'Disposition Category' style(column)=[cellwidth=2.6in];
	define T0 / display 'Placebo|N=86' style(column)=[cellwidth=1.1in];
	define T54 / display 'Xanomeline Low Dose|N=84' 
		style(column)=[cellwidth=1.3in];
	define T81 / display 'Xanomeline High Dose|N=84' 
		style(column)=[cellwidth=1.3in];
	define T999 / display 'Total|N=254' style(column)=[cellwidth=1.1in];
	title4 'Disposition Summary, n (%)';
run;

ods pdf close;
ods listing;
title;
footnote;

/* ------------------------------------------------------------------- */
/* QC checks                                                           */
/* ------------------------------------------------------------------- */
proc freq data=adsl_disp;
	tables TRT01P COMP24FL * TRT01P DISCONFL * TRT01P DSRAEFL * TRT01P DTHFL * 
		TRT01P / missing;
	title 'Disposition QC: key flags by treatment';
run;