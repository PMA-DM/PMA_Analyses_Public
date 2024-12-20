/*******************************************************************************
* The following .do file will create the .xls file output that PMA used to 
* 	generate the Phase 4 cross sectional results briefs using PMA's publicly  
* 	available Household and Female dataset
*
* This .do file will only work on Phase 4 HHQFQ cross sectional datasets. You 
*   can  find the .do files to generate the .xls file outputs for PMA's publicly
* 	available Phase 4 SDP, CQ and Panel datasets and other surveys in the  
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
*  FILENAME:		PMA_HHQFQ_PHASE4XS_ResultsBrief.do
*  PURPOSE:			Generate the .xls output for the PMA Phase 4 XS Results Brief
*  CREATED BY: 		Claire Silberg (csilber4@jhu.edu)
*  DATA IN:			PMA's PHASE4 XS HHQFQ publicly released dataset
*  DATA OUT: 		PMA_COUNTRY_PHASE4_XS_HHQFQ_Analysis_DATE.dta
*  FILE OUT: 		PMA_COUNTRY_PHASE4_XS_HHQFQ_Analysis_DATE.xls
*  LOG FILE OUT: 	PMA_COUNTRY_PHASE4_XS_HHQFQ_Log_DATE.log
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

*	1. A directory for the publicly available PMA dataset on your computer
*		- For example (Mac): 
*		  local datadir "~/Desktop/PMA2020/PMA2018_NGR5_National_HHQFQ_v5_4Nov2019"
*		- For example (PC):
* 		  local datadir "~\PMA2020\PMA2018_NGR5_National_HHQFQ_v5_4Nov2019.dta"

local datadir "~/Dropbox (Gates Institute)/BF-Burkina/PMABF_Datasets/PHASE4/Final_PublicRelease/HQFQ/PMA2022_BFP3_HQFQ_v2.0_12Jul2023/PMA2022_BFP3_HQFQ_v2.0_12Jul2023.dta"


*	2. A directory for the folder where you want to save the dataset, xls and
*		log files that this .do file creates
*		- For example (Mac): 
*		  local briefdir "~/Desktop/PMA2020/NigeriaAnalysisOutput"
*		- For example (PC): 
*		  local briefdir "~\PMA2020\NigeriaAnalysisOutput"
local briefdir "~/Documents/PMA/PMA_DataManagement/DM_GitKraken/DM_Baltimore/Data_Not_Shared/Analyses_Private_Datadir"


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
*		analyzing the data. Generally, all Phase 4 data contains both 
*		wealthquintile or wealthtertile variables. You may choose which one to use.
*	    For certain geographies, such as Nigeria, you will need to
*		specify the wealth for the specific geography that you are analyzing.
*		You can identify the correct wealth by searching for variables that  
*		begin with "wealth" in the dataset
*		- For example (Nigeria): wealthtertile
*		- For example (Kenya): wealthquintile_Kilifi
*		- For example (Burkina Faso): wealthquintile
local wealth "wealthtertile"

*	4. The education macros correspond to the coding of the school variable for
*	    each designated education level. In the briefs, PMA codes education as: 
*	    1) None or primary education; 2) Secondary; or 3) Tertiary. In the
*	    public release dataset, the school variable is labeled to facilitate 
*	    the identification of the levels. There is not check for these locals in
*	 	this .do file, therefore, if indicators that are disaggregated by
*		education do not match the PMA brief output, please check that you coded
*		the macros correctly

local none_primary_education "(school==0| school==1)"
local secondary_education "(school==2 | school==3)"
local tertiary_education  "(school==4)"

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
cap destring phase, replace

* Confirm that it is Phase 4 data
if country=="Burkina" {
	gen check=(phase==4)
	}
else if country=="DRC" {
	gen check=(phase==4)
	}
else if country=="Nigeria" {
	gen check=(phase==4)
	}	
else if country=="Uganda" {
	gen check=(phase==4)
	}	
else if country=="Cotedivoire" {
	gen check=(phase==4)
	}
else if country=="Niger" {
	gen check=(phase==4)
	}	
	
if check!=1 {
	di in smcl as error "The dataset you are using is not a PMA Phase 4 XS dataset. This .do file is to generate the .xls files for PMA Phase 4 XS surveys only. Please use a PMA Phase 4 XS survey and rerun the .do file"
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
		capture confirm string var $level1_var
		if _rc==0 {
			gen check=(state==subnational)
			keep if check==1
		}
		else {
			decode state, gen(state_string)
			gen subnational_keep=substr(state_string,4,.)
			gen subnational_keep1=subinstr(subnational_keep," ","",.)
			gen check=(subnational_keep1==subnational)
			keep if check==1
			capture quietly regress check state
		}

		if _rc==2000 {
			di in smcl as error "The specified sub-national level is not correct. Please search for the sub-national variable in the dataset to identify the correct spelling of the sub-national level, update the local and rerun the .do file"
			exit
			}
		local country `country'_`subnational'
		
		capture confirm string var $level1_var
		if _rc==0 {
			drop subnational check
		}
		else {
			drop subnational state_string subnational_keep subnational_keep1 check			
		}
	}	

*	Countries without national analysis
	if (country=="DRC" | country=="Nigeria") & subnational_yn!="yes" {
		di in smcl as error "Please specify a sub-national level for this country as national analysis is not available. Please search for the sub-national variable in the dataset to identify the correct spelling of the sub-national level, update the local and rerun the .do file"
		exit
		}
			
		
* Start log file
log using "`briefdir'/PMA_`country'_PHASE4_XS_HHQFQ_Log_`date'.log", replace		

* Set local for xls file
local tabout "PMA_`country'_PHASE4_XS_HHQFQ_Analysis_`date'.xls"

* Set local for dataset
local dataset "PMA_`country'_PHASE4_XS_HHQFQ_Analysis_`date'.dta"

* Use household data to show response rates. PMA only includes households 
* 	that fully completed the questionnaire in the analytical sample

* Only keep the cross-sectional sample
keep if xs_sample==1
	

preserve

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
	tabout responserate using "`tabout'", replace ///
		cells(freq col) h2("Household response rate") f(0 1) clab(n %)
		
restore

* Use female data to show female response rates
*	Generate a variable that will identify female questionnaires as either 
*		"Complete" or "Not Complete"
	gen FQresponserate=0 if eligible==1 & last_night==1
		replace FQresponserate=1 if FRS_result==1 & last_night==1 & HHQ_result==1
	label define responselist 0 "Not complete" 1 "Complete"
	label val FQresponserate responselist

* 	Tabout All Women Response Rate
	tabout FQresponserate using "`tabout'", append ///
		cells(freq col) h2("Female response rate") f(0 1) clab(n %)	

* Create analytical sample: Only keep de facto women who completed questionnaire 
* 	and households with completed questionnaires. This represents PMA's Analytical
*	Population
keep if FRS_result==1 & HHQ_result==1
keep if last_night==1

* Save dataset so can replicate analysis results later
save "`dataset'", replace

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
label define married_list 0 "Single/Divorced/Widowed/Seperated" 1 "Married/Currently living with a man"
label values married married_list
label variable married "Married or currently living with a man"

* Generate dichotomous sexually active unmarried women variable to represent all 
*	sexually active women who are not married or currently living with a man
gen umsexactive=0 
	replace umsexact=1 if ///
		(FQmarital_status!=1 & FQmarital_status != 2 & FQmarital_status !=.) & ///
		((last_time_sex==2 & last_time_sex_value<=4 & last_time_sex_value>=0) | ///
		(last_time_sex==1 & last_time_sex_value<=30 & last_time_sex_value>=0) | ///
		(last_time_sex==3 & last_time_sex_value<=1 & last_time_sex_value>=0))
label variable umsexactive "Unmarried sexually active" 
label define yesno 0 "0. No" 1 "1. Yes"
	label values umsexactive yesno

* Tabout count of all women, unweighted
tabout one ///
	using "`tabout'", append ///
	cells(freq) h2("All women (unweighted)") f(0)

* Tabout count of all married women, unweighted
tabout married if married==1 ///
	using "`tabout'", append ///
	cells (freq) h2("Married women (unweighted)") f(0)

* Tabout count of unmarried sexually active women, unweighted
tabout umsexactive if umsexactive==1  ///
	using "`tabout'", append ///
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
****************************************	
* DATE OF THE INTERVIEW

capture confirm double var FQdoi_correctedSIF 

	if _rc==0 & FQdoi_correctedSIF==. {

	* Generate doimonth (month of interview) by extracting month from FQdoi_corrected variable 
	gen doimonth=usubstr(FQdoi_corrected, 3, 3)
	tab1 doimonth, mis
	replace doimonth=lower(doimonth)
	replace doimonth="12" if doimonth=="dec" 
	replace doimonth="1" if doimonth=="jan" 
	replace doimonth="2" if doimonth=="feb" 
	replace doimonth="3" if doimonth=="mar" 
	replace doimonth="4" if doimonth=="apr" 
	replace doimonth="5" if doimonth=="may" 
	replace doimonth="6" if doimonth=="jun"
	replace doimonth="7" if doimonth=="jul"
	replace doimonth="8" if doimonth=="aug"
	replace doimonth="9" if doimonth=="sep"
	replace doimonth="10" if doimonth=="oct"
	replace doimonth="11" if doimonth=="nov" 
	tab1 doimonth, mis

	* Generate doiyear (year of interview) by extracting year from FQdoi_corrected variable 
	gen doiyear=usubstr(FQdoi_corrected, 6, 4)

	* Destring doimonth and doiyear 
	destring doimonth, replace
	destring doiyear, replace

	* Calculate doi in century month code (months since January 1900)
	gen doicmc=(doiyear-1900)*12+doimonth 

	* Drop unnecessary variables
	drop doi_*
	}

	else {
	gen doimonth= month(dofc(FQdoi_correctedSIF))
	tab1 doimonth, mis

	* Generate doiyear (year of interview) variable in numeric
	gen doiyear = year(dofc(FQdoi_correctedSIF))

	cap drop doicmc
	gen doicmc=(doiyear-1900)*12+doimonth 

	}
			
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

* Age categories, 5-year age groups
recode age -99=. -88=. -77=.
egen age_cat5=cut(FQ_age) , at (15(5)50)
label define age_cat5_lab 15 "15-19" 20 "20-24" 25 "25-29" 30 "30-34" ///
	35 "35-39" 40 "40-44" 45 "45-49" 50 ">=50"
label values age_cat5 age_cat5_lab
label var age_cat5 "Age Categories (by 5 years)"

* Age categories, highlight adolescents
recode age -99=. -88=. -77=.
egen age_cat=cut(FQ_age) , at (15,20,25,50)
label define age_cat_lab 15 "15-19" 20 "20-24" 25 "25-49" 
label values age_cat age_cat_lab
label var age_cat "Age Categories (years)"
	
****************************************
* EDUCATION

cap rename school_cc school

* Generate three education variables
gen none_primary_education = `none_primary_education' 
gen secondary_education  = `secondary_education' 
gen tertiary_education =  `tertiary_education' 
	
* Combine into single education varaible 
gen education = 1 if none_primary_education == 1
replace education = 2 if secondary_education == 1
replace	education = 3 if tertiary_education == 1
label define education_list 1 "None/Primary education" 2 "Secondary Education" 3 "Tertiary Education"
label values education education_list
label var education "Highest level of education attained"

****************************************
* WORKED

cap rename work_yn_12mo work_12mo
cap rename work_yn_7days work_7d

* Generate a variable to indicate whether a woman has recetly worked 
gen worked_recent = 0 
replace worked_recent = 1 if (work_12mo==1| work_7d==1)
replace worked_recent =. if (work_12mo==. & work_7d==.)
label values worked_recent yes_no_dnk_nr_list
label var worked_recent "Aside from household work, have you done any work in the last 12 months or 7 days"
	
****************************************
* TIME SINCE LAST BIRTH
	
* Generate month and year of last birth variables - UPDATE SO LENGTH NOT INCLUDED
split recent_birth, parse(-) gen(lastbirth_)
rename lastbirth_1 lastbirthyear
rename lastbirth_2 lastbirthmonth
drop lastbirth_*

* Destring last birth month and year variables 
destring lastbirth*, replace
tab1 lastbirthmonth lastbirthyear

* Replace last birth month and year equal to missing is year is 2020 (i.e. missing)
replace lastbirthmonth=. if lastbirthyear==2030
recode lastbirthyear 2030=. 

* Generate last birth data in century month code
gen lastbirthcmc=(lastbirthyear-1900)*12+lastbirthmonth

* Generate time since last birth in months variable
gen tsinceb=doicmc-lastbirthcmc

****************************************
* PARITY
	
* Create categorical parity variable
replace birth_events=. if birth_events ==-88 | birth_events ==-99
egen parity=cut(birth_events), at (0, 1, 3, 5) icodes
label define paritylist 0 "None" 1 "One-Two" 2 "Three-Four" 3 "Five+"
replace parity=3 if birth_events>=5 & birth_events!=.
label val parity paritylist

****************************************
* INTENTION TO USE

* Create intention to use variable
gen intention_use = 0 if cp==0 & pregnant!=1
replace intention_use=1 if fp_start==1 | fp_start==3 | (fp_start==2 & fp_start_value<=1) ///
	& future_user_not_current==1
replace intention_use=. if pregnant==1
label values intention_use yes_no_dnk_nr_list
label var intention_use "Intention to use contraception in the future/in the next year among women who are not current contraception users"

****************************************	
* TOTAL DEMAND

* Generate total demand = current use + unmet need
gen totaldemand=0
	replace totaldemand=1 if cp==1 | unmettot==1
label variable totaldemand "Has contraceptive demand, i.e. current user or unmet need"

* Generate total demand staisfied
gen totaldemand_sat=0 if totaldemand==1
	replace totaldemand_sat=1 if totaldemand==1 & mcp==1
label variable totaldemand_sat "Contraceptive demand satisfied by modern method"

****************************************	
* FEMALE CONTROLLED METHODS

* Generate female controlled method
gen fc_mcp = 0 if current_user == 1
replace fc_mcp=1 if mcp==1 & current_methodnum_rc!=2 & current_methodnum_rc!=9
label var fc_mcp "Current contraceptive use - female controlled method"
	
****************************************
* UNINTENDED BIRTHS

* Generate pregnancy desired variable combining list and current pregnancies
gen pregnancy_desired=pregnancy_last_desired if pregnant!=1
	replace pregnancy_desired=pregnancy_current_desired if pregnancy_desired==. & pregnant==1
	label val pregnancy_desired pregnancy_desired_list
	label var pregnancy_desired "Intendedness of current/most recent pregnancy"

* Generate wantedness variable that combines results from last birth and current pregnancy questions
gen wanted=pregnancy_desired if recent_birth != "" & ever_birth == 1 & tsinceb<=60
recode wanted -88=0 -99=0 
label variable wanted "Intendedness of previous birth/current pregnancy (categorical): then, later, not at all"
label def wantedlist 1 "then" 2 "later" 3 "not at all"
label val wanted wantedlist
tab wanted, mis

* Generate dichotomous intendedness variables that combines births wanted "later" or "not at all"
gen unintend=1 if wanted==2 | wanted==3
replace unintend=0 if wanted==1
label variable unintend "Intendedness of previous birth/current pregnancy (dichotomous)"
label define unintendlist 0 "Intended" 1 "Unintended"
label values unintend unintendlist

* Percent wanted later
gen wanted_later = 1 if wanted == 2
replace wanted_later = 0 if wanted == 1| wanted == 3
label variable wanted_later "% Wanted later" 
label define wanted_laterlist 0 "Wanted then or not at all" 1"Wanted later"
label values wanted_later wanted_laterlist

* Percent not wanted at all
gen wanted_nomore = 1 if wanted == 3
replace wanted_nomore = 0 if wanted == 1| wanted == 2
label variable wanted_nomore "% Wanted no more" 
label define wanted_nomorelist 1 "Wanted none at all" 0"Wanted then or later"
label values wanted_nomore wanted_nomorelist

* Intention to use contraception 
gen intention_use_nonuser = intention_use if cp == 0 & pregnant == 0
label var intention_use_nonuser "Percent of all women age 15-49 who are not currently using contraception but intend to use contraception in the next 12 months"
label values intention_use_nonuser yes_no_dnk_nr_list

****************************************
* METHOD INFORMATION INDEX PLUS

* Recode Missing Variables
recode fp_told_other_methods -88 -99=.
recode fp_side_effects -88 -99=.
recode fp_side_effects_instructions -88 -99=.
recode fp_told_switch -88=. -99=.

* Generate method information index variable
gen mii = 0
replace mii = 1 if fp_told_switch == 1 & fp_side_effects == 1 & ///
	fp_told_other_methods == 1 & fp_side_effects_instructions==1
replace mii= . if fp_provider_rw == .
label define mii_list 1 "YES for all four MII sub-categories" 0 "No for at least one"
label values mii mii_list
label var mii "Method Information Index"

****************************************
* PROVIDER

* Generate variable for receiving fp information
recode visited_by_health_worker -88 -99=0
recode facility_fp_discussion -88 -99=0
gen healthworkerinfo=0
replace healthworkerinfo=1 if visited_by_health_worker==1 | facility_fp_discussion==1
label values healthworkerinfo yes_no_dnk_nr_list
label variable healthworkerinfo "Received family planning info from provider/community health worker in last 12 months"

* Public vs Private
recode fp_provider_rw (1/19=1 "public") (-88 -99=0) (nonmiss=0 "not public"), gen(publicfp_rw)
label variable publicfp_rw "Respondent or partner for method got first time from public provider"


* Recode age at first use if women has children variable
replace age_at_first_use_children=0 if ever_birth==0 & fp_ever_used==1
	
** Generate respondent age variable in months
	gen birthyear=year(dofc(birthdateSIF))
	gen birthmonth=month(dofc(birthdateSIF))
	gen v011=(birthyear-1900)*12 + birthmonth 

** Generate age at first marriage variable
*** Generate *marraigemonth and *marriageyear
gen firstmarriagemonth=husband_cohabit_first_month
gen firstmarriageyear=year(dofc(husband_cohabit_start_firstSIF))
gen recentmarriagemonth=husband_cohabit_recent_month
gen recentmarriageyear=year(dofc(husband_cohabit_start_recentSIF))

*** Recode month and year of marriage as missing if year of marriage is 2030 (i.e. missing)
	replace firstmarriagemonth=. if firstmarriageyear==2030
	replace recentmarriagemonth=. if firstmarriageyear==2030
	recode firstmarriageyear 2030=.
	recode recentmarriageyear 2030=.
	
*** Recode month as missing if equal to -88
	replace firstmarriagemonth=1 if firstmarriagemonth==-88 | firstmarriagemonth==0 | firstmarriagemonth==-87
	replace recentmarriagemonth=1 if recentmarriagemonth==-88 | recentmarriagemonth==0 | recentmarriagemonth==-87
	
*** Generate marriage century month code variable
	gen marriagecmc=(firstmarriageyear-1900)*12+firstmarriagemonth
	replace marriagecmc=(recentmarriageyear-1900)*12+recentmarriagemonth ///
		if times_married==1

*** Generate age at first marriage variable
	gen agemarriage=(marriagecmc-v011)/12
	label variable agemarriage "Age at first marriage (25 to 49 years)"
	
** Generate age at first birth variable
gen birthdateSIF_td=dofc(birthdateSIF)
format birthdateSIF_td %td
gen first_birthSIF_td=dofc(first_birthSIF)
format first_birthSIF_td %td
gen recent_birthSIF_td=dofc(recent_birthSIF)
format recent_birthSIF_td %td
replace first_birthSIF_td=recent_birthSIF_td if birth_events==1
gen agefirstbirth=(first_birthSIF_td-birthdateSIF_td)/365.25

****************************************
* LIFE EVENTS BY 18 AND AGE-SPECFICIC RATES

* Percent of women age 18-24 having first birth by age 18 
gen birth18=0 if FQ_age>=18 & FQ_age<25
	replace birth18=1 if agefirstbirth<18 & birth18==0
label variable birth18 "Birth by age 18 (18-24)"

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
	
****************************************	
* Recode all "-99" as "0" to represent missing. For analytical purposes only, PMA recodes -99 values to 0
foreach var in return_to_provider refer_to_relative fp_told_other_methods fp_side_effects ///
			   fp_side_effects_instructions visited_by_health_worker pregnancy_last_desired ///
			   pregnancy_current_desired visited_by_health_worker facility_fp_discussion{
	recode `var' -99=0 -88=0 
	}
recode school -99=.
foreach var in partner_know partner_decision why_not_decision partner_overall {
	recode `var' -99=. 
	}

save, replace

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
* SECTION 1: CONTRACEPTIVE USE, DYNAMICS, AND DEMAND
*
*******************************************************************************

*******************************************************************************
* Modern Contraceptive Prevalence
*******************************************************************************

* The tabout for this graph is available in the Contraceptive Trends .do file in
* 	the public repository 

*******************************************************************************
* Contraceptive Prevalence by Method Type
*******************************************************************************

* The tabout for this graph is available in the Contraceptive Trends .do file in
* 	the public repository 

*******************************************************************************
* Trends in Modern Contraceptive Mix
*******************************************************************************

* The tabout for this graph is available in the Contraceptive Trends .do file in
* 	the public repository 

*******************************************************************************
* Modern Contraceptive Method Mix
*******************************************************************************
capture ssc install tabout 

* Current/recent method, 
*	among married women currently using a modern method
tabout current_methodnum_rc if mcp==1 & married==1 [aweight=`weight'] ///
	using "`tabout'", append c(col) f(1) clab(%) npos(row) ///
	h2("Percent distribution of modern contraceptive users age 15-49 by method and marital status - Married women")

* Current/recent method, 
*	among unmarried sexually active women currently using a modern method if N>=50
quietly tab current_methodnum_rc if umsexactive==1 & mcp==1

if r(N)>=50 {
	tabout current_methodnum_rc if mcp==1 & umsexactive==1 [aweight=`weight'] ///
		using "`tabout'", append c(col) f(1) clab(%) npos(row) ///
		h2("Percent distribution of modern contraceptive users age 15-49 by method and marital status - Unmarried, sexually active women")
	}

*******************************************************************************
* Method Use, Unmet Need, and Demand Satisfied by a Modern Method
*******************************************************************************

* The tabout for this graph is available in the Contraceptive Trends .do file in
* 	the public repository 

*******************************************************************************
* Intention to Use Contraception in the Next Year
*******************************************************************************

* Intention to use contraeption in the next year,
*	among all women who are not currently using contraception
tabout intention_use_nonuser [aweight=`weight'] ///
	using "`tabout'", append c(col) f(1) clab(%) npos(row) ///
	h2("Percent of all women age 15-49 who are not currently using contraception but intend to use contraception in the next 12 months")
	
*******************************************************************************
* Intention of Most Recent Birth/Current Pregnancy
*******************************************************************************
	
* Intention of most recent birth/current pregnancy, 
*	among all women currently pregnant or who have giving birth in the last 5 years
foreach var in unintend wanted_later wanted_nomore {
tabout `var'  [aweight=`weight'] ///
	using "`tabout'", append c(col) f(1) clab(%) npos(row) ///
	h2("Percent of women by intention of their most recent birth or current pregnancy")
}
	
*******************************************************************************
*
* SECTION 2: CONTRACEPTIVE USER COUNSELING AND OUTREACH
*
*******************************************************************************

* Update indicators labels to match labels in Phase 4 briefs
label var fp_side_effects "By the provider about side effects or problems you might have?"
label var fp_side_effects_instructions "What to do if you experienced side effects or problems?"
label var fp_told_other_methods "By the provider about methods of FP other than the method you received?"
label var fp_told_switch "That you could switch to a different method in the future?"
label var healthworkerinfo "Percent who received FP info from a provider/community health worker(CHW),by age"
label var partner_know "Does your partner know you are using this method?"
label var partner_decision "Before you started using this method had you discussed the decision to delay or avoid pregnancy with your partner?"
label var partner_overall "Would you say that using FP is mainly your decision?"
label var why_not_decision "Would you say that not using FP is mainly your decision?"
label var rc_forcepreg "Tried to force or pressure them to become pregnant in the past 12 months"
label var rc_treatbad "Made them feel badly for wanting to use an FP method to delay or prevent pregnancy in the past 12 months"
label var rc_took_away_fp "Took away their FP method or kept them from a clinic in the past 12 months"
label var rc_partner_leave "Said he would leave them if they did not get pregnant in the past 12 months"


*******************************************************************************
* Method Information Index Plus (MII+)
*******************************************************************************

* Method Information Index Plus,
*	among modern contraceptive users
*	1) Told by the provider about side effects or problems
*	2) Told what to do if they experienced side effects
*	3) Told about other FP methods
*	4) Told that they could switch to different method in the future
foreach var in fp_side_effects fp_side_effects_instructions fp_told_other_methods fp_told_switch {
tabout `var' [aweight=`weight'] ///
	using "`tabout'", append c(col) f(1) clab(%) npos(row) ///
	h2("When you obtained your method were you told:")
}
	
* Percent of women who responded "Yes" to all four MII+ questions,
*	among modern contraceptive users
tabout mii [aweight=`weight'] ///
	using "`tabout'", oneway append c(col) f(1) clab(%)  npos(row) ///
	h2("MII+:Percent women who responded 'Yes' to all four MII+ questions")

*******************************************************************************
* Discussed FP in the Past Year With Provider/CHW
*******************************************************************************

* Percent of women who received FP information from a provider or CHW,
*	by age
tabout healthworkerinfo age_cat [aw=`weight'] ///
	using "`tabout'", append c(col) f(1) clab(%) npos(row) ///
	h1("Discussed FP in the past year with provider/CHW")
	
*******************************************************************************
*
* SECTION 3: QUALITY OF FP SERVICES
*
*******************************************************************************

* The tabouts for these graphs are available in the Client Exit Interview .do file 
*	in the public repository 

*******************************************************************************
*
* SECTION 4: PARTNER DYNAMICS
*
*******************************************************************************
	
*******************************************************************************
* Partner Involvement in FP Decisions
*******************************************************************************

* Percent of women who agree with the following statement,
*	among women who are currently using a modern, female controlled method
*	1) "Does your partner know that you are using this method"
tabout partner_know if fc_mcp==1 [aw=`weight'] ///
	using "`tabout'", append c(col) f(1) clab(%) npos(row) ///
	h2("Percent of women who are currently using modern, female controlled methods and agree with the following statement")
	
	* Percent of women who agree with the statement, by,
	*	1) Age
	*	2) Education
	foreach var in age_cat education {
		tabout partner_know `var' if fc_mcp==1 [aw=`weight'] ///
			using "`tabout'", append c(col) f(1) clab(%) npos(row) ///
			h1("Percent of women who are currently using modern, female controlled methods and agree with the following statement, by `var'")
	}
	
* Percent of women who agree with the following statement,
*	among women who are currently using a modern, female controlled method
*	1) "Before you started using this method had you discussed the decision to delay or avoid pregnancy with your partner?"
tabout partner_decision if fc_mcp==1 [aw=`weight'] ///
	using "`tabout'", append c(col) f(1) clab(%) npos(row) ///
	h2("Percent of women who are currently using modern, female controlled methods and agree with the following statement")
	
	* Percent of women who agree with the statement, by,
	*	1) Age
	*	2) Education
	foreach var in age_cat education {
		tabout partner_decision `var' if fc_mcp==1 [aw=`weight'] ///
			using "`tabout'", append c(col) f(1) clab(%) npos(row) ///
			h1("Percent of women who are currently using modern, female controlled methods and agree with the following statement, by `var'")
	}	
	
* Percent of women who agree with the following statement,
*	among all family planning users
*	1) "Would you say that using FP is mainly your decision"
tabout partner_overall [aw=`weight'] ///
	using "`tabout'", append c(col) f(1) clab(%) npos(row) ///
	h2("Percent of women who are currently using FP and agree with the following statement")  
	
	* Percent of women who agree with the statement, by,
	*	1) Age
	*	2) Education
	foreach var in age_cat education {
		tabout partner_overall `var' [aw=`weight'] ///
			using "`tabout'", append c(col) f(1) clab(%) npos(row) ///
			h1("Percent of women who are currently using FP and agree with the following statement by `var'")
	}	
	
* Percent of women who agree with the following statement,
*	among all women who do not use family planning
*	1) "Would you say that not using FP is mainly your decision"
tabout why_not_decision [aw=`weight'] ///
	using "`tabout'", append c(col) f(1) clab(%) npos(row) ///
	h2("Percent of women who are not currently using FP and agree with the following statement") 
	
	* Percent of women who agree with the statement, by,
	*	1) Age
	*	2) Education
	foreach var in age_cat education {
		tabout why_not_decision `var' [aw=`weight'] ///
			using "`tabout'", append c(col) f(1) clab(%) npos(row) ///
			h1("Percent of women who are not currently using FP and agree with the following statement by `var'")
	}	
	
*******************************************************************************
* Pregnancy Coercion
*******************************************************************************

* Percent of married women who report that their partner:
*	1) Tried to force or pressure her to become pregnant
*	2) Threatened to abandon them if they did not get pregnant
*	3) Made them feel badly for wanting to use a FP method to delay or prevent pregnancy
*	4) Prevented them from using a FP method to delay or prevent pregnancy
foreach var in rc_forcepreg rc_treatbad rc_partner_leave rc_took_away_fp {
	recode `var' -99=. -88=.
tabout `var' if married==1 [aw=`weight'] ///
	using "`tabout'", append c(col) f(1) clab(%) npos(row) ///
	h2("Pregnancy Coercion Indicators - Percent currently married women who report that their partner:")
}

*******************************************************************************
*
* SECTION 5: SERVICE DELIVERY POINTS
*
*******************************************************************************	

* OBTAINED CURRENT METHOD AT A PUBLIC HEALTH FACILITY

* Percent of women who obtained their modern method at a public facility,
*	among current modern contraceptive users
tabout publicfp_rw if mcp==1 [aw=`weight'] ///
	using "`tabout'", append c(col) f(1) npos(row) ///
	h2("Percent of women who obtained their current modern method from a public facility") 

*******************************************************************************
*
* DEMOGRAPHIC VARIABLES (NOT INCLUDED ON BRIEF)
*
*******************************************************************************	

* Distribtuion of de facto women by age
tabout age_cat5 [aw=`weight'] ///
	using "`tabout'",  append c(freq col) f(0 1) clab(n %) nwt(`weight') npos(row) ///
	h2("Distribution of de facto women by age - weighted")

* Distribution of de facto women by education
tabout school [aw=`weight'] ///
	using "`tabout'",  append c(freq col) f(0 1) clab(n %) nwt(`weight') npos(row) ///
	h2("Distribution of de facto women by education - weighted")

* Distribution of de facto women by marital status
tabout FQmarital_status [aw=`weight'] ///
	using "`tabout'",  append c(freq col) f(0 1) clab(n %) nwt(`weight') npos(row) ///
	h2("Distribution of de facto women by marital status - weighted")

* Distribution of de facto women by wealth
tabout `wealth' [aw=`weight'] ///
	using "`tabout'",  append c(freq col) f(0 1) clab(n %) nwt(`weight') npos(row) ///
	h2("Distribution of de facto women by wealth - weighted")

* Distribution of de facto women by urban/rural
tabout urban [aw=`weight'] ///
	using "`tabout'",  append c(freq col) f(0 1) clab(n %) nwt(`weight') npos(row) ///
	h2("Distribution of de facto women by urban/rural - weighted")
	

*******************************************************************************
* CLOSE
*******************************************************************************

log close
