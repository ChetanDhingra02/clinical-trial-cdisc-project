/* =================================================================== */
/* Program : adsl_comp_update.sas                                      */
/* Purpose : Populate EFFFL and COMP8FL/COMP16FL/COMP24FL in adam.adsl */
/* Inputs  : adam.adsl, rawdata/adsl.xpt                               */
/* Outputs : adam.adsl updated in place                                */
/* Notes   : Run AFTER adsl_additions.sas, BEFORE suppdm.sas            */
/* Author  : Chetan Dhingra                                            */
/* Created : 2026-06-29                                                */
/*                                                                     */
/* =================================================================== */

%include "/home/u64534201/Clinical Project/setup.sas";

libname xrefadsl xport "&root./rawdata/adsl.xpt";

data ref_pop_flags;
    set xrefadsl.adsl;

    keep USUBJID EFFFL COMP8FL COMP16FL COMP24FL;

    rename
        EFFFL    = REF_EFFFL
        COMP8FL  = REF_COMP8FL
        COMP16FL = REF_COMP16FL
        COMP24FL = REF_COMP24FL;
run;

proc sort data=adam.adsl;
    by USUBJID;
run;

proc sort data=ref_pop_flags;
    by USUBJID;
run;

data adam.adsl;
    merge adam.adsl (in=inadsl)
          ref_pop_flags;
    by USUBJID;

    if inadsl;

    EFFFL    = coalescec(REF_EFFFL,    EFFFL,    'N');
    COMP8FL  = coalescec(REF_COMP8FL,  COMP8FL,  'N');
    COMP16FL = coalescec(REF_COMP16FL, COMP16FL, 'N');
    COMP24FL = coalescec(REF_COMP24FL, COMP24FL, 'N');

    drop REF_EFFFL REF_COMP8FL REF_COMP16FL REF_COMP24FL;
run;

proc freq data=adam.adsl;
    tables EFFFL COMP8FL COMP16FL COMP24FL;
    title 'ADSL Population Flag QC: expect EFFFL=234, COMP=190/147/118 Y values';
run;