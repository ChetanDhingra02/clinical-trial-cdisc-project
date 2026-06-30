/* =================================================================== */
/* Program : crosscheck_reference.sas                                  */
/* Purpose : Cross-check portfolio outputs against CDISC Pilot01        */
/*           reference XPT datasets and expected QC counts              */
/* Study   : CDISCPILOT01 — Xanomeline Alzheimer's Study                */
/* Inputs  : Portfolio SDTM/ADaM datasets and reference XPTs            */
/* Outputs : SAS Results QC output                                      */
/* Author  : Chetan Dhingra                                            */
/* Created : 2026-06-30                                                */
/* =================================================================== */

%include "/home/u64534201/Clinical Project/setup.sas";
%let refroot = /home/u64534201/Clinical Project/reference;

/* ------------------------------------------------------------------- */
/* Reference libnames                                                   */
/* ------------------------------------------------------------------- */
libname radsl xport "&refroot./adam/adsl.xpt";
libname radqs xport "&refroot./adam/adqsadas.xpt";
libname radae xport "&refroot./adam/adae.xpt";
libname radvs xport "&refroot./adam/advs.xpt";
libname radlbc xport "&refroot./adam/adlbc.xpt";
libname rdm xport "&refroot./sdtm/dm.xpt";
libname rvs xport "&refroot./sdtm/vs.xpt";
libname rae xport "&refroot./sdtm/ae.xpt";
libname rsuppae xport "&refroot./sdtm/suppae.xpt";
libname rsuppdm xport "&refroot./sdtm/suppdm.xpt";

/* ------------------------------------------------------------------- */
/* Copy reference XPTs into WORK                                        */
/* ------------------------------------------------------------------- */
data ref_adsl;
	set radsl.adsl;
run;

data ref_adqsadas;
	set radqs.adqsadas;
run;

data ref_adae;
	set radae.adae;
run;

data ref_advs;
	set radvs.advs;
run;

data ref_adlbc;
	set radlbc.adlbc;
run;

data ref_dm;
	set rdm.dm;
run;

data ref_vs;
	set rvs.vs;
run;

data ref_ae;
	set rae.ae;
run;

data ref_suppae;
	set rsuppae.suppae;
run;

data ref_suppdm;
	set rsuppdm.suppdm;
run;

/* ------------------------------------------------------------------- */
/* PART 1: Row-count overview                                           */
/* ------------------------------------------------------------------- */
title "PART 1A: Portfolio Dataset Row Counts";

proc sql;
	create table portfolio_counts as select "sdtm.dm" as dataset length=30, 
		count(*) as nobs from sdtm.dm union all select "sdtm.vs", count(*) from 
		sdtm.vs union all select "sdtm.ae", count(*) from sdtm.ae union all select 
		"sdtm.suppae", count(*) from sdtm.suppae union all select "sdtm.suppdm", 
		count(*) from sdtm.suppdm union all select "adam.adsl", count(*) from 
		adam.adsl union all select "adam.adqsadas", count(*) from adam.adqsadas union 
		all select "adam.adae", count(*) from adam.adae union all select "adam.advs", 
		count(*) from adam.advs;
quit;

proc print data=portfolio_counts noobs;
run;

title "PART 1B: Reference Dataset Row Counts";

proc sql;
	create table reference_counts as select "ref_dm" as dataset length=30, 
		count(*) as nobs from ref_dm union all select "ref_vs", count(*) from ref_vs 
		union all select "ref_ae", count(*) from ref_ae union all select 
		"ref_suppae", count(*) from ref_suppae union all select "ref_suppdm", 
		count(*) from ref_suppdm union all select "ref_adsl", count(*) from ref_adsl 
		union all select "ref_adqsadas", count(*) from ref_adqsadas union all select 
		"ref_adae", count(*) from ref_adae union all select "ref_advs", count(*) from 
		ref_advs union all select "ref_adlbc", count(*) from ref_adlbc;
quit;

proc print data=reference_counts noobs;
run;

/* ------------------------------------------------------------------- */
/* PART 2: ADSL key checks                                              */
/* ------------------------------------------------------------------- */
title "PART 2A: ADSL Treatment Counts";

proc freq data=adam.adsl;
	tables TRT01P TRT01PN / missing;
run;

title "PART 2B: ADSL Population and Completion Flags";

proc freq data=adam.adsl;
	tables SAFFL ITTFL EFFFL COMP8FL COMP16FL COMP24FL / missing;
run;

title "PART 2C: ADSL Disposition Variables";

proc freq data=adam.adsl;
	tables DISCONFL DSRAEFL DTHFL DCDECOD / missing;
run;

title "PART 2D: ADSL Continuous Variables";

proc means data=adam.adsl n nmiss mean std min max;
	var AGE HEIGHTBL WEIGHTBL BMIBL MMSETOT;
run;

/* ------------------------------------------------------------------- */
/* PART 3: ADSL selected-variable comparison vs reference               */
/* ------------------------------------------------------------------- */
proc sort data=adam.adsl out=my_adsl_sel;
	by USUBJID;
run;

proc sort data=ref_adsl out=ref_adsl_sel;
	by USUBJID;
run;

title "PART 3: PROC COMPARE — Selected ADSL Variables vs Reference ADSL";

proc compare base=ref_adsl_sel compare=my_adsl_sel criterion=1E-8 listbasevar 
		listcompvar;
	id USUBJID;
	var TRT01P TRT01PN SAFFL ITTFL EFFFL MMSETOT DISCONFL DCDECOD DSRAEFL DTHFL 
		COMP8FL COMP16FL COMP24FL;
run;

/* ------------------------------------------------------------------- */
/* PART 4: ADQSADAS checks and comparison                               */
/* ------------------------------------------------------------------- */
title "PART 4A: ADQSADAS Key Counts";

proc freq data=adam.adqsadas;
	tables PARAMCD ABLFL ANL01FL DTYPE EFFFL / missing;
run;

proc sort data=adam.adqsadas out=my_adqsadas;
	by USUBJID PARAMCD AVISITN DTYPE;
run;

proc sort data=ref_adqsadas out=ref_adqsadas_s;
	by USUBJID PARAMCD AVISITN DTYPE;
run;

title "PART 4B: PROC COMPARE — ADQSADAS Key Analysis Variables vs Reference";

proc compare base=ref_adqsadas_s compare=my_adqsadas criterion=1E-8;
	id USUBJID PARAMCD AVISITN DTYPE;
	var TRTP TRTPN AVAL BASE CHG ABLFL ANL01FL EFFFL;
run;

/* ------------------------------------------------------------------- */
/* PART 5: ADAE key checks                                              */
/* ------------------------------------------------------------------- */
title "PART 5A: ADAE Row Counts and Treatment-Emergent Flag";

proc freq data=adam.adae;
	tables TRTEMFL AESER TRTAN * TRTEMFL / missing;
run;

title "PART 5B: Serious Treatment-Emergent AEs in Portfolio ADAE";

proc print data=adam.adae noobs;
	where AESER='Y' and TRTEMFL='Y';
	var USUBJID TRTAN TRTA AEDECOD AEBODSYS AESER TRTEMFL;
run;

title "PART 5C: Reference ADAE Serious Treatment-Emergent AEs";

proc print data=ref_adae noobs;
	where AESER='Y' and TRTEMFL='Y';
	var USUBJID TRTAN TRTA AEDECOD AEBODSYS AESER TRTEMFL;
run;

/* ------------------------------------------------------------------- */
/* PART 6: SUPP domain checks                                           */
/* ------------------------------------------------------------------- */
title "PART 6A: SUPPAE QNAM/QVAL Counts";

proc freq data=sdtm.suppae;
	tables QNAM QVAL / missing;
run;

title "PART 6B: Reference SUPPAE QNAM/QVAL Counts";

proc freq data=ref_suppae;
	tables QNAM QVAL / missing;
run;

title "PART 6C: SUPPDM QNAM Counts";

proc freq data=sdtm.suppdm;
	tables QNAM / missing;
run;

title "PART 6D: Reference SUPPDM QNAM Counts";

proc freq data=ref_suppdm;
	tables QNAM / missing;
run;

/* ------------------------------------------------------------------- */
/* PART 7: ADVS key checks                                              */
/* ------------------------------------------------------------------- */
title "PART 7A: ADVS Row Counts by Parameter";

proc freq data=adam.advs;
	tables PARAMCD TRTP / missing;
run;

title "PART 7B: Reference ADVS Row Counts by Parameter";

proc freq data=ref_advs;
	tables PARAMCD TRTP / missing;
run;

title "PART 7C: ADVS Baseline CHG Check";

proc means data=adam.advs(where=(ABLFL='Y')) n nmiss;
	var CHG;
run;

/* ------------------------------------------------------------------- */
/* PART 8: ADLBC / Lab Shift Input Checks                               */
/* ------------------------------------------------------------------- */
title "PART 8A: Reference ADLBC Liver Function Test Counts";

proc freq data=ref_adlbc;
	where PARAMCD in ('ALT', 'AST', 'BILI', 'ALP', 'GGT') and ANL01FL='Y' and 
		SAFFL='Y' and strip(ANRIND) ne '';
	tables PARAMCD TRTP / missing;
run;

/* ------------------------------------------------------------------- */
/* PART 9: Output PDF existence checks                                  */
/* ------------------------------------------------------------------- */
data pdf_check;
	length output_file $160 exists $3;
	output_file="&root./output/t_14_1_1_demog.pdf";
	exists=ifc(fileexist(output_file), "YES", "NO");
	output;
	output_file="&root./output/t_14_1_2_disposition.pdf";
	exists=ifc(fileexist(output_file), "YES", "NO");
	output;
	output_file="&root./output/t_14_3_1_ae.pdf";
	exists=ifc(fileexist(output_file), "YES", "NO");
	output;
	output_file="&root./output/t_14_3_2_ae_serious.pdf";
	exists=ifc(fileexist(output_file), "YES", "NO");
	output;
	output_file="&root./output/t_14_3_4_lab_shift.pdf";
	exists=ifc(fileexist(output_file), "YES", "NO");
	output;
	output_file="&root./output/f_11_2_adascog.pdf";
	exists=ifc(fileexist(output_file), "YES", "NO");
	output;
run;

title "PART 9: Output PDF Existence Check";

proc print data=pdf_check noobs;
run;

proc freq data=pdf_check;
	tables exists / missing;
run;

title;
footnote;