/* =================================================================== */
/* Program   : t_demog.sas                                             */
/* Purpose   : Generate the demographic summary table by treatment      */
/*             group using the ADaM Subject-Level Analysis Dataset.     */
/*                                                                     */
/* Study     : CDISCPILOT01 — Xanomeline vs Placebo, Alzheimer's Phase 3*/
/*                                                                     */
/* Inputs    : adam.adsl                                                */
/* Outputs   : output/t_14_1_1_demog.pdf                                */
/*                                                                     */
/* Author    : Chetan Dhingra                                           */
/* Created   : 2026-06-29                                               */
/*                                                                     */
/* ------------------------------------------------------------------- */
/* Modification History                                                 */
/* Date         Author          Description                             */
/* ----------   -------------   -------------------------------------- */
/* 2026-06-29   Chetan Dhingra  Initial version                         */
/* =================================================================== */

%include "/home/u64534201/Clinical Project/setup.sas";


/* Only Safety Population subjects */

data safe_pop;
    length AGEGR1D $5;

    set adam.adsl;
    where SAFFL = 'Y';

    if AGE < 65 then
        AGEGR1D = '<65';
    else if 65 <= AGE <= 80 then
        AGEGR1D = '65-80';
    else if AGE > 80 then
        AGEGR1D = '>80';

    label AGEGR1D = 'Age Group';
run;


/* Open PDF output */

ods listing close;
ods pdf file="&root./output/t_14_1_1_demog.pdf" style=journal;

%set_titles(
    tbl=Table 14.1.1,
    heading=Demographics and Baseline Characteristics,
    pgm=t_demog.sas
);


/* ---- N per arm ---- */

proc freq data=safe_pop;
    tables TRT01P;
    title4 'Number of Subjects';
run;


/* ---- Age: continuous ---- */

proc means data=safe_pop n mean std min max;
    class TRT01P;
    var AGE;
    title4 'Age (years): N, Mean, SD, Min, Max';
run;


/* ---- Age group ---- */

proc freq data=safe_pop;
    tables TRT01P * AGEGR1D / nocol nopercent;
    title4 'Age Group, n (%)';
run;


/* ---- Sex ---- */

proc freq data=safe_pop;
    tables TRT01P * SEX / nocol nopercent;
    title4 'Sex, n (%)';
run;


/* ---- Race ---- */

proc freq data=safe_pop;
    tables TRT01P * RACE / nocol nopercent;
    title4 'Race, n (%)';
run;


/* ---- Treatment duration ---- */

proc means data=safe_pop n mean std min max;
    class TRT01P;
    var TRTDUR;
    title4 'Treatment Duration (days): N, Mean, SD, Min, Max';
run;


ods pdf close;
ods listing;
title;
footnote;