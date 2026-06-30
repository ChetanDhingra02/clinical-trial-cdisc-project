/* =================================================================== */
/* Program   : titles.sas                                              */
/* Purpose   : Define reusable macros for standardized titles,         */
/*             footnotes, and report formatting used across all        */
/*             Tables, Listings, and Figures (TFLs).                   */
/*                                                                     */
/* Study     : CDISCPILOT01 — Xanomeline vs Placebo, Alzheimer's Phase 3*/
/*                                                                     */
/* Inputs    : Parameters passed to the %set_titles macro              */
/* Outputs   : Standardized titles and footnotes in SAS output         */
/*                                                                     */
/* Spec Ref  : Project Reporting Standards;                            */
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
%macro set_titles(tbl=, heading=, pgm=);
	title1 j=c 'CDISCPILOT01 — Xanomeline Alzheimer Study';
	title2 j=c "&tbl";
	title3 j=c "&heading";
	footnote1 j=l "Program: &pgm" j=r 'DRAFT — NOT FOR SUBMISSION';
	footnote2 j=l 'Data cutoff: 2014-12-01';
%mend set_titles;