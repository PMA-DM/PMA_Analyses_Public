/*******************************************************************************
* The following .do file will create the .xls file output that PMA used to 
* 	generate its Phase 2 Panel COVID-19 briefs using PMA's publicly available  
*	Service Delivery Point dataset
*
* This .do file will only work on Phase 1 and Phase 2 SDP panel datasets that 
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
*  DATA OUT: 		PMA_COUNTRY_Phase2_Panel_SDP_COVID19_Analysis_DATE.dta
*  FILE OUT: 		PMA_COUNTRY_Phase2_Panel_SDP_COVID19_Analysis_DATE.xls
*  LOG FILE OUT: 	PMA_COUNTRY_Phase2_Panel_SDP_COVID19_Log_DATE.log
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

***** SDP DATASET *****
local SDPdataset "/Users/ealarson/Dropbox (Gates Institute)/5 Burkina Faso/PMABF_Datasets/Phase2/Final_PublicRelease/SQ/PMA2021_BFP2_SQ_v1.0_7Oct2021/PMA2021_BFP2_SQ_v1.0_7Oct2021.dta"

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

*	2. The level1 macro corresponds to the highest geographical level in the
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
use "`SDPdataset'"

*	Country Variable
	gen countrycheck="`country'"
	gen check=(countrycheck==country)
	if check!=1 {
		di in smcl as error "The specified country is not the correct coding for this phase of data collection. Please search for the country variable in the dataset to identify the correct country code, update the local and rerun the .do file"
		exit
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
log using "`briefdir'/PMA_`country'_Phase2_Panel_SDP_COVID19_Analysis_`date'.log", replace		

* Set local for xls file
local tabout "PMA_`country'_Phase2_Panel_SDP_COVID19_Analysis_`date'.xls"

* Set local for dataset
local dataset "PMA_`country'_Phase2_Panel_SDP_COVID19_Analysis_`date'.dta"

save `dataset', replace

*******************************************************************************
* SECTION 4: GENERATE NECESSARY VARIBLES AND SET UP DATA FOR ANALYSIS
*
* Section 4 is necessary to make sure the .do file runs correctly, please do not 
*	move, update or delete
*******************************************************************************
****************************************	
* KEEP ONLY COMPLETED SURVEYS
keep if SDP_result==1

****************************************	
* RECODE ALL NEGATIVE VALUES AS MISSING

foreach var in covid_closure covid_reduced_hours covid_reassignments covid_no_fp covid_no_provider_fp covid_regular_supplies {
	recode `var' -99 -88 -77=.
	}
		
*******************************************************************************
* SECTION 5: PMA RESULTS BRIEF OUTPUT
*
* Section 5 generates the output that matches what is presented in PMA's
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

* The tabouts for these graphs are available in the HHQFQ COVID-19 .do file in
* 	the public repository 

*******************************************************************************
*
* SECTION 2: ECONOMIC IMPACT OF COVID-19
*
*******************************************************************************

*******************************************************************************
* Household Income Loss
*******************************************************************************

* The tabouts for these graphs are available in the HHQFQ COVID-19 .do file in
* 	the public repository 

*******************************************************************************
* Household Income Recovery
*******************************************************************************	
	
* The tabouts for these graphs are available in the HHQFQ COVID-19 .do file in
* 	the public repository 
	
*******************************************************************************
* Food Insecurity
*******************************************************************************	

* The tabouts for these graphs are available in the HHQFQ COVID-19 .do file in
* 	the public repository 
	
*******************************************************************************
* Economic Reliance
*******************************************************************************	

* The tabouts for these graphs are available in the HHQFQ COVID-19 .do file in
* 	the public repository 
	
*******************************************************************************
*
* SECTION 3: BARRIER TO ACCESSING HEALTH SERVICES
*
*******************************************************************************

*******************************************************************************
* Want to Visit a Health Facility
*******************************************************************************

* The tabouts for these graphs are available in the HHQFQ COVID-19 .do file in
* 	the public repository 	
	
*******************************************************************************
* Difficulty Accessing a Health Facility
*******************************************************************************

* The tabouts for these graphs are available in the HHQFQ COVID-19 .do file in
* 	the public repository 
	
*******************************************************************************
* Reasons for Difficulty Accessing Health Facility
*******************************************************************************

* The tabouts for these graphs are available in the HHQFQ COVID-19 .do file in
* 	the public repository 

*******************************************************************************
* Success in Accessing Health Services
*******************************************************************************

* The tabouts for these graphs are available in the HHQFQ COVID-19 .do file in
* 	the public repository 


*******************************************************************************
* FP Interuption Due to COVID-19
*******************************************************************************
	
* The tabouts for these graphs are available in the HHQFQ COVID-19 .do file in
* 	the public repository 


*******************************************************************************
*
* SECTION 4: COVID-19 Impact on Service Delivery Points
*
*******************************************************************************

*******************************************************************************
* Impact on Health and FP Services During COVID-19 Restrictions
*******************************************************************************

* Percent of facilities that closed during COVID-19 restrictions when they would have otherwise been open
** among all facilities
tabout covid_closure ///
	using `tabout', append c(freq col) f(0 1) clab(n %) npos(row) ///
	h2("Percent of facilities that completely closed during COVID-19 - All facilities ")

* Percentage of facilities reporting reduction in hours of operation during COVID-19 restrictions
** among all facilities
tabout covid_reduced_hours ///
	using `tabout', append c(freq col) f(0 1) clab(n %) npos(row) ///
	h2("Percent of facilities reporting reduction in number of hours of operation during COVID-19 - All Facilities")

* Percentage of facilities reporting a suspension of FP services during COVID-19
** among facilities offering FP
tabout covid_no_fp ///
	using `tabout', append c(freq col) f(0 1) clab(n %) npos(row) ///
	h2("Percent of facilities reporting suspension of FP services during COVID-19 lockdown - Facilities offering FP")

* Percentage of facilities where personnel were reassigned from FP services to COVID-19 related duties during the COVID-19 restrictions
** among facilities offering FP
tabout covid_reassignments ///
	using `tabout', append c(freq col) f(0 1) clab(n %) npos(row) ///
	h2("Percent of facilities reporting personnel reassigned from FP services to COVID-19 related duties - Facilities offering FP")

* Percentage of facilities reporting a period of time when provider-administered methods were not offered during COVID-19 restrictions
** among facilities offering FP
tabout covid_no_provider_fp ///
	using `tabout', append c(freq col) f(0 1) clab(n %) npos(row) ///
	h2("Percent of facilities reporting a period of time when provider administered methods were not offered during COVID-19 lockdown- Facilites offering Sterilization/IUDs/Implants/Injectables")

* Percentage of facilities with regular or irregular method supply during COVID-19 restrictions
** among facilities offering FP
tabout covid_regular_supplies ///
	using `tabout', append c(freq col) f(0 1) clab(n %) npos(row) ///
	h2("Regularity of FP methods supply to this facility during COVID-19 lockdown - Facilities offering FP")

*******************************************************************************
log close
