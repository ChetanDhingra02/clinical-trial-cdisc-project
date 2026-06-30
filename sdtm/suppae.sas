/* =================================================================== */
/* Program : suppae.sas                                                */
/* Purpose : Build SUPPAE — stores AETRTEM as supplemental qualifier    */
/* Inputs  : sdtm.ae, adam.adsl                                        */
/* Outputs : sdtm.suppae                                               */
/* Notes   : One row per AE record.                                    */
/*           QVAL='Y' if treatment-emergent, otherwise QVAL='N'.        */
/* Author  : Chetan Dhingra                                            */
/* Created : 2026-06-30                                                */
/* =================================================================== */

%include "/home/u64534201/Clinical Project/setup.sas";


/* ------------------------------------------------------------------- */
/* Step 1: Get AE records with treatment start dates from ADSL          */
/* ------------------------------------------------------------------- */

proc sort data=sdtm.ae out=ae_sorted;
    by USUBJID AESEQ;
run;

proc sort data=adam.adsl out=adsl_sorted(keep=USUBJID TRTSDT);
    by USUBJID;
run;

data ae_with_dates;
    merge ae_sorted(in=inae keep=STUDYID USUBJID AESEQ AESTDTC)
          adsl_sorted;
    by USUBJID;

    if inae;

    length AETRTEM $1;
    format ASTDT yymmdd10.;

    /* Convert AE start date to numeric SAS date */
    if length(strip(AESTDTC)) = 10 then
        ASTDT = input(AESTDTC, yymmdd10.);
    else if length(strip(AESTDTC)) = 7 then
        ASTDT = input(cats(AESTDTC, '-01'), yymmdd10.);

    /* Treatment-emergent flag */
    AETRTEM = 'N';

    if ASTDT >= TRTSDT > . then
        AETRTEM = 'Y';
run;


/* ------------------------------------------------------------------- */
/* Step 2: Build SUPPAE structure                                      */
/* ------------------------------------------------------------------- */

data sdtm.suppae;
    set ae_with_dates;

    length
        RDOMAIN  $2
        IDVAR    $8
        IDVARVAL $40
        QNAM     $8
        QLABEL   $40
        QVAL     $200
        QORIG    $20
        QEVAL    $40
    ;

    RDOMAIN  = 'AE';
    IDVAR    = 'AESEQ';
    IDVARVAL = strip(put(AESEQ, best.));

    QNAM     = 'AETRTEM';
    QLABEL   = 'TREATMENT EMERGENT FLAG';
    QVAL     = AETRTEM;
    QORIG    = 'DERIVED';
    QEVAL    = 'CLINICAL STUDY SPONSOR';

    label
        STUDYID  = 'Study Identifier'
        RDOMAIN  = 'Related Domain Abbreviation'
        USUBJID  = 'Unique Subject Identifier'
        IDVAR    = 'Identifying Variable'
        IDVARVAL = 'Identifying Variable Value'
        QNAM     = 'Qualifier Variable Name'
        QLABEL   = 'Qualifier Variable Label'
        QVAL     = 'Data Value'
        QORIG    = 'Origin'
        QEVAL    = 'Evaluator'
    ;

    keep STUDYID RDOMAIN USUBJID IDVAR IDVARVAL QNAM QLABEL QVAL QORIG QEVAL;
run;


/* ------------------------------------------------------------------- */
/* QC checks                                                           */
/* ------------------------------------------------------------------- */

title "SUPPAE QC 1: Row Count Should Match AE";

proc sql;
    select "SDTM.AE" as dataset length=20,
           count(*) as nobs
    from sdtm.ae

    union all

    select "SDTM.SUPPAE" as dataset length=20,
           count(*) as nobs
    from sdtm.suppae;
quit;


title "SUPPAE QC 2: Expected QVAL Counts: N=65, Y=1126";

proc freq data=sdtm.suppae;
    tables QNAM QVAL / missing;
run;


title "SUPPAE QC 3: Structure Check";

proc contents data=sdtm.suppae varnum;
run;


title;
footnote;