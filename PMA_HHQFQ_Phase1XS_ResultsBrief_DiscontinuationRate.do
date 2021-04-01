/*******************************************************************************
* The following .do file will create the .xls file output that PMA used to 
* 	generate the discontinuation rates for the Phase 1 cross sectional results   
* 	briefs using PMA's publicly available Household and Female dataset
*
* This .do file will only work on Phase 1 HHQFQ cross sectional datasets. You 
*   can  find the .do files to generate the .xls file outputs for PMA's publicly
* 	available Phase 1 SDP and CQ datasets and other surveys in the  
*   PMA_Analyses_Public repository
*
* This .do file does not contain the necessary codes for trends over time or
*   for discontinuation rates. You can find those .do files in the
*   PMA_Analyses_Public repository
*
* If you have any questions on how to use this or any of the other .do files in
* 	the PMA_Analyses_Public repository, please contact the PMA Data Management 
* 	Team at datamanagement@pma2020.org
*******************************************************************************/

/*******************************************************************************
*
*  FILENAME:		PMA_HHQFQ_Phase1XS_ResultsBrief_DiscontinuationRate.do
*  PURPOSE:			Generate the .xlsx output with discontinuation rates for PMA brief
*  CREATED BY: 		Elizabeth Larson (elarso11@jhu.edu)
*  ADAPTED FROM: 	Ann Roger's HHQFQDoFile4_Discontinuation_Code.do
*  DATA IN:			PMA's publicly released dataset
*  DATA OUT: 		PMA_COUNTRY_PHASE_XS_DiscontinuationRates_DATE.dta
*  DATA OUT: 		PMA_COUNTRY_PHASE_XS_EventsFile_DATE.dta
*  FILE OUT: 		PMA_COUNTRY_PHASE_XS_DiscontinuationRates_DATE.xlsx
*  LOG FILE OUT: 	PMA_COUNTRY_PHASE_XS_DiscontinuationRates_Log_DATE.log
*
*******************************************************************************/

/*******************************************************************************
* 
* INSTRUCTIONS
* Please complete the following instructions to set up and run the .do file
*
* 1. Update Directories in Section 1
* 2. Update macros in Section 2
* 3. Update the list of methods in Section 2 to match the methods you want 
*	 included in the discontinuation calculations
*******************************************************************************/

*******************************************************************************
* SECITON A: STATA SET UP (PLEASE DO NOT DELETE)
*
* Section A is necessary to make sure the .do file runs correctly, please do not 
*	move, update or delete
*******************************************************************************

clear
clear matrix
clear mata
capture log close
set maxvar 15000
set more off
numlabel, add

*******************************************************************************
* SECTION 1: SET DIRECTORIES AND DATASET
*
* You will need to set up the macro for the dataset directory. Additionally, you 
*   will need to set up one directory for where you want to save your Excel 
*   output. For the .do file to run correctly, all macros need to be contained
* 	in quotation marks ("localmacro"):
*******************************************************************************

*	1. A directory for the publicly available PMA2020 dataset on your computer
*		- For example (Mac): 
*		  local datadir "/User/ealarson/Desktop/PMA2020/PMA2018_NGR5_National_HHQFQ_v5_4Nov2019"
*		- For example (PC):
* 		  local datadir "C:\Users\annro\PMA2020\PMA2018_NGR5_National_HHQFQ_v5_4Nov2019.dta"
local datadir "/Users/ealarson/Dropbox (Gates Institute)/5 Burkina Faso/PMABF_Datasets/Phase1/Final_PublicRelease/HQFQ/PMA_BFP1_HQFQ_v1.1_15Feb2021/PMA_BFP1_HQFQ_Baseline_v1.1_15Feb2021.dta"

*	2. A directory for the folder where you want to save the dataset, xls and
*		log files that this .do file creates
*		- For example (Mac): 
*		  local calendardir "/User/ealarson/Desktop/PMA2020/NigeriaAnalysisOutput"
*		- For example (PC): 
*		  local calendardir "C:\Users\annro\PMA2020\NigeriaAnalysisOutput"
local calendardir "/Users/ealarson/Documents/PMA/Burkina Faso/PublicRelease"

*******************************************************************************
* SECTION 2: SET MACROS FOR THE COUNTRY AND ROUND AND CALENDAR START, END AND LENGTH 
*
* Set macros for country and round, and calendar start, end and length. 
*	These macros will make sure that your .do runs correctly and will also create  
*	file outputs that are easy to identify. For the .do file to run correctly, 
*	some macros need to be contained in quotation marks ("localmacro")
*******************************************************************************

*	1. The country local macro should be the name of the country. Please 
*		capitalize all country names. For regional or state level datasets, the  
*		name of the local should be "Country_Region" or "Country_State"
*		- For example: local country "NG"
*		- For example: local country "NE_Niamey"
local country "Burkina"

*	1a. The subnational macros allow you to generate the estimates on one of
*		 PMA's subnational restulsts brief. The value for the subnational_yn 
*		 macro should be "yes" if you are running a subnational estimate, or 
*		 "no" if you are running a national estimate. If you are running a 
*		 subnational estimate, the value for the subnational macro should be
*		 the name of the region as it appears in the highest geographical level 
*		 variable, typically "region" or "county". If you are not running a
*		 submational estimate, leave the subnational macro empty ("")
*		 - For example (No subnational estimate):
*		   local subnational_yn "no"
*		   local subnational ""
*		 - For example (Subnational estimate for Kenya, Kericho county):
*		   local subnational_yn "yes"
*		   local subnational "KERICHO"
local subnational_yn "no"
local subnational ""

*	2. The firstyear local macro should be the year in which the calendar starts.   
*		You can find the correct year for the macro in PMA's analytical handbook
*		at in Annex 5
*		- For example: local firstyear 2017
local firstyear 2018

*	3. The lastyear local macro should be the year in which the calendar ends.   
*		You can find the correct year for the macro in PMA's analytical handbook
*		at in Annex 5
*		- For example: local lastyear 2019
local lastyear 2020

*	4. The cal_len local macro should be the length in months of the calendar.   
*		You can find the correct month length for the macro in PMA's analytical 
*		handbook in Annex 5
*		- For example: local cal_len = 36
local cal_len = 36

*	5. Methods List 1  
*	   This recoding collapses methods into categories based on contraceptive
*	   type. For example, it collapes the three possible types of injectables
*	   (1-month injectables, 3-month injectables and sub-cutaneous injectabes)
*	   into a single injectable method. Ensure that all of the code is contained
*	   in quotation marks, including empty macros (as they are currently
*	   formatted). The following is the list of all of the contraceptive methods 
*	   and their respective values to include in the method list (If you want 
*	   your output to match the PMA brief, DO NOT change this coding)
*	   List of methods and their respective values:
*		1. Female Sterilization				11. Diaphragm	
*		2. Male Sterilization				12. Foam / Jelly	
*		3. Implant							13. Std Days / Cycle beads
*		4. IUD								14. LAM
*		5. Injectables						15. N tablet
*		6. Injectables 3mo					16. Injectables SC
*		7. Pill								30. Rhythm method
*		8. Emergency Contraception			31. Withdrawal
*		9. Male Condom						39. Other traditional methods
*		10. Female Condom							
local method_recode1  "(7 = 1)"				// Pills			
local method_recode2  "(4 = 2)"				// IUD 				
local method_recode3  "(5 6 16 = 3)"		// Injectables	 		
local method_recode4  "(3 = 4)"				// Implants				
local method_recode5  "(9 = 5)"				// MC			
local method_recode6  "(31 = 7)"			// WITHDRAWAL		
local method_recode7  "(14 8 = 8)"			// LAM EC			
local method_recode8  "(nonmissing = 9)"	// Other	
local method_recode9  ""
local method_recode10 ""
local method_recode11 ""	
local method_recode12 ""
local method_recode13 ""
local method_recode14 ""
local method_recode15 ""
local method_recode16 ""
local method_recode17 "(missing = .), gen(method)"  // Do not change this line

*	6. Methods List 2  
*	   This is label for the method list. If you made any changes to the coding
*	   in 6, you will need to update the method list. If you want your output to  
*	   match the PMA brief, DO NOT change the list coding.
local method_list 1 "Pill" 2 "IUD" 3 "Injectables" 4 "Implant" 5 "Male condom" 7 "Withdrawal" 8 "LAM/EC" 9 "Other" 

*	7. Methods List 3
*	   This label is for the final methods list. If you made any changes to the 
*	   coding in 6 and 7, you will need to update the method list. If you want
*	   your output to match the PMA brief, DO NOT change the list coding. The
*	   final number in the list should always be "All methods"
local method_list2 1 "Pill"	2 "IUD" 3 "Injectables" 4 "Implant"	5 "Male condom" 6 "Periodic abstinence" 7 "Withdrawal" 8 "LAM/EC" 9 "Other"	10 "All methods"

*******************************************************************************
* SECTION 3: CREATE MACRO FOR DATE
*
* Section 3 is necessary to make sure the .do file runs correctly, please do not 
*	move, update or delete
*******************************************************************************

* Set local/global macros for current date
local today=c(current_date)
local c_today= "`today'"
local date=subinstr("`c_today'", " ", "",.)

*******************************************************************************
* SECTION 4: CHECKS
*
* Section 4 will check the macros inputed in Section 2
*******************************************************************************
* Set main output directory
cd "`calendardir'"

* Open dataset 
use "`datadir'", clear

* Confirm that it is phase 1 data
capture destring phase, replace
gen check=(phase==1)
	if check!=1 {
		di in smcl as error "The dataset you are using is not a PMA phase 1 XS dataset. This .do file is to generate the .xls files for PMA Phase 1 XS surveys only. Please use a PMA Phase 1 XS survey rerun the .do file"
		stop
		}
	drop check

* Confirm that correct variables were chosen for locals

*	Country Variable
	gen countrycheck="`country'"
	gen check=(countrycheck==country)
	if check!=1 {
		di in smcl as error "The specified country is not the correct coding for this phase of data collection. Please search for the country variable in the dataset to identify the correct country code, update the local and rerun the .do file"
		stop
		}
	drop countrycheck check
	
* Subnational estimates
gen subnational_yn="`subnational_yn'"

*	Kenya
	if country=="Kenya" & subnational_yn=="yes" {
		gen subnational="`subnational'"
		decode county, gen(county_string)
		gen subnational_keep=substr(county_string,4,.)
		gen subnational_keep1=subinstr(subnational_keep," ","",.)
		gen check=(subnational_keep1==subnational)
		keep if check==1
		capture quietly regress check county
			if _rc==2000 {
				di in smcl as error "The specified sub-national level is not correct. Please search for the sub-national variable in the dataset to identify the correct spelling of the sub-national level, update the local and rerun the .do file"
				stop	
				}
		local country `country'_`subnational'
		drop subnational county_string subnational_keep subnational_keep1 check
		}	
	
* 	Burkina
	if country=="Burkina" & subnational_yn=="yes" {
		gen subnational="`subnational'"
		decode region, gen(region_string)
		gen subnational_keep=substr(region_string,4,.)
		gen subnational_keep1=subinstr(subnational_keep," ","",.)
		gen check=(subnational_keep1==subnational)
		keep if check==1
		capture quietly regress check region
			if _rc==2000 {
				di in smcl as error "The specified sub-national level is not correct. Please search for the sub-national variable in the dataset to identify the correct spelling of the sub-national level, update the local and rerun the .do file"
				stop		
				}
		di in smcl as error "The sub-national estimates are not yet available for Burkina Faso, we will update the .do file once they become available. If you would like Burkina Faso-related estimates, please update the .do file to generate national-level estimates"
		stop
		local country `country'_`subnational'
		drop subnational region_string subnational_keep subnational_keep1 check
		}	
		
*	DRC
	if country=="DRC" & subnational_yn=="yes" {
		gen subnational="`subnational'"
		decode province, gen(province_string)
		gen subnational_keep=substr(province_string,4,.)
		gen subnational_keep1=subinstr(subnational_keep," ","",.)
		gen check=(subnational_keep1==subnational)
		keep if check==1
		capture quietly regress check province
			if _rc==2000 {
				di in smcl as error "The specified sub-national level is not correct. Please search for the sub-national variable in the dataset to identify the correct spelling of the sub-national level, update the local and rerun the .do file"
				stop
				}
		local country `country'_`subnational'
		drop subnational province_string subnational_keep subnational_keep1 check
		}		
	
* Start log file
log using "`calendardir'/PMA_`country'_Phase1_XS_DiscontinuationRates_Log_`date'.log", replace		

* Set local for xls file
local tabout "PMA_`country'_Phase1_XS_DiscontinuationRates_`date'.xls"

* Set local for dataset
local dataset "PMA_`country'_Phase1_XS_DiscontinuationRates_`date'.dta"

* Install Programs you may need
ssc install stcompet, replace 

*******************************************************************************
* SECTION 5: CONTRACEPTIVE CALENDAR
*
* Section 5 will generate the .xlsx and .dta files
*******************************************************************************

* Split calendar variables in multiple variables
capture rename calendar_col1_full calendar_c1_full
capture rename calendar_col2_full calendar_c1_full

split calendar_c1_full, parse(",") gen(calendar_es_)
split calendar_c2_full, parse(",") gen(calendar_ed_)

*gen year=`cal_len'/12
*quietly ds calendar_c*
*foreach var in `r(varlist)' {

* Calendar encoding labels
label define calendar_encode1_list 0 "0" 1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10" 11 "11" 12 "12" 13 "13" 14 "14" 15 "15" 16 "16" 30 "30" 31 "31" 39 "39" 40 "B" 41 "P" 42 "T" 

* Calendar variable labels
label define calendar_option1_list 40 "B. Births" 41 "P. Pregnancies" 42 "T. Terminations" 0 "0. No Method Used" 1 "1. Female Sterilization" 2 "2. Male Sterilization" 3 "3. Implant" 4 "4. IUD" 5 "5. Injectables" 6 "6. Injectables 3mo" 7 "7. Pill" 8 "8. Emergency Contraception" 9 "9. Male Condom" 10 "10. Female Condom" 11 "11. Diaphragm" 12 "12. Foam / Jelly" 13 "13. Std Days / Cycle beads" 14 "14. LAM" 15 "15. N tablet" 16 "16. Injectables SC" 30 "30. Rhythm method" 31 "31. Withdrawal" 39 "39. Other traditional methods"


quietly ds calendar_es_*
foreach var in `r(varlist)' {
	rename `var' `var'_string
	encode `var'_string, gen(`var') label(calendar_encode1_list)
	label val `var' calendar_option1_list
	}

* Calendar encoding labels
label define calendar_encode2_list 1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10" 11 "11" 12 "12" 96 "96"

* Calendar variable labels
label define calendar_option2_list 1 "1. Infrequent sex / husband away" 2 "2. Became pregnant while using" 3 "3. Wanted to become pregnant" 4 "4. Husband / partner disapproved" 5 "5. Wanted more effective method" 6 "6. Side effects / health concerns" 7 "7. Lack of access / too far" 8 "8. Costs too much" 9 "9. Inconvenient to use" 10 "10. Up to god / fatalistic" 11 "11. Difficult to get pregnant / menopausal" 12 "12. Marital dissolution / separation" 96 "96. Other"
	
quietly ds calendar_ed_*
foreach var in `r(varlist)' {
	rename `var' `var'_string
	encode `var'_string, gen(`var') label(calendar_encode2_list)
	label val `var' calendar_option2_list
	}

*Restrict the data to only variables you need
if country=="Nigeria" {
	keep FQmetainstanceID calendar_es_* calendar_ed_* FQdoi_correctedSIF state FQweight*
	}
else {
	keep FQmetainstanceID calendar_es_* calendar_ed_* FQdoi_correctedSIF FQweight*
	}
drop *_string
duplicates tag FQmetainstanceID, gen(d)
keep if d== 0 

* Step 1 : Rename Contraceptive Calendar Month by Month Data serially in the order of the calendar with *_1 being the month prior to interview month. Interview month is denoted with *_0 (Step 1a). Generate variables that document the number of changes in contraceptive use status (Refer Step 1b)  

*Step 1.a
local cc_m = 1
forval m = 1/`cal_len' {
	rename calendar_e*_`m' calendar_e*_`cc_m'a
	local cc_m=`cc_m'+1
	}

rename calendar_e*a calendar_e*

* Step 1b
/* Note: 
* Events refer to a change in status of method use either due to discontinuation, adopting a new method, switching a method, pregnancies, births and terminations. Event number increases by 1 unit for every change in contraceptive use status or pregnancy and related status. 
* Episodes refer to the total number of events for a woman
*/

* Set episode number - initialized to 0
gen episodes_tot = 0
* Set previous calendar column 1 variable to anything that won't be in the calendar
gen prev_cal_col = -1

* Create variable to identify unique episodes of use
forvalues j = `cal_len'(-1)1 {
  local i = `cal_len' - `j' + 1
  * Increase the episode number if there is a change in calendar_es_
  replace episodes_tot = episodes_tot+1 if calendar_es_`i' != prev_cal_col
  * Set the episode number
  gen int event_number`i' = episodes_tot
  * Save the calendar_es_* value for the next time through the loop
  replace prev_cal_col = calendar_es_`i'
}

* Step 2: Reshape to data into Long Format and drop unnnecessary variables
* Drop the calendar variables now we have the separate month by month variables
drop episodes_tot prev_cal_col
* Reshape the new month by month variables into a long format
reshape long event_number calendar_es_ calendar_ed_ , i(FQmetainstanceID) j(i)

* label the event number variable
label variable event_number "Event number"

* Step 3 - Generate Century Month Code for start of calendar and date of interview
/* Note:
* Reference 1900 and Month is January, of the first year of the calendar which is where the calendar starts = Start of Survey
*/
gen start_cmc = ((`firstyear'-1900)*12)+1
gen cmc=start_cmc+i-1

* CMC Dates for today
replace FQdoi_correctedSIF=dofc(FQdoi_correctedSIF)
format FQdoi_correctedSIF %td
gen today_cmc = ((year(FQdoi_correctedSIF)-1900)*12)+month(FQdoi_correctedSIF) 

* Drop blank episodes occurring after the date of interview 
drop if cmc > today_cmc

*Step 4: Generate Events File 
* 4a Collapse the episodes within each case, keeping start and end, the event code,
* and other useful information 
*4b Generate Variables that document current, previous and next Event status 
*4c Label all variables 

* Step 4a
collapse FQweight* today_cmc start_cmc (first) event_start=cmc (last) event_end=cmc (count) event_duration=cmc ///
  (last) event_code_numeric=calendar_es_ discontinuation_code_numeric=calendar_ed_, by(FQmetainstanceID event_number)

* label the variables created in the collapse statement
label variable event_start  "CMC event begins"
label variable event_end  "CMC event ends"
label variable event_duration "Duration of event"
label variable event_code_numeric "Event code"
label variable discontinuation_code_numeric "Discontinuation Code"
format event_number %2.0f
format event_start event_end %4.0f

* Step 4b				
* capture the previous event and its duration for each respondent
by FQmetainstanceID:gen previous_event = event_code_numeric[_n-1] if _n > 1
by FQmetainstanceID:gen previous_event_dur = event_duration[_n-1] if _n > 1

* capture the following event and its duration for this respondent
by FQmetainstanceID:gen next_event = event_code_numeric[_n+1]  if _n < _N
by FQmetainstanceID:gen next_event_dur = event_duration[_n+1]  if _n < _N

* Step 4c
* label the event file variables and values
label variable event_code_numeric  "Current Event code"
label variable discontinuation_code_numeric   "Discontinuation code"
label variable previous_event  "Prior event code"
label variable previous_event_dur "Duration of prior event"
label variable next_event  "Next event code"
label variable next_event_dur "Duration of next event"
label values previous_event cc_option1_list
label values next_event cc_option1_list
label values event_code_numeric cc_option1_list
label values discontinuation_code_numeric cc_option2_list

format event_duration event_code_numeric discontinuation_code_numeric	///
	previous_event previous_event_dur next_event next_event_dur %2.0f	
	
* save the events file
save `country'_eventsfile.dta, replace

* Step 5
* Use Events File to generate Discontinuation Indicators: - 
*Variables Generated in Step 5: Discontinuation; Time from event to Interview; Late Entry Variables; Exposure

* Drop ongoing events as the calendar began
drop if start_cmc == event_start

* drop births, terminations, pregnancies, and episodes of non-use
* keep missing methods. to exclude missing change 99 below to 100.
drop if (event_code_numeric > 39| event_code_numeric ==0) & event_code_numeric!=.

* time from beginning of event to interview
gen tbeg_int = today_cmc - event_start
label var tbeg_int "time from beginning of event to interview"

* time from end of event to interview
gen tend_int = today_cmc - event_end
label var tend_int "time from end of event to interview"

* Generate Discontinuation Variable
gen discont = 0
replace discont = 1 if discontinuation_code_numeric != .
* censoring those who discontinue in last three months
replace discont = 0 if tend_int < 3
label var discont "discontinuation indicator"
tab discont
tab discontinuation_code_numeric discont, m


* Generate late entry variable
gen entry = 0
replace entry = tbeg_int - 23 if tbeg_int >= 24
tab tbeg_int entry

* taking away exposure time outside of the 3 to 23 month window
gen exposure = event_duration
replace exposure = event_duration - (3 - tend_int) if tend_int < 3
recode exposure -3/0=0

* drop those events that started in the month of the interview and two months prior
drop if tbeg_int < 3

* drop events that started and ended before 23 months prior to survey
drop if tbeg_int > 23 & tend_int > 23

* to remove sterilized women or women whose partners use male sterilisation from denominator use the command below - not used for DHS standard
replace exposure = . if (event_code_numeric == 1| event_code_numeric == 2)

* censor any discontinuations that are associated with use > 20 months
replace discont = 0 if (exposure - entry) > 20


* Step 6 
* recode methods, discontinuation reason, and construct switching

* recode contraceptive method 
local method_recode `method_recode1' `method_recode2' `method_recode3' ///
					`method_recode4' `method_recode5' `method_recode6' ///
					`method_recode7' `method_recode8' `method_recode9' ///
					`method_recode10' `method_recode11' `method_recode12' ///
					`method_recode13' `method_recode14' `method_recode15' ///
					`method_recode16' `method_recode17'
recode event_code_numeric `method_recode'	
label define method_list `method_list'
label values method method_list

* LAM and Emergency contraception are grouped here
* Other category is Female Sterilization, Male sterilization, Other Traditional, 
*       Female Condom, Other Modern, Standard Days Method
* adjust global meth_list below if changing the grouping of methods above

* recode reasons for discontinuation - ignoring switching
recode discontinuation_code_numeric 			     						///
	(0 .     = .)		     						///
	(2       = 1 "Method failure")	     			///
	(3       = 2 "Desire to become pregnant")		///
	(1 11 12 = 3 "Other fertility related reasons")	///
	(6    = 4 "Side effects/health concerns")	///
	(5       = 5 "Wanted more effective method")	///
	(7 8 9 = 6 "Other method related")			///
	(nonmissing = 7 "Other/DK") if discont==1, gen(reason)
label var reason "Reason for discontinuation"

* switching methods
* switching directly from one method to the next, with no gap
sort FQmetainstanceID event_number
by FQmetainstanceID: gen switch = 1 if event_end+1 == event_start[_n+1]
* if reason was "wanted more effective method" allow for a  1-month gap
by FQmetainstanceID: replace switch = 1 if discontinuation_code_numeric == 5 & event_end+2 >= event_start[_n+1] & next_event == 0
* not a switch if returned back to the same method
* note that these are likely rare, so there may be no or few changes from this command
by FQmetainstanceID: replace switch = . if event_code_numeric == event_code_numeric[_n+1] & event_end+1 == event_start[_n+1]
tab switch

* calculate variable for switching for discontinuations we are using
gen discont_sw = .
replace discont_sw = 1 if switch == 1 & discont == 1
replace discont_sw = 2 if discont_sw == . & discontinuation_code_numeric != . & discont == 1
label def discont_sw 1 "switch" 2 "other reason"
label val discont_sw discont_sw
tab discont_sw

* Step 7
* Calculate the competing risks cumulative incidence for each method and for all methods

* create global lists of the method variables included
levelsof method
global meth_codes `r(levels)'
*modify meth_list and methods_list according to the methods included
global meth_list pill iud inj impl mcondom withdr lamec other
global methods_list `" "Pill" "IUD" "Injectables" "Implant" "Male condom" "Withdrawal" "LAM/EC" "Other" "All methods" "'
global drate_list 
global drate_list_sw 
foreach m in $meth_list {
	global drate_list $drate_list drate_`m'
	global drate_list_sw $drate_list_sw drate_`m'_sw
}

* competing risks estimates - first all methods and then by method
tokenize allmeth $meth_list
foreach x in 0 $meth_codes {

	* by reason - no switching
	* declare time series data for st commands
	stset exposure if `x' == 0 | method == `x' [iw=FQweight], failure(reason==1) enter(entry)
	stcompet discont_`1' = ci, compet1(2) compet2(3) compet3(4) compet4(5) compet5(6) compet6(7) 
	* convert rate to percentage
	gen drate_`1' = discont_`1' * 100

	* switching
	* declare time series data for st commands
	stset exposure if `x' == 0 | method == `x' [iw=FQweight], failure(discont_sw==1) enter(entry)
	stcompet discont_`1'_sw = ci, compet1(2) 
	* convert rate to percentage
	gen drate_`1'_sw = discont_`1'_sw * 100

	* Get the label for the method and label the variables appropriately
	local lab1 All methods
	if `x' > 0 {
		local lab1 : label method `x'
	}
	label var drate_`1' "Rate for `lab1'"
	label var drate_`1'_sw "Rate for `lab1' for switching"
	
	* shift to next method name in token list
	macro shift
}

* Keep the variables we need for output
keep FQmetainstanceID method drate* exposure reason discont_sw FQweight entry

* save data file with cumulative incidence variables added to each case
save "`country'_drates.dta", replace


* Step 8
* calculate and save the weighted and unweighted denominators
* and convert into format for adding to dataset of results

* calculate unweighted Ns, for entries in the first month of the life table
drop if entry != 0
collapse (count) methodNunwt = entry, by(method)
save "`country'_method_Ns.dta", replace

use "`country'_drates.dta", clear
* calculate weighted Ns, for total episodes including late entries
collapse (count) methodNwt = entry [iw=FQweight], by(method)

* merge in the unweighted Ns
merge 1:1 method using "`country'_method_Ns.dta"

* drop the merge variable
drop _merge

* switch rows (methods) and columns (weighted and unweighted counts)
* to create a file that will have a row for weight Ns and a row for unweighted Ns with methods as the variables
* first transpose the file
xpose, clear
* rename the variables v1 to v9 to match the drate variable list (ignoring all methods)

tokenize $drate_list
local num : list sizeof global(drate_list)
forvalues x = 1/`num' { // this list is a sequential list of numbers up to the count of vars
	rename v`x' `1'
	mac shift
}
* drop the first line with the method code as the methods are now variables
drop if _n == 1
* generate the reason code (to be used last for the Ns)
gen reason = 9 + _n

* save the final Ns - two rows, one for weighhted N, one for unweighted N
save "`country'_method_Ns.dta", replace


* Step 9: Combine components for results output

* Prepare resulting data for output
* This code can be used to produce rates for different durations for use, 
* but is here set for 12-month discontinuation rates

* Loop through possible discontinuation rates for 6, 12, 24 and 36 months
//foreach x in 6 12 24 36 {
* current version presents only 12-month discontinuation rates:
local x 12

* open the working file with the rates attached to each case
use "`country'_drates.dta", clear	

* collect information from relevant time period only
drop if exposure > `x'

* keep only discontinuation information
keep method drate* exposure reason discont_sw FQweight

* save smaller dataset for x-month duration which we will use in collapse commands below
save "`country'_drates_`x'm.dta", replace

* collapsing data for reasons, all reasons, switching, merging and adding method Ns

* reasons for discontinuation
* collapse data by discontinuation category and save
collapse (max) $drate_list drate_allmeth, by(reason)
* drop missing values
drop if reason == .
save "`country'_reasons.dta", replace

* All reasons
* calculate total discontinuation and save
collapse (sum) $drate_list drate_allmeth
gen reason = 8
save "`country'_allreasons.dta", replace

* switching data
use "`country'_drates_`x'm.dta"
* collapse and save a file just for switching
collapse (max) $drate_list_sw drate_allmeth_sw, by(discont_sw)
* only keep row for switching, not for other reasons
drop if discont_sw != 1
* we no longer need discont_sw and don't want it in the resulting file
drop discont_sw 
gen reason = 9	// switching
* rename switching variables to match the non-switching names
rename drate_*_sw drate_*
save "`country'_switching.dta", replace

* Go back to data by reasons and merge "all reasons" and switching data to it
use "`country'_reasons.dta"
append using "`country'_allreasons.dta" // all reasons
append using "`country'_switching.dta" // switching 
append using "`country'_method_Ns.dta" // weighted and unweighted numbers
label def reason 8 "All reasons" 9 "Switching" 10 "Weighted N" 11 "Unweighted N", add

* replace empty cells with zeros for each method
* and sum the weighted and unweighted Ns into the all methods variable
foreach z in drate_allmeth $drate_list {
	replace `z' = 0 if `z' == .
	* sum the method Ns to give the total Ns
	replace drate_allmeth = drate_allmeth + `z' if reason >= 10
}

*Add missing reason if no woman selected a reason in the list 
forval y= 1/11 {
	local n= [_N]+1
	egen reason_`y'=anycount(reason), values(`y')
	quietly sum reason_`y'
	local total_reason_`y'=r(max)
	if `total_reason_`y''==0 {
		set obs `n'
		replace reason =`y' in `n'
		foreach var of varlist drate* {
			replace `var'=0 in `n'
			}
		}
	drop reason_`y'
	}
sort reason

save "`country'_drates_`x'm.dta", replace

* Step 10
* Output results in various ways

* simple output with reasons in rows and methods in columns
list reason $drate_list drate_allmeth, tab div abb(16) sep(9) noobs linesize(160)
outsheet reason $drate_list drate_allmeth using `country'_`x'm_rates.csv, comma replace	

* Outputting as excel file with putexcel	
* putexcel output
putexcel set "`country'_drates_`x'm.xlsx", replace
putexcel B1 = "Reasons for discontinuation"
putexcel A2 = "Contraceptive method"
* list out the contraceptive methods
local row = 2
foreach method of global methods_list {
	local row = `row'+1
	putexcel A`row' = "`method'"
}

putexcel B3:J`row', nformat(number_d2)
putexcel K3:L`row', nformat(number)

tokenize B C D E F G H I J K L
local recs = [_N]
* loop over reasons for discontinuation
forvalues j = 1/`recs' {
	local lab1 : label reason `j'
	putexcel `1'2 = "`lab1'", txtwrap
	local k = 2
	* loop over contraceptive methods
	local str
	foreach i in $drate_list drate_allmeth {
		local k = `k'+1
		local str `str' `1'`k' = `i'[`j']
	}
	* output results for method
	putexcel `str'
	mac shift
}


* Converting results dataset into long format for use with other tab commands

* convert results into long format 
reshape long drate_, i(reason) j(method_name) string
gen method = .
tokenize $meth_list allmeth
foreach m in $meth_codes 10 {
	replace method = `m' if method_name == "`1'"
	mac shift
}

label var method "Contraceptive method"
label define method `method_list2'
label val method method

* Now tabulate (using table instead of tab to avoid extra Totals)
table method reason [iw=drate_], cellwidth(10) f(%3.1f)


* close loop if multiple durations used and file clean up
* closing brace if foreach is used for different durations
//}


* clean up working files
erase "`country'_drates.dta"
erase "`country'_reasons.dta"
erase "`country'_allreasons.dta"
erase "`country'_switching.dta"
erase "`country'_method_Ns.dta"



