libname datum '~/../myshortcuts/SAS/CPS_Project/perf';

data demog;
    set datum.performancetask_demog;
run;
data finstat;
    set datum.performancetask_finstat;
run;

data studentDataRaw;
    merge demog finstat;
    by STUDENT_UNIQUE_ID;
    if grade_level = '09' or grade_level = '10' or grade_level = '11' or grade_level = '12';
    if (leave_date < input('2015-06-01',yymmdd10.) or entry_date > input('2016-06-30',yymmdd10.)) then delete;
    
    /* Create empty values */
    numerator=.;
    denominator=.;
    
    /* Set inital denominator values */
    if leave_date >= input('2015-06-01',yymmdd10.) then denominator = 1;
    
    /* If still enrolled then include in denominator and exclude from numerator*/
    if leave_date >= input('2016-06-30',yymmdd10.) then denominator = 1;
    if leave_date >= input('2016-06-30',yymmdd10.) then numerator = 0;
    
    /* Define denominator values for leave_codes */
    if leave_code = '31' then denominator = 1;   
    else if leave_code = '32' or leave_code = '33' or leave_code = '34' then do;
    	if (
    	  verified_transfer = 'YES' 
    	  or verified_transfer = 'UNKNOWN'
    	  or leave_date >= input('2016-02-01',yymmdd10.)
    	) and denominator = . then denominator = 0;
    	else denominator = 1;
    end;
    else if leave_code = '35' and demoninator = . then denominator = 0;
    else if leave_code = '40' and demoninator = . then denominator = 0;
    else if leave_code = '41' and demoninator = . then denominator = 0;
    else if leave_code = '52' and demoninator = . then denominator = 1;
    else if leave_code = '53' and demoninator = . then denominator = 1;
    else if leave_code = '55' and demoninator = . then denominator = 1;
    else if leave_code = '67' and demoninator = . then denominator = 1;
    else if leave_code = '86' and demoninator = . then denominator = 1;
    else if leave_code = '87' and demoninator = . then denominator = 1;
    else if leave_code = '88' and demoninator = . then denominator = 1;
    else if leave_code = '99' and demoninator = . then denominator = 1;
    
    /* Define numerator values for leave_codes */
    if leave_code = '31' then numerator = 1;   
    else if leave_code = '32' or leave_code = '33' or leave_code = '34' then do;
    	if (
    	verified_transfer = 'YES' 
    	or verified_transfer = 'UNKNOWN'
    	or leave_date >= input('2016-02-01',yymmdd10.)) and denominator ^= 1 then numerator = 0;
    	else numerator = 1;
    end;
    else if leave_code = '35' and numerator =. then numerator = 0;
    else if leave_code = '40' and numerator = . then numerator = 0;
    else if leave_code = '41' and numerator = . then numerator = 0;
    else if leave_code = '52' and numerator = . then numerator = 1;
    else if leave_code = '53' and numerator = . then numerator = 1;
    else if leave_code = '55' and numerator = . then numerator = 0;
    else if leave_code = '67' and numerator = . then numerator = 1;
    else if leave_code = '86' and numerator = . then numerator = 1;
    else if leave_code = '87' and numerator = . then numerator = 1;
    else if leave_code = '88' and numerator = . then numerator = 1;
    else if leave_code = '99' and numerator = . then numerator = 1;
run;

data studentDataerrors;
  set studentDataRaw;
  if denominator = . or numerator = .;
run;


data studentData;
  retain SCHOOL_UNIQUE_ID STUDENT_UNIQUE_ID grade_level STUDENT_GENDER leave_code verified_transfer numerator denominator;
  set studentDataRaw (KEEP=SCHOOL_UNIQUE_ID STUDENT_UNIQUE_ID grade_level STUDENT_GENDER leave_code verified_transfer numerator denominator);
  if numerator ^=. and denominator ^= .;
run;

/* Create district level dataset */
proc sql;
  CREATE TABLE districtData AS
  select
  	(
  	  sum(numerator)/sum(denominator)
  	) AS overall_dropout_rate,
  	(
  	  sum((student_gender EQ 'FEMALE')*numerator)/sum((student_gender EQ 'FEMALE')*denominator)
  	) AS female_dropout_rate,
  	(
  	  sum((student_gender EQ 'MALE')*numerator)/sum((student_gender EQ 'MALE')*denominator)
  	) AS male_dropout_rate
  from studentData;
  quit;

/* Create school level dataset */
proc sql;
  CREATE TABLE schoolData AS
  select 
  SCHOOL_UNIQUE_ID,
  (
  sum(numerator)/sum(denominator)
  ) as schoolwide_dropout_rate,
  (
  sum((student_gender EQ 'FEMALE')*numerator)/sum((student_gender EQ 'FEMALE')*denominator)
  ) AS female_dropout_rate,
  (
  sum((student_gender EQ 'MALE')*numerator)/sum((student_gender EQ 'MALE')*denominator)
  ) AS male_dropout_rate
  from studentData
  group by SCHOOL_UNIQUE_ID;
  quit;


proc export data=WORK.studentDataRaw
   outfile='~/../myshortcuts/SAS/CPS_Project/studentDataRaw.csv'
   dbms=csv
   replace;
run;


proc export data=WORK.studentDataErrors
   outfile='~/../myshortcuts/SAS/CPS_Project/studentDataErrors.csv'
   dbms=csv
   replace;
run;

proc export data=WORK.districtData
   outfile='~/../myshortcuts/SAS/CPS_Project/districtData.csv'
   dbms=csv
   replace;
run;

proc export data=WORK.schoolData
   outfile='~/../myshortcuts/SAS/CPS_Project/schoolData.csv'
   dbms=csv
   replace;
run;

proc delete data=WORK.demog WORK.finstat WORK.studentDataRaw;
  



  