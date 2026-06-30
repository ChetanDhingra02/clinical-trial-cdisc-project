/* =================================================================== */
/* Program   : export_sdtm_xpt.sas                                     */
/* Purpose   : Export final SDTM datasets to CDISC transport (.xpt)    */
/*             files for validation in Pinnacle 21 Community.          */
/*                                                                     */
/* Study     : CDISCPILOT01 — Xanomeline vs Placebo, Alzheimer's Phase 3*/
/*                                                                     */
/* Inputs    : sdtm.dm, sdtm.ae, sdtm.vs                               */
/* Outputs   : output/dm.xpt, output/ae.xpt, output/vs.xpt             */
/*                                                                     */
/* Spec Ref  : CDISC SDTM Transport File (XPT) Export;                 */
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
libname xptdm xport "/home/u64534201/Clinical Project/output/dm.xpt";

proc copy in=sdtm out=xptdm memtype=data;
	select dm;
run;

libname xptdm clear;

/* AE */
libname xptae xport "/home/u64534201/Clinical Project/output/ae.xpt";

proc copy in=sdtm out=xptae memtype=data;
	select ae;
run;

libname xptae clear;

/* VS */
libname xptvs xport "/home/u64534201/Clinical Project/output/vs.xpt";

proc copy in=sdtm out=xptvs memtype=data;
	select vs;
run;

libname xptvs clear;