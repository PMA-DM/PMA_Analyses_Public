/*******************************************************************************
* The following .do file will create the .xls file output that PMA used to 
* 	generate its Phase 2 cross sectional results briefs using PMA's publicly  
* 	available Household and Female dataset
*
* This .do file will only work on Phase 2 HHQFQ cross sectional datasets. You 
*   can  find the .do files to generate the .xls file outputs for PMA's publicly
* 	available Phase 2 SDP and CQ datasets and other surveys in the  
*   PMA_Analyses_Public repository
*
* This .do file does not contain the cross sectional estimates or the 
*   mCPR Annual Percent Change. You can find those .do files in the
*   PMA_Analyses_Public repository
*
* If you have any questions on how to use this or any of the other .do files in
* 	the PMA_Analyses_Public repository, please contact the PMA Data Management 
* 	Team at datamanagement@pma2020.org
*******************************************************************************/

/*******************************************************************************
*
*  FILENAME:		PMA_HHQFQ_Phase2XS_ResultsBrief_ContraceptiveTrends.do
*  PURPOSE:			Generate the .xls output with contraceptive trends for the PMA Phase 2 XS Results Brief
*  CREATED BY: 		Elizabeth Larson (elarso11@jhu.edu)
*  DATA IN:			PMA's Phase1 XS HHQFQ publicly released dataset
*  DATA OUT: 		PMA_COUNTRY_PHASE2_XS_ContraceptiveTrends_DATE.dta
*  FILE OUT: 		PMA_COUNTRY_PHASE2_XS_ContraceptiveTrends_DATE.xls
*  LOG FILE OUT: 	PMA_COUNTRY_PHASE2_XS_ContraceptiveTrends_Log_DATE.log
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
* SECTION A: STATA SET UP (PLEASE DO NOT DELETE)
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

*	1. Total number of PMA datasets to include in the analysis excluding the current Phase analysis (Phase 2). The local should 
*		be the number.
*		- For example: local PMAdataset_count 4
*		- For example: local PMAdataset_count 7
local PMAdataset_count 7

*	2. A directory for the folder where you want to save the dataset, xls and
*		log files that this .do file creates
*		- For example (Mac): 
*		  local briefdir "/User/ealarson/Desktop/PMA2020/NigeriaAnalysisOutput"
*		- For example (PC): 
*		  local briefdir "C:\Users\annro\PMA2020\NigeriaAnalysisOutput"
local briefdir "/Users/clairesilberg/Documents/PMA_Local/Public Release Do Files/BF/Phase2/Contraceptive Trends"

************** DATASETS & DATES *************
*	Directory for each of the publicly available PMA2020 and PMA datasets on  
*		your computer. When entering datasets, start with the earliest and end 
*		with the most recent. Enter PMA2020 Datasets first and PMA Datasets
*		second. Leave exta locals blank if you are not including 10 datasets in 
*		your analysis.
*		- For example (Mac): 
*		  local dataset1 "/User/ealarson/Desktop/PMA2020/PMA2018_NGR5_National_HHQFQ_v5_4Nov2019"
*		- For example (PC):
* 		  local dataset1 "C:\Users\annro\PMA2020\PMA2018_NGR5_National_HHQFQ_v5_4Nov2019.dta"

*	Dates of Data Collection for the Phase or Round of data collection 
*		corresponding to the given dataset. If data collection took place in 
*		one year only, the format should be "MM-MM/YYYY" where the first MM 
*		represents the numeric code for the first month of data collection, 
*		the last MM represents the numeric code for the last month of data 
*		collection, and the YYYY represents the numeric code for the year of 
*		data collection. If data collection took place over two years, the 
*		format should be "MM/YYYY-MM/YYYY". Leave extra locals blank if you are 
*		not including 10 datasets in your analysis
*		- For example: local dataset1dates "11-12/2019"

***********************************************
* PMA2020 *
***** FIRST DATASET *****
* Dataset 1 Directory
local PMAdataset1 "/Users/clairesilberg/Dropbox (Gates Institute)/PMABF_Datasets/Round5/Final_PublicRelease/HHQFQ/PMA2017_BFR5_HHQFQ_v1_26Aug2018/PMA2017_BFR5_HHQFQ_v1_26Aug2018.dta"

* Dates of Data Collection for Dataset 1
local PMAdataset1dates "09/2020-11/2020"

***** SECOND DATASET *****
* Dataset 2 Directory
local PMAdataset2 "/Users/clairesilberg/Dropbox (Gates Institute)/PMABF_Datasets/Round6/Final_PublicRelease/HHQFQ/PMA2019_BFR6_HHQFQ_v1_17May2019/PMA2019_BFR6_HHQFQ_v1_20May2019.dta" 

* Dates of Data Collection for Dataset 2
local PMAdataset2dates "4-6/2015"

***** THIRD DATASET *****
* Dataset 3 Directory
local PMAdataset3 "/Users/clairesilberg/Dropbox (Gates Institute)/PMABF_Datasets/Round4/Final_PublicRelease/HHQ/PMA2016_BFR4_HHQFQ_v4_6Nov2018/PMA2016_BFR4_HHQFQ_v4_6Nov2018.dta"

* Dates of Data Collection for Dataset 3
local PMAdataset3dates "3-5/2015"

***** FOURTH DATASET *****
* Dataset 4 Directory
local PMAdataset4 "/Users/clairesilberg/Dropbox (Gates Institute)/PMABF_Datasets/Round3/Final_PublicRelease/HHQ/PMA2016_BFR3_HHQFQ_v3_6Nov2018/PMA2016_BFR3_HHQFQ_v3_6Nov2018.dta"

* Dates of Data Collection for Dataset 4
local PMAdataset4dates "11/2-16-2/2016"

***** FIFTH DATASET *****
* Dataset 5 Directory
local PMAdataset5 "/Users/clairesilberg/Dropbox (Gates Institute)/PMABF_Datasets/Round2/Final_PublicRelease/HHQ/PMA2015_BFR2_HHQFQ_v3_6Nov2018/PMA2015_BFR2_HHQFQ_v3_6Nov2018.dta"

* Dates of Data Collection for Dataset 5
local PMAdataset5dates "11/2017-1/2018"

***** SIXTH DATASET *****
* Dataset 6 Directory
local PMAdataset6 "/Users/clairesilberg/Dropbox (Gates Institute)/PMABF_Datasets/Round1/Final_PublicRelease/HHQ/PMA2014_BFR1_HHQFQ_v3_6Nov2018/PMA2014_BFR1_HHQFQ_v3_6Nov2018.dta"

* Dates of Data Collection for Dataset 6
local PMAdataset6dates "12/2018-1/2019"

***********************************************
* PMA Phases *
*****  PMA PHASE 1 Dataset ***** 
local PMAdataset7 "/Users/clairesilberg/Dropbox (Gates Institute)/PMABF_Datasets/Phase1/Final_PublicRelease/HQFQ/PMA2020_BFP1_HQFQ_v2.0_1Oct2021/PMA2020_BFP1_HQFQ_v2.0_1Oct2021.dta"

* Dates of Data Collection for Dataset 1
local PMAdataset7dates "01/2020-03/2020"

***** PMA PHASE 2 DATASET *****
* Dataset 2 Directory
local PMAdatasetPhase2 "/Users/clairesilberg/Dropbox (Gates Institute)/PMABF_Datasets/Phase2/Final_PublicRelease/HQFQ/PMA2021_BFP2_HQFQ_v1.0_7Oct2021/PMA2021_BFP2_HQFQ_v1.0_1Oct2021.dta"

* Dates of Data Collection for Dataset 2
local PMAdatasetPhase2dates "01/2021-03/2021"

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
local country "Kenya"

*	2. The weight local macro should be the weight variable that is used for  
*		analyzing the data. Generally, it will be "FQweight", however for certain
*		geographies, such as Nigeria, you will need to specify the weight for the
*		specific geography that you are analyzing. You can identify the correct 
*		weight by searching for variables that begin with "FQweight" in the 
*		dataset
*		- For example (Nigeria): FQweight_National
*		- For example (Burkina Faso): FQweight
local weight "FQweight"

*	3. The primary sampling unit local macro should be the name of the variable
*		that corresponds to the primary sampling unit in the country. It should
*		be either EA_ID or Cluster_ID depending on the country.
*		- For example (Kenya): EA_ID
*		- For example (Nigeria): Cluster_ID
local PSU "EA_ID"

*	4. The strata local should be the variables that are used to calculate the
*		strata. To identify the strata variable, search "strata" in the 
*		dataset.
*		- For example (Kenya): strata
*		- For example (DRC): nothing (there is no strata variable in DRC)
local strata "strata"

*	5. The subnational macros allow you to generate the estimates on one of
*		 PMA's subnational restulsts brief. The value for the subnational_yn 
*		 macro should be "yes" if you are running a subnational estimate, or 
*		 "no" if you are running a national estimate. If you are running a 
*		 subnational estimate, the value for the subnational_unit macro should 
*		 be the name of the geographical level, and the value for the subnational 
*		 macro should be the name of the region as it appears in the highest 
*		 geographical level variable, typically "region" or "county". 
*		 If you are not running a submational estimate, leave the subnational_unit 
*		 and subnational macros empty ("")
*		 - For example (No subnational estimate):
*		   local subnational_yn "no"
*		   local subnational_unit ""
*		   local subnational ""
*		 - For example (Subnational estimate for Kenya, Kericho county):
*		   local subnational_yn "yes"
*		   local subnational_unit county
*		   local subnational "KERICHO"
local subnational_yn "no"
local subnational_unit 
local subnational 


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

global level1_var `subnational_unit'
global level1 `subnational'

*******************************************************************************
* SECTION 4: DATA CHECKS
*
* Section 4 will perform data checks to make sure that the .do file will run 
* 	correclty, please do not move, update or delete
*******************************************************************************
* Set main output directory
cd "`briefdir'"

* Open Phase 2 dataset
use "`PMAdatasetPhase2'",clear

* Confirm that correct variables were chosen for locals

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
		di in smcl as error "Variable `weight' not found in dataset. Please search for the correct weight variable in the dataset to specify as the local macro. If you are doing a regional/state-level analysis, please make sure that you have selected the correct variable for the geographic level, update the local and rerun the .do file"
		exit
		}
		
*	PSU Variable
	capture confirm var `PSU'
	if _rc!=0 {
		di in smcl as error "Variable `PSU' not found in dataset. Please search for the correct wealth variable in the dataset to specify as the local macro. If you are doing a regional/state-level analysis, please make sure that you have selected the correct variable for the geographic level, update the local and rerun the .do file"
		exit
		} 
		
*	Strata Variable
	capture confirm var `strata'
	if _rc!=0 {
		di in smcl as error "Variable `strata' not found in dataset. Please search for the correct strata variable in the dataset to specify as the local macro and rerun the .do file. Some countries do not have a strata variable and the macro should be left blank"
		exit
		} 

* Subnational estimates
gen subnational_yn="`subnational_yn'"

*	Subnational Unit Variable 
	if subnational_yn=="yes" {
		capture confirm var `subnational_unit' 
		if _rc!=0 {
			di in smcl as error "Variable `subnational_unit' not found in dataset. Please search for the correct geographic variable in the dataset to specify as the local macro, update the local and rerun the .do file"
			exit
			}
		}
		
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
log using "`briefdir'/PMA_`country'_Phase2_XS_HHQFQ_ContraceptiveTrends_Log_`date'.log", replace		

* Set local for xls file
local excel "PMA_`country'_Phase2_XS_HHQFQ_ContraceptiveTrends_`date'.xls"

* Set local for dataset
local dataset "PMA_`country'_Phase2_XS_HHQFQ_ContraceptiveTrends_`date'.dta"

*******************************************************************************
* SECTION 5: TRENDS IN METHOD USE
*
* Section 5 is necessary to make sure the .do file runs correctly, please do not 
* 	move, update or delete
*******************************************************************************
**********Prepare Excel**********
cd "`briefdir'"

putexcel set "`excel'", replace sheet("Method Use, Unmet Need, Demand")

putexcel C4=("All Women")
putexcel C6=("Dates of Data Collection"), txtwrap
putexcel D6=("N")
putexcel E6=("Longacting Method Use"), txtwrap
putexcel F6=("Shortacting Method Use"), txtwrap
putexcel G6=("Traditional Method Use"), txtwrap
putexcel H6=("Unmet Need for Limiting"), txtwrap
putexcel I6=("Unmet Need for Spacing"), txtwrap
putexcel J6=("Demand Satisfied by Modern Method"), txtwrap

***** PMA2020 AND PMA PHASE DATA
putexcel A7=("PMA2020 & PMA PHASE")

local row=8
forval i = 1/`PMAdataset_count' {
	use "`PMAdataset`i''", clear
	if "$level1"!="" {
		numlabel, remove force
		decode $level1_var, gen(str_$level1_var)
		replace str_$level1_var = proper(str_$level1_var)
		keep if str_$level1_var == proper("$level1")
		}
		
	capture confirm var round 
		if _rc==0 {
		    quietly sum round
			local round `r(max)'
			putexcel B`row'=("Round `round'")
			}
		else {
			cap gen phase=1
			quietly sum phase
			local phase `r(max)'
			putexcel B`row'=("Phase `phase'")			
			}
			
	putexcel C`row'=("`PMAdataset`i'dates'")

	** COUNT - Female Sample - All **
	capture confirm var last_night
	if _rc==0 {
		gen FQresponse_1=1 if FRS_result==1 & HHQ_result==1 & last_night==1
		}
	else {
		gen FQresponse_1=1 if FRS_result==1 & HHQ_result==1 & (usual_member==1 | usual_member==3)
		}
	preserve
	collapse (count) FQresponse_1
	mkmat FQresponse_1
	putexcel D`row'=matrix(FQresponse_1)
	restore

	** Generate Longacting shortacting
	gen shortacting= current_methodnum_rc>=5 & current_methodnum_rc<=16
	label var shortacting "Current use of short acting contraceptive method"

	gen longacting=current_methodnum_rc>=1 & current_methodnum_rc<=4
	label var shortacting "Current use of long acting contraceptive method"

	* Generate total demand = current use + unmet need
	gen totaldemand=0
	replace totaldemand=1 if cp==1 | unmettot==1
	label variable totaldemand "Has contraceptive demand, i.e. current user or unmet need"

	* Generate total demand staisfied
	gen totaldemand_sat=0 if totaldemand==1
	replace totaldemand_sat=1 if totaldemand==1 & mcp==1
	label variable totaldemand_sat "Contraceptive demand satisfied by modern method"

	* Unmet need for limiting
	gen unmet_limit = 0 if unmet != .
	replace unmet_limit = 1 if unmet == 2
	label var unmet_limit "Unmet need for limiting"

	* Unmet need for spacing
	gen unmet_space = 0 if unmet != .
	replace unmet_space = 1 if unmet == 1
	label var unmet_space "Unmet need for spacing"

	*** Estimate Percentage and 95% CI
	keep if FQresponse_1==1
	egen all=tag(FQmetainstanceID)
	
	if "`strata'"!="" {
		capture egen strata=concat(`strata'), punct(-)
		capture egen strata=concat($level1_var), punct(-)
		}
	else{
		gen strata=1
		}
	
	if country=="Nigeria" | country=="NG" {
		if "`subnational'"=="lagos" capture rename FQweight_Lagos FQweight 
		if "`subnational'"=="kano" 	capture rename FQweight_Kano FQweight 
		}
	
	svyset `PSU' [pw=`weight'], strata(strata) singleunit(scaled)
	foreach group in all {
	preserve
		keep if `group'==1
		foreach indicator in longacting shortacting tcp unmet_limit unmet_space totaldemand_sat{
			svy: prop `indicator', citype(wilson) percent
			matrix reference=r(table)
			matrix `indicator'_`group'_percent=round(reference[1,2]	, .1)
			}	
	restore
		}
	putexcel E`row'=matrix(longacting_all_percent)
	putexcel F`row'=matrix(shortacting_all_percent)
	putexcel G`row'=matrix(tcp_all_percent)
	putexcel H`row'=matrix(unmet_limit_all_percent)
	putexcel I`row'=matrix(unmet_space_all_percent)
	putexcel J`row'=matrix(totaldemand_sat_all_percent)
	local row=`row'+1
	}

***** PMA CURRENT PHASE
use "`PMAdatasetPhase2'", clear
keep if xs_sample==1

if "$level1"!="" {
	keep if level1=="$level1"	
	replace level1 = upper(level1)
	}

capture rename EA EA_ID
capture rename ClusterID Cluster_ID

destring phase, replace
quietly sum phase
local phase `r(max)'
putexcel B`row'=("Phase `phase'")			
putexcel C`row'=("`PMAdatasetPhase2dates'")

** COUNT - Female Sample - All / Married Women  **
preserve
		gen FQresponse_1=1 if FRS_result==1 & HHQ_result==1 & last_night==1
		collapse (count) FQresponse_1
		mkmat FQresponse_1
		putexcel D`row'=matrix(FQresponse_1)
	restore

	** Generate Longacting shortacting
	gen shortacting= current_methodnum_rc>=5 & current_methodnum_rc<=16
	label var shortacting "Current use of short acting contraceptive method"
	
	capture drop longacting
	gen longacting=current_methodnum_rc>=1 & current_methodnum_rc<=4
	label var shortacting "Current use of long acting contraceptive method"
	
	* Generate total demand = current use + unmet need
	gen totaldemand=0
	replace totaldemand=1 if cp==1 | unmettot==1
	label variable totaldemand "Has contraceptive demand, i.e. current user or unmet need"
	
	* Generate total demand staisfied
	gen totaldemand_sat=0 if totaldemand==1
	replace totaldemand_sat=1 if totaldemand==1 & mcp==1
	label variable totaldemand_sat "Contraceptive demand satisfied by modern method"
	
	* Unmet need for limiting
	gen unmet_limit = 0 if unmet != .
	replace unmet_limit = 1 if unmet == 2
	label var unmet_limit "Unmet need for limiting"
	
	* Unmet need for spacing
	gen unmet_space = 0 if unmet != .
	replace unmet_space = 1 if unmet == 1
	label var unmet_space "Unmet need for spacing"
	
	*** Estimate Percentage and 95% CI
	keep if FRS_result==1 & HHQ_result==1 & last_night==1
egen all=tag(FQmetainstanceID)

if "`strata'"!="" {
	capture egen strata=concat(`strata'), punct(-)
	}
else{
	gen strata=1
	}
	
svyset `PSU' [pw=FQweight], strata(strata) singleunit(scaled)
foreach group in all {
preserve
	keep if `group'==1
		foreach indicator in longacting shortacting tcp unmet_limit unmet_space totaldemand_sat{
			svy: prop `indicator', citype(wilson) percent
			matrix reference=r(table)
			matrix `indicator'_`group'_percent=round(reference[1,2]	, .1)
			}	
	restore
	putexcel E`row'=matrix(longacting_all_percent)
	putexcel F`row'=matrix(shortacting_all_percent)
	putexcel G`row'=matrix(tcp_all_percent)
	putexcel H`row'=matrix(unmet_limit_all_percent)
	putexcel I`row'=matrix(unmet_space_all_percent)
	putexcel J`row'=matrix(totaldemand_sat_all_percent)
	}


********************************************************************************
**********************TRENDS IN METHOD MIX**************************************
********************************************************************************

**********Prepare Excel**********
putexcel set "`excel'", modify sheet("Method Mix-All Women")
	
putexcel A1=("Method")
putexcel B1=("Round")
putexcel C1=("Dates")
putexcel D1=("Percent")
putexcel E1= ("N")

local row=2
forval y = 1/17 {
	forval i = 1/`PMAdataset_count' {
		use "`PMAdataset`i''", clear
		
		capture confirm var round 
		if _rc==0 {
			quietly sum round
			local round `r(max)'
			putexcel B`row'=("Round `round'")
			}
		else {
			cap gen phase=1
			quietly sum phase
			local phase `r(max)'
			putexcel B`row'=("Phase `phase'")			
			}
		
		if "$level1"!="" {
			numlabel, remove force
			decode $level1_var, gen(str_$level1_var)
			replace str_$level1_var =proper(str_$level1_var)
			keep if str_$level1_var == proper("$level1")
			}

		putexcel C`row'=("`PMAdataset`i'dates'")
		

		if "`strata'"!="" {
			capture egen strata=concat(`strata'), punct(-)
			}
		else{
			gen strata=1
			}
			
		if country=="Nigeria" | country=="NG" {
			if "`subnational'"=="lagos" capture rename FQweight_Lagos FQweight 
			if "`subnational'"=="kano" 	capture rename FQweight_Kano FQweight 
			}
			
		label define methods_list_num 1 "Female Sterilization" 2 "Male Sterilization" 3 "Implants" 4 "IUD"  5 "Injectables-IM"  ///
			6 "Injectables, 1mo" 7 "Pill" 8 "Emergency Contraception" 9 "Male Condoms" 10 "Female Condoms"  11 "Diaphragm" ///
			12 "Foam/Jelly" 13 "Std. Days/Cycle Beads" 14 "LAM" 15 "N Tablet"  16 "Injectable-SC" 17 "Other Modern", modify
		local method_`y'_lab: label methods_list_num `y'
		
		gen method_`y'=0 if mcp==1
		replace method_`y'=1 if current_methodnum_rc==`y'
		capture replace method_17=1 if current_methodnum_rc==19
		svyset `PSU' [pw=`weight'], strata(strata) singleunit(scaled)
		svy: tab method_`y' if mcp==1, percent
		if e(r)==2 {
			matrix prop_`y'=e(Prop)*100
			matrix prop_`y'=round(prop_`y'[2,1], .1)
			}
		else {
			matrix prop_`y'=0
			}
				
		putexcel A`row'=("`method_`y'_lab'")
		putexcel D`row' =matrix(prop_`y')
		putexcel E`row'=(e(N))
		local row=`row'+1
		}
	local row=`row' +2
	}
	
***** PMA PHASE Data	
use "`PMAdatasetPhase2'", clear
keep if xs_sample == 1

	if "$level1"!="" {
		numlabel, remove force
		decode $level1_var, gen(str_$level1_var)
		replace str_$level1_var = proper(str_$level1_var)
		keep if str_$level1_var == proper("$level1")
	}
		capture rename EA EA_ID
		capture rename ClusterID Cluster_ID
		
		putexcel B`row'=("PMA Phase 2")
		putexcel C`row'=("`PMAdatasetPhase2dates'")
		
		if "`strata'"!="" {
			capture egen strata=concat($leve1_var ur), punct(-)
			capture egen strata=concat($level1_var), punct(-)
			}
		else{
			gen strata=1
			}
	
		svyset `PSU' [pw=`weight'], strata(strata) singleunit(scaled)

local row=`PMAdataset_count'+2
forval y = 1/17 {
	label define methods_list_num 1 "Female Sterilization" 2 "Male Sterilization" 3 "Implants" 4 "IUD"  5 "Injectables"  ///
		6 "Injectables, 1mo" 7 "Pill" 8 "Emergency Contraception" 9 "Male Condoms" 10 "Female Condoms"  11 "Diaphragm" ///
		12 "Foam/Jelly" 13 "Std. Days/Cycle Beads" 14 "LAM" 15 "N Tablet"  16 "Sayana Press" 17 "Other Modern", modify
	local method_`y'_lab: label methods_list_num `y'

	gen method_`y'=0 if mcp==1
		replace method_`y'=1 if current_methodnum_rc==`y'
		capture replace method_17=1 if current_methodnum_rc==19
		svy: tab method_`y' if mcp==1, percent
		if e(r)==2 {
		matrix prop_`y'=e(Prop)*100
		matrix prop_`y'=round(prop_`y'[2,1], .1)
		}
		
	else {
		matrix prop_`y'=0
		}
	putexcel A`row'=("`method_`y'_lab'")
	destring phase, replace
	quietly sum phase
	local phase `r(max)'
	putexcel B`row'=("Phase 2")
	putexcel C`row'=("`PMAdatasetPhase2dates'")
	putexcel D`row' =matrix(prop_`y')
	putexcel E`row'=(e(N))
	local row=`row'+`PMAdataset_count'+2
	}

********************************************************************************
**********************TRENDS IN CPR,mCPR, UNMET NEED****************************
********************************************************************************

**********Prepare Excel**********
putexcel set "`excel'", modify sheet("CPR, mCPR, unmet need")
putexcel D4=("All Women")
putexcel Q4=("Married Women")
putexcel AD4= ("Unmarried Sexually Active")
putexcel E5=("CPR")
putexcel I5=("mCPR")
putexcel M5=("Total Unmet Need")
putexcel R5=("CPR")
putexcel V5=("mCPR")
putexcel Z5=("Total Unmet Need")
putexcel AE5=("CPR")
putexcel AI5=("mCPR")
putexcel AM5=("Total Unmet Need") 
putexcel C6=("Dates of Data Collection")
putexcel D6=("N")
putexcel Q6=("N")
putexcel AD6=("N")


foreach col in E I M R V Z AE AI AM {
	putexcel `col'6=("Percent")
	}

foreach col in F J N S W AA AF AJ AN {
	putexcel `col'6=("SE")
	}	

foreach col in G K O T X AB	AG AK AO {
	putexcel `col'6=("CI LB")
	}	

foreach col in H L P U Y AC AH AL AP {
	putexcel `col'6=("CI UB")
	}	

***** PMA2020 data
putexcel A7=("PMA2020 and PMA Phases")
local row=8

forval i = 1/`PMAdataset_count' {
	use "`PMAdataset`i''", clear
	if "$level1"!="" {
		numlabel, remove force
		decode $level1_var, gen(str_$level1_var)
		replace str_$level1_var = proper(str_$level1_var)
		keep if str_$level1_var== proper("$level1")
		}
	
		capture confirm var round 
		if _rc==0 {
			quietly sum round
			local round `r(max)'
			putexcel B`row'=("Round `round'")
			}
		else {
			cap gen phase=1
			quietly sum phase
			local phase `r(max)'
			putexcel B`row'=("Phase `phase'")			
			}
			
putexcel C`row'=("`PMAdataset`i'dates'")
	
* Generate Unmarried sexually active	
	cap drop umsexactive
	gen umsexactive=0 
	replace umsexact=1 if (FQmarital_status!=1 & FQmarital_status !=2 & FQmarital_status !=.) & ((last_time_sex==2 & last_time_sex_value<=4 & last_time_sex_value>=0) | ///
		(last_time_sex==1 & last_time_sex_value<=30 & last_time_sex_value>=0) | (last_time_sex==3 & last_time_sex_value<=1 & last_time_sex_value>=0))	
		

** COUNT - Female Sample - All / Married Women  **
	capture confirm var last_night
	if _rc==0 {
		gen FQresponse_1=1 if FRS_result==1 & HHQ_result==1 & last_night==1
		gen FQresponse_2=1 if FRS_result==1 & HHQ_result==1 & last_night==1 & (FQmarital_status==1 | FQmarital_status==2)
		gen FQresponse_3=1 if FRS_result==1 & HHQ_result==1 & last_night==1 & umsexactive == 1
		}
	else {
		gen FQresponse_1=1 if FRS_result==1 & HHQ_result==1 & (usual_member==1 | usual_member==3)
		gen FQresponse_2=1 if FRS_result==1 & HHQ_result==1 & (usual_member==1 | usual_member==3) & (FQmarital_status==1 | FQmarital_status==2)
		gen FQresponse_3=1 if FRS_result==1 & HHQ_result==1 & (usual_member==1 | usual_member==3) & umsexactive == 1
		
		}
	preserve
	collapse (count) FQresponse_1 FQresponse_2 FQresponse_3
	mkmat FQresponse_1
	mkmat FQresponse_2
	mkmat FQresponse_3
	putexcel D`row'=matrix(FQresponse_1)
	putexcel Q`row'=matrix(FQresponse_2)
	putexcel AD`row'=matrix(FQresponse_3)
	restore

	*** Estimate Percentage and 95% CI
	keep if FQresponse_1==1
	egen all=tag(FQmetainstanceID)
	egen mar=tag(FQmetainstanceID) if (FQmarital_status==1 | FQmarital_status==2)
	egen umsex = tag(FQmetainstanceID) if umsexactive == 1
	
	if "`strata'"!="" {
		capture egen strata=concat($level1_var ur), punct(-)
		capture egen strata=concat($level1_var), punct(-)
		}
	else{
		gen strata=1
		}
			
	if country=="Nigeria" | country=="NG" {
		if "`subnational'"=="lagos" capture rename FQweight_Lagos FQweight 
		if "`subnational'"=="kano" 	capture rename FQweight_Kano FQweight 
		}
	
	svyset `PSU' [pw=`weight'], strata(strata) singleunit(scaled)
	foreach group in all mar umsex {
	preserve
		keep if `group'==1
		foreach indicator in cp mcp unmettot  {
			svy: prop `indicator', citype(wilson) percent
			matrix reference=r(table)
			matrix `indicator'_`group'_percent=round(reference[1,2]	, .01)
			matrix `indicator'_`group'_se=round(reference[2,2], .01)
			matrix `indicator'_`group'_ll=round(reference[5,2], .01)
			matrix `indicator'_`group'_ul=round(reference[6,2], .01)
		}	
	restore
	}
	putexcel E`row'=matrix(cp_all_percent)
	putexcel F`row'=matrix(cp_all_se)
	putexcel G`row'=matrix(cp_all_ll)
	putexcel H`row'=matrix(cp_all_ul)
	putexcel I`row'=matrix(mcp_all_percent)
	putexcel J`row'=matrix(mcp_all_se)
	putexcel K`row'=matrix(mcp_all_ll)
	putexcel L`row'=matrix(mcp_all_ul)
	putexcel M`row'=matrix(unmettot_all_percent)
	putexcel N`row'=matrix(unmettot_all_se)
	putexcel O`row'=matrix(unmettot_all_ll)
	putexcel P`row'=matrix(unmettot_all_ul)
	putexcel R`row'=matrix(cp_mar_percent)
	putexcel S`row'=matrix(cp_mar_se)
	putexcel T`row'=matrix(cp_mar_ll)
	putexcel U`row'=matrix(cp_mar_ul)
	putexcel V`row'=matrix(mcp_mar_percent)
	putexcel W`row'=matrix(mcp_mar_se)
	putexcel X`row'=matrix(mcp_mar_ll)
	putexcel Y`row'=matrix(mcp_mar_ul)
	putexcel Z`row'=matrix(unmettot_mar_percent)
	putexcel AA`row'=matrix(unmettot_mar_se)
	putexcel AB`row'=matrix(unmettot_mar_ll)
	putexcel AC`row'=matrix(unmettot_mar_ul)
	putexcel AE`row'=matrix(cp_umsex_percent)
	putexcel AF`row'=matrix(cp_umsex_se)
	putexcel AG`row'=matrix(cp_umsex_ll)
	putexcel AH`row'=matrix(cp_umsex_ul)
	putexcel AI`row'=matrix(mcp_umsex_percent)
	putexcel AJ`row'=matrix(mcp_umsex_se)
	putexcel AK`row'=matrix(mcp_umsex_ll)
	putexcel AL`row'=matrix(mcp_umsex_ul)
	putexcel AM`row'=matrix(unmettot_umsex_percent)
	putexcel AN`row'=matrix(unmettot_umsex_se)
	putexcel AO`row'=matrix(unmettot_umsex_ll)
	putexcel AP`row'=matrix(unmettot_umsex_ul)
	local row=`row'+1
	}
	
***** PMA DATA
local row=`row'+1
use "`PMAdatasetPhase2'", clear

	if "$level1"!="" {
		numlabel, remove force
		decode $level1_var, gen(str_$level1_var)
		replace str_$level1_var = proper(str_$level1_var)
		keep if str_$level1_var == proper("$level1")
		}
	
	capture rename EA EA_ID
	capture rename ClusterID Cluster_ID

	putexcel A`row'=("PMA Phase2")
	putexcel B`row'=("Phase 2")
	putexcel C`row'=("`PMAdatasetPhase2dates'")

* Generate Unmarried sexually active	
	cap drop umsexactive
	gen umsexactive=0 
	replace umsexact=1 if (FQmarital_status!=1 & FQmarital_status!=2 & FQmarital_status !=.) & ((last_time_sex==2 & last_time_sex_value<=4 & last_time_sex_value>=0) | ///
	(last_time_sex==1 & last_time_sex_value<=30 & last_time_sex_value>=0) | (last_time_sex==3 & last_time_sex_value<=1 & last_time_sex_value>=0))


** COUNT - Female Sample - All / Married Women  **
	preserve
	gen FQresponse_1=1 if FRS_result==1 & HHQ_result==1 & last_night==1
	collapse (count) FQresponse_1
	mkmat FQresponse_1
	putexcel D`row'=matrix(FQresponse_1)
	restore
	preserve
	gen FQresponse_1=1 if FRS_result==1 & HHQ_result==1 & last_night==1 & (FQmarital_status==1 | FQmarital_status==2)
	collapse (count) FQresponse_1
	mkmat FQresponse_1
	putexcel Q`row'=matrix(FQresponse_1)
	restore 
	preserve
	gen FQresponse_3=1 if FRS_result==1 & HHQ_result==1 & last_night==1 &umsexactive == 1
	collapse (count) FQresponse_3
	mkmat FQresponse_3
	putexcel AD`row'=matrix(FQresponse_3)
	restore 
	
	*** Estimate Percentage and 95% CI
	keep if FRS_result==1 & HHQ_result==1 & last_night==1
	egen all=tag(FQmetainstanceID)
	egen mar=tag(FQmetainstanceID) if (FQmarital_status==1 | FQmarital_status==2)
	egen umsex = tag(FQmetainstanceID) if umsexactive == 1
	
	
	if "`strata'"!="" {
		capture egen strata=concat($level1_var ur), punct(-)
		capture egen strata=concat($level1_var), punct(-)
		}
	else{
		gen strata=1
		}
		
	svyset `PSU' [pw=`weight'], strata(strata) singleunit(scaled)
	foreach group in all mar umsex {
		preserve
		keep if `group'==1
		foreach indicator in cp mcp unmettot {
			svy: prop `indicator', citype(wilson) percent
			matrix reference=r(table)
			matrix `indicator'_`group'_percent=round(reference[1,2]	, .01)
			matrix `indicator'_`group'_se=round(reference[2,2], .01)
			matrix `indicator'_`group'_ll=round(reference[5,2], .01)
			matrix `indicator'_`group'_ul=round(reference[6,2], .01)
			}	
		restore
		}
	putexcel E`row'=matrix(cp_all_percent)
	putexcel F`row'=matrix(cp_all_se)
	putexcel G`row'=matrix(cp_all_ll)
	putexcel H`row'=matrix(cp_all_ul)
	putexcel I`row'=matrix(mcp_all_percent)
	putexcel J`row'=matrix(mcp_all_se)
	putexcel K`row'=matrix(mcp_all_ll)
	putexcel L`row'=matrix(mcp_all_ul)
	putexcel M`row'=matrix(unmettot_all_percent)
	putexcel N`row'=matrix(unmettot_all_se)
	putexcel O`row'=matrix(unmettot_all_ll)
	putexcel P`row'=matrix(unmettot_all_ul)
	putexcel R`row'=matrix(cp_mar_percent)
	putexcel S`row'=matrix(cp_mar_se)
	putexcel T`row'=matrix(cp_mar_ll)
	putexcel U`row'=matrix(cp_mar_ul)
	putexcel V`row'=matrix(mcp_mar_percent)
	putexcel W`row'=matrix(mcp_mar_se)
	putexcel X`row'=matrix(mcp_mar_ll)
	putexcel Y`row'=matrix(mcp_mar_ul)
	putexcel Z`row'=matrix(unmettot_mar_percent)
	putexcel AA`row'=matrix(unmettot_mar_se)
	putexcel AB`row'=matrix(unmettot_mar_ll)
	putexcel AC`row'=matrix(unmettot_mar_ul)
	putexcel AE`row'=matrix(cp_umsex_percent)
	putexcel AF`row'=matrix(cp_umsex_se)
	putexcel AG`row'=matrix(cp_umsex_ll)
	putexcel AH`row'=matrix(cp_umsex_ul)
	putexcel AI`row'=matrix(mcp_umsex_percent)
	putexcel AJ`row'=matrix(mcp_umsex_se)
	putexcel AK`row'=matrix(mcp_umsex_ll)
	putexcel AL`row'=matrix(mcp_umsex_ul)
	putexcel AM`row'=matrix(unmettot_umsex_percent)
	putexcel AN`row'=matrix(unmettot_umsex_se)
	putexcel AO`row'=matrix(unmettot_umsex_ll)
	putexcel AP`row'=matrix(unmettot_umsex_ul)
	local row=`row'+1

	
**************************************************************************
**************** MCPR TRENDS BY REGION - KENYA ONLY **********************
**************************************************************************
if country == "Kenya" {
 
putexcel set "`excel'", modify sheet("MCPR by Level1")
putexcel A1 = "mCPR by county for Kenya"
putexcel B2 = ("County")
putexcel C2 = ("N")
putexcel D2 = ("mCPR%")	


local row 3

forval i = 1/`PMAdataset_count' {
	use "`PMAdataset`i''", clear
	putexcel A`row' = ("Phase `i'")
	
	decode county, gen(county_string)
		gen county_string1=substr(county_string,4,.)
		gen county_string2=subinstr(county_string1," ","",.)
		gen county_string3=subinstr(county_string2,"_","",.)
		gen county_string4=regexr(county_string3,word(county_string3,1), proper(word(county_string3,1)))
		replace county_string4="Pokot" if county_string4=="Westpokot"
		replace county_string4="Kimbu" if county_string4=="Kiambu"
	levelsof county_string4, local(levels) 
	foreach l of local levels {
		foreach group in all {
			preserve
			egen all=tag(FQmetainstanceID)
			keep if county_string4 == "`l'"
			foreach indicator in  mcp  {
				svyset `PSU' [pw=`weight'_`l'], strata(strata) singleunit(scaled)
					svy: prop `indicator', percent
					matrix reference=r(table)
					matrix `indicator'_`group'_percent=round(reference[1,2]	, .01)	
					local RowCount = e(N_pop)
					}	
			}
		restore
		putexcel D`row'=matrix(mcp_all_percent)
		putexcel B`row' = "`l'"
		putexcel C`row' = `RowCount'
		local row=`row'+1
		}	
			
	}
		drop county_string county_string1 county_string2 county_string3 county_string4
}

*******************************************************************************
* CLOSE
*******************************************************************************

log close
