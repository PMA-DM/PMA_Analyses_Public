/*******************************************************************************
*PMA Ethiopia Cohort 1 Six-Month Maternal and Newborn Technical Report .do file*

*   The following .do file will create the .xlsx file output that PMA Ethiopia used
*	to produce the PMA Ethiopia Six-Month Postpartum Maternal and Newborn Health
	Technical Report, 2019-2021 Cohort, using PMA Ethiopia's publicly 
*	available baseline and 6-month postpartum follow-up dataset. 
*
*
*   If you have any questions on how to use this .do files, please contact 
*	Ellie Qian at jqian@jhu.edu.
*******************************************************************************/


/*******************************************************************************
*
*	FILENAME:		PMAET_Cohort1_6M_MNHTechnicalReport_PR.do
*	PURPOSE:		Generate the .xls output for the PMA Ethiopia 6-month MNH report 
*	CREATED BY: 	Ellie Qian (jqian@jhu.edu)
*	DATA IN:		PMA Ethiopia's publicly released baseline dataset for Cohort 1
*					PMA Ethiopia's publicly released 6-week dataset for Cohort 1
*					PMA Ethiopia's publicly released 6-month dataset for Cohort 1
*	DATA OUT: 		PMAET_Cohort1_6M_MNHAnalysis_PR_DATE.dta
*   FILE OUT: 		PMAET_Cohort1_6M_MNHAnalysis_DATE.xlsx
*   LOG FILE OUT: 	PMAET_Cohort1_6M_MNHAnalysis_PR_DATE.log
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
set maxvar 15000
set more off
numlabel, add

********************************************************************************
*******************   SECTION 1: CREATE MACRO FOR DATE   *********************** 
*
*   Section 1 is necessary to make sure the .do file runs correctly, 
*		please do not move, update or delete
*
********************************************************************************

*	Set local/global macros for current date
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
*  		in quotation marks ("`localmacro'").
*
********************************************************************************

*** 1. Set directory for the publicly available PMA2020 dataset on your computer
*	- For example (Mac): 
*		local datadir "/Users/ellieee/Desktop/PMAET/Technical_Report/SDP/PublicRelease"
*	- For example (PC):
*		local datadir "C:\Users\annro\PMA2020"

local baselinedata "/Users/ellieqian/Dropbox (Gates Institute)/PMAET2_Datasets/1-Cohort1/1-Baseline/Final_PublicRelease/PMAET_HQFQ_Panel_Cohort1_BL_v2.0_19May2021/PMAET_HQFQ_Panel_Cohort1_BL_v2.0_19May2021.dta"

local sixweekdata "/Users/ellieqian/Dropbox (Gates Institute)/PMAET2_Datasets/1-Cohort1/2-6Week/Final_PublicRelease/PMAET_Panel_Cohort1_6wkFU_v2.0_6May2022/PMAET_HQFQ_Panel_Cohort1_6wkFU_v2.0_6May2022.dta"

local sixmonthdata "/Users/ellieqian/Dropbox (Gates Institute)/PMAET2_Datasets/1-Cohort1/3-6Month/Final_PublicRelease/PMAET_Panel_Cohort1_6moFU_v2.0_6May2022/PMAET_Panel_Cohort1_6moFU_v2.0_6May2022.dta"


*** 2. Set directory for the folder where you want to save the dataset, xlsx and
*			log files that this .do file creates
*	- For example (Mac): 
*		  local briefdir "/Users/ellieee/Desktop/PMAET/Technical_Report/SDP/PublicRelease"
*	- For example (PC): 
*		  local briefdir "C:\Users\annro\PMAEthiopia\SDPOutput"
local datadir "/Users/ellieqian/OneDrive - Johns Hopkins/PMAET/Technical_Report/6m/data"

local outputdir "/Users/ellieqian/OneDrive - Johns Hopkins/PMAET/Technical_Report/6m/analysis_$date"
capture mkdir "`outputdir'"

*** 3. Set cohort macro
local COHORT Cohort1 


********************************************************************************
**********   SECTION 3: MERGING BASELINE, 6-WEEK, AND 6-MONTH DATA  ************
********************************************************************************

*	Change to output directory
cd "`outputdir'"

*	Create log file 
log using "PMAET_`COHORT'_6M_MNHAnalysis_PR_$date.log", replace

*	Prepare Baseline for merge
use "`baselinedata'", clear
keep if FRS_result!=.

keep EA_ID memberID participant_ID baseline_followup baseline_status recent_birthSIF FQ_age birth_events_rw school ur region wealthquintile FRS_result strata

*	Create a dummy participant ID for women who did not complete the baseline
tostring EA_ID, replace
replace participant_ID=EA_ID+"_"+memberID if participant_ID==""
duplicates drop participant_ID, force

tempfile base
save `base'.dta, replace

*	Prepare 6-week for Merge
use "`sixweekdata'" , clear

keep SWmetainstanceID participant_ID SW_result recent_birthSIF recent_birth_m_dnk consent available birth*_outcome_cc pregnancy_type

foreach var of varlist _all {
	rename `var' SW`var'
	}
rename SWSWmetainstanceID SWmetainstanceID
rename SWparticipant_ID participant_ID
rename SWSW_result SWresult
duplicates drop participant_ID, force

tempfile sw
save `sw'.dta, replace

*	Merge Baseline and 6 Week
use `base'.dta, clear

merge 1:1 participant_ID using `sw'.dta, gen(sw_merge)
drop if sw_merge==2

tempfile merge
save `merge'.dta, replace

*	Prepare 6-month for Merge
use "`sixmonthdata'" , clear

rename covid_trust_source_healthworker covid_trust_source_hw

foreach var of varlist _all {
	rename `var' SM`var'
	}
rename SMSMmetainstanceID SMmetainstanceID
rename SMparticipant_ID participant_ID
rename SMSMFUweight SMFUweight
rename SMSM_result SMresult

duplicates drop participant_ID, force

tempfile sm 
save `sm'.dta, replace

*	Merge Baseline, Panel Pregnancy, 6 Week, and 6 month
use `merge'.dta, clear

merge 1:1 participant_ID using `sm'.dta, gen(sm_merge)
drop if sm_merge==2

*	Replace dummy participant ID=.
capture tostring memberID EA_ID
replace participant_ID="" if participant_ID==EA_ID+"_"+memberID & FRS_result!=1

/*
	One participant refused future follow up in 6-week. The public release data 
	does not have this variable so manually coding her to refused 
*/

capture drop sw_followup
gen sw_followup=.
replace sw_followup=1 if SWresult==1 & SWmetainstanceID!="VZMY2DI3PS052VYKSX7U7TWRA"
replace sw_followup=2 if SWconsent==1 & SWmetainstanceID!="VZMY2DI3PS052VYKSX7U7TWRA" & SWresult!=1
replace sw_followup=3 if SWresult==4
replace sw_followup=4 if SWmetainstanceID=="VZMY2DI3PS052VYKSX7U7TWRA" & SWresult==1
replace sw_followup=5 if SWresult==8 | SWresult==9
replace sw_followup=6 if SWresult!=1 & sw_followup==. & SWresult!=.
replace sw_followup=7 if SWavailable==3 
replace sw_followup=8 if SWresult==13
replace sw_followup=9 if SWbirth1_outcome_cc!=1 & SWbirth2_outcome_cc!=1 & SWresult==1
replace sw_followup=10 if (baseline_followup==1 | baseline_followup==2) & sw_followup==.
label define fu_list 1 "Completed and consented to FU" 2 "Incomplete but consented to FU" 3 "Refused" 4 "Refused follow-up" 5 "Respondent/Household moved" 6 "Incomplete, did not refuse" 7 "Respondent died" 8 "False pregnancy" 9 "No live births" 10 "Consented at baseline"
label val sw_followup fu_list 
label var sw_followup "Does the woman consent to FU after 6-week"
tab sw_followup

capture drop fu_after_6w
gen fu_after_6w=0 if SWresult!=.
replace fu_after_6w=1 if sw_followup==1 | sw_followup==2
replace fu_after_6w=-88 if sw_followup==6 | sw_followup==5
label val fu_after_6w yes_no_dnk_nr_list
label var fu_after_6w "Should this woman be followed up after 6-week"

capture drop sm_followup
gen sm_followup=.
replace sm_followup=1 if (SMresult==1 | SMresult==2) & SMrefused_follow_up!=1
replace sm_followup=2 if (SMstill_consent_yn==1) & SMrefused_follow_up!=1 & SMresult!=1
replace sm_followup=3 if SMresult==4
replace sm_followup=4 if SMrefused_follow_up==1 & (SMresult==1 | SMresult==2)
replace sm_followup=5 if SMresult==9 | SMresult==10
replace sm_followup=6 if SMresult!=. & sm_followup==.
replace sm_followup=7 if SMavailable==3 
replace sm_followup=8 if SMresult==13
label val sm_followup fu_list 
label var sm_followup "Does the woman/caregiver consent to FU after 6-week"

capture drop fu_after_6m
gen fu_after_6m=0 if SMresult!=.
replace fu_after_6m=1 if sm_followup==1 | sm_followup==2
replace fu_after_6m=-88 if sm_followup==6 | sm_followup==5
label val fu_after_6m yes_no_dnk_nr_list
label var fu_after_6m "Should this woman/caregiver be followed up after 6-month"

save, replace
save "`datadir'/`COHORT'_Base_6W_6M_Merged.dta", replace


*******************************************************************************
*********************   SECTION 4: RESPONSE RATE		**************************
*******************************************************************************

use "`datadir'/`COHORT'_Base_6W_6M_Merged.dta", clear

*	Set survey weights
*	Create weight for all women with complete forms
svyset EA_ID [pweight=SMFUweight], strata(strata) singleunit(scaled)


*** Reponse rate *** 
*	Calculate overall response rate
count if SMresult!=.
local tot_elig = r(N)
count if  SMresult==1 
local tot_comp = r(N)

local responserate = string(`tot_comp' / `tot_elig' * 100, "%4.1f")  

*** Set up putexcel and output 
putexcel set PMAET_`COHORT'_6M_MNHAnalysis_$date.xlsx, sheet(Table1) replace
putexcel A1="Table 1. Six-Month Postpartum Follow-up Interview Response Rate and Mean Time to Interview", bold underline
putexcel A2=("Response Rate"), bold underline
putexcel B3=("Total"), hcenter
putexcel A5=("Number of eligible women") A4=("Number of eligible women who completed the interview") A6=("6-week interview response rate"), left
putexcel B4=(`tot_comp') B5=(`tot_elig'), nformat(number_sep) hcenter
putexcel B6=(`responserate'), hcenter nformat(0.0)  


*** Mean time to interview (among those who completed the interview *** 
*	Generate delivery date (6m and baseline data not used unless it's the only data available)
gen delivery_date=SWrecent_birthSIF if baseline_status==1
replace delivery_date=SMrecent_birthSIF if (baseline_status==1 & delivery_date==.) | SWrecent_birth_m_dnk==1
replace delivery_date=recent_birthSIF if baseline_status!=1 & (delivery_date==. | year(delivery_date)==2030)


*	Modify 6M interview date
replace SMtoday="2020-08-03" if SMtoday=="2020-08-03T14:00:00.000+03:00"
replace SMtoday="2020-08-04" if SMtoday=="2020-08-04T10:02:00.000+03:00"
replace SMtoday="2020-08-10" if SMtoday=="2020-08-10T11:48:00.000+03:00"
replace SMtoday="2020-08-10" if SMtoday=="2020-08-10T13:22:00.000+03:00"

drop SMtodaySIF
gen double SMtodaySIF= date(SMtoday, "YMD")
format SMtodaySIF %td
local today_lab : variable label SMtoday
label var SMtodaySIF "`today_lab' SIF"
order SMtodaySIF, after(SMtoday)

*	Months postpartum / Months Postpartum 
gen child_age=(SMtodaySIF-delivery_date)/30.5

*	Pre-COVID 
sum child_age if SMresult==1 & (SMQREversion==31 | SMQREversion==30) [aw=SMFUweight]
local tot_precov = r(N)
local mean_precov = string(r(mean), "%4.1f")

*	During COVID 
sum child_age if SMresult==1 & (SMQREversion==25) [aw=SMFUweight]
local tot_postcovid = r(N)
local mean_postcovid = string(r(mean), "%4.1f")

*	Overall 
sum child_age if SMresult==1 [aw=SMFUweight]
local tot_pp = r(N)
local mean_pp = string(r(mean), "%4.1f")

*** Putexcel mean time to interview 
putexcel A7=("Mean Time to Interview"), bold underline
putexcel B8=("Number of months postpartum") C8=("Number of women") A9=("Pre-COVID") A10=("During COVID") A11=("Overall")
putexcel B9=(`mean_precov') B10=(`mean_postcovid') B11=(`mean_pp'), nformat(0.0) hcenter
putexcel C9=(`tot_precov') C10=(`tot_postcovid') C11=(`tot_pp'), nformat(number_sep) hcenter

*******************************************************************************
*****************	SECTION 5: BACKGROUND CHARACTERISTICS	*******************
*******************************************************************************

*	Keep complete records (2,414 / 2,695)
*	NOTE: mother completed only (n = 2,414)
*		  caregiver completed (n = 1)

keep if SMresult==1

*	Generate age categories
egen age5=cut(FQ_age), at(15(5)50)
gen age_new=age5
replace age_new=40 if age5>=40
label define age_newl 15 "15-19" 20 "20-24" 25 "25-29" 30 "30-34" 35 "35-39" 40 "40-49" 
label val age_new age_newl
label var age_new "Age" 

*	Recode age for putexcel
recode age_new (15=1) (20=2) (25=3) (30=4) (35=5) (40=6), gen(age_recode)
label define age_recodel 1 "15-19" 2 "20-24" 3 "25-29" 4 "30-34" 5 "35-39" 6 "40-49" 
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
bysort FQ_age wealthquintile urban region school: replace birth_events_rw=birth_events_rw[_n+1] if birth_events_rw==.
replace birth_events_rw=birth_events_rw[_n+2] if birth_events_rw==.

*	Generate categorical variable for parity 
egen parity=cut(birth_events_rw), at(0, 1, 3, 5, 30) icodes
gen parity_recode=1 if parity==0
replace parity_recode=2 if parity==1
replace parity_recode=3 if parity==2
replace parity_recode=4 if parity==3
lab def parityl 1 "0 children" 2 "1-2 children" 3 "3-4 children" 4 "5+ children"
lab val parity_recode parityl
lab var parity_recode "Parity" 
tab parity_recode

*	Recode region for putexcel
recode region (7=5) (10=6), gen(region_recode)
label define region_list 1 "Tigray" 2 "Afar" 3 "Amhara" 4 "Oromiya" 5 "SNNP" 6 "Addis", modify
label val region_recode region_list
label var region_recode "Region"

*	Remove numbers from wealth quintile label 
label define wealthquintile_list 1 "Lowest quintile" 2 "Lower quintile" 3 "Middle quintile" 4 "Higher quintile" 5 "Highest quintile", modify

*	Categories for children's age
gen child_age_cat=.
replace child_age_cat=1 if child_age<=6.5
replace child_age_cat=2 if child_age>6.5 & child_age<=8
replace child_age_cat=3 if child_age>8
label define childage 1 "<=6.5 months" 2 "6.5-8 months" 3 ">8 months"
label values child_age_cat childage

*	Binary variable for children's age
gen child_age_bi=.
replace child_age_bi=0 if child_age<=7
replace child_age_bi=1 if child_age>7
label define childage_bi 0 "<=7 months" 1 ">7 months"
label values child_age_bi childage_bi
tab child_age_bi

*** Respondent background characteristic *** 
*** Set up putexcel and output 
putexcel set PMAET_`COHORT'_6M_MNHAnalysis_$date.xlsx, sheet(Table2) modify
putexcel A1=("Table 2. Background Characteristics of Respondents"), bold underline
putexcel A2=("Percent distribution of respondents by selected background characteristics and months postpartum, PMA Ethiopia 2019-2021 Cohort") A3=("Background characteristics") B3=("Weighted percent") C3=("Weighted N") D3=("Unweighted N")
putexcel A4=("Age") A12=("Education") A18=("Parity") A24=("Region") A32=("Residence") A36=("Wealth") A43=("Months Postpartum") A49=("Overall") , bold

local row = 5
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile child_age_cat {
	tabulate `RowVar', matcell(freq) matrow(names)
	local rows = rowsof(names)
	local RowValueLabel : value label `RowVar'
	
	svy: tab `RowVar'		
	tabulate `RowVar' [aw=SMFUweight], matcell(a)
	
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

count 
local n=r(N)
putexcel B`row'=(100.0), nformat(0.0) left
putexcel C`row'=(`n') D`row'=(`n'), nformat(number_sep) left

*******************************************************************************
**********************	 SECTION 6: CHILD HEALTH	***************************
******************************************************************************* 

*******************************************************************************
**** BACKGROUND CHARACTERISTICS (INFANT)
******************************************************************************* 

preserve 

*	Reshape data to long
rename SMbaby*_card_polio0 SMbaby*_card_poliooral

unab kid_var :  SMbaby1_alive-SMbaby1_where_died
local stubs: subinstr local kid_var "1" "@", all
local stubs: subinstr local stubs "polio@" "polio1", all
local stubs: subinstr local stubs "pentavalent@" "pentavalent1", all
local stubs: subinstr local stubs "pcv@" "pcv1", all
local stubs: subinstr local stubs "rota@" "rota1", all
local stubs: subinstr local stubs "measles@" "measles1", all

gen mother_ID=SMmetainstanceID

reshape long `stubs', i(mother_ID) j(index)
bysort mother_ID: drop if _n==2 & SMpregnancy_type!=2

*** Restrict children-level analysis to only children who were still alive
*	Note: Three women had twins and in all three one of the twins was a stillbirth
tab SMbaby_alive, m
drop if SMbaby_alive!=1

*** Mother's characteristic *** 
*** Set up putexcel and output 
putexcel set PMAET_`COHORT'_6M_MNHAnalysis_$date.xlsx, sheet(Table3) modify
putexcel A1=("Table 3. Background Characteristics of Children"), bold underline
putexcel A2=("Percent distribution of mother's selected background characteristics, among children still alive at time of the 6-month interview, PMA Ethiopia 2019-2021 Cohort") A3=("Background characteristics") B3=("Weighted percent") C3=("Weighted N") D3=("Unweighted N")
putexcel A4=("Mother's Age") A12=("Mother's Education") A18=("Mother's Parity") A24=("Mother's Region") A32=("Mother's Residence") A36=("Mother's Wealth") A43=("Age in Months") A49=("Overall") , bold

local row = 5
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile child_age_cat {
	tabulate `RowVar', matcell(freq) matrow(names)
	local rows = rowsof(names)
	local RowValueLabel : value label `RowVar'
	
	svy: tab `RowVar'		
	tabulate `RowVar' [aw=SMFUweight], matcell(a)
	
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

count 
local n=r(N)
putexcel B`row'=(100.0), nformat(0.0) left
putexcel C`row'=(`n') D`row'=(`n'), nformat(number_sep) left


*******************************************************************************
* CHILD HEALTH: BREASTFEEDING 
*******************************************************************************

*	Recode DNK and NR to 0
recode SMbaby_fed_* (-88 -99 .=0)

*** Breastfeeding pattern (RESTRICTED TO 5-7 MONTHS OLD INFANTS)
*** TENTATIVE DEFINITIONS *** 

*	Eaten food yesterday
gen eaten_food=0
replace eaten_food=1 if (SMbaby_fed_fort==1 | SMbaby_fed_grain==1 | SMbaby_fed_bean==1 | SMbaby_fed_dairy==1 | SMbaby_fed_ylw_veg==1 | SMbaby_fed_wht_veg==1 | SMbaby_fed_grn_veg==1 | SMbaby_fed_ripe_frt==1 | SMbaby_fed_oth_frt_veg==1 | SMbaby_fed_org==1 | SMbaby_fed_meat==1 | SMbaby_fed_egg==1 | SMbaby_fed_fish==1 | SMbaby_fed_other==1)
label val eaten_food yes_no_dnk_nr_list
label var eaten_food "Child ate any food yesterday"
	
*	Water-based liquid 
gen water_based=0
replace water_based=1 if (SMbaby_fed_water==1 | SMbaby_fed_unsweetjuice==1 | SMbaby_fed_sugar_juice==1 |SMbaby_fed_honey_juice==1 | SMbaby_fed_unsweettea==1 | SMbaby_fed_broth==1 | SMbaby_fed_sugar_tea==1 | SMbaby_fed_honey_tea==1 |SMbaby_fed_unsweetother==1 |SMbaby_fed_sweetother==1)
label val water_based yes_no_dnk_nr_list
label var water_based "Child drank water-based liquid yesterday"

*	Milk-based liquid 
gen milk_based=0
replace milk_based=1 if (SMbaby_fed_milk==1 | SMbaby_fed_formula==1 | SMbaby_fed_yogurt==1 | SMbaby_fed_unsweetgruel==1 | SMbaby_fed_unsweetfenugreek==1 | SMbaby_fed_porridge==1 | SMbaby_fed_sugar_gruel==1 | SMbaby_fed_honey_gruel==1 | SMbaby_fed_sugar_fenugreek==1 | SMbaby_fed_honey_fenugreek==1)
label val milk_based yes_no_dnk_nr_list
label var milk_based "Child drank milk-based liquid yesterday"

*	Not breastfeeding
*	Defined as did not eat breastmilk yesterday
gen not_bf=0 
replace not_bf=1 if SMbaby_fed_breastmilk==0
label val not_bf yes_no_dnk_nr_list
label var not_bf "Child that is not breastfed yesterday" 

*	Exclusive breastfeeding 
*	Defined as children that only ate breastmilk yesterday
gen exclusive_bf=0 
replace exclusive_bf=1 if SMbaby_fed_breastmilk==1 & water_based==0 & milk_based==0 & eaten_food==0
label val exclusive_bf yes_no_dnk_nr_list
label var exclusive_bf "Child that is exclusively breastfed"

*	Predominant breastfeeding
*	Defined as children that ate breast milk yesterday AND had a water based liquid yesterday AND no milk drinks AND no foods 
gen predominantly_bf=0 
replace predominantly_bf=1 if SMbaby_fed_breastmilk==1 & water_based==1 & milk_based==0 & eaten_food==0
label val predominantly_bf yes_no_dnk_nr_list
label var predominantly_bf "Child that is predominantly breastfed"

*	Partial breastfeeding
*	Defined as children ate breast milk yesterday and also had milk based liquids or also ate solid foods
gen partially_bf=0 
replace partially_bf=1 if (SMbaby_fed_breastmilk==1 & milk_based==1) | (SMbaby_fed_breastmilk==1 & eaten_food==1)
label val partially_bf yes_no_dnk_nr_list
label var partially_bf "Child that is partially breastfed"

tab1 not_bf exclusive_bf predominantly_bf partially_bf

*** Set up putexcel
putexcel set "PMAET_`COHORT'_6M_MNHAnalysis_$date.xlsx", sheet("Table4") modify
putexcel A1=("Table 4. Breastfeeding Pattern"), bold underline
putexcel A2=("Among children who were 5-7 months old, the percentage distribution of those who were not breastfed, breastfed partially, predominantly, and exclusively in the last 24 hours, by mother's background characteristics, PMA Ethiopia 2019-2021 Cohort")
putexcel B3=("Not breastfed") C3=("Partially breastfed") D3=("Predominantly breastfed") E3=("Exclusively breastfed") F3=("Number of children 5-7 months old (weighted)")
putexcel  A4=("Overall") A5=("Mother's Age") A13=("Mother's Education") A19=("Mother's Parity") A25=("Mother's Region") A33=("Mother's Residence") A37=("Mother's Wealth"), bold

*	Overall breastfeeding pattern 
local row = 4

sum not_bf [aw=SMFUweight] if child_age<=7
local mean1: disp %3.1f r(mean)*100
sum partially_bf [aw=SMFUweight] if child_age<=7
local mean2: disp %3.1f r(mean)*100
sum predominantly_bf [aw=SMFUweight] if child_age<=7
local mean3: disp %3.1f r(mean)*100
sum exclusive_bf [aw=SMFUweight] if child_age<=7
local mean4: disp %3.1f r(mean)*100

count if child_age<=7
if r(N)!=0 local n_1= r(N)
putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4'), left nformat(0.0)	bold
putexcel F`row'=(`n_1'), left nformat(number_sep) bold

*	Breastfeeding pattern by background characteristics
local row=6
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile {

	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SMFUweight] if child_age<=7, matcell(a)
	putexcel F`row'=matrix(a), left nformat(number_sep)

	forvalues i = 1/`RowCount' {
		sum not_bf if `RowVar'==`i' & child_age<=7 [aw=SMFUweight] 
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum partially_bf if `RowVar'==`i' & child_age<=7 [aw=SMFUweight]
			local mean2: disp %3.1f r(mean)*100
			
			sum predominantly_bf if `RowVar'==`i' & child_age<=7 [aw=SMFUweight] 
			local mean3: disp %3.1f r(mean)*100
			
			sum exclusive_bf if `RowVar'==`i' & child_age<=7 [aw=SMFUweight] 
			local mean4: disp %3.1f r(mean)*100
			
			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4'), left nformat(0.0)	
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}
 

*******************************************************************************
* CHILD HEALTH: VACCINATION AND VITAMIN A
*******************************************************************************

/*	Vaccination document verification
- 	No vaccination card (official or unofficial)
-	Official vaccination card, not verified
-	Official vaccination card, verified by RE
-	Non-official vaccination card, observed by RE 
-	Non-official vaccination card, not observed by RE */

gen vax_card_cat=0
replace vax_card_cat=1 if SMbaby_vax_card_moh==0 & SMbaby_vax_card_unofficial==0 
replace vax_card_cat=2 if SMbaby_vax_card_moh==1
replace vax_card_cat=3 if SMbaby_vax_card_moh==2
replace vax_card_cat=4 if SMbaby_vax_card_unofficial==1
replace vax_card_cat=5 if SMbaby_vax_card_unofficial==2
label define vax_card 1 "No vaccination card" 2 "Official vaccination card, verified by RE" 3 "Official vaccination card, not verified by RE" 4 "Non-offical vaccination card, verified by RE" 5 "Non-offical vaccination card, not verified by RE"

label val vax_card_cat vax_card
label var vax_card "Vaccination card types"
tab vax_card

*** Set up putexcel
putexcel set PMAET_`COHORT'_6M_MNHAnalysis_$date.xlsx, sheet(Figure3) modify
putexcel A1=("Figure 3. Types of Vaccination Record"), bold underline
putexcel A2=("Percent distribution of children approximately six months old with no vaccination card, official vaccination card (seen and not seen) and non-official vaccination card (seen and not seen)") B3=("Percent")

local row = 4

	tabulate vax_card, matcell(freq) matrow(names)
	local rows = rowsof(names)
	local RowValueLabel : value label vax_card
	
	svy: tab vax_card		
	tabulate vax_card [aw=SMFUweight], matcell(a)
	
	putexcel B`row'=matrix(e(Prop)*100), left nformat(0.0)
	
	forvalues i = 1/`rows' {

			local val = names[`i',1]
			local val_lab : label `RowValueLabel' `val'
				
			putexcel A`row'=("`val_lab'") 
			local row = `row' + 1
		}

count 
local n=r(N)
putexcel A9=("Number of Children"), left bold
putexcel B`row'=(`n'), nformat(number_sep) left 


*	Generate binary variable for vaccination (-88 coded as 1 for card)
gen bcg=0
replace bcg=1 if SMbaby_card_bcg==1 | SMbaby_card_bcg==-88 | SMbaby_nocard_bcg_yn==1
gen vit_a=0
replace vit_a=1 if SMbaby_card_vit_a==1 | SMbaby_card_vit_a==-88 | SMbaby_nocard_vit_a_yn==1

foreach var in polio pentavalent pcv rota {
		capture drop `var'
		gen `var'1=0
		replace `var'1=1 if (SMbaby_card_`var'1==1 | SMbaby_card_`var'1==-88) | (SMbaby_nocard_`var'_yn==1 & SMbaby_nocard_`var'_ct>=1)
		label values `var' yes_no_list
	}

***	Polio
*** NOTE: Did not restrict on timing of administration (within 2 weeks)
*** The DHS measures "children 12-23 months vaccinated at any time before the survey"
gen polio2=0
replace polio2=1 if (SMbaby_card_polio2==1 | SMbaby_card_polio2==-88) | (SMbaby_nocard_polio_yn==1 & SMbaby_nocard_polio_ct>=2)
label values polio2 yes_no_list
label variable polio2 "Child received Polio 2 vaccine"

gen polio3=0
replace polio3=1 if (SMbaby_card_polio3==1 | SMbaby_card_polio3==-88) | (SMbaby_nocard_polio_yn==1 & SMbaby_nocard_polio_ct>=3)
label values polio3 yes_no_list
label variable polio3 "Child received Polio 3 vaccine"

***	Pentavalent
gen pentavalent2=0
replace pentavalent2=1 if (SMbaby_card_pentavalent2==1 | SMbaby_card_pentavalent2==-88) | (SMbaby_nocard_pentavalent_yn==1 & SMbaby_nocard_pentavalent_ct>=2)
label values pentavalent2 yes_no_list
label variable pentavalent2 "Child received Pentavalent 2 vaccine"

gen pentavalent3=0
replace pentavalent3=1 if (SMbaby_card_pentavalent3==1 | SMbaby_card_pentavalent3==-88) | (SMbaby_nocard_pentavalent_yn==1 & SMbaby_nocard_pentavalent_ct>=3)
label values pentavalent3 yes_no_list
label variable pentavalent3 "Child received Pentavalent 3 vaccine"

***	PCV
gen pcv2=0
replace pcv2=1 if (SMbaby_card_pcv2==1 | SMbaby_card_pcv2==-88) | (SMbaby_nocard_pcv_yn==1 & SMbaby_nocard_pcv_ct>=2)
label values pcv2 yes_no_list
label variable pcv2 "Child received PCV 2 vaccine"

gen pcv3=0
replace pcv3=1 if (SMbaby_card_pcv3==1 | SMbaby_card_pcv3==-88) | (SMbaby_nocard_pcv_yn==1 & SMbaby_nocard_pcv_ct>=3)
label values pcv3 yes_no_list
label variable pcv3 "Child received PCV 3 vaccine"

***	Rota
gen rota2=0
replace rota2=1 if (SMbaby_card_rota2==1 | SMbaby_card_rota2==-88) |(SMbaby_nocard_rota_yn==1 & SMbaby_nocard_rota_ct>=2)
label values rota2 yes_no_list
label variable rota2 "Child received Rota 2 vaccine"

*** All basic vaccines (BCG, 3 Polio, 3 Pentavalent, and 1 measles)
*	Note: Removing measles from the definition as it is adminitered later (after 6 months)
gen all_basic=0
replace all_basic=1 if bcg==1 & polio3==1 & pentavalent3==1
label values all_basic yes_no_list
label var all_basic "Received all basic child vaccinations"
tab all_basic, m

*** No vaccine 
*	Two children were reported not to have any vaccination but had vaccination cards
*	Replace value to 1
replace SMbaby_vax_yn=1 if SMmetainstanceID=="FTBFLT8G3YRPH15YWG9OYFARL" | SMmetainstanceID=="YX6MNEM5M2U3X12OMZHB8N2Y8"
gen no_vax=SMbaby_vax_yn==0
label val no_vax yes_no_list
label var no_vax "Received no vaccination"
tab no_vax


*** Set up putexcel
putexcel set "PMAET_`COHORT'_6M_MNHAnalysis_$date.xlsx", sheet("Table5") modify
putexcel A1=("Table 5. Child Vaccination"), bold underline
putexcel A2=("Percentage of children approximately six months old who received BCG, Polio1-3, PCV1-3, Pentavalent1-3, Rota1-2, IPV, Measles vaccinations, and Vitamin A supplement, by mother's background characteristics, PMA Ethiopia 2019-2021 Cohort")
putexcel B3=("BCG") C3=("Polio") F3=("Pentavalent") I3=("PCV") L3=("Rota") N3=("All basic") O3=("None") P3=("Vitamin A") Q3=("Number of children (weighted)"), bold hcenter
putexcel C4=(1) D4=(2) E4=(3) F4=(1) G4=(2) H4=(3) I4=(1) J4=(2) K4=(3) L4=(1) M4=(2), hcenter nformat(0) border(bottom)
putexcel (C3:E3) (F3:H3) (I3:K3) (L3:M3), merge hcenter vcenter
putexcel A5=("Overall") A6=("Mother's Age") A14=("Mother's Education") A20=("Mother's Parity") A26=("Mother's Region") A34=("Mother's Residence") A38=("Mother's Wealth") A45=("Age in Months"), bold

*	Overall vaccination rate 
local row = 5

sum bcg [aw=SMFUweight]
local mean1: disp %3.1f r(mean)*100
sum polio1 [aw=SMFUweight]
local mean2: disp %3.1f r(mean)*100
sum polio2 [aw=SMFUweight]
local mean3: disp %3.1f r(mean)*100
sum polio3 [aw=SMFUweight]
local mean4: disp %3.1f r(mean)*100
sum pentavalent1 [aw=SMFUweight]
local mean5: disp %3.1f r(mean)*100
sum pentavalent2 [aw=SMFUweight]
local mean6: disp %3.1f r(mean)*100
sum pentavalent3 [aw=SMFUweight]
local mean7: disp %3.1f r(mean)*100
sum pcv1 [aw=SMFUweight]
local mean8: disp %3.1f r(mean)*100
sum pcv2 [aw=SMFUweight]
local mean9: disp %3.1f r(mean)*100
sum pcv3 [aw=SMFUweight]
local mean10: disp %3.1f r(mean)*100
sum rota1 [aw=SMFUweight]
local mean11: disp %3.1f r(mean)*100
sum rota2 [aw=SMFUweight]
local mean12: disp %3.1f r(mean)*100
sum all_basic [aw=SMFUweight]
local mean13: disp %3.1f r(mean)*100
sum no_vax [aw=SMFUweight]
local mean14: disp %3.1f r(mean)*100
sum vit_a [aw=SMFUweight]
local mean15: disp %3.1f r(mean)*100

count
if r(N)!=0 local n_1= r(N)
putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6') H`row'=(`mean7') I`row'=(`mean8') J`row'=(`mean9') K`row'=(`mean10') L`row'=(`mean11') M`row'=(`mean12') N`row'=(`mean13') O`row'=(`mean14') P`row'=(`mean15'), left nformat(0.0)	
putexcel Q`row'=(`n_1'), left nformat(number_sep)

*	Vaccination rate by background characteristics
local row=7
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile child_age_cat {

	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SMFUweight], matcell(a)
	putexcel Q`row'=matrix(a), left nformat(number_sep)

	forvalues i = 1/`RowCount' {
		sum bcg if `RowVar'==`i' [aw=SMFUweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum polio1 [aw=SMFUweight] if `RowVar'==`i'
			local mean2: disp %3.1f r(mean)*100
			
			sum polio2 [aw=SMFUweight] if `RowVar'==`i'
			local mean3: disp %3.1f r(mean)*100
			
			sum polio3 [aw=SMFUweight] if `RowVar'==`i'
			local mean4: disp %3.1f r(mean)*100
			
			sum pentavalent1 [aw=SMFUweight] if `RowVar'==`i'
			local mean5: disp %3.1f r(mean)*100
			
			sum pentavalent2 [aw=SMFUweight] if `RowVar'==`i'
			local mean6: disp %3.1f r(mean)*100
			
			sum pentavalent3 [aw=SMFUweight] if `RowVar'==`i'
			local mean7: disp %3.1f r(mean)*100
			
			sum pcv1 [aw=SMFUweight] if `RowVar'==`i'
			local mean8: disp %3.1f r(mean)*100
			
			sum pcv2 [aw=SMFUweight] if `RowVar'==`i'
			local mean9: disp %3.1f r(mean)*100
			
			sum pcv3 [aw=SMFUweight] if `RowVar'==`i'
			local mean10: disp %3.1f r(mean)*100
			
			sum rota1 [aw=SMFUweight] if `RowVar'==`i'
			local mean11: disp %3.1f r(mean)*100
			
			sum rota2 [aw=SMFUweight] if `RowVar'==`i'
			local mean12: disp %3.1f r(mean)*100
			
			sum all_basic [aw=SMFUweight] if `RowVar'==`i'
			local mean13: disp %3.1f r(mean)*100
			
			sum no_vax [aw=SMFUweight] if `RowVar'==`i'
			local mean14: disp %3.1f r(mean)*100
			
			sum vit_a [aw=SMFUweight] if `RowVar'==`i'
			local mean15: disp %3.1f r(mean)*100
			
			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6') H`row'=(`mean7') I`row'=(`mean8') J`row'=(`mean9') K`row'=(`mean10') L`row'=(`mean11') M`row'=(`mean12') N`row'=(`mean13') O`row'=(`mean14') P`row'=(`mean15'), left nformat(0.0)	
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*******************************************************************************
* CHILD HEALTH: ILLNESS AND TREATMENT 
*******************************************************************************

*	Recode DNK and missing to no and generate any illness binary variable
gen any_illness=0
foreach var in vomit unconsc swelling sorethrt lesion poorfeed other nostool lethargy fever fastbrth eyeinfect difbrth diarrhea cough convuls {
		recode SMbaby_ill_`var'_2wk (-88 .=0)
		replace any_illness=1 if SMbaby_ill_`var'_2wk==1
	}
label val any_illness yes_no_list
label var any_illness "Suffered any illness in the past two weeks"

*	Combine fast and difficulty breathing
gen fast_dif=0
replace fast_dif=1 if SMbaby_ill_fastbrth_2wk==1 | SMbaby_ill_difbrth_2wk==1
label values fast_dif yes_no_list
label variable fast_dif "Suffered fast of difficulty breathing in the past two weeks"
							
*** Set up putexcel
putexcel set "PMAET_`COHORT'_6M_MNHAnalysis_$date.xlsx", sheet("Table6") modify
putexcel A1=("Table 6. Child Illness"), bold underline
putexcel A2=("Percentage of children approximately six months old who suffered each of the indicated illnesses in the past two weeks, by mother's background characteristics, PMA Ethiopia 2019-2021 Cohort")
putexcel B3=("Cough") C3=("Fever") D3=("Diarrhea") E3=("Skin rash") F3=("Eye infection") G3=("Vomiting") H3=("Poor feeding") I3=("Fast or difficulty breathing") J3=("Any illness") K3=("Number of children (weighted)") 
putexcel A4=("Overall") A5=("Mother's Age") A13=("Mother's Education") A19=("Mother's Parity") A25=("Mother's Region") A33=("Mother's Residence") A37=("Mother's Wealth") A44=("Age in Months"), bold

*	Overall child illness
local row = 4

sum SMbaby_ill_cough_2wk [aw=SMFUweight]
local mean1: disp %3.1f r(mean)*100
sum SMbaby_ill_fever_2wk [aw=SMFUweight]
local mean2: disp %3.1f r(mean)*100
sum SMbaby_ill_diarrhea_2wk [aw=SMFUweight]
local mean3: disp %3.1f r(mean)*100
sum SMbaby_ill_lesion_2wk [aw=SMFUweight]
local mean4: disp %3.1f r(mean)*100
sum SMbaby_ill_eyeinfect_2wk [aw=SMFUweight]
local mean5: disp %3.1f r(mean)*100
sum SMbaby_ill_vomit_2wk [aw=SMFUweight]
local mean6: disp %3.1f r(mean)*100
sum SMbaby_ill_poorfeed_2wk [aw=SMFUweight]
local mean7: disp %3.1f r(mean)*100
sum fast_dif [aw=SMFUweight]
local mean8: disp %3.1f r(mean)*100
sum any_illness [aw=SMFUweight]
local mean9: disp %3.1f r(mean)*100

count
if r(N)!=0 local n_1= r(N)
putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6') H`row'=(`mean7') I`row'=(`mean8') J`row'=(`mean9'), left nformat(0.0) bold
putexcel K`row'=(`n_1'), left nformat(number_sep) bold

*	Child illness by background characteristics
local row=6
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile child_age_cat {

	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SMFUweight], matcell(a)
	putexcel K`row'=matrix(a), left nformat(number_sep)

	forvalues i = 1/`RowCount' {
		sum SMbaby_ill_cough_2wk if `RowVar'==`i' [aw=SMFUweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100

			sum SMbaby_ill_fever_2wk [aw=SMFUweight] if `RowVar'==`i'
			local mean2: disp %3.1f r(mean)*100
			sum SMbaby_ill_diarrhea_2wk [aw=SMFUweight] if `RowVar'==`i'
			local mean3: disp %3.1f r(mean)*100
			sum SMbaby_ill_lesion_2wk [aw=SMFUweight] if `RowVar'==`i'
			local mean4: disp %3.1f r(mean)*100
			sum SMbaby_ill_eyeinfect_2wk [aw=SMFUweight] if `RowVar'==`i'
			local mean5: disp %3.1f r(mean)*100
			sum SMbaby_ill_vomit_2wk [aw=SMFUweight] if `RowVar'==`i'
			local mean6: disp %3.1f r(mean)*100
			sum SMbaby_ill_poorfeed_2wk [aw=SMFUweight] if `RowVar'==`i'
			local mean7: disp %3.1f r(mean)*100
			sum fast_dif [aw=SMFUweight] if `RowVar'==`i'
			local mean8: disp %3.1f r(mean)*100
			sum any_illness [aw=SMFUweight] if `RowVar'==`i'
			local mean9: disp %3.1f r(mean)*100
			
			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6') H`row'=(`mean7') I`row'=(`mean8') J`row'=(`mean9'), left nformat(0.0)	
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}
	

***	Place of treatment (public, private, home or other, and no treatment)
foreach var in fever diarrhea cough {
		*	Sought treatment at home 
		gen `var'_trt_homeother=0 if SMbaby_ill_`var'_2wk==1
		replace `var'_trt_homeother=1 if (SMbaby_trt_`var'_homevisit==1 | SMbaby_trt_`var'_otherhome==1 | SMbaby_trt_`var'_tradheal==1 | SMbaby_trt_`var'_store==1 | SMbaby_trt_`var'_religion==1 | SMbaby_trt_`var'_pharm==1 | SMbaby_trt_`var'_other==1) & SMbaby_ill_`var'_2wk==1
		label values `var'_trt_homeother yes_no_list
		label variable `var'_trt_homeother "Sought treatment for `var' at home or others (e.g., traditional, drug stores)"
		
		*	Sought treatment at public facility
		gen `var'_trt_public=0 if SMbaby_ill_`var'_2wk==1
		replace `var'_trt_public=1 if (SMbaby_trt_`var'_otherpub==1 | SMbaby_trt_`var'_govhp==1 | SMbaby_trt_`var'_govhc==1 | SMbaby_trt_`var'_govhosp==1) & SMbaby_ill_`var'_2wk==1
		label values `var'_trt_public yes_no_list
		label variable `var'_trt_public "Sought treatment for `var' at public health facility"
		
		*	Sought treatment private facility
		gen `var'_trt_pri=0 if SMbaby_ill_`var'_2wk==1
		replace `var'_trt_pri=1 if (SMbaby_trt_`var'_privhosp==1 | SMbaby_trt_`var'_otherpriv==1 | SMbaby_trt_`var'_ngohf==1) & SMbaby_ill_`var'_2wk==1
		label values `var'_trt_pri yes_no_list
		label variable `var'_trt_pri "Sought treatment for `var' at private health facility"
	}

*	No treatment sought
foreach var in fever diarrhea cough {
	gen `var'_trt_none=0 if SMbaby_ill_`var'_2wk==1
	replace `var'_trt_none=1 if SMbaby_trt_`var'_yn==0 
	label val `var'_trt_none yes_no_list
	label var `var'_trt_none "Sought no treatment for `var'"
}

tab1 cough_trt_none fever_trt_none diarrhea_trt_none

*** Set up putexcel
putexcel set "PMAET_`COHORT'_6M_MNHAnalysis_$date.xlsx", sheet("Table7") modify
putexcel A1=("Table 7. Place of Treatment for Child Illness"), bold underline
putexcel A2=("Among children approximately six months old who suffered from a cough, fever, or diarrhea in the past two weeks, the percentage who received treatment for the illness at a public facility, private facility, home/other, and no treatment, PMA Ethiopia 2019-2021 Cohort")
putexcel B3=("Cough") C3=("Fever") D3=("Diarrhea"), bold hcenter border(bottom)
putexcel A4=("Public facility") A5=("Private facility") A6=("Home or other") A7=("No treatment") A8=("Number of children (weighted)")

*	Overall place of treatment
local row = 4

foreach var in public pri homeother none {
		sum cough_trt_`var' [aw=SMFUweight]
		local mean1: disp %3.1f r(mean)*100
		putexcel B`row'=(`mean1'), left nformat(0.0)
		
		local row = `row' + 1
	}
local row = 4

foreach var in public pri homeother none {
		sum fever_trt_`var' [aw=SMFUweight]
		local mean1: disp %3.1f r(mean)*100
		putexcel C`row'=(`mean1'), left nformat(0.0)
		
		local row = `row' + 1
	}
local row = 4

foreach var in public pri homeother none {
		sum diarrhea_trt_`var' [aw=SMFUweight]
		local mean1: disp %3.1f r(mean)*100
		putexcel D`row'=(`mean1'), left nformat(0.0)
		
		local row = `row' + 1
	}
	
local row = 8
count if SMbaby_ill_cough_2wk==1
if r(N)!=0 local n_1= r(N)
count if SMbaby_ill_fever_2wk==1
if r(N)!=0 local n_2= r(N)
count if SMbaby_ill_diarrhea_2wk==1
if r(N)!=0 local n_3= r(N)
putexcel B`row'=(`n_1') C`row'=(`n_2') D`row'=(`n_3'), left nformat(number_sep) bold


*** Diarrhea specific (blood in diarrhea and treatment for diarrhea)
gen diarrhea_trt_zinc=0 if SMbaby_ill_diarrhea_2wk==1
replace diarrhea_trt_zinc=1 if SMbaby_rcv_diar_zinctabs==1
label val diarrhea_trt_zinc yesno 
label var diarrhea_trt_zinc "Received Zinc tablet for diarrhea"

gen diarrhea_trt_ors=0 if SMbaby_ill_diarrhea_2wk==1
replace diarrhea_trt_ors=1 if SMbaby_rcv_diar_orsathome==1 | SMbaby_rcv_diar_orsinfacility==1
label val diarrhea_trt_ors yesno 
label var diarrhea_trt_ors "Received ORS at facility for to take home for diarrhea"


*** Set up putexcel
putexcel set "PMAET_`COHORT'_6M_MNHAnalysis_$date.xlsx", sheet("Figure7") modify
putexcel A1=("Figure 7. Presence of Blood and Treatment for Diarrhea"), bold underline
putexcel A2=("Among children who suffered diarrhea in the past two weeks, the proportion with bloody diarrhea and proportions who received zinc tablet and oral rehydration salt (ORS) as treatment, PMA Ethiopia 2019-2021 Cohort")
putexcel B3=("Percent") A4=("Blood in diarrhea") A5=("Zinc tablets") A6=("ORS") A7=("Number of children")

*	Presence of blood and treatment overall
local row = 4

foreach var in SMbaby_diarrhea_blood diarrhea_trt_zinc diarrhea_trt_ors {
		sum `var' [aw=SMFUweight]
		local mean1: disp %3.1f r(mean)*100
		putexcel B`row'=(`mean1'), left nformat(0.0)
		
		local row = `row' + 1
	}
	
count if SMbaby_ill_diarrhea_2wk==1
if r(N)!=0 local n_1= r(N)
putexcel B`row'=(`n_1'), left nformat(number_sep) bold

restore

*******************************************************************************
**********************  SECTION 7: MATERNAL HEALTH	**************************
*******************************************************************************

*******************************************************************************
* MATERNAL HEALTH: PNC
*******************************************************************************

*** Any PNC
*	For women who completed the 6w interview only 
*	Those those did not complete the 6w interview were asked about 
*	health check within 2 months of delivery, not any time after delivery 
gen anypnc=0 if SMsurvey_6w_yn==1
replace anypnc=1 if SMmother_baby_check_yn==1 & SMsurvey_6w_yn==1
label values anypnc yes_no_list
label variable anypnc "Received any PNC"

*** Content of PNC (counseling and measurement)
foreach var in SMhc_no_sugary_drinks SMhc_liquids_before_6m SMhc_foods_after_6m SMhc_feeding_frequency SMhc_dietary_diversity SMhc_breastfeeding SMhc_animal_source_foods SMmeasure_weight SMmeasure_muac SMmeasure_height {
		recode `var' (-88 -99=0)
	}
	
*** Any form of PNC counseling
gen anypnc_coun=0 if anypnc==1
replace anypnc_coun=1 if (SMhc_no_sugary_drinks== 1| SMhc_liquids_before_6m== 1| SMhc_foods_after_6m== 1 | SMhc_feeding_frequency== 1| SMhc_dietary_diversity== 1| SMhc_breastfeeding== 1| SMhc_animal_source_foods==1) & anypnc==1
label values anypnc_coun yes_no_list
label variable anypnc_coun "Received any PNC counseling"

*** Set up putexcel
putexcel set "PMAET_`COHORT'_6M_MNHAnalysis_$date.xlsx", sheet("Table8") modify
putexcel A1=("Table 8. Postnatal Care Coverage and Counseling"), bold underline
putexcel A2=("Percentage of women approximately six months postpartum who received any postnatal care (PNC), excluding immediate postnatal care, and among those who received any PNC, the percentage receiving each form of PNC counseling, by background characteristics, PMA Ethiopia 2019-2021 Cohort")
putexcel B3=("Any health checks") C3=("Number of women (weighted)") D3=("Breastfeeding") E3=("No other liquids before 6 months") F3=("Other food or liquids after 6 months") G3=("Food varieties") H3=("Animal source food") I3=("Feeding frequency") J3=("No SSB") K3=("Any counseling") L3=("Number of women with PNC (weighted)") 
putexcel A4=("Overall") A5=("Age") A13=("Education") A19=("Parity") A25=("Region") A33=("Residence") A37=("Wealth") A44=("Months Postpartum") , bold

*	PNC coverage and PNC counseling overall
local row = 4

sum anypnc [aw=SMFUweight]
local mean1: disp %3.1f r(mean)*100
sum SMhc_breastfeeding [aw=SMFUweight] if anypnc==1
local mean2: disp %3.1f r(mean)*100
sum SMhc_liquids_before_6m [aw=SMFUweight] if anypnc==1
local mean3: disp %3.1f r(mean)*100
sum SMhc_foods_after_6m [aw=SMFUweight] if anypnc==1
local mean4: disp %3.1f r(mean)*100
sum SMhc_dietary_diversity [aw=SMFUweight] if anypnc==1
local mean5: disp %3.1f r(mean)*100
sum SMhc_animal_source_foods [aw=SMFUweight] if anypnc==1
local mean6: disp %3.1f r(mean)*100
sum SMhc_feeding_frequency [aw=SMFUweight] if anypnc==1
local mean7: disp %3.1f r(mean)*100
sum SMhc_no_sugary_drinks [aw=SMFUweight] if anypnc==1
local mean8: disp %3.1f r(mean)*100
sum anypnc_coun [aw=SMFUweight] if anypnc==1
local mean9: disp %3.1f r(mean)*100

count if anypnc!=.
if r(N)!=0 local n_1= r(N)
count if anypnc==1
if r(N)!=0 local n_2= r(N)

putexcel B`row'=(`mean1') D`row'=(`mean2') E`row'=(`mean3') F`row'=(`mean4') G`row'=(`mean5') H`row'=(`mean6') I`row'=(`mean7') J`row'=(`mean8') K`row'=(`mean9'), left nformat(0.0) bold
putexcel C`row'=(`n_1') L`row'=(`n_2'), left nformat(number_sep) bold

*	PNC coverage and counseling by background characteristics
local row=6
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile child_age_cat {

	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SMFUweight] if anypnc!=. , matcell(a)
	putexcel C`row'=matrix(a), left nformat(number_sep)
	tabulate `RowVar' [aw=SMFUweight] if anypnc==1 , matcell(a)
	putexcel L`row'=matrix(a), left nformat(number_sep)
	
	forvalues i = 1/`RowCount' {
		sum anypnc if `RowVar'==`i' [aw=SMFUweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100

			sum SMhc_breastfeeding [aw=SMFUweight] if anypnc==1 & `RowVar'==`i' 
			local mean2: disp %3.1f r(mean)*100
			sum SMhc_liquids_before_6m [aw=SMFUweight] if anypnc==1 & `RowVar'==`i' 
			local mean3: disp %3.1f r(mean)*100
			sum SMhc_foods_after_6m [aw=SMFUweight] if anypnc==1 & `RowVar'==`i' 
			local mean4: disp %3.1f r(mean)*100
			sum SMhc_dietary_diversity [aw=SMFUweight] if anypnc==1 & `RowVar'==`i' 
			local mean5: disp %3.1f r(mean)*100
			sum SMhc_animal_source_foods [aw=SMFUweight] if anypnc==1 & `RowVar'==`i' 
			local mean6: disp %3.1f r(mean)*100
			sum SMhc_feeding_frequency [aw=SMFUweight] if anypnc==1 & `RowVar'==`i' 
			local mean7: disp %3.1f r(mean)*100
			sum SMhc_no_sugary_drinks [aw=SMFUweight] if anypnc==1 & `RowVar'==`i' 
			local mean8: disp %3.1f r(mean)*100
			sum anypnc_coun [aw=SMFUweight] if anypnc==1 & `RowVar'==`i' 
			local mean9: disp %3.1f r(mean)*100
			
			count if `RowVar'==`i' & anypnc==1 
			if r(N)!=0 local n_1= r(N)

			putexcel A`row'=("`CellContents'")  B`row'=(`mean1') D`row'=(`mean2') E`row'=(`mean3') F`row'=(`mean4') G`row'=(`mean5') H`row'=(`mean6') I`row'=(`mean7') J`row'=(`mean8') K`row'=(`mean9'), left nformat(0.0)	
			
			if `n_1'>=25 & `n_1'<=49 {
					putexcel D`row'="(`mean2')" E`row'="(`mean3')" F`row'="(`mean4')" G`row'="(`mean5')" H`row'="(`mean6')" I`row'="(`mean7')" J`row'="(`mean8')" K`row'="(`mean9')", left nformat(0.0)	
				}
			
			if `n_1'<25 {
					putexcel D`row'="*" E`row'="*" F`row'="*" G`row'="*" H`row'="*" I`row'="*" J`row'="*" K`row'="*", left
				}
				
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}
	
*** Set up putexcel
putexcel set "PMAET_`COHORT'_6M_MNHAnalysis_$date.xlsx", sheet("Table9") modify
putexcel A1=("Table 9. Growth Monitoring and Screening for Malnutrition at PNC"), bold underline
putexcel A2=("Among women approximately six months postpartum who received any postnatal care (PNC), the percentage of those whose children's weight, length of height, and mid-upper arm circumference (MUAC) were measured, by background characteristics, PMA Ethiopia 2019-2021 Cohort")
putexcel B3=("Weight") C3=("Height") D3=("MUAC") E3=("Number of women with PNC (weighted)") 
putexcel A4=("Overall") A5=("Age") A13=("Education") A19=("Parity") A25=("Region") A33=("Residence") A37=("Wealth") A44=("Months Postpartum"), bold

*	Growth monitoring and screening for malnutrition overall
local row = 4

sum SMmeasure_weight [aw=SMFUweight] if anypnc==1
local mean1: disp %3.1f r(mean)*100
sum SMmeasure_height [aw=SMFUweight] if anypnc==1
local mean2: disp %3.1f r(mean)*100
sum SMmeasure_muac [aw=SMFUweight] if anypnc==1
local mean3: disp %3.1f r(mean)*100

count if anypnc==1
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3'), left nformat(0.0) bold
putexcel E`row'=(`n_1'), left nformat(number_sep) bold

*	Growth monitoring and screening for malnutrition by background characteristics
local row=6
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile child_age_cat {

	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SMFUweight] if anypnc==1, matcell(a)
	putexcel E`row'=matrix(a), left nformat(number_sep)
	
	forvalues i = 1/`RowCount' {
		sum SMmeasure_weight if `RowVar'==`i' & anypnc==1 [aw=SMFUweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100

			sum SMmeasure_height [aw=SMFUweight] if anypnc==1 & `RowVar'==`i' 
			local mean2: disp %3.1f r(mean)*100
			sum SMmeasure_muac [aw=SMFUweight] if anypnc==1 & `RowVar'==`i' 
			local mean3: disp %3.1f r(mean)*100
			
			count if `RowVar'==`i' & anypnc==1 
			if r(N)!=0 local n_1= r(N)

			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3'), left nformat(0.0)	
			
			if `n_1'>=25 & `n_1'<=49 {
					putexcel B`row'="(`mean1')" C`row'="(`mean2')" D`row'="(`mean3')", left nformat(0.0)	
				}
			
			if `n_1'<25 {
					putexcel B`row'="*" C`row'="*" D`row'="*", left
				}
				
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*******************************************************************************
* MATERNAL HEALTH: BREASTFEEDING, HEALTH CHECKS, AND FP INFO 
*******************************************************************************
	
*** Ever breastfed and difficulty breastfeeding
recode SMbf_difficulty_yn (-88 -99=0)

*** Set up putexcel
putexcel set "PMAET_`COHORT'_6M_MNHAnalysis_$date.xlsx", sheet("Figure11") modify
putexcel A1=("Figure 11a-b. Breastfeeding and Difficulty Breastfeeding"), bold underline
putexcel A2=("Percentage of women approximately six months postpartum who ever breastfed, experienced any difficulties breatfeeding, and sought treatment for difficulties breastfeeding, PMA Ethiopia 2019-2021 Cohort")

putexcel B3=("Percent") C3=("Number of women") A4=("Ever breastfed") A5=("Difficulties breastfeeding") A6=("Sought help for difficulies breastfeeding")

*	Ever breastfed
sum SMever_bf [aw=SMFUweight]
local mean1: disp %3.1f r(mean)*100
if r(N)!=0 local n_1= r(N)

*	Difficulty breastfeeding
sum SMbf_difficulty_yn [aw=SMFUweight] if SMever_bf==1
local mean2: disp %3.1f r(mean)*100
if r(N)!=0 local n_2= r(N)

*	Sought help for difficulies breastfeeding
sum SMbf_difficulty_trt [aw=SMFUweight] if SMbf_difficulty_yn==1 & SMever_bf==1
local mean3: disp %3.1f r(mean)*100
local n_3=r(N)

putexcel B4=(`mean1') B5=(`mean2') B6=(`mean3'), left nformat(0.0) 
putexcel C4=(`n_1') C5=(`n_2') C6=(`n_3') , left nformat(number_sep) 


*** FP info at immunization and non-immunization health checks

*** Set up putexcel
putexcel set "PMAET_`COHORT'_6M_MNHAnalysis_$date.xlsx", sheet("Figure12") modify
putexcel A1=("Figure 12. Information about Family Planning at Health Checks"), bold underline
putexcel A2=("Percentage of women approximately six months postpartum who received information about family planning (FP) since they delivered their most recent baby at immunization and non-immunization health visits, PMA Ethiopia 2019-2021 Cohort")
putexcel B3=("Percent receiving FP information") C3=("Number of women with non-immunization health visit") D3=("Percent receiving FP information") E3=("Number of women with immunization health visit") 
putexcel A4=("Overall"), bold

*	FP info overall
local row = 4

sum SMfp_info_non_vaccine_visit [aw=SMFUweight] if SMnon_immunization_health_check==1
local mean1: disp %3.1f r(mean)*100
sum SMfp_info_vaccine_visit [aw=SMFUweight] 
local mean2: disp %3.1f r(mean)*100

count if SMnon_immunization_health_check==1
if r(N)!=0 local n_1= r(N)
count if SMfp_info_vaccine_visit!=.
if r(N)!=0 local n_2= r(N)

putexcel B`row'=(`mean1') D`row'=(`mean2'), left nformat(0.0) bold
putexcel C`row'=(`n_1') E`row'=(`n_2'), left nformat(number_sep) bold


*******************************************************************************
****************  SECTION 7: SEXUAL AND REPRODUCTIVE HEALTH	 ******************
*******************************************************************************

*******************************************************************************
* SRH: RETURN OF MENSES, SEXUAL ACTIVITIES AND CURRENT FP USE 
*******************************************************************************
	
*** Return of menses
tab SMcycle_returned, m

*** Resuming sexual activities 
*	Pregnant at 6 months = resumed sexual activities 
tab SMresumed_sex, m
replace SMresumed_sex=1 if SMpregnant==1 
replace SMresumed_sex=-99 if SMpregnant==-88
replace SMresumed_sex=0 if SMresumed_sex==-99

*** Returned menses and resumed sexual activities
gen menses_sex=0
replace menses_sex=1 if SMresumed_sex==1 & SMcycle_returned==1
label values menses_sex yes_no_list
label variable menses_sex "Menses returned and resumed sexual activities"
tab menses_sex, m

*** Set up putexcel
putexcel set "PMAET_`COHORT'_6M_MNHAnalysis_$date.xlsx", sheet("Table10") modify
putexcel A1=("Table 10. Return of Menses and Resuming Sexual Activities"), bold underline
putexcel A2=("Percentage of women approximately six months postpartum whose menses returned, resumed sexual activities since delivery by the date of interview, by background characteristics, PMA Ethiopia 2019-2021 Cohort")
putexcel B3=("Menses returned") C3=("Resumed sexual activities") D3=("Menses returned and resumed sexual activities") E3=("Number of women (weighted)")
putexcel A4=("Overall") A5=("Age") A13=("Education") A19=("Parity") A25=("Region") A33=("Residence") A37=("Wealth") A44=("Months Postpartum"), bold

*	Return of menses and resuming sexual activities overall
local row = 4

sum SMcycle_returned [aw=SMFUweight]
local mean1: disp %3.1f r(mean)*100
sum SMresumed_sex [aw=SMFUweight]
local mean2: disp %3.1f r(mean)*100
sum menses_sex [aw=SMFUweight]
local mean3: disp %3.1f r(mean)*100

count
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3'), left nformat(0.0) bold
putexcel E`row'=(`n_1'), left nformat(number_sep) bold

*	Return of menses and resuming sexual activities by background characteristics
local row=6
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile child_age_cat {

	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SMFUweight], matcell(a)
	putexcel E`row'=matrix(a), left nformat(number_sep)
	
	forvalues i = 1/`RowCount' {
		sum SMcycle_returned if `RowVar'==`i' [aw=SMFUweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100

			sum SMresumed_sex [aw=SMFUweight] if `RowVar'==`i' 
			local mean2: disp %3.1f r(mean)*100
			sum menses_sex [aw=SMFUweight] if `RowVar'==`i' 
			local mean3: disp %3.1f r(mean)*100
			
			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3'), left nformat(0.0)
				
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}


*** FP use
*	Generate binary variables for
*		- Current user
*		- Non-current user with future intention to use
*		- Non-current user with no future intention to use 
*		- Missing or unkonwn intention 

gen nonuser_intention=0 if SMpregnant!=1
replace nonuser_intention=1 if SMcurrent_user==0 & SMfuture_user_not_current==1 
label values nonuser_intention yes_no_list
label variable nonuser_intention "Not currently using FP but intent to use in the future"

gen nonuser_no_intention=0 if SMpregnant!=1
replace nonuser_no_intention=1 if SMcurrent_user==0 & SMfuture_user_not_current==0
label values nonuser_no_intention yes_no_list
label variable nonuser_no_intention "Not currently using FP and have no intent to use in the future"

gen intention_unknown=0 if SMpregnant!=1
replace intention_unknown=1 if SMcurrent_user==0 & (SMfuture_user_not_current==-88 | SMfuture_user_not_current==.)
label values intention_unknown yes_no_list
label variable intention_unknown "Not currently using FP and future intention unsure or missing"

tab1 nonuser_intention nonuser_no_intention intention_unknown

*** Set up putexcel
putexcel set "PMAET_`COHORT'_6M_MNHAnalysis_$date.xlsx", sheet("Table11") modify
putexcel A1=("Table 11. Family Planning Use and Future Intention"), bold underline
putexcel A2=("Among women who were approximately six months postpartum and not pregnant, the percent distribution of those who were currently using family planning, not currently using with future intention to use, not currently using with no future intention to use, and not currently using and not sure about future intention at the time of the survey, by background characteristics PMA Ethiopia 2019-2021 Cohort")
putexcel B3=("Current user") C3=("Non-current user with future intention to use") D3=("Non-current user with no future intention to use") E3=("Non-current user with unknown intention") F3=("Number of women (weighted)*")
putexcel A4=("Overall") A5=("Age") A13=("Education") A19=("Parity") A25=("Region") A33=("Residence") A37=("Wealth") A44=("Months Postpartum"), bold

*	FP user and intention overall
local row = 4

sum SMcurrent_user [aw=SMFUweight]
local mean1: disp %3.1f r(mean)*100
sum nonuser_intention [aw=SMFUweight]
local mean2: disp %3.1f r(mean)*100
sum nonuser_no_intention [aw=SMFUweight]
local mean3: disp %3.1f r(mean)*100
sum intention_unknown [aw=SMFUweight]
local mean4: disp %3.1f r(mean)*100

count if SMcurrent_user!=.
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4'), left nformat(0.0) bold
putexcel F`row'=(`n_1'), left nformat(number_sep) bold

*	FP use and intention by background characteristics
local row=6
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile child_age_cat {

	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SMFUweight] if SMcurrent_user!=., matcell(a)
	putexcel F`row'=matrix(a), left nformat(number_sep)
	
	forvalues i = 1/`RowCount' {
		sum SMcurrent_user if `RowVar'==`i' [aw=SMFUweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100

			sum nonuser_intention [aw=SMFUweight] if `RowVar'==`i' 
			local mean2: disp %3.1f r(mean)*100
			sum nonuser_no_intention [aw=SMFUweight] if `RowVar'==`i' 
			local mean3: disp %3.1f r(mean)*100
			sum intention_unknown [aw=SMFUweight] if `RowVar'==`i' 
			local mean4: disp %3.1f r(mean)*100	
			
			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') , left nformat(0.0)
				
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

count if SMpregnant==1
local preg_num=r(N)
putexcel A`row'=("*`preg_num' pregnant women excluded")


*** Current method 
*	No method 
gen no_method=0 
replace no_method=1 if SMcurrent_user==0 | SMpregnant==1
label values no_method yes_no_list
label variable no_method "Not using a FP method"

*	Short-acting method
gen short_acting=0
replace short_acting=1 if SMcurrent_user==1 & SMcurrent_methodnum>=5 & SMcurrent_methodnum<=16 
label values short_acting yes_no_list
label variable short_acting "Using a short-acting method"

*	Long-acting method
gen long_acting=0 
replace long_acting=1 if SMcurrent_user==1 & SMcurrent_methodnum>=1 & SMcurrent_methodnum<=4
label values long_acting yes_no_list
label variable long_acting "Using a long-acting method"

*	Traditional method
gen traditional=0 
replace traditional=1 if SMcurrent_user==1 & SMcurrent_methodnum>=30 & SMcurrent_methodnum<=39
label values traditional yes_no_list
label variable traditional "Using a traditional method"

tab1 no_method short_acting long_acting traditional

*** Set up putexcel
putexcel set "PMAET_`COHORT'_6M_MNHAnalysis_$date.xlsx", sheet("Table12") modify
putexcel A1=("Table 12. Current Family Planning Method Type (Most Effective)"), bold underline
putexcel A2=("Among women approximately six months postpartum, the percentage distribution of those using no method, short-acting, long-acting, and traditional method as the most effective method, by background characteristics, PMA Ethiopia 2019-2021 Cohort")
putexcel B3=("No method") C3=("Shorting-acting method") D3=("Long-acting method") E3=("Traditional method") F3=("Number of women (weighted)")
putexcel A4=("Overall") A5=("Age") A13=("Education") A19=("Parity") A25=("Region") A33=("Residence") A37=("Wealth") A44=("Months Postpartum"), bold

*	FP method type overall
local row = 4

sum no_method [aw=SMFUweight]
local mean1: disp %3.1f r(mean)*100
sum short_acting [aw=SMFUweight]
local mean2: disp %3.1f r(mean)*100
sum long_acting [aw=SMFUweight]
local mean3: disp %3.1f r(mean)*100
sum traditional [aw=SMFUweight]
local mean4: disp %3.1f r(mean)*100

count if no_method!=.
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4'), left nformat(0.0) bold
putexcel F`row'=(`n_1'), left nformat(number_sep) bold

*	FP method type by background characteristics
local row=6
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile child_age_cat {

	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SMFUweight], matcell(a)
	putexcel F`row'=matrix(a), left nformat(number_sep)
	
	forvalues i = 1/`RowCount' {
		sum no_method if `RowVar'==`i' [aw=SMFUweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100

			sum short_acting [aw=SMFUweight] if `RowVar'==`i' 
			local mean2: disp %3.1f r(mean)*100
			sum long_acting [aw=SMFUweight] if `RowVar'==`i' 
			local mean3: disp %3.1f r(mean)*100
			sum traditional [aw=SMFUweight] if `RowVar'==`i' 
			local mean4: disp %3.1f r(mean)*100	
			
			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') , left nformat(0.0)
				
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}


*	Specific method type (for pie chart)
putexcel I4=("Figure 15. Percent distribution of specific method type"), bold underline
putexcel J5=("Percent") 
local row = 6

tabulate SMcurrent_methodnum, matcell(freq) matrow(names)
local rows = rowsof(names)
local RowValueLabel : value label SMcurrent_methodnum

svy: tab SMcurrent_methodnum		
tabulate SMcurrent_methodnum [aw=SMFUweight], matcell(a)

putexcel J`row'=matrix(e(Prop)*100), left nformat(0.0)

forvalues i = 1/`rows' {

		local val = names[`i',1]
		local val_lab : label `RowValueLabel' `val'
			
		putexcel I`row'=("`val_lab'") 
		local row = `row' + 1
	}

count if SMcurrent_user==1 
local n_1=r(N)
putexcel I`row'=("Number of Current Users") J`row'=(`n_1'), left bold nformat(number_sep)


*******************************************************************************
*** SRH: DESIRED METHOD OBTAINED, REASONS FOR CHOOSING CURRENT METHOD 
***		 AND REASON FOR NOT USING 
*******************************************************************************

*** Desired mehtod obtained

*** Set up putexcel
putexcel set "PMAET_`COHORT'_6M_MNHAnalysis_$date.xlsx", sheet("Figure16") modify
putexcel A1=("Figure 16. Desired Family Planning Method Obtained"), bold underline
putexcel A2=("Among women approximately six months postpartum who were currently using any method of family planning except LAM and traditional methods at the time of the survey, the percentage who were using their desired method, by background characteristics, PMA Ethiopia 2019-2021 Cohort")
putexcel B3=("Percent") C3=("Number of women (weighted)")
putexcel A4=("Overall"), bold

*	Desired method obtained overall
local row = 4

sum SMfp_obtain_desired [aw=SMFUweight]
local mean1: disp %3.1f r(mean)*100
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1'), left nformat(0.0) bold
putexcel C`row'=(`n_1'), left nformat(number_sep) bold


*** Reason for choosing current method

*** Set up putexcel
putexcel set "PMAET_`COHORT'_6M_MNHAnalysis_$date.xlsx", sheet("Table13") modify
putexcel A1=("Table 13. Reasons for Choosing Current Method"), bold underline
putexcel A2=("Among women approximately six months postpartum who were currently using a family planning method other than traditional method at the time of the survey, the percentage distribution of reported reasons for choosing the method, by method type, PMA Ethiopia 2019-2021 Cohort")
putexcel B3=("Long-acting methods users") C3=("Shorting-acting methods users")
putexcel A4=("Long duration of protection") A5=("Less need for follow-up") A6=("Unavailability of other methods") A7=("Provider recommended") A8=("Fewer side effects than other methods") A9=("Can use without husband's knowledge") A10=("Other")
putexcel A11=("Number of women") , left bold

local row = 4

foreach var in SMwhy_current_fp_duration SMwhy_current_fp_nofollowup SMwhy_current_fp_othersunavail SMwhy_current_fp_recommendation SMwhy_current_fp_fewersidefx SMwhy_current_fp_ignoranthusband SMwhy_current_fp_other {
		
		local i=1
		sum `var' [aw=SMFUweight] if long_acting==1
		local mean`i': disp %3.1f r(mean)*100
		putexcel B`row'=(`mean`i''), left nformat(0.0)
		
		sum `var' [aw=SMFUweight] if short_acting==1
		local mean`i': disp %3.1f r(mean)*100
		putexcel C`row'=(`mean`i''), left nformat(0.0)
		
		local row=`row' + 1
		local i=`i'+ 1
	}

count if SMwhy_current_fp_duration!=. & long_acting==1
local n_1=r(N)
putexcel B`row'=(`n_1'), left bold nformat(number_sep)

count if SMwhy_current_fp_duration!=. & short_acting==1
local n_1=r(N)
putexcel C`row'=(`n_1'), left bold nformat(number_sep)
	
	
*** Reason for not using 
*	Group reasons 
gen partner_religion=0 if SMcurrent_user==0 & SMfp_since_birth==0
replace partner_religion=1 if SMwhy_not_usingrespopp==1 | SMwhy_not_usingrelig==1
label val partner_religion yes_no_list
label var partner_religion "Not using due to partner's disapproval or religious  prohibition'"

gen no_sex=0 if SMcurrent_user==0 & SMfp_since_birth==0
replace no_sex=1 if SMwhy_not_usinginfrequentsex==1 | SMwhy_not_usingabstinent==1 | SMwhy_not_usingnotresumedsex==1 
label val no_sex yes_no_list
label var no_sex "Not using due to no, infrequent sex or prefers abstinence"

*** Set up putexcel
putexcel set "PMAET_`COHORT'_6M_MNHAnalysis_$date.xlsx", sheet("Table14") modify
putexcel A1=("Table 14. Reasons for Not Using Family Planning"), bold underline
putexcel A2=("Among women approximately six months postpartum who have not used family planning since delivery, the percentage distribution of reported reasons for not using a method, PMA Ethiopia 2019-2021 Cohort")
putexcel B3=("Percent")
putexcel A4=("Has not resumed menstruation") A5=("Currently breastfeeding") A6=("Worried about side effects") A7=("Other") A8=("Religious prohibition or partner disapproves") A9=("No/infrequent sex or prefers abstinence ") A10=("Wants to become pregnant") A11=("FP might make getting pregnant again difficult") A12=("Do not know enough about family planning") A13=("Desired method not available")
putexcel A14=("Number of non-current users") , left bold

local row = 4

foreach var in SMwhy_not_usingmenses SMwhy_not_usingbreastfd SMwhy_not_usingfearside SMwhy_not_usingother partner_religion no_sex SMwhy_not_usingwantpreg SMwhy_not_usingfpdifficult SMwhy_not_usingfpconfusion SMwhy_not_usingprfnotavail {
		
		local i=1
		sum `var' [aw=SMFUweight]
		local mean`i': disp %3.1f r(mean)*100
		
		putexcel B`row'=(`mean`i''), left nformat(0.0)
		
		local row=`row' + 1
		local i=`i'+ 1
	}

count if SMwhy_not_usingfearside!=.
local n_1=r(N)
putexcel B`row'=(`n_1'), left bold nformat(number_sep)

local row=`row'+1
putexcel A`row'=("*`preg_num' pregnant women excluded")

*******************************************************************************
* SRH: IMPLANT-SPECIFIC 
*******************************************************************************

/*
- told about duration of implant protection
- told how much implant removal would cost
- told how and where to go for implant removal 
- wanted implant removed 
- tried to remove implant 
*/

*** Set up putexcel
putexcel set "PMAET_`COHORT'_6M_MNHAnalysis_$date.xlsx", sheet("Figure19") modify
putexcel A1=("Figure 19. Implant Counseling and Intention to Remove Implant"), bold underline
putexcel A2=("Among women approximately six months postpartum who were currently using a implant, the proportions who received implant-specific counseling and wanted and/or attempted to remove their implant, PMA Ethiopia 2019-2021 Cohort")
putexcel B3=("Percent") 
putexcel A4=("Told about duration of implant protection") A5=("Told about cost of implant removal") A6=("Told about where to go for implant removal") A7=("Wanted implant removed") A8=("Tried to remove implant")
putexcel A9=("Number of current implant users") , left bold

local row = 4

foreach var in SMimplant_protect SMtold_removal_cost SMtold_removal SMimplant_want_removed SMimplant_removed_attempt {
		
		local i=1
		sum `var' [aw=SMFUweight] if SMimplant==1
		local mean`i': disp %3.1f r(mean)*100
		putexcel B`row'=(`mean`i''), left nformat(0.0)

		local row=`row' + 1
		local i=`i'+ 1
	}

count if SMimplant==1
local n_1=r(N)
putexcel B`row'=(`n_1'), left bold nformat(number_sep)

*******************************************************************************
* SRH: FP SIDE EFFECTS
*******************************************************************************

*** Side effect 
*** Told about side effect (Current user of MS, FS, implant, IUD, pills, injectables, MC, EC, FC, and standard days )
tab SMfp_side_effects
replace SMfp_side_effects=0 if SMfp_side_effects==-88

*** Set up putexcel
putexcel set "PMAET_`COHORT'_6M_MNHAnalysis_$date.xlsx", sheet("Table15") modify
putexcel A1=("Table 15. Told about Side Effects"), bold underline
putexcel A2=("Among women approximately six months postpartum who were currently using a method of family planning other than LAM and traditional methods at the time of the survey, the percentage who were told about potential side effects when they obtained the method, by background characteristics, PMA Ethiopia 2019-2021 Cohort")
putexcel B3=("Percent") C3=("Number of women (weighted)")
putexcel A4=("Overall") A5=("Age") A13=("Education") A19=("Parity") A25=("Region") A33=("Residence") A37=("Wealth") A44=("Months Postpartum"), bold

*	Told about FP side effects overall
local row = 4

sum SMfp_side_effects [aw=SMFUweight]
local mean1: disp %3.1f r(mean)*100
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1'), left nformat(0.0) bold
putexcel C`row'=(`n_1'), left nformat(number_sep) bold

*	Told about FP side effects by background characteristics
local row=6
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile child_age_cat {

	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SMFUweight] if SMfp_side_effects!=., matcell(a)
	putexcel C`row'=matrix(a), left nformat(number_sep)
	
	forvalues i = 1/`RowCount' {
		sum SMfp_side_effects if `RowVar'==`i' [aw=SMFUweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100

			putexcel A`row'=("`CellContents'") B`row'=(`mean1'), left nformat(0.0)
			
			count if `RowVar'==`i' & SMfp_side_effects!=.
			local n_1=r(N)
			
			if `n_1'>=25 & `n_1'<=49 {
				putexcel B`row'="(`mean1')", left nformat(0.0)
			}
			
			if `n_1'<25 {
				putexcel B`row'="*", left
			}
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}


*******************************************************************************
* SRH: FP DECISION
*******************************************************************************

*** Family planning decision 
*** Set up putexcel
putexcel set "PMAET_`COHORT'_6M_MNHAnalysis_$date.xlsx", sheet("Table16") modify
putexcel A1=("Table 16. Family Planning Decision"), bold underline
putexcel A2=("Among all women approximately six months postpartum who were using family planning (FP), the percentage distribution of those who discussed their decision to use FP with their partner before use, by background characteristics, PMA Ethiopia 2019-2021 Cohort")
putexcel B3=("Percent") C3=("Number of women (weighted)")
putexcel A4=("Overall") A5=("Age") A13=("Education") A19=("Parity") A25=("Region") A33=("Residence") A37=("Wealth") A44=("Months Postpartum"), bold

*	FP method type overall
local row = 4

sum SMpartner_discussion_before [aw=SMFUweight] if SMcurrent_user==1
local mean1: disp %3.1f r(mean)*100
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1'), left nformat(0.0) bold
putexcel C`row'=(`n_1'), left nformat(number_sep) bold

*	FP method type by background characteristics
local row=6
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile child_age_cat {

	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SMFUweight] if SMpartner_discussion_before!=. & SMcurrent_user==1, matcell(a)
	putexcel C`row'=matrix(a), left nformat(number_sep)
	
	forvalues i = 1/`RowCount' {
		sum SMpartner_discussion_before [aw=SMFUweight] if `RowVar'==`i' & SMcurrent_user==1
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100

			putexcel A`row'=("`CellContents'") B`row'=(`mean1') , left nformat(0.0)
			
			count if `RowVar'==`i' &  SMpartner_discussion_before!=.
			local n_1=r(N)
			
			if `n_1'>=25 & `n_1'<=49 {
				putexcel B`row'="(`mean1')", left nformat(0.0)
			}
			
			if `n_1'<25 {
				putexcel B`row'="*", left
			}
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	Decision to use among current users
tab SMwhy_decision SMcurrent_user, m

*	Decision not to use among non-current users 
tab SMwhy_not_decision SMcurrent_user, m 

count if SMcurrent_user==1 & SMwhy_decision!=.
local user=r(N)
count if SMcurrent_user==0 & SMwhy_not_decision!=.
local nonuser=r(N)

putexcel F4=("Figure 21. Family Planning Decision Among Current and Non-current Users"), bold underline
putexcel F5=("Among current users of FP, the proportion of women reporting that the decision to use FP was mainly the respondent's, husband's, joint or other, and among non-current users, the decision type for not using a method, PMA Ethiopia 2019-2021 Cohort")
putexcel G6=("Decision to use N=(`user')") H6=("Decision not to use N=(`nonuser')"), bold hcenter
putexcel F7=("Mainly respondent") F8=("Mainly husband/partner") F9=("Joint") F10=("Other")
local row=7

svy: tab SMwhy_decision		
putexcel G`row'=matrix(e(Prop)*100), left nformat(0.0)
	
svy: tab SMwhy_not_decision
putexcel H`row'=matrix(e(Prop)*100), left nformat(0.0)

*******************************************************************************
* SRH: FP COERSION 
*******************************************************************************

/*
- Method switch and pressured by provider for methods with sufficient sample 
	* Injectable (n=525)
	* Implant (n=245)
	* Pill (n=118)
*/

putexcel set "PMAET_`COHORT'_6M_MNHAnalysis_$date.xlsx", sheet("Figure22") modify
putexcel A1=("Figure 22. Family Planning Provider Bias"), bold underline
putexcel A2=("Among women who were approximately six months postpartum and currently using injectable, implant, or pill as the most effective method, the proportions who reported they were told that they could switch to a different method in the future and who felt that they were pressured from a health care provider to accept the current method, PMA Ethiopia 2019-2021 Cohort")
putexcel B3=("Injectable users") C3=("Implant users") D3=("Pill users")
putexcel A4=("Told about method switch") A5=("Felt pressured from health care provider")
putexcel A6=("Number of women"), left bold

local row = 4

foreach var in SMfp_told_switch SMfp_provider_forced {
		
		local i=1
		sum `var' [aw=SMFUweight] if SMcurrent_methodnum==5
		local mean`i': disp %3.1f r(mean)*100
		putexcel B`row'=(`mean`i''), left nformat(0.0)
		
		sum `var' [aw=SMFUweight] if SMcurrent_methodnum==3
		local mean`i': disp %3.1f r(mean)*100
		putexcel C`row'=(`mean`i''), left nformat(0.0)
		
		sum `var' [aw=SMFUweight] if SMcurrent_methodnum==7
		local mean`i': disp %3.1f r(mean)*100
		putexcel D`row'=(`mean`i''), left nformat(0.0)
		
		local row=`row' + 1
		local i=`i'+ 1
	}

count if SMcurrent_methodnum==5
local n_1=r(N)
count if SMcurrent_methodnum==3
local n_2=r(N)
count if SMcurrent_methodnum==7
local n_3=r(N)
putexcel B`row'=(`n_1') C`row'=(`n_2') D`row'=(`n_3'), left bold nformat(number_sep)

local `row'=`row'+2
putexcel A`row'=("*Four women were using contraceptive pills plus another more effective method."), italic

	
*******************************************************************************
* SRH: PREGNANCY INTENTION 
*******************************************************************************

/*
- Pregnancy intention
	* want no more childrem
	* want children in <=2 years
	* want children in >2 years 
- Would feel happy if they got pregnant now 
*/

*	Generate binary variables for pregnancy intention 
gen intent_nomore=0 if SMpregnant!=1
replace intent_nomore=1 if SMmore_children==0
label var intent_nomore "Wanted no more children"

gen intent_less2=0 if SMpregnant!=1
replace intent_less2=1 if SMmore_children==1 & (SMwait_birth==1 | (SMwait_birth==2 & SMwait_birth_value<2))
label var intent_less2 "wanted another child in less than two years"

gen intent_more2=0 if SMpregnant!=1
replace intent_more2=1 if SMmore_children==1 & SMwait_birth==2 & SMwait_birth_value>=2
label var intent_more2 "Wanted another child in two or more years"

gen intent_dnk=0 if SMpregnant!=1
replace intent_dnk=1 if SMmore_children==-88 | SMwait_birth==-88 | SMwait_birth==-99
label var intent_dnk "Not sure when or whether to have another child"

label val intent_nomore intent_less2 intent_more2 intent_dnk yesno
tab1 intent_nomore intent_less2 intent_more2 intent_dnk

*** Set up putexcel
putexcel set "PMAET_`COHORT'_6M_MNHAnalysis_$date.xlsx", sheet("Table17") modify
putexcel A1=("Table 17. Pregnancy Intention"), bold underline
putexcel A2=("Among women approximately six months postpartum, the percentage of those who wanted no more child, would wait less than two year and two or more years before having another child, by background characteristics, PMA Ethiopia 2019-2021 Cohort")
putexcel B3=("No more children") C3=("Less than two year") D3=("Two or more years") E3=("Do not know") F3=("Number of women (weighted)*")
putexcel A4=("Overall") A5=("Age") A13=("Education") A19=("Parity") A25=("Region") A33=("Residence") A37=("Wealth") A44=("Months Postpartum"), bold

*	Pregnancy intention overall
local row = 4

sum intent_nomore [aw=SMFUweight]
local mean1: disp %3.1f r(mean)*100
sum intent_less2 [aw=SMFUweight]
local mean2: disp %3.1f r(mean)*100
sum intent_more2 [aw=SMFUweight]
local mean3: disp %3.1f r(mean)*100
sum intent_dnk [aw=SMFUweight]
local mean4: disp %3.1f r(mean)*100
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') , left nformat(0.0) bold
putexcel F`row'=(`n_1'), left nformat(number_sep) bold

*	Pregnancy intention by background characteristics
local row=6
foreach RowVar in age_recode education_recode parity_recode region_recode urban_recode wealthquintile child_age_cat {

	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
	
	tabulate `RowVar' [aw=SMFUweight], matcell(a)
	putexcel C`row'=matrix(a), left nformat(number_sep)
	
	forvalues i = 1/`RowCount' {
		sum intent_nomore if `RowVar'==`i' [aw=SMFUweight]
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100

			sum intent_less2 [aw=SMFUweight] if `RowVar'==`i'
			local mean2: disp %3.1f r(mean)*100
			sum intent_more2 [aw=SMFUweight] if `RowVar'==`i'
			local mean3: disp %3.1f r(mean)*100
			sum intent_dnk [aw=SMFUweight] if `RowVar'==`i'
			local mean4: disp %3.1f r(mean)*100

			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4'), left nformat(0.0)
			
			count if `RowVar'==`i' & SMpregnant!=1
			local n_1=r(N)
			
			putexcel F`row'=(`n_1'), left nformat(number_sep)
			
			if `n_1'>=25 & `n_1'<=49 {
				putexcel B`row'="(`mean1')" C`row'="(`mean2')" D`row'="(`mean3')" E`row'="(`mean4')", left nformat(0.0)
			}
			
			if `n_1'<25 {
				putexcel B`row'="*" C`row'=("*") D`row'=("*") E`row'=("*"), left
			}
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}
	
count if SMpregnant==1
local preg_num=r(N)	
putexcel A`row'=("*`preg_num' pregnant women excluded")

*	Reaction if currently pregnant
*** Set up putexcel
putexcel set "PMAET_`COHORT'_6M_MNHAnalysis_$date.xlsx", sheet("Figure24") modify
putexcel A1=("Figure 24. Emotional Response Toward Potential Pregnancy"), bold underline
putexcel A2=("Among women approximately six months postpartum and not currently pregnant, the percentage of those who would feel very happy, sort of happy, mixed happy and unhappy, sort of unhappy, and very unhappy if they were pregnant now, PMA Ethiopia 2019-2021 Cohort") A4=("Very happy") A5=("Sort of happy") A6=("Mixed happy and unhappy") A7=("Sort of unhappy") A8=("Very unhappy")
putexcel B3=("Percent") 

local row = 4
	
tabulate SMpreg_now_react [aw=SMFUweight] if SMpreg_now_react!=-99 & SMpregnant!=1, matcell(a)

svy: tab SMpreg_now_react if SMpreg_now_react!=-99 & SMpregnant!=1
putexcel B`row'=matrix(e(Prop)*100), left nformat(0.0)

count if SMpreg_now_react!=-99 & SMpregnant!=1
local n=r(N)
putexcel A9=("Number of women*"), left bold
putexcel B9=(`n'), nformat(number_sep) left 

local row=`row'+1
putexcel A11=("*3 no response excluded"), left italic  

log close 
