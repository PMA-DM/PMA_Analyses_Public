/*******************************************************************************
* The following .do file will create the .xls file output that PMA used to 
* 	generate its Phase 2 cross sectional results briefs using PMA's publicly  
* 	available Client Exit Interview dataset
*
* This .do file will only work on Phase 2 CEI cross sectional datasets. You 
*   can  find the .do files to generate the .xls file outputs for PMA's publicly
* 	available Phase 2 Household and Female datasets and other surveys in the  
*   PMA_Analyses_Public repository
*
* If you have any questions on how to use this or any of the other .do files in
* 	the PMA_Analyses_Public repository, please contact the PMA Data Management 
* 	Team at datamanagement@pma2020.org
*******************************************************************************/

/*******************************************************************************
*
*  FILENAME:		PMA_CEI_Phase2XS_ResultsBrief.do
*  PURPOSE:			Generate the .xls output for the PMA Phase 1 XS Results Brief
*  CREATED BY: 		Elizabeth Larson (elarso11@jhu.edu)
*  DATA IN:			PMA's Phase2 XS CEI publicly released dataset
*  DATA OUT: 		PMA_COUNTRY_PHASE2_XS_CEI_Analysis_DATE.dta
*  FILE OUT: 		PMA_COUNTRY_PHASE2_XS_CEI_Analysis_DATE.xls
*  LOG FILE OUT: 	PMA_COUNTRY_PHASE2_XS_CEI_Log_DATE.log
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
local datadir "/Users/ealarson/Dropbox (Gates Institute)/12 Kenya/PMAKE_Datasets/Phase2/Final_PublicRelease/CQ/PMA2020_KEP2_CQ_v1.0_25Aug2021/PMA2020_KEP2_CQ_Baseline_v1.0_25Aug2021.dta"

*	2. A directory for the folder where you want to save the dataset, xls and
*		log files that this .do file creates
*		- For example (Mac): 
*		  local briefdir "/User/ealarson/Desktop/PMA2020/NigeriaAnalysisOutput"
*		- For example (PC): 
*		  local briefdir "C:\Users\annro\PMA2020\NigeriaAnalysisOutput"
local briefdir "/Users/ealarson/Documents/PMA/Kenya/PublicRelease/Phase 2/West Pokot"


*******************************************************************************
* SECTION 2: SET MACROS FOR THE COUNTRY
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
local country "Kenya"

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
local subnational_yn "yes"
local subnational "WEST_POKOT"

*******************************************************************************
* SECTION 3: CREATE MACRO FOR DATE, XLS and Dataset
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
		di in smcl as error "The specified country is not the correct coding for this phase of data collection. Please search for the country variable in the dataset to identify the correct country code, update the local and rerun the .do file"
		exit
		}
	drop countrycheck check
	
* Confirm that it is phase 2 data
if country=="Burkina" {
	gen check=(phase==2)
	}
else if country=="DRC" {
	gen check=(phase==2)
	}
else if country=="Kenya" {
	gen check=(phase==2)
	}
else if country=="Nigeria" {
	gen check=(phase=="2")
	}
if check!=1 {
	di in smcl as error "The dataset you are using is not a PMA phase 1 XS dataset. This .do file is to generate the .xls files for PMA Phase 2 XS surveys only. Please use a PMA Phase 2 XS survey and rerun the .do file"
	exit
	}
	drop check

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
		capture quietly regress check province
			if _rc==2000 {
				di in smcl as error "The specified sub-national level is not correct. Please search for the sub-national variable in the dataset to identify the correct spelling of the sub-national level, update the local and rerun the .do file"
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
log using "`briefdir'/PMA_`country'_Phase2_XS_CEI_Log_`date'.log", replace		

* Set local for xls file
local tabout "PMA_`country'_Phase2_XS_CEI_Analysis_`date'.xls"

* Set local for dataset
local dataset "PMA_`country'_Phase2_XS_CEI_Analysis_`date'.dta"

* Response Rate
tabout CEI_result using "`tabout'", replace ///
		cells(freq col) h2("CEI response rate") f(0 1) clab(n %)	

* Create analytical sample: Only keep completed surveys & women counseled on fp
keep if CEI_result==1 & fp_info_yn==1

* Save dataset so can replicate analysis results later
save "`dataset'", replace

*******************************************************************************
* SECTION 5: GENERATE NECESSARY VARIBLES AND SET UP DATA FOR ANALYSIS
*
* Section 5 is necessary to make sure the .do file runs correctly, please do not 
*	move, update or delete
*******************************************************************************

****************************************	
* Personal perception of quality of care
foreach var in qcc_interp_encourage qcc_info_complete qcc_info_sideeffects qcc_disresp_pressure {
	gen `var'_bin=0 if `var'!=.
	replace `var'_bin=1 if `var'==1 | `var'==2
	label val `var'_bin yes_no_list
	}

	label var qcc_interp_encourage_bin "Felt encouraged by provider to ask questions and express concerns"
	label var qcc_info_complete_bin "Felt they received all the information they wanted to know about their options for contraceptive methods"
	label var qcc_info_sideeffects_bin "Felt they understood how their body might react to the method"
	label var qcc_disresp_pressure_bin "Felt pressured by provider to use the method"

****************************************
* Recode missing values
recode qoc_* (-99 -88 =.)

*******************************************************************************
* SECTION 6: PMA RESULTS BRIEF OUTPUT
*
* Section 6 generates the output that matches what is presented in PMA's
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
* SECTION 3: QUALITY OF FP SERVICES
*
*******************************************************************************

*******************************************************************************
* Community Perception of Quality of Care
*******************************************************************************	
	
* Percent distribution of community agreement with the following statement as reported as FP clients,
*	1) Women are treated respectfully at the clinic
tabout qoc_comm_respect ///
	using "`tabout'", append c(col) npos(row) ///
	h2("FP clients who thought the community felt that women are treated respectfully at facility ")
	
* Percent distribution of community agreement with the following statement as reported as FP clients,
*	1) Women will be able to receive the FP method of their choice at this facility	
tabout qoc_comm_preferfp ///
	using "`tabout'", append c(col) npos(row) ///
	h2("Women clients who thought the community felt that women will be able to receive FP method of their choice at this facility")
	
* Percent distribution of community agreement with the following statement as reported as FP clients,
*	1) Women have access to affordable FP at this facility	
tabout qoc_comm_affordfp /// 
	using "`tabout'", append c(col) npos(row) ///
	h2("Women clients who thought the community felt that women have access to affordable FP at this facility ")

*******************************************************************************
* Personal Perception of Quality of Care
*******************************************************************************	

* Percent of female FP clients that agreed with the following statement,
*	1) Felt encouraged by the provider to ask questions and express concerns
tabout qcc_interp_encourage_bin ///
	using "`tabout'", append c(col) npos(row) ///
	h2("Women clients who felt encouraged by provider to ask questions and express concerns by ")	
	
* Percent of female FP clients that agreed with the following statement,
*	1) Felt they received all the information they wanted to know about their options for contraceptive methods
tabout qcc_info_complete_bin ///
	using "`tabout'", append c(col) npos(row) ///
	h2("Women clients who felt they received all the information they wanted to know about their options for contraceptive methods ")	
	
* Percent of female FP clients that agreed with the following statement,
*	1) Felt they understood how their body might react to the method
tabout qcc_info_sideeffects_bin ///
	using "`tabout'", append c(col) npos(row) ///
	h2("Women clients who felt they understood how their body might react to the method ")	
	
* Percent of female FP clients that agreed with the following statement,
*	1) Felt pressured by the provider to use the method the provider preferred
tabout qcc_disresp_pressure_bin ///
	using "`tabout'", append c(col) npos(row) ///
	h2("Women clients who felt pressured by provider to use the method")	

*******************************************************************************
* CLOSE
*******************************************************************************

log close
