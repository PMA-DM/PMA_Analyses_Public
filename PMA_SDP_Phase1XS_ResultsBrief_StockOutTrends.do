/*******************************************************************************
* The following .do file will create the .xls file output that PMA used to 
* 	generate its Phase 1 cross sectional results briefs using PMA's publicly  
* 	available SDP dataset
*
* This .do file will only work on Phase 1 SDP cross sectional datasets. You 
*   can  find the .do files to generate the .xls file outputs for PMA's publicly
* 	available Phase 1 HHQFQ and CQ datasets and other surveys in the  
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
*  FILENAME:		PMA_/sdp_Phase1XS_ResultsBrief_StockOutTrends.do
*  PURPOSE:			Generate the .xls output with SDP trends for the PMA Phase 1 XS Results Brief
*  CREATED BY: 		Elizabeth Larson (elarso11@jhu.edu)
*  DATA IN:			PMA's Phase1 XS SDP publicly released dataset
*  DATA OUT: 		PMA_COUNTRY_PHASE_XS_StockOutTrends_DATE.dta
*  FILE OUT: 		PMA_COUNTRY_PHASE_XS_StockOutTrends_DATE.xls
*  LOG FILE OUT: 	PMA_COUNTRY_PHASE_XS_StockOutTrends_Log_DATE.log
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
*		- For example: local dataset_count 4
*		- For example: local dataset_count 7
local PMA2020dataset_count 7

*	1b. Total number of PMA datasets to include in the analysis. The local should 
*		be the number.
*		- For example: local dataset_count 1
*		- For example: local dataset_count 3
local PMAdataset_count 1

*	2. A directory for the folder where you want to save the dataset, xls and
*		log files that this .do file creates
*		- For example (Mac): 
*		  local briefdir "/User/ealarson/Desktop/PMA2020/NigeriaAnalysisOutput"
*		- For example (PC): 
*		  local briefdir "C:\Users\annro\PMA2020\NigeriaAnalysisOutput"
local briefdir "/Users/ealarson/Documents/PMA/Kenya/PublicRelease"

************** DATASETS *************
*	Directory for each of the publicly available PMA2020 and PMA datasets on  
*		your computer. When entering datasets, start with the earliest and end 
*		with the most recent. Enter PMA2020 Datasets first and PMA Datasets
*		second. Leave exta locals blank if you are not including 10 datasets in 
*		your analysis.
*		- For example (Mac): 
*		  local dataset1 "/User/ealarson/Desktop/PMA2020/PMA2018_NGR5_National_HHQFQ_v5_4Nov2019"
*		- For example (PC):
* 		  local dataset1 "C:\Users\annro\PMA2020\PMA2018_NGR5_National_HHQFQ_v5_4Nov2019.dta"

***********************************************
* PMA2020 DATASETS
***** FIRST DATASET *****
* Dataset 1 Directory
local PMA2020dataset1 "/Users/ealarson/Dropbox (Gates Institute)/12 Kenya/PMAKE_Datasets/Round1/Final_PublicRelease/SDP/PMA2014_KER1_SDP_v1_24Jan2017/PMA2014_KER1_SDP_v1_23Jan2017.dta" 

***** SECOND DATASET *****
* Dataset 2 Directory
local PMA2020dataset2 "/Users/ealarson/Dropbox (Gates Institute)/12 Kenya/PMAKE_Datasets/Round2/Final_PublicRelease/SDP/PMA2014_KER2_SDP_v1_24Jan2017/PMA2014_KER2_SDP_v1_23Jan2017.dta"

***** THIRD DATASET *****
* Dataset 3 Directory
local PMA2020dataset3 "/Users/ealarson/Dropbox (Gates Institute)/12 Kenya/PMAKE_Datasets/Round3/Final_PublicRelease/SDP/PMA2015_KER3_SDP_v1_24Jan2017/PMA2015_KER3_SDP_v1_23Jan2017.dta"

***** FOURTH DATASET *****
* Dataset 4 Directory
local PMA2020dataset4 "/Users/ealarson/Dropbox (Gates Institute)/12 Kenya/PMAKE_Datasets/Round4/Final_PublicRelease/SDP/PMA2015_KER4_SDP_v1_24Jan2017/PMA2015_KER4_SDP_v1_23Jan2017.dta"

***** FIFTH DATASET *****
* Dataset 5 Directory
local PMA2020dataset5 "/Users/ealarson/Dropbox (Gates Institute)/12 Kenya/PMAKE_Datasets/Round5/Final_PublicRelease/SDP/PMA2016_KER5_SDP_v1_2March2018/PMA2016_KER5_SDP_v1_2Mar2018.dta"

***** SIXTH DATASET *****
* Dataset 6 Directory
local PMA2020dataset6 "/Users/ealarson/Dropbox (Gates Institute)/12 Kenya/PMAKE_Datasets/Round6/Final_PublicRelease/SDP/PMA2017_KER6_SDP_v1_31Aug2018/PMA2017_KER6_SDP_v1_31Aug2018.dta"

***** SEVENTH DATASET *****
* Dataset 7 Directory
local PMA2020dataset7 "/Users/ealarson/Dropbox (Gates Institute)/12 Kenya/PMAKE_Datasets/Round7/Final_PublicRelease/SDP/PMA2018_KER7_SDP_v1_17May2019/PMA2018_KER7_SDP_v1_17May2019.dta"

***********************************************
* PMA DATASETS
***** FIRST DATASET *****
* Dataset 1 Directory
local PMAdataset1 "/Users/ealarson/Dropbox (Gates Institute)/12 Kenya/PMAKE_Datasets/Phase1/Final_PublicRelease/SQ/PMA_KEP1_SQ_Baseline_v1_1Jul2020/PMA_KEP1_SQ_Baseline_v1_1Jul2020.dta"

***** SECOND DATASET *****
* Dataset 2 Directory
local PMAdataset2 ""

***** THIRD DATASET *****
* Dataset 3 Directory
local PMAdataset3 ""


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
*		   local subnational_unit 
*		   local subnational ""
*		 - For example (Subnational estimate for Kenya, Kericho county):
*		   local subnational_yn "yes"
*		   local subnational_unit county
*		   local subnational "KERICHO"
local subnational_yn "no"
local subnational_unit 
local subnational ""
	
**** MACROS FOR DATE	
* Set local/global macros for current date
	local today=c(current_date)
	local c_today= "`today'"
	global date=subinstr("`c_today'", " ", "",.)
	local todaystata=clock("`today'", "DMY")	
	
local level1 `subnational_unit'
local sub_nat `subnational'

*******************************************************************************
* SECTION 4: DATA CHECKS
*
* Section 4 will perform data checks to make sure that the .do file will run 
* 	correclty, please do not move, update or delete
*******************************************************************************
* Set main output directory
cd "`briefdir'"

* Open dataset
use "`PMAdataset1'",clear

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
log using "`briefdir'/PMA_`country'_Phase1_XS_SDP_StockOutTrends_Log_$date.log", replace		

* Set local for xls file
local excel "PMA_`country'_Phase1_XS_SDP_StockOutTrends_$date.xls"

* Set local for dataset
local dataset "PMA_`country'_Phase1_XS_SDP_StockOutTrends_$date.dta"


*******************************************************************************
* SECTION 5: TRENDS IN METHOD USE
*
* Section 5 is necessary to make sure the .do file runs correctly, please do not 
* 	move, update or delete
*******************************************************************************
**********Prepare Excel**********
cd "`briefdir'"
putexcel set "`excel'", replace sheet("Stockout by Sector")
putexcel A1=("Public" )
putexcel I1=("Private")

tokenize A B C D E F H I J K L M N
local methodrow=3
local textrow=`methodrow'+1
local surveyrow=`textrow'+1
local datarow=`surveyrow'+1

foreach method in iud implants injectables pills male_condoms {
	
	***** PMA2020 DATA
	putexcel A`surveyrow'=("PMA2020")
	putexcel I`surveyrow'=("PMA2020")
	forval y = 1/`PMA2020dataset_count' {
		
	use "`PMA2020dataset`y''", clear
		if "`level1'"!="" {
		numlabel, remove force
		decode `level1', gen(str_`level1')
		replace str_`level1' = proper(str_`level1')
		keep if str_`level1' == proper("`sub_nat'")
		}

	* Create a public/private variable
	gen sector=.
	replace sector=0 if managing_authority==1 
	replace sector=1 if managing_authority!=1 & managing_authority!=.
	label define sector_list 0 Public 1 Private
	label val sector sector_list
	
		*In earlier rounds, the stock out questions were not asked
		capture confirm var stock_iud, exact
	if _rc!=0 {
			putexcel ``y''1=("`country' ROUND `y' DOES NOT HAVE STOCKOUT DATA")
			putexcel B`datarow'=("Round `y'")
			putexcel J`datarow'=("Round `y'")
		}
	
	*For rounds with stock out questions	
	else {
	
		*Recode -88 and -99 as missing
		foreach x of varlist stock_* stockout_3mo_*{
			replace `x'=. if `x'<0
			}

		* Keep only completed interviews
		keep if SDP_result==1
		

		*Combine injectable variables, depo and sayana
		capture confirm var stockout_3mo_depo_provera
	if _rc==0 {
		
		*Combine depo & sayana press 
		gen provided_sayanadepo=.
			replace provided_sayanadepo=0 if provided_depo_provera==0 | provided_sayana_press==0
			replace provided_sayanadepo=1 if provided_depo_provera==1 | provided_sayana_press==1
			
		gen provided_injectables = provided_sayanadepo
		}

		
		capture confirm var stock_sayana_press 
		if _rc==0 {
			capture confirm var stock_injectables 
			if _rc==0 {
				rename stock_injectables stock_injectables_orig
				gen stock_injectables=.
				replace stock_injectables=1 if stock_injectables_orig==1 | stock_sayana_press==1
				replace stock_injectables=2 if stock_injectables_orig>=2 & stock_sayana_press>=2
				replace stock_injectables=3 if stock_injectables_orig>=3 & stock_sayana_press>=3
				replace stock_injectables=. if stock_injectables_orig==. & stock_sayana_press==.
				
				rename stockout_3mo_injectables stockout_3mo_injectables_orig
				gen stockout_3mo_injectables=.
				replace stockout_3mo_injectables=0 if stockout_3mo_injectables_orig==0 | stockout_3mo_sayana_press==0
				replace stockout_3mo_injectables=1 if stockout_3mo_injectables_orig>=1 & stockout_3mo_sayana_press>=1
				replace stockout_3mo_injectables=. if stockout_3mo_injectables_orig==. & stockout_3mo_sayana_press==.
				}
			else {
				gen stock_injectables=.
				replace stock_injectables=1 if stock_depo_provera==1 | stock_sayana_press==1
				replace stock_injectables=2 if stock_depo_provera>=2 & stock_sayana_press>=2
			replace stock_injectables=3 if stock_depo_provera>=3 & stock_sayana_press>=3
			replace stock_injectables=. if stock_depo_provera==. & stock_sayana_press==.
			
			gen stockout_3mo_injectables=.
			replace stockout_3mo_injectables=0 if stockout_3mo_depo_provera==0 | stockout_3mo_sayana_press==0
				replace stockout_3mo_injectables=1 if stockout_3mo_depo_provera>=1 & stockout_3mo_sayana_press>=1
				replace stockout_3mo_injectables=. if stockout_3mo_depo_provera==. & stockout_3mo_sayana_press==.
				}
			}
		
		*Combine pill variables, pills and progestin pills
		capture confirm var stock_progestin_pills 
		if _rc==0 {
			rename stock_pills stock_pills_orig
			gen stock_pills=.
			replace stock_pills=1 if stock_pills_orig==1 | stock_progestin_pills==1
			replace stock_pills=2 if stock_pills_orig>=2 & stock_progestin_pills>=2
			replace stock_pills=3 if stock_pills_orig>=3 & stock_progestin_pills>=3
			replace stock_pills=. if stock_pills_orig==. & stock_progestin_pills==.
			
			rename stockout_3mo_pills stockout_3mo_pills_orig
			gen stockout_3mo_pills=.
			replace stockout_3mo_pills=0 if stockout_3mo_pills_orig==0 | stockout_3mo_progestin_pills==0
			replace stockout_3mo_pills=1 if stockout_3mo_pills_orig>=1 & stockout_3mo_progestin_pills>=1
			replace stockout_3mo_pills=. if stockout_3mo_pills_orig==. & stockout_3mo_progestin_pills==.
			}
		
			label define offer_stockout_lab 1 "In stock" 2 "In stock, but stockout last 3 months" 3 "Out of stock" 4 "Don't offer the method"

			capture noisily gen offer_stockout_`method'=.
			capture noisily replace offer_stockout_`method'=4 if fp_offer==1
			capture noisily replace offer_stockout_`method'=1 if fp_offer==1 & provided_`method'==1 & (stock_`method'==1 | stock_`method'==2) /*observed OR unobserved*/
			capture noisily replace offer_stockout_`method'=2 if fp_offer==1 & provided_`method'==1 & (stock_`method'==1 | stock_`method'==2) & stockout_3mo_`method'==1
			capture noisily replace offer_stockout_`method'=3 if fp_offer==1 & provided_`method'==1 & (stock_`method'==3)
			capture noisily replace offer_stockout_`method'=4 if fp_offer==1 & provided_`method'==0 
			capture label var offer_stockout_`method' "4-category availability of `x' among those that offer FP"
			capture label val offer_stockout_`method' offer_stockout_lab
			
			putexcel A`methodrow'=("Stock of `method' in public facilities")
			putexcel A`textrow'=("Survey")
			putexcel B`textrow'=("Round or Phase")
			putexcel C`textrow'=("In Stock")
			putexcel D`textrow'=("In Stock, but stockout in last 3 months")
			putexcel E`textrow'=("Out of Stock")
			putexcel F`textrow'=("Don't offer method")
			putexcel G`textrow'=("N")
			
			putexcel I`methodrow'=("Stock of `method' in private facilities")
			putexcel I`textrow'=("Survey")
			putexcel J`textrow'=("Round or Phase")
			putexcel K`textrow'=("In Stock")
			putexcel L`textrow'=("In Stock, but stockout in last 3 months")
			putexcel M`textrow'=("Out of Stock")
			putexcel N`textrow'=("Don't offer method")
			putexcel O`textrow'=("N")
			
			putexcel B`datarow'=("Round `y'")
			forval r = 1/4 {
				tab offer_stockout_`method' if sector==0 & fp_offer==1 & offer_stockout_`method'==`r', matcell(``r'')
				if r(N)==0 {
					matrix define ``r''=(0)
					}
				else {
					quietly tab offer_stockout_`method' if sector==0 & fp_offer==1
					matrix define ``r''=``r'''/r(N)*100
					}
				}
			matrix define `method'_pub=A,B,C,D
			putexcel C`datarow'=matrix(`method'_pub), nformat(#)
			
			quietly tab offer_stockout_`method' if sector==0 & fp_offer==1
			putexcel G`datarow'=(r(N))

			putexcel J`datarow'=("Round `y'")
			forval r = 8/12 {
				local val=`r'-7
				tab offer_stockout_`method' if sector==1 & fp_offer==1 & offer_stockout_`method'==`val', matcell(``r'')
				if r(N)==0 {
					matrix define ``r''=(0)
					}
				else {
					quietly tab offer_stockout_`method' if sector==1 & fp_offer==1
					matrix define ``r''=``r'''/r(N)*100
					}
				}
			matrix define `method'_priv=I,J,K,L
			putexcel K`datarow'=matrix(`method'_priv), nformat(#)
			
			quietly tab offer_stockout_`method' if sector==1 & fp_offer==1
			putexcel O`datarow'=(r(N))
		
			}
		local datarow=`datarow'+1
		}
		
	local surveyrow=`datarow'
	local datarow=`datarow'+1
	
	***** PMA Data
	putexcel A`surveyrow'=("PMA")
	putexcel I`surveyrow'=("PMA")
	forval y = 1/`PMAdataset_count' {
		
	putexcel B`datarow'=("Phase `y'")
	
	use "`PMAdataset`y''", clear
		if "`level1'"!="" {
		numlabel, remove force
		decode `level1', gen(str_`level1')
		replace str_`level1' = proper(str_`level1')
		replace str_`level1' = proper(str_`level1')
		keep if str_`level1' == proper("`sub_nat'")
		}
		
	keep if SDP_result==1
	
	* Create a public/privat variable
	gen sector=.
	replace sector=0 if managing_authority==1 
	replace sector=1 if managing_authority!=1 & managing_authority!=.
	label values sector sector_lab
	label variable sector "Sector"
	
	capture confirm var provided_injectable_sp 
	if _rc == 0 {
		gen provided_injectables = .
			replace provided_injectables=0 if provided_injectable_sp==0 | provided_injectable_dp==0
			replace provided_injectables=1 if provided_injectable_sp==1 | provided_injectable_dp==1

		gen stock_injectables=.
			replace stock_injectables=1 if stock_injectable_dp==1 | stock_injectable_sp==1
			replace stock_injectables=2 if stock_injectable_dp>=2 & stock_injectable_sp>=2
				replace stock_injectables=3 if stock_injectable_dp>=3 & stock_injectable_sp>=3
				replace stock_injectables=. if stock_injectable_dp==. & stock_injectable_sp==.
				
				gen stockout_3mo_injectables=.
			replace stockout_3mo_injectables=0 if stockout_3mo_injectable_dp==0 | stockout_3mo_injectable_sp==0
			replace stockout_3mo_injectables=1 if stockout_3mo_injectable_dp>=1 & stockout_3mo_injectable_sp>=1
			replace stockout_3mo_injectables=. if stockout_3mo_injectable_dp==. & stockout_3mo_injectable_sp==.


		gen stockout_why_injectables=. 
			replace stockout_why_injectables = 1 if (stockout_why_injectable_dp	== 1| stockout_why_injectable_sp == 1)
			replace stockout_why_injectables = 2 if (stockout_why_injectable_dp	== 2| stockout_why_injectable_sp == 2)
			replace stockout_why_injectables = 3 if (stockout_why_injectable_dp	== 3| stockout_why_injectable_sp == 3)
			replace stockout_why_injectables = 4 if (stockout_why_injectable_dp	== 4| stockout_why_injectable_sp == 4)
			replace stockout_why_injectables = 5 if (stockout_why_injectable_dp	== 5| stockout_why_injectable_sp == 5)
			replace stockout_why_injectables = 96 if (stockout_why_injectable_dp	== 96| stockout_why_injectable_sp == 96) & stockout_why_injectables==.
			label values stockout_why_injectables out_of_stock_reason_list	
		}
			
		label define offer_stockout_lab 1 "In stock" 2 "In stock, but stockout last 3 months" 3 "Out of stock" 4 "Don't offer the method"

		capture noisily gen offer_stockout_`method'=.
		capture noisily replace offer_stockout_`method'=4 if fp_offer==1
		capture noisily replace offer_stockout_`method'=1 if fp_offer==1 & provided_`method'==1 & (stock_`method'==1 | stock_`method'==2) /*observed OR unobserved*/
		capture noisily replace offer_stockout_`method'=2 if fp_offer==1 & provided_`method'==1 & (stock_`method'==1 | stock_`method'==2) & stockout_3mo_`method'==1
		capture noisily replace offer_stockout_`method'=3 if fp_offer==1 & provided_`method'==1 & (stock_`method'==3)
		capture noisily replace offer_stockout_`method'=4 if fp_offer==1 & provided_`method'==0 
		capture label var offer_stockout_`method' "4-category availability of `x' among those that offer FP"
		capture label val offer_stockout_`method' offer_stockout_lab
		
		forval r = 1/4 {
			tab offer_stockout_`method' if sector==0 & fp_offer==1 & offer_stockout_`method'==`r', matcell(``r'')
			if r(N)==0 {
				matrix define ``r''=(0)
				}
			else {
				quietly tab offer_stockout_`method' if sector==0 & fp_offer==1
				matrix define ``r''=``r'''/r(N)*100
				}
			}
		matrix define `method'_pub=A,B,C,D
		putexcel C`datarow'=matrix(`method'_pub), nformat(#)
		
		quietly tab offer_stockout_`method' if sector==0 & fp_offer==1
		putexcel G`datarow'=(r(N))

		putexcel J`datarow'=("Phase `y'")
		forval r = 8/12 {
			local val=`r'-7
			tab offer_stockout_`method' if sector==1 & fp_offer==1 & offer_stockout_`method'==`val', matcell(``r'')
			if r(N)==0 {
				matrix define ``r''=(0)
				}
			else {
				quietly tab offer_stockout_`method' if sector==1 & fp_offer==1
				matrix define ``r''=``r'''/r(N)*100
				}
			}
		matrix define `method'_priv=I,J,K,L
	putexcel K`datarow'=matrix(`method'_priv), nformat(#)
	
	quietly tab offer_stockout_`method' if sector==1 & fp_offer==1, mis
	putexcel O`datarow'=(r(N))
	
	local datarow=`datarow'+1
	
	}
		
	local methodrow=`methodrow'+`PMA2020dataset_count'+`PMAdataset_count'+5
	local textrow=`methodrow'+1
	local surveyrow=`textrow'+1
	local datarow=`surveyrow'+1
	}
log close
