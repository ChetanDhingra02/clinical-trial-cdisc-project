/* =================================================================== */
/* Program : run_all.sas                                               */
/* Purpose : Master driver program for CDISCPILOT01 portfolio           */
/* Study   : CDISCPILOT01 — Xanomeline Alzheimer's Disease Trial        */
/* Inputs  : Source/reference XPT files and project SAS programs        */
/* Outputs : SDTM datasets, ADaM datasets, and TFL PDF outputs          */
/* Author  : Chetan Dhingra                                            */
/* Created : 2026-06-29                                                */
/* =================================================================== */


/* ------------------------------------------------------------------- */
/* Step 0: Project setup                                                */
/* ------------------------------------------------------------------- */

%include "/home/u64534201/Clinical Project/setup.sas";


/* ------------------------------------------------------------------- */
/* Step 1: SDTM parent domains                                          */
/* ------------------------------------------------------------------- */

%put NOTE: >>> Starting SDTM parent domain programming;

%include "/home/u64534201/Clinical Project/sdtm/dm.sas";
%include "/home/u64534201/Clinical Project/sdtm/vs.sas";
%include "/home/u64534201/Clinical Project/sdtm/ae.sas";

%put NOTE: >>> SDTM parent domains complete;


/* ------------------------------------------------------------------- */
/* Step 2: ADSL and subject-level additions                             */
/* ------------------------------------------------------------------- */

%put NOTE: >>> Starting ADSL programming;

%include "/home/u64534201/Clinical Project/adam/adsl.sas";
%include "/home/u64534201/Clinical Project/adam/adsl_additions.sas";
%include "/home/u64534201/Clinical Project/adam/adsl_comp_update.sas";

%put NOTE: >>> ADSL programming complete;


/* ------------------------------------------------------------------- */
/* Step 3: Supplemental qualifier domains                               */
/* SUPPAE and SUPPDM depend on final ADSL variables                     */
/* ------------------------------------------------------------------- */

%put NOTE: >>> Starting SUPP domain programming;

%include "/home/u64534201/Clinical Project/sdtm/suppae.sas";
%include "/home/u64534201/Clinical Project/sdtm/suppdm.sas";

%put NOTE: >>> SUPP domain programming complete;


/* ------------------------------------------------------------------- */
/* Step 4: Remaining ADaM datasets                                      */
/* ------------------------------------------------------------------- */

%put NOTE: >>> Starting remaining ADaM programming;

%include "/home/u64534201/Clinical Project/adam/advs.sas";
%include "/home/u64534201/Clinical Project/adam/adae.sas";
%include "/home/u64534201/Clinical Project/adam/adqsadas.sas";

%put NOTE: >>> Remaining ADaM programming complete;


/* ------------------------------------------------------------------- */
/* Step 5: TFL production                                               */
/* ------------------------------------------------------------------- */

%put NOTE: >>> Starting TFL production;

%include "/home/u64534201/Clinical Project/tfl/t_demog.sas";
%include "/home/u64534201/Clinical Project/tfl/t_disposition.sas";
%include "/home/u64534201/Clinical Project/tfl/t_ae.sas";
%include "/home/u64534201/Clinical Project/tfl/t_ae_serious.sas";
%include "/home/u64534201/Clinical Project/tfl/t_lab_shift.sas";
%include "/home/u64534201/Clinical Project/tfl/f_adascog.sas";

%put NOTE: >>> TFL production complete;


/* ------------------------------------------------------------------- */
/* Step 6: Optional validation programs                                 */
/* These are kept separate from production but listed here for clarity. */
/* Run manually when QC is needed.                                      */
/* ------------------------------------------------------------------- */

/*
%include "/home/u64534201/Clinical Project/validation/check_reference_uploads.sas";
%include "/home/u64534201/Clinical Project/validation/crosscheck_reference.sas";
%include "/home/u64534201/Clinical Project/validation/advs_deep_compare.sas";
*/


%put NOTE: >>> ALL PRODUCTION PROGRAMS COMPLETE — check log for errors;