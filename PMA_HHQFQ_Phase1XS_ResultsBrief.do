/*******************************************************************************
* The following .do file will create the .xls file output that PMA used to 
* 	generate its Phase 1 cross sectional results briefs using PMA's publicly  
* 	available Household and Female dataset
*
* This .do file will only work on Phase 1 HHQFQ cross sectional datasets. You 
*   can  find the .do files to generate the .xls file outputs for PMA's publicly
* 	available Phase 1 SDP and CQ datasets and other surveys in the  
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
*  FILENAME:		PMA_HHQFQ_Phase1XS_ResultsBrief.do
*  PURPOSE:			Generate the .xls output for the PMA Phase 1 XS Results Brief
*  CREATED BY: 		Elizabeth Larson (elarso11@jhu.edu)
*  DATA IN:			PMA's Phase1 XS HHQFQ publicly released dataset
*  DATA OUT: 		PMA_COUNTRY_PHASE_XS_HHQFQ_Analysis_DATE.dta
*  FILE OUT: 		PMA_COUNTRY_PHASE_XS_HHQFQ_Analysis_DATE.xls
*  LOG FILE OUT: 	PMA_COUNTRY_PHASE_XS_HHQFQ_Log_DATE.log
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
local datadir "/Users/ealarson/Dropbox (Gates Institute)/5 Burkina Faso/PMABF_Datasets/Phase1/Final_PublicRelease/HQFQ/PMA_BFP1_HQFQ_v1.1_15Feb2021/PMA_BFP1_HQFQ_Baseline_v1.1_15Feb2021.dta"

*	2. A directory for the folder where you want to save the dataset, xls and
*		log files that this .do file creates
*		- For example (Mac): 
*		  local briefdir "/User/ealarson/Desktop/PMA2020/NigeriaAnalysisOutput"
*		- For example (PC): 
*		  local briefdir "C:\Users\annro\PMA2020\NigeriaAnalysisOutput"
local briefdir "/Users/ealarson/Documents/PMA/Burkina Faso/PublicRelease"


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
local subnational_yn "yes"
local subnational "centre"

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

* Confirm that it is phase 1 data
gen check=(phase==1)
	if check!=1 {
		di in smcl as error "The dataset you are using is not a PMA phase 1 XS dataset. This .do file is to generate the .xls files for PMA Phase 1 XS surveys only. Please use a PMA Phase 1 XS survey and rerun the .do file"
		stop
		}
	drop check

* Confirm that correct variables were chosen for locals

*	Country Variable
	gen countrycheck="`country'"
	gen check=(countrycheck==country)
	if check!=1 {
		di in smcl as error "The specified country is not the correct coding for this phase of data collection. Please search for the country variable in the dataset to identify the correct country code, update the local and rerun the .do file"
		stop
		}
	drop countrycheck check

*	Weight Variable
	capture confirm var `weight'
	if _rc!=0 {
		di in smcl as error "Variable `weight' not found in dataset. Please search for the correct weight variable in the dataset and update the local macro 'weight'. If you are doing a regional/state-level analysis, please make sure that you have selected the correct variable for the geographic level, update the local and rerun the .do file"
		stop
		}
		
*	Wealth Variable	
	capture confirm var `wealth'
	if _rc!=0 {
		di in smcl as error "Variable `wealth' not found in dataset. Please search for the correct wealth variable in the dataset and update the local macro 'wealth'. If you are doing a regional/state-level analysis, please make sure that you have selected the correct variable for the geographic level, update the local and rerun the .do file"
		stop
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
				stop	
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
				stop		
				}
		di in smcl as error "The sub-national estimates are not yet available for Burkina Faso, we will update the .do file once they become available. If you would like Burkina Faso-related estimates, please update the .do file to generate national-level estimates"
		stop
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
				stop
				}
		local country `country'_`subnational'
		drop subnational province_string subnational_keep subnational_keep1 check
		}	
		
* Start log file
log using "`briefdir'/PMA_`country'_Phase1_XS_HHQFQ_Log_`date'.log", replace		

* Set local for xls file
local tabout "PMA_`country'_Phase1_XS_HHQFQ_Analysis_`date'.xls"

* Set local for dataset
local dataset "PMA_`country'_Phase1_XS_HHQFQ_Analysis_`date'.dta"

* Use household data to show response rates. PMA only includes households 
* 	that fully completed the questionnaire in the analytical sample
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
		replace FQresponserate=1 if FRS_result==1 & last_night==1
	label define responselist 0 "Not complete" 1 "Complete"
	label val FQresponserate responselist

* 	Tabout All Women Response Rate
	tabout FQresponserate if HHQ_result==1 using "`tabout'", append ///
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

* Split FQdoi_corrected
split FQdoi_corrected, gen(doi_)

* Generate doimonth (month of interview) from first split variable 
gen doimonth=doi_1
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

* Generate doiyear (year of interview) from third split variable
gen doiyear=doi_3

* Destring doimonth and doiyear 
destring doimonth, replace force
destring doiyear, replace

* Calculate doi in century month code (months since January 1900)
gen doicmc=(doiyear-1900)*12+doimonth 

* Drop unnecessary variables
drop doi_*

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
gen intention_use = 0 
replace intention_use=1 if fp_start==1 | fp_start==3 | (fp_start==2 & fp_start_value<=1)
label values intention_use yes_no_dnk_nr_list
label var intention_use "Intention to use contraception in the future/in the next year"

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
* UNINTENDED BIRTHS

* Generate pregnancy desired variable combining list and current pregnancies
gen pregnancy_desired=pregnancy_last_desired
	replace pregnancy_desired=pregnancy_current_desired if pregnancy_desired==.
	label val pregnancy_desired pregnancy_desired_list
	label var pregnancy_desired "Intendedness of current/most recent pregnancy"

* Generate wantedness variable that combines results from last birth and current pregnancy questions
gen wanted=pregnancy_desired if recent_birth != "" & ever_birth == 1 & tsinceb<60
recode wanted -88=0 -99=0 
label variable wanted "Intendedness of previous birth/current pregnancy (categorical): then, later, not at all"
label def wantedlist 1 "Then" 2 "Later" 3 "Not at all"
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

****************************************
* METHOD INFORMATION INDEX PLUS

* Recode Missing Variables
recode fp_told_other_methods -88 -99=.
recode fp_side_effects -88 -99=.
recode fp_side_effects_instructions -88 -99=.
recode fp_told_switch -88=. -99=.

* Combine fp_provider_rw variables
gen fp_provider_rw=fp_provider_rw_kn
	replace fp_provider_rw=fp_provider_rw_nr if fp_provider_rw==.
	label val fp_provider_rw providers_list
	label var fp_provider_rw "Where did you and your partner get METHOD at the time" 

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
tab healthworkerinfo [aweight=`weight']

* Public vs Private
recode fp_provider_rw (1/19=1 "public") (-88 -99=0) (nonmiss=0 "not public"), gen(publicfp_rw)
label variable publicfp_rw "Respondent or partner for method got first time from public provider"
		
****************************************
* PERSONAL NORMS

* Generate 4 personal norms variables:
** 1) Adolescents who use FP are promiscuous
** 2) FP is only for women who are married
** 3) FP is only for women who do not want any more children
** 4) People who use FP have a better quality of life
label define self_list 1 "Strongly Agree/Agree" 0 "Disagree/Strongly Disagree"
foreach var in promis onlymar nomore lifestyle {
	recode fp_think_`var' -88=. -99=. 
	gen attitude_`var'=1 if fp_think_`var'== 1 | fp_think_`var'==2
	replace attitude_`var'=0 if fp_think_`var'==3 | fp_think_`var'==4 
	label values attitude_`var' self_list
	}
label var attitude_promis "Self Attitude: Adolescents who use FP are promiscuous"
label var attitude_onlymar "Self Attitude: FP is only for women who are married"
label var attitude_nomore "Self Attittude: FP is only for women who do not want any more children"
label var attitude_lifestyle "Self Attittude: People who use FP have a better quality of life"

****************************************
* WGE SCORE

* Variable Generation: Contraceptive Existence of Choice (motivational autonomy)
** Create composite variable for would/could conflict
	gen wge_conflict=fp_aut_conflict_will
	replace wge_conflict=fp_aut_conflict if wge_conflict==.
	label var wge_conflict "If I use FP it could/will cause conflict in my relationship" 
	label val wge_conflict agree_down5_list

* Rename fp_aut* variables to wge
rename fp_aut_otherptr wge_seek_partner
rename fp_aut_diffpreg wge_trouble_preg
rename fp_aut_abchild wge_abnormal_birth 
rename fp_aut_disrupt wge_body_side_effects	
rename fp_aut_switch wge_switch_fp
rename fp_aut_confident wge_confident_method
	
** Reverse scores for low empowerment direction measures
	foreach v of var wge_seek_partner wge_trouble_preg wge_conflict ///
			wge_abnormal_birth wge_body_side_effects {
			recode `v' -99 -88 =.
			
			local `v'_lab : variable label `v'
			gen `v'_rev=.
			replace `v'_rev=1 if `v'==5
			replace `v'_rev=2 if `v'==4
			replace `v'_rev=3 if `v'==3
			replace `v'_rev=4 if `v'==2
			replace `v'_rev=5 if `v'==1
			label var `v'_rev "REVERSE ``v'_lab'" 
		}

** Create composite variables for Contraceptive Existence of Choice
	*Mean impute
	foreach var in wge_seek_partner_rev wge_trouble_preg_rev wge_conflict_rev ///
			wge_abnormal_birth_rev wge_body_side_effects_rev {
	
		*Store mean value of reversed
		quietly sum `var'
		local `var'_m r(mean)
		
		*Replace missing values with the mean of the recode
		gen `var'_rc=`var'
		replace `var'_rc=``var'_m' if `var'==.
		}
	
	egen fp_aut_mean_score=rowmean(wge_seek_partner_rev_rc wge_trouble_preg_rev_rc ///
			wge_conflict_rev_rc wge_abnormal_birth_rev_rc wge_body_side_effects_rev_rc)
		label var fp_aut_mean_score "Mean WGE FP autonomy score"

** Create absolute quintiles
	gen fp_aut_quint=.
	replace fp_aut_quint=1 if fp_aut_mean_score>=1 & fp_aut_mean_score<=2
	replace fp_aut_quint=2 if fp_aut_mean_score>2 & fp_aut_mean_score<=3
	replace fp_aut_quint=3 if fp_aut_mean_score>3 & fp_aut_mean_score<=4
	replace fp_aut_quint=4 if fp_aut_mean_score>4 & fp_aut_mean_score<5
	replace fp_aut_quint=5 if fp_aut_mean_score==5
	
* Variable Generation: Contraceptive Exercise of Choice (Self-efficacy)
** Mean impute
	foreach var in wge_switch_fp wge_confident_method {

	local `var'_lab: variable label `var'
	
	*Store mean value of recode
	recode `var' -99 -88 =.
	quietly sum `var'
	local `var'_m r(mean)
	
	*Replace missing values with the mean of the recode
	gen `var'_rc=`var'
	replace `var'_rc=``var'_m' if `var'==.
	}

** Create composite variable for Contraceptive Exercise of Choice	
	gen fp_se_mean_score=(wge_switch_fp_rc+wge_confident_method_rc)/2
	label var fp_se_mean_score "Mean FP exercise of choice score"
	sum fp_se_mean_score

** Create absolute quintiles
	gen fp_se_quint=. 
	replace fp_se_quint=1 if fp_se_mean_score>=1 & fp_se_mean_score<=2
	replace fp_se_quint=2 if fp_se_mean_score>2 & fp_se_mean_score<=3
	replace fp_se_quint=3 if fp_se_mean_score>3 & fp_se_mean_score<=4
	replace fp_se_quint=4 if fp_se_mean_score>4 & fp_se_mean_score<5
	replace fp_se_quint=5 if fp_se_mean_score==5
	tab fp_se_quint, m
	bysort fp_se_quint: summ fp_se_mean_score
	
* Variable Generation: Combined Indicator
egen fp_wge_comb=rowmean(wge_seek_partner_rev_rc wge_trouble_preg_rev_rc wge_conflict_rev_rc wge_abnormal_birth_rev_rc wge_body_side_effects_rev_rc wge_switch_fp_rc wge_confident_method_rc)
label var fp_wge_comb "Mean combined FP WGE score"

gen wge_quint=. 
	replace wge_quint=1 if fp_wge_comb>=1 & fp_wge_comb<=2
	replace wge_quint=2 if fp_wge_comb>2 & fp_wge_comb<=3
	replace wge_quint=3 if fp_wge_comb>3 & fp_wge_comb<=4
	replace wge_quint=4 if fp_wge_comb>4 & fp_wge_comb<5
	replace wge_quint=5 if fp_wge_comb==5
	
label var wge_quint "WGE Quintile values, from least to most"	
	
save, replace

****************************************
* MEANS AND MEDIANS

* Recode age at first use if women has children variable
replace age_at_first_use_children=0 if ever_birth==0 & fp_ever_used==1

* Generate program: Arguments to input are 1 (dataset), 2 (variable name), 
*	3 (lower age bound), 4 (weight)
capture program drop pmamediansimple
program define pmamediansimple
	
	use `1', clear
	keep if FQ_age>=`3' //age range for the tabulation
	
	gen one=1
	drop if `2'==.
	collapse (count) count=one [pweight=`4'], by(`2')
	sort  `2'
	gen ctotal=sum(count)
	egen total=sum(count)
	gen cp=ctotal/total
	
	keep if (cp <= 0.5 & cp[_n+1]>0.5) | (cp>0.5 & cp[_n-1]<=0.5)
	
	local median=(0.5-cp[1])/(cp[2]-cp[1])*(`2'[2]-`2'[1])+`2'[1] +1
	
	macro list _median
	
	clear
	set obs 1
	gen median=`median'
	
	end
capture drop one
	
* Generate variables for median and mean calculations
use "`dataset'", clear
	
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
	
*** Recode month as missing if equal to -87
	replace firstmarriagemonth=1 if firstmarriagemonth==-87
	replace recentmarriagemonth=1 if recentmarriagemonth==-87
	
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

* Save dataset to use in median calculations
save, replace

* Generate temp files for brief development

** Create a local macro for the dataset to use during median calculations
** local median_dataset "PMA_`country'_`phase'_HHQFQ_XS_Analysis_`date'.dta"
	tempfile median_file

** Median age at first marriage
	preserve
		save median_file, replace
		pmamediansimple median_file agemarriage 25 `weight'
		gen urban="All Women"
		tempfile afm_total
		save `afm_total', replace 
	restore

	preserve
		keep if urban==0
		capture codebook metainstanceID
		if _rc!=2000 { 
			save median_file, replace
			pmamediansimple median_file agemarriage 25 `weight'
			gen urban="Rural"
			tempfile afm_rural
			save `afm_rural', replace
		}
	restore 

	preserve
		keep if urban==1
		capture codebook metainstanceID
		if _rc!=2000 { 
			save median_file, replace
			pmamediansimple median_file agemarriage 25 `weight'
			gen urban="Urban"
			tempfile afm_urban
			save `afm_urban', replace
		}
	restore

* 	Median age at first sex among all women who have had sex
	preserve
		keep if age_at_first_sex>0 & age_at_first_sex<50 
		save `median_file', replace
		pmamediansimple `median_file' age_at_first_sex 15 `weight'
		gen urban="All Women"
		tempfile afs_total
		save `afs_total', replace
	restore
	
	preserve 
		keep if age_at_first_sex>0 & age_at_first_sex<50 & urban==0
		capture codebook metainstanceID
		if _rc!=2000 {
			save `median_file', replace
			pmamediansimple `median_file' age_at_first_sex 15 `weight'
			gen urban="Rural"
			tempfile afs_rural
			save `afs_rural', replace 
		}
	restore
	
	preserve 
		keep if age_at_first_sex>0 & age_at_first_sex<50 & urban==1 
		capture codebook metainstanceID
		if _rc!=2000 {
			save `median_file', replace
			pmamediansimple `median_file' age_at_first_sex 15 `weight'
			gen urban="Urban"
			tempfile afs_urban
			save `afs_urban',replace
		}
	restore

*	Median age at first contraceptive use among all women who have ever used contraception
	preserve
		keep if fp_ever_used==1 & age_at_first_use>0
		save `median_file', replace
		pmamediansimple `median_file' age_at_first_use 15 `weight'
		gen urban="All Women"
		tempfile afc_total
		save `afc_total', replace
	restore
	
	preserve
		keep if fp_ever_used==1 & age_at_first_use>0 & urban==0
		capture codebook metainstanceID
		if _rc!=2000 {
			save `median_file', replace
			pmamediansimple `median_file' age_at_first_use 15 `weight'
			gen urban="Rural"
			tempfile afc_rural
			save `afc_rural', replace
		}
	restore
	
	preserve
		keep if fp_ever_used==1 & age_at_first_use>0 & urban==1
		capture codebook metainstanceID
		if _rc!=2000 {
			save `median_file', replace
			pmamediansimple `median_file' age_at_first_use 15 `weight'
			gen urban="Urban"
			tempfile afc_urban
			save `afc_urban', replace
		}
	restore

* 	Median age at first birth among all women who have ever given birth
	preserve
		keep if ever_birth==1
		capture codebook metainstanceID
		if _rc!=2000 {
			save `median_file', replace
			pmamediansimple `median_file' agefirstbirth 25 `weight'
			gen urban="All Women"
			tempfile afb_total
			save `afb_total', replace
		}
	restore
	
	preserve
		keep if ever_birth==1 & birth_events!=. & birth_events!=-99 & urban==0
		capture codebook metainstanceID 
		if _rc!=2000 {
			save `median_file', replace
			pmamediansimple `median_file' agefirstbirth 25 `weight'
			gen urban="Rural"
			tempfile afb_rural
			save `afb_rural', replace
		}
	restore
	
	preserve
		keep if ever_birth==1 & birth_events!=. & birth_events!=-99 & urban==1
		capture codebook metainstanceID 
		if _rc!=2000 {
			save `median_file', replace
			pmamediansimple `median_file' agefirstbirth 25 `weight'
			gen urban="Urban"
			tempfile afb_urban
			save `afb_urban', replace
		}
	restore

use "`dataset'", clear

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

* Current/recent method, 
*	among married women currently using a modern method
tabout current_methodnum_rc if mcp==1 & married==1 [aweight=`weight'] ///
	using "`tabout'", append c(col) f(1) clab(%) npos(row) ///
	h2("Method Mix - married women (weighted)")

* Current/recent method, 
*	among unmarried sexually active women currently using a modern method
tabout current_methodnum_rc if mcp==1 & umsexactive==1 [aweight=`weight'] ///
	using "`tabout'", append c(col) f(1) clab(%) npos(row) ///
	h2("Method mix - unmarried sexually active women (weighted)") 

*******************************************************************************
* Method Use, Unmet Need, and Demand Satisfied by a Modern Method
*******************************************************************************

* The tabout for this graph is available in the Contraceptive Trends .do file in
* 	the public repository 

*******************************************************************************
* 12-Month Discontinuation Rate
*******************************************************************************

* The tabout for this graph is available in the Discontiuation Rate .do file in
* 	the public repository 

*******************************************************************************
* Intention of Most Recent Birth/Current Pregnancy
*******************************************************************************
	
* Intention of most recent birth/current pregnancy, 
*	among all women currently pregnant or who have giving birth in the last 5 years
tabout unintend wanted_later wanted_nomore if tsinceb<=60 [aweight=`weight'] ///
	using "`tabout'", append oneway c(col) f(1) clab(%) npos(row) ///
	h2("Fertility Intention Indicators (weighted) - women who are currently pregnant or who gave birth in the last 5 years")
	
*******************************************************************************
*
* SECTION 2: QUALITY OF FP SERVICES AND COUNSELING
*
*******************************************************************************

*******************************************************************************
* Method Information Index Plus (MII+)
*******************************************************************************

* Method Information Index Plus,
*	among modern contraceptive users
*	1) Told by the provider about side effects or problems
*	2) Told what to do if they experienced side effects
*	3) Told about other FP methods
*	4) Told that they could switch to different method in the future
tabout fp_side_effects fp_side_effects_instructions fp_told_other_methods fp_told_switch [aweight=`weight'] ///
	using "`tabout'", oneway append c(col) f(1) clab(%) npos(row) ///
	h2("MII+ Indicators (weighted) - current modern contraceptive users")
	
* Percent of women who responded "Yes" to all four MII+ questions,
*	among modern contraceptive users
tabout mii [aweight=`weight'] ///
	using "`tabout'", oneway append c(col) f(1) clab(%) npos(row) ///
	h2("Percent of women who responded 'Yes' to all four MII+ indicators (weighted) - current modern contraceptive users")

*******************************************************************************
* Discussed FP in the Past Year With Provider/CHW
*******************************************************************************

* Percent of women who received FP information from a provider or CHW,
*	by age
tabout healthworkerinfo age_cat [aw=`weight'] ///
	using "`tabout'", append c(col) f(1) clab(%) npos(row) ///
	h1("Discussed FP in the past year with a provider/community health worker by age (weighted) - all women")
	
*******************************************************************************
* Client Exit Interviews
*******************************************************************************

* The tabouts for these graphs are available in the Client Exit Interview .do file 
*	in the public repository 

*******************************************************************************
*
* SECTION 3: PARTNER DYNAMICS
*
*******************************************************************************
	
*******************************************************************************
* Partner Involvement in FP Decisions
*******************************************************************************

* Percent of women who agree with the following statements,
*	among women who are currently using a modern, female controlled method
*	1) "Does your partner know that you are using this method"
*	2) "Before you started using this method had you discussed the decision to
*		delay or avoid pregnancy with your partner?"
tabout partner_know partner_decision if mcp==1 [aw=`weight'] ///
	using "`tabout'", append oneway c(col) f(1) clab(%) npos(row) ///
	h2("Partner Dynamics (weighted) - female-controlled method users ")
	
* Percent of women who agree with the following statement,
*	among all family planning users
*	1) "Would you say that using FP is mainly your decision"
tabout partner_overall [aw=`weight'] ///
	using "`tabout'", append c(col) f(1) clab(%) npos(row) ///
	h2("Joint decision making around contraceptive use (weighted) - all contraceptive users")  
	
* Percent of women who agree with the following statement,
*	among all women who do not use family planning
*	1) "Would you say that not using FP is mainly your decision"
tabout why_not_decision [aw=`weight'] ///
	using "`tabout'", append c(col) f(1) clab(%) npos(row) ///
	h2("Joint decision making around non-use of contraception (weighted) - all non-contraceptive users") 

*******************************************************************************
*
* SECTION 4: WOMEN AND GIRLS' EMPOWERMENT
*
*******************************************************************************	
*******************************************************************************
* Agreement with Family Planning Empowerment Statements
*******************************************************************************

* Exercise of Choice (self-efficacy, negotiation) for family planning,
*	among all married women
*	1) I feel confident telling my provider what is important when selecting
*	   an FP method
*	2) I can decide to switch from one FP method to another if I want to

	* Kenya is among all women
	if country=="Kenya" {
		tabout wge_confident_method wge_switch_fp [aw=`weight'] ///
			using "`tabout'", append oneway c(col) f(1) clab(%) npos(row) ///
			h2("Exercise of Choice for Family Planning (weighted) - all women")
		}
else {
tabout wge_confident_method wge_switch_fp if married==1 [aw=`weight'] ///
	using "`tabout'", append oneway c(col) f(1) clab(%) npos(row) ///
	h2("Exercise of Choice for Family Planning (weighted) - all married women")
	}
	
	
* Existence of Choice (motivational autonomy) for family planning,
*	among all married women
*	1) If I use FP, my body may experience side effects that will disrupt 
*	   relations with my partner
*	2) If I use FP, my children may not be born normal
*	3) There will be conflict in my relationship/marriage if I use FP
*	4) If I use FP, I may have trouble getting pregnant the next time I want to
*	5) If I use FP, my partner may seek another sexual partner

	* Kenya is among all women
	if country=="Kenya" {
		tabout wge_body_side_effects wge_abnormal_birth wge_conflict wge_trouble_preg wge_seek_partner [aw=`weight'] ///
			using "`tabout'", append oneway c(col) f(1) clab(%) npos(row) ///
			h2("Existence of Choice for Family Planning (weighted) - all  women")	
		}
else {
tabout wge_body_side_effects wge_abnormal_birth wge_conflict wge_trouble_preg wge_seek_partner if married==1 [aw=`weight'] ///
	using "`tabout'", append oneway c(col) f(1) clab(%) npos(row) ///
	h2("Existence of Choice for Family Planning (weighted) - all married women")	
	}

*******************************************************************************
* Women's and Girl's Empowerment (WGE) Sub-Scale for Family Planning
*******************************************************************************
	
* Mean WGE Score,
*	by education, among married women
tabout education if married==1 ///
	using "`tabout'", append sum cells(mean fp_wge_comb) npos(row) ///
	h2("Mean WGE Score by education - married women")
	
* Mean WGE Score,
*	by age, among married women
tabout age_cat if married==1 ///
	using "`tabout'", append sum cells(mean fp_wge_comb) npos(row) ///
	h2("Mean WGE Score by age - married women")
	
* Percent of women using a modern method of contraception,
*	by categorical WGE score, among married women 
tabout mcp wge_quint if married==1 [aw=`weight'] ///
	using "`tabout'", append cells(col) f(1) clab(%) nwt(`weight') npos(row) ///
	h1("mCPR by WGE Quintile (weighted) - married women")
	
* Percent of women who intend to use contraception in the next year,
*	by categorical WGE score, among married women
tabout intention_use wge_quint if married==1 [aw=`weight'] ///
	using "`tabout'", append cells(col) f(1) clab(%) nwt(`weight') npos(row) ///
	h1("Intent to Use by WGE Quintile (weighted) - married women") 
	
* Percent of women using a modern method of contraception,
*	by employment
tabout mcp worked_recent [aw=`weight'] ///
	using "`tabout'", append cells(col) f(1) clab(%) nwt(`weight') npos(row) ///
	h1("mCPR by Employment Status (weighted) - all women")
	
* Percent of women who intend to use contraception in the next year,
*	by employment
tabout intention_use worked_recent [aw=`weight'] ///
	using "`tabout'", append cells(col) f(1) clab(%) nwt(`weight') npos(row) ///
	h1("Intent to Use by Employment Status (weighted) - all women") 

*******************************************************************************
*
* SECTION 5: ATTITUDES TOWARDS CONTRACEPTION
*
*******************************************************************************	

*******************************************************************************
* Personal Attitudes
*******************************************************************************

* Percent of women who personally agree with the following statements made about 
*	contraceptive use,
*	by age
*	1) Adolescents who use FP are promiscuous
*	2) FP is only for married women
*	3) Fp is only for women who don't want any more children
*	4) People who use FP have a better quality of life
foreach var in attitude_promis attitude_onlymar attitude_nomore attitude_lifestyle {
	tabout `var' age_cat [aw=`weight'] ///
	using "`tabout'", append c(col) f(1) clab(%) npos(row) ///
	h1("Personal norms around FP by contraceptive use age (weighted) - all women")
	}
	
* Percent of women who personally agree with the following statements made about 
*	contraceptive use,
*	by residence
*	1) Adolescents who use FP are promiscuous
*	2) FP is only for married women
*	3) Fp is only for women who don't want any more children
*	4) People who use FP have a better quality of life
foreach var in attitude_promis attitude_onlymar attitude_nomore attitude_lifestyle {
	tabout `var' urban [aw=`weight'] ///
	using "`tabout'", append c(col) f(1) clab(%) npos(row) ///
	h1("Personal norms around FP by contraceptive use residence (weighted) - all women")
	}
	
* Percent of women who personally agree with th following statements made about 
*	contraceptive use,
*	by residence
*	1) Adolescents who use FP are promiscuous
*	2) FP is only for married women
*	3) Fp is only for women who don't want any more children
*	4) People who use FP have a better quality of life
foreach var in attitude_promis attitude_onlymar attitude_nomore attitude_lifestyle {
	tabout `var' cp [aw=`weight'] ///
	using "`tabout'", append c(col) f(1) clab(%) npos(row) ///
	h1("Personal norms around FP by contraceptive use status (weighted) - all women")
	}

*******************************************************************************
*
* SECTION 6: REPRODUCTIVE TIMELINE
*
*******************************************************************************	
	
*******************************************************************************
* Reproductive timeline
*******************************************************************************

* Mean of living children at first contraceptive use,
*	among women who have ever used contraception 
tabout urban if fp_ever_used==1 & age_at_first_use_children>=0 [aweight=`weight'] ///
	using "`tabout'", append sum c(mean age_at_first_use_children) f(3) npos(row) ///
	h2("Mean number of children at first contraceptive use (weighted) - women who have used contraception") 


* Install the new command needed for the change
ssc install listtab, all replace


* Median age at first marriage *

** Append Datasets
	preserve
	use `afm_total', clear
	capture append using `afm_rural'
	capture append using `afm_urban'

** Median age at first marriage,
**	among married women aged 25-49
	listtab urban median, appendto("`tabout'") ///
		rstyle(tabdelim) headlines("Median age at marriage by residence (weighted) - married women aged 25-49") footlines(" ")
	restore

* Median age at first sex *

** Append Datasets
	preserve
	use `afs_total', clear
	capture append using `afs_rural'
	capture append using `afs_urban'

** Median age at first sex,
**	among women who have had sex
	listtab urban median, appendto("`tabout'") ///
		rstyle(tabdelim) headlines("Median age at first sex by residence (weighted) - women who have had sex") footlines(" ")
	restore

* Median age at first contraceptive use *

** Append Datasets
	preserve
	use `afc_total', clear
	capture append using `afc_rural'
	capture append using `afc_urban'

** Median age at first contraceptive use,
**	among women who have ever used contraception
	listtab urban median, appendto("`tabout'") ///
		rstyle(tabdelim) headlines("Median age at first contraceptive use by resdience (weighted) - women who have used contraception") footlines(" ")
	restore

* Median age at first birth *

** Append Datasets
	preserve
	use `afb_total', clear
	capture append using `afb_rural'
	capture append using `afb_urban'

** Median age at first birth,
**	among women who have give birth aged 25-49 years
	listtab urban median, appendto("`tabout'") ///
		rstyle(tabdelim)  headlines("Median age at first birth by residence (weighted) - women who have given birth aged 25-49 years") footlines(" ")
	restore

*******************************************************************************
* Reproductive Events by Age 18
*******************************************************************************

* Married by 18, first birth before 18, contraceptive use by 18, first sex by 18,
*	among women age 18-24
tabout sex18 married18 birth18 fp18 if FQ_age>=18 & FQ_age<25 [aw=`weight'] ///
	using "`tabout'", append oneway c(col) f(1) clab(%) npos(row) ///
	h2("Married by 18, first sex by 18, contraceptive use by 18, first birth before 18 (weighted) - women aged 18-24") 
	
*******************************************************************************
*
* SECTION 7: SERVICE DELIVERY POINTS
*
*******************************************************************************	

* OBTAINED CURRENT METHOD AT A PUBLIC HEALTH FACILITY

* Percent of women who obtained their modern method at a public facility,
*	among current modern contraceptive users
tabout publicfp_rw if mcp==1 [aw=`weight'] ///
	using "`tabout'", append c(col) f(1) npos(row) ///
	h2("Respondent/partner received method from public facility (weighted) - current modern user") 

*******************************************************************************
*
* DEMOGRAPHIC VARIABLES (NOT INCLUDED ON 2-PAGER)
*
*******************************************************************************	

* Distribtuion of de facto women by age
tabout age_cat5 [aw=`weight'] ///
	using "`tabout'",  append c(freq col) f(0 1) clab(n %) npos(row) ///
	h2("Distribution of de facto women by age - weighted")

* Distribution of de facto women by education
tabout school [aw=`weight'] ///
	using "`tabout'",  append c(freq col) f(0 1) clab(n %) npos(row) ///
	h2("Distribution of de facto women by education - weighted")

* Distribution of de facto women by marital status
tabout FQmarital_status [aw=`weight'] ///
	using "`tabout'",  append c(freq col) f(0 1) clab(n %) npos(row) ///
	h2("Distribution of de facto women by marital status - weighted")

* Distribution of de facto women by wealth
tabout `wealth' [aw=`weight'] ///
	using "`tabout'",  append c(freq col) f(0 1) clab(n %) npos(row) ///
	h2("Distribution of de facto women by wealth - weighted")

* Distribution of de facto women by urban/rural
tabout urban [aw=`weight'] ///
	using "`tabout'",  append c(freq col) f(0 1) clab(n %) npos(row) ///
	h2("Distribution of de facto women by urban/rural - weighted")
	


*******************************************************************************
* CLOSE
*******************************************************************************

erase "median_file.dta"
log close
