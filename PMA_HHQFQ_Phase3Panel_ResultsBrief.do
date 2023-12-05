/*******************************************************************************
* The following .do file will create the .xls file output that PMA used to 
* 	generate its Phase 3 Panel briefs using PMA's publicly available Household 
*	and Female dataset
*
* This .do file will only work on Phase 1, Phase 2 and Phase 3 HHQFQ panel  
*	datasets. You can  find the .do files to generate the .xls file outputs for  
* 	PMA's publicly available Phase 3 SDP, CQ and COVID19 datasets and other     
*   surveys in the PMA_Analyses_Public repository
*
* If you have any questions on how to use this or any of the other .do files in
* 	the PMA_Analyses_Public repository, please contact the PMA Data Management 
* 	Team at datamanagement@pma2020.org
*******************************************************************************/

/*******************************************************************************
*
*  FILENAME:		PMA_HHQFQ_Phase3Panel_ResultsBrief.do
*  PURPOSE:			Generate the .xls output for the PMA Phase 3 Panel Results Brief
*  CREATED BY: 		Guy Bai (gbai5@jhu.edu)
*  DATA IN:			PMA's Phase3 Panel HHQFQ publicly released datasets
*  DATA OUT: 		PMA_COUNTRY_Phase3_Panel_Analysis_DATE.dta
*  FILE OUT: 		PMA_COUNTRY_Phase3_Panel_Analysis_DATE.xls
*  LOG FILE OUT: 	PMA_COUNTRY_Phase3_Panel_Log_DATE.log
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
*		  local briefdir "~/Desktop/PMA2020/NigeriaAnalysisOutput"
*		- For example (PC): 
*		  local briefdir "~\PMA2020\NigeriaAnalysisOutput"
local briefdir "~/Documents/PMA/PMA_DataManagement/DM_GitKraken/DM_Baltimore/Data_Not_Shared/Analyses_Private_Datadir"

************** DATASETS & DATES *************

***** FIRST DATASET *****
* Dataset 1 Directory
local PMAdataset1 "~/Dropbox (Gates Institute)/BF-Burkina/PMABF_Datasets/Phase1/Final_PublicRelease/HQFQ/Previously released version/PMA2020_BFP1_HQFQ_v2.0_1Oct2021/PMA2020_BFP1_HQFQ_v2.0_1Oct2021.dta"

***** SECOND DATASET *****
* Dataset 2 Directory
local PMAdataset2 "~/Dropbox (Gates Institute)/BF-Burkina/PMABF_Datasets/Phase2/Final_PublicRelease/HQFQ/Previously released versions/PMA2021_BFP2_HQFQ_v1.0_7Oct2021/PMA2021_BFP2_HQFQ_v1.0_1Oct2021.dta"

***** THIRD DATASET *****
* Dataset 3 Directory
local PMAdataset3 "~/Dropbox (Gates Institute)/BF-Burkina/PMABF_Datasets/Phase3/Final_PublicRelease/HQFQ/PMA2022_BFP3_HQFQ_v2.0_12Jul2023/PMA2022_BFP3_HQFQ_v2.0_12Jul2023.dta"

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
global country "Burkina"
local country $country

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
*		- For example (Nigeria): FQweight
*		- For example (Burkina Faso): FQweight
local weight "FQweight"

*	3. The wealth local macro should be the wealth variable that is used for
*		analyzing the data. Generally, it will generally be "wealthq" or, 
*	    however for certain geographies, such as Nigeria, you will need to
*		specify the wealth for the specific geography that you are analyzing.
*		You can identify the correct wealth by searching for variables that  
*		begin with "wealth" in the dataset
*		- For example (Nigeria): wealthquintile
*		- For example (DRC): wealth
*		- For example (Uganda): wealth
*		- For example (Niger): wealth
*		- For example (Kenya): wealth
*		- For example (Burkina Faso): wealth
*		- For example (Côte d'Ivoire): wealth
*		- For example (Rajasthan): wealth
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
local tertiary_education  "(school==4)"

*	5. The level1 macro corresponds to the highest geographical level in the
*	    the dataset. This is likely county, state, region, or province
*		- For example (Nigeria): state
*		- For example (DRC): province
*		- For example (Uganda): county
*		- For example (Niger): region
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
forvalues i=1/3 {
	
	use "`PMAdataset`i''", clear
	
	*	Country Variable
		local country $country	
		gen countrycheck="$country"
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
			gen check=(state==subnational)
			keep if check==1
			encode state, gen(state_num)
			capture quietly regress check state_num
				if _rc==2000 {
					di in smcl as error "The specified sub-national level is not correct. Please search for the sub-national variable in the dataset to identify the correct spelling of the sub-national level, update the local and rerun the .do file"
					exit
					}
			local country `country'_`subnational'
			drop subnational check
			}	
			
	*	Countries without national analysis
		if (country=="DRC" | country=="Nigeria") & subnational_yn!="yes" {
			di in smcl as error "Please specify a sub-national level for this country as national analysis is not available. Please search for the sub-national variable in the dataset to identify the correct spelling of the sub-national level, update the local and rerun the .do file"
			exit
			}

	tempfile Phase`i'
	save "`Phase`i''", replace
}
		
* Start log file
log using "`briefdir'/PMA_`country'_Phase3_Panel_Analysis_`date'.log", replace		

* Set local for xls file
local tabout "PMA_`country'_Phase3_Panel_Analysis_`date'.xls"

* Set local for dataset
local dataset "PMA_`country'_Phase3_Panel_Analysis_`date'.dta"

*******************************************************************************
* SECTION 4: GENERATE NECESSARY VARIABLES AND SET UP DATA FOR ANALYSIS
*
* Section 6 is necessary to make sure the .do file runs correctly, please do not 
*	move, update or delete
*******************************************************************************

forvalues x=1/3	{

	* OPEN PHASE 1, 2, or 3 DATASET HERE 
	use "`Phase`x''", clear

	****************************************	
	* MARITAL STATUS
	****************************************
	* Generate dichotomous "married" variable to represent all women married or currently living with a man
	gen married=(FQmarital_status==1 | FQmarital_status==2)
	label define married_list 0 "Single,Divorced,Widowed or Seperated" 1 "In-Union", replace
	label values married married_list
	label variable married "Marital Status"
		
	****************************************	
	* URBAN/RURAL VARIABLE
	****************************************
	* Create urban/rural variable if there is an urban/rural breakdown of the data
	capture confirm var ur 
	if _rc==0 {
		gen urban=ur==1
		label variable urban "Urban/rural place of residence"
		label define urban 1 "Urban" 0 "Rural"
		label value urban urban
		}
	else {
		gen urban=1
		label variable urban "No urban/rural breakdown"
		}

	****************************************
	* AGE
	****************************************
	recode FQ_age -99=. -88=. -77=.
	egen age5=cut(FQ_age) , at (15(5)50)
	recode age5 (15=0) (20=1) (25 30 35 40 45=2) 
	label define age5_lab 0 "15-19" 1 "20-24" 2 "25-49"
	label values age5 age5_lab
	label var age5 "Age Categories"
	
	****************************************
	* EDUCATION
	****************************************
	cap rename school_cc school

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
	* PARITY
	****************************************		
	* Create categorical parity variable
	replace birth_events=. if birth_events ==-88 | birth_events ==-99 
	egen parity=cut(birth_events), at (0, 1, 3, 5) icodes 
	label define paritylist 0 "None" 1 "One-Two" 2 "Three-Four" 3 "Five+" 
	replace parity=3 if birth_events>=5 & birth_events!=. 
	replace parity=0 if birth_events==. 
	label val parity paritylist 

	****************************************
	* INTENTION TO USE
	****************************************
	* Create intention to use variable
	gen intention_use = 0 
	replace intention_use=1 if fp_start==1 | fp_start==3 | (fp_start==2 & fp_start_value<=1)
	label values intention_use yes_no_dnk_nr_list
	label var intention_use "Intention to use contraception in the future/in the next year"

			
	* Recode all "-99" as "0" to represent missing. For analytical purposes only, PMA recodes -99 values to 0
	foreach var in partner_support school partner_know partner_decision why_not_decision partner_overall {
		recode `var' -99=. 
		}

	if `x'==1 {
		
		* Only Keep Phase 1 Variables Required for Analysis
		keep FQmetainstanceID age5 education `wealth' married ///
			partner_support FRS_result eligible last_night HHQ_result cp ///
			current_methodnum_rc pregnant country FQ_age flw_willing unmettot ///
			intention_use urban parity female_ID
		
		* Identify sample enrolled for panel at P1 for P2 
		gen new_panel_eligible=0 if female_ID != ""
		replace new_panel_eligible=1 if FQ_age<=48 & flw_willing==1 
		label var new_panel_eligible "Phase `x' population enrolled for P2 panel"
		label val new_panel_eligible yes_no_list	
	}
	
	
	if `x'==2 {
		
		* Only Keep Phase 2 Variables Required for Analysis	
		keep FQmetainstanceID age5 education `wealth' married /// 
			partner_support FRS_result eligible last_night HHQ_result cp /// 
			current_methodnum_rc pregnant country FQ_age flw_willing unmettot ///
			intention_use urban parity panel_woman xs_sample newly_enrolled female_ID P2FUweight
			
		*Identify sample enrolled for panel at P2 for P3 
		gen new_panel_eligible=0 if female_ID != ""
		replace new_panel_eligible=1 if FQ_age<=48 & xs_sample==1 & newly_enrolled==1 & flw_willing==1
		label var new_panel_eligible "Phase `x' population enrolled for P3 panel"
		label val new_panel_eligible yes_no_list	
	}
	
	if `x'==3 {
			
		capture confirm var unmettot, exact
		if _rc!=0 {
			gen unmettot = 1
			} 	
		
		capture confirm var P1P2P3_FUweight, exact
		if _rc!=0 {
			gen P1P2P3_FUweight = 1 if FRS_result==1 & last_night==1
			}
			
		capture confirm var P2P3_FUweight, exact
		if _rc!=0 {
			gen P2P3_FUweight = 1 if FRS_result==1 & last_night==1
			}	
			
		keep FQmetainstanceID age5 education `wealth' married ///
			partner_support FRS_result eligible last_night HHQ_result cp ///
			current_methodnum_rc pregnant country FQ_age FQflw_willing unmettot ///
			intention_use urban parity  panel_woman xs_sample newly_enrolled female_ID ///
			P1P2P3_FUweight P2P3_FUweight		 
	}

save "PMA_`country'_Phase`x'_Panel_Analysis_`date'.dta", replace

}

*******************************************************************************
* SECTION X: PREPARE AND MERGE DATASETS FOR PHASE 3 PANEL ANALYSIS
*******************************************************************************
* Xa. Prepare Phase 1, 2 and 3 datasets before merging 

* Phase 1	
	use "PMA_`country'_Phase1_Panel_Analysis_`date'.dta", clear
	
	* Only keep eligible women in Phase 1 dataset
	keep if female_ID != ""
	keep if FQ_age<49
	
	* Rename Phase 1 required variables 
	rename * *_P1
	rename female_ID_P1 female_ID
	
	* Drop not eligible women
	drop if new_panel_eligible!=1
	tempfile `country'_Phase1
	save ``country'_Phase1'.dta, replace

* Phase 2
	use "PMA_`country'_Phase2_Panel_Analysis_`date'.dta", clear
	keep if (new_panel_eligible==1 | female_ID != "")
	cap rename FRS_result_cc FRS_result
	rename * *_P2
	rename female_ID_P2 female_ID
	replace female_ID=FQmetainstanceID if female_ID==""
	tempfile `country'_Phase2
	save ``country'_Phase2'.dta, replace

* Phase 3	
	use "PMA_`country'_Phase3_Panel_Analysis_`date'.dta", clear
	cap rename FRS_result_cc FRS_result
	rename * *_P3
	rename female_ID_P3 female_ID
	replace female_ID=FQmetainstanceID if female_ID==""
	keep if female_ID != ""
	sort FRS_result_P3
	duplicates drop female_ID, force
	tempfile `country'_Phase3
	save ``country'_Phase3'.dta, replace

* Xb. Merge P1 data with P2 data 

use ``country'_Phase1'.dta, clear
merge 1:1 female_ID using "``country'_Phase2'.dta", gen(P1P2_merge)

* Label variable P1P2_merge
label define P1P2_merge_lab 1 "P1 Panel Women LTFU at P2" 2 "XS Women at P2"  3 "P1 Panel Women Found at P2"
label values P1P2_merge P1P2_merge_lab

* Capture newly enrolled panel women at Phase 2, including women who were de facto at Phase 2 but not at Phase 1
replace new_panel_eligible_P2=1 if P1P2_merge==2 & newly_enrolled_P2==. & FQ_age_P2<=48 & flw_willing_P2==1

tempfile P1P2_Merged
save `P1P2_Merged'.dta, replace

* Xc. Merge P1/P2 data with P3 data 
merge 1:1 female_ID using "``country'_Phase3'.dta" , gen(P1P2P3_merge)

* Label variable P1P2P3_merge
label define P1P2P3_merge_lab 1 "Panel Women Not found at P3" 2 "XS Women at P3" 3 "Women Found P1/P3 or P2/P3 or P1/P2/P3"
label values P1P2P3_merge P1P2P3_merge_lab

*******************************************************************************
* Summary Tables Calculation

* This section will generate summary table calculation we have in the last page 
* of in Panel Brief
*******************************************************************************

**********************************************
* 1.a. Enrolled at Phase 1
**********************************************
	gen none=.
	tabout none using `tabout', replace ptotal(none) h3("SUMMARY TABLE")

	** Women who were enrolled at P1 #P1Enrolled
	tabout new_panel_eligible_P1 if new_panel_eligible_P1==1 ///
	using `tabout', append cells(freq) f(0) clab(n) ptotal(none) ///
	h2("ENROLLED AT PHASE 1") ///
	h3("Women enrolled at Phase 1")

	** Among the Women who were enrolled at P1, how many completed survey #P1Enrolled_CompletedP1
	tabout new_panel_eligible_P1 if new_panel_eligible_P1==1 & FRS_result_P1==1 & last_night_P1==1 ///
	using `tabout', append cells(freq) f(0) clab(n) ptotal(none) ///
	h2("Women enrolled at Phase 1 who Completed Phase 1") h3(nil)

	** Woman first interviewed at P1 and successfully followed up at P2 #P1Enrolled_CompletedP2
	tabout P1P2_merge if P1P2_merge==3 & FRS_result_P2==1 & last_night_P2==1 ///
	using `tabout', append cells(freq) f(0) clab(n) ptotal(none) ///
	h2("Women enrolled at Phase 1 first who Completed Phase 2") h3(nil)
	
	* Women First Enrolled at P1 who completed P3 survey #P1Enrolled_CompletedP3
	tabout P1P2P3_merge if new_panel_eligible_P1==1 & FRS_result_P3==1 & last_night_P3==1 ///
	using `tabout', append cells(freq) f(0) clab(n) ptotal(none) ///
	h2("Women enrolled at Phase 1 who Completed Phase 3") h3(nil)
	
	* Women First Enrolled at P1 who completed P2 & P3 surveys #P1Enrolled_CompletedP2P3
	tabout P1P2P3_merge if new_panel_eligible_P1==1 & FRS_result_P2==1 & FRS_result_P3==1 & last_night_P2==1 & last_night_P3==1 ///
	using `tabout', append cells(freq) f(0) clab(n) ptotal(none) ///
	h2("Women enrolled at Phase 1 who Completed both Phase 2 and Phase 3") h3(nil)

	* Women First Enrolled at P1 who completed P1 & P2 & P3 surveys #P1Enrolled_CompletedP1P2P3
	tabout P1P2P3_merge if new_panel_eligible_P1==1 & FRS_result_P1==1 & FRS_result_P2==1 & FRS_result_P3==1 & last_night_P1==1 & last_night_P2==1 & last_night_P3==1 ///
	using `tabout', append cells(freq) f(0) clab(n) ptotal(none) ///
	h2("Women enrolled at Phase 1 who Completed Phase 1, Phase 2 and Phase 3") h3(nil)	

**********************************************	
* 1.b. Enrolled at Phase 2
**********************************************
	
	** Women who were enrolled at P2 #P2Enrolled
	tabout new_panel_eligible_P2 if new_panel_eligible_P2==1  ///
	using `tabout', append cells(freq) f(0) clab(n) ptotal(none) ///
	h2("ENROLLED AT PHASE 2") ///
	h3("Women enrolled at Phase 2")
	
	** Among the Women who were enrolled at P2, how many completed survey #P2Enrolled_CompletedP2
	tabout new_panel_eligible_P2 if new_panel_eligible_P2==1 & FRS_result_P2==1 & last_night_P2==1 ///
	using `tabout', append cells(freq) f(0) clab(n) ptotal(none)  ///
	h2("Women enrolled at Phase 2 who Completed Phase 2") h3(nil)

	* Women First Enrolled at P2 who completed P3 survey #P2Enrolled_CompletedP3
	tabout P1P2P3_merge if new_panel_eligible_P2==1 & FRS_result_P2==1 & FRS_result_P3==1 & last_night_P3==1 ///
	using `tabout', append cells(freq) f(0) clab(n) ptotal(none) ///
	h2("Women first enrolled at Phase 2 who Completed Phase 3") h3(nil)
	
	* Women First Enrolled at P2 who completed P2 & P3 survey #P2Enrolled_CompletedP2P3
	tabout P1P2P3_merge if new_panel_eligible_P2==1 & FRS_result_P2==1 & FRS_result_P3==1 & last_night_P2==1 & last_night_P3==1 ///
	using `tabout', append cells(freq) f(0) clab(n) ptotal(none) ///
	h2("Women first enrolled at Phase 2 who Completed Phase 2 and Phase 3") h3(nil)

**********************************************	
* 1.c. Total Women Calculations
**********************************************

	** Total number of panel women enrolled #TotalPanelWomen_Enrolled (P1Enrolled + P2Enrolled)
	gen totalpanel_eligible=0
	replace totalpanel_eligible=1 if new_panel_eligible_P1==1 | new_panel_eligible_P2==1
	tabout totalpanel_eligible if totalpanel_eligible==1 ///
	using `tabout' , append cells(freq) f(0) clab(n) ptotal(none) ///
	h2("TOTAL PANEL WOMEN") ///
	h3("Total panel women enrolled at Phase 1 and Phase 2")

	** Total number of panel women who completed P1 #TotalPanelWomen_CompletedP1
	gen TotalPanelWomen_CompletedP1=0
	replace TotalPanelWomen_CompletedP1=1 if (inlist(P1P2_merge, 1, 3) & FRS_result_P1==1 & last_night_P1==1)
	tabout TotalPanelWomen_CompletedP1 if TotalPanelWomen_CompletedP1==1 ///
	using `tabout' , append cells(freq) f(0) clab(n) ptotal(none) ///
	h2("Total panel women enrolled who completed Phase 1") h3(nil) 
	
	** Total number of panel women who completed P2 #TotalPanelWomen_CompletedP2
	gen TotalPanelWomen_CompletedP2=0
	replace TotalPanelWomen_CompletedP2=1 if (P1P2_merge==3 & FRS_result_P2==1 & last_night_P2==1) | (new_panel_eligible_P2==1 & FRS_result_P2==1 & last_night_P2==1)
	tabout TotalPanelWomen_CompletedP2 if TotalPanelWomen_CompletedP2==1 ///
	using `tabout' , append cells(freq) f(0) clab(n) ptotal(none) ///
	h2("Total panel women who completed Phase 2") h3(nil)

	* Total number of women who completed P3 survey #TotalPanelWomen_CompletedP3
	gen TotalPanelWomen_CompletedP3=0
	replace TotalPanelWomen_CompletedP3=1 if (new_panel_eligible_P2==1 & FRS_result_P3==1 & last_night_P3==1) | (new_panel_eligible_P1==1 & FRS_result_P3==1 & last_night_P3==1) 
	tabout TotalPanelWomen_CompletedP3 if TotalPanelWomen_CompletedP3==1 ///
	using `tabout' , append cells(freq) f(0) clab(n) ptotal(none) ///
	h2("Total panel women who completed Phase 3") h3(nil)
	
	* Total number of women who completed P2 and P3 surveys
	gen TotalPanelWomen_CompletedP2P3=0
	replace TotalPanelWomen_CompletedP2P3=1 if P1P2P3_merge==3 & last_night_P2==1 & last_night_P3==1 & FRS_result_P2==1 & FRS_result_P3==1 
	tabout TotalPanelWomen_CompletedP2P3 if TotalPanelWomen_CompletedP2P3==1 ///
	using `tabout' , append cells(freq) f(0) clab(n) ptotal(none) ///
	h2("Total panel women who completed Phase 2 and Phase 3") h3(nil)

	* Total number of women who completed P1, P2 and P3 surveys
	tabout P1P2P3_merge if new_panel_eligible_P1==1 & FRS_result_P1==1 & FRS_result_P2==1 & FRS_result_P3==1 & last_night_P1==1 & last_night_P2==1 & last_night_P3==1 ///
	using `tabout', append cells(freq) f(0) clab(n) ptotal(none) ///
	h2("Total panel women who Completed Phase 1, Phase 2 and Phase 3") h3(nil)	
	
	
*******************************************************************************
* SECTION 5: RESPONSE RATES
*
* Section 5 will generate household and female survey response rates. To
* 	generate the correct response rates, please do not move, update or delete
*******************************************************************************
drop if P1P2P3_merge==2

* Tabout Response Rate Among All Panel Eligible Women  
tabout FRS_result_P3 ///
	using `tabout', append cells(freq col) f(0 1) clab(n %) ///
	h2("FQ Result, among panel eligible women")

* Keep only merged observations of de facto women
keep if P1P2P3_merge==3 
keep if (last_night_P1==1 | last_night_P2==1 | last_night_P3==1)
drop P1P2P3_merge

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
		replace phase2_cp_group=0 if pregnant_P2==1
		replace phase2_cp_group=1 if cp_P2==0 & pregnant_P2!=1
		replace phase2_cp_group=2 if cp_P2==1 
		label define cp_grouped_label2 0 "Phase 2 Pregnant" 1 "Phase 2 Not using FP" 2 "Phase 2 Using FP"
		label val phase2_cp_group cp_grouped_label2
		label var phase2_cp_group "Contraceptive use status from Phase 2"
		
	** Phase 1 Change in Contraceptive Use
	gen phase1_cp_group=.
		replace phase1_cp_group=0 if pregnant_P1==1
		replace phase1_cp_group=1 if cp_P1==0 & pregnant_P1!=1
		replace phase1_cp_group=2 if cp_P1==1
		label define cp_grouped_label1 0 "Phase 1 Pregnant" 1 "Phase 1 Not using FP" 2 "Phase 1 Using FP"
		label val phase1_cp_group cp_grouped_label1
		label var phase1_cp_group "Contraceptive use status from Phase 1 Survey"
		
	** Phase 3 Change in Contraceptive Usex
	gen phase3_cp_group=.
		replace phase3_cp_group=0 if pregnant_P3==1
		replace phase3_cp_group=1 if cp_P3==0 & pregnant_P3!=1
		replace phase3_cp_group=2 if cp_P3==1
		label define cp_grouped_label3 0 "Phase 3 Pregnant" 1 "Phase 3 Not using FP" 2 "Phase 3 Using FP"
		label val phase3_cp_group cp_grouped_label3
		label var phase3_cp_group "Contraceptive use status from Phase 3 Survey"
		
	preserve
	keep if phase3_cp_group != . & phase2_cp_group	!=. & phase1_cp_group !=.
	keep if last_night_P1==1 & last_night_P2==1 & last_night_P3==1
	tempfile Sankey1
	save `Sankey1', replace
	restore
		
	* Change in Method Use Sankey
	** Phase 3 Change in Method Use
	gen phase3_method_group=.
		replace phase3_method_group=0 if cp_P3==0 
		replace phase3_method_group=1 if cp_P3==1 & current_methodnum_rc_P3>=30 
		replace phase3_method_group=2 if cp_P3==1 & current_methodnum_rc_P3>=5 & current_methodnum_rc_P3<30 
		replace phase3_method_group=3 if cp_P3==1 & current_methodnum_rc_P3>=1 & current_methodnum_rc_P3<5 
		label define method_grouped_label3 0 "Phase 3 No use" 1 "Phase 3 Traditional" 2 "Phase 3 Short Acting" 3 "Phase 3 Long Acting"
		label val phase3_method_group method_grouped_label3
		label var phase3_method_group "Method use status from Phase 3 Survey"	
			
		
	* Change in Method Use Sankey
	** Phase 2 Change in Method Use
	gen phase2_method_group=.
		replace phase2_method_group=0 if cp_P2==0 
		replace phase2_method_group=1 if cp_P2==1 & current_methodnum_rc_P2>=30 
		replace phase2_method_group=2 if cp_P2==1 & current_methodnum_rc_P2>=5 & current_methodnum_rc_P2<30 
		replace phase2_method_group=3 if cp_P2==1 & current_methodnum_rc_P2>=1 & current_methodnum_rc_P2<5 
		label define method_grouped_label2 0 "Phase 2 No use" 1 "Phase 2 Traditional" 2 "Phase 2 Short Acting" 3 "Phase 2 Long Acting"
		label val phase2_method_group method_grouped_label2
		label var phase2_method_group "Method use status from Phase 2 Survey"
		
	** Phase 1 Change in Method Use
	gen phase1_method_group=.
		replace phase1_method_group=0 if cp_P1==0 
		replace phase1_method_group=1 if cp_P1==1 & current_methodnum_rc_P1>=30 
		replace phase1_method_group=2 if cp_P1==1 & current_methodnum_rc_P1>=5 & current_methodnum_rc_P1<30 
		replace phase1_method_group=3 if cp_P1==1 & current_methodnum_rc_P1>=1 & current_methodnum_rc_P1<5 
		label define method_grouped_label1 0 "Phase 1 No use" 1 "Phase 1 Traditional" 2 "Phase 1 Short Acting" 3 "Phase 1 Long Acting"
		label val phase1_method_group method_grouped_label1
		label var phase1_method_group "Method use status from Phase 1 Survey"


	preserve
	keep if phase3_method_group != . & phase2_method_group	!=. & phase1_method_group !=.
	keep if last_night_P1==1 & last_night_P2==1 & last_night_P3==1
	tempfile Sankey2
	save `Sankey2', replace
	restore
		
							
	**Continuers
	gen continuers=0
		replace continuers=1 if (cp_P3==1 & cp_P2==1) & (current_methodnum_rc_P3==current_methodnum_rc_P2)
		label var continuers "Women using the same method at P3 as P2"
		label val continuers yes_no_list
		
	**Discontinuers
	gen discontinuers=0
		replace discontinuers=1 if cp_P3==0 & cp_P2==1 
		label var discontinuers "Women who used a method at P2 but are no longer using a method/pregnant at P3"
		label val discontinuers yes_no_list
		
	**Adopters
	gen adopters=0
		replace adopters=1 if cp_P3==1 & cp_P2==0 
		label var adopters "Women who were not using a method/pregnant at P2 but are using at P3"
		label val adopters yes_no_list	
		
	**Non-Adopters
	gen non_adopters=0
		replace non_adopters=1 if cp_P3==0 & cp_P2==0 
		label var non_adopters "Women who were not using a method/pregnant at P2 and are not using at P3"
		label val non_adopters yes_no_list		
		
	**Switchers
	gen switchers=0
		replace switchers=1 if (cp_P3==1 & cp_P2==1) & (current_methodnum_rc_P3!=current_methodnum_rc_P2) 
		label var switchers "Women who switched methods between P2 and P3"
		label val switchers yes_no_list	
		
	**Categorical Variable 
	gen contraceptive_dynamics=1 if continuers==1
		replace contraceptive_dynamics=2 if discontinuers==1
		replace contraceptive_dynamics=3 if adopters==1
		replace contraceptive_dynamics=4 if non_adopters==1
		replace contraceptive_dynamics=5 if switchers==1
		label var contraceptive_dynamics "Women's contraceptive use between Phase 2 and Phase 3"
		label define c_dynamics_list 1 "Continued using the same method" 2 "Stopped using a method" 3 "Started using a method" 4 "Continued non-use" 5 "Changed methods" 
		label val contraceptive_dynamics c_dynamics_list

	**Detailed discontinuation
	gen stopped_use=0
		replace stopped_use=1 if discontinuers==1
		replace stopped_use=2 if discontinuers==1 & pregnant_P3==1
		label var stopped_use "Women who stopped using a method or got pregnant between P2 and P3"
		label define stopped_use_list 0 "Continued non-use" 1 "Stopped using a method" 2 "Became pregnant" 
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
preserve
*Only among women in the Sankey Charts
keep if FRS_result_P1==1 & FRS_result_P2==1 & FRS_result_P3==1 & last_night_P1==1 & last_night_P2==1 & last_night_P3==1

*******************************************************************************
* Change in Contraceptive Use or Non-Use
*******************************************************************************

* Percent of respondents who changed contraceptive use status
* 	among all women 

** Tabout
tabout phase1_cp_group phase2_cp_group [aw=P1P2P3_FUweight] ///
	using `tabout', append c(freq) f(0) clab(n) ///
		h1("Women who changed their contraceptive use status between Phase 1 (Row) and Phase 2 (Column) - Weighted")
		
tabout phase2_cp_group phase3_cp_group [aw=P1P2P3_FUweight] ///
	using `tabout', append c(freq) f(0) clab(n) ///
		h1("Women who changed their contraceptive use status between Phase 2 (Row) and Phase 3 (Column) - Weighted")
		
	
*******************************************************************************
* Change in Contraceptive Method Type
*******************************************************************************

* Percent of respondents who changed method type status
*	among all respondents

** Tabout
tabout phase1_method_group phase2_method_group [aw=P1P2P3_FUweight] ///
	using `tabout', append c(freq) f(0) clab(n) ///
	h1("Women who changed their method type status between Phase 1 (Row) and Phase 2 (Column) - Weighted")

tabout phase2_method_group phase3_method_group [aw=P1P2P3_FUweight] ///
	using `tabout', append c(freq) f(0) clab(n) ///
	h1("Women who changed their method type status between Phase 1 (Row) and Phase 3 (Column) - Weighted")


*******************************************************************************
* Change in Contraceptive Use or Non-Use (Percentages)
*******************************************************************************
		
** Percentages
tabout phase1_cp_group if phase2_cp_group!=. & phase3_cp_group !=. [aw=P1P2P3_FUweight] ///
	using `tabout', append oneway c(freq col) f(0 1) clab(n %) ///
	h2("Contraceptive use status (Phase 1) - Weighted")

tabout phase2_cp_group if phase1_cp_group!=. & phase3_cp_group !=. [aw=P1P2P3_FUweight] ///
	using `tabout', append oneway c(freq col) f(0 1) clab(n %) ///
	h2("Contraceptive use status (Phase 2) - Weighted")	

tabout phase3_cp_group if phase1_cp_group!=. & phase2_cp_group !=. [aw=P1P2P3_FUweight] ///
	using `tabout', append oneway c(freq col) f(0 1) clab(n %) ///
	h2("Contraceptive use status (Phase 3) - Weighted")	

	
*******************************************************************************
* Change in Contraceptive Method Type (Percentages)
*******************************************************************************
	
** Percentages
tabout phase1_method_group if phase2_method_group!=. & phase3_method_group !=. [aw=P1P2P3_FUweight] ///
	using `tabout', append oneway c(freq col) f(0 1) clab(n %) ///
	h2("Method type status (Phase 1) - Weighted")

tabout phase2_method_group if phase1_method_group!=. & phase3_method_group !=. [aw=P1P2P3_FUweight] ///
	using `tabout', append oneway c(freq col) f(0 1) clab(n %) ///
	h2("Method type status (Phase 2) - Weighted")

tabout phase3_method_group if phase1_method_group!=. & phase2_method_group !=. [aw=P1P2P3_FUweight] ///
	using `tabout', append oneway c(freq col) f(0 1) clab(n %) ///
	h2("Method type status (Phase 3) - Weighted")	

restore	

*******************************************************************************
*
* SECTION 2: CONTRACEPTIVE DYNAMICS BY KEY MEASURES
*
*******************************************************************************
preserve
*Only among women who completed P3 and P2
keep if FRS_result_P2==1 & FRS_result_P3==1 & last_night_P2==1 & last_night_P3==1

*******************************************************************************
* Contraceptive Dynamics
*******************************************************************************

* Change in contraceptive use status, by age
*	among all respondents
tabout contraceptive_dynamics age5_P2 [aw=P2P3_FUweight_P3] ///
	using `tabout', append	c(col) f(1) clab(%) npos(row) ///
	h1("Percent of women age 15-49 who engaged in one of the following contraceptive use behaviors between PMA Phase 2 and PMA Phase 3, by age at P2")

* Change in contraceptive use status, by education level
*	among all respondents	
tabout contraceptive_dynamics education_P2 [aw=P2P3_FUweight_P3] ///
	using `tabout', append	c(col) f(1) clab(%) npos(row) ///
	h1("Percent of women age 15-49 who engaged in one of the following contraceptive use behaviors between PMA Phase 2 and PMA Phase 3, by education level at P2")

* Change in contraceptive use status, by marital status
*	among all respondents	
tabout contraceptive_dynamics married_P2 [aw=P2P3_FUweight_P3] ///
	using `tabout', append	c(col) f(1) clab(%) npos(row) ///
	h1("Percent of women age 15-49 who engaged in one of the following contraceptive use behaviors between PMA Phase 2 and PMA Phase 3, by marital status at P2")

* Change in contraceptive use status, by parity
*	among all respondents	
tabout contraceptive_dynamics parity_P2 [aw=P2P3_FUweight_P3] ///
	using `tabout', append	c(col) f(1) clab(%) npos(row) ///
	h1("Percent of women age 15-49 who engaged in one of the following contraceptive use behaviors between PMA Phase 2 and PMA Phase 3, by parity level at P2")
	
*******************************************************************************
*
* SECTION 3: OTHER PANEL DYNAMICS
*
*******************************************************************************

*******************************************************************************
* Other Dynamics 
*******************************************************************************
*Contraceptive discontinuation
	tabout stopped_use if unmettot_P3==1 [aw=P2P3_FUweight] ///
		using `tabout', append	c(col) f(1) clab(%) npos(row)  ///
		h2("Among women 15-49 with unmet need at Phase 3, the percentage that stopped using a contraceptive method or became pregnant since Phase 2 (Weighted)")
		

*Prediction of uptake
rename partner_supportive*P1 partner_support_P1

foreach strat in partner_supportive_P2 intention_use_P2 unmettot_P2 {
	tabout adopters `strat' if cp_P2==0 [aw=P2P3_FUweight] ///
		using `tabout', append	c(col) f(1) clab(%) npos(row)  ///
		h1("Percent of women age 15-49 who were not using an FP method at Phase 2 and who adopted an FP method between Phase 2 and Phase 3, by their ``strat'_lab' at Phase 2")
	}

restore

log close
