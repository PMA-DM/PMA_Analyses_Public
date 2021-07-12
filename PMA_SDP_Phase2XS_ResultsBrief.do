/*******************************************************************************
* The following .do file will create the .xls file output that PMA used to 
* 	generate its Phase 2 cross sectional results briefs using PMA's publicly  
* 	available Service Delivery Point dataset
*
* This .do file will only work on Phase 2 SDP cross sectional datasets. You 
*   can  find the .do files to generate the .xls file outputs for PMA's publicly
* 	available Phase 2 Household and Female datasets and other surveys in the  
*   PMA_Analyses_Public repository
*
* This .do file does not contain the necessary codes for trends over time. You 
*	can find those .do files in the PMA_Analyses_Public repository
*
* If you have any questions on how to use this or any of the other .do files in
* 	the PMA_Analyses_Public repository, please contact the PMA Data Management 
* 	Team at datamanagement@pma2020.org
*******************************************************************************/

/*******************************************************************************
*
*  FILENAME:		PMA_SDP_Phase2XS_ResultsBrief.do
*  PURPOSE:			Generate the .xls output for the PMA Phase 2 XS Results Brief
*  CREATED BY: 		Elizabeth Larson (elarso11@jhu.edu)
*  DATA IN:			PMA's Phase1 XS SDP publicly released dataset
*  DATA OUT: 		PMA_COUNTRY_PHASE2_XS_SDP_Analysis_DATE.dta
*  FILE OUT: 		PMA_COUNTRY_PHASE2_XS_SDP_Analysis_DATE.xls
*  LOG FILE OUT: 	PMA_COUNTRY_PHASE2_XS_SDP_Log_DATE.log
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
local datadir "/Users/Beth/Dropbox (Gates Institute)/5 Burkina Faso/PMABF_Datasets/Phase2/Prelim100/BFP2_SDP_Clean_Data_with_checks_14Apr2021.dta"

*	2. A directory for the folder where you want to save the dataset, xls and
*		log files that this .do file creates
*		- For example (Mac): 
*		  local briefdir "/User/ealarson/Desktop/PMA2020/NigeriaAnalysisOutput"
*		- For example (PC): 
*		  local briefdir "C:\Users\annro\PMA2020\NigeriaAnalysisOutput"
local briefdir "/Users/Beth/Documents/PMA/Burkina Faso/PublicRelease"


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
	di in smcl as error "The dataset you are using is not a PMA phase 2 XS dataset. This .do file is to generate the .xls files for PMA Phase 2 XS surveys only. Please use a PMA Phase 2 XS survey and rerun the .do file"
	exit
	}
	drop check


* Confirm that correct variables were chosen for locals

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
		capture quietly regress check region
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
log using "`briefdir'/PMA_`country'_Phase2_XS_SDP_Log_`date'.log", replace		

* Set local for xls file
local tabout "PMA_`country'_Phase2_XS_SDP_Analysis_`date'.xls"

* Set local for dataset
local dataset "PMA_`country'_Phase2_XS_SDP_Analysis_`date'.dta"

* Response Rate
tabout SDP_result using "`tabout'", replace ///
		cells(freq col) h2("SDP response rate") f(0 1) clab(n %)	

* Create analytical sample: Only keep completed surveys
keep if SDP_result==1

* Save dataset so can replicate analysis results later
save "`dataset'", replace


*******************************************************************************
* SECTION 5: GENERATE NECESSARY VARIBLES AND SET UP DATA FOR ANALYSIS
*
* Section 5 is necessary to make sure the .do file runs correctly, please do not 
*	move, update or delete
*******************************************************************************
****************************************	
* PUBLIC/PRIVATE SECTOR VARIABLE
gen sector=.
	replace sector=0 if managing_authority==1 
	replace sector=1 if managing_authority!=1 & managing_authority!=.
	label define sector_lab 0 "Public" 1 "Private"
	label values sector sector_lab
	label variable sector "Sector"

****************************************	
* IN/OUTSTOCK OF METHOD - PERCENT OF FACILITIES

*Combine injectable variables, depo and sayana if both are asked
capture confirm var provided_sayana_press 
if _rc == 0 {
	gen provided_injectables = .
		replace provided_injectables=0 if provided_sayana_press==0 | provided_depo_provera==0
		replace provided_injectables=1 if provided_sayana_press==1 | provided_depo_provera==1

	gen stock_injectables=.
		replace stock_injectables=1 if stock_depo_provera==1 | stock_sayana_press==1
		replace stock_injectables=2 if stock_depo_provera>=2 & stock_sayana_press>=2
			replace stock_injectables=3 if stock_depo_provera>=3 & stock_sayana_press>=3
			replace stock_injectables=. if stock_depo_provera==. & stock_sayana_press==.
			
			gen stockout_3mo_injectables=.
		replace stockout_3mo_injectables=0 if stockout_3mo_depo_provera==0 | stockout_3mo_sayana_press==0
		replace stockout_3mo_injectables=1 if stockout_3mo_depo_provera>=1 & stockout_3mo_sayana_press>=1
		replace stockout_3mo_injectables=. if stockout_3mo_depo_provera==. & stockout_3mo_sayana_press==.


	gen stockout_why_injectables=. 
		replace stockout_why_injectables = 1 if (stockout_why_dp == 1| stockout_why_sp == 1)
		replace stockout_why_injectables = 2 if (stockout_why_dp == 2| stockout_why_sp == 2)
		replace stockout_why_injectables = 3 if (stockout_why_dp == 3| stockout_why_sp == 3)
		replace stockout_why_injectables = 4 if (stockout_why_dp == 4| stockout_why_sp == 4)
		replace stockout_why_injectables = 5 if (stockout_why_dp == 5| stockout_why_sp == 5)
		replace stockout_why_injectables = 96 if (stockout_why_dp == 96| stockout_why_sp == 96) & stockout_why_injectables==.
		label values stockout_why_injectables out_of_stock_reason_list	
	}
* Generate Label
label define offer_stockout_lab 1 "In stock" 2 "In stock but not observed" 3 "Out of stock" 4 "Don't offer"

* Generate variable
foreach x in implants IUD sayana_press depo_provera pills ec male_condoms female_condoms diaphragm foam beads  {
capture noisily gen offer_stockout_`x'=.
capture noisily replace offer_stockout_`x'=4 if fp_offer==1
capture noisily replace offer_stockout_`x'=1 if fp_offer==1 & provided_`x'==1 & (stock_`x'==1 | stock_`x'==2)
capture noisily replace offer_stockout_`x'=2 if fp_offer==1 & provided_`x'==1 & (stock_`x'==1 | stock_`x'==2) & stockout_3mo_`x'==1
capture noisily replace offer_stockout_`x'=3 if fp_offer==1 & provided_`x'==1 & (stock_`x'==3 | stock_`x'==-99)
capture noisily replace offer_stockout_`x'=4 if fp_offer==1 & provided_`x'==0 
capture label var offer_stockout_`x' "Facilites offering and currently in/out of stock of `x' among those that offer FP"
capture label val offer_stockout_`x' offer_stockout_lab
}
****************************************
* OFFERING EFFECTIVE IMPLANTS INSERTION AND REMOVAL SERVICES - PERCENT OF FACILITIES

* Generate variable
generate implant_supplies_personnel=0 if provided_implants==1
replace implant_supplies_personnel = 1 if implant_insert == 1 & implant_remove == 1 & implant_gloves == 1 & implant_antiseptic == 1 ///
	& implant_sterile_gauze == 1 & implant_anesthetic == 1& implant_sealed_pack == 1 & implant_blade == 1 & implant_forceps == 1 & provided_implants==1
label values implant_supplies_personnel yes_no_nr_list
label var implant_supplies_personnel "Has a trained provider and instruments/supplies needed for Implant insertion/removal"
	
****************************************
* OFFERING EFFECTIVE IUD INSERTION AND REMOVAL SERVICES - PERCENT OF FACILITIES

* Generate variable
generate iud_supplies_personnel=0 if provided_iud==1
replace iud_supplies_personnel = 1 if iud_insert == 1 & iud_remove == 1 & iud_gloves == 1 & iud_antiseptic == 1 & iud_drapes == 1 ///
	& iud_scissors == 1 & iud_forceps == 1 & iud_speculums == 1 & iud_tenaculum == 1 & iud_uterinesound == 1 & provided_iud==1
label values iud_supplies_personnel yes_no_nr_list
label var iud_supplies_personnel "Has a trained provider and instruments/supplies needed for IUD insertion/removal"

****************************************
* REASON FOR STOCKOUG

* Generate variable
egen any_stockout=rownonmiss(stockout_why_*)

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
* SECTION 5: SERVICE DELIVERY POINTS
*
*******************************************************************************

*******************************************************************************
* TRENDS IN METHOD AVAILAIBLITY
*******************************************************************************

* The tabout for this graph is available in the SDP Trends .do file in
* 	the public repository 

*******************************************************************************
* MAIN REASON FOR EPISODES OF STOCKOUT OF ANY METHOD BY TYPE OF FACILITY
*******************************************************************************

preserve

* Only keep if at least one stockout at the facility
keep if any_stockout>=1

* Reshape data to long format
reshape long stockout_why_, i(metainstanceID) j(method) string
rename stockout_why_ stockout_why_

label var stockout_why "Reason for stockout among all methods" 

tabout stockout_why sector ///
	using "`tabout''", append c(freq col) ptotal(none) npos(row) ///
	h1("Reasons for stock out - Among episodes of stockout")

restore

*******************************************************************************
* FACILITY READINESS
*******************************************************************************

* Implant insertion  and removal,
*	among all facilities providing implants
tabout implant_supplies_personnel sector ///
	using "`tabout'", append c(freq col) ptotal(none) npos(row) ///
	h1("Has a trained provider and supplies for implant insertion/removal- Among facilities providing implants")
	
* IUD insertion and removal,
*	among all facilities providing IUDs
tabout iud_supplies_personnel sector ///
	using "`tabout'", append c(freq col) ptotal(none) npos(row) ///
	h1("Has a trained provider and supplies for IUD insertion/removal- Among facilities providing IUDs")
	
*******************************************************************************
* OBTAINED METHOD FROM PUBLIC FACILITY
*******************************************************************************

* The tabout for this graph is available in the HHQFQ .do file in
*	the public repository

*******************************************************************************
*
* SDP DISTRIBUTION VARIABLES (NOT INCLUDED ON BRIEF)
*
*******************************************************************************	

* Distribution by facility type
tabout facility_type sector ///
	using "`tabout''", append cells(freq col) ///
	h1("Facility type by public/private among all facilities")

* Distribution of facilities that offer FP
tabout facility_type sector if fp_offered==1 ///
	using "`tabout'", append cells(freq col) ///
	h1("Facility type by public/private among facilities offering FP")

*******************************************************************************
* CLOSE
*******************************************************************************

log close
