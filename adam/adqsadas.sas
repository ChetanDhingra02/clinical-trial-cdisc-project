/* =================================================================== */
/* Program : adqsadas.sas                                               */
/* Purpose : Read ADQSADAS XPT — ADAS-Cog efficacy analysis dataset     */
/* Inputs  : rawdata/adqsadas.xpt (from CDISCPILOT01 submission)        */
/* Outputs : adam.adqsadas                                              */
/* Key vars: PARAMCD AVAL BASE CHG ABLFL ANL01FL DTYPE EFFFL TRTP       */
/* Notes   : PARAMCD='ACTOT' is the primary efficacy endpoint           */
/*           DTYPE='LOCF' = imputed. DTYPE='' = observed.               */
/*           Population: EFFFL='Y' (234 of 254 subjects)                */
/*           Treatment col: TRTP / TRTPN (same as ADVS)                 */
/* Author  : Chetan Dhingra                                             */
/* Created : 2026-06-29                                                 */
/* =================================================================== */

%include "/home/u64534201/Clinical Project/setup.sas";

/* Step 1: Read the ADQSADAS XPT file */
libname xadqs xport "&root./rawdata/adqsadas.xpt";

data adam.adqsadas;
    set xadqs.adqsadas;

    /* The XPT already contains: */
    /* AVAL    : observed ADAS-Cog score at this visit */
    /* BASE    : ADAS-Cog score at baseline (same for all visits) */
    /* CHG     : AVAL - BASE (positive = worsening) */
    /* PCHG    : percent change from baseline */
    /* ABLFL   : 'Y' on the Baseline visit record */
    /* ANL01FL : 'Y' on all post-baseline records in primary analysis */
    /* DTYPE   : '' = observed 'LOCF' = last observation carried fwd */
    /* AVISITN : 0=Baseline 8=Week8 16=Week16 24=Week24 */
    /* TRTP    : 'Placebo' / 'Xanomeline Low Dose' / 'Xanomeline High Dose' */
    /* TRTPN   : 0 / 54 / 81 */
    /* EFFFL   : 'Y' for the efficacy population (234 subjects) */
run;


/* Step 2: QC checks */

/* QC 1: overall row count and PARAMCD distribution */
proc freq data=adam.adqsadas;
    tables PARAMCD;
    title 'ADQSADAS QC: Record count by parameter — ACTOT should be 1,040';
run;


/* QC 2: DTYPE distribution — check LOCF vs observed split */
proc freq data=adam.adqsadas(where=(PARAMCD='ACTOT'));
    tables DTYPE ANL01FL ABLFL EFFFL;
    title 'ADQSADAS QC: ACTOT flags — LOCF=241, ANL01FL-Y=1016, ABLFL-Y=254';
run;


/* QC 3: Mean CHG by treatment and visit */
/* Observed data only (DTYPE='') */
proc means data=adam.adqsadas
    (where=(PARAMCD='ACTOT' and ANL01FL='Y' and DTYPE='')) n mean std;
    class TRTP AVISIT AVISITN;
    var CHG;
    title 'ADQSADAS QC: Observed mean CHG — Wk8: Pbo 0.85 / Lo 1.66 / Hi 0.96';
run;


/* QC 4: LOCF-included analysis */
proc means data=adam.adqsadas
    (where=(PARAMCD='ACTOT' and ANL01FL='Y')) n mean std;
    class TRTP AVISIT AVISITN;
    var CHG;
    title 'ADQSADAS QC: LOCF-included mean CHG — Wk24: Pbo 2.34 / Lo 1.84 / Hi 1.30';
run;