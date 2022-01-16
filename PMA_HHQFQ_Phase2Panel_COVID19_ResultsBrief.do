/*******************************************************************************
* The following .do file will create the .xls file output that PMA used to 
* 	generate its Phase 2 Panel COVID-19 briefs using PMA's publicly available  
*	Household and Female dataset
*
* This .do file will only work on Phase 1 and Phase 2 HHQFQ panel datasets that 
*	also contain COVID-19 data. You can  find the .do files to generate the .xls 
*	file outputs for PMA's publicly available Phase 2 SDP, CQ and Panel datasets 
*	and other surveys in the PMA_Analyses_Public repository
*
* If you have any questions on how to use this or any of the other .do files in
* 	the PMA_Analyses_Public repository, please contact the PMA Data Management 
* 	Team at datamanagement@pma2020.org
*******************************************************************************/

/*******************************************************************************
*
*  FILENAME:		PMA_HHQFQ_Phase2Panel_COVID19_ResultsBrief.do
*  PURPOSE:			Generate the .xls output for the PMA Phase 2 COVID-19 Results Brief
*  CREATED BY: 		Elizabeth Larson (elarso11@jhu.edu)
*  DATA IN:			PMA's Phase2 Panel HHQFQ publicly released datasets
*  DATA OUT: 		PMA_COUNTRY_Phase2_Panel_COVID19_Analysis_DATE.dta
*  FILE OUT: 		PMA_COUNTRY_Phase2_Panel_COVID19_Analysis_DATE.xls
*  LOG FILE OUT: 	PMA_COUNTRY_Phase2_Panel_COVID19_Log_DATE.log
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

*	1. A directory for the folder where you want to save the dataset, xls and
*		log files that this .do file creates
*		- For example (Mac): 
*		  local briefdir "/User/ealarson/Desktop/PMA2020/NigeriaAnalysisOutput"
*		- For example (PC): 
*		  local briefdir "C:\Users\annro\PMA2020\NigeriaAnalysisOutput"
local briefdir "/Users/ealarson/Documents/PMA/Burkina Faso/PublicRelease/Phase 2"

************** DATASETS & DATES *************

***** FIRST DATASET *****
* Dataset 1 Directory
local PMAdataset1 "/Users/ealarson/Dropbox (Gates Institute)/5 Burkina Faso/PMABF_Datasets/Phase1/Final_PublicRelease/HQFQ/PMA2020_BFP1_HQFQ_v2.0_1Oct2021/PMA2020_BFP1_HQFQ_v2.0_1Oct2021.dta"

***** SECOND DATASET *****
* Dataset 2 Directory
local PMAdataset2 "/Users/ealarson/Dropbox (Gates Institute)/5 Burkina Faso/PMABF_Datasets/Phase2/Final_PublicRelease/HQFQ/PMA2021_BFP2_HQFQ_v1.0_7Oct2021/PMA2021_BFP2_HQFQ_v1.0_1Oct2021.dta"

***** COVID-19 DATASET *****
local COVID19dataset "/Users/ealarson/Dropbox (Gates Institute)/5 Burkina Faso/PMABF_Datasets/Covid_FQFU/Final_PublicRelease/PMA_BFP1_Covid19_FQFU_v1.1_28Feb2021/PMA2020_BFP1_COVID19_FQFU_v1.1_28Feb2021.dta"

*******************************************************************************
* SECTION 2: SET MACROS FOR THE COUNTRY, WEIGHT, WEALTH AND EDUCATION
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

*	2. The weight local macro should be the weight variable that is used for  
*		analyzing the data. Generally, it will be "FQweight", however for certain
*		geographies, such as Nigeria, you will need to specify the weight for the
*		specific geography that you are analyzing. You can identify the correct 
*		weight by searching for variables that begin with "FQweight" in the 
*		dataset
*		- For example (Nigeria): FQweight_National
*		- For example (Burkina Faso): FQweight
local weight "FQweight"

*	3. The wealth local macro should be the wealth variable that is used for
*		analyzing the data. Generally, it will generally be "wealthq" or, 
*	    however for certain geographies, such as Nigeria, you will need to
*		specify the wealth for the specific geography that you are analyzing.
*		You can identify the correct wealth by searching for variables that  
*		begin with "wealth" in the dataset
*		- For example (Nigeria): wealth_National
*		- For example (Burkina Faso): wealth
local wealth "wealthtertile"

*	4. The education macros correspond to the coding of the school variable for
*	    each designated education level. In the briefs, PMA codes education as: 
*	    1) None or primary education; 2) Secondary; or 3) Tertiary. In the
*	    public release dataset, the school variable is labeled to facilitate 
*	    the identification of the levels. There is not check for these locals in
*	 	this .do file, therefore, if indicators that are disagregated by
*		education to not match the PMA brief output, please check that you coded
*		the macros correctly

local none_primary_education "(school==0| school==1)"
local secondary_education "(school==2 | school==3)"
local tertiary_education  "(school==4 | school==5)"

*	5. The level1 macro corresponds to the highest geographical level in the
*	    the dataset. This is likely county, state, region, or province
*		- For example (Kenya): county
*		- For example (Burkina Faso) region
local level1 region


*******************************************************************************
* SECTION 3: CREATE MACRO FOR DATE, AND CHECK MACROS
*
* Section 3 is necessary to make sure the .do file runs correctly, please do not 
*	move, update or delete
*******************************************************************************

* Set local/global macros for current date
local today=c(current_date)
local c_today= "`today'"
local date=subinstr("`c_today'", " ", "",.)

* Set main output directory
cd "`briefdir'"

* Confirm that correct variables were chosen for locals
use "`PMAdataset2'"

*	Country Variable
	gen countrycheck="`country'"
	gen check=(countrycheck==country)
	if check!=1 {
		di in smcl as error "The specified country is not the correct coding for this phase of data collection. Please search for the country variable in the dataset to identify the correct country code, update the local and rerun the .do file"
		exit
		}
	drop countrycheck check

*	Weight Variable
	capture confirm var `weight'
	if _rc!=0 {
		di in smcl as error "Variable `weight' not found in dataset. Please search for the correct weight variable in the dataset and update the local macro 'weight'. If you are doing a regional/state-level analysis, please make sure that you have selected the correct variable for the geographic level, update the local and rerun the .do file"
		exit
		}
		
*	Wealth Variable	
	capture confirm var `wealth'
	if _rc!=0 {
		di in smcl as error "Variable `wealth' not found in dataset. Please search for the correct wealth variable in the dataset and update the local macro 'wealth'. If you are doing a regional/state-level analysis, please make sure that you have selected the correct variable for the geographic level, update the local and rerun the .do file"
		exit
		} 

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
				di in smcl as error "The specified sub-national level is not correct. Please search for the sub-national variable in the dataset to identify the correct spelling of the sub-national level, update the local and rerun the .do file."
				exit	
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
		capture quietly regress check province
			if _rc==2000 {
				di in smcl as error "The specified sub-national level is not correct. Please search for the sub-national variable in the dataset to identify the correct spelling of the sub-national level, update the local and rerun the .do file"
				exit		
				}
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
				exit
				}
		local country `country'_`subnational'
		drop subnational province_string subnational_keep subnational_keep1 check
		}	
		
*	Nigeria
	if country=="Nigeria" & subnational_yn=="yes" {
		gen subnational="`subnational'"
		decode state, gen(state_string)
		gen subnational_keep=substr(state_string,4,.)
		gen subnational_keep1=subinstr(subnational_keep," ","",.)
		gen check=(subnational_keep1==subnational)
		keep if check==1
		capture quietly regress check state
			if _rc==2000 {
				di in smcl as error "The specified sub-national level is not correct. Please search for the sub-national variable in the dataset to identify the correct spelling of the sub-national level, update the local and rerun the .do file"
				exit
				}
		local country `country'_`subnational'
		drop subnational state_string subnational_keep subnational_keep1 check
		}	
		
*	Countries without national analysis
	if (country=="DRC" | country=="Nigeria") & subnational_yn!="yes" {
		di in smcl as error "Please specify a sub-national level for this country as national analysis is not available. Please search for the sub-national variable in the dataset to identify the correct spelling of the sub-national level, update the local and rerun the .do file"
		exit
		}
		
* Start log file
log using "`briefdir'/PMA_`country'_Phase2_Panel_COVID19_Analysis_`date'.log", replace		

* Set local for xls file
local tabout "PMA_`country'_Phase2_Panel_COVID19_Analysis_`date'.xls"

* Set local for dataset
local dataset "PMA_`country'_Phase2_Panel_COVID19_Analysis_`date'.dta"

tempfile Phase2
save `Phase2', replace

*******************************************************************************
* SECTION 4: GENERATE NECESSARY VARIBLES AND SET UP DATA FOR ANALYSIS
*
* Section 6 is necessary to make sure the .do file runs correctly, please do not 
*	move, update or delete
*******************************************************************************
****************************************	
* PHASE 2 DATA
use "`Phase2'", clear

****************************************	
* MARITAL STATUS

* Generate dichotomous "married" variable to represent all women married or 
*	currently living with a man
gen married=1 if marital_status!=-99
	replace married=2 if marital_status==1 | marital_status==2
	label define married_list 1 "Single/Divorced/Widowed/Seperated" ///
		2 "Married/Currently living with a man"
	label values married married_list
	label variable married "Married or currently living with a man"
		
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
* AGE
recode age -99=. -88=. -77=.
	egen age5=cut(age) , at (15(5)50)
	recode age5 (15=0) (20=1) (25 30=2) (35 40 45=3)
	label define age5_lab 0 "15-19" 1 "20-24" 2 "25-34" 3 "35-49"
	label values age5 age5_lab
	label var age5 "Age Categories"
	
****************************************
* DIFFICULTY ACCESSING HEALTH CARE
gen any_difficulty=0 if why_visited_facility_4w != "" & why_visited_facility_4w != "-77"
foreach var in closed husbopp notransport restricted cost fear {	
	replace any_difficulty=1 if access_difficulty_4w_`var'==1 & why_visited_facility_4w != "" & why_visited_facility_4w != "-77"
	}
label val any_difficulty yes_no_nr_list
label var any_difficulty "Did the woman face any difficulty accessing care?"

save `Phase2', replace
	
****************************************	
* PHASE 1 DATA
use "`PMAdataset1'"
tempfile Phase1 
save `Phase1', replace

****************************************	
* MARITAL STATUS

* Generate dichotomous "married" variable to represent all women married or 
*	currently living with a man
gen married=1 if FQmarital_status!=-99
	replace married=2 if FQmarital_status==1 | FQmarital_status==2
	label define married_list 1 "Single/Divorced/Widowed/Seperated" ///
		2 "Married/Currently living with a man"
	label values married married_list
	label variable married "Married or currently living with a man"
	
****************************************	
* ONLY KEEP PHASE 1 VARIABLES REQUIRED FOR ANALYSIS
keep FQmetainstanceID `level1' wealth married FRS_result 
rename FQmetainstanceID female_ID

****************************************
* DROP NON-FEMALE FORMS
drop if female_ID==""

****************************************
* RENAME VARIABLES TO IDENTIFY AS P1
rename * *_P1
rename female_ID_P1 female_ID

save `PHASE1', replace

****************************************	
* COVID-19 DATA
use "`COVID19dataset'"
tempfile Covid
save `Covid', replace

* Restrict analysis to women who fulfullied our analysis criteria: 
*Analysis criteria:  Women aged<50 who completed the Covid survey, were successfully logitudinally linked with their P1 data.
keep if COV_result==1 & female_ID!=""
drop if age>49

* Only Keep Covid Variables Required for Analysis
keep female_ID cFQFUweight self_covid_concern lack_food_24h /// 
reliant_finance why_visited_facility why_visit_facility_fp health_facility_difficulty ///
health_facility_diff_closed ///
health_facility_diff_husbopp health_facility_diff_notransport ///
health_facility_diff_restricted health_facility_diff_cost health_facility_diff_fear ///
health_facility_diff_none accessed_health ///
COV_result

****************************************	
* DIFFICULTY ACCESSING HEALTH CARE
gen any_difficulty=0 if why_visited_facility != ""
foreach var in closed husbopp notransport restricted cost fear {	
	replace any_difficulty=1 if health_facility_diff_`var'==1 & why_visited_facility != ""
	}
label val any_difficulty yes_no_list
label var any_difficulty "Did the woman face any difficulty accessing care?"


* Drop non-female forms
drop if female_ID==""

****************************************
* MERGE DATASETS	
merge 1:1 female_ID using `Phase1'
keep if _merge==3
	drop _merge
	
* Recode all negative values as missing
foreach var in self_covid_concern lack_food_24h reliant_finance ///
why_visit_facility_fp accessed_health {
	recode `var' -99 -88 -77=.
	}
	
* Recode in string variable	
foreach var in why_visited_facility health_facility_difficulty {
replace `var' ="" if (`var' == "-99"|	`var' == "-88"|`var' == "-77")
}	

save `dataset', replace



*******************************************************************************
* SECTION 5: PMA RESULTS BRIEF OUTPUT
*
* Section 7 generates the output that matches what is presented in PMA's
*	analysis brief. Please do not move, update or delete for .do file 
*	to run correctly
*******************************************************************************

* ALERT FOR ALL DATA
pause on
di in smcl as error "Data presented in the online briefs represent preliminary results and therefore there may be slight differences between the .do file results and those in the brief. Please access datalab at https://datalab.pmadata.org/ to cross check any discrepancies"
di in smcl as error "Please type 'end' to continue"
pause
pause off

*******************************************************************************
*
* SECTION 1: CONCERN ABOUT COVID-19
*
*******************************************************************************

*******************************************************************************
* Concern about getting COVID-19
*******************************************************************************
* Percent of respondents who are worried about getting infected
* 	among all women 

** Tabout - COVID DATA
use `dataset', clear
tabout self_covid_concern [aw=cFQFUweight] ///
	using `tabout', mi replace c(freq col) f(0 1) clab(n %) npos(row) ///
		h2("Percent of respondents at the time of the Covid19 survey who are worried about getting infected - women who heard of COVID Weighted")
		
** Tabout - PHASE 2 DATA
use `Phase2', clear
tabout self_covid_concern [aw=FQweight] ///
	using `tabout', append c(freq col) f(0 1) clab(n %) npos(row) ///
	h2("Percent of respondents at P2 who are worried about getting infected with Covid-19 - all women Weighted")
	

*******************************************************************************
*
* SECTION 2: ECONOMIC IMPACT OF COVID-19
*
*******************************************************************************

*******************************************************************************
* Household Income Loss
*******************************************************************************

* Percent of respondents who experienced household income loss due to COVID-19
*	among all respondents
tabout income_loss_from_covid `wealth' [aw=FQweight] ///
	using `tabout', append c(freq col) f(0 1) clab(n %) npos(row) ///
	h1("Percent of respondents at P2 who have experienced HH income loss in last 12m, of which that loss was due to Covid (by wealth) - All Women Weighted")

*******************************************************************************
* Household Income Recovery
*******************************************************************************	
	
** Percent of HH income Recovery from COVID-19
*	among women who experience HH income loss
tabout income_recovery `wealth' if income_loss_from_covid==1 [aw=FQweight] ///
	using `tabout', append c(freq col) f(0 1) clab(n %) npos(row) ///
	h1("Percent of respondents at P2 who report partial/complete/no recovery of HH income loss from Covid (by wealth) - Among women with HH income loss due to Covid-19 Weighted")
	
*******************************************************************************
* Food Insecurity
*******************************************************************************	

** Percent of respondents who experienced food insecurity during COVID-19

** Tabout - COVID DATA
*	Among women who have heard of COVID 
use `dataset', clear
tabout lack_food_24h `wealth' [aw=cFQFUweight] ///
	using `tabout', append c(freq col) f(0 1) clab(n %) npos(row) ///
	h1("Percent of respondents at the time of the Covid19 survey who experienced food insecurity during Covid restrictions (by wealth) - Women who heard of Covid Weighted")
	
** Tabout - PHASE 2 DATA
*	Among all women
use `Phase2', clear
tabout lack_food_24h_4w `wealth' [aw=FQweight] ///
	using `tabout', append c(freq col) f(0 1) clab(n %) npos(row) ///
	h1("Percent of respondents at P2 who experienced food insecurity in the last 4 weeks (by wealth) - All Women Weighted")
	
*******************************************************************************
* Economic Reliance
*******************************************************************************	

** Percent of respondents who are economically reliant on their partner
*	Among married women

** Tabout - COVID DATA
use `dataset', clear
tabout reliant_finance `wealth' if married==2 [aw=cFQFUweight] ///
	using `tabout', append c(freq col) f(0 1) clab(n %) npos(row) ///
	h1("Percent of respondents at the time of the Covid19 survey who were economically reliant on partner (by wealth) - Married Women Weighted")
	
** Tabout - PHASE 2 DATA
use `Phase2', clear
tabout reliant_finance `wealth' if married==2 [aw=FQweight] ///
	using `tabout', append c(freq col) f(0 1) clab(n %) npos(row) ///
	h1("Percent of respondents in-union at P2 who were economically reliant on partner (by wealth) - Married Women Weighted")	
	
*******************************************************************************
*
* SECTION 3: BARRIER TO ACCESSING HEALTH SERVICES
*
*******************************************************************************

*******************************************************************************
* Want to Visit a Health Facility
*******************************************************************************

* Percent of respondents who want to visit a health facility for family planning
*	among women who wanted to visit a health facility for any reason

** Tabout - COVID DATA
use `dataset', clear
tabout why_visit_facility_fp `wealth' [aw=cFQFUweight] ///
	using `tabout', append c(freq col) f(0 1) clab(n %) npos(row) ///
	h1("Percent of respondents at the time of the covid19 survey who wanted to visit a health facility for family planning (by wealth) - Women who wanted to visit a facility for any reason (weighted)")	
	
** Tabout - PHASE 2 DATA
use `Phase2', clear
tabout why_visit_facility_fp `wealth' if why_visited_facility_4w!="-77" [aw=FQweight] ///
	using `tabout', append c(freq col) f(0 1) clab(n %) npos(row) ///
	h1("Percent of respondents at P2 who wanted to visit a health facility for family planning in the last 4 weeks (by wealth) - Women who wanted to visit a facility for any reason (weighted)")	
	
*******************************************************************************
* Difficulty Accessing a Health Facility
*******************************************************************************

* Percent of respondents who experienced any difficulty in accessing healthcare
*	among women who wanted to visit a health facility for any reason

** Tabout - COVID DATA
use `dataset', clear
tabout any_difficulty `wealth' if  why_visited_facility != "" [aw=cFQFUweight] ///
	using `tabout', append c(freq col) f(0 1) clab(n %) npos(row) ///
	h1("Percent experienced any difficulty in accessing healthcare at the time of the covid19 survey (by wealth) - Women who wanted to visit a health facility for any reason (weighted)")	
	
** Tabout - PHASE 2 DATA
use `Phase2', clear
tabout any_difficulty `wealth' if  why_visited_facility_4w != "" & why_visited_facility_4w != "-77" [aw=FQweight] ///
	using `tabout', append c(freq col) f(0 1) clab(n %) npos(row) ///
	h2("Percent Experienced any difficulty in accessing healthcare at P2 (by wealth) - Women who wanted to visit a health facility for any reason (weighted)")
	
*******************************************************************************
* Reasons for Difficulty Accessing Health Facility
*******************************************************************************

* Percent of woman who had specific difficult in accessing health care
** among women who wanted to visit a health facilty for any reason

** Tabout - COVID DATA
use `dataset', clear

	* Facilty Closed
	tabout health_facility_diff_closed `wealth' if why_visited_facility!="" [aw=cFQFUweight] ///
	using `tabout', append c(freq col) f(0 1) clab(n %) npos(row) ///
	h1("Percent experienced any difficulty in accessing healthcare because the facility was closed at the time of the covid19 survey (by wealth) - Women who wanted to visit a health facility for any reason (weighted)")
	
	* Partner Disapproval
	tabout health_facility_diff_husbopp `wealth' if why_visited_facility!="" [aw=cFQFUweight] ///
	using `tabout', append c(freq col) f(0 1) clab(n %) npos(row) ///
	h1("Percent experienced any difficulty in accessing healthcare because their partner disapproved at the time of the covid19 survey (by wealth) - Women who wanted to visit a health facility for any reason (weighted)")
	
	* Lack of transportation
	tabout health_facility_diff_notransport `wealth' if why_visited_facility!="" [aw=cFQFUweight] ///
	using `tabout', append c(freq col) f(0 1) clab(n %) npos(row) ///
	h1("Percent experienced any difficulty in accessing healthcare because of a lack of transportation at the time of the covid19 survey (by wealth) - Women who wanted to visit a health facility for any reason (weighted)")
	
	* Government restrictions on movement
	tabout health_facility_diff_restricted `wealth' if why_visited_facility!="" [aw=cFQFUweight] ///
	using `tabout', append c(freq col) f(0 1) clab(n %) npos(row) ///
	h1("Percent experienced any difficulty in accessing healthcare because of government restrictions at the time of the covid19 survey (by wealth) - Women who wanted to visit a health facility for any reason (weighted)")
	
	* Cost
	tabout health_facility_diff_cost `wealth' if why_visited_facility!="" [aw=cFQFUweight] ///
	using `tabout', append c(freq col) f(0 1) clab(n %) npos(row) ///
	h1("Percent experienced any difficulty in accessing healthcare because of cost at the time of the covid19 survey (by wealth) - Women who wanted to visit a health facility for any reason (weighted)")
	
	* Fear of COVID-19 at facility
	tabout health_facility_diff_fear `wealth' if why_visited_facility!="" [aw=cFQFUweight] ///
	using `tabout', append c(freq col) f(0 1) clab(n %) npos(row) ///
	h1("Percent experienced any difficulty in accessing healthcare because of fear of Covid-19 at the facility at the time of the covid19 survey (by wealth) - Women who wanted to visit a health facility for any reason (weighted)")


** Tabout - PHASE 2 DATA 
use `Phase2', clear

	* Facilty Closed
	tabout access_difficulty_4w_closed `wealth' if why_visited_facility!="" [aw=FQweight] ///
	using `tabout', append c(freq col) f(0 1) clab(n %) npos(row) ///
	h1("Percent experienced any difficulty in accessing healthcare because the facility was closed at the time of the P2 survey (by wealth) - Women who wanted to visit a health facility for any reason (weighted)")
	
	* Partner Disapproval
	tabout access_difficulty_4w_husbopp `wealth' if why_visited_facility!="" [aw=FQweight] ///
	using `tabout', append c(freq col) f(0 1) clab(n %) npos(row) ///
	h1("Percent experienced any difficulty in accessing healthcare because their partner disapproved at the time of the P2 survey (by wealth) - Women who wanted to visit a health facility for any reason (weighted)")
	
	* Lack of transportation
	tabout access_difficulty_4w_notransport `wealth' if why_visited_facility!="" [aw=FQweight] ///
	using `tabout', append c(freq col) f(0 1) clab(n %) npos(row) ///
	h1("Percent experienced any difficulty in accessing healthcare because of a lack of transportation at the time of the P2 survey (by wealth) - Women who wanted to visit a health facility for any reason (weighted)")
	
	* Government restrictions on movement
	tabout access_difficulty_4w_restricted `wealth' if why_visited_facility!="" [aw=FQweight] ///
	using `tabout', append c(freq col) f(0 1) clab(n %) npos(row) ///
	h1("Percent experienced any difficulty in accessing healthcare because of government restrictions at the time of the P2 survey (by wealth) - Women who wanted to visit a health facility for any reason (weighted)")
	
	* Cost
	tabout access_difficulty_4w_cost `wealth' if why_visited_facility!="" [aw=FQweight] ///
	using `tabout', append c(freq col) f(0 1) clab(n %) npos(row) ///
	h1("Percent experienced any difficulty in accessing healthcare because of cost at the time of the P2 survey (by wealth) - Women who wanted to visit a health facility for any reason (weighted)")
	
	* Fear of COVID-19 at facility
	tabout access_difficulty_4w_fear `wealth' if why_visited_facility!="" [aw=FQweight] ///
	using `tabout', append c(freq col) f(0 1) clab(n %) npos(row) ///
	h1("Percent experienced any difficulty in accessing healthcare because of fear of Covid-19 at the facility at the time of the P2 survey (by wealth) - Women who wanted to visit a health facility for any reason (weighted)")

*******************************************************************************
* Success in Accessing Health Services
*******************************************************************************

* Percent of respondents who were able to access health services
** Among women who wanted to access the facility

** Tabout - COVID DATA
use `dataset', clear
tabout accessed_health `wealth' [aw=cFQFUweight] ///
	using `tabout', append c(freq col) f(0 1) clab(n %) npos(row) ///
	h1("Percent able to access the health services needed at the time of the Covid19 survey - Women who wanted to visit a health facility for any reason ")


** Tabout - PHASE 2 DATA 
use `Phase2', clear
tabout accessed_health `wealth' [aw=FQweight] ///
	using `tabout', append c(freq col) f(0 1) clab(n %) npos(row) ///
	h1("Percent able to access the health services needed at P2 - Women who wanted to visit a health facility for any reason")	


*******************************************************************************
* FP Interuption Due to COVID-19
*******************************************************************************
	
* Percent of respondents who report interrupted contraceptie use due to COVID-19
** Among current users
tabout covid_fp_interruption `wealth' if cp==1 [aw=FQweight] ///
	using `tabout', append c(freq col) f(0 1) clab(n %) npos(row) ///
	h1("Percent of respondents at P2 who report interrupted contraceptive use due to Covid (by wealth) - Current users (weighted)")


*******************************************************************************
*
* SECTION 4: COVID-19 Impact on Service Delivery Points
*
*******************************************************************************

*******************************************************************************
* Impact on Health and FP Services During COVID-19 Restrictions
*******************************************************************************

* The tabouts for these graphs are available in the SDP COVID-19 .do file in
* 	the public repository 


log close
