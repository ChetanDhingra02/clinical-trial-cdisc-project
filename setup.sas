/* =================================================================== */
/* Program   : setup.sas                                               */
/* Purpose   : Define global project paths, assign SAS libraries, and  */
/*             load shared macro programs for the CDISCPILOT01 project */
/*                                                                     */
/* Study     : CDISCPILOT01 — Xanomeline vs Placebo, Alzheimer's Phase 3*/
/*                                                                     */
/* Inputs    : macros/formats.sas, macros/titles.sas                   */
/* Outputs   : Librefs RAWDATA, SDTM, ADAM and shared macro definitions*/
/*                                                                     */
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

options nomprint nomlogic nosymbolgen nodate nonumber;

/* Root project path */
%let root = /home/u64534201/Clinical Project;

/* Project libraries */
libname rawdata "&root./rawdata";
libname sdtm    "&root./sdtm";
libname adam    "&root./adam";

/* Load shared macros and formats */
%include "&root./macros/formats.sas";
%include "&root./macros/titles.sas";