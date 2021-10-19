/*******************************************************************************
***** PMA Ethiopia Cohort 1 Maternal and Newborn Technical Report .do file *****

*   The following .do file will create the .xlsx file output that PMA Ethiopia used
*	to produce the PMA Ethiopia Six-Week Postpartum Maternal and Newborn Health
	Technical Report, 2019-2021 Cohort, using PMA Ethiopia's publicly 
*	available baseline and 6-week postpartum follow-up dataset. 
*
*
*   If you have any questions on how to use this .do files, please contact 
*	Ellie Qian at jqian@jhu.edu.
*******************************************************************************/


/*******************************************************************************
*
*	FILENAME:		PMAET_Cohort1_6W_MNHTechnicalReport_PR.do
*	PURPOSE:		Generate the .xls output for the PMA Ethiopia 6-week MNH report 
*	CREATED BY: 	Ellie Qian (jqian@jhu.edu)
*	DATA IN:		PMA Ethiopia's publicly released baseline dataset for Cohort 1
*					PMA Ethiopia's publicly released 6-week dataset for Cohort 1
*	DATA OUT: 		PMAET_Cohort1_6W_MNHAnalysis_PR_DATE.dta
*   FILE OUT: 		PMAET_Cohort1_6W_MNHAnalysis_DATE.xlsx (main tables)
*					PMAET_Cohort1_6W_MNHAppendix_DATE.xlsx (appendix)
*   LOG FILE OUT: 	PMAET_Cohort1_6W_MNHAnalysis_PR_DATE.log
*
*******************************************************************************/


/*******************************************************************************
*   
*   INSTRUCTIONS:
*   Please update directories in SECTION 2 to set up and run the .do file
*
*******************************************************************************/


********************************************************************************
**************   SECITON A: STATA SET UP (PLEASE DO NOT DELETE) ****************
*
*   Section A is necessary to make sure the .do file runs correctly, 
*		please do not move, update or delete
*
********************************************************************************

clear
clear matrix
clear mata
capture log close
set more off
numlabel, remove 

********************************************************************************
*********************   SECTION 1: CREATE MACRO FOR DATE   ********************* 
*
*   Section 1 is necessary to make sure the .do file runs correctly, 
*		please do not move, update or delete
*
********************************************************************************

*   Set local/global macros for current date
local today=c(current_date)
local c_today= "`today'"
global date=subinstr("`c_today'", " ", "",.)


********************************************************************************
***********   SECTION 2: SET DIRECTORIES AND DATASET AND OUTPUT ****************
*
*	You will need to set up the macro for the dataset directory. 
*	Additionally, you will need to set up one directory for where you want to 
*		save your Excel output. 
*	For the .do file to run correctly, all macros need to be contained
*  		in quotation marks ("localmacro").
*
********************************************************************************

*** 1. Set directory for the publicly available PMA2020 dataset on your computer
*	- For example (Mac): 
*		local datadir "/Users/ellieee/Desktop/PMAET/Technical_Report/SDP/PublicRelease"
*	- For example (PC):
*		local datadir "C:\Users\annro\PMA2020"

local datadir "/Users/ellieqian/OneDrive - Johns Hopkins/PMAET/Technical_Report/6w/PublicRelease/data"


*** 2. Set directory for the folder where you want to save the dataset, xls and
*			log files that this .do file creates
*		Please note that this should be a path on your LOCAL device, 
*			not any cloud server like Dropbox

*	- For example (Mac): 
*		  local briefdir "/Users/ellieee/Desktop/PMAET/Technical_Report/SDP/PublicRelease"
*	- For example (PC): 
*		  local briefdir "C:\Users\annro\PMAEthiopia\SDPOutput"

local outputdir "/Users/ellieqian/OneDrive - Johns Hopkins/PMAET/Technical_Report/6w/PublicRelease/analysis_$date"

capture mkdir "`outputdir'"

*	Create log
log using "`outputdir'/PMAET_`COHORT'_6W_MNHAnalysis_PR_$date.log", replace

*** 3. Set cohort macro

local COHORT Cohort1 

***	4. Set macros for datasets.
*		We will be merging the baseline and 6-week datasets
*		So both paths need to be specified.

local baselinedata "`datadir'/PMAET_HQFQ_Panel_Cohort1_BL_v2.0_19May2021.dta"
 
local fullsixweekdata "`datadir'/PMAET_Panel_Cohort1_6wkFU_v1.0_19May2021.dta"

********************************************************************************
***************   SECTION 3: MERGING BASELINE AND 6-WEEK DATA ******************
*		
*	In order to analyze indicators by background characteristics,
*		we need to merge the 6-week data with baseline
*
********************************************************************************

cd "`datadir'"

*	Prepare baseline dataset for merge
use "`baselinedata'", clear

*	Confirm that it is Ethiopia Cohort 1 baseline data
gen check=(svy_year=="2019" & country=="Ethiopia" & svy_design=="Panel" & cohort=="Cohort1")
capture confirm var age 
if _rc!=0 {
		replace check=0
	}
	
if check!=1 {
		di in smcl as error "The dataset you are using is not the PMA Ethiopia Cohort1 baseline dataset. This .do file is to generate the .xlsx files for PMA Ethiopia Cohort1 6-Week Maternal and Newborn Health Technical Report only. Please use the Cohort1 baseline dataset and rerun the .do file"
		exit
	}
	drop check
	
drop if participant_ID==""

*	Save as a temporary file
tempfile baselineprep
save `baselineprep'.dta, replace

*	Prepare the full 6-week follow-up dataset for Merge
use "`fullsixweekdata'", clear

*	Confirm that it is Ethiopia Cohort1 6-week data
gen check=(svy_year=="2020" & country=="Ethiopia" & svy_design=="Panel" & cohort=="Cohort1" & cohort_type=="6wkFU")

capture confirm var region
if _rc!=0 {
		replace check=0
	}
	
if check!=1 {
		di in smcl as error "The dataset you are using is not the PMA Ethiopia Cohort1 6-week dataset. This .do file is to generate the .xlsx files for PMA Ethiopia Cohort1 6-Week Maternal and Newborn Health Technical Report only. Please use a the Cohort1 6-week dataset and rerun the .do file"
		exit
	}
	drop check

*	Rename variable name in order to add prefix
rename covid_trust_source_healthworker covid_trust_source_hw

*	Rename all 6-week follow-up variable adding prefix to prevent the data loss 
foreach var of varlist _all {
	rename `var' SW`var'
	}
	
*	Rename variable with redundant prefix and the merge key variable
rename SWSWmetainstanceID SWmetainstanceID
rename SWparticipant_ID participant_ID
rename SWSWFUweight SWFUweight
rename SWSW_result SW_result

*	Drop duplicates
duplicates drop participant_ID, force

*	Save as a temporary file
tempfile fswprep
save `fswprep'.dta, replace

*	Merge prepared baseline, and the full 6-week follow-up datasets
use `baselineprep'.dta, clear
merge 1:1 participant_ID using `fswprep'.dta, gen(sw_merge)

*	Drop women without baseline interview 
drop if sw_merge==2

*	Save the merged baseline and 6-week follow-up dataset
save `COHORT'_Baseline_6wkFU_Merged_$date.dta, replace

********************************************************************************
**********	SECTION 4: RESPONSE RATE AND MEAN TIME TO INTERVIEW ****************
*	
*	Note: Response rate is calculated separately for women who were pregnant 
*			or 0-4 weeks postpartum at enrollment and those who were
*			5-9 weeks postpartum at enrollment.
*		
********************************************************************************

*	Change to output directory and create log
cd "`outputdir'"

*** Reponse rate among pregnant and 0-4 weeks postpartum women *** 
*	Count number of eligible women 
count if SW_result!=. & (baseline_status==1 | baseline_status==2)
local preg_elig = r(N)

*	Count number of eligible women who completed the 6-week interview
count if (baseline_status==1 | baseline_status==2) & SW_result==1
local preg_comp = r(N)

*** Reponse rate among 5-9 weeks postpartum women ***
*	Count number of eligible women 
count if baseline_status==3
local pp_elig = r(N)

*	Count number of eligible women who completed the 6-week interview
count if baseline_status==3 & FRS_result_cc==1
local pp_comp = r(N)

*	Calculate overall response rate
count if (FRS_result_cc!=.& baseline_status==3) | (SW_result!=. & baseline_status!=3)
local tot_elig = r(N)
count if (FRS_result_cc==1 & baseline_status==3) | (SW_result==1 & baseline_status!=3)
local tot_comp = r(N)

local responserate = string((`preg_comp' + `pp_comp') / (`preg_elig' + `pp_elig') * 100, "%4.1f") 

*** Set up putexcel and output 
putexcel set PMAET_Cohort1_6W_MNHAnalysis_$date.xlsx, sheet(Table1) replace
putexcel A1="Table 1. Six-Week Postpartum Follow-up Interview Response Rate and Mean Time to Interview", bold underline
putexcel A2=("Response rate"), bold
putexcel (A2:D2) (B6:D6), merge hcenter vcenter 
putexcel B3=("Total") C3=("Pregnant or 0-4 weeks postpartum") D3=("5-9 weeks postpartum"), hcenter
putexcel A4=("Number of eligible women") A5=("Number of eligible women who completed the interview") A6=("6-week interview response rate"), left
putexcel B4=(`tot_elig') C4=(`preg_elig') D4=(`pp_elig') B5=(`tot_comp') C5=(`preg_comp') D5=(`pp_comp') B6=`responserate', hcenter 

*** Mean time to interview *** 

*** Restrict analysis to women who completed questionnaire 
keep if (baseline_status!=3 & SW_result==1) | ///
		(baseline_status==3 & FRS_result==1)
		
*** Pregnancy Outcome
* 	Replace 6-week data with baseline for 5-9 weeks postpartum women
replace SWpregnancy_type=pregnancy_type if baseline_status==3
replace SWbirth1_outcome_cc=birth1_outcome if baseline_status==3
replace SWbirth2_outcome_cc=birth2_outcome if baseline_status==3
replace SWbirth1_outcome_cc=-99 if SWpregnancy_type==-99 | SWbirth1_outcome_cc==.

***	Restrict analysis to women with LIVE or STILL BIRTHS
drop if SWbirth1_outcome_cc==3 | SWbirth1_outcome_cc==4 | SWbirth1_outcome_cc==-99	

*** Set survey weights
*	Create weight for all women with complete forms
gen SWweight=FQweight if baseline_status==3
replace SWweight=SWFUweight if SW_result!=.
svyset EA_ID [pweight=SWweight], strata(strata) singleunit(scaled)


*================== Final analytic sample size: 2,557 =========================*


*	Replace weeks postpartum for 5-9 weeks postpartum women 
replace SWrecent_birth_w_ago = recent_birth_w_ago if baseline_status==3

*	Replace questionnaire version for 5-9 weeks postpartum women
*	All baseline interviews were conducted pre-COVID
replace SWQREversion="In-person pre-COVID" if baseline_status==3

*** Summarize mean weeks postpartum
sum SWrecent_birth_w_ago [aw=SWweight]
local tot_num = r(N)
local mean_overall = string(r(mean), "%4.1f")

sum SWrecent_birth_w_ago [aw=SWweight] if SWQREversion =="In-person post-COVID" 
local tot_postcovid = r(N)
local mean_postcovid = string(r(mean), "%4.1f")

sum SWrecent_birth_w_ago  [aw=SWweight] if SWQREversion =="In-person pre-COVID"
local tot_precovid = r(N)
local mean_precovid = string(r(mean), "%4.1f")

*** Output to Excel
putexcel A7=("Mean number of weeks postpartum at time of interview"), bold
putexcel (A7:D7), merge hcenter vcenter 
putexcel B8=("Number of women") C8=("Number of weeks postpartum"), hcenter
putexcel A9=("Overall") A10=("Pre-COVID") A11=("During COVID"), left
putexcel B9=(`tot_num') C9=(`mean_overall') B10=(`tot_precovid') C10=(`mean_precovid') B11=`tot_postcovid' C11=`mean_postcovid', hcenter 
putexcel (C9:D9) (C10:D10) (C11:D11), merge hcenter vcenter


********************************************************************************
******************   SECTION 5: BACKGROUND CHARACTERISTICS *********************
********************************************************************************

*	Generate age categories
egen age5=cut(FQ_age), at(15(5)50)
gen age_new=age5
replace age_new=40 if age5>=40
label define age_newl 15 "15-19" 20 "20-24" 25 "25-29" 30 "31-34" 35 "35-39" 40 "40-49" 
label val age_new age_newl
label var age_new "Age"

*	Recode age for putexcel
recode age_new (15=1) (20=2) (25=3) (30=4) (35=5) (40=6), gen(age_recode)
label define age_recodel 1 "15-19" 2 "20-24" 3 "25-29" 4 "31-34" 5 "35-39" 6 "40-49" 
label val age_recode age_recodel
label var age_recode "Age"
tab age_recode

*	Generate 0/1 urban/rural variable
gen urban=ur==1
label variable urban "Urban/rural place of residence"
label define urban 1 "Urban" 0 "Rural"
label val urban urban 

*	Recode residence for putexcel
recode urban (0=1) (1=2), gen(urban_recode)
label define urban_recodel 1 "Rural" 2 "Urban"
label val urban_recode urban_recodel 
label variable urban_recode "Residence"
tab urban_recode

*	Group technical & vocational with higher education 
gen education=school
replace education=3 if school>=3
lab def edul 0 "No education" 1 "Primary" 2 "Secondary" 3 "More than secondary"
lab val education edul
lab var education "Education level" 

*	Recode education for putexcel
recode education (0=1) (1=2) (2=3) (3=4), gen(education_recode)
label define edu_recodel 1 "No education" 2 "Primary" 3 "Secondary" 4 "More than secondary"
label val education_recode edu_recodel
label var education_recode "Education"
tab education_recode

*	Impute missing parity
replace birth_events_rw=. if birth_events_rw==-99
bysort FQ_age wealthquintile urban region education: replace birth_events_rw=birth_events_rw[_n+2] if birth_events_rw==.

*	Generate categorical variable for parity 
egen parity4=cut(birth_events_rw), at(0, 1, 3, 5, 30) icodes
replace parity4=0 if birth_events_rw==.
lab def parity4l 0 "0 children" 1 "1-2 children" 2 "3-4 children" 3 "5+ children"
lab val parity4 parity4l
lab var parity4 "Parity" 

*	Recode parity for putexcel
recode parity4 (0=1) (1=2) (2=3) (3=4), gen(parity_recode)
label define parity_recodel 1 "0 children" 2 "1-2 children" 3 "3-4 children" 4 "5+ children"
label val parity_recode parity_recodel
label var parity_recode "Parity"
tab parity_recode

*	Recode region for putexcel
recode region (7=5) (10=6), gen(region_recode)
label define region_list 1 "Tigray" 2 "Afar" 3 "Amhara" 4 "Oromiya" 5 "SNNP" 6 "Addis", modify
label val region_recode region_list
label var region_recode "Region"

*	Remove numbers from wealth quintile label 
label define wealthquintile_list 1 "Lowest quintile" 2 "Lower quintile" 3 "Middle quintile" 4 "Higher quintile" 5 "Highest quintile", modify


*** Set up putexcel and output 
putexcel set PMAET_Cohort1_6W_MNHAnalysis_$date.xlsx, sheet(Table2) modify
putexcel A1=("Table 2. Background Characteristics of Respondents"), bold underline
putexcel A2=("Percent distribution of respondents by selected background characteristics and birth outcomes, PMA Ethiopia 2019-2021 Cohort") A3=("Background characteristics") B3=("Weighted percent") C3=("Weighted N") D3=("Unweighted N")
putexcel A4=("Age") A12=("Education") A18=("Parity") A24=("Region") A32=("Residence") A36=("Wealth") A43=("Pregnancy outcome"), bold

local row = 5
foreach RowVar in age_new education parity4 region urban wealthquintile SWbirth1_outcome_cc {
	tabulate `RowVar', matcell(freq) matrow(names)
	local rows = rowsof(names)
	local RowValueLabel : value label `RowVar'
	
	svy: tab `RowVar'		
	tabulate `RowVar' [aw=SWweight], matcell(a)
	
	putexcel B`row'=matrix(e(Prop)*100), left nformat(0.0)
	putexcel C`row'=matrix(a) D`row'=matrix(e(Obs)), left nformat(number_sep)
	
	forvalues i = 1/`rows' {

			local val = names[`i',1]
			local val_lab : label `RowValueLabel' `val'
				
			putexcel A`row'=("`val_lab'") 
			local row = `row' + 1
		}

	local row=`row'+2
	}
	
********************************************************************************
***********************   SECTION 6: ANC UTILIZATION  **************************
********************************************************************************

*** Overall utilization ***

*	Replace 6w data with baseline for 5-9 pp women at enrollment
foreach var in anc_hew_num anc_phcp_num anc_hew_yn anc_phcp_yn  {
		replace SW`var'= `var'_pp if baseline_status==3
	}
	
foreach var of varlist pregprob_migraine-pregprob_vision {
		replace SW`var'= `var'_pp if baseline_status==3
	}

foreach var of varlist anc_hew_place-anc_hew_place_other anc_hew_timing anc_phcp_provider-anc_phcp_other anc_phcp_timing anc_phcp_place-anc_ppfp_couns anc_nd_info_yn anc_nd_info_iron anc_nd_info_deworm pregprob_trt_migraine-anc_disc_1x5meet {
		replace SW`var'= `var' if baseline_status==3
	}
	
*	Total number of ANC
recode SWanc_hew_num(-88 .=0) 
recode SWanc_phcp_num(-88 .=0) 

gen tot_anc=SWanc_hew_num+SWanc_phcp_num
recode tot_anc (1/3=3) (4/16 =4), gen(total_anc)
label define anc_num_l 0 "0 visits" 3 "1-3 visits" 4 "4+ visits"
label val total_anc anc_num_l
label var total_anc "Number of ANC visit"
tab total_anc, m

*** Any ANC ***

gen anyanc=0
replace anyanc=1 if total_anc!=0
label val anyanc yes_no_list
label var anyanc "Received any ANC"
tab anyanc, m

*** 4+ ANC *** 

gen ANC4=0
replace ANC4=1 if total_anc>=4
label val ANC4 yes_no_list
label var ANC4 "Received 4+ ANC" 

*	Set up putexcel
putexcel set "PMAET_Cohort1_6W_MNHAnalysis_$date.xlsx", sheet("Table3") modify
putexcel A1=("Table 3. Antenatal Care Utalization"), bold underline
putexcel A2=("Percent distribution of women who received any antenatal care (ANC) and 4+ ANC among all women, by background characteristics, PMA Ethiopia 2019-2021 Cohort"), italic
putexcel B3=("Any ANC") C3=("4+ ANC") D3=("Number of women (weighted)") 
putexcel A4=("Age") A12=("Education") A18=("Parity") A24=("Region") A32=("Residence") A36=("Wealth") A44=("Overall"), bold

*	Any ANC and 4+ ANC by background characteristics
local row = 5
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile  {

	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SWweight], matcell(a)
	putexcel D`row'=matrix(a), left nformat(number_sep)

	forvalues i = 1/`RowCount' {
		sum anyanc if `RowVar'==`i' [aw=SWweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum ANC4 if `RowVar'==`i' [aw=SWweight]
			local mean2: disp %3.1f r(mean)*100

			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2'), left nformat(0.0)	
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	Any ANC and 4+ ANC overall
sum anyanc [aw=SWweight]
local mean1: disp %3.1f r(mean)*100
sum ANC4 [aw=SWweight]
local mean2: disp %3.1f r(mean)*100
count
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2'), left nformat(0.0)	
putexcel D`row'=(`n_1'), left nformat(number_sep)	

**** ANC provider ***

gen anc_provider=0 
replace anc_provider=1 if SWanc_hew_yn==1 & SWanc_phcp_yn==0
replace anc_provider=2 if SWanc_hew_yn==0 & SWanc_phcp_yn==1
replace anc_provider=3 if SWanc_hew_yn==1 & SWanc_phcp_yn==1
replace anc_provider=0 if anyanc==0
label define providerl 0 "No ANC" 1 "HEW only" 2 "PHCP only" 3 "Both"
label val anc_provider providerl
tab anc_provider

*	Generate binary variables for provider type 
gen noanc=0
replace noanc=1 if anc_provider==0
gen provider_hew=0
replace provider_hew=1 if anc_provider==1
gen provider_phcp=0
replace provider_phcp=1 if anc_provider==2
gen provider_both=0
replace provider_both=1 if anc_provider==3

*	Set up putexcel
putexcel set "PMAET_Cohort1_6W_MNHAnalysis_$date.xlsx", sheet("Table4") modify
putexcel A1=("Table 4. ANC Provider Type"), bold underline
putexcel A2=("Percent distribution respondents who received no ANC, ANC from a health extension worker (HEW) only, professional health care provider (PHCP) only, and both providers, among all women, by background characteristics, PMA Ethiopia 2019-2021 Cohort"), italic
putexcel B3=("No ANC") C3=("HEW only") D3=("PHCP only") E3=("Both") F3=("Number of women (weighted)") 
putexcel A4=("Age") A12=("Education") A18=("Parity") A24=("Region") A32=("Residence") A36=("Wealth") A44=("Overall"), bold

*	ANC provider type by background characteristics
local row = 5
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile {

	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SWweight], matcell(a)
	putexcel F`row'=matrix(a), left nformat(number_sep)

	forvalues i = 1/`RowCount' {
		sum noanc if `RowVar'==`i' [aw=SWweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum provider_hew if `RowVar'==`i' [aw=SWweight]
			local mean2: disp %3.1f r(mean)*100
			
			sum provider_phcp if `RowVar'==`i' [aw=SWweight]
			local mean3: disp %3.1f r(mean)*100
			
			sum provider_both if `RowVar'==`i' [aw=SWweight]
			local mean4: disp %3.1f r(mean)*100

			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4'), left nformat(0.0)	
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	ANC provider type overall
sum noanc [aw=SWweight]
local mean1: disp %3.1f r(mean)*100
sum provider_hew [aw=SWweight]
local mean2: disp %3.1f r(mean)*100
sum provider_phcp [aw=SWweight]
local mean3: disp %3.1f r(mean)*100
sum provider_both [aw=SWweight]
local mean4: disp %3.1f r(mean)*100
count
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4'), left nformat(0.0)	
putexcel F`row'=(`n_1'), left nformat(number_sep)	


*** Number of ANC ***
*	Recode number of ANC for putexcel
recode total_anc (0=1) (3=2) (4=3)
label define anc_num_l 1 "0 visits" 2 "1-3 visits" 3 "4+ visits", modify
label val total_anc anc_num_l

**** ANC timing ***

gen anc_timing=SWanc_phcp_timing 
replace anc_timing=SWanc_hew_timing if SWanc_hew_timing<SWanc_phcp_timing
replace anc_timing=0 if anyanc==0
replace anc_timing=-88 if anyanc==1 & (anc_timing==0 | anc_timing==.) 
recode anc_timing  (1/3=1) (4/6=2) (7/9=3) , gen(anc_timing_month)  
label define anc_month_list  -88 "DNK or missing" 0 "No ANC" 1 "0-3 months" 2 "4-6 months" 3 "7-9+ months"	
label val anc_timing_month anc_month_list
tab anc_timing_month

*	Recode ANC timing for putexcel
recode anc_timing_month (0=1) (1=2) (2=3) (3=4) (-88=5), gen(anc_timing_recode)
label define anc_month_recode 1 "No ANC" 2 "0-3 months" 3 "4-6 months" 4 "7-9+ months"	5 "DNK or missing" 
label val anc_timing_recode anc_month_recode
tab anc_timing_month

*	Set up putexcel
putexcel set "PMAET_Cohort1_6W_MNHAnalysis_$date.xlsx", sheet("Table5") modify
putexcel A1=("Table 5. Number and Timing of ANC"), bold underline
putexcel A2=("Percent distribution of women who had 0, 1-3, and 4+ ANC, and timing at first ANC visits, among all women, by residence, PMA Ethiopia 2019-2021 Cohort"), italic
putexcel B3=("Rural") C3=("Urban") D3=("Total")
putexcel A4=("Number of ANC visit") A9=("Number of months pregnant at time of first ANC visit") A17=("Mean gestational age (in months) at first ANC visit (among those with ANC )"), bold
putexcel A8=("Total") A15=("Total") A16=("Number of women (weighted)") A18=("Number of women with ANC (weighted)")
putexcel B8=(100) C8=(100) D8=(100) B15=(100) C15=(100) D15=(100), left nformat(0.0)

local row = 5
foreach RowVar in total_anc anc_timing_recode {
	tabulate `RowVar', matcell(freq) matrow(names)
	local rows = rowsof(names)
	local RowValueLabel : value label `RowVar'
	
	svy: tab `RowVar' if urban_recode==1	
	putexcel B`row'=matrix(e(Prop)*100), left nformat(0.0)
	
	svy: tab `RowVar' if urban_recode==2	
	putexcel C`row'=matrix(e(Prop)*100), left nformat(0.0)
	
	svy: tab `RowVar'		
	putexcel D`row'=matrix(e(Prop)*100), left nformat(0.0)
	
	forvalues i = 1/`rows' {

			local val = names[`i',1]
			local val_lab : label `RowValueLabel' `val'
				
			putexcel A`row'=("`val_lab'") 
				
			local row = `row' + 1
		}
	local row=`row'+2
	}
	
*	Number of women (weighted) by residence
tabulate urban_recode [aw=SWweight], matcell(a)
mat b = matrix(a)'
count
local n=r(N)

local row=`row'-1
putexcel B`row'=matrix(b), left nformat(number_sep)
putexcel D`row'=(`n'), left nformat(number_sep)

*	Mean GA overall 
sum anc_timing if anyanc==1 & anc_timing!=. & anc_timing!=-88 & anc_timing!=-99 [aw=SWweight] 
local mean_ga_all=r(mean)
count if anyanc==1 & anc_timing!=. & anc_timing!=-88 & anc_timing!=-99
local anyanc_all=r(N)

*	Mean GA for urban women 
sum anc_timing if anyanc==1 & anc_timing!=. & anc_timing!=-88 & anc_timing!=-99 & urban_recode==2 [aw=SWweight] 
local mean_ga_urban=r(mean)

*	Mean GA for rural women
sum anc_timing if anyanc==1 & anc_timing!=. & anc_timing!=-88 & anc_timing!=-99 & urban_recode==1 [aw=SWweight] 
local mean_ga_rural=r(mean)

local row=`row'+1
putexcel B`row'=(`mean_ga_rural') C`row'=(`mean_ga_urban') D`row'=(`mean_ga_all'), left nformat(0.0)

*	Number of women with any ANC by residence (weighted)
local row=`row'+1

tabulate urban_recode [aw=SWweight] if anyanc==1 & anc_timing!=. & anc_timing!=-88 & anc_timing!=-99, matcell(a)
mat b = matrix(a)'
putexcel B`row'=matrix(b), left nformat(number_sep)

putexcel D`row'=(`anyanc_all'), left nformat(number_sep)


********************************************************************************
**		ANC CONTENT (NUTRITION, BIRTH READINESS, ASSESSMENT, STI, 1to5)		 **		
**					 		AMONG ALL WOMEN							  		**
********************************************************************************

*** Nutrition counseling *** 

*	General nutrition counseling
recode SWanc_nd_info_yn (.=0)
replace SWanc_nd_info_yn=0 if anyanc==0
label var SWanc_nd_info_yn "Received general nutrition counseling at ANC"

*	Iron counseling
recode SWanc_nd_info_iron (.=0)
replace SWanc_nd_info_iron=0 if anyanc==0
label var SWanc_nd_info_iron "Received iron counseling at ANC"

*	De-worming medication counseling 
recode SWanc_nd_info_deworm (.=0)
replace SWanc_nd_info_deworm=0 if anyanc==0
label var SWanc_nd_info_deworm "Received de-worming medication counseling at ANC"

*	Set up putexcel
putexcel set "PMAET_Cohort1_6W_MNHAnalysis_$date.xlsx", sheet("Table6") modify
putexcel A1=("Table 6. Content of ANC - Nutritional Counseling (all women)"), bold underline
putexcel A2=("Percent distribution of respondents who received general nutrition counseling and counseling on taking iron/folate supplements and deworming medications, by background characteristics, PMA Ethiopia 2019-2021 Cohort"), italic
putexcel B3=("General nutrition counseling") C3=("Iron and folate counseling") D3=("Deworming medication counseling") E3=("Number of women (weighted)") 
putexcel A4=("Age") A12=("Education") A18=("Parity") A24=("Region") A32=("Residence") A36=("Wealth") A44=("Overall"), bold

*	Nutritional counseling by background characteristics
local row = 5
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile {

	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SWweight], matcell(a)
	putexcel E`row'=matrix(a), left nformat(number_sep)

	forvalues i = 1/`RowCount' {
		sum SWanc_nd_info_yn if `RowVar'==`i' [aw=SWweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum SWanc_nd_info_iron if `RowVar'==`i' [aw=SWweight]
			local mean2: disp %3.1f r(mean)*100
			
			sum SWanc_nd_info_deworm if `RowVar'==`i' [aw=SWweight]
			local mean3: disp %3.1f r(mean)*100

			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3'), left nformat(0.0)	
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	Nutritional counseling overall
sum SWanc_nd_info_yn [aw=SWweight]
local mean1: disp %3.1f r(mean)*100
sum SWanc_nd_info_iron [aw=SWweight]
local mean2: disp %3.1f r(mean)*100
sum SWanc_nd_info_deworm [aw=SWweight]
local mean3: disp %3.1f r(mean)*100
count
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3'), left nformat(0.0)	
putexcel E`row'=(`n_1'), left nformat(number_sep)	

*** Birth readiness counseling ***  
 
foreach var in SWanc_disc_delivplace SWanc_disc_skilled SWanc_disc_danger_place SWanc_disc_transport SWanc_disc_danger_migraine SWanc_disc_danger_hbp SWanc_disc_danger_edema SWanc_disc_danger_convuls SWanc_disc_danger_bleeding {
		recode `var' (-99 -88 . =0) 
	}

*	All 9 topics
gen all_dis=0
replace all_dis=1 if SWanc_disc_delivplace==1 & SWanc_disc_skilled==1 & SWanc_disc_danger_place==1 & SWanc_disc_transport==1 & SWanc_disc_danger_migraine==1 & SWanc_disc_danger_hbp==1 & SWanc_disc_danger_edema==1 & SWanc_disc_danger_convuls==1 & SWanc_disc_danger_bleeding==1
			
*	Set up putexcel
putexcel set "PMAET_Cohort1_6W_MNHAnalysis_$date.xlsx", sheet("Table7") modify
putexcel A1=("Table 7. Content of ANC - Birth Preparedness Discussion (all women)"), bold underline
putexcel A2=("Percent distribution of respondents who received counseling on each birth preparedness topic, including place of delivery, delivery by a skilled birth attendant, arrangement of delivery transport, where to go when experiencing pregnancy danger signs, severe headaches with blurred vision, high blood pressure, edema, convulsions, and bleeding before delivery as a danger sign, by background characteristics, PMA Ethiopia 2019-2021 Cohort"), italic
putexcel A3=("Background characteristics" )B3=("Place of delivery") C3=("Skilled birth attendant") D3=("Delivery transport") E3=("Where to go when in danger") F3=("Severe headaches")G3=("High blood pressure") H3=("Edema") I3=("Convulsions") J3=("Bleeding before delivery") K3=("All 9 topics") L3=("Number of women (weighted)")
putexcel A4=("Age") A12=("Education") A18=("Parity") A24=("Region") A32=("Residence") A36=("Wealth") A44=("Overall"), bold

*	Birth readiness discussion by background characteristics
local row = 5
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile {
        
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SWweight], matcell(a)
	putexcel L`row'=matrix(a), left nformat(number_sep)

	forvalues i = 1/`RowCount' {
		sum SWanc_disc_delivplace if `RowVar'==`i' [aw=SWweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum SWanc_disc_skilled if `RowVar'==`i' [aw=SWweight]
			local mean2: disp %3.1f r(mean)*100
			
			sum SWanc_disc_transport if `RowVar'==`i' [aw=SWweight]
			local mean3: disp %3.1f r(mean)*100
			
			sum SWanc_disc_danger_place if `RowVar'==`i' [aw=SWweight]
			local mean4: disp %3.1f r(mean)*100

			sum SWanc_disc_danger_migraine if `RowVar'==`i' [aw=SWweight]
			local mean5: disp %3.1f r(mean)*100
			
			sum SWanc_disc_danger_hbp if `RowVar'==`i' [aw=SWweight]
			local mean6: disp %3.1f r(mean)*100

			sum SWanc_disc_danger_edema if `RowVar'==`i' [aw=SWweight]
			local mean7: disp %3.1f r(mean)*100
			
			sum SWanc_disc_danger_convuls if `RowVar'==`i' [aw=SWweight]
			local mean8: disp %3.1f r(mean)*100

			sum SWanc_disc_danger_bleeding if `RowVar'==`i' [aw=SWweight]
			local mean9: disp %3.1f r(mean)*100
			
			sum all_dis if `RowVar'==`i' [aw=SWweight]
			local mean10: disp %3.1f r(mean)*100
			
			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6') H`row'=(`mean7') I`row'=(`mean8') J`row'=(`mean9') K`row'=(`mean10'), left nformat(0.0)	
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	Birth readiness discussion overall
sum SWanc_disc_delivplace [aw=SWweight]
local mean1: disp %3.1f r(mean)*100
sum SWanc_disc_skilled [aw=SWweight]
local mean2: disp %3.1f r(mean)*100
sum SWanc_disc_danger_place [aw=SWweight]
local mean3: disp %3.1f r(mean)*100
sum SWanc_disc_transport [aw=SWweight]
local mean4: disp %3.1f r(mean)*100
sum SWanc_disc_danger_migraine [aw=SWweight]
local mean5: disp %3.1f r(mean)*100
sum SWanc_disc_danger_hbp [aw=SWweight]
local mean6: disp %3.1f r(mean)*100
sum SWanc_disc_danger_edema [aw=SWweight]
local mean7: disp %3.1f r(mean)*100
sum SWanc_disc_danger_convuls [aw=SWweight]
local mean8: disp %3.1f r(mean)*100
sum SWanc_disc_danger_bleeding [aw=SWweight]
local mean9: disp %3.1f r(mean)*100
sum all_dis [aw=SWweight]
local mean10: disp %3.1f r(mean)*100
count
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6') H`row'=(`mean7') I`row'=(`mean8') J`row'=(`mean9') K`row'=(`mean10'), left nformat(0.0)	
putexcel L`row'=(`n_1'), left nformat(number_sep)			

*** Maternal assessment *** 

*	Recode missing and DNK to 0
foreach var in anc_bp anc_weight anc_urine anc_blood anc_stool  {
		recode SW`var' (-88 -99 .=0) 
	}

*	All 5 assessment
gen all_assess=0
replace all_assess=1 if SWanc_bp==1 & SWanc_weight==1 & SWanc_urine==1 & SWanc_blood==1 & SWanc_stool==1 

*	Set up putexcel
putexcel set "PMAET_Cohort1_6W_MNHAnalysis_$date.xlsx", sheet("Table8") modify
putexcel A1=("Table 8. Content of ANC - Maternal Assessment (all women)"), bold underline
putexcel A2=("Percent distribution of respondents who had their weight, blood pressure, urine, blood, and stool sample taken at ANC and the proportion of women who received all 5 maternal assessments, among all women, by background characteristics, PMA Ethiopia 2019-2021 Cohort"), italic
putexcel A3=("Background characteristics" ) B3=("Blood pressure taken") C3=("Weight taken") D3=("Urine sample taken") E3=("Blood sample taken") F3=("Stool sample taken") G3=("All 5 assessments") H3=("Number of women (weighted)")
putexcel A4=("Age") A12=("Education") A18=("Parity") A24=("Region") A32=("Residence") A36=("Wealth") A44=("Overall"), bold

*	Maternal assessment by background characteristics
local row = 5
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile {
        
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SWweight], matcell(a)
	putexcel H`row'=matrix(a), left nformat(number_sep)

	forvalues i = 1/`RowCount' {
		sum SWanc_bp if `RowVar'==`i' [aw=SWweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum SWanc_weight if `RowVar'==`i' [aw=SWweight]
			local mean2: disp %3.1f r(mean)*100
			
			sum SWanc_urine if `RowVar'==`i' [aw=SWweight]
			local mean3: disp %3.1f r(mean)*100
			
			sum SWanc_blood if `RowVar'==`i' [aw=SWweight]
			local mean4: disp %3.1f r(mean)*100

			sum SWanc_stool if `RowVar'==`i' [aw=SWweight]
			local mean5: disp %3.1f r(mean)*100
			
			sum all_assess if `RowVar'==`i' [aw=SWweight]
			local mean6: disp %3.1f r(mean)*100
			
			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6'), left nformat(0.0)	
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	Maternal assessment overall
sum SWanc_bp [aw=SWweight]
local mean1: disp %3.1f r(mean)*100
sum SWanc_weight [aw=SWweight]
local mean2: disp %3.1f r(mean)*100
sum SWanc_urine [aw=SWweight]
local mean3: disp %3.1f r(mean)*100
sum SWanc_blood [aw=SWweight]
local mean4: disp %3.1f r(mean)*100
sum SWanc_stool [aw=SWweight]
local mean5: disp %3.1f r(mean)*100
sum all_assess [aw=SWweight]
local mean6: disp %3.1f r(mean)*100
count
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6'), left nformat(0.0)	
putexcel H`row'=(`n_1'), left nformat(number_sep)			

*** Postpartum family planning  *** 
recode SWanc_ppfp_couns (-99 -88 .=0)

*	Set up putexcel
putexcel set "PMAET_Cohort1_6W_MNHAnalysis_$date.xlsx", sheet("Table9") modify
putexcel A1=("Table 9. Content of ANC - Postpartum Family Planning Counselling (all women)"), bold underline
putexcel A2=("Percent distribution of respondents who received postpartum family planning counseling at ANC, by background characteristics, PMA Ethiopia 2019-2021 Cohort"), italic
putexcel A3=("Background characteristics" ) B3=("Percent") C3=("Number of women (weighted)")
putexcel A4=("Age") A12=("Education") A18=("Parity") A24=("Region") A32=("Residence") A36=("Wealth") A44=("Overall"), bold

*	PPFP counseling by background characteristics
local row = 5
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile {
        
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SWweight], matcell(a)
	putexcel C`row'=matrix(a), left nformat(number_sep)

	forvalues i = 1/`RowCount' {
		sum SWanc_ppfp_couns if `RowVar'==`i' [aw=SWweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			putexcel A`row'=("`CellContents'") B`row'=(`mean1'), left nformat(0.0)	
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	PPFP counselling overall
sum SWanc_ppfp_couns [aw=SWweight]
local mean1: disp %3.1f r(mean)*100
count
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1'), left nformat(0.0)	
putexcel C`row'=(`n_1'), left nformat(number_sep)	

*** STI testing *** 

*	Recode missing and DNK to 0
foreach var in syph_test syph_result syph_couns hiv_test hiv_result hiv_couns {
		recode SWanc_`var' (-99 -88 . = 0)
		local SWanc_`var'_lab: variable label SWanc_`var'
	}
	
*	Replace to 0 if no ANC received
replace SWanc_hiv_test=0 if anyanc==0
replace SWanc_syph_test=0 if anyanc==0

*	Set up putexcel
putexcel set "PMAET_Cohort1_6W_MNHAnalysis_$date.xlsx", sheet("Table10") modify
putexcel A1=("Table 10. Content of ANC - HIV and Syphilis Testing (all women)"), bold underline
putexcel A2=("Percent distribution of respondents who received HIV and Syphilis testing, test results, and test counseling at ANC, among all women, by background characteristics, PMA Ethiopia 2019-2021 Cohort"), italic
putexcel A3=("Background characteristics" ) B3=("HIV testing") C3=("Syphilis testing") D3=("Number of women (weighted)") E3=("HIV result") F3=("HIV counseling") G3=("Number of women with HIV test (weighted)") H3=("Syphilis result") I3=("Syphilis counseling")  J3=("Number of women with syphilis test (weighted)")  
putexcel A4=("Age") A12=("Education") A18=("Parity") A24=("Region") A32=("Residence") A36=("Wealth") A44=("Overall"), bold

*	STI testing by background characteristics
local row = 5
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile {
        
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SWweight], matcell(a)
	putexcel D`row'=matrix(a), left nformat(number_sep)
	
	tabulate `RowVar' [aw=SWweight] if SWanc_hiv_test==1 , matcell(b)
	putexcel G`row'=matrix(b), left nformat(number_sep)
	
	tabulate `RowVar' [aw=SWweight] if SWanc_syph_test==1, matcell(c)
	putexcel J`row'=matrix(c), left nformat(number_sep)
	

	forvalues i = 1/`RowCount' {
		sum SWanc_hiv_test if `RowVar'==`i' [aw=SWweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum SWanc_syph_test if `RowVar'==`i' [aw=SWweight]
			local mean2: disp %3.1f r(mean)*100
			
			sum SWanc_hiv_result if `RowVar'==`i' & SWanc_hiv_test==1 [aw=SWweight]
			local mean3: disp %3.1f r(mean)*100
			
			sum SWanc_hiv_couns if `RowVar'==`i'  & SWanc_hiv_test==1 [aw=SWweight]
			local mean4: disp %3.1f r(mean)*100

			sum SWanc_syph_result if `RowVar'==`i' & SWanc_syph_test==1 [aw=SWweight]
			local mean5: disp %3.1f r(mean)*100
			
			sum SWanc_syph_couns if `RowVar'==`i' & SWanc_syph_test==1 [aw=SWweight]
			local mean6: disp %3.1f r(mean)*100
			
			count if `RowVar'==`i' & SWanc_hiv_test==1 
			local n_1=r(N)
			
			count if `RowVar'==`i' & SWanc_syph_test==1 
			local n_2=r(N)
			
			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') E`row'=(`mean3') F`row'=(`mean4') H`row'=(`mean5') I`row'=(`mean6'), left nformat(0.0)	
			
			*	Suppress output with insufficient sample size
			if `n_1' <= 49 & `n_1' > 24 {
				putexcel E`row'=("(`mean3')") F`row'=("(`mean4')"), left nformat(0.0)	
				}
			if `n_1' <= 24 {
				putexcel E`row'=("*") F`row'=("*")
				}
				
			if `n_2' <= 49 & `n_2' > 24 {
				putexcel H`row'=("(`mean5')") I`row'=("(`mean6')"), left nformat(0.0)	
				}
			if `n_2' <= 24 {
				putexcel H`row'=("*") I`row'=("*")	
				}
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	STI testing overall
sum SWanc_hiv_test [aw=SWweight]
local mean1: disp %3.1f r(mean)*100
sum SWanc_syph_test [aw=SWweight]
local mean2: disp %3.1f r(mean)*100
count
if r(N)!=0 local n_1= r(N)

sum SWanc_hiv_result if SWanc_hiv_test==1 [aw=SWweight]
local mean3: disp %3.1f r(mean)*100
sum SWanc_hiv_couns if SWanc_hiv_test==1 [aw=SWweight]
local mean4: disp %3.1f r(mean)*100
count if SWanc_hiv_test==1 
if r(N)!=0 local n_2= r(N)

sum SWanc_syph_result if SWanc_syph_test==1 [aw=SWweight]
local mean5: disp %3.1f r(mean)*100
sum SWanc_syph_couns if SWanc_syph_test==1 [aw=SWweight]
local mean6: disp %3.1f r(mean)*100
count if SWanc_syph_test==1
if r(N)!=0 local n_3= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') E`row'=(`mean3') F`row'=(`mean4') H`row'=(`mean5') I`row'=(`mean6') J`row'=(`n_3'), left nformat(0.0)	
putexcel D`row'=(`n_1') G`row'=(`n_2') J`row'=(`n_3'), left nformat(number_sep)			

local row=`row'+2
putexcel A`row'=("NOTE: Estimates based on 25-49 unweighted samples are reported inside parentheses in the report. Estimates based on less than 25 unweighted samples are suppressed."), italic

*** 1to5 meeting *** 

*	Generate binary variables for types of participation 
gen meeting_nr=0
replace meeting_nr=1 if SWanc_disc_1x5meet==-99
gen meeting_yes=0
replace meeting_yes=1 if SWanc_disc_1x5meet==1
gen meeting_no=0
replace meeting_no=1 if SWanc_disc_1x5meet==2
gen meeting_notmember=0
replace meeting_notmember=1 if SWanc_disc_1x5meet==3

*	Set up putexcel
putexcel set "PMAET_Cohort1_6W_MNHAnalysis_$date.xlsx", sheet("Table11") modify
putexcel A1=("Table 11. One-to-five Meeting Participation"), bold underline
putexcel A2=("Percent distribution of women who participated in a one-to-five meeting during pregnancy, among all women, by background characteristics, PMA Ethiopia 2019-2021 Cohort"), italic
putexcel A3=("Background characteristics" ) B3=("Yes") C3=("No, member but did not participate") D3=("No, not a member") E3=("No response") F3=("Number of women (weighted)")
putexcel A4=("Age") A12=("Education") A18=("Parity") A24=("Region") A32=("Residence") A36=("Wealth") A44=("Overall"), bold

*	1to5 by background characteristics
local row = 5
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile {
        
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SWweight], matcell(a)
	putexcel F`row'=matrix(a), left nformat(number_sep)

	forvalues i = 1/`RowCount' {
		sum meeting_yes if `RowVar'==`i' [aw=SWweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum meeting_no if `RowVar'==`i' [aw=SWweight]
			local mean2: disp %3.1f r(mean)*100
			
			sum meeting_notmember if `RowVar'==`i' [aw=SWweight]
			local mean3: disp %3.1f r(mean)*100
			
			sum meeting_nr if `RowVar'==`i' [aw=SWweight]
			local mean4: disp %3.1f r(mean)*100
			
			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') , left nformat(0.0)	
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	1to5 overall
sum meeting_yes [aw=SWweight]
local mean1: disp %3.1f r(mean)*100
sum meeting_no [aw=SWweight]
local mean2: disp %3.1f r(mean)*100
sum meeting_notmember [aw=SWweight]
local mean3: disp %3.1f r(mean)*100
sum meeting_nr [aw=SWweight]
local mean4: disp %3.1f r(mean)*100
count
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4'), left nformat(0.0)	
putexcel F`row'=(`n_1'), left nformat(number_sep)	


********************************************************************************
*** AMONG WOMEN WITH ANC (APPENDIX)
********************************************************************************

preserve 
keep if anyanc==1

*	Set up putexcel
putexcel set "PMAET_Cohort1_6W_MNHAppendix_$date.xlsx", sheet("Appendix1") replace
putexcel A1=("Appendix1. Content of ANC - Nutritional Counselling (ANC recipients)"), bold underline
putexcel A2=("Percent distribution of women with ANC who received general nutrition counseling and counseling on taking iron/folate supplements and deworming medications, by background characteristics, PMA Ethiopia 2019-2021 Cohort"), italic
putexcel B3=("General nutrition counseling") C3=("Iron and folate counseling") D3=("Deworming medication counseling") E3=("Number of women (weighted)") 
putexcel A4=("Age") A12=("Education") A18=("Parity") A24=("Region") A32=("Residence") A36=("Wealth") A44=("Overall"), bold

*	Nutritional counseling by background characteristics
local row = 5
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile {

	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SWweight], matcell(a)
	putexcel E`row'=matrix(a), left nformat(number_sep)

	forvalues i = 1/`RowCount' {
		sum SWanc_nd_info_yn if `RowVar'==`i' [aw=SWweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum SWanc_nd_info_iron if `RowVar'==`i' [aw=SWweight]
			local mean2: disp %3.1f r(mean)*100
			
			sum SWanc_nd_info_deworm if `RowVar'==`i' [aw=SWweight]
			local mean3: disp %3.1f r(mean)*100

			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3'), left nformat(0.0)	
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	Nutritional counseling overall
sum SWanc_nd_info_yn [aw=SWweight]
local mean1: disp %3.1f r(mean)*100
sum SWanc_nd_info_iron [aw=SWweight]
local mean2: disp %3.1f r(mean)*100
sum SWanc_nd_info_deworm [aw=SWweight]
local mean3: disp %3.1f r(mean)*100
count
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3'), left nformat(0.0)	
putexcel E`row'=(`n_1'), left nformat(number_sep)	

*** Birth readiness counseling ***  
			
*	Set up putexcel
putexcel set "PMAET_Cohort1_6W_MNHAppendix_$date.xlsx", sheet("Appendix2") modify
putexcel A1=("Appendix 2. Content of ANC - Birth Preparedness Discussion (ANC recipients)"), bold underline
putexcel A2=("Percent distribution of women with ANC who received counseling on each birth preparedness topic, including place of delivery, delivery by a skilled birth attendant, arrangement of delivery transport, where to go when experiencing pregnancy danger signs, severe headaches with blurred vision, high blood pressure, edema, convulsions, and bleeding before delivery as a danger sign, by background characteristics, PMA Ethiopia 2019-2021 Cohort"), italic
putexcel A3=("Background characteristics" )B3=("Place of delivery") C3=("Skilled birth attendant") D3=("Delivery transport") E3=("Where to go when in danger") F3=("Severe headaches")G3=("High blood pressure") H3=("Edema") I3=("Convulsions") J3=("Bleeding before delivery") K3=("All 9 topics") L3=("Number of women (weighted)")
putexcel A4=("Age") A12=("Education") A18=("Parity") A24=("Region") A32=("Residence") A36=("Wealth") A44=("Overall"), bold

*	Birth readiness discussion by background characteristics
local row = 5
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile {
        
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SWweight], matcell(a)
	putexcel L`row'=matrix(a), left nformat(number_sep)

	forvalues i = 1/`RowCount' {
		sum SWanc_disc_delivplace if `RowVar'==`i' [aw=SWweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum SWanc_disc_skilled if `RowVar'==`i' [aw=SWweight]
			local mean2: disp %3.1f r(mean)*100
			
			sum SWanc_disc_transport if `RowVar'==`i' [aw=SWweight]
			local mean3: disp %3.1f r(mean)*100
			
			sum SWanc_disc_danger_place if `RowVar'==`i' [aw=SWweight]
			local mean4: disp %3.1f r(mean)*100

			sum SWanc_disc_danger_migraine if `RowVar'==`i' [aw=SWweight]
			local mean5: disp %3.1f r(mean)*100
			
			sum SWanc_disc_danger_hbp if `RowVar'==`i' [aw=SWweight]
			local mean6: disp %3.1f r(mean)*100

			sum SWanc_disc_danger_edema if `RowVar'==`i' [aw=SWweight]
			local mean7: disp %3.1f r(mean)*100
			
			sum SWanc_disc_danger_convuls if `RowVar'==`i' [aw=SWweight]
			local mean8: disp %3.1f r(mean)*100

			sum SWanc_disc_danger_bleeding if `RowVar'==`i' [aw=SWweight]
			local mean9: disp %3.1f r(mean)*100
			
			sum all_dis if `RowVar'==`i' [aw=SWweight]
			local mean10: disp %3.1f r(mean)*100
			
			count if `RowVar'==`i'
			local `n_1'=r(N)
					
			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6') H`row'=(`mean7') I`row'=(`mean8') J`row'=(`mean9') K`row'=(`mean10'), left nformat(0.0)	
			
			if `n_1'>=25 & `n_1'<=49 {
				putexcel B`row'=("(`mean1')") C`row'=("(`mean2')") D`row'=("(`mean3')") E`row'=("(`mean4')") F`row'=("(`mean5')") G`row'=("(`mean6')") H`row'=("(`mean7')") I`row'=("(`mean8')") J`row'=("(`mean9')") K`row'=("(`mean10')"), left nformat(0.0)	
				}
			if `n_1'<25 {
				putexcel B`row'=("*") C`row'=("*") D`row'=("*") E`row'=("*") F`row'=("*") G`row'=("*") H`row'=("*") I`row'=("*") J`row'=("*") K`row'=("*")
				}
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	Birth readiness discussion overall
sum SWanc_disc_delivplace [aw=SWweight]
local mean1: disp %3.1f r(mean)*100
sum SWanc_disc_skilled [aw=SWweight]
local mean2: disp %3.1f r(mean)*100
sum SWanc_disc_danger_place [aw=SWweight]
local mean3: disp %3.1f r(mean)*100
sum SWanc_disc_transport [aw=SWweight]
local mean4: disp %3.1f r(mean)*100
sum SWanc_disc_danger_migraine [aw=SWweight]
local mean5: disp %3.1f r(mean)*100
sum SWanc_disc_danger_hbp [aw=SWweight]
local mean6: disp %3.1f r(mean)*100
sum SWanc_disc_danger_edema [aw=SWweight]
local mean7: disp %3.1f r(mean)*100
sum SWanc_disc_danger_convuls [aw=SWweight]
local mean8: disp %3.1f r(mean)*100
sum SWanc_disc_danger_bleeding [aw=SWweight]
local mean9: disp %3.1f r(mean)*100
sum all_dis [aw=SWweight]
local mean10: disp %3.1f r(mean)*100
count
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6') H`row'=(`mean7') I`row'=(`mean8') J`row'=(`mean9') K`row'=(`mean10'), left nformat(0.0)	
putexcel L`row'=(`n_1'), left nformat(number_sep)			

*** Maternal assessment *** 

*	Set up putexcel
putexcel set "PMAET_Cohort1_6W_MNHAppendix_$date.xlsx", sheet("Appendix3") modify
putexcel A1=("Appendix 3. Content of ANC - Maternal Assessment (ANC recipients)"), bold underline
putexcel A2=("Percent distribution of respondents who had their weight, blood pressure, urine, blood, and stool sample taken at ANC and the proportion of women who received all 5 maternal assessments, among women with ANC, by background characteristics, PMA Ethiopia 2019-2021 Cohort"), italic
putexcel A3=("Background characteristics" ) B3=("Blood pressure taken") C3=("Weight taken") D3=("Urine sample taken") E3=("Blood sample taken") F3=("Stool sample taken") G3=("All 5 assessments") H3=("Number of women (weighted)")
putexcel A4=("Age") A12=("Education") A18=("Parity") A24=("Region") A32=("Residence") A36=("Wealth") A44=("Overall"), bold

*	Maternal assessment by background characteristics
local row = 5
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile {
        
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SWweight], matcell(a)
	putexcel H`row'=matrix(a), left nformat(number_sep)

	forvalues i = 1/`RowCount' {
		sum SWanc_bp if `RowVar'==`i' [aw=SWweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum SWanc_weight if `RowVar'==`i' [aw=SWweight]
			local mean2: disp %3.1f r(mean)*100
			
			sum SWanc_urine if `RowVar'==`i' [aw=SWweight]
			local mean3: disp %3.1f r(mean)*100
			
			sum SWanc_blood if `RowVar'==`i' [aw=SWweight]
			local mean4: disp %3.1f r(mean)*100

			sum SWanc_stool if `RowVar'==`i' [aw=SWweight]
			local mean5: disp %3.1f r(mean)*100
			
			sum all_assess if `RowVar'==`i' [aw=SWweight]
			local mean6: disp %3.1f r(mean)*100
			
			count if `RowVar'==`i'
			local n_1=r(N)
			
			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6'), left nformat(0.0)	
		
			if `n_1'>=25 & `n_1'<=49 {
				putexcel B`row'=("(`mean1')") C`row'=("(`mean2')") D`row'=("(`mean3')") E`row'=("(`mean4')") F`row'=("(`mean5')") G`row'=("(`mean6')"), left nformat(0.0)	
				}
			if `n_1'<25 {
				putexcel B`row'=("*") C`row'=("*") D`row'=("*") E`row'=("*") F`row'=("*") G`row'=("*")
				}
				
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	Maternal assessment overall
sum SWanc_bp [aw=SWweight]
local mean1: disp %3.1f r(mean)*100
sum SWanc_weight [aw=SWweight]
local mean2: disp %3.1f r(mean)*100
sum SWanc_urine [aw=SWweight]
local mean3: disp %3.1f r(mean)*100
sum SWanc_blood [aw=SWweight]
local mean4: disp %3.1f r(mean)*100
sum SWanc_stool [aw=SWweight]
local mean5: disp %3.1f r(mean)*100
sum all_assess [aw=SWweight]
local mean6: disp %3.1f r(mean)*100
count
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6'), left nformat(0.0)	
putexcel H`row'=(`n_1'), left nformat(number_sep)			

*** Postpartum family planning  *** 

*	Set up putexcel
putexcel set "PMAET_Cohort1_6W_MNHAppendix_$date.xlsx", sheet("Appendix4") modify
putexcel A1=("Appendix 4. Content of ANC - Postpartum Family Planning Counselling (ANC recipients)"), bold underline
putexcel A2=("Percent distribution of women with ANC who received postpartum family planning counseling at ANC, by background characteristics, PMA Ethiopia 2019-2021 Cohort"), italic
putexcel A3=("Background characteristics" ) B3=("Percent") C3=("Number of women (weighted)")
putexcel A4=("Age") A12=("Education") A18=("Parity") A24=("Region") A32=("Residence") A36=("Wealth") A44=("Overall"), bold

*	PPFP counseling by background characteristics
local row = 5
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile {
        
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SWweight], matcell(a)
	putexcel C`row'=matrix(a), left nformat(number_sep)

	forvalues i = 1/`RowCount' {
		sum SWanc_ppfp_couns if `RowVar'==`i' [aw=SWweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			count if `RowVar'==`i'
			local n_1=r(N)
			
			putexcel A`row'=("`CellContents'") B`row'=(`mean1'), left nformat(0.0)	
			
			if `n_1'>=25 & `n_1'<=49 {
				putexcel B`row'=("(`mean1')"), left nformat(0.0)	
				}
			if `n_1'<25 {
				putexcel B`row'=("*")
				}
				
				
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	PPFP counselling overall
sum SWanc_ppfp_couns [aw=SWweight]
local mean1: disp %3.1f r(mean)*100
count
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1'), left nformat(0.0)	
putexcel C`row'=(`n_1'), left nformat(number_sep)	

*** STI testing *** 

*	Set up putexcel
putexcel set "PMAET_Cohort1_6W_MNHAppendix_$date.xlsx", sheet("Appendix5") modify
putexcel A1=("Appendix 5. Content of ANC - HIV and Syphilis Testing (ANC recipients)"), bold underline
putexcel A2=("Percent distribution of women with ANC who received HIV and Syphilis testing, test results, and test counseling at ANC, by background characteristics, PMA Ethiopia 2019-2021 Cohort"), italic
putexcel A3=("Background characteristics" ) B3=("HIV testing") C3=("Syphilis testing") D3=("Number of women (weighted)") E3=("HIV result") F3=("HIV counseling") G3=("Number of women with HIV test (weighted)") H3=("Syphilis result") I3=("Syphilis counseling")  J3=("Number of women with syphilis test (weighted)")  
putexcel A4=("Age") A12=("Education") A18=("Parity") A24=("Region") A32=("Residence") A36=("Wealth") A44=("Overall"), bold

*	STI testing by background characteristics
local row = 5
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile {
        
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SWweight], matcell(a)
	putexcel D`row'=matrix(a), left nformat(number_sep)
	
	tabulate `RowVar' [aw=SWweight] if SWanc_hiv_test==1 , matcell(b)
	putexcel G`row'=matrix(b), left nformat(number_sep)
	
	tabulate `RowVar' [aw=SWweight] if SWanc_syph_test==1, matcell(c)
	putexcel J`row'=matrix(c), left nformat(number_sep)
	

	forvalues i = 1/`RowCount' {
		sum SWanc_hiv_test if `RowVar'==`i' [aw=SWweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum SWanc_syph_test if `RowVar'==`i' [aw=SWweight]
			local mean2: disp %3.1f r(mean)*100
			
			sum SWanc_hiv_result if `RowVar'==`i' & SWanc_hiv_test==1 [aw=SWweight]
			local mean3: disp %3.1f r(mean)*100
			
			sum SWanc_hiv_couns if `RowVar'==`i'  & SWanc_hiv_test==1 [aw=SWweight]
			local mean4: disp %3.1f r(mean)*100

			sum SWanc_syph_result if `RowVar'==`i' & SWanc_syph_test==1 [aw=SWweight]
			local mean5: disp %3.1f r(mean)*100
			
			sum SWanc_syph_couns if `RowVar'==`i' & SWanc_syph_test==1 [aw=SWweight]
			local mean6: disp %3.1f r(mean)*100
			
			count if `RowVar'==`i' & SWanc_hiv_test==1 
			local n_1=r(N)
			
			count if `RowVar'==`i' & SWanc_syph_test==1 
			local n_2=r(N)
			
			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') E`row'=(`mean3') F`row'=(`mean4') H`row'=(`mean5') I`row'=(`mean6'), left nformat(0.0)	
			
			*	Suppress output with insufficient sample size
			if `n_1' <= 49 & `n_1' > 24 {
				putexcel E`row'=("(`mean3')") F`row'=("(`mean4')"), left nformat(0.0)	
				}
			if `n_1' <= 24 {
				putexcel E`row'=("*") F`row'=("*")
				}
				
			if `n_2' <= 49 & `n_2' > 24 {
				putexcel H`row'=("(`mean5')") I`row'=("(`mean6')"), left nformat(0.0)	
				}
			if `n_2' <= 24 {
				putexcel H`row'=("*") I`row'=("*")	
				}

			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	STI testing overall
sum SWanc_hiv_test [aw=SWweight]
local mean1: disp %3.1f r(mean)*100
sum SWanc_syph_test [aw=SWweight]
local mean2: disp %3.1f r(mean)*100
count
if r(N)!=0 local n_1= r(N)
sum SWanc_hiv_result if SWanc_hiv_test==1 [aw=SWweight]
local mean3: disp %3.1f r(mean)*100
sum SWanc_hiv_couns if SWanc_hiv_test==1 [aw=SWweight]
local mean4: disp %3.1f r(mean)*100
count if SWanc_hiv_test==1 
if r(N)!=0 local n_2= r(N)
sum SWanc_syph_result if SWanc_syph_test==1 [aw=SWweight]
local mean5: disp %3.1f r(mean)*100
sum SWanc_syph_couns if SWanc_syph_test==1 [aw=SWweight]
local mean6: disp %3.1f r(mean)*100
count if SWanc_syph_test==1
if r(N)!=0 local n_3= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') E`row'=(`mean3') F`row'=(`mean4') H`row'=(`mean5') I`row'=(`mean6') J`row'=(`n_3'), left nformat(0.0)	
putexcel D`row'=(`n_1') G`row'=(`n_2') J`row'=(`n_3'), left nformat(number_sep)			

local row=`row'+2
putexcel A`row'=("NOTE: Estimates based on 25-49 unweighted samples are reported inside parathesis in the report. Estimates based on less than 25 unweighted samples are suppressed."), italic

restore 

********************************************************************************
**							DELIVERY INDICATORS   		                  	**   
********************************************************************************

* Replace 6w data for 5-9 weeks pp women 
foreach var of varlist deliv_place deliv_assit-postdelivprob_trt_convuls {
		replace SW`var'=`var' if baseline_status==3
	}

*** Place of delivery *** 
*	Generate new delivery place category 
gen delivery_location=1 if SWdeliv_place==1 | SWdeliv_place==2
replace delivery_location=2 if SWdeliv_place==11 
replace delivery_location=3 if SWdeliv_place==12 | SWdeliv_place==13
replace delivery_location=4 if SWdeliv_place==31 | SWdeliv_place==36
replace delivery_location=5 if SWdeliv_place==21 | SWdeliv_place==96
label define delivery_lab 1 "Home" 2 "Public sector hospital" 3 "Public sector health center or lower" 4 "Private sector" 5 "NGO and others"
label val delivery_location delivery_lab

*	Generate binary variables for putexcel
gen deliv_home=0
replace deliv_home=1 if delivery_location==1
gen deliv_pubhosp=0
replace deliv_pubhosp=1 if delivery_location==2
gen deliv_pubhc=0
replace deliv_pubhc=1 if delivery_location==3
gen deliv_pri=0
replace deliv_pri=1 if delivery_location==4
gen deliv_ngo=0
replace deliv_ngo=1 if delivery_location==5

*	Facility delivery 
gen facility_deliv=0
replace facility_deliv=1 if SWdeliv_place>2 & SWdeliv_place!=96
tab facility_deliv
label val facility_deliv yes_no_list

*	Set up putexcel
putexcel set "PMAET_Cohort1_6W_MNHAnalysis_$date.xlsx", sheet("Table12") modify
putexcel A1=("Table 12. Place of Delivery"), bold underline
putexcel A2=("Percent distribution of women's place of delivery and the percentage of women who delivered at a health facility, among all women, by background characteristics and number of ANC visits, PMA Ethiopia 2019-2021 Cohort"), italic
putexcel A3=("Background characteristics") B3=("Home") C3=("Government hospital") D3=("Government HC or lower") E3=("Private sector") F3=("NGO and others") G3=("Percentage delivered in a health facility") H3=("Number of women (weighted)")
putexcel A4=("Age") A12=("Education") A18=("Parity") A24=("Region") A32=("Residence") A36=("Wealth") A43=("Number of ANC visits") A49=("Overall"), bold

*	Place of delivery by background characteristics
local row = 5
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile total_anc {
        
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SWweight], matcell(a)
	putexcel H`row'=matrix(a), left nformat(number_sep)

	forvalues i = 1/`RowCount' {
		sum deliv_home if `RowVar'==`i' [aw=SWweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum deliv_pubhosp if `RowVar'==`i' [aw=SWweight]
			local mean2: disp %3.1f r(mean)*100
			
			sum deliv_pubhc if `RowVar'==`i' [aw=SWweight]
			local mean3: disp %3.1f r(mean)*100

			sum deliv_pri if `RowVar'==`i' [aw=SWweight]
			local mean4: disp %3.1f r(mean)*100
						
			sum deliv_ngo if `RowVar'==`i' [aw=SWweight]
			local mean5: disp %3.1f r(mean)*100
			
			sum facility_deliv if `RowVar'==`i' [aw=SWweight]
			local mean6: disp %3.1f r(mean)*100
			
			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6') , left nformat(0.0)	
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	Place of delivery overall
sum deliv_home [aw=SWweight]
local mean1: disp %3.1f r(mean)*100
sum deliv_pubhosp [aw=SWweight]
local mean2: disp %3.1f r(mean)*100
sum deliv_pubhc [aw=SWweight]
local mean3: disp %3.1f r(mean)*100
sum deliv_pri [aw=SWweight]
local mean4: disp %3.1f r(mean)*100
sum deliv_ngo [aw=SWweight]
local mean5: disp %3.1f r(mean)*100
sum facility_deliv [aw=SWweight]
local mean6: disp %3.1f r(mean)*100
count
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6'), left nformat(0.0)	
putexcel H`row'=(`n_1'), left nformat(number_sep)	


*** Birth attendant *** 

*	Generate skilled birth attendant variable 
gen skilled_birthattendant=0
replace skilled_birthattendant=1 if SWdeliv_assit>=1 & SWdeliv_assit<=4
label val skilled_birthattendant yes_no_list

*	Generate binary variables for putexcel
gen assist_noone=0
replace assist_noone=1 if SWdeliv_assit==0
gen assist_doctor=0
replace assist_doctor=1 if SWdeliv_assit==1
gen assist_ho=0
replace assist_ho=1 if SWdeliv_assit==2
gen assist_nurse=0
replace assist_nurse=1 if SWdeliv_assit==3
gen assist_skilled=0
replace assist_skilled=1 if SWdeliv_assit==4
gen assist_hew=0
replace assist_hew=1 if SWdeliv_assit==5
gen assist_traditional=0
replace assist_traditional=1 if SWdeliv_assit==7
gen assist_family=0
replace assist_family=1 if SWdeliv_assit==8
gen assist_other=0
replace assist_other=1 if SWdeliv_assit==96

*	Generate new delivery place category 
gen delivery_location1=1 if SWdeliv_place==1 | SWdeliv_place==2
replace delivery_location1=2 if SWdeliv_place==11 
replace delivery_location1=3 if SWdeliv_place==12 | SWdeliv_place==13
replace delivery_location1=4 if SWdeliv_place==31 | SWdeliv_place==36
replace delivery_location1=5 if SWdeliv_place==21
replace delivery_location1=6 if SWdeliv_place==96

label define delivery_lab1 1 "Home" 2 "Public sector hospital" 3 "Public sector health center or lower" 4 "Private sector" 5 "NGO" 6 "Other, not specified"
label val delivery_location1 delivery_lab1

*	Set up putexcel
putexcel set "PMAET_Cohort1_6W_MNHAnalysis_$date.xlsx", sheet("Table13") modify
putexcel A1=("Table 13. Skilled Birth Attendant"), bold underline
putexcel A2=("Percent distribution of women's birth attendant and the percentage of women who delivered with a skilled birth attendant, among all women, by background characteristics, number of ANC visits, and delivery location, PMA Ethiopia 2019-2021 Cohort"), italic
putexcel A3=("Background characteristics" )B3=("No one assisted") C3=("Doctor") D3=("Health officer") E3=("Nurse/Midwife") F3=("Skilled attendant can't distinguish	")G3=("Health extension worker") H3=("Traditional birth attendant") I3=("Family member") J3=("Other") K3=("Skilled birth attendant") L3=("Number of women (weighted)")
putexcel A4=("Age") A12=("Education") A18=("Parity") A24=("Region") A32=("Residence") A36=("Wealth") A43=("Number of ANC visits") A48=("Delivery location") A57=("Overall") , bold

*	Birth attendant by background characteristics
local row = 5
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile total_anc delivery_location1 {
        
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SWweight], matcell(a)
	putexcel L`row'=matrix(a), left nformat(number_sep)

	forvalues i = 1/`RowCount' {
		sum assist_noone if `RowVar'==`i' [aw=SWweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum assist_doctor if `RowVar'==`i' [aw=SWweight]
			local mean2: disp %3.1f r(mean)*100
			
			sum assist_ho if `RowVar'==`i' [aw=SWweight]
			local mean3: disp %3.1f r(mean)*100
			
			sum assist_nurse if `RowVar'==`i' [aw=SWweight]
			local mean4: disp %3.1f r(mean)*100

			sum assist_skilled if `RowVar'==`i' [aw=SWweight]
			local mean5: disp %3.1f r(mean)*100
			
			sum assist_hew if `RowVar'==`i' [aw=SWweight]
			local mean6: disp %3.1f r(mean)*100

			sum assist_traditional if `RowVar'==`i' [aw=SWweight]
			local mean7: disp %3.1f r(mean)*100
			
			sum assist_family if `RowVar'==`i' [aw=SWweight]
			local mean8: disp %3.1f r(mean)*100

			sum assist_other if `RowVar'==`i' [aw=SWweight]
			local mean9: disp %3.1f r(mean)*100
			
			sum skilled_birthattendant if `RowVar'==`i' [aw=SWweight]
			local mean10: disp %3.1f r(mean)*100
			
			count if `RowVar'==`i'
			local n_1=r(N)
			
			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6') H`row'=(`mean7') I`row'=(`mean8') J`row'=(`mean9') K`row'=(`mean10'), left nformat(0.0)
			
			if `n_1' < 25 {
				putexcel B`row'=("*") C`row'=("*") D`row'=("*") E`row'=("*") F`row'=("*") G`row'=("*") H`row'=("*") I`row'=("*") J`row'=("*") K`row'=("*")
			}
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	Birth attendant overall
sum assist_noone [aw=SWweight]
local mean1: disp %3.1f r(mean)*100
sum assist_doctor [aw=SWweight]
local mean2: disp %3.1f r(mean)*100
sum assist_ho [aw=SWweight]
local mean3: disp %3.1f r(mean)*100
sum assist_nurse [aw=SWweight]
local mean4: disp %3.1f r(mean)*100
sum assist_skilled [aw=SWweight]
local mean5: disp %3.1f r(mean)*100
sum assist_hew [aw=SWweight]
local mean6: disp %3.1f r(mean)*100
sum assist_traditional [aw=SWweight]
local mean7: disp %3.1f r(mean)*100
sum assist_family [aw=SWweight]
local mean8: disp %3.1f r(mean)*100
sum assist_other [aw=SWweight]
local mean9: disp %3.1f r(mean)*100
sum skilled_birthattendant [aw=SWweight]
local mean10: disp %3.1f r(mean)*100
count
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6') H`row'=(`mean7') I`row'=(`mean8') J`row'=(`mean9') K`row'=(`mean10'), left nformat(0.0)	
putexcel L`row'=(`n_1'), left nformat(number_sep)	

local row=`row'+2
putexcel A`row'=("NOTE: Estimates based on 25-49 unweighted samples are reported inside parentheses in the report. Estimates based on less than 25 unweighted samples are suppressed."), italic

*** Caesarean delivery *** 
replace SWdeliv_csection=deliv_csection if baseline_status==3
recode SWdeliv_csection (.=0)

*	Set up putexcel
putexcel set "PMAET_Cohort1_6W_MNHAnalysis_$date.xlsx", sheet("Table14") modify
putexcel A1=("Table 14. Caesarean Section Delivery"), bold underline
putexcel A2=("Percent distribution of women who had a caesarean section (c-section) delivery among women with facility births and among all women, by background characteristics and number of ANC visits, PMA Ethiopia 2019-2021 Cohort"), italic
putexcel A3=("Background characteristics") B3=("Among women with facility births") C3=("Number of women with facility births (weighted)") D3=("Among all women") E3=("Number of women (weighted)")
putexcel A4=("Age") A12=("Education") A18=("Parity") A24=("Region") A32=("Residence") A36=("Wealth") A43=("Number of ANC") A49=("Overall"), bold

*	C-section by background characteristics
local row = 5
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile total_anc {
        
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' if facility_deliv==1 [aw=SWweight], matcell(a)
	putexcel C`row'=matrix(a), left nformat(number_sep)
	tabulate `RowVar' [aw=SWweight], matcell(b)
	putexcel E`row'=matrix(b), left nformat(number_sep)

	forvalues i = 1/`RowCount' {
		sum SWdeliv_csection if `RowVar'==`i' & facility_deliv==1 [aw=SWweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			count if `RowVar'==`i' & facility_deliv==1
			local n_1=r(N)
			
			sum SWdeliv_csection if `RowVar'==`i' [aw=SWweight]
			local mean2: disp %3.1f r(mean)*100
			
			putexcel A`row'=("`CellContents'") B`row'=(`mean1')  D`row'=(`mean2'), left nformat(0.0)	
			
			if `n_1'>=24 & `n_1'<=49 {
				putexcel B`row'=("(`mean1')"), left nformat(0.0)	
			}
			if `n_1'<25 {
				putexcel B`row'=("*")	
			}
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	C-section overall
sum SWdeliv_csection if facility_deliv==1 [aw=SWweight]
local mean1: disp %3.1f r(mean)*100
count if facility_deliv==1
if r(N)!=0 local n_1= r(N)

sum SWdeliv_csection [aw=SWweight]
local mean2: disp %3.1f r(mean)*100
if r(N)!=0 local n_2= r(N)

putexcel B`row'=(`mean1')  D`row'=(`mean2'), left nformat(0.0)	
putexcel C`row'=(`n_1') E`row'=(`n_2'), left nformat(number_sep)	

local row=`row'+2
putexcel A`row'=("NOTE: Estimates based on 25-49 unweighted samples are reported inside parentheses in the report. Estimates based on less than 25 unweighted samples are suppressed."), italic

*** Delivery complications *** 
gen any_delivprob=0
foreach var in delivprob_bleed delivprob_leakmemb24hr delivprob_leakmembpre9mo delivprob_malposition delivprob_prolonglab delivprob_convuls {
		recode SW`var' (-99 -88 =0) 
		replace any_delivprob=1 if SW`var'==1
	}
label val any_delivprob yes_no_list

*	Set up putexcel
putexcel set "PMAET_Cohort1_6W_MNHAnalysis_$date.xlsx", sheet("Table15") modify
putexcel A1=("Table 15. Delivery Complications"), bold underline
putexcel A2=("Percent distribution of women who self-reported delivery-related maternal health complications, including severe bleeding, rupture of membrane and no labor pains for >24 hours, rupture of membrane before 9 months, malposition/malpresentation, prolonged labor, convulsions/fits, and any complication among all women, by background characteristics and number of ANC visits, PMA Ethiopia 2019-2021 Cohort"), italic
putexcel A3=("Background characteristics" ) B3=("Severe bleeding") C3=("Rupture of membrane and no labor pains for >24 hours") D3=("Rupture of membrane before 9 months") E3=("Malposition/malpresentation") F3=("Prolonged labor (>12 hours)")G3=("Convulsions/fits") H3=("Any complication") I3=("Number of women (weighted)")
putexcel A4=("Age") A12=("Education") A18=("Parity") A24=("Region") A32=("Residence") A36=("Wealth") A43=("Number of ANC") A49=("Overall"), bold

*	Delivery complications by background characteristics
local row = 5
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile total_anc {
        
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SWweight], matcell(a)
	putexcel I`row'=matrix(a), left nformat(number_sep)

	forvalues i = 1/`RowCount' {
		sum SWdelivprob_bleed if `RowVar'==`i' [aw=SWweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum SWdelivprob_leakmemb24hr if `RowVar'==`i' [aw=SWweight]
			local mean2: disp %3.1f r(mean)*100
			
			sum SWdelivprob_leakmembpre9mo if `RowVar'==`i' [aw=SWweight]
			local mean3: disp %3.1f r(mean)*100
			
			sum SWdelivprob_malposition if `RowVar'==`i' [aw=SWweight]
			local mean4: disp %3.1f r(mean)*100

			sum SWdelivprob_prolonglab if `RowVar'==`i' [aw=SWweight]
			local mean5: disp %3.1f r(mean)*100
			
			sum SWdelivprob_convuls if `RowVar'==`i' [aw=SWweight]
			local mean6: disp %3.1f r(mean)*100

			sum any_delivprob if `RowVar'==`i' [aw=SWweight]
			local mean7: disp %3.1f r(mean)*100
			
			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6') H`row'=(`mean7'), left nformat(0.0)	
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	Delivery complications overall
sum SWdelivprob_bleed [aw=SWweight]
local mean1: disp %3.1f r(mean)*100
sum SWdelivprob_leakmemb24hr [aw=SWweight]
local mean2: disp %3.1f r(mean)*100
sum SWdelivprob_leakmembpre9mo [aw=SWweight]
local mean3: disp %3.1f r(mean)*100
sum SWdelivprob_malposition [aw=SWweight]
local mean4: disp %3.1f r(mean)*100
sum SWdelivprob_prolonglab [aw=SWweight]
local mean5: disp %3.1f r(mean)*100
sum SWdelivprob_convuls [aw=SWweight]
local mean6: disp %3.1f r(mean)*100
sum any_delivprob [aw=SWweight]
local mean7: disp %3.1f r(mean)*100

count
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6') H`row'=(`mean7'), left nformat(0.0)	
putexcel I`row'=(`n_1'), left nformat(number_sep)		

*** Treatment for complications *** 
*	Generate binary variables
gen trt_home=0
replace trt_home=1 if (SWdelivprob_trt_herhome==1 | SWdelivprob_trt_otherhome==1)

gen trt_govhops=0
replace trt_govhops=1 if (SWdelivprob_trt_govhosp==1)

gen trt_govhchp=0
replace trt_govhchp=1 if (SWdelivprob_trt_govhc==1 | SWdelivprob_trt_govhp==1 | SWdelivprob_trt_otherpub==1)

gen trt_other=0
replace trt_other=1 if (SWdelivprob_trt_privhosp==1 | SWdelivprob_trt_otherpriv==1 | SWdelivprob_trt_ngohf==1 | SWdelivprob_trt_tradheal==1 | SWdelivprob_trt_pharmacy==1 | SWdelivprob_trt_other==1)

gen trt_none=0
replace trt_none=1 if SWdelivprob_trt_notreat==1

foreach var in home govhops govhchp other none {
		recode trt_`var' (-88 -99 .=0) 
	}

*	Set up putexcel
putexcel set "PMAET_Cohort1_6W_MNHAnalysis_$date.xlsx", sheet("Table16") modify
putexcel A1=("Table 16. Treatment of Delivery Complications"), bold underline
putexcel A2=("Percent distribution of places where women sought care for any complications during delivery, among women with any delivery complications, by background characteristics, PMA Ethiopia 2019-2021 Cohort"), italic
putexcel A3=("Background characteristics" ) B3=("Home") C3=("Government hospital") D3=("Government HC or lower") E3=("Private, NGO and other") F3=("No treatment sought") G3=("Number of women (weighted)")
putexcel A4=("Age") A12=("Education") A18=("Parity") A24=("Region") A32=("Residence") A36=("Wealth") A44=("Overall"), bold

*	Treatment for delivery complications by background characteristics
local row = 5
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile {
        
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SWweight] if any_delivprob==1, matcell(a)
	putexcel G`row'=matrix(a), left nformat(number_sep)

	forvalues i = 1/`RowCount' {
		sum trt_home if `RowVar'==`i' & any_delivprob==1 [aw=SWweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum trt_govhops if `RowVar'==`i' & any_delivprob==1 [aw=SWweight]
			local mean2: disp %3.1f r(mean)*100
			
			sum trt_govhchp if `RowVar'==`i' & any_delivprob==1 [aw=SWweight]
			local mean3: disp %3.1f r(mean)*100
			
			sum trt_other if `RowVar'==`i' & any_delivprob==1 [aw=SWweight]
			local mean4: disp %3.1f r(mean)*100

			sum trt_none if `RowVar'==`i' & any_delivprob==1 [aw=SWweight]
			local mean5: disp %3.1f r(mean)*100
			
			count if `RowVar'==`i' & any_delivprob==1 
			local n_1=r(N)
			
			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5'), left nformat(0.0)	
			
			if `n_1' > 24 & `n_1' <=49 {
				putexcel B`row'=("(`mean1')") C`row'=("(`mean2')") D`row'=("(`mean3')") E`row'=("(`mean4')") F`row'=("(`mean5')")	
			}
			
			if `n_1' <= 24 {
				putexcel B`row'=(("*")) C`row'=(("*")) D`row'=(("*")) E`row'=(("*")) F`row'=(("*"))
			}
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	Treatment for delivery complications overall
sum trt_home [aw=SWweight] if any_delivprob==1
local mean1: disp %3.1f r(mean)*100
sum trt_govhops [aw=SWweight] if any_delivprob==1
local mean2: disp %3.1f r(mean)*100
sum trt_govhchp [aw=SWweight] if any_delivprob==1
local mean3: disp %3.1f r(mean)*100
sum trt_other [aw=SWweight]if any_delivprob==1
local mean4: disp %3.1f r(mean)*100
sum trt_none [aw=SWweight] if any_delivprob==1
local mean5: disp %3.1f r(mean)*100

count if any_delivprob==1
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5'), left nformat(0.0)	
putexcel G`row'=(`n_1'), left nformat(number_sep)

local row=`row'+2
putexcel A`row'=("NOTE: Estimates based on 25-49 unweighted samples are reported inside parentheses in the report. Estimates based on less than 25 unweighted samples are suppressed."), italic

********************************************************************************
**							PNC INDICATORS          	           		**   
********************************************************************************

*	Replace 6w data with baseline for 5-9 weeks postpartum women
foreach var in mother_check mother_check_timing mother_check_timing_val mother_check_provider hew_visit hew_visit_timing seek_hew seek_hew_timing seek_phcp_yn seek_phcp_timing ppfp_couns couns_breastfeed couns_vax couns_feeding couns_growth {		
		replace SWpnc_`var'=pnc_`var' if baseline_status==3	
	}
	
*	Recode DNK, missing, and NR to 0
foreach var in pnc_mother_check pnc_hew_visit pnc_seek_hew pnc_seek_phcp_yn {
		recode 	SW`var' (-88 -99=0)
	}

*** Timing of PNC *** 

*	Any PNC 
gen anypnc=0
replace anypnc=1 if SWpnc_mother_check==1 | SWpnc_hew_visit==1 | SWpnc_seek_hew==1 | SWpnc_seek_phcp_yn==1

*	Timing of first check
gen pnc_check_48hrs=0 if anypnc==1
replace pnc_check_48hrs=1 if (SWpnc_mother_check_timing==1 | SWpnc_mother_check_timing==2) & SWpnc_mother_check==1
replace pnc_check_48hrs=1 if (SWpnc_mother_check_timing==3 & SWpnc_mother_check_timing_val<=2) & SWpnc_mother_check==1
replace pnc_check_48hrs=1 if (SWpnc_hew_visit_timing<=2 & SWpnc_hew_visit_timing!=-88 & SWpnc_hew_visit_timing!=-99) & SWpnc_hew_visit==1
replace pnc_check_48hrs=1 if (SWpnc_seek_hew_timing<=2 & SWpnc_seek_hew_timing!=-88 & SWpnc_seek_hew_timing!=-99) & SWpnc_seek_hew==1
replace pnc_check_48hrs=1 if (SWpnc_seek_phcp_timing<=2 & SWpnc_seek_phcp_timing!=-88 & SWpnc_seek_phcp_timing!=-99) & SWpnc_seek_phcp_yn==1
label var pnc_check_48hrs "Was the check within 48 hrs?"
label val pnc_check_48hrs yes_no_list
tab pnc_check_48hrs

*	Binary variables for PNC timing
gen pnc_within48hrs=0
replace pnc_within48hrs=1 if pnc_check_48hrs==1
gen pnc_beyond48hrs=0
replace pnc_beyond48hrs=1 if pnc_check_48hrs==0
gen nopnc=0
replace nopnc=1 if anypnc==0

*	Set up putexcel
putexcel set "PMAET_Cohort1_6W_MNHAnalysis_$date.xlsx", sheet("Table17") modify
putexcel A1=("Table 17. Timing of postnatal care"), bold underline
putexcel A2=("The percent distribution of respondent who received postnatal care (PNC) within 48 hours of delivery, more than 48 hours after delivery and the proportion of women with no PNC by the time of their 6-week interview, among all women, by background characteristics, PMA Ethiopia 2019-2021 Cohort"), italic
putexcel A3=("Background characteristics" ) B3=("PNC <= 48 hours of delivery") C3=("PNC > 48 hours of delivery") D3=("No PNC") E3=("Number of women (weighted)")
putexcel A4=("Age") A12=("Education") A18=("Parity") A24=("Region") A32=("Residence") A36=("Wealth") A44=("Overall"), bold

*	PNC timing by background characteristics
local row = 5
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile {
        
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SWweight], matcell(a)
	putexcel E`row'=matrix(a), left nformat(number_sep)

	forvalues i = 1/`RowCount' {
		sum pnc_within48hrs if `RowVar'==`i' [aw=SWweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum pnc_beyond48hrs if `RowVar'==`i' [aw=SWweight]
			local mean2: disp %3.1f r(mean)*100
			
			sum nopnc if `RowVar'==`i' [aw=SWweight]
			local mean3: disp %3.1f r(mean)*100
		
			
			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') , left nformat(0.0)	
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	PNC timing overall
sum pnc_within48hrs [aw=SWweight] 
local mean1: disp %3.1f r(mean)*100
sum pnc_beyond48hrs [aw=SWweight]
local mean2: disp %3.1f r(mean)*100
sum nopnc [aw=SWweight] 
local mean3: disp %3.1f r(mean)*100

count
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3'), left nformat(0.0)	
putexcel E`row'=(`n_1'), left nformat(number_sep)


*** PNC coverage ***

recode SWpnc_mother_check (.=0)

*	Set up putexcel
putexcel set "PMAET_Cohort1_6W_MNHAnalysis_$date.xlsx", sheet("Table18") modify
putexcel A1=("Table 18. PNC Utalization"), bold underline
putexcel A2=("Percent distribution of respondents who reported receiving PNC after delivery among all women, and the proportion of women whose health was checked after delivery among women with facility delivery, PMA Ethiopia 2019-2021 Cohort"), italic
putexcel A3=("Background characteristics" ) B3=("Mother's health checked after delivery") C3=("Visited by an HEW after delivery") D3=("Sought care from an HEW after delivery") E3=("Sought care from an PHCP after delivery") F3=("Any PNC") G3=("Number of women (weighted)") H3=("Mother's health checked after delivery") I3=("Number of women with facility delivery (weighted)")
putexcel A4=("Age") A12=("Education") A18=("Parity") A24=("Region") A32=("Residence") A36=("Wealth") A44=("Overall"), bold

*	PNC coverage by background characteristics
local row = 5
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile {
        
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SWweight], matcell(a)
	putexcel G`row'=matrix(a), left nformat(number_sep)
	tabulate `RowVar' [aw=SWweight] if facility_deliv==1 , matcell(b)
	putexcel I`row'=matrix(b), left nformat(number_sep)

	forvalues i = 1/`RowCount' {
		sum SWpnc_mother_check if `RowVar'==`i' [aw=SWweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum SWpnc_hew_visit if `RowVar'==`i' [aw=SWweight]
			local mean2: disp %3.1f r(mean)*100
			
			sum SWpnc_seek_hew if `RowVar'==`i' [aw=SWweight]
			local mean3: disp %3.1f r(mean)*100
			
			sum SWpnc_seek_phcp_yn if `RowVar'==`i' [aw=SWweight]
			local mean4: disp %3.1f r(mean)*100

			sum anypnc if `RowVar'==`i' [aw=SWweight]
			local mean5: disp %3.1f r(mean)*100
			
			sum SWpnc_mother_check if `RowVar'==`i' & facility_deliv==1 [aw=SWweight]
			local mean6: disp %3.1f r(mean)*100
			
			count if `RowVar'==`i' & facility_deliv==1
			local n_1=r(N)
			
			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') H`row'=(`mean6') , left nformat(0.0)	
			
			if `n_1'>=25 & `n_1'<=49 {
					putexcel H`row'=("(`mean6')"), left nformat(0.0)
				}
			
			if `n_1'<25 {
					putexcel H`row'=("*")
				}
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	PNC coverage overall
sum SWpnc_mother_check [aw=SWweight] 
local mean1: disp %3.1f r(mean)*100
sum SWpnc_hew_visit [aw=SWweight]
local mean2: disp %3.1f r(mean)*100
sum SWpnc_seek_hew [aw=SWweight] 
local mean3: disp %3.1f r(mean)*100
sum SWpnc_seek_phcp_yn [aw=SWweight]
local mean4: disp %3.1f r(mean)*100
sum anypnc [aw=SWweight]
local mean5: disp %3.1f r(mean)*100
sum SWpnc_mother_check [aw=SWweight] if facility_deliv==1
local mean6: disp %3.1f r(mean)*100

count
if r(N)!=0 local n_1= r(N)
count if facility_deliv==1
if r(N)!=0 local n_2= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') H`row'=(`mean6'), left nformat(0.0)	
putexcel G`row'=(`n_1') I`row'=(`n_2'), left nformat(number_sep)

local row=`row'+2
putexcel A`row'=("NOTE: Estimates based on 25-49 unweighted samples are reported inside parentheses in the report. Estimates based on less than 25 unweighted samples are suppressed."), italic

*** PPFP, EBF, immunization, infant feeding, and infant growth counseling *** 
*	Recode missing, DNK, and NR to 0
recode SWpnc_ppfp_couns (-88 -99=0)

foreach var in fp breastfeed vax feeding growth fp {
		recode SWpnc_couns_`var'(-99 -88=0)
	}

*	Received PPFP counseling either at or outside health facility
* Received FP counseling at either places 
gen anyfp=0
replace anyfp=1 if SWpnc_ppfp_couns==1 | SWpnc_couns_fp==1

*	Received PNC outside the health facility 
gen pnc_none_facility=0
replace pnc_none_facility=1 if SWpnc_couns_breastfeed!=.

*	Set up putexcel
putexcel set "PMAET_Cohort1_6W_MNHAnalysis_$date.xlsx", sheet("Table19") modify
putexcel A1=("Table 19. Counseling at PNC"), bold underline
putexcel A2=("Percent distribution of respondents who reported receiving postpartum family planning counseling at PNC among women with facility delivery who had PNC, and the proportion of women who reported receiving exclusive breastfeeding, immunization, infant feeding, and infant growth counseling at PNC among women who reported PNC outside the health facility, by background characteristics, PMA Ethiopia 2019-2021 Cohort"), italic
putexcel A3=("Background characteristics" ) B3=("Postpartum family planning") C3=("Number of women with facility delivery") D3=("Postpartum family planning") E3=("Number of women with any PNC") F3=("Exclusive breastfeeding") G3=("Immunization") H3=("Infant feeding") I3=("Infant growth") J3=("Number of women (weighted)")
putexcel A4=("Age") A12=("Education") A18=("Parity") A24=("Region") A32=("Residence") A36=("Wealth") A44=("Overall"), bold

*	Counseling at PNC by background characteristics
local row = 5
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile {
        
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SWweight] if facility_deliv==1 , matcell(a)
	putexcel C`row'=matrix(a), left nformat(number_sep)
	tabulate `RowVar' [aw=SWweight] if anypnc==1 , matcell(b)
	putexcel E`row'=matrix(b), left nformat(number_sep)
	tabulate `RowVar' [aw=SWweight] if pnc_none_facility==1 , matcell(c)
	putexcel J`row'=matrix(c), left nformat(number_sep)

	forvalues i = 1/`RowCount' {
		sum SWpnc_ppfp_couns if `RowVar'==`i' & facility_deliv==1 [aw=SWweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			count if `RowVar'==`i' & facility_deliv==1
			local n_1=r(N)
			
			sum anyfp if `RowVar'==`i' & anypnc==1 [aw=SWweight]
			local mean2: disp %3.1f r(mean)*100
			count if `RowVar'==`i' & anypnc==1
			local n_2=r(N)
			
			sum SWpnc_couns_breastfeed if `RowVar'==`i' & pnc_none_facility==1 [aw=SWweight]
			local mean3: disp %3.1f r(mean)*100

			
			sum SWpnc_couns_vax if `RowVar'==`i' & pnc_none_facility==1 [aw=SWweight]
			local mean4: disp %3.1f r(mean)*100

			sum SWpnc_couns_feeding if `RowVar'==`i' & pnc_none_facility==1 [aw=SWweight]
			local mean5: disp %3.1f r(mean)*100
			
			sum SWpnc_couns_growth if `RowVar'==`i' & pnc_none_facility==1 [aw=SWweight]
			local mean6: disp %3.1f r(mean)*100
			count if `RowVar'==`i' & pnc_none_facility==1
			local n_3=r(N)
			
			
			putexcel A`row'=("`CellContents'") B`row'=(`mean1') D`row'=(`mean2') F`row'=(`mean3') G`row'=(`mean4') H`row'=(`mean5') I`row'=(`mean6') , left nformat(0.0)	
			
			if `n_1'>=25 & `n_1'<=49 {
				putexcel B`row'=("(`mean1')"), left nformat(0.0)
				}
			if `n_2'>=25 & `n_1'<=49 {
				putexcel D`row'=("(`mean2')"), left nformat(0.0) 
				}
			if `n_3'>=25 & `n_1'<=49 {
				putexcel F`row'=("(`mean3')") G`row'=("(`mean4')") H`row'=("(`mean5')") I`row'=("(`mean6')"), left nformat(0.0) 
				}
			
			if `n_1'<25 {
				putexcel B`row'=("*")
				}
			if `n_2'<25 {
				putexcel D`row'=("*")
				}
			if `n_3'<25 {
				putexcel F`row'=("*") G`row'=("*") H`row'=("*") I`row'=("*")
				}
				
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	Counseling at PNC overall
sum SWpnc_ppfp_couns if facility_deliv==1 [aw=SWweight] 
local mean1: disp %3.1f r(mean)*100
count if facility_deliv==1 
if r(N)!=0 local n_1= r(N)

sum anyfp if anypnc==1 [aw=SWweight]
local mean2: disp %3.1f r(mean)*100
count if anypnc==1
if r(N)!=0 local n_2= r(N)

sum SWpnc_couns_breastfeed if pnc_none_facility==1 [aw=SWweight] 
local mean3: disp %3.1f r(mean)*100
sum SWpnc_couns_vax if pnc_none_facility==1 [aw=SWweight]
local mean4: disp %3.1f r(mean)*100
sum SWpnc_couns_feeding if pnc_none_facility==1 [aw=SWweight]
local mean5: disp %3.1f r(mean)*100
sum SWpnc_couns_growth if pnc_none_facility==1 [aw=SWweight]
local mean6: disp %3.1f r(mean)*100
count if pnc_none_facility==1 
if r(N)!=0 local n_3= r(N)

putexcel B`row'=(`mean1') D`row'=(`mean2') F`row'=(`mean3') G`row'=(`mean4') H`row'=(`mean5') I`row'=(`mean6'), left nformat(0.0)	
putexcel C`row'=(`n_1') E`row'=(`n_2') J`row'=(`n_3'), left nformat(number_sep)

local row=`row'+2
putexcel A`row'=("NOTE: Estimates based on 25-49 unweighted samples are reported inside parentheses in the report. Estimates based on less than 25 unweighted samples are suppressed."), italic

*** PPFP (use of modern contraception) ***
replace SWcurrent_methodnum=current_methodnum if baseline_status==3

*	New category for delivery place 
gen deliv_place_new=0
replace deliv_place_new=1 if SWdeliv_place==1 | SWdeliv_place==2
replace deliv_place_new=2 if SWdeliv_place==11
replace deliv_place_new=3 if SWdeliv_place==12 | SWdeliv_place==13
replace deliv_place_new=4 if SWdeliv_place==21 | SWdeliv_place==31 | SWdeliv_place==36 | SWdeliv_place==96

label define deliv_place_l 1 "Home" 2 "Public hospital" 3 "Public HC or lower" 4 "Other"
label values deliv_place_new deliv_place_l

*	Use of any modern contraception 
gen modern=0
replace modern=1 if SWcurrent_methodnum<=9

replace SWrecent_birth_w=recent_birth_w if baseline_status==3
gen pp_9=0
replace pp_9=1 if SWrecent_birth_w>=9
label define pp_l 0 "<9 weeks pp at interview" 1 ">=9 weeks pp at interview"
label val pp_9 pp_l

*	Method received after delivery 
replace SWpnc_ppfp_method=pnc_ppfp_method if baseline_status==3
gen any_mcp=0
replace any_mcp=1 if SWpnc_ppfp_method!=.

*	Set up putexcel
putexcel set "PMAET_Cohort1_6W_MNHAnalysis_$date.xlsx", sheet("Table20") modify
putexcel A1=("Table 20. Postpartum family planning use"), bold underline
putexcel A2=("Percent distribution of women who received any modern contraceptive methods after delivery among women who delivered at a health facility, and the proportion of women using any modern contraception other than Lactational Amenorrhea Method (LAM) by the time of their 6-week interview among all women, PMA Ethiopia 2019-2021 Cohort"), italic
putexcel A3=("Background characteristics" ) B3=("Immediate PPFP") C3=("Number of women with faciltiy delivery") D3=("PPFP at 6 week") E3=("Number of women (weighted)")
putexcel A4=("Age") A12=("Education") A18=("Parity") A24=("Region") A32=("Residence") A36=("Wealth") A43=("Facility type") A49=("Overall"), bold

*	PPFP use by background characteristics
local row = 5
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile deliv_place_new {
        
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SWweight] if facility_deliv==1, matcell(a)
	putexcel C`row'=matrix(a), left nformat(number_sep)
	tabulate `RowVar' [aw=SWweight] if pp_9==0, matcell(a)
	putexcel E`row'=matrix(a), left nformat(number_sep)

	forvalues i = 1/`RowCount' {
		sum any_mcp if `RowVar'==`i' & facility_deliv==1 [aw=SWweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			count if `RowVar'==`i' & facility_deliv==1 
			if r(N)!=0 local n_1= r(N)
			
			sum modern if `RowVar'==`i' & pp_9==0 [aw=SWweight]
			local mean2: disp %3.1f r(mean)*100
			count if `RowVar'==`i' & pp_9==0  
			if r(N)!=0 local n_2= r(N)
			
			putexcel A`row'=("`CellContents'") B`row'=(`mean1') D`row'=(`mean2'), left nformat(0.0)	
			
			if `n_1'>=25 & `n_1'<=49 {
				putexcel B`row'=("(`mean1')"), left nformat(0.0)
				}
			if `n_2'>=25 & `n_1'<=49 {
				putexcel D`row'=("(`mean2')"), left nformat(0.0) 
				}
				
			if `n_1'<25 {
				putexcel B`row'=("*")
				}
			if `n_2'<25 {
				putexcel D`row'=("*")
				}
				
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	PPFP overall
sum any_mcp [aw=SWweight] if facility_deliv==1
local mean1: disp %3.1f r(mean)*100
count if facility_deliv==1
if r(N)!=0 local n_1= r(N)

sum modern [aw=SWweight] if pp_9==0
local mean2: disp %3.1f r(mean)*100
count if pp_9==0
if r(N)!=0 local n_2= r(N)

putexcel B`row'=(`mean1') D`row'=(`mean2'), left nformat(0.0)	
putexcel C`row'=(`n_1') E`row'=(`n_2'), left nformat(number_sep)
putexcel D44=("-") D45=("-") D46=("-") E44=("-") E45=("-") E46=("-") E47=("")

local row=`row'+2
putexcel A`row'=("NOTE: Estimates based on 25-49 unweighted samples are reported inside parentheses in the report. Estimates based on less than 25 unweighted samples are suppressed."), italic

*******************************************************************************
**						NEONATES-RELATED INDICATORS               		**   
*******************************************************************************

*	Changing the data into long format to handle twins data

*Replace 6-week variables with data from baseline for 5-9 weeks postpartum at baseline women
foreach var of varlist pregnancy_type deliv_baby_weighed applied_cord_yn applied_cord cord_cut_used ///
 cord_cut_boiled birth*_outcome baby*_alive baby*_cry baby*_normalcry baby*_wrapped baby*_wrapped_min ///
 baby*_placednaked baby*_firstbreast_timing baby*_firstbreast_timing_val baby*_vax_bcg baby*_vax_polio_oral /// 
 baby*_fed_breastmilk baby*_fed_vitamins baby*_fed_water baby*_fed_juice baby*_fed_ors baby*_fed_formula ///
 baby*_fed_milk baby*_fed_tonic baby*_fed_otherliquid baby*_fed_else  {
		replace SW`var'=`var' if baseline_status==3
		}
		

preserve

keep SWpregnancy_type SWdeliv_baby_weighed SWapplied_cord_yn SWapplied_cord SWcord_cut_used ///
 SWcord_cut_boiled SWbirth*_outcome_cc SWbaby*_alive SWbaby*_cry SWbaby*_normalcry SWbaby*_wrapped SWbaby*_wrapped_min ///
 SWbaby*_placednaked SWbaby*_firstbreast_timing SWbaby*_firstbreast_timing_val SWbaby*_vax_bcg SWbaby*_vax_polio_oral /// 
 SWbaby*_fed_breastmilk SWbaby*_fed_vitamins SWbaby*_fed_water SWbaby*_fed_juice SWbaby*_fed_ors SWbaby*_fed_formula ///
 SWbaby*_fed_milk SWbaby*_fed_tonic SWbaby*_fed_otherliquid SWbaby*_fed_else baseline_status age_recode /// 
 education_recode parity_recode region_recode urban_recode wealthquintile delivery_location SWweight ///
 FQmetainstanceID SWmetainstanceID facility_deliv pp_9 SWQREversion

*	Reshape data 
unab kid_var : SWbirth1_outcome_cc-SWbaby1_vax_polio_oral
local stubs: subinstr local kid_var "1" "@", all
gen mother_ID=FQmetainstanceID
replace mother_ID=SWmetainstanceID if mother_ID==""

reshape long `stubs', i(mother_ID) j(index)
bysort mother_ID: drop if _n==2 & SWpregnancy_type!=2

*	Baby weighted recode
recode SWdeliv_baby_weighed (-88=0)

*	Baby wrapped within 5 minutes after birth 
recode SWbaby_wrapped(-88=0)
gen wrapped_5min=0 if SWbirth_outcome_cc==1
replace wrapped_5min=1 if SWbaby_wrapped_min <= 5

*	Cried normally recode 
recode SWbaby_normalcry (-88 -99=0)

*	Skin-to-skin recode
recode SWbaby_placednaked(-88 -99=0)

*	Skin-to-skin contact within 1 hour 
gen skin_1hr=0 if SWbirth_outcome_cc==1
replace skin_1hr=1 if SWbaby_firstbreast_timing==1 | (SWbaby_firstbreast_timing==2 & SWbaby_firstbreast_timing_val<=1)

*	Set up putexcel
putexcel set "PMAET_Cohort1_6W_MNHAnalysis_$date.xlsx", sheet("Table21") modify
putexcel A1=("Table 21. Immediate Neonatal Care"), bold underline
putexcel A2=("Percent distribution of infants who were weighed at birth among facility births, and the proportion of infants who were wrapped at birth, wrapped within 5 minutes of birth, cried normally at birth, placed skin-to-skin with mothers immediately after birth, and breastfed within 1 hour of birth among all live birth, by mother's background characteristics, PMA Ethiopia 2019-2021 Cohort"), italic
putexcel A3=("Background characteristics" ) B3=("Infants weighed at birth") C3=("Number of infants born in health facility (weighted)") D3=("Infants wrapped at birth") E3=("Infants wrapped within 5 minutes of birth") F3=("Infants who cried/breathed normally at birth") G3=("Infants placed immediately skin-to-skin with mother's chest") H3=("Infants with immediate skin-to-skin contact") I3=("Number of live births (weighted)")

putexcel A4=("Age") A12=("Education") A18=("Parity") A24=("Region") A32=("Residence") A36=("Wealth") A44=("Overall"), bold

*	Immediate neonatal care by background characteristics
local row = 5
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile {
        
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SWweight] if facility_deliv==1, matcell(a)
	putexcel C`row'=matrix(a), left nformat(number_sep)
	tabulate `RowVar' [aw=SWweight] if SWbirth_outcome_cc==1, matcell(a)
	putexcel I`row'=matrix(a), left nformat(number_sep)

	forvalues i = 1/`RowCount' {
		sum SWdeliv_baby_weighed if `RowVar'==`i' & facility_deliv==1 [aw=SWweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum SWbaby_wrapped if `RowVar'==`i' & SWbirth_outcome_cc==1 [aw=SWweight]
			local mean2: disp %3.1f r(mean)*100
			
			sum wrapped_5min if `RowVar'==`i' & SWbirth_outcome_cc==1 [aw=SWweight]
			local mean3: disp %3.1f r(mean)*100
			
			sum SWbaby_normalcry if `RowVar'==`i' & SWbirth_outcome_cc==1 [aw=SWweight]
			local mean4: disp %3.1f r(mean)*100
			
			sum SWbaby_placednaked if `RowVar'==`i' & SWbirth_outcome_cc==1 [aw=SWweight]
			local mean5: disp %3.1f r(mean)*100
						
			sum skin_1hr if `RowVar'==`i' & SWbirth_outcome_cc==1 [aw=SWweight]
			local mean6: disp %3.1f r(mean)*100
			
			putexcel A`row'=("`CellContents'") B`row'=(`mean1') D`row'=(`mean2') E`row'=(`mean3') F`row'=(`mean4') G`row'=(`mean5') H`row'=(`mean6'), left nformat(0.0)	
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	Immediate neonatal care overall
sum SWdeliv_baby_weighed [aw=SWweight] if facility_deliv==1
local mean1: disp %3.1f r(mean)*100
count if facility_deliv==1
if r(N)!=0 local n_1= r(N)

sum SWbaby_wrapped [aw=SWweight] if SWbirth_outcome_cc==1
local mean2: disp %3.1f r(mean)*100
sum wrapped_5min [aw=SWweight] if SWbirth_outcome_cc==1
local mean3: disp %3.1f r(mean)*100
sum SWbaby_normalcry [aw=SWweight] if SWbirth_outcome_cc==1
local mean4: disp %3.1f r(mean)*100
sum SWbaby_placednaked [aw=SWweight] if SWbirth_outcome_cc==1
local mean5: disp %3.1f r(mean)*100
sum skin_1hr [aw=SWweight] if SWbirth_outcome_cc==1
local mean6: disp %3.1f r(mean)*100

count if SWbirth_outcome_cc==1
if r(N)!=0 local n_2= r(N)

putexcel B`row'=(`mean1') D`row'=(`mean2') E`row'=(`mean3') F`row'=(`mean4') G`row'=(`mean5') H`row'=(`mean6'), left nformat(0.0)	
putexcel C`row'=(`n_1') I`row'=(`n_2'), left nformat(number_sep)

local row=`row'+2
putexcel A`row'=("NOTE: Estimates based on 25-49 unweighted samples are reported inside parentheses in the report. Estimates based on less than 25 unweighted samples are suppressed."), italic

*** Care of umbilical cord *** 

*	Generate binary variables for instrument used to cut cord 
gen surg_blade=0 if SWbirth_outcome_cc==1 // surgical blade 
replace surg_blade=1 if SWcord_cut_used==1 
gen razor_blade=0 if SWbirth_outcome_cc==1 // razor blade
replace razor_blade=1 if SWcord_cut_used==2
gen bamboo=0 if SWbirth_outcome_cc==1 //bamboo
replace bamboo=1 if SWcord_cut_used==3
gen scissors=0 if SWbirth_outcome_cc==1 // scissors
replace scissors=1 if SWcord_cut_used==4
gen cord_ins_other=0 if SWbirth_outcome_cc==1 // other 
replace cord_ins_other=1 if SWcord_cut_used==96
gen cord_ins_dnk=0 if SWbirth_outcome_cc==1 //DNK
replace cord_ins_dnk=1 if SWcord_cut_used==-88

*	Set up putexcel
putexcel set "PMAET_Cohort1_6W_MNHAnalysis_$date.xlsx", sheet("Table22") modify
putexcel A1=("Table 22. Care of the Umbilical Cord - Instrument Used"), bold underline
putexcel A2=("Percent distribution of the instrument used to cut the umbilical cord among all live births, by mother's background characteristics, PMA Ethiopia 2019-2021 Cohort"), italic
putexcel A3=("Background characteristics" ) B3=("Surgical blade") C3=("Razor blade") D3=("Bamboo strips") E3=("Scissors") F3=("Other") G3=("Do not know") H3=("Number of live births (weighted)")

putexcel A4=("Age") A12=("Education") A18=("Parity") A24=("Region") A32=("Residence") A36=("Wealth") A44=("Overall"), bold

*	Instrument used to cut cord by background characteristics
local row = 5
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile {
        
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SWweight] if SWbirth_outcome_cc==1, matcell(a)
	putexcel H`row'=matrix(a), left nformat(number_sep)

	forvalues i = 1/`RowCount' {
		sum surg_blade if `RowVar'==`i' & SWbirth_outcome_cc==1 [aw=SWweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum razor_blade if `RowVar'==`i' & SWbirth_outcome_cc==1 [aw=SWweight]
			local mean2: disp %3.1f r(mean)*100
			
			sum bamboo if `RowVar'==`i' & SWbirth_outcome_cc==1 [aw=SWweight]
			local mean3: disp %3.1f r(mean)*100
			
			sum scissors if `RowVar'==`i' & SWbirth_outcome_cc==1 [aw=SWweight]
			local mean4: disp %3.1f r(mean)*100
			
			sum cord_ins_other if `RowVar'==`i' & SWbirth_outcome_cc==1 [aw=SWweight]
			local mean5: disp %3.1f r(mean)*100
						
			sum cord_ins_dnk if `RowVar'==`i' & SWbirth_outcome_cc==1 [aw=SWweight]
			local mean6: disp %3.1f r(mean)*100
			
			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6'), left nformat(0.0)	
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	Instrument used to cut cord overall
sum surg_blade [aw=SWweight] if SWbirth_outcome_cc==1
local mean1: disp %3.1f r(mean)*100
sum razor_blade [aw=SWweight] if SWbirth_outcome_cc==1
local mean2: disp %3.1f r(mean)*100
sum bamboo [aw=SWweight] if SWbirth_outcome_cc==1
local mean3: disp %3.1f r(mean)*100
sum scissors [aw=SWweight] if SWbirth_outcome_cc==1
local mean4: disp %3.1f r(mean)*100
sum cord_ins_other [aw=SWweight] if SWbirth_outcome_cc==1
local mean5: disp %3.1f r(mean)*100
sum cord_ins_dnk [aw=SWweight] if SWbirth_outcome_cc==1
local mean6: disp %3.1f r(mean)*100

count if SWbirth_outcome_cc==1
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6'), left nformat(0.0)	
putexcel H`row'=(`n_1'), left nformat(number_sep)

*** Instrument boiled before use ***
*(only including surgical blade, razor blade, and scissors)

recode SWcord_cut_boiled(-99=-88)

*	Binary variables for instrument boiled 
gen boiled_yes=0 if surg_blade==1 | razor_blade==1 | scissors==1 
replace boiled_yes=1 if SWcord_cut_boiled==1
gen boiled_no=0 if surg_blade==1 | razor_blade==1 | scissors==1 
replace boiled_no=1 if SWcord_cut_boiled==0
gen boiled_new=0 if surg_blade==1 | razor_blade==1 | scissors==1 
replace boiled_new=1 if SWcord_cut_boiled==-77
gen boiled_dnk=0 if surg_blade==1 | razor_blade==1 | scissors==1 
replace boiled_dnk=1 if SWcord_cut_boiled==-88

*	Set up putexcel
putexcel set "PMAET_Cohort1_6W_MNHAnalysis_$date.xlsx", sheet("Table23") modify
putexcel A1=("Table 23. Care of the Umbilical Cord - Instrument Boiled"), bold underline
putexcel A2=("Percent distribution of whether the instrument used to cut the cord was boiled before use, by background characteristics, among live births whose cord was cut using surgical blade, razor blade or scissors, PMA Ethiopia 2019-2021 Cohort"), italic
putexcel A3=("Background characteristics" ) B3=("Yes") C3=("No") D3=("New blade / no need to boil") E3=("Do not know") F3=("Number of live births (weighted)")

putexcel A4=("Age") A12=("Education") A18=("Parity") A24=("Region") A32=("Residence") A36=("Wealth") A44=("Overall"), bold

*	Instrument boiled before use by background characteristics
local row = 5
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile {
        
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SWweight] if SWbirth_outcome_cc==1 & (surg_blade==1 | razor_blade==1 | scissors==1 ), matcell(a)
	putexcel F`row'=matrix(a), left nformat(number_sep)

	forvalues i = 1/`RowCount' {
		sum boiled_yes if `RowVar'==`i' & SWbirth_outcome_cc==1 & (surg_blade==1 | razor_blade==1 | scissors==1) [aw=SWweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum boiled_no if `RowVar'==`i' & SWbirth_outcome_cc==1 & (surg_blade==1 | razor_blade==1 | scissors==1) [aw=SWweight]
			local mean2: disp %3.1f r(mean)*100
			
			sum boiled_new if `RowVar'==`i' & SWbirth_outcome_cc==1 & (surg_blade==1 | razor_blade==1 | scissors==1) [aw=SWweight]
			local mean3: disp %3.1f r(mean)*100
			
			sum boiled_dnk if `RowVar'==`i' & SWbirth_outcome_cc==1 & (surg_blade==1 | razor_blade==1 | scissors==1) [aw=SWweight]
			local mean4: disp %3.1f r(mean)*100
			
			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4'), left nformat(0.0)	
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	Instrument boiled before use overall
sum boiled_yes [aw=SWweight] if SWbirth_outcome_cc==1 & (surg_blade==1 | razor_blade==1 | scissors==1 )
local mean1: disp %3.1f r(mean)*100
sum boiled_no [aw=SWweight] if SWbirth_outcome_cc==1 & (surg_blade==1 | razor_blade==1 | scissors==1 )
local mean2: disp %3.1f r(mean)*100
sum boiled_new [aw=SWweight] if SWbirth_outcome_cc==1 & (surg_blade==1 | razor_blade==1 | scissors==1 )
local mean3: disp %3.1f r(mean)*100
sum boiled_dnk [aw=SWweight] if SWbirth_outcome_cc==1 & (surg_blade==1 | razor_blade==1 | scissors==1 )
local mean4: disp %3.1f r(mean)*100

count if SWbirth_outcome_cc==1 & (surg_blade==1 | razor_blade==1 | scissors==1 )
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4'), left nformat(0.0)	
putexcel F`row'=(`n_1'), left nformat(number_sep)

	
*******************************************************************************
**								NEONATAL PNC   			          		**   
*******************************************************************************

*** Infant vaccination ***
recode SWbaby_vax_bcg (-88 -99=0)
recode SWbaby_vax_polio_oral (-88 -99=0)

*	Set up putexcel
putexcel set "PMAET_Cohort1_6W_MNHAnalysis_$date.xlsx", sheet("Table24") modify
putexcel A1=("Table 24. Infant vaccination"), bold underline
putexcel A2=("Percent distribution of live births who received BCG vaccination and oral polio vaccination by the time of their mothers' 6-week interviews, among all live births, PMA Ethiopia 2019-2021 Cohort"), italic
putexcel A3=("Background characteristics" ) B3=("BCG Vaccination") C3=("Oral polio vaccination") D3=("Number of live births (weighted)")

putexcel A4=("Age") A12=("Education") A18=("Parity") A24=("Region") A32=("Residence") A36=("Wealth") A44=("Overall"), bold

*	Infant vaccination by background characteristics
local row = 5
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile {
        
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SWweight] if SWbirth_outcome_cc==1, matcell(a)
	putexcel D`row'=matrix(a), left nformat(number_sep)

	forvalues i = 1/`RowCount' {
		sum SWbaby_vax_bcg [aw=SWweight] if `RowVar'==`i' & SWbirth_outcome_cc==1 
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum SWbaby_vax_polio_oral if `RowVar'==`i' & SWbirth_outcome_cc==1 [aw=SWweight]
			local mean2: disp %3.1f r(mean)*100
			
			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2'), left nformat(0.0)	
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	Infant vaccination overall
sum SWbaby_vax_bcg [aw=SWweight] if SWbirth_outcome_cc==1
local mean1: disp %3.1f r(mean)*100
sum SWbaby_vax_polio_oral [aw=SWweight] if SWbirth_outcome_cc==1 
local mean2: disp %3.1f r(mean)*100

count if SWbirth_outcome_cc==1
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2'), left nformat(0.0)	
putexcel D`row'=(`n_1'), left nformat(number_sep)


*** Exclusive breastfeeding (among those <9 weeks postpartum at interview) *** 
recode SWbaby_fed* (-88 -99=0)  
egen babyfed_count=rowtotal(SWbaby_fed*) 
 
gen exclusive_bf=0 if SWbaby_alive==1 
replace exclusive_bf=1 if babyfed_count==1 & SWbaby_fed_breastmilk==1 
label var exclusive_bf "Was the baby exclusively breastfed in the last 24 hrs" 
label val exclusive_bf yes_no_list 
tab exclusive_bf [aw=SWweight] if pp_9==0

*	Set up putexcel
putexcel set "PMAET_Cohort1_6W_MNHAnalysis_$date.xlsx", sheet("Table25") modify
putexcel A1=("Table 25. Exclusive Breastfeeding"), bold underline
putexcel A2=("Percent distribution of live births who were exclusively breastfed within the last 24 hours, among infants who were less than 9 weeks old and still alive at the time of the interview, PMA Ethiopia 2019-2021 Cohort"), italic
putexcel A3=("Background characteristics" ) B3=("Percent") C3=("Number of infants still alive (weighted)")

putexcel A4=("Age") A12=("Education") A18=("Parity") A24=("Region") A32=("Residence") A36=("Wealth") A44=("Overall"), bold

*	EBF by background characteristics
local row = 5
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile {
        
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SWweight] if SWbaby_alive==1 & pp_9==0, matcell(a)
	putexcel C`row'=matrix(a), left nformat(number_sep)

	forvalues i = 1/`RowCount' {
		sum exclusive_bf if `RowVar'==`i' & SWbaby_alive==1 & pp_9==0  [aw=SWweight]
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			putexcel A`row'=("`CellContents'") B`row'=(`mean1'), left nformat(0.0)	
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	EBF overall
sum exclusive_bf [aw=SWweight] if SWbaby_alive==1 & pp_9==0
local mean1: disp %3.1f r(mean)*100

count if SWbaby_alive==1 & pp_9==0
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1'), left nformat(0.0)	
putexcel C`row'=(`n_1'), left nformat(number_sep)

local row=`row'+ 2
putexcel A`row'=("Note: Due to COVID-19, 825 women were interviewed 9 weeks or more postpartum. To calculate the proportion of babies exclusively breastfed by approximately 6-weeks, babies that were 9 or more weeks postpartum at the time of the interview were excluded."), italic

restore 

*	Save data
save "`outputdir'/PMAET_`COHORT'_6W_MNHAnalysis_PR_$date.dta", replace  

log close 
