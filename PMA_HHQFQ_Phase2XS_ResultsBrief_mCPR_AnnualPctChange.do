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
*   contraceptive trends. You can find those .do files in the
*   PMA_Analyses_Public repository
*
* If you have any questions on how to use this or any of the other .do files in
* 	the PMA_Analyses_Public repository, please contact the PMA Data Management 
* 	Team at datamanagement@pma2020.org
*******************************************************************************/

/*******************************************************************************
*
*  FILENAME:		PMA_HHQFQ_Phase2XS_ResultsBrief_mCPR_AnnualPctChange.do
*  PURPOSE:			Generate the .xls output with the mCPR Annual Percent Change for the PMA Phase 2 XS Results Brief
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

*	1a. Total number of PMA2020 datasets to include in the analysis. The local should 
*		be the number.
*		- For example: local PMA2020dataset_count 4
*		- For example: local PMA2020dataset_count 7
local PMA2020dataset_count 6

*	1b. Total number of PMA datasets to include in the analysis. The local should 
*		be the number.
*		- For example: local PMAdataset_count 1
*		- For example: local PMAdataset_count 3
local PMAdataset_count 2

*	2. A directory for the folder where you want to save the dataset, xls and
*		log files that this .do file creates
*		- For example (Mac): 
*		  local briefdir "/User/ealarson/Desktop/PMA2020/NigeriaAnalysisOutput"
*		- For example (PC): 
*		  local briefdir "C:\Users\annro\PMA2020\NigeriaAnalysisOutput"
local briefdir "/Users/ealarson/Documents/PMA/Burkina Faso/PublicRelease/Phase 2/untitled folder"

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

*	Year of Data Collection for the Phase or Round of data collection 
*		corresponding to the given dataset. If data collection took place in 
*		one year only, the format should be "YYYY" where the YYYY represents the 
*		numeric code for the year of data collection. If data collection took place 
*		over two years, only indicate the first year. Leave extra locals blank if you are 
*		not including 9 datasets in your analysis
*		- For example: local dataset1year "2019"

***********************************************
* PMA2020 DATASETS
***** FIRST DATASET *****
* Dataset 1 Directory
local PMA2020dataset1 "/Users/ealarson/Dropbox (Gates Institute)/5 Burkina Faso/PMABF_Datasets/Round1/Final_PublicRelease/HHQ/PMA2014_BFR1_HHQFQ_v3_6Nov2018/PMA2014_BFR1_HHQFQ_v3_6Nov2018.dta"

local datasetyear1 "2014"

***** SECOND DATASET *****
* Dataset 2 Directory
local PMA2020dataset2 "/Users/ealarson/Dropbox (Gates Institute)/5 Burkina Faso/PMABF_Datasets/Round2/Final_PublicRelease/HHQ/PMA2015_BFR2_HHQFQ_v3_6Nov2018/PMA2015_BFR2_HHQFQ_v3_6Nov2018.dta" 

local datasetyear2 "2015"

***** THIRD DATASET *****
* Dataset 3 Directory
local PMA2020dataset3 "/Users/ealarson/Dropbox (Gates Institute)/5 Burkina Faso/PMABF_Datasets/Round3/Final_PublicRelease/HHQ/PMA2016_BFR3_HHQFQ_v3_6Nov2018/PMA2016_BFR3_HHQFQ_v3_6Nov2018.dta"

local datasetyear3 "2016"

***** FOURTH DATASET *****
* Dataset 4 Directory
local PMA2020dataset4 "/Users/ealarson/Dropbox (Gates Institute)/5 Burkina Faso/PMABF_Datasets/Round4/Final_PublicRelease/HHQ/PMA2016_BFR4_HHQFQ_v4_6Nov2018/PMA2016_BFR4_HHQFQ_v4_6Nov2018.dta"

local datasetyear4 "2016"

***** FIFTH DATASET *****
* Dataset 5 Directory
local PMA2020dataset5 "/Users/ealarson/Dropbox (Gates Institute)/5 Burkina Faso/PMABF_Datasets/Round5/Final_PublicRelease/HHQFQ/PMA2017_BFR5_HHQFQ_v1_26Aug2018/PMA2017_BFR5_HHQFQ_v1_26Aug2018.dta"

local datasetyear5 "2017"

***** SIXTH DATASET *****
* Dataset 6 Directory
local PMA2020dataset6 "/Users/ealarson/Dropbox (Gates Institute)/5 Burkina Faso/PMABF_Datasets/Round6/Final_PublicRelease/HHQFQ/PMA2019_BFR6_HHQFQ_v1_17May2019/PMA2019_BFR6_HHQFQ_v1_20May2019.dta"

local datasetyear6 "2018"

***** SEVENTH DATASET *****
* Dataset 7 Directory
local PMA2020dataset7 ""

local datasetyear7 ""

***********************************************
* PMA DATASETS
***** FIRST DATASET *****
* Dataset 1 Directory
local PMAdataset1 "/Users/ealarson/Dropbox (Gates Institute)/5 Burkina Faso/PMABF_Datasets/Phase1/Final_PublicRelease/HQFQ/PMA2020_BFP1_HQFQ_v2.0_1Oct2021/PMA2020_BFP1_HQFQ_v2.0_1Oct2021.dta"

local datasetyear8 "2019"

***** SECOND DATASET *****
* Dataset 2 Directory
local PMAdataset2 "/Users/ealarson/Dropbox (Gates Institute)/5 Burkina Faso/PMABF_Datasets/Phase2/Final_PublicRelease/HQFQ/PMA2021_BFP2_HQFQ_v1.0_7Oct2021/PMA2021_BFP2_HQFQ_v1.0_1Oct2021.dta"

local datasetyear9 "2020"

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
*		 geographical level variable, typically "region" or "county". Enter the 
*		 local in lower case letters, even if it uppercase in the dataset.
*		 If you are not running a submational estimate, leave the subnational_unit 
*		 and subnational macros empty ("")
*		 - For example (No subnational estimate):
*		   local subnational_yn "no"
*		   local subnational_unit 
*		   local subnational ""
*		 - For example (Subnational estimate for Kenya, Kericho county):
*		   local subnational_yn "yes"
*		   local subnational_unit county
*		   local subnational "kericho"
local subnational_yn "no"
local subnational_unit region
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

* Open dataset
use "`PMAdataset2'",clear

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
	if _rc!=0 & _rc!=7 {
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
		gen subnational_keep2=lower(subnational_keep1)
		gen check=(subnational_keep2==subnational)
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
		gen subnational_keep2=lower(subnational_keep1)
		gen check=(subnational_keep2==subnational)
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
		gen subnational_keep2=lower(subnational_keep1)
		gen check=(subnational_keep2==subnational)
		keep if check==1
		capture quietly regress check region
			if _rc==2000 {
				di in smcl as error "The specified sub-national level is not correct. Please search for the sub-national variable in the dataset to identify the correct spelling of the sub-national level, update the local and rerun the .do file"
				exit		
				}
		local country `country'_`subnational'
		drop subnational region_string subnational_keep subnational_keep1 check
		}
		
* 	Niger
	if country=="NE" & subnational_yn=="yes" {
		gen subnational="`subnational'"
		decode region, gen(region_string)
		gen subnational_keep=substr(region_string,4,.)
		gen subnational_keep1=subinstr(subnational_keep," ","",.)
		gen subnational_keep2=lower(subnational_keep1)
		gen check=(subnational_keep2==subnational)
		keep if check==1
		capture quietly regress check region
			if _rc==2000 {
				di in smcl as error "The specified sub-national level is not correct. Please search for the sub-national variable in the dataset to identify the correct spelling of the sub-national level, update the local and rerun the .do file"
				exit		
				}
		local country `country'_`subnational'
		capture drop subnational region_string subnational_keep subnational_keep1 check
		}		

*	Nigeria
	if country=="Nigeria" & subnational_yn=="yes" {
		gen subnational="`subnational'"
		decode state, gen(state_string)
		gen subnational_keep=substr(state_string,4,.)
		gen subnational_keep1=subinstr(subnational_keep," ","",.)
		gen subnational_keep2=lower(subnational_keep1)
		gen check=(subnational_keep2==subnational)
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
log using "`briefdir'/PMA_`country'_Phase2_XS_HHQFQ_mCPR_AnnualPctChange_Log_`date'.log", replace		

* Set local for xls file
local excel "PMA_`country'_Phase2_XS_HHQFQ_mCPR_AnnualPctChange_`date'.xls"

* Set local for dataset
local dataset "PMA_`country'_Phase2_XS_HHQFQ_mCPR_AnnualPctChange_`date'.dta"

*******************************************************************************
* SECTION 5: SET UP DATASETS
*
* Section 5 is necessary to make sure the .do file runs correctly, please do not 
* 	move, update or delete
*******************************************************************************
cd "`briefdir'"

**********Ensure correct variables in datsets**********
***** PMA2020 DATA
forval i = 1/`PMA2020dataset_count' {
	use "`PMA2020dataset`i''", clear

	* Restrict to Sub-National if Necessary
	gen subnational_yn="`subnational_yn'"
	if subnational_yn=="yes" {
		gen subnational="`subnational'"
		decode `subnational_unit', gen(`subnational_unit'_string)
		gen subnational_keep=substr(`subnational_unit'_string,4,.)
		gen subnational_keep1=subinstr(subnational_keep," ","",.)
		gen subnational_keep2=lower(subnational_keep1)
		keep if subnational==subnational_keep2
		}
	drop subnational_yn
	
	* Generate Necessary Variables
	gen xdefacto=0
	capture confirm var eligible
	if _rc==0 {
		replace xdefacto=1 if eligible==1
		}
	else {
		capture confirm var last_night
		if _rc==0 {
			replace xdefacto=1 if last_night==1
		}
		else {
			replace xdefacto=1 if inlist(usual_member,1,3)
		}
	}

	save `country'_Round`i', replace
	}

***** PMA DATA
forval i=1/`PMAdataset_count' {
	use "`PMAdataset`i''", clear
	
	** Restrict to Sub-National if Necessary
	gen subnational_yn="`subnational_yn'"
	if subnational_yn=="yes" {
		gen subnational="`subnational'"
		decode `subnational_unit', gen(`subnational_unit'_string)
		gen subnational_keep=substr(`subnational_unit'_string,4,.)
		gen subnational_keep1=subinstr(subnational_keep," ","",.)
		gen subnational_keep2=lower(subnational_keep1)
		keep if subnational==subnational_keep2
		}
	drop subnational_yn
	
	* Generate Necessary Variables
	gen xdefacto=0
	replace xdefacto=1 if eligible==1
	save `country'_Phase`i', replace
	}
	
**********Generate Necessary Variables**********	
***** PMA2020 DATA
set more off
forval i=1/`PMA2020dataset_count' {
	use "`country'_Round`i'.dta", clear
	
	* Keep only the PMA Sample
	keep if HHQ_result==1 & FRS_result==1
	keep if xdefacto==1
	keep if mcp!=.
	
	* Survey Year and Month
	capture confirm variable FQtodaySIF 
		if !_rc {
			d FQtodaySIF				
			}
		else {
			gen FQtodaySIF= FQsystem_dateSIF
			}
			
	replace FQtodaySIF=dofc(FQtodaySIF)	
	format FQtodaySIF %td

	sort FQtodaySIF
	local j=int(_N/2)
	gen intdate=FQtodaySIF[`j']	
	
	gen dataset`i'year=`datasetyear`i''
	
	* Strata
	capture confirm variable strata 
		if !_rc {
			d strata
			}
		else {
			gen strata=99	
			}	
	egen xstrata=group(strata)
	
	capture destring round, replace
	keep x* FQ* country round `strata' `PSU' mcp cp current_method* intdate
	save temp_`country'_Round`i', replace
	}	
	
***** PMA DATA
set more off
forval i=1/`PMAdataset_count' {
	use "`country'_Phase`i'.dta", clear
	
	* Keep only the PMA Sample
	keep if HHQ_result==1 & FRS_result==1
	keep if xdefacto==1
	keep if mcp!=.
	
	* Survey Year and Month
	capture confirm variable FQtodaySIF 
		if !_rc {
			replace FQtodaySIF=startSIF				
			}
		else {
			gen FQtodaySIF= startSIF
			}
			
	replace FQtodaySIF=dofc(FQtodaySIF)	
	format FQtodaySIF %td
	
	sort FQtodaySIF
	local j=int(_N/2)
	gen intdate=FQtodaySIF[`j']	
	
	
	* Strata
	capture confirm variable strata 
		if !_rc {
			d strata
			}
		else {
			gen strata=99	
			}	
	egen xstrata=group(strata)
	
	* Round variable
	capture drop round
	gen round=`i'+`PMA2020dataset_count'
	destring round, replace
	keep x* FQ* country round `strata' `PSU' mcp cp current_method* intdate
	save temp_`country'_Phase`i', replace
		
	}
	
**********Append Datasets**********	
use temp_`country'_Round1, clear
	save `country'_IR_pooled, replace

forval i=2/`PMA2020dataset_count' {
	use `country'_IR_pooled, clear
	append using temp_`country'_Round`i', force
	save `country'_IR_pooled, replace
	}

forval i=1/`PMAdataset_count' {
	use `country'_IR_pooled, clear
	append using temp_`country'_Phase`i', force
	save `country'_IR_pooled, replace
	}
	
**********Generate Variables for Analysis**********	
use `country'_IR_pooled, clear

* Start Date

egen R1_intdate=min(intdate)
	replace R1_intdate=R1_intdate[_n-1] if R1_intdate==.
	
* Lag year
gen lagyear=(intdate-R1_intdate)/365
tab lagyear

* Maximum round (most recent implemented phase)lol
egen maxround=max(round)

save `country'_IR_pooled, replace

*******************************************************************************
* SECTION 5: SURVEY ESTIAMTES
*
* Section 6 is necessary to make sure the .do file runs correctly, please do not 
* 	move, update or delete
*******************************************************************************	

capture putdocx clear 
putdocx begin
putdocx save "PMA_`country'_Phase2_AnnualPctChange_`date'.docx", replace

clear
set obs 1
gen n=1
save ratechange, replace	

** Geographic level updates
use `country'_IR_pooled, clear

	svyset `PSU' [pw=`weight'], str(xstrata) single(scaled)

	svy: prop mcp, over(round)

	matrix a=r(table)

	gen mCPR=.
    gen mcpr1st=.
	gen mcprlast=.
	gen mCPR_ll=.
	gen mCPR_ul=.
    
	local k=maxround 
	
	replace mcpr1st=a[1,`k'+1]  	  
	replace mcprlast=a[1,`k'+`k']  	  
	
	gen totlagyear=lagyear if round==`k'
	
	*final lagyear
	egen flagyear=mean(totlagyear)
	
	*sample size
	gen i=1
	egen ncount=count(i), by(round)
	
	gen n1st=ncount if round==1
	egen nround1st=mean(n1st)
	
	gen nlast=ncount if round==`k'
	egen nroundlast=mean(nlast)
	
	sort intdate
	gen intyr1st=intdate[1]
	gen intyrlast=intdate[_N]
    for var intyr1st intyrlast: format X %tc

	*since maxround varies across countries
	local roundcount=`PMA2020dataset_count'+`PMAdataset_count'
	forvalues j=1(1)`roundcount'{
		forvalues i=1(1)`j' {
			replace mCPR=a[1,`i'+`j']  	  if round==`i'	& maxround==`j'          
			replace mCPR_ll=a[5,`i'+`j']  if round==`i'	& maxround==`j'
			replace mCPR_ul=a[6,`i'+`j']  if round==`i'	& maxround==`j'
			}
		}
	
	* Change locals if fewer than 7 PMA2020 rounds
	gen roundcount=`roundcount' 
	if roundcount<9 {
	gen PMAdataset_count=`PMAdataset_count'
		if PMAdataset_count==2 {
			forval i=8/9 {
				local round_update = `i'-`roundcount'
				local new_dataset_num = `PMA2020dataset_count'+`round_update'+1
				local datasetyear`new_dataset_num' = `datasetyear`i''
				}
			}
		else if PMAdataset_count==1 {
			local round_update = 8-`roundcount'
			local new_dataset_num = `PMA2020dataset_count'+`round_update'+1
			local datasetyear`new_dataset_num' = `datasetyear8'
			}
		}
		
		

	
	forval i=1/`roundcount' {
		gen datasetyear`i'=`datasetyear`i'' if round==`i'
		sort datasetyear`i'
		replace datasetyear`i'=datasetyear`i'[_n-1] if datasetyear`i'==.
		}
		

	local inf_rc=`roundcount'+1
	local inf_year=`datasetyear1'+`inf_rc'
	
	
		gen datasetyear`inf_rc'=`inf_year'
	forval i=2/`inf_rc' {
		local j=`i'-1
		gen dataset`j'check=1 if datasetyear`j'==datasetyear`i'
		if dataset`j'check!=1 {
			local datasetyear`j'm `datasetyear`j''m11
			}
		if dataset`j'check==1 {
			local datasetyear`j'm `datasetyear`j''m6
			}
		}

	foreach i in `datasetyear1m' `datasetyear2m' `datasetyear3m' `datasetyear4m' `datasetyear5m' `datasetyear6m' `datasetyear7m' `datasetyear8m' `datasetyear9m' {
	di m(`i') " " _c
	local x = m(`i') 
	local X "`X'`x' " 
	 }
	 
	 forval i=1/`roundcount' {
	 	preserve
		keep if round==`i'
	 	local idatelabel_r`i'=intdate
		di `idatelabel_r`i''
		restore
		}
	 
	***** CALENDAR variable format	
	tab intdate
	replace intdate=cofd(intdate)
		format intdate  %tCMon_CCYY
	lab var intdate "Calendar Year"
	replace intdate=dofc(intdate)
		gen idate=dofd(intdate)
	format intdate %tdMon_CCYY 
	tab intdate, m

	ta idate	
	
	br FQtodaySIF idate intdate round mcp `weight' `PSU'

	global intdatelabel "`idatelabel_r1' `idatelabel_r2' `idatelabel_r3' `idatelabel_r4' `idatelabel_r5' `idatelabel_r6' `idatelabel_r7' `idatelabel_r8' `idatelabel_r9'"
	
capture putdocx clear 
putdocx begin

putdocx paragraph
putdocx text ("`country'"), bold linebreak
putdocx text ("`today'")
  
	preserve
	for var mCPR mCPR_ll mCPR_ul: replace X=X*100
	bysort round: keep if _n==1
	
	#delimit;	
	graph twoway scatter mCPR intdate,     
	|| pcspike mCPR_ll intdate mCPR_ul intdate, lcolor(navy)  
	|| lfit mCPR intdate, 
		legend(label(1 "Observed mCPR") label(2 "95% CI" ) label(3 "Linear fit" )
			size(*.75) row(1))  
		plotregion(margin(large)) 
		ylabel(0(5)50) xlabel($intdatelabel, valuelabel labsize(*.75)) 
		ytitle("mCPR (%)") xtitle("Calendar Year", size(*.75)) ///
		title("mCPR in `country' by survey round" "with linear fitted line")
		xsize(6) ysize(3.5)
		;
		#delimit cr
	restore	
	
br EA round intdate mCPR*

*********************************************************
*****  Regression models 
*********************************************************	

*** A. LOGIT model	
*** A1. linear logit
	svy:logit mcp c.lagyear 

	*estat gof
	predict p1
	margins, dydx(lagyear) 

	matrix A= r(table)
	gen dy_llogit=A[1,1]
	gen se_llogit=A[2,1]
	gen ll_llogit=A[5,1]
	gen ul_llogit=A[6,1]
	
*putdocx pagebreak
putdocx paragraph
putdocx text ("A. Logit model"), linebreak
putdocx text ("Annual change rate of mCPR (dydx [elasticity] estimate for linear logit model)"), 			 
putdocx table tbl2 = etable, width(100%)
estat gof
gen GOFp_l= r(p)
gen GOFf_l= r(F)

gen GOFdf1_l=r(df1)
gen GOFdf2_l=r(df2)

local gof = "GOF p-value: " + string(GOFp_l,"%4.03f") + "  F(" + string(GOFdf1_l,"%3.0f") + "," + string(GOFdf2_l,"%3.0f") + ") = " + string(GOFf_l,"%4.02f")
 
putdocx paragraph
putdocx text ("`gof'"), bold
putdocx paragraph


*** A2. Quadratic logit model

	svy:logit mcp c.lagyear##c.lagyear 
	matrix R=r(table)
	*p-value for the square term
    gen p_sqterm=R[4,2]
	
    *estat gof, group(5)
	predict p2
	margins, dydx(lagyear) 


	matrix A= r(table)
	gen dy_qlogit=A[1,1]
	gen se_qlogit=A[2,1]
	gen ll_qlogit=A[5,1]
	gen ul_qlogit=A[6,1]

	
putdocx paragraph
putdocx text ("Annual change rate of mCPR (dydx [elasticity] estimate for quadratic logit model)"), 
putdocx table tbl2 = etable, width(100%) 

estat gof
gen GOFp_q= r(p)
gen GOFf_q= r(F)

gen GOFdf1_q=r(df1)
gen GOFdf2_q=r(df2)


local gof = "GOF p-value: " + string(GOFp_q,"%4.03f") + "  F(" + string(GOFdf1_q,"%3.0f") + "," + string(GOFdf2_q,"%3.0f") + ") = " + string(GOFf_q,"%4.02f")


putdocx paragraph
putdocx text ("`gof'"), bold
putdocx paragraph

	preserve
	for var mCPR* p1 p2 : replace X=X*100
	bysort round: keep if _n==1
	
	gen ylab="0(5)50"
	
	drop country
	gen country="`country'"
	
	local Country=country
	local ylab=ylab
	
	#delimit;
	graph twoway scatter mCPR intdate , ylabel(0(5)50)
	|| pcspike mCPR_ll intdate mCPR_ul intdate , lcolor(navy)
	|| line p1 intdate , lcolor(cranberry)
	|| line p2 intdate , lcolor(orange) 
	|| ,  
		legend(	label(1 "Observed") label(2 "95% CI" )  
				label(3 "Linear" "logit fit" )  label(4 "Quadratic" "logit fit" )
				size(*.5) r(1) ring(0) ) 
		ylabel(`ylab') xlabel($intdatelabel, valuelabel labsize(*.75) angle(45) ) ytitle("mCPR (%)") 
		title("`Country'")
		saving(`country'.gph, replace)
		xsize(6) ysize(3.5)
		;
		#delimit cr
			
	restore


preserve

label define round 1 "R1" 2 "R2" 3 "R3" 4 "R4" 5 "R5" 6 "R6" 7 "R7" 8 "R8" 9 "R9"
label val round round 

label define mpc_use 0 "No mCPR Use" 1 "mCPR Use"
label val mcp mpc_use

putdocx paragraph
putdocx text ("mCPR by round"), linebreak
svy: prop mcp, over(round)
matrix a=r(table)
putdocx table a = etable, width(100%)	

putdocx paragraph
graph export graph.png, replace
putdocx image graph.png

capture drop p1 p2 

restore

* BELOW is for the summary table
keep if _n==1

putdocx paragraph
putdocx text ("Summary of annual change rate of mCPR (dydx [elasticity] estimates)") 
putdocx table stable = (2,4)

putdocx table stable(2,1)=("`country'")
putdocx table stable(2,2)=("Logit model")

putdocx table stable(1,1)=("Country")
putdocx table stable(1,2)=("Model")
putdocx table stable(1,3)=("Linear")
putdocx table stable(1,4)=("Quadratic")

	capture drop s1 s2 s3
 
	for var dy* ll* ul* se*: replace X=X*100
	for var dy* ll* ul*: format X %4.2f 
 
	gen s1 = string(dy_llogit,"%3.1f") + "(" + string(ll_llogit,"%3.1f") + "-" + string(ul_llogit,"%3.1f") + ")"
	gen s2 = string(dy_qlogit,"%3.1f") + "(" + string(ll_qlogit,"%3.1f") + "-" + string(ul_qlogit,"%3.1f") + ")"

	for var s1 s2: ta X
	
	
putdocx table stable(2,3)=(s1)
putdocx table stable(2,4)=(s2)

   keep dy* se* ll* ul* GOFp_l GOFp_q GOFf_l GOFf_q mcpr* flagyear nround* intyr1st intyrlast p_sq* mCPR*
   gen country="`country'"
   append using ratechange
   save ratechange, replace
		
putdocx save "PMA_`country'_Phase2_AnnualPctChange_`date'.docx", append


** ERASE TEMPORARY DATASETS
local list : dir . files "*temp*.dta"
foreach f of local list {
    erase "`f'"
}
forval i=1/`PMA2020dataset_count' {
	erase `country'_Round`i'.dta
	}
forval i=1/`PMAdataset_count' {
	erase `country'_Phase`i'.dta
	}

*******************************************************************************
* CLOSE
*******************************************************************************

log close
