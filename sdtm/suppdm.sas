/* =================================================================== */
/* Program : suppdm.sas                                                */
/* Purpose : Build SUPPDM — stores 6 population flags                  */
/* Inputs  : adam.adsl, fully updated with EFFFL and COMP flags         */
/* Outputs : sdtm.suppdm                                               */
/* Author  : Chetan Dhingra                                            */
/* Created : 2026-06-29                                                */
/* =================================================================== */

%include "/home/u64534201/Clinical Project/setup.sas";

data adsl_flags;
    set adam.adsl;

    keep STUDYID USUBJID SAFFL ITTFL EFFFL COMP8FL COMP16FL COMP24FL;
run;

%macro make_supp_flag(flagvar=, qnam=, qlabel=);

    data flag_&qnam;
        length
            RDOMAIN $2
            IDVAR $8
            IDVARVAL $40
            QNAM $8
            QLABEL $40
            QVAL $200
            QORIG $20
            QEVAL $40;

        set adsl_flags;

        where &flagvar = 'Y';

        RDOMAIN = 'DM';
        IDVAR = ' ';
        IDVARVAL = ' ';

        QNAM = "&qnam";
        QLABEL = "&qlabel";
        QVAL = 'Y';
        QORIG = 'DERIVED';
        QEVAL = 'CLINICAL STUDY SPONSOR';

        keep STUDYID RDOMAIN USUBJID IDVAR IDVARVAL QNAM QLABEL QVAL QORIG QEVAL;
    run;

%mend make_supp_flag;

%make_supp_flag(flagvar=SAFFL,    qnam=SAFETY,   qlabel=Safety Population Flag);
%make_supp_flag(flagvar=ITTFL,    qnam=ITT,      qlabel=Intent to Treat Population Flag);
%make_supp_flag(flagvar=EFFFL,    qnam=EFFICACY, qlabel=Efficacy Population Flag);
%make_supp_flag(flagvar=COMP8FL,  qnam=COMPLT8,  qlabel=Completers of Week 8 Population Flag);
%make_supp_flag(flagvar=COMP16FL, qnam=COMPLT16, qlabel=Completers of Week 16 Population Flag);
%make_supp_flag(flagvar=COMP24FL, qnam=COMPLT24, qlabel=Completers of Week 24 Population Flag);

data sdtm.suppdm;
    length
        RDOMAIN $2
        IDVAR $8
        IDVARVAL $40
        QNAM $8
        QLABEL $40
        QVAL $200
        QORIG $20
        QEVAL $40;

    set flag_SAFETY
        flag_ITT
        flag_EFFICACY
        flag_COMPLT8
        flag_COMPLT16
        flag_COMPLT24;

    label
        RDOMAIN = 'Related Domain Abbreviation'
        IDVAR = 'Identifying Variable'
        IDVARVAL = 'Identifying Variable Value'
        QNAM = 'Qualifier Variable Name'
        QLABEL = 'Qualifier Variable Label'
        QVAL = 'Data Value'
        QORIG = 'Origin'
        QEVAL = 'Evaluator';
run;

proc freq data=sdtm.suppdm;
    tables QNAM;
    title 'SUPPDM QC: expect SAFETY=254 ITT=254 EFFICACY=234 COMPLT8=190 COMPLT16=147 COMPLT24=118';
run;