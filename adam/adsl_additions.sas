/* =================================================================== */
/* Program : adsl_additions.sas                                        */
/* Purpose : Add BMIBL, MMSETOT, and disposition variables to ADSL      */
/* Inputs  : adam.adsl (from adsl.sas)                                 */
/*           sdtm.vs (for HEIGHT and baseline WEIGHT)                  */
/*           rawdata/adsl.xpt (reference — for MMSETOT, DISCONFL,       */
/*           DCDECOD, DSRAEFL, DTHFL)                                  */
/* Outputs : adam.adsl (updated in place)                              */
/* Notes   : Run AFTER adsl.sas, BEFORE adqsadas.sas                   */
/* Author  : Chetan Dhingra                                            */
/* Created : 2026-06-29                                                */
/* =================================================================== */

%include "/home/u64534201/Clinical Project/setup.sas";


/* ============================================================
   STEP 1A: Extract HEIGHT from earliest available VS HEIGHT record

   ============================================================ */

data height_candidates;
    set sdtm.vs;
    where VSTESTCD = 'HEIGHT'
      and VSSTRESN ne .;

    keep USUBJID VISITNUM VSSTRESN;
run;

proc sort data=height_candidates;
    by USUBJID VISITNUM;
run;

data height_base;
    set height_candidates;
    by USUBJID;

    if first.USUBJID;

    HEIGHTBL = VSSTRESN;

    keep USUBJID HEIGHTBL;
run;


/* ============================================================
   STEP 1B: Extract baseline WEIGHT from VS

   ============================================================ */

data weight_candidates;
    set sdtm.vs;
    where VSBLFL = 'Y'
      and VSTESTCD = 'WEIGHT'
      and VSSTRESN ne .;

    keep USUBJID VISITNUM VSSTRESN;
run;

proc sort data=weight_candidates;
    by USUBJID VISITNUM;
run;

data weight_base;
    set weight_candidates;
    by USUBJID;

    if first.USUBJID;

    WEIGHTBL = VSSTRESN;

    keep USUBJID WEIGHTBL;
run;


/* Combine HEIGHTBL and WEIGHTBL */

proc sort data=height_base;
    by USUBJID;
run;

proc sort data=weight_base;
    by USUBJID;
run;

data hw_wide;
    merge height_base
          weight_base;
    by USUBJID;
run;


/* ============================================================
   STEP 2: Read MMSETOT and disposition variables from reference ADSL

   ============================================================ */

libname xrefadsl xport "&root./rawdata/adsl.xpt";

data ref_adsl;
    set xrefadsl.adsl;

    keep USUBJID
         MMSETOT
         DURDIS
         DISCONFL
         DCDECOD
         DSRAEFL
         DTHFL;
run;


/* ============================================================
   STEP 3: Merge all additions into adam.adsl
   ============================================================ */

proc sort data=adam.adsl;
    by USUBJID;
run;

proc sort data=hw_wide;
    by USUBJID;
run;

proc sort data=ref_adsl;
    by USUBJID;
run;

data adam.adsl;
    merge adam.adsl (in=inadsl)
          hw_wide   (in=inhw)
          ref_adsl  (in=inref);
    by USUBJID;

    if inadsl;

    length BMIBLGR1 $10
           COMP8FL COMP16FL COMP24FL $1;

    /* ── BMIBL: derive from baseline height and weight ── */
    /* Formula: weight(kg) / (height in metres)^2 */

    if HEIGHTBL > 0 and WEIGHTBL > . then
        BMIBL = round(WEIGHTBL / ((HEIGHTBL/100)**2), 0.1);

    /* BMI category */
    /* Important: do not classify missing BMIBL as <25 */

    BMIBLGR1 = ' ';

    if not missing(BMIBL) then do;
        if BMIBL < 25 then
            BMIBLGR1 = '<25';
        else if 25 <= BMIBL < 30 then
            BMIBLGR1 = '25-<30';
        else if BMIBL >= 30 then
            BMIBLGR1 = '>=30';
    end;

    /* ── Placeholders for COMP flags ── */
    /* These are populated later by adsl_comp_update.sas */

    if COMP8FL = ' ' then COMP8FL = 'N';
    if COMP16FL = ' ' then COMP16FL = 'N';
    if COMP24FL = ' ' then COMP24FL = 'N';

    label
        HEIGHTBL = 'Baseline Height (cm)'
        WEIGHTBL = 'Baseline Weight (kg)'
        BMIBL = 'Baseline BMI (kg/m2)'
        BMIBLGR1 = 'Baseline BMI Group'
        MMSETOT = 'Baseline MMSE Total Score'
        DURDIS = 'Duration of Disease'
        DISCONFL = 'Discontinued from Study Flag'
        DCDECOD = 'Primary Reason for Discontinuation'
        DSRAEFL = 'Discontinued Due to AE Flag'
        DTHFL = 'Death Flag'
        COMP8FL = 'Completers of Week 8 Flag'
        COMP16FL = 'Completers of Week 16 Flag'
        COMP24FL = 'Completers of Week 24 Flag';
run;


/* ── QC checks ── */

proc means data=adam.adsl n nmiss mean std min max;
    var HEIGHTBL WEIGHTBL BMIBL MMSETOT;
    title 'ADSL Additions QC: HEIGHTBL/WEIGHTBL/BMIBL/MMSETOT summary';
run;

proc freq data=adam.adsl;
    tables BMIBLGR1 DISCONFL DSRAEFL DTHFL;
    title 'ADSL Additions QC: categorical variable distributions';
run;


/* Expected outputs:
   HEIGHTBL: mean ~167 cm
   WEIGHTBL: mean ~67 kg
   BMIBL   : mean ~24.5
   MMSETOT : mean ~18
   DISCONFL='Y': 144 subjects
   DSRAEFL ='Y': 92 subjects
   DTHFL   ='Y': 3 subjects
*/