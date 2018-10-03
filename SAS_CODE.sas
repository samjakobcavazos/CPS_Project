libname datum '~/../myshortcuts/SAS/CPS_Project/perf';

data demog;
    set datum.performancetask_demog;
run;
data finstat;
    set datum.performancetask_finstat;
run;

data studentDataRaw;
    merge demog finstat;
    by student_unique_id;
    if grade_level = '09' or grade_level = '10' or grade_level = '11' or grade_level = '12';
    if (leave_date < input('2015-06-01',yymmdd10.) or entry_date > input('2016-06-30',yymmdd10.)) then delete;
    
    /* create empty values */
    numerator=.;
    denominator=.;
    
    /* set inital denominator values */
    if leave_date >= input('2015-06-01',yymmdd10.) then denominator = 1;
    
    /* if still enrolled then include in denominator and exclude from numerator*/
    if leave_date >= input('2016-06-30',yymmdd10.) then denominator = 1;
    if leave_date >= input('2016-06-30',yymmdd10.) then numerator = 0;
    
    /* define denominator values for leave_codes */
    if leave_code = '31' then denominator = 1;   
    else if leave_code = '32' or leave_code = '33' or leave_code = '34' then do;
    	if (
    	  verified_transfer = 'yes' 
    	  or verified_transfer = 'unknown'
    	  or leave_date >= input('2016-02-01',yymmdd10.)
    	) and denominator = . then denominator = 0;
    	else denominator = 1;
    end;
    else if leave_code = '35' and denominator = . then denominator = 0;
    else if leave_code = '40' and denominator = . then denominator = 0;
    else if leave_code = '41' and denominator = . then denominator = 0;
    else if leave_code = '52' and denominator = . then denominator = 1;
    else if leave_code = '53' and denominator = . then denominator = 1;
    else if leave_code = '55' and denominator = . then denominator = 1;
    else if leave_code = '67' and denominator = . then denominator = 1;
    else if leave_code = '86' and denominator = . then denominator = 1;
    else if leave_code = '87' and denominator = . then denominator = 1;
    else if leave_code = '88' and denominator = . then denominator = 1;
    else if leave_code = '99' and denominator = . then denominator = 1;
    
    /* define numerator values for leave_codes */
    if leave_code = '31' then numerator = 1;   
    else if leave_code = '32' or leave_code = '33' or leave_code = '34' then do;
    	if (
    	verified_transfer = 'yes' 
    	or verified_transfer = 'unknown'
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

data studentDataErrors;
  set studentDataRaw;
  if denominator = . or numerator = .;
run;


data studentData;
  retain school_unique_id student_unique_id grade_level student_gender leave_code verified_transfer numerator denominator;
  set studentDataRaw (keep=school_unique_id student_unique_id grade_level student_gender leave_code verified_transfer numerator denominator);
  if numerator ^=. and denominator ^= .;
run;

/* create district level dataset */
proc sql;
  create table districtData as
  select
  	(
  	  sum(numerator)/sum(denominator)
  	) as overall_dropout_rate,
  	(
  	  sum((student_gender eq 'FEMALE')*numerator)/sum((student_gender eq 'FEMALE')*denominator)
  	) as female_dropout_rate,
  	(
  	  sum((student_gender eq 'MALE')*numerator)/sum((student_gender eq 'MALE')*denominator)
  	) as male_dropout_rate
  from studentData;
  quit;

/* create school level dataset */
proc sql;
  create table schoolData as
  select 
  school_unique_id,
  (
  sum(numerator)/sum(denominator)
  ) as schoolwide_dropout_rate,
  (
  sum((student_gender eq 'FEMALE')*numerator)/sum((student_gender eq 'FEMALE')*denominator)
  ) as female_dropout_rate,
  (
  sum((student_gender eq 'MALE')*numerator)/sum((student_gender eq 'MALE')*denominator)
  ) as male_dropout_rate
  from studentData
  group by school_unique_id;
  quit;

proc export data=studentDataRaw
   outfile='~/../myshortcuts/SAS/CPS_Project/studentDataRaw.csv'
   dbms=csv
   replace;
run;

proc export data=studentDataErrors
   outfile='~/../myshortcuts/SAS/CPS_Project/studentDataErrors.csv'
   dbms=csv
   replace;
run;

proc export data=districtData
   outfile='~/../myshortcuts/SAS/CPS_Project/districtData.csv'
   dbms=csv
   replace;
run;

proc export data=schoolData
   outfile='~/../myshortcuts/SAS/CPS_Project/schoolData.csv'
   dbms=csv
   replace;
run;   

proc delete data=work.demog work.finstat work.studentDataRaw;
