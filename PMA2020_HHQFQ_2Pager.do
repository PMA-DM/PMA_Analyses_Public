/*******************************************************************************
* The following .do file will create the .xls file output that PMA2020 used to 
* generate its 2-page briefs using PMA2020's publicly available Household and 
* Female dataset
*
* You can also find the .do file to generate the .xls file output for PMA2020's
* 	publicly available SDP dataset in the Public_Analysis repository
*
* If you have any questions on how to use this or any of the other .do files in
* 	the PMA_Analyses_Public repository, please contact the PMA Data Management Team
* 	at datamanagement@pma2020.org
*******************************************************************************/

/*******************************************************************************
*
*  FILENAME:		PMA2020_HHQFQ_Brief.do
*  PURPOSE:			Generate the .xls output for the PMA2020 2-Page Brief
*  CREATED BY: 		Elizabeth Larson (elarso11@jhu.edu)
*  ADAPTED FROM: 	Linnea Zimmerman's PMA_HHQFQ_2Page_Analysis_$date.do
*  DATA IN:			PMA's publicly released dataset
*  DATA OUT: 		PMA2020_COUNTRY_ROUND_HHQFQ_2Page_Analysis_DATE.dta
*  FILE OUT: 		PMA2020_COUNTRY_ROUND_HHQFQ_2Page_Analysis_DATE.xls
*  LOG FILE OUT: 	PMA2020_COUNTRY_ROUND_HHQFQ_2Page_Log_DATE.log
*
*******************************************************************************/

/*******************************************************************************
* 
* INSTRUCTIONS
* Please complete the following instructions to set up and run the .do file
*
* 1. Update Directories in Section 1
* 2. Update macros in Section 2
*
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
local datadir "dataset"

*	2. A directory for the folder where you want to save the dataset, xls and
*		log files that this .do file creates
*		- For example (Mac): 
*		  local briefdir "/User/ealarson/Desktop/PMA2020/NigeriaAnalysisOutput"
*		- For example (PC): 
*		  local briefdir "C:\Users\annro\PMA2020\NigeriaAnalysisOutput"
local briefdir "folder"


*******************************************************************************
* SECTION 2: SET MACROS FOR THE COUNTRY, ROUND AND CORRECT WEIGHT AND WEALTH 
*
* Set macros for country and round. These macros will make sure that your .do
*	runs correctly and will also create file outputs that are easy to identify.
*	For the .do file to run correctly, all macros need to be contained in 
*	quotation marks ("localmacro")
*******************************************************************************

*	1. The country local macro should be the name of the country. Please 
*		capitalize all country names. For regional or state level datasets, the  
*		name of the local should be "Country_Region" or "Country_State"
*		- For example: local country "NG"
*		- For example: local country "NE_Niamey"
local country "country"

*	2. The round local macro should be the round of data collection typed as 
*		"Round#" where "#" is the numeric value of the round. You can identify
*		the numeric value of the round from either the "round" variable in the 
*		dataset, or from the datset file name
*		- For example: local round "Round5"
local round "round"

*	3. The weight local macro should be the weight variable that is used for  
*		analyzing the data. Generally, it will be "FQweight", however for certain
*		geographies, such as Nigeria, you will need to specify the weight for the
*		specific geography that you are analyzing. You can identify the correct 
*		weight by searching for variables that begin with "FQweight" in the 
*		dataset
*		- For example (Nigeria): FQweight_National
*		- For example (Burkina Faso): FQweight
local weight "weight"

*	4. The wealth local macro should be the wealth variable that is used for
*		analyzing the data. Generally, it will be either "wealthquintile" or 
*		"wealthtertile", however for certain geographies, such as Nigeria, you 
*		will need to specify the wealth for the specific geography that you are
*		analyzing. You can identify the correct wealth by searching for
*		variables that begin with "wealth" in the dataset
*		- For example (Nigeria): wealthquintile_National
*		- For example (Burkina Faso): wealthtertile
local wealth "wealth"

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
* SECTION 4: RESPONSE RATES
*
* Section 4 will generate household and female survey response rates. To
* 	generate the correct response rates, please do not move, update or delete
*******************************************************************************
* Set main output directory
cd "`briefdir'"

* Open dataset
use "`datadir'",clear


* Confirm that correct variables were chosen for locals

*	Country Variable
	gen countrycheck="`country'"
	gen check=(countrycheck==country)
	if check!=1 {
		di in smcl as error "The specified country is not the correct coding for this round of data collection. Please search for the country variable in the dataset to identify the correct country code, update the local and rerun the .do file"
		stop
		}
	drop countrycheck check


*	Round Variable
	gen roundcheck="`round'"
	gen roundcheckv2=substr(roundcheck,6,1)
		destring roundcheckv2, replace
	gen check=(roundcheckv2==round)
	if check!=1 {
		di in smcl as error "The specified round is not the correct round of data collection. Please search for the round variable in the dataset to identify the correct round of data collection, update the local and rerun the .do file"
		stop
		}
	drop roundcheck roundcheckv2 check

*	Weight Variable
	capture confirm var `weight'
	if _rc!=0 {
		di in smcl as error "Variable `weight' not found in dataset. Please search for the correct weight variable in the dataset to specify as the local macro. If you are doing a regional/state-level analysis, please make sure that you have selected the correct variable for the geographic level, update the local and rerun the .do file"
		stop
		}
		
*	Wealth Variable	
	capture confirm var `wealth'
	if _rc!=0 {
		di in smcl as error "Variable `wealth' not found in dataset. Please search for the correct wealth variable in the dataset to specify as the local macro. If you are doing a regional/state-level analysis, please make sure that you have selected the correct variable for the geographic level, update the local and rerun the .do file"
		stop
		} 

* Change country local for subnational estimates
	gen wealth="`wealth'"
	if wealth=="wealthtertile_Niamey" {
		local subnational Niamey
		}
		
	if wealth=="wealthquintile_Taraba" {
		local subnational Taraba
		}
	
	if wealth=="wealthquintile_Rivers" {
		local subnational Rivers
		}
		
	if wealth=="wealthquintile_Nasarawa" {
		local subnational Nasarawa
		}
		
	if wealth=="wealthquintile_Lagos" {
		local subnational Lagos
		}
		
	if wealth=="wealthquintile_Kano" {
		local subnational Kano
		}
		
	if wealth=="wealthquintile_Kaduna" {
		local subnational Kaduna
		}
		
	if wealth=="wealthquintile_Anambra" {
		local subnational Anambra
		}
	
	local country `country'_`subnational'
	
* Start log file
log using "`briefdir'/PMA2020_`country'_`round'_HHQFQ_2Page_Log_`date'.log", replace		

* Use household data to show response rates. PMA2020 only includes households 
* 	that fully completed the questionnaire in the analytical sample
preserve

* If a certain state/region within a country, keep only that state/region (Nigeria and Niger)
if wealth=="wealthtertile_Niamey" {
	keep if region==1 
	}
	
if wealth=="wealthquintile_Taraba" {
	keep if state==3
	}

if wealth=="wealthquintile_Rivers" {
	keep if state==5
	}
	
if wealth=="wealthquintile_Nasarawa" {
	keep if state==6
	}
	
if wealth=="wealthquintile_Lagos" {
	keep if state==2
	}
	
if wealth=="wealthquintile_Kano" {
	keep if state==4
	}
	
if wealth=="wealthquintile_Kaduna" {
	keep if state==1
	}
	
if wealth=="wealthquintile_Anambra" {
	keep if state==7
	}

* 	Generate a variable that will identify one observation per household and only 
*		keep one observation per household
	egen metatag=tag(metainstanceID)
	keep if metatag==1 

*	Recode all households that did not fully complete the questionnaire as having 
*		a "Not complete" Questionnaire
	gen responserate=0 if HHQ_result>=1 & HHQ_result<6
		replace responserate=1 if HHQ_result==1
	label define responselist 0 "Not complete" 1 "Complete"
	label val responserate responselist

*	Tabout Household Respone Rate
	tabout responserate ///
		using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", replace ///
		cells(freq col) h2("Household response rate") f(0 1) clab(n %)
		
restore
drop wealth

* Use female data to show female response rates

* 	If using an earlier version of the PMA2020 survey, generate the variable 
*	last_night to identify eligible women
	capture confirm var usual_member
	if _rc==0 {
		gen last_night=0
		replace last_night=1 if usual_member==1 | usual_member==3
		}
	
*	If using an earlier version of the PMA2020 survey, generate the variable 
*		eligible to identify eligible women
	capture confirm var eligible
	if _rc!=0 {
		gen eligible=1 if last_night==1 & HHQ_result==1 & FRS_result==1
		}

*	Generate a variable that will identify female questionnaires as either 
*		"Complete" or "Not Complete"
	gen FQresponserate=0 if eligible==1 & last_night==1
		replace FQresponserate=1 if FRS_result==1 & last_night==1
	label define responselist 0 "Not complete" 1 "Complete"
	label val FQresponserate responselist

* 	Tabout All Women Response Rate
	tabout FQresponserate if HHQ_result==1 ///
		using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
		cells(freq col) h2("Female response rate") f(0 1) clab(n %)	

* Create analytical sample: Only keep de facto women who completed questionnaire 
* 	and households with completed questionnaires. This represents PMA2020's 
*	Analytical Population
keep if FRS_result==1 & HHQ_result==1
keep if last_night==1

* Save dataset so can replicate analysis results later
save "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.dta", replace


*******************************************************************************
* SECTION 5: COUNTS FOR ALL WOMEN, MARRIED WOMEN, AND UNMARRIED SEXUALLY ACTIVE
*	WOMEN
*
* Section 5 is necessary to make sure the .do file runs correctly, please do not 
* 	move, update or delete
*******************************************************************************
* Generate variable that represents number of observations
gen one=FRS_result
label var one "All women"

* Generate dichotomous "married" variable to represent all women married or 
*	currently living with a man
gen married=(FQmarital_status==1 | FQmarital_status==2)
label variable married "Married or currently living with a man"

* Generate dichotomous sexually active unmarried women variable to represent all 
*	sexually active women who are not married or currently living with a man
gen umsexactive=0 
	replace umsexact=1 if married==0 & ///
		((last_time_sex==2 & last_time_sex_value<=4 & last_time_sex_value>=0) ///
		| (last_time_sex==1 & last_time_sex_value<=30 & last_time_sex_value>=0) ///
		| (last_time_sex==3 & last_time_sex_value<=1 & last_time_sex_value>=0))
label variable umsexactive "Unmarried sexually active" 

* Generate dichotomous sexually active variable to represent all women who have 
*	been sexually active in the last 30 days (month)
gen sexactive=(last_time_sex==2 & last_time_sex_value<=4 & last_time_sex_value>=0) ///
	| (last_time_sex==1 & last_time_sex_value<=30 & last_time_sex_value>=0) ///
	| (last_time_sex==3 & last_time_sex_value<=1 & last_time_sex_value>=0) 

* Label yes/no response options for the newly created married, umsexactive and 
*	sexactive variables
label define yesno 0 "No" 1 "Yes"
foreach x in married umsexactive sexactive {
	label values `x' yesno
	}

* Tabout count of all women, unweighted
tabout one ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	cells(freq) h2("All women (unweighted)") f(0)

* Tabout count of all married women, unweighted
tabout married if married==1 ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	cells (freq) h2("Married women (unweighted)") f(0)

* Tabout count of unmarried sexually active women, unweighted
tabout umsexactive if umsexactive==1  ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	cells(freq) h2("Unmarried sexually active (unweighted)") f(0)

* Drop the observation variable (will regenerate later)
drop one
save, replace


*******************************************************************************
* SECTION 6: GENERATE NECESSARY VARIBLES AND SET UP DATA FOR ANALYSIS
*
* Section 6 is necessary to make sure the .do file runs correctly, please do not 
*	move, update or delete
*******************************************************************************
* CONTRACEPTIVE METHODS

* Recode current method 
replace current_methodnum_rc=. if current_methodnum_rc==-99
recode current_methodnum_rc 1 2=1 ///
							3=2 ///
							4=3 ///
							5 6=4 ///
							16=5 ///
							7=6 ///
							8=7 ///
							9 10=8 ///
							11 12 13 14 15 19=9 ///
							30 31 32 39=10,	///
							gen(current_method_recode)
capture lab def current_method_recode_list 1 "Sterilization" 2 "Implants" ///
	3 "IUD" 4 "DMPA" 5 "DMPA-SC" 6 "Pill" 7 "EC" 8 "Condom" 9 "Other modern" ///
	10 "Other traditional"
lab val current_method_recode current_method_recode_list

* Label Current User and Current Modern User Variables
label value cp yesno
label value mcp yesno

* Generate dichotomous current use of long acting contraceptive variable
capture drop longacting
gen longacting=current_methodnum_rc>=1 & current_methodnum_rc<=4
label value longacting yesno
label variable longacting "Current use of long acting contraceptive method"

	
****************************************	
* URBAN/RURAL VARIABLE

* Create urban/rural variable if there is an urban/rural breakdown of the data
capture confirm var ur 
if _rc==0 {
	gen urban=ur==1
	label variable urban "Urban/rural place of residence"
	label define urban 1 "Urban" 0 "Rural"
	label value urban urban
	}

* Create urban/rural variable if there is no urban/rural breakdown of the data
else {
	gen urban=1
	label variable urban "No urban/rural breakdown"
	}

****************************************	
* DATE OF THE INTERVIEW

* DRC Round 1 does not include the FQdoi_correctedSIF variable
if country=="CD" & round==1 {
	gen FQdoi_correctedSIF=FQSubmissionDateSIF
	}

* Generate day, month and year variables from the FQdoi_correctedSIF variable	
gen FQdoi_correctedSIFdate=dofc(FQdoi_correctedSIF)
gen FQdoi_correctedmonth=month(FQdoi_correctedSIFdate)
gen FQdoi_correctedyear=year(FQdoi_correctedSIFdate)

* Calculate doimonth in century month code (months since January 1900)
gen doicmc=(12*(FQdoi_correctedyear-1900))+FQdoi_correctedmonth

* Drop unnecessary variables
drop FQdoi_correctedSIFdate FQdoi_correctedmonth FQdoi_correctedyear

****************************************
* TIME SINCE LAST BIRTH
	
* Generate day, month and year variables from the recent_birthSIF variable
gen recent_birthSIFdate=dofc(recent_birthSIF)
	format recent_birthSIFdate %td
gen recent_birthmonth=month(recent_birthSIFdate)
gen recent_birthyear=year(recent_birthSIFdate)

* Replace last birth month and year equal to missing if year is 2020 (i.e. missing)
replace recent_birthmonth=. if recent_birthyear==2020
	recode recent_birthyear 2020=. 
	
* Generate last birth date in century month code (months since January 1900)
gen lastbirthcmc=(recent_birthyear-1900)*12+recent_birthmonth

* Generate time since last birth in months variable
gen tsinceb=hours(FQdoi_correctedSIF-recent_birthSIF)/730.484

* Drop unnecessary variables
drop recent_birthSIFdate recent_birthmonth recent_birthyear

****************************************	
* UNMET NEED

* Generate total demand = current use + unmet need
gen totaldemand=0
	replace totaldemand=1 if cp==1 | unmettot==1
label variable totaldemand "Has contraceptive demand, i.e. current user or unmet need"

* Generate total demand staisfied
gen totaldemand_sat=0 if totaldemand==1
	replace totaldemand_sat=1 if totaldemand==1 & mcp==1
label variable totaldemand_sat "Contraceptive demand satisfied by modern method"

* Generate categorical unmet need, traditional method, modern method variable
gen cont_unmet=0 if married==1
	replace cont_unmet=1 if unmettot==1
	replace cont_unmet=2 if tcp==1
	replace cont_unmet=3 if mcp==1
label variable cont_unmet "Unmet need, traditional method, and modern method prevalence among married women"
label define cont_unmetl 0 "None" 1 "Unmet need" 2 "Traditional contraceptive use" ///
	3 "Modern contraceptive use"
label values cont_unmet cont_unmetl

* Label yes/no response options
foreach x in totaldemand totaldemand_sat {
	label values `x' yesno
	}
	
* Label unmet need variables
label define unmet_dichot 0 "No Unmet Need" 1 "Unmet Need"
label val unmettot unmet_dichot
label define unmet_cat -99 "Missing" -97 "Not Sexually Active" ///
	1 "Unmet Need for Spacing" 2 "Unmet Need for Limiting" 3 "Using for Spacing" ///
	4 "Using for Limiting" 7 "No Unmet Need" 9 "Infecund of Menopausal" 
label val unmet unmet_cat
	

****************************************
* UNINTENDED BIRTHS

* Recode "-99" as "." to represent missing
recode pregnancy_last_desired -99 =.
recode pregnancy_current_desired -99 =.

* Generate wantedness variable that combines results from last birth and current 
*	pregnancy questions
gen wanted=1 if pregnancy_last_desired==1 | pregnancy_current_desired==1 
	replace wanted=2 if pregnancy_last_desired==2 | pregnancy_current_desired==2 
	replace wanted=3 if pregnancy_last_desired==3 | pregnancy_current_desired==3 
label variable wanted "Intendedness of previous birth/current pregnancy (categorical): then, later, not at all"
label def wantedlist 1 "Then" 2 "Later" 3 "Not at all"
label val wanted wantedlist

* Generate dichotomous intendedness variables that combines births wanted 
*	"later" or "not at all"
gen unintend=1 if wanted==2 | wanted==3
	replace unintend=0 if wanted==1
label variable unintend "Intendedness of previous birth/current pregnancy (dichotomous)"
label define unintendl 0 "Intended" 1 "Unintended"
label values unintend unintendl	

****************************************
* CHOICE

* Generate dichotomous variable for whether the woman chose the method herself
*	or jointly with her partner or provider
gen methodchosen=1 if fp_final_decision==1 | fp_final_decision==4 | fp_final_decision==5
	replace methodchosen=0 if fp_final_decision==2 | fp_final_decision==3
	replace methodchosen=0 if fp_final_decision==-99 | fp_final_decision==6 
label variable methodchosen "Who chose method?"
label define methodchosenl 0 "Not self" 1 "Self, self/provider, self/partner"
label values methodchosen methodchosenl

* Label variables
foreach var in fp_obtain_desired fp_told_other_methods fp_side_effects {
	label values `var' yesno
	}

****************************************
* PROVIDER

* Generate dichotomous would return to provider/refer relative to provider variable
recode return_to_provider -88 -99=0
recode refer_to_relative -88 -99=0
gen returnrefer=1 if return_to_provider==1 & refer_to_relative==1 & cp==1
	replace returnrefer=0 if cp==1 & (return_to_provider==0 | refer_to_relative==0)
label variable returnrefer "Would return to provider and refer a friend or family member"
label values returnrefer yesno

* Generate dichotomous variable for whether the woman paid fees the last time 
*	she obtained a family planning method from a provider. Older rounds of 
*	PMA2020 have a variable called "fees_12months" while newer versions how a 
*	variable called "method_fees"
capture confirm var fees_12months
if _rc==0 {
	gen fees_paid_lastvisit=fees_12months
	}
	
else {
	gen fees_paid_lastvisit=0 if method_fees==0
		replace fees_paid_lastvisit=1 if method_fees>0 & method_fees!=.
		replace fees_paid_lastvisit=1 if method_fees==-88
	}
	
label var fees_paid_lastvisit "Did you pay for services the last time you obtained FP?"
label val fees_paid_lastvisit yesno

* Generate dichotomous variable for public versus not public source of family 
*	planning. Older and newer rounds of PMA2020 use two different questions to 
*	calculate this variable
capture confirm var fp_provider
if _rc==0 {
	gen public_fpv2=fp_provider
	}
else {
	gen public_fpv2=fp_provider_rw
	}
recode public_fpv2 (1/19=1 "Public") (-88 -99=0) (nonmiss=0 "Not Public"), gen(public_fp)
label variable public_fp "Respondent or partner for method for first time from public family planning provider"
	
* Generate variable for whether she received FP information from visiting 
*	provider or health care worker at facility
recode visited_by_health_worker -99=0
recode facility_fp_discussion -99=0
gen healthworkerinfo=0
	replace healthworkerinfo=1 if visited_by_health_worker==1 | facility_fp_discussion==1
label variable healthworkerinfo "Received family planning info from provider in last 12 months"

* Generate variable for exposure to family planning media in past few months
gen fpmedia=0
	replace fpmedia=1 if fp_ad_radio==1 | fp_ad_magazine==1 | fp_ad_tv==1
label variable fpmedia "Exposed to family planning media in last few months"

* Label yes/no response options for healthworkerinfo and fpmedia variables
foreach x in healthworkerinfo fpmedia {
label values `x' yesno
	}
	
* Generate alternative source of method and method type (Nigeria-Kaduna, Round 2 & Indonesia)
capture confirm var fp_provider
if _rc==0 {
	if country=="ID" {
		recode fp_provider (11 12 13 16 17 19=0 "Public Health Center") ///
						   (14 15 18 =1  "Public Fieldworker/Mobile Outreach") ///
						   (21 22 23 24 25 26 28 =2 "Private Health Center/Provider") ///
						   (27=3 "Private Midwife") ///
						   (29=4 "Village Midwife") /// 
						   (30 42= 5 "Private shop/pharmacy") ///
						   (41 96 = 6 "Other") ///
						   (-88 -99=.), ///
						   gen (fp_provider2)
						   
		recode current_methodnum_rc (1 2 =96 "Female/Male Sterilization") ///
									(3 4 =1 "Implant/IUD") ///
									(5 6 = 2 "Injectable") ///
									(7 = 3 "Pill") ///
									(9 10 = 4 "Condom"), ///
									gen(method)	
		}
	if country=="NG" & round==2 & state==1 {
		recode fp_provider (11=0 "Public - Secondary") (12/15=1 "Public - Primary") ///
			(21 24/27=2 "Private Health Care Provider") (22/23 31=3 "Pharmacy/chemist") ///
			(33/96=4 "Other") (-88 -99=.), gen(fp_providerv2)
		}
	
	recode current_methodnum_rc (2 8 11 12 13 14 15 30/39=96 "Other") (3 4 =1 "Implant/IUD") ///
		(5 6 = 2 "Injectable") (7 = 3 "Pill") (9 10 = 4 "Condom") (1=5 "Sterilization") , gen(method)
		}	
		
****************************************
* REASONS FOR NON USE

* DRC Round 1 Does not include the why_not_using variable, therefore, this is 
*	not included in the 2-pager analysis
if country=="CD" & round==1 {
	}
else if (country=="CD" & round!=1) | country!="CD" {
* 	Collapse reasons into five categories

*		Not using because perceived not at risk (not married, lactating, 
*			infrequent/no sex, husband away, menopausal, subfecund, fatalistic)
	
*			Infrequent/no sex/husband away 
			gen nosex=0 if why_not_using!="" 
				replace nosex=1 if (why_not_usinghsbndaway==1 | why_not_usingnosex==1)
		
*			Menopausal/subfecund/amenorhheic
			gen meno=0 if why_not_using!="" 
			replace meno=1 if why_not_usingmeno==1 | why_not_usingnomens==1 ///
				| why_not_usingsubfec==1 
		
*			Lactating
			gen lactate=0 if why_not_using!=""
				replace lactate=1 if why_not_usingbreastfd==1
		
*			Combined no need due to perceived not at risk variables
			gen noneed=0 if why_not_using!="" 
				replace noneed=1 if nosex==1 | meno==1 | lactate==1 ///
					| why_not_usinguptogod==1
			label variable noneed "Perceived not at risk"
		
*		Not using because not married
		gen notmarried=0 if why_not_using!=""
			replace notmarried=1 if why_not_usingnotmarr==1
		label variable notmarried "Reason not using: not married"
	
*		Not using for method related reasons, includes fear of side effects, health
*			concers, interferes with bodies natural processes, inconvenient to use
		gen methodrelated=0 if why_not_using!=""
			replace methodrelated=1 if (why_not_usinghealth==1 | why_not_usingbodyproc==1 ///
			| why_not_usingfearside==1 | why_not_usinginconv==1)
		label variable methodrelated "Reason not using: method or health-related concerns"
	
*		Not using due to opposition that includes personal, partner, other, religious 
		gen opposition=0 if why_not_using!=""
			replace opposition=1 if why_not_usingrespopp==1|why_not_usinghusbopp==1 ///
			| why_not_usingotheropp==1 | why_not_usingrelig==1 
		label variable opposition "Reason not using: opposition to use"
	
*		Not using due to lack of access/knowledge
		gen accessknowledge=0 if why_not_using!=""
			replace accessknowledge=1 if why_not_usingdksource==1 | why_not_usingdkmethod==1 ///
				| why_not_usingaccess==1 | why_not_usingcost==1 | why_not_usingprfnotavail==1 ///
				| why_not_usingnomethod==1
		label variable accessknowledge "Reason not using: lack of access/knowledge"
	
*		Not using for other/no response/don't know
		gen othernoresp=0 if why_not_using!=""
			replace othernoresp=1 if ( why_not_usingother==1 | why_not_using=="-88" ///
				| why_not_using=="-99" )
		label variable othernoresp "Reason not using: other"

	
* 	Label yes/no response options
	foreach x in noneed nosex notmarried methodrelated opposition accessknowledge othernoresp {
		label values `x' yesno
		}
	}

save, replace

****************************************
* MEANS AND MEDIANS

* Generate program: Arguments to input are 1 (dataset), 2 (variable name), 
*	3 (lower age bound), 4 (weight)
capture program drop pma2020mediansimple
program define pma2020mediansimple
	
	use `1', clear
	keep if FQ_age>=`3' //age range for the tabulation
	
	gen one=1
	drop if `2'==.
	collapse (count) count=one [pweight=`4'], by(`2')
	sort  `2'
	gen ctotal=sum(count)
	egen total=sum(count)
	gen cp=ctotal/total
	
	keep if (cp <= 0.5 & cp[_n+1]>0.5) | (cp>0.5 & cp[_n-1]<=0.5)
	
	local median=(0.5-cp[1])/(cp[2]-cp[1])*(`2'[2]-`2'[1])+`2'[1] +1
	
	macro list _median
	
	clear
	set obs 1
	gen median=`median'
	
	end
	
* Generate variables for median and mean calculations
use "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.dta", clear

* 	Generate month and date from SIF birth and first marriage variables
*		Marriage - husband_firstSIFdate variable does not exist in DRC Round 1, 
*			and needs to be generated
		if country=="CD" & round==1 {
			gen husband_cohabit_start_firstSIF=FQSubmissionDateSIF
			gen husband_cohabit_start_recentSIF=FQSubmissionDateSIF
			}
		gen husband_firstSIFdate=dofc(husband_cohabit_start_firstSIF)
		gen husband_recentSIFdate=dofc(husband_cohabit_start_recentSIF)
		
*		Birth - birthdateSIF variable does not exist in DRC Round 1, and needs
*			to be generated
		if country=="CD" & round==1 {
			gen birthdateSIF=recent_birthSIF
			}
		gen birthdateSIFdate=dofc(birthdateSIF)
	
*	Generate respondent age variable in months
	gen birthyear=year(birthdateSIFdate)
	gen birthmonth=month(birthdateSIFdate)
		capture replace birthmonth=6 if birthdate_month==-88
	gen v011=(birthyear-1900)*12 + birthmonth 

* 		Generate age at first marriage variable
		gen firstmarriagemonth=month(husband_firstSIFdate)
		gen firstmarriageyear=year(husband_firstSIFdate)
		gen marriagecmc=(firstmarriageyear-1900)*12+firstmarriagemonth
		replace marriagecmc=(year(husband_recentSIFdate)-1900)*12+month(husband_recentSIFdate) if marriage_history==1
		gen agemarriage=(marriagecmc-v011)/12
			label variable agemarriage "Age at first marriage (25 to 49 years)"
	
*		Generate age at first birth variable - first_birthSIF does not exist in 
*			DRC Round one and needs to be generated
		if country=="CD" & round==1 {
			gen first_birthSIF=.
			}
		capture replace first_birthSIF=recent_birthSIF if birth_events==1
		capture replace first_birthSIF=recent_birthSIF if children_born==1 
		gen agefirstbirth=hours(first_birthSIF-birthdateSIF)/8765.81

* Save dataset to use in median calculations
save, replace


* Generate temp files for brief development

*	Create a local macro for the dataset to use during median calculations
*	local median_dataset "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.dta"
	tempfile median_file
	save `median_file', replace

*	Median age at first marriage
	preserve
		pma2020mediansimple `median_file' agemarriage 25 `weight'
		gen urban="All Women"
		tempfile afm_total
		save `afm_total', replace 
	restore

	preserve
		keep if urban==0
		capture codebook metainstanceID
		if _rc!=2000 { 
			save `median_file', replace
			pma2020mediansimple `median_file' agemarriage 25 `weight'
			gen urban="Rural"
			tempfile afm_rural
			save `afm_rural', replace
		}
	restore 

	preserve
		keep if urban==1
		capture codebook metainstanceID
		if _rc!=2000 { 
			save `median_file', replace
			pma2020mediansimple `median_file' agemarriage 25 `weight'
			gen urban="Urban"
			tempfile afm_urban
			save `afm_urban', replace
		}
	restore

* 	Median age at first sex among all women who have had sex
	preserve
		keep if age_at_first_sex>0 & age_at_first_sex<50 
		save `median_file', replace
		pma2020mediansimple `median_file' age_at_first_sex 15 `weight'
		gen urban="All Women"
		tempfile afs_total
		save `afs_total', replace
	restore
	
	preserve 
		keep if age_at_first_sex>0 & age_at_first_sex<50 & urban==0
		capture codebook metainstanceID
		if _rc!=2000 {
			save `median_file', replace
			pma2020mediansimple `median_file' age_at_first_sex 15 `weight'
			gen urban="Rural"
			tempfile afs_rural
			save `afs_rural', replace 
		}
	restore
	
	preserve 
		keep if age_at_first_sex>0 & age_at_first_sex<50 & urban==1 
		capture codebook metainstanceID
		if _rc!=2000 {
			save `median_file', replace
			pma2020mediansimple `median_file' age_at_first_sex 15 `weight'
			gen urban="Urban"
			tempfile afs_urban
			save `afs_urban',replace
		}
	restore

*	Median age at first contraceptive use among all women who have ever used contraception
	preserve
		keep if fp_ever_used==1 & age_at_first_use>0
		save `median_file', replace
		pma2020mediansimple `median_file' age_at_first_use 15 `weight'
		gen urban="All Women"
		tempfile afc_total
		save `afc_total', replace
	restore
	
	preserve
		keep if fp_ever_used==1 & age_at_first_use>0 & urban==0
		capture codebook metainstanceID
		if _rc!=2000 {
			save `median_file', replace
			pma2020mediansimple `median_file' age_at_first_use 15 `weight'
			gen urban="Rural"
			tempfile afc_rural
			save `afc_rural', replace
		}
	restore
	
	preserve
		keep if fp_ever_used==1 & age_at_first_use>0 & urban==1
		capture codebook metainstanceID
		if _rc!=2000 {
			save `median_file', replace
			pma2020mediansimple `median_file' age_at_first_use 15 `weight'
			gen urban="Urban"
			tempfile afc_urban
			save `afc_urban', replace
		}
	restore

* 	Median age at first birth among all women who have ever given birth. In older 
*		rounds of the PMA2020 survey, the variable "birth_events" was used to 
*		identify whether a women had given birth, contrastingly in newer rounds 
*		of the PMA2020 survey, the variable ever_birth was used.
	preserve
	capture confirm var ever_birth
	if _rc!=0 {
		keep if birth_events>0 & birth_events!=.
		}
	else {
		keep if ever_birth==1
		}
		save `median_file', replace
		pma2020mediansimple `median_file' agefirstbirth 25 `weight'
		gen urban="All Women"
		tempfile afb_total
		save `afb_total', replace
	restore
	
	preserve
	capture confirm var ever_birth
	if _rc!=0 {
		keep if birth_events>0 & birth_events!=.
		}
	else {
		keep if ever_birth==1
		}
		keep if urban==0
		capture codebook metainstanceID 
		if _rc!=2000 {
			save `median_file', replace
			pma2020mediansimple `median_file' agefirstbirth 25 `weight'
			gen urban="Rural"
			tempfile afb_rural
			save `afb_rural', replace
		}
	restore
	
	preserve
	capture confirm var ever_birth
	if _rc!=0 {
		keep if birth_events>0 & birth_events!=.
		}
	else {
		keep if ever_birth==1
		}
		keep if urban==1
		capture codebook metainstanceID 
		if _rc!=2000 {
			save `median_file', replace
			pma2020mediansimple `median_file' agefirstbirth 25 `weight'
			gen urban="Urban"
			tempfile afb_urban
			save `afb_urban', replace
		}
	restore

use "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.dta", clear

****************************************
* LIFE EVENTS BY 18 AND AGE-SPECFICIC RATES

* Percent of women age 18-24 having first birth by age 18 
gen birth18=0 if FQ_age>=18 & FQ_age<25
	replace birth18=1 if agefirstbirth<18 & birth18==0
label variable birth18 "Birth by age 18 (18-24)"
	
* Recode age at first use variable. In older rounds of the PMA2020 survey, the 
*	variable "birth_events" was used to identify whether a women had given birth, 
*	contrastingly in newer rounds of the PMA2020 survey, the variable 
*	ever_birth was used.
capture confirm var ever_birth
if _rc!=0 {
	replace age_at_first_use_children=0 if fp_ever_used==1 & birth_events==0
	}
else {
	replace age_at_first_use_children=0 if ever_birth==0 & fp_ever_used==1
	}

* Percent women 18-24 who are married by age 18
gen married18=0 if FQ_age>=18 & FQ_age<25
	replace married18=1 if agemarriage<18 & married18==0
label variable married18 "Married by age 18"
	
* Percent women 18-24 who have had first contraceptive use by age 18
gen fp18=0 if FQ_age>=18 & FQ_age<25
	replace fp18=1 if age_at_first_use>0 & age_at_first_use<18 & fp18==0 
label variable fp18 "Used contraception by age 18"

* Percent women who had first sex by age 18
gen sex18=0 if FQ_age>=18 & FQ_age<25
	replace sex18=1 if age_at_first_sex>0 & age_at_first_sex<18 & sex18==0 
label variable sex18 "Had first sex by age 18"

* Label yes/no response options
foreach x in married18 birth18 fp18 sex18 {
	label values `x' yesno
	}

* Age specific rates of long, short, tcp and unmet need
gen lstu=1 if longacting==1
	replace lstu=2 if longacting!=1 & mcp==1
	replace lstu=3 if tcp==1
	replace lstu=4 if unmettot==1
	replace lstu=5 if lstu==. 
	label define lstul 1 "Long acting" 2 "Short acting" 3 "Traditional" ///
		4 "Unmet need" 5 "Not using/no need"
	label val lstu lstul

* Generate 5-year age groups
egen age5=cut(FQ_age), at(15(5)50)
	
****************************************	
* Recode all "-99" as "0" to represent missing. For analytical purposes only, PMA2020 recodes -99 values to 0
capture recode fees_12months -88=0 -99=0
recode return_to_provider -88=0 -99=0
recode refer_to_relative -88=0 -99=0
recode fp_told_other_methods -88=0 -99=0
recode fp_side_effects -88=0 -99=0
recode fp_side_effects_instructions -88=0 -99=0
recode visited_by_health_worker -88=0 -99=0
recode pregnancy_last_desired -88=0 -99=0
recode pregnancy_current_desired -88=0 -99=0
recode visited_by_health_worker -88=0 -99=0
recode facility_fp_discussion -88=0 -99=0
recode fp_obtain_desired -88=0 -99=0
recode school -99=.

save, replace


*******************************************************************************
* SECTION 7: PMA2020 2-PAGE ANALYSIS BRIEF OUTPUT
*
* Section 7 generates the output that matches what is presented in PMA2020's
*	2-page analysis brief. Please do not move, update or delete for .do file 
*	to run correctly
*******************************************************************************

* ALERT FOR ALL DATA
pause on
di in smcl as error "Data presented in the 2-pagers online represent preliminary results and therefore there may be slight differences between the .do file results and those in the brief. Please access datalab at https://datalab.pmadata.org/ to cross check any discrepancies"
di in smcl as error "Please type 'end' to continue"
pause
pause off

* ALERT FOR DRC ROUND 1
pause on
if country=="CD" & round==1 {
	di in smcl as error "You are generating the 2-pager for the first round of data collection in the DRC. This alert is to inform you that the DRC Round 1 2-Pager does not contain all of the same indicators as in other DRC rounds and other PMA2020 countries. Therefore the 2-pager output does not contain the indicators related to Total Fertility Rate or reasons for non-use among all women wanting to delay. If you have any questions, please contact the PMA data management team at datamanagement@pma2020.org"
	di in smcl as error "Please type 'end' to continue"
	pause
	}
pause off

* ALERT FOR NO INDIA R1 2PAGER
pause on
if country=="RJ" & round==1 {
	di in smcl as error "You are generating the 2-pager for the first round of data collection in India. This alert is to inform you that there is no India Round 1 2-Pager available on the PMA website.  If you have any questions, please contact the PMA data management team at datamanagement@pma2020.org"
	di in smcl as error "Please type 'end' to conintue"
	pause
	}
pause off

* ALERT FOR NO INDONESIA REGIONAL 2PAGERS
pause on
if country=="ID" {
	di in smcl as error "You are generating the 2-pager for Indonesia. This alert it to inform you that although there are regional 2-Pagers for Rounds 1 and 2 of data collection available on the PMA website, this .do file will only generate the National-Level estimates. If you have any questions, please contact the PMA data management team at datamanagement@pma2020.org"
	di in smcl as error "Please type 'end' to continue"
	pause
	}
pause off

* ALERT FOR WEALTH TERTILES IN BURKINA FASO R1
pause on
if country=="BF" & round==1 {
	di in smcl as error "You are generating the 2-pager for Burkina Faso Round 1. This alert is to inform you that although the 2-pager presents wealth quintiles, the dataset you are using has wealth tertiles. Therefore, all results present wealth tertiles and not quintiles. If you have any questions, please contact the PMA data management team at datamanagement@pma2020.org"
	di in smcl as error "Please type 'end' to continue"
	pause
}
pause off

* ALERT FOR 2PAGERS THAT INCLUDE TFR
pause on 
if  (country=="BF" & (round==1 | round==2 | round==3)) | ///
	(country=="ET" & (round==1 | round==2 | round==3)) | ///
	(country=="CD" & (round==2 | round==3)) | ///
	(country=="GH" & (round==1 | round==2 | round==3 | round==4 | round==5)) | ///
	(country=="KE" & (round==1 | round==3)) | ///
	(country=="NE" & (round==1 | round==2)) | ///
	(country=="Nigeria" & round==1) | ///
	(country=="UG" & (round==1 | round==2)) {
	di in smcl as error "You are generating a 2-Pager that included Total Fertility Rate Estimates. PMA2020 is not powered to detect a meaningful change in TFR. Therefore, although TFR is included on the 2-Pager, PMA2020 is not including the caluclations in this .do file. If you have any quetions, please contact the PMA data managmeent team at datamanagement@pma2020.org"
	di in smcl as error "Please type 'end' to continue"
	pause
	}
pause off

*******************************************************************************
* IF SPECIFIC STATE/REGION KEEP ONLY THAT STATE/REGION
*******************************************************************************
gen wealth="`wealth'"
if wealth=="wealthtertile_Niamey" {
	keep if region==1 
	}
	
if wealth=="wealthquintile_Taraba" {
	keep if state==3
	}

if wealth=="wealthquintile_Rivers" {
	keep if state==5
	}
	
if wealth=="wealthquintile_Nasarawa" {
	keep if state==6
	}
	
if wealth=="wealthquintile_Lagos" {
	keep if state==2
	}
	
if wealth=="wealthquintile_Kano" {
	keep if state==4
	}
	
if wealth=="wealthquintile_Kaduna" {
	keep if state==1
	}
	
if wealth=="wealthquintile_Anambra" {
	keep if state==7
	}

*******************************************************************************
*
* FIRST PAGE
*
*******************************************************************************

*******************************************************************************
* Contraceptive Prevalence Rate
*******************************************************************************

* Tabout weighted proportion of contracpetive use (overall, modern, traditional, long acting) among all women
tabout cp mcp tcp longacting [aw=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	oneway c(col) f(1) clab(%) npos(row)  h2("CPR/mCPR/Long-acting - all women (weighted)") 

* Tabout weighted proportion of contracpetive use (overall, modern, traditional, long acting) among married women
tabout cp mcp tcp longacting if married==1 [aw=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	oneway c(col) f(1) clab(%) npos(row)  h2("CPR/mCPR/Long-acting - married women (weighted)") 

	
*******************************************************************************
* Unmet Need
*******************************************************************************
	
* Tabout weighted proportion of unmet need (categorical and dichotomous) among all women 
tabout unmettot unmet [aw=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	oneway c(col) f(1) clab(%) npos(row)  h2("Unmet need (categorical and dichotomous) - all women (weighted)") 

* Tabout weighted proportion of unmet need (categorical dichotomous) among married women 
tabout unmettot unmet if married==1 [aw=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	oneway c(col) f(1) clab(%) npos(row)  h2("Unmet need (categorical and dichotomous) - married women (weighted)") 

* Tabout weighted proportion of total demand among all women 
tabout totaldemand [aw=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	oneway c(col) f(1) clab(%) npos(row)  h2("Total demand for contraception - all women (weighted)") 

* Tabout weighted proportion of total demand among all women 
tabout totaldemand_sat [aw=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	oneway c(col) f(1) clab(%) npos(row)  h2("Contraceptive demand satisfied by modern method- all women (weighted)") 

* Tabout weighted proportion of total demand among married women 
tabout totaldemand if married==1 [aw=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	oneway c(col) f(1) clab(%) npos(row)  h2("Total demand for contraception - married women (weighted)") 

* Tabout weighted proportion of total demand among married women 
tabout totaldemand_sat if married==1 [aw=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	oneway c(col) f(1) clab(%) npos(row)  h2("Contraceptive demand satisfied by modern method- married women (weighted)") 

	
*******************************************************************************
* UNINTENDED BIRTHS
*******************************************************************************

* Tabout intendedness and wantedness among women who had a birth in the last 5 years or are currently pregnant
tabout unintend wanted if tsinceb<60 | pregnant==1 [aw=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	oneway c(col) f(1) clab(%) npos(row) h2("Intendedness (dichotomous and categorical) among women who had a birth in the last 5 years or are currently pregnant (weighted)")


*******************************************************************************
* CURRENT USE AND UNMET NEED AMONG MARRIED WOMEN BY WEALTH
*******************************************************************************

* Tabout current use and unmet need among married women of reproductive age, by wealth quintile (weighted)
tabout `wealth' cont_unmet if married==1 [aw=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	c(row) f(1) clab(%) npos(row) h1("Unmet need, traditional method, and modern method prevalence among married women (weighted)")
	
* Tabout weighted proportion of total demand among married women 
tabout totaldemand_sat `wealth' if married==1 [aw=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	c(col) f(1) clab(%) npos(row)  h1("Contraceptive demand satisfied by wealth - married women (weighted)") 
	

*******************************************************************************
* UNMET NEED AND CONTRACEPTIVE USE, BY AGE
*******************************************************************************

* Tabout unmet need, traditional, short-acting, and long-acting methods by 5-year age group
tabout age5 lstu [aw=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	c(row) f(2) h1("Use/need by age - all women (weighted)") 
	
	
*******************************************************************************
* SOURCE OF METHOD BY PROVIDER - KADUNA ROUND 2 and INDONESIA ONLY
*******************************************************************************
* Nigeria, Kaduna Round 2 2Pager
if wealth=="wealthquintile_Kaduna" & round==2 {

	* Tabout source of method by provider, married women aged 15-49
	tabout fp_providerv2 method if married==1 & cp==1 [aw=`weight'] ///
		using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
		c(col) f(1) clab(%) npos(row) h1("Source of Method, by Provider - married women (weighted)")
	}
	
* Indonesia
if country=="ID" {
	
	* Tabout source of method by provider, married modern contraceptive users aged 15-49
	tabout fp_providerv2 method if married==1 & mcp==1 [aw=`weight'] ///
		using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
		c(col) f(1) clab(%) npos(row) h1("Source of Method, by Provider - married modern contraceptive users (weighted)")
	}

*******************************************************************************
* METHOD MIX
*******************************************************************************

* Tabout current/recent method if using modern contraceptive method, among married women
tabout current_methodnum_rc if mcp==1 & married==1 & cp==1 [aweight=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	oneway c(col) f(1) clab(%) npos(row)  h2("Method mix - married women (weighted)")

* Tabout current/recent method if using modern contraceptive method, among unmarried sexually active women
tabout current_methodnum_rc if mcp==1 & umsexactive==1 & cp==1 [aweight=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	oneway c(col) f(1) clab(%) npos(row)  h2("Method mix - unmarried sexually active women (weighted)") 

*******************************************************************************
*
* SECOND PAGE
*
*******************************************************************************

*******************************************************************************
* CHOICE INDICATORS BY URBAN/RURAL 
*******************************************************************************
* Analysis only includes Nigeria-Kano Round 2 & 3, Nigeria-Taraba Round 1 & 3
if  (wealth=="wealthquintile_Kano" & (round==4 | round==5)) | ///
	(wealth=="wealthquintil_Taraba" & (round==3 | round==5)) {
	
* Tabout who chose method by urban/rural (weighted) among current users
tabout methodchosen ur if mcp==1 [aweight=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	c(col) f(1) clab(%) npos(row)  h1("Method chosen - current modern user (weighted)")
	
* Tabout obtained method of choice by urban/rural (weighted) among current users
tabout fp_obtain_desired ur if mcp==1 [aweight=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	c(col) f(1) clab(%) npos(row)  h1("Obtained method of choice by wealth - current modern user (weighted)")

* Tabout told of other methods by urban/rural (weighted) among current users
tabout fp_told_other_methods ur if mcp==1 [aweight=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	c(col) f(1) npos(row)  h1("Told of other methods by wealth - current modern user (weighted)")

* Tabout counseled on side effects by urban/rural (weighted) among current users
tabout fp_side_effects ur if mcp==1 [aweight=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	c(col) f(1) npos(row)  h1("Told about side effects by wealth - current modern user (weighted)")

* Tabout paid for services by urban/rural (weighted) among current users 
tabout fees_paid_lastvisit ur if mcp==1 [aweight=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	c(col) f(1) npos(row)  h1("REWORDED QUESTION FROM PREVIOUS ROUNDS Paid for FP services at last visit by wealth - current modern user (weighted)")

* Tabout would return to provider by urban/rural (weighted) among current users
tabout returnrefer ur if cp==1 [aweight=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	c(col) f(1) npos(row)  h1("Return to/refer provider by wealth - current modern user (weighted)") 

}

*******************************************************************************
* CHOICE INDICATORS BY WEALTH
*******************************************************************************
*Analysis does not include Nigeria-Kano Round 2 & 3, Nigeria-Taraba Round 1 & 3
else {

* Tabout who chose method by wealth quintile (weighted) among current users
tabout methodchosen `wealth' if mcp==1 [aweight=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	c(col) f(1) clab(%) npos(row)  h1("Method chosen - current modern user (weighted)")
	
* Tabout obtained method of choice by wealth (weighted) among current users
tabout fp_obtain_desired `wealth' if mcp==1 [aweight=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	c(col) f(1) clab(%) npos(row)  h1("Obtained method of choice by wealth - current modern user (weighted)")

* Tabout told of other methods by wealth (weighted) among current users
tabout fp_told_other_methods `wealth' if mcp==1 [aweight=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	c(col) f(1) npos(row)  h1("Told of other methods by wealth - current modern user (weighted)")

* Tabout counseled on side effects by wealth (weighted) among current users
tabout fp_side_effects `wealth' if mcp==1 [aweight=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	c(col) f(1) npos(row)  h1("Told about side effects by wealth - current modern user (weighted)")

* Tabout paid for services by wealth (weighted) among current users 
tabout fees_paid_lastvisit `wealth' if mcp==1 [aweight=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	c(col) f(1) npos(row)  h1("REWORDED QUESTION FROM PREVIOUS ROUNDS Paid for FP services at last visit by wealth - current modern user (weighted)")

* Tabout would return to provider by wealth (weighted) among current users
tabout returnrefer `wealth' if mcp==1 [aweight=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	c(col) f(1) npos(row)  h1("Return to/refer provider by wealth - current modern user (weighted)") 
}

*******************************************************************************
* RECEIVED A METHOD FROM A PUBLIC SDP
*******************************************************************************

* Tabout whether received contraceptive method from public facility by wealth (weighted) among current users
tabout public_fp `wealth' if mcp==1 [aw=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	c(col) f(1) npos(row)  h1("Respondent/partner received method from public facility initially by wealth - current modern user (weighted)") 

* Tabout percent unintended births is the only indicator in the section not restricted to current users (all others restricted to current users)
tabout unintend `wealth' if tsinceb<60 | pregnant==1 [aweight=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	c(col) f(1) npos(row)  h1("Percent unintended by wealth - current user (weighted)") 

*******************************************************************************
* REASON FOR NON-USE
*******************************************************************************

* This indicator is not included in DRC R1
if country=="CD" & round==1 {
	}
else if (country=="CD" & round!=1) | country!="CD" {
* Tabout reasons for not using contraception among all women wanting to delay the next birth for 2 or more yeras
tabout notmarried noneed methodrelated opposition accessknowledge othernoresp [aweight=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls",	append ///
	oneway c(freq col) f(0 1) npos(row) h2("Reasons for non-use - among all women wanting to delay (weighted)") 
	
	}

*******************************************************************************
* MEDIANS
*******************************************************************************

* Install the new command needed for the change
ssc install listtab, all replace


* Median age at first marriage among all women who have married
*	Append Datasets
	preserve
	use `afm_total', clear
	capture append using `afm_rural'
	capture append using `afm_urban'

*	Tabout median age at first marriage among all women who have married
	listtab urban median, appendto("PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls") ///
		rstyle(tabdelim) headlines("Median age at marriage among all women who have married- by urban/rural (weighted)") footlines(" ")
	restore

* Median age at first sex among all women who have had sex
*	Append Datasets
	preserve
	use `afs_total', clear
	capture append using `afs_rural'
	capture append using `afs_urban'

*	Tabout median age at first sex among all women who have had sex
	listtab urban median, appendto("PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls") ///
		rstyle(tabdelim) headlines("Median age at first sex - among all women who have had sex by urban/rural(weighted)") footlines(" ")
	restore

* Median age at first contraceptive use among all women who have ever use contraception
*	Append Datasets
	preserve
	use `afc_total', clear
	capture append using `afc_rural'
	capture append using `afc_urban'

*	Tabout median age at first contraceptive use among all women who have ever used contraception
	listtab urban median, appendto("PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls") ///
		rstyle(tabdelim) headlines("Median age at first contraceptive use - among all women who have used contraception by urban/rural (weighted)") footlines(" ")
	restore

* Median age at first birth among all women who have ever given birth
*	Append Datasets
	preserve
	use `afb_total', clear
	capture append using `afb_rural'
	capture append using `afb_urban'

*	Tabout median age at first birth among all women who have ever given birth
	listtab urban median, appendto("PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls") ///
		rstyle(tabdelim)  headlines("Median age at first birth - among all women who have given birth by urban/rural(weighted)") footlines(" ")
	restore

*******************************************************************************
* MEANS
*******************************************************************************

* Tabout mean no. of living children at first contraceptive use among women who have ever used contraception 
tabout urban if fp_ever_used==1 & age_at_first_use_children>=0 [aweight=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	sum c(mean age_at_first_use_children) f(3) npos(row)  h2("Mean number of children at first contraceptive use - among all women who have used contraception (weighted)") 

* Tabout birth by age 18 among all women by urban/rural, weighted
tabout birth18 urban [aweight=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	c(col) f(1) npos(row)  h1("Birth by age 18 (18-24) - among all women (weighted)") 

* Tabout received family planning information from provider in last 12 months among all women by urban/rural, weighted
tabout healthworkerinfo urban [aweight=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	c(col) f(1) npos(row)  h1("Received FP info. from provider in last 12 months - among all women (weighted)") 

* Tabout received family planning information from provider in last 12 months among all women by urban/rural, weighted
tabout fpmedia urban [aweight=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	c(col) f(1) npos(row)  h1("Exposed to FP media in last few months - among all women (weighted)") 

*******************************************************************************
* LIFE EVENTS BY AGE 18 AND AGE SPECIFIC RATES
*******************************************************************************	

* Tabout married by 18, first birth before 18, contraceptive use by 18, first sex by 18 among women age 18-24 (weighted)
tabout married18 sex18 fp18 birth18 if FQ_age>=18 & FQ_age<25 [aw=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	oneway c(col) f(1) clab(%) npos(row) h2("Married by 18, first sex by 18, contraceptive use by 18, first birth before 18 - women age 18-24 (weighted)") 

* Tabout 
tabout age5 lstu [aw=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls", append ///
	cells(row) h1("Use/need by age - all women (weighted)") f(2)

*******************************************************************************
* DEMOGRAPHIC VARIABLES (NOT INCLUDED ON 2-PAGER)
*******************************************************************************
* Distribtuion of de facto women by age
tabout age5 [aw=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls",  append  ///
	c(freq col) f(0 1) clab(n %) npos(row)  h2("Distribution of de facto women by age - weighted")

* Distribution of de facto women by education
tabout school [aw=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls",  append  ///
	c(freq col) f(0 1) clab(n %) npos(row)  h2("Distribution of de facto women by education - weighted")

* Distribution of de facto women by marital status
tabout FQmarital_status [aw=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls",  append  ///
	c(freq col) f(0 1) clab(n %) npos(row)  h2("Distribution of de facto women by marital status - weighted")

* Distribution of de facto women by wealth
tabout `wealth' [aw=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls",  append  ///
	c(freq col) f(0 1) clab(n %) npos(row)  h2("Distribution of de facto women by wealth - weighted")

* Distribution of de facto women by sexual activity
tabout sexactive  [aw=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls",  append  ///
	c(freq col) f(0 1) clab(n %) npos(row)  h2("Distribution of de facto women by sexual activity - weighted")

* Distribution of de facto women by urban/rural
tabout urban [aw=`weight'] ///
	using "PMA2020_`country'_`round'_HHQFQ_2Page_Analysis_`date'.xls",  append ///
	c(freq col) f(0 1) clab(n %) npos(row)  h2("Distribution of de facto women by urban/rural - weighted")


*******************************************************************************
* CLOSE
*******************************************************************************

log close
