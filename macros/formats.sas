/* =================================================================== */
/* Program   : formats.sas                                             */
/* Purpose   : Define custom SAS formats used throughout the            */
/*             CDISCPILOT01 project for treatment groups and other      */
/*             commonly displayed values.                              */
/*                                                                     */
/* Study     : CDISCPILOT01 — Xanomeline vs Placebo, Alzheimer's Phase 3*/
/*                                                                     */
/* Inputs    : None                                                    */
/* Outputs   : User-defined SAS formats available for all programs     */
/*                                                                     */
/* Spec Ref  : Project Formatting Standards;                           */
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
proc format;
	/* Sex: values in the real data are 'M' and 'F' */
	value $sexfmt 'M'='Male' 'F'='Female';

	/* Race: values are full uppercase strings in this dataset */
	value $racefmt 'WHITE'='White' 
		'BLACK OR AFRICAN AMERICAN'='Black or African American' 
		'AMERICAN INDIAN OR ALASKA NATIVE'='American Indian or Alaska Native' 
		'ASIAN'='Asian';

	/* Treatment arm codes from ARMCD in DM */
	/* Pbo = Placebo, Xan_Lo = Xanomeline Low Dose, Xan_Hi = High Dose */
	value $armfmt 'Pbo'='Placebo' 'Xan_Lo'='Xanomeline Low Dose' 
		'Xan_Hi'='Xanomeline High Dose' 'Scrnfail'='Screen Failure';

	/* TRT01PN numeric values from ADSL */
	value trtpfmt 0='Placebo' 54='Xanomeline Low Dose' 81='Xanomeline High Dose';
run;