/* =================================================================== */
/* Program : advs_deep_compare.sas                                     */
/* Purpose : Diagnose why portfolio ADVS differs from reference ADVS    */
/* =================================================================== */

%include "/home/u64534201/Clinical Project/setup.sas";

%let refroot = /home/u64534201/Clinical Project/reference;

libname radvs xport "&refroot./adam/advs.xpt";

data ref_advs;
    set radvs.advs;
run;


/* --------------------------------------------------------------- */
/* 1. Basic counts                                                  */
/* --------------------------------------------------------------- */

title "ADVS Deep Compare 1: Total Row Counts";

proc sql;
    select "MY ADVS" as source, count(*) as nobs from adam.advs
    union all
    select "REF ADVS" as source, count(*) as nobs from ref_advs;
quit;


/* --------------------------------------------------------------- */
/* 2. Compare variables available                                  */
/* --------------------------------------------------------------- */

title "ADVS Deep Compare 2A: My ADVS Variables";

proc contents data=adam.advs varnum;
run;

title "ADVS Deep Compare 2B: Reference ADVS Variables";

proc contents data=ref_advs varnum;
run;


/* --------------------------------------------------------------- */
/* 3. Counts by PARAMCD                                             */
/* --------------------------------------------------------------- */

proc sql;
    create table my_param as
    select PARAMCD, count(*) as my_n
    from adam.advs
    group by PARAMCD;

    create table ref_param as
    select PARAMCD, count(*) as ref_n
    from ref_advs
    group by PARAMCD;

    create table param_compare as
    select coalesce(a.PARAMCD,b.PARAMCD) as PARAMCD length=20,
           a.my_n,
           b.ref_n,
           coalesce(a.my_n,0) - coalesce(b.ref_n,0) as diff
    from my_param a
    full join ref_param b
        on a.PARAMCD = b.PARAMCD
    order by calculated diff;
quit;

title "ADVS Deep Compare 3: Counts by PARAMCD";

proc print data=param_compare noobs;
run;


/* --------------------------------------------------------------- */
/* 4. Counts by PARAMCD and AVISIT                                  */
/* --------------------------------------------------------------- */

proc sql;
    create table my_visit as
    select PARAMCD, AVISIT, AVISITN, count(*) as my_n
    from adam.advs
    group by PARAMCD, AVISIT, AVISITN;

    create table ref_visit as
    select PARAMCD, AVISIT, AVISITN, count(*) as ref_n
    from ref_advs
    group by PARAMCD, AVISIT, AVISITN;

    create table visit_compare as
    select coalesce(a.PARAMCD,b.PARAMCD) as PARAMCD length=20,
           coalesce(a.AVISIT,b.AVISIT) as AVISIT length=40,
           coalesce(a.AVISITN,b.AVISITN) as AVISITN,
           a.my_n,
           b.ref_n,
           coalesce(a.my_n,0) - coalesce(b.ref_n,0) as diff
    from my_visit a
    full join ref_visit b
        on a.PARAMCD = b.PARAMCD
       and a.AVISIT = b.AVISIT
       and a.AVISITN = b.AVISITN
    where calculated diff ne 0
    order by PARAMCD, AVISITN;
quit;

title "ADVS Deep Compare 4: Visit-Level Differences Only";

proc print data=visit_compare noobs;
run;


/* --------------------------------------------------------------- */
/* 5. Counts by analysis flags                                      */
/* --------------------------------------------------------------- */

title "ADVS Deep Compare 5A: My ADVS ABLFL/ANL01FL";

proc freq data=adam.advs;
    tables ABLFL ANL01FL / missing;
run;

title "ADVS Deep Compare 5B: Reference ADVS ABLFL/ANL01FL";

proc freq data=ref_advs;
    tables ABLFL ANL01FL / missing;
run;


/* --------------------------------------------------------------- */
/* 6. Check if missing rows are screen failures / nonrandomized      */
/* --------------------------------------------------------------- */

title "ADVS Deep Compare 6A: My ADVS Treatment Counts";

proc freq data=adam.advs;
    tables TRTP TRTPN / missing;
run;

title "ADVS Deep Compare 6B: Reference ADVS Treatment Counts";

proc freq data=ref_advs;
    tables TRTP TRTPN / missing;
run;


/* --------------------------------------------------------------- */
/* 7. Subject counts                                                */
/* --------------------------------------------------------------- */

proc sql;
    title "ADVS Deep Compare 7: Distinct Subject Counts";

    select "MY ADVS" as source,
           count(distinct USUBJID) as n_subjects
    from adam.advs

    union all

    select "REF ADVS" as source,
           count(distinct USUBJID) as n_subjects
    from ref_advs;
quit;


/* --------------------------------------------------------------- */
/* 8. Identify subjects present in reference but not my ADVS         */
/* --------------------------------------------------------------- */

proc sql;
    create table my_subj as
    select distinct USUBJID
    from adam.advs;

    create table ref_subj as
    select distinct USUBJID
    from ref_advs;

    create table subj_only_ref as
    select a.USUBJID
    from ref_subj a
    left join my_subj b
        on a.USUBJID = b.USUBJID
    where b.USUBJID is null;
quit;

title "ADVS Deep Compare 8: Subjects in Reference ADVS but not My ADVS";

proc print data=subj_only_ref noobs;
run;


/* --------------------------------------------------------------- */
/* 9. Key exact-row comparison attempt                              */
/* --------------------------------------------------------------- */

proc sort data=adam.advs out=my_advs_key;
    by USUBJID PARAMCD AVISITN AVISIT AVAL;
run;

proc sort data=ref_advs out=ref_advs_key;
    by USUBJID PARAMCD AVISITN AVISIT AVAL;
run;

title "ADVS Deep Compare 9: PROC COMPARE on Key Analysis Values";

proc compare base=ref_advs_key compare=my_advs_key criterion=1E-8;
    id USUBJID PARAMCD AVISITN AVISIT AVAL;
    var BASE CHG ABLFL ANL01FL;
run;

title;
footnote;