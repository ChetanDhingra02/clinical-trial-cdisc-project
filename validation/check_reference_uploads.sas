/* =================================================================== */
/* Program : check_reference_uploads.sas                               */
/* Purpose : Confirm reference CDISC Pilot XPT files were uploaded      */
/* =================================================================== */

%include "/home/u64534201/Clinical Project/setup.sas";

%let refroot = /home/u64534201/Clinical Project/reference;

data reference_file_check;
    length filetype $8 filename $40 fullpath $200 exists $3;

    filetype = "ADaM";
    filename = "adsl.xpt";
    fullpath = cats("&refroot./adam/", filename);
    exists = ifc(fileexist(fullpath), "YES", "NO");
    output;

    filename = "adqsadas.xpt";
    fullpath = cats("&refroot./adam/", filename);
    exists = ifc(fileexist(fullpath), "YES", "NO");
    output;

    filename = "adae.xpt";
    fullpath = cats("&refroot./adam/", filename);
    exists = ifc(fileexist(fullpath), "YES", "NO");
    output;

    filename = "advs.xpt";
    fullpath = cats("&refroot./adam/", filename);
    exists = ifc(fileexist(fullpath), "YES", "NO");
    output;

    filename = "adlbc.xpt";
    fullpath = cats("&refroot./adam/", filename);
    exists = ifc(fileexist(fullpath), "YES", "NO");
    output;

    filetype = "SDTM";
    filename = "dm.xpt";
    fullpath = cats("&refroot./sdtm/", filename);
    exists = ifc(fileexist(fullpath), "YES", "NO");
    output;

    filename = "vs.xpt";
    fullpath = cats("&refroot./sdtm/", filename);
    exists = ifc(fileexist(fullpath), "YES", "NO");
    output;

    filename = "ae.xpt";
    fullpath = cats("&refroot./sdtm/", filename);
    exists = ifc(fileexist(fullpath), "YES", "NO");
    output;

    filename = "suppae.xpt";
    fullpath = cats("&refroot./sdtm/", filename);
    exists = ifc(fileexist(fullpath), "YES", "NO");
    output;

    filename = "suppdm.xpt";
    fullpath = cats("&refroot./sdtm/", filename);
    exists = ifc(fileexist(fullpath), "YES", "NO");
    output;
run;

title "Reference XPT Upload Check";

proc print data=reference_file_check noobs;
run;

proc freq data=reference_file_check;
    tables exists / missing;
run;

title;