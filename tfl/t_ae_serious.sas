/* =================================================================== */
/* Program   : t_ae_serious.sas                                        */
/* Purpose   : Generate serious treatment-emergent adverse event table */
/*             with Fisher Exact p-values versus placebo.              */
/*                                                                     */
/* Study     : CDISCPILOT01 — Xanomeline vs Placebo, Alzheimer's Phase 3*/
/*                                                                     */
/* Inputs    : adam.adae, adam.adsl                                    */
/* Outputs   : output/t_14_3_2_ae_serious.pdf                          */
/*                                                                     */
/* Notes     : Serious TEAEs are sparse in this dataset, so Fisher      */
/*             Exact tests are used for active-dose vs placebo          */
/*             comparisons.                                            */
/*                                                                     */
/* Author    : Chetan Dhingra                                          */
/* Created   : 2026-06-30                                              */
/* =================================================================== */

%include "/home/u64534201/Clinical Project/setup.sas";


/* ------------------------------------------------------------------- */
/* Step 1: Denominators — Safety Population N per arm                  */
/* ------------------------------------------------------------------- */

proc sql;
    create table denom as
    select TRT01PN as TRTAN,
           TRT01P,
           count(distinct USUBJID) as N_ARM
    from adam.adsl
    where SAFFL = 'Y'
    group by TRT01PN, TRT01P
    order by TRTAN;
quit;


/* ------------------------------------------------------------------- */
/* Step 2: Serious treatment-emergent AEs only                         */
/* ------------------------------------------------------------------- */

data serious_ae;
    set adam.adae;
    where AESER = 'Y'
      and TRTEMFL = 'Y'
      and SAFFL = 'Y';
run;


/* ------------------------------------------------------------------- */
/* Step 3: Preferred term list and display shell                       */
/* ------------------------------------------------------------------- */

proc sql;
    create table pt_list as
    select distinct AEDECOD,
                    AEBODSYS
    from serious_ae
    order by AEDECOD;

    create table display_shell as
    select p.AEBODSYS,
           p.AEDECOD,
           d.TRTAN,
           d.TRT01P,
           d.N_ARM
    from pt_list as p,
         denom as d
    order by p.AEDECOD, d.TRTAN;
quit;


/* ------------------------------------------------------------------- */
/* Step 4: Count subjects and events                                   */
/* ------------------------------------------------------------------- */

proc sql;
    create table subj_counts as
    select AEDECOD,
           TRTAN,
           count(distinct USUBJID) as N_SUBJ
    from serious_ae
    group by AEDECOD, TRTAN;

    create table event_counts as
    select AEDECOD,
           TRTAN,
           count(*) as N_EVENTS
    from serious_ae
    group by AEDECOD, TRTAN;

    create table ae_display as
    select s.AEBODSYS,
           s.AEDECOD,
           s.TRTAN,
           s.TRT01P,
           s.N_ARM,
           coalesce(sc.N_SUBJ, 0) as N_SUBJ,
           coalesce(ec.N_EVENTS, 0) as N_EVENTS
    from display_shell as s
    left join subj_counts as sc
        on s.AEDECOD = sc.AEDECOD
       and s.TRTAN   = sc.TRTAN
    left join event_counts as ec
        on s.AEDECOD = ec.AEDECOD
       and s.TRTAN   = ec.TRTAN
    order by s.AEDECOD, s.TRTAN;
quit;

data ae_display;
    length RESULT $30;

    set ae_display;

    RESULT =
        catx(
            ' ',
            strip(put(N_SUBJ, best.)),
            cats(
                '(',
                strip(put(100 * N_SUBJ / N_ARM, 5.1)),
                '%)',
                ' [',
                strip(put(N_EVENTS, best.)),
                ']'
            )
        );
run;


/* ------------------------------------------------------------------- */
/* Step 5: Build Fisher input                                          */
/*         One record per subject, treatment, and serious AE PT         */
/* ------------------------------------------------------------------- */

proc sql;
    create table backbone as
    select subj.USUBJID,
           subj.TRTAN,
           pt.AEDECOD
    from
        (
            select distinct USUBJID,
                            TRT01PN as TRTAN
            from adam.adsl
            where SAFFL = 'Y'
        ) as subj,
        pt_list as pt
    order by AEDECOD, TRTAN, USUBJID;

    create table had_event as
    select distinct USUBJID,
                    TRTAN,
                    AEDECOD
    from serious_ae;

    create table fisher_input as
    select a.USUBJID,
           a.TRTAN,
           a.AEDECOD,
           case
               when b.USUBJID is not null then 1
               else 0
           end as EVENT
    from backbone as a
    left join had_event as b
        on a.USUBJID = b.USUBJID
       and a.TRTAN   = b.TRTAN
       and a.AEDECOD = b.AEDECOD
    order by a.AEDECOD, a.TRTAN, a.USUBJID;
quit;

proc sort data=fisher_input;
    by AEDECOD;
run;


/* ------------------------------------------------------------------- */
/* Step 6: Fisher Exact — High Dose vs Placebo                         */
/* TRTAN: 0=Placebo, 54=Low Dose, 81=High Dose                         */
/* ------------------------------------------------------------------- */

ods exclude all;
ods output FishersExact = fish_hi_raw;

proc freq data=fisher_input;
    by AEDECOD;
    where TRTAN in (0, 81);
    tables TRTAN * EVENT / fisher;
run;

ods exclude none;

data fish_hi;
    set fish_hi_raw;
    where Name1 = 'XP2_FISH';

    P_HI = nValue1;

    keep AEDECOD P_HI;
run;


/* ------------------------------------------------------------------- */
/* Step 7: Fisher Exact — Low Dose vs Placebo                          */
/* ------------------------------------------------------------------- */

ods exclude all;
ods output FishersExact = fish_lo_raw;

proc freq data=fisher_input;
    by AEDECOD;
    where TRTAN in (0, 54);
    tables TRTAN * EVENT / fisher;
run;

ods exclude none;

data fish_lo;
    set fish_lo_raw;
    where Name1 = 'XP2_FISH';

    P_LO = nValue1;

    keep AEDECOD P_LO;
run;


/* ------------------------------------------------------------------- */
/* Step 8: Final table                                                 */
/* ------------------------------------------------------------------- */

proc sql;
    create table final_table_pre as
    select a.AEBODSYS,
           a.AEDECOD,
           a.TRTAN,
           a.TRT01P,
           a.RESULT,
           h.P_HI,
           l.P_LO
    from ae_display as a
    left join fish_hi as h
        on a.AEDECOD = h.AEDECOD
    left join fish_lo as l
        on a.AEDECOD = l.AEDECOD
    order by a.AEDECOD, a.TRTAN;
quit;

data final_table;
    length P_HI_VS_PBO P_LO_VS_PBO $8;

    set final_table_pre;

    if missing(P_HI) then
        P_HI_VS_PBO = 'NA';
    else
        P_HI_VS_PBO = strip(put(P_HI, 6.4));

    if missing(P_LO) then
        P_LO_VS_PBO = 'NA';
    else
        P_LO_VS_PBO = strip(put(P_LO, 6.4));

    label
        AEBODSYS = 'System Organ Class'
        AEDECOD = 'Preferred Term'
        TRT01P = 'Treatment'
        RESULT = 'n (%) [events]'
        P_HI_VS_PBO = 'p-value High vs Placebo'
        P_LO_VS_PBO = 'p-value Low vs Placebo';
run;


/* ------------------------------------------------------------------- */
/* Step 9: Output PDF                                                  */
/* ------------------------------------------------------------------- */

ods listing close;
ods pdf file="&root./output/t_14_3_2_ae_serious.pdf" style=journal;

%set_titles(
    tbl=Table 14.3.2,
    heading=Serious Treatment-Emergent Adverse Events,
    pgm=t_ae_serious.sas
);

footnote3 'Fisher Exact p-value: each active dose vs Placebo.';
footnote4 'NA indicates the comparison was not estimable because no events occurred in either compared arm.';

proc report data=final_table nowd
    style(header)=[background=lightgray font_weight=bold];

    columns AEBODSYS AEDECOD TRT01P RESULT P_HI_VS_PBO P_LO_VS_PBO;

    define AEBODSYS     / group 'System Organ Class' width=35;
    define AEDECOD      / group 'Preferred Term' width=35;
    define TRT01P       / display 'Treatment' width=25;
    define RESULT       / display 'n (%) [events]' width=18;
    define P_HI_VS_PBO  / display 'p-value High vs Pbo' width=18;
    define P_LO_VS_PBO  / display 'p-value Low vs Pbo' width=18;
run;

ods pdf close;
ods listing;
title;
footnote;


/* ------------------------------------------------------------------- */
/* QC checks                                                           */
/* ------------------------------------------------------------------- */

proc freq data=serious_ae;
    tables TRTAN * TRTA AESER TRTEMFL / missing;
    title 'Serious AE QC: expect 3 serious treatment-emergent AEs total';
run;

proc print data=serious_ae;
    var USUBJID TRTAN TRTA AEDECOD AEBODSYS AESER TRTEMFL;
    title 'Serious AE QC Listing';
run;