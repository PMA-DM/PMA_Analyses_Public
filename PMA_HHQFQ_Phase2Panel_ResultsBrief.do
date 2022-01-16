/*******************************************************************************
* The following .do file will create the .xls file output that PMA used to 
* 	generate its Phase 2 Panel briefs using PMA's publicly available Household 
*	and Female dataset
*
* This .do file will only work on Phase 1 and Phase 2 HHQFQ panel datasets. You 
*	can  find the .do files to generate the .xls file outputs for PMA's 
* 	publicly available Phase 2 SDP, CQ and COVID19 datasets and other surveys    
*   in the PMA_Analyses_Public repository
*
* If you have any questions on how to use this or any of the other .do files in
* 	the PMA_Analyses_Public repository, please contact the PMA Data Management 
* 	Team at datamanagement@pma2020.org
*******************************************************************************/

/*******************************************************************************
*
*  FILENAME:		PMA_HHQFQ_Phase2Panel_ResultsBrief.do
*  PURPOSE:			Generate the .xls output for the PMA Phase 2 Panel Results Brief
*  CREATED BY: 		Elizabeth Larson (elarso11@jhu.edu)
*  DATA IN:			PMA's Phase2 Panel HHQFQ publicly released datasets
*  DATA OUT: 		PMA_COUNTRY_Phase2_Panel_Analysis_DATE.dta
*  FILE OUT: 		PMA_COUNTRY_Phase2_Panel_Analysis_DATE.xls
*  LOG FILE OUT: 	PMA_COUNTRY_Phase2_Panel_Log_DATE.log
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
local wealth "wealth"

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
use "`PMAdataset1'"

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
log using "`briefdir'/PMA_`country'_Phase2_Panel_Analysis_`date'.log", replace		

* Set local for xls file
local tabout "PMA_`country'_Phase2_Panel_Analysis_`date'.xls"

* Set local for dataset
local dataset "PMA_`country'_Phase2_Panel_Analysis_`date'.dta"

tempfile Phase1
save `Phase1', replace

*******************************************************************************
* SECTION 4: GENERATE NECESSARY VARIBLES AND SET UP DATA FOR ANALYSIS
*
* Section 6 is necessary to make sure the .do file runs correctly, please do not 
*	move, update or delete
*******************************************************************************
****************************************	
* PHASE 1 DATA
use "`Phase1'", clear

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
recode FQ_age -99=. -88=. -77=.
	egen age5=cut(FQ_age) , at (15(5)50)
	recode age5 (15=0) (20=1) (25 30 35 40 45=2) 
	label define age5_lab 0 "15-19" 1 "20-24" 2 "25-49
	label values age5 age5_lab
	label var age5 "Age Categories"
	
****************************************
* EDUCATION

* Generate three education variables
gen none_primary_education=`none_primary_education' 
gen secondary_education=`secondary_education' 
gen tertiary_education=`tertiary_education' 
	
* Combine into single education varaible 
gen education=0 if none_primary_education==1
	replace education=1 if secondary_education==1
	replace	education=2 if tertiary_education==1
label define education_list 0 "None/Primary education" 1 "Secondary Education" 2 "Tertiary Education"
	label val education education_list
label var education "Highest level of education attained"

****************************************
* WORKED

* Generate a variable to indicate whether a woman worked outside the home 
gen work = 0 
replace work = 1 if (work_12mo == 1| work_7d == 1)
replace work =. if (work_12mo == . & work_7d == .)
label values work yes_no_dnk_nr_list
label var work "Employment outside the household in the last 12m/7d"

****************************************
* PARITY
	
* Create categorical parity variable
replace birth_events=. if birth_events ==-88 | birth_events ==-99 
egen parity=cut(birth_events), at (0, 1, 3, 5) icodes 
label define paritylist 0 "None" 1 "One-Two" 2 "Three-Four" 3 "Five+" 
replace parity=3 if birth_events>=5 & birth_events!=. 
replace parity=0 if birth_events==. 
label val parity paritylist 

****************************************
* INTENTION TO USE

* Create intention to use variable
gen intention_use = 0 
replace intention_use=1 if fp_start==1 | fp_start==3 | (fp_start==2 & fp_start_value<=1)
label values intention_use yes_no_dnk_nr_list
label var intention_use "Intention to use contraception in the future/in the next year"

	
****************************************	
* Recode all "-99" as "0" to represent missing. For analytical purposes only, PMA recodes -99 values to 0
foreach var in partner_support {
	recode `var' -99=.
	}
recode school -99=.
foreach var in partner_know partner_decision why_not_decision partner_overall {
	recode `var' -99=. 
	}

****************************************
* Only Keep Phase 1 Variables Required for Analysis
keep FQmetainstanceID `level1_var'  age5 education wealth married work ///
	 partner_support FRS_result eligible last_night HHQ_result cp ///
	 current_methodnum_rc pregnant country FQ_age flw_willing unmettot ///
	 intention_use urban parity female_ID
	 
****************************************
* PHASE 1 ELIGIBILITY FOR PHASE 2
gen panel_eligible=0 
replace panel_eligible=1 if FQ_age<=48 & flw_willing==1 
label var panel_eligible "Phase 1 population eligble for panel"
label val panel_eligible yes_no_list

* Panel Elibigle women information
tabout panel_eligible if FRS_result==1 | FRS_result==5 ///
	using `tabout' , replace cells(freq col) f(0 1) clab(n %) ///
	h2("Eligible Phase 1 Sample") 

* Keep only panel women who spent the night at their P1 HH
keep if FQ_age<=48 & flw_willing==1 

* Panel de facto sample
tabout last_night ///
	using `tabout', append cells (freq col) f(0 1) clab(n %) ///
	h2("P1 de facto sample")

* Rename variables to identify as Phase 1 variables
rename * *_P1
rename female_ID_P1 female_ID

numlabel, remove

save `Phase1', replace

****************************************
* MERGE P1 AND P2 DATA	
use "`PMAdataset2'", clear

* Only keep panel women
keep if female_ID!="" & FRS_result!=. 
duplicates drop female_ID, force

* Merge datasets
merge 1:1 female_ID using `Phase1'

drop if _merge==1

* Generate loss to follow-up variable
gen LTFU=0 if _merge==3
replace LTFU=1 if _merge==2
label var LTFU "Lost to follow-up"
label define LTFU_list 0 "Reached" 1 "Lost"
label val LTFU LTFU_list


*******************************************************************************
* SECTION 5: RESPONSE RATES
*
* Section 5 will generate household and female survey response rates. To
* 	generate the correct response rates, please do not move, update or delete
*******************************************************************************
* Tabout Panel Attrition Rate
tabout LTFU ///
	using `tabout', append cells(freq col) f(0 1) clab(n %) ///
	h2("Panel Attrition Rate, among P1 panel eligible women")

* Tabout Response Rate Among All Panel Eligible Women  
tabout FRS_result_cc ///
	using `tabout', mi append cells(freq col) f(0 1) clab(n %) ///
	h2("FQ Result, among P1 panel eligible women")
	
* Tabout Response Rate Among Reached Women
tabout FRS_result_cc ///
	using `tabout', append cells(freq col) f(0 1) clab(n %) ///
	h2("FQ Result, among contacted women")	
	
* Tabout Response Rate Among DeFacto Women
tabout last_night last_night_P1 ///
	using `tabout', append cells(freq col) f(0 1) clab(n %) ///
	h1("Panel women defacto (Row) by P1 defacto (Column), among contacted women")
	
* Keep only merged observations of de facto women
keep if _merge==3 & last_night==1 & last_night_P1==1
drop _merge

* Tabout Response Rate
tabout FRS_result_cc FRS_result_P1 ///
	using `tabout', append cells(freq col) f(0 1) clab(n %) ///
	h1("Panel women P2 FRS result (Row) by P1 FRS result (Column)- among de facto women at P1 and P2") 

* Keep only completed panel women
keep if FRS_result_cc==1 & FRS_result_P1==1	
	
capture confirm var P2FUweight, exact
if _rc!=0 {
	gen P2FUweight=1
	}

save "`dataset'", replace


*******************************************************************************
* SECTION 6: GENERATE PANEL ANALYSIS INDICATORS
*
* Section 6 is necessary to make sure the .do file runs correctly, please do not 
* 	move, update or delete
*******************************************************************************
* Change in Contraceptive Use Sankey
** Phase 2 Change in Contraceptive Use
gen phase2_cp_group=.
	replace phase2_cp_group=0 if pregnant==1
	replace phase2_cp_group=1 if cp==0 & pregnant!=1
	replace phase2_cp_group=2 if cp==1 
	label define cp_grouped_label 0 "Pregnant" 1 "Not using FP" 2 "Using FP"
	label val phase2_cp_group cp_grouped_label
	label var phase2_cp_group "Contraceptive use status from Phase 2"
	
** Phase 1 Change in Contraceptive Use
gen phase1_cp_group=.
	replace phase1_cp_group=0 if pregnant_P1==1
	replace phase1_cp_group=1 if cp_P1==0 & pregnant_P1!=1
	replace phase1_cp_group=2 if cp_P1==1
	label val phase1_cp_group cp_grouped_label
	label var phase1_cp_group "Contraceptive use status from Phase 1 Survey"

	
* Change in Method Use Sankey
** Phase 2 Change in Method Use
gen phase2_method_group=.
	replace phase2_method_group=0 if cp==0 
	replace phase2_method_group=1 if cp==1 & current_methodnum_rc>=30 
	replace phase2_method_group=2 if cp==1 & current_methodnum_rc>=5 & current_methodnum_rc<30 
	replace phase2_method_group=3 if cp==1 & current_methodnum_rc>=1 & current_methodnum_rc<5 
	label define method_grouped_label 0 "No use" 1 "Traditional" 2 "Short Acting" 3 "Long Acting"
	label val phase2_method_group method_grouped_label
	label var phase2_method_group "Method use status from Phase 2"
	
** Phase 1 Change in Method Use
gen phase1_method_group=.
	replace phase1_method_group=0 if cp_P1==0 
	replace phase1_method_group=1 if cp_P1==1 & current_methodnum_rc_P1>=30 
	replace phase1_method_group=2 if cp_P1==1 & current_methodnum_rc_P1>=5 & current_methodnum_rc_P1<30 
	replace phase1_method_group=3 if cp_P1==1 & current_methodnum_rc_P1>=1 & current_methodnum_rc_P1<5 
	label val phase1_method_group method_grouped_label
	label var phase1_method_group "Method use status from Phase 1 Survey"

**Continuers
gen continuers=0
	replace continuers=1 if (cp==1 & cp_P1==1) & (current_methodnum_rc==current_methodnum_rc_P1)
	label var continuers "Women using the same method at P2 as P1"
	label val continuers yes_no_list
	
**Discontinuers
gen discontinuers=0
	replace discontinuers=1 if cp==0 & cp_P1==1 
	label var discontinuers "Women who used a method at P1 but are no longer using a method/pregnant at P2"
	label val discontinuers yes_no_list
	
**Adopters
gen adopters=0
	replace adopters=1 if cp==1 & cp_P1==0 
	label var adopters "Women who were not using a method/pregnant at P1 but are using at P2"
	label val adopters yes_no_list	
	
**Non-Adopters
gen non_adopters=0
	replace non_adopters=1 if cp==0 & cp_P1==0 
	label var non_adopters "Women who were not using a method/pregnant at P1 and are not using at P2"
	label val non_adopters yes_no_list		
	
**Switchers
gen switchers=0
	replace switchers=1 if (cp==1 & cp_P1==1) & (current_methodnum_rc!=current_methodnum_rc_P1) 
	label var switchers "Women who switched methods between P1 and P2"
	label val switchers yes_no_list	
	
**Categorical Variable 
gen contraceptive_dynamics=1 if continuers==1
	replace contraceptive_dynamics=2 if discontinuers==1
	replace contraceptive_dynamics=3 if adopters==1
	replace contraceptive_dynamics=4 if non_adopters==1
	replace contraceptive_dynamics=5 if switchers==1
	label var contraceptive_dynamics "Women's contraceptive use between Phase 1 and Phase 2"
	label define c_dynamics_list 1 "Continued using the same method" 2 "Stopped using a method" 3 "Started using a method" 4 "Continued non-use" 5 "Changed methods" 
	label val contraceptive_dynamics c_dynamics_list

**Detailed discontinuation
gen stopped_use=0
	replace stopped_use=1 if discontinuers==1
	replace stopped_use=2 if discontinuers==1 & pregnant==1
	label var stopped_use "Women who stopped using a method or got pregnant between P1 and P2"
	label define stopped_use_list 0 "No" 1 "Stopped using a method" 2 "Got pregnant" 
	label val stopped_use stopped_use_list
		
save "`dataset'", replace

*******************************************************************************
* SECTION 7: PMA RESULTS BRIEF OUTPUT
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
* SECTION 1: OVERALL CONTRACEPTIVE DYNAMICS
*
*******************************************************************************

*******************************************************************************
* Change in Contraceptive Use or Non-Use
*******************************************************************************

* Percent of respondents who changed contraceptive use status
* 	among all women 

** Tabout
tabout phase1_cp_group phase2_cp_group [aw=P2FUweight] ///
	using `tabout', append c(freq) f(0) clab(n) ///
		h1("Women who changed their contraceptive use status between Phase 1 (Row) and Phase 2 (Column) - Weighted")
		
** Percentages
tabout phase1_cp_group if phase2_cp_group!=. [aw=P2FUweight] ///
	using `tabout', append oneway c(freq col) f(0 1) clab(n %) ///
	h2("Contraceptive use status (Phase 1) - Weighted")

tabout phase2_cp_group if phase1_cp_group!=. [aw=P2FUweight] ///
	using `tabout', append oneway c(freq col) f(0 1) clab(n %) ///
	h2("Contraceptive use status (Phase 2) - Weighted")	

*******************************************************************************
* Change in Contraceptive Method Type
*******************************************************************************

* Percent of respondents who changed method type status
*	among all respondents

** Tabout
tabout phase1_method_group phase2_method_group [aw=P2FUweight] ///
	using `tabout', append c(freq) f(0) clab(n) ///
	h1("Women who changed their method type status between Phase 1 (Row) and Phase 2 (Column) - Weighted")
		
** Percentages
tabout phase1_method_group if phase2_method_group!=. [aw=P2FUweight] ///
	using `tabout', append oneway c(freq col) f(0 1) clab(n %) ///
	h2("Method type status (Phase 1) - Weighted")

tabout phase2_method_group if phase1_method_group!=. [aw=P2FUweight] ///
	using `tabout', append oneway c(freq col) f(0 1) clab(n %) ///
	h2("Method type status (Phase 2) - Weighted")
	
*******************************************************************************
*
* SECTION 2: CONTRACEPTIVE DYNAMICS BY KEY MEASURES
*
*******************************************************************************

*******************************************************************************
* Contraceptive Dynamics
*******************************************************************************

* Change in contraceptive use status, by age
*	among all respondents
tabout contraceptive_dynamics age5_P1 [aw=P2FUweight] ///
	using `tabout', append	c(col) f(1) clab(%) npos(row) ///
	h1("Contraceptive use status by age at P1 - All women Weighted")

* Change in contraceptive use status, by education level
*	among all respondents	
tabout contraceptive_dynamics education_P1 [aw=P2FUweight] ///
	using `tabout', append	c(col) f(1) clab(%) npos(row) ///
	h1("Contraceptive use status by education level at P1 - All women Weighted")

* Change in contraceptive use status, by marital status
*	among all respondents	
tabout contraceptive_dynamics married_P1 [aw=P2FUweight] ///
	using `tabout', append	c(col) f(1) clab(%) npos(row) ///
	h1("Contraceptive use status by marital status at P1 - All women Weighted")

* Change in contraceptive use status, by parity
*	among all respondents	
tabout contraceptive_dynamics parity_P1 [aw=P2FUweight] ///
	using `tabout', append	c(col) f(1) clab(%) npos(row) ///
	h1("Contraceptive use status by parity at P1 - All women Weighted")
	
*******************************************************************************
*
* SECTION 3: OTHER PANEL DYNAMICS
*
*******************************************************************************

*******************************************************************************
* Other Dynamics 
*******************************************************************************
*Contraceptive discontinuation
	capture confirm var unmettot, exact
	if _rc!=0 {
		di as error "Use the WealthWeightAll dataset instead of ECRecode"
		exit
	}
	tabout stopped_use if unmettot==1 [aw=P2FUweight] ///
		using `tabout', append	c(col) f(1) clab(%) npos(row)  ///
		h2("Women who stopped using a method between Phase 1 and Phase 2  - Women with unmet need at P2 Weighted")
		

*Prediction of uptake
rename partner_supportive*P1 partner_support_P1

foreach strat in partner_support_P1 intention_use_P1 unmettot_P1 {
	tabout adopters `strat' if cp_P1==0 [aw=P2FUweight] ///
		using `tabout', append	c(col) f(1) clab(%) npos(row)  ///
		h1("Women who started using a method between Phase 1 and Phase 2 by ``strat'_lab'  - Women not using any method at P1 Weighted")
	}


log close
