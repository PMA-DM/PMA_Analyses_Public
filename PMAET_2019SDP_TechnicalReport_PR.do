/*******************************************************************************
*******  PMA Ethiopia 2019 SDP Technical Report Public Release .do file  *******

*   The following .do file will create the .xls file output that PMA Ethiopia used
*	to produce the 2019 Technical Report using PMA Ethiopia's publicly 
*	available Service Delivery Point dataset.
*
*
*   If you have any questions on how to use this .do files, please contact 
*	Ellie Qian at jqian@jhu.edu.
*******************************************************************************/


/*******************************************************************************
*
*	FILENAME:		PMAET_2019SDP_TechnicalReport_PR.do
*	PURPOSE:		Generate the .xls output for the 2019 PMA Ethiopia SDP Technical Report
*	CREATED BY: 	Elizabeth Stierman (estierm1@jhu.edu)
*	ADAPTED BY: 	Ellie Qian (jqian@jhu.edu)
*	DATA IN:		PMA Ethiopia's 2019 publicly released SDP dataset
*	DATA OUT: 		PMAET_2019SDP_Analysis_PR_DATE.dta
*   FILE OUT: 		PMAET_2019SDP_Analysis_DATE.xls
*   LOG FILE OUT: 	PMAET_2019SDP_Analysis_DATE.log
*
*******************************************************************************/


/*******************************************************************************
*   
*   INSTRUCTIONS:
*   Please update directories in SECTION 2 to set up and run the .do file

*******************************************************************************/


*******************************************************************************
*   SECITON A: STATA SET UP (PLEASE DO NOT DELETE)
*
*   Section A is necessary to make sure the .do file runs correctly, please do not 
*		move, update or delete
*******************************************************************************

clear
clear matrix
clear mata
capture log close
set more off

********************************************************************************
***   SECTION 1: CREATE MACRO FOR DATE
*
*   Section 1 is necessary to make sure the .do file runs correctly, please do not 
*		move, update or delete
********************************************************************************

*   Set local/global macros for current date
local today=c(current_date)
local c_today= "`today'"
global date=subinstr("`c_today'", " ", "",.)

********************************************************************************
***   SECTION 2: SET DIRECTORIES AND DATASET AND OUTPUT 
*
*	You will need to set up the macro for the dataset directory. 
*	Additionally, you will need to set up one directory for where you want to 
*		save your Excel output. 
*	For the .do file to run correctly, all macros need to be contained
*  		in quotation marks ("localmacro").
********************************************************************************

*   1. Set directory for the publicly available PMA2020 dataset on your computer
*	- For example (Mac): 
*		local datadir "/Users/ellieee/Desktop/PMAET/Technical_Report/SDP/PublicRelease/PMAET_SQ_2019_CrossSection_v2.0_13Aug2021.dta"
*	- For example (PC):
*		local datadir "C:\Users\annro\PMA2020\PMA2018_NGR5_National_HHQFQ_v5_4Nov2019.dta"

local datadir "/Users/ellieee/Desktop/PMAET/Technical_Report/SDP/PublicRelease/PMAET_SQ_2019_CrossSection_v2.0_13Aug2021.dta"


*   2. Set directory for the folder where you want to save the dataset, xls and
*			log files that this .do file creates
*		Please note that this should be a path on your LOCAL device, 
*			not any cloud server like Dropbox

*	- For example (Mac): 
*		  local briefdir "/Users/ellieee/Desktop/PMAET/Technical_Report/SDP/PublicRelease"
*	- For example (PC): 
*		  local briefdir "C:\Users\annro\PMAEthiopia\SDPOutput"

local outputdir "/Users/ellieee/Desktop/PMAET/Technical_Report/SDP/PublicRelease/analysis_$date"
capture mkdir "`outputdir'"


********************************************************************************
***   SECTION 3: PREPARATION OF DATA
********************************************************************************

*	Change to output directory
cd "`outputdir'"

*	Create log file 
log using "PMAET_2019SDP_Analysis_$date.log", replace

*	Load data 
use "`datadir'", clear

* Confirm that it is Ethiopia 2019 SDP data
gen check=(svy_year=="2019" & country=="Ethiopia")
capture confirm var facility_type 
if _rc!=0 {
	replace check=0
	}
if check!=1 {
	di in smcl as error "The dataset you are using is not the PMA Ethiopia 2019 SDP dataset. This .do file is to generate the .xls files for PMA Ethiopia 2019 SDP Technical Report only. Please use a the PMA Ethiopia 2019 SDP dataset and rerun the .do file"
	exit
	}
	drop check

*	Create a public/private variable
gen sector=.
replace sector=1 if managing_authority==1 
replace sector=2 if managing_authority!=1 & managing_authority!=.
ta sector managing_authority, m

*	Label sector variable
label define sectorl 1 "Public" 2 "Private"
label values sector sectorl
label variable sector "Sector"

*	Create a new facility type variable with combined category for pharmacies and drug shops
gen facility_type2=facility_type
replace facility_type2=5 if facility_type==7
label var facility_type2 "Type of facility" 
label define facility_type2_list 1 "Hospital" 2 "Health center" 3 "Health post" 4 "Health clinic" 5 "Pharmacy/Drug shop"
label val facility_type2 facility_type2_list
ta facility_type2 facility_type, m

*	Label yes/no response options
capture label define yesno 0 "No" 1 "Yes"

********************************************************************************
***   SECTION 4: RESPONSE RATE
********************************************************************************	

numlabel, remove

ssc install mdesc, replace

*	Check completeness of background characteristic variables
mdesc facility_type2 sector region
tab1 facility_type2 sector region

*	Set up putexcel
putexcel set PMAET_2019SDP_Analysis_$date.xlsx, sheet(Table1) replace
putexcel A1="Table 1. Response rate of sampled service delivery points, by background characteristics", bold underline
putexcel B2="Completed" C2="Not at facility" D2="Partly completed" E2="Other" F2="Number of SDPs in sample"
putexcel A3="Type" A10="Managing authority" A14="Region", bold

local datarow=4

*	Response rate by facility type, managing authority and region
foreach RowVar in facility_type2 sector region {
		local ColVar = "SDP_result"
		tab `RowVar' if !missing(`ColVar'), matcell(rowtotals)
		tab `RowVar' `ColVar', matcell(cellcounts)
		local RowCount = r(r)
		local ColCount = r(c)
		 
		local RowValueLabel : value label `RowVar'
		levelsof `RowVar' if !missing(`ColVar'), local(RowLevels) 
		local ColValueLabel : value label `ColVar'
		levelsof `ColVar', local(ColLevels) 
		 
		putexcel set PMAET_2019SDP_Analysis_$date.xlsx, sheet(Table1) modify
		
		forvalues row = 1/`RowCount' {
				local RowValueLabelNum = word("`RowLevels'", `row')
				local CellContents : label `RowValueLabel' `RowValueLabelNum'
				local Cell = char(64 + 1) + string(`datarow')
				putexcel `Cell' = "`CellContents'", left
					 
				local CellContents = rowtotals[`row',1]
				local Cell = char(64 + `ColCount' + 2) + string(`datarow')
				putexcel `Cell' = `CellContents', left
			 
				forvalues col = 1/`ColCount' {
					local cellcount = cellcounts[`row',`col']
					local cellpercent = string(100*`cellcount'/rowtotals[`row',1],"%9.1f")
					local CellContents = "`cellpercent'"
					local Cell = char(64 + `col' + 1) + string(`datarow')
					putexcel `Cell' = `CellContents', left			
			
				}
				
			local datarow=`datarow'+1
			
			}
		local datarow=`datarow'+2
	}

*	Overall response rate 
putexcel A`datarow'="Total", bold left
tab `ColVar', matcell(coltotals)
local totalSDP = r(N)
mat define cellpercent=coltotals'/`totalSDP'*100

local Cell = char(64 + 2) + string(`datarow')
putexcel `Cell' = matrix(cellpercent), left nformat(0.0)

local Cell = char(64 + `ColCount'+ 2) + string(`datarow')
putexcel `Cell'= "`totalSDP'", left

*	Keep only completed surveys (n=799) 
keep if SDP_result==1

********************************************************************************
***   SECTION 5: SDP BACKGROUND CHARACTERISTICS
********************************************************************************	

putexcel set PMAET_2019SDP_Analysis_$date.xlsx, sheet(Table2) modify
putexcel A1=("Table 2. Distribution of surveyed service delivery points, by facility characteristics"), bold underline
putexcel B2="Percent distribution of surveyed SDPs" C2="Number of SDPs" 
putexcel A3="Type" A10="Managing authority" A14="Region", bold

*	Facility type , managing authority, and region
local row = 4
foreach RowVar in facility_type2 sector region {
	tabulate `RowVar', matcell(freq) matrow(names)
	local rows = rowsof(names)
	
	local RowValueLabel : value label `RowVar'
	
	forvalues i = 1/`rows' {
			local val = names[`i',1]
			local val_lab : label `RowValueLabel' `val'
			local freq_val = freq[`i',1]
			local percent_val = `freq_val'/`r(N)'*100
			local percent_val : display %9.1f `percent_val'
	 
			putexcel A`row'=("`val_lab'") B`row'=(`percent_val') C`row'=(`freq_val'), left
			local row = `row' + 1
		}
	local row=`row'+2
	}
	
putexcel A`row'=("Total"), left bold
putexcel B`row'=(100.0) C`row'=(r(N)), left

*********************************************************
***   Staffing pattern
*********************************************************

*	Check staffing variables 
mdesc staffing_gyn_tot staffing_neo_tot staffing_ped_tot staffing_phy_tot staffing_ho_tot staffing_eo_tot staffing_po_tot staffing_anes_tot staffing_otherspec_tot staffing_anestech_tot staffing_nurse_tot staffing_midwife_tot staffing_uhep_tot staffing_hewl3_tot staffing_hewl4_tot staffing_pharmacy_tot staffing_labtech_tot if facility_type2!=5

summ staffing_gyn_tot staffing_neo_tot staffing_ped_tot staffing_phy_tot staffing_ho_tot staffing_eo_tot staffing_po_tot staffing_anes_tot staffing_otherspec_tot staffing_anestech_tot staffing_nurse_tot staffing_midwife_tot staffing_uhep_tot staffing_hewl3_tot staffing_hewl4_tot staffing_pharmacy_tot staffing_labtech_tot if facility_type2!=5

*	Recode 'don't know' (code -88) to missing
foreach v of varlist staffing_phy_tot staffing_anes_tot staffing_uhep_tot staffing_hewl3_tot staffing_hewl4_tot {
		replace `v'=. if `v'==-88
	}

*	Generate variable for specialist doctors
gen staffing_specialist = staffing_gyn_tot + staffing_neo_tot + staffing_ped_tot + staffing_anes_tot + staffing_otherspec_tot
label var staffing_specialist "Specialist"
ta staffing_specialist facility_type2, m

*	Generate variable for any other clinician: health officer, emergency officer, pediatrics officer, anesthesia technician 
gen staffing_clinician = staffing_ho_tot + staffing_eo_tot + staffing_po_tot + staffing_anestech_tot
label var staffing_clinician "Clinician"
ta staffing_clinician facility_type2, m

*	Generate variable for health extension workers
gen staffing_extension = staffing_uhep_tot + staffing_hewl3_tot + staffing_hewl4_tot if facility_type2!=3
replace staffing_extension = staffing_hewl3_tot + staffing_hewl4_tot if facility_type2==3
label var staffing_extension "Health extension worker"
ta staffing_extension facility_type2, m

*   Staffing pattern in survey SDPs, condensed
putexcel set "PMAET_2019SDP_Analysis_$date.xlsx", sheet("Table3.1") modify
putexcel A1="Table 3.1 Staffing pattern in service delivery points: expanded", bold underline
putexcel A2="Median number (25th to 75th percentile) of providers who work at facility, by type of provider and type of facility, PMA Ethiopia 2019", italic
putexcel B3=("Hospital") C3=("Health center") D3=("Health post") E3=("Health clinic") F3=("Pharmacy/Drug shop")

local row=4
foreach v of varlist staffing_phy_tot staffing_specialist staffing_clinician staffing_nurse_tot staffing_midwife_tot staffing_extension staffing_pharmacy_tot staffing_labtech_tot {
		sum `v' if facility_type2==1, detail
		local varlabel: variable label `v'
		local med_iqr1: disp %1.0f r(p50) " (" %1.0f r(p25) "-" %1.0f r(p75) ")"
		if r(N)!=0 local n_1= r(N)

		sum `v' if facility_type2==2, detail
		local med_iqr2: disp %1.0f r(p50) " (" %1.0f r(p25) "-" %1.0f r(p75) ")"
		if r(N)!=0 local n_2= r(N)
		
		sum `v' if facility_type2==3, detail
		local med_iqr3: disp %1.0f r(p50) " (" %1.0f r(p25) "-" %1.0f r(p75) ")"
		if r(N)!=0 local n_3= r(N)
		
		sum `v' if facility_type2==4, detail
		local med_iqr4: disp %1.0f r(p50) " (" %1.0f r(p25) "-" %1.0f r(p75) ")"
		if r(N)!=0 local n_4= r(N)
		
		sum `v' if facility_type2==5, detail
		local med_iqr5: disp %1.0f r(p50) " (" %1.0f r(p25) "-" %1.0f r(p75) ")"
		if r(N)!=0 local n_5= r(N)
		
		putexcel A`row'=("`varlabel'") B`row'=("`med_iqr1'") C`row'=("`med_iqr2'") D`row'=("`med_iqr3'") E`row'=("`med_iqr4'") F`row'=("`med_iqr5'")
		local row = `row' + 1
	}
		putexcel A`row'=("Number of SDPs") B`row'=(`n_1') C`row'=(`n_2') D`row'=(`n_3') E`row'=(`n_4') F`row'=(`n_5'), left
	
*	Staffing pattern in survey SDPs, expanded (as defined in the SDP questionnaire)
putexcel set "PMAET_2019SDP_Analysis_$date.xlsx", sheet("Table3.2") modify
putexcel A1=("Table 3.2 Staffing pattern in service delivery points: expanded"), bold underline
putexcel A2=("Median number (25th to 75th percentile) of providers who work at facility, by type of provider and type of facility, PMA Ethiopia 2019"), italic
putexcel B3=("Hospital") C3=("Health center") D3=("Health post") E3=("Health clinic") F3=("Pharmacy/Drug shop")

local row=4
foreach v of varlist staffing_phy_tot staffing_gyn_tot staffing_neo_tot staffing_ped_tot staffing_anes_tot staffing_otherspec_tot staffing_ho_tot staffing_eo_tot staffing_po_tot staffing_anestech_tot staffing_nurse_tot staffing_midwife_tot staffing_uhep_tot staffing_hewl3_tot staffing_hewl4_tot staffing_pharmacy_tot staffing_labtech_tot {
		sum `v' if facility_type2==1, detail
		local varlabel: variable label `v'
		local med_iqr1: disp %1.0f r(p50) " (" %1.0f r(p25) "-" %1.0f r(p75) ")"
		if r(N)!=0 local n_1= r(N)
		
		sum `v' if facility_type2==2, detail
		local med_iqr2: disp %1.0f r(p50) " (" %1.0f r(p25) "-" %1.0f r(p75) ")"
		if r(N)!=0 local n_2= r(N)
		
		sum `v' if facility_type2==3, detail
		local med_iqr3: disp %1.0f r(p50) " (" %1.0f r(p25) "-" %1.0f r(p75) ")"
		if r(N)!=0 local n_3= r(N)
		
		sum `v' if facility_type2==4, detail
		local med_iqr4: disp %1.0f r(p50) " (" %1.0f r(p25) "-" %1.0f r(p75) ")"
		if r(N)!=0 local n_4= r(N)
		
		sum `v' if facility_type2==5, detail
		local med_iqr5: disp %1.0f r(p50) " (" %1.0f r(p25) "-" %1.0f r(p75) ")"
		if r(N)!=0 local n_5= r(N)

		putexcel A`row'=("`varlabel'") B`row'=("`med_iqr1'") C`row'=("`med_iqr2'") D`row'=("`med_iqr3'") E`row'=("`med_iqr4'") F`row'=("`med_iqr5'")
		local row = `row' + 1
	}
		putexcel A`row'=("Number of SDPs") B`row'=(`n_1') C`row'=(`n_2') D`row'=(`n_3') E`row'=(`n_4') F`row'=(`n_5'), left

*********************************************************
***   Availability of basic amenities
*********************************************************

*	Check completeness of basic amenities variables
bys facility_type2: mdesc electricity_7d electricity_other water_outlet toilet_pt internet_7d if facility_type2!=5
tab1 electricity_7d electricity_other water_outlet toilet_pt internet_7d if facility_type2!=5, m

*	Generate regular electricity variable
gen electricity_regular = 0 if facility_type2!=5
replace electricity_regular = 1 if electricity_7d==5 | electricity_other==1
label var electricity_regular "Regular source of electricity (no interuption and/or backup source)"
label val electricity_regular yesno
ta facility_type2 electricity_regular, m

*	Generate continuous (i.e., no interruptions) binary electricity variable
gen electricity_binary = 0 if facility_type2!=5
replace electricity_binary = 1 if electricity_7d==5 
label var electricity_binary "Regular source of electricity (no interuption in past 7 days)"
label val electricity_binary yesno
ta electricity_7d electricity_binary, m

*	Generate binary internet variable
gen internet_binary = 0 if facility_type2!=5
replace internet_binary = 1 if internet==1 | internet==2
label var internet_binary "Access to internet"
label val internet_binary yesno
ta internet_binary internet_7d, m

*	Set up putexcel
putexcel set "PMAET_2019SDP_Analysis_$date.xlsx", sheet("Table4") modify
putexcel A1=("Table 4. Availability of basic amenities for client services"), bold underline
putexcel B2=("Regular electricity") C2=("Continuous electricity") D2=("Water outlet onsite") E2=("Client toilet") F2=("Internet") G2=("Number of facilities")
putexcel A3="Type" A9="Managing authority" A13="Region" A27="Total", bold

*	Basic amenities by facility type, managing authority, and region
local row = 4
foreach RowVar in facility_type2 sector region {

	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)

	forvalues i = 1/`RowCount' {
		
		sum electricity_regular if `RowVar'==`i'
			
		if r(N)!=0 {
			
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum electricity_binary if `RowVar'==`i'
			local mean2: disp %3.1f r(mean)*100
			
			sum water_outlet if `RowVar'==`i'
			local mean3: disp %3.1f r(mean)*100
			
			sum toilet_pt if `RowVar'==`i'
			local mean4: disp %3.1f r(mean)*100
			
			sum internet_binary if `RowVar'==`i'
			local mean5: disp %3.1f r(mean)*100
			if r(N)!=0 local n_1= r(N)
			
			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2')  D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`n_1'), left
			
			local row = `row' + 1
			
			}
		}
	local row=`row'+2
	}
	
*	Overall amenities
sum electricity_regular 
local mean1: disp %3.1f r(mean)*100
sum electricity_binary 
local mean2: disp %3.1f r(mean)*100
sum water_outlet 
local mean3: disp %3.1f r(mean)*100
sum toilet_pt 
local mean4: disp %3.1f r(mean)*100
sum internet_binary 
local mean5: disp %3.1f r(mean)*100
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2')  D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`n_1'), left

*********************************************************
***   Health management information systems (HMIS)
*********************************************************	

*	Check completeness of hmis variables
mdesc hmis_system_yn hmis_report if facility_type2!=5
tab1 hmis_system_yn hmis_report if facility_type2!=5, m
ta hmis_report_freq hmis_report if facility_type2!=5, m
mdesc hmis_report_freq if hmis_report==1 & facility_type2!=5
tab1 hmis_report_freq if hmis_report==1 & facility_type2!=5, m

*	Generate variable for monthly or more reporting
gen hmis_report_monthly = 0 if facility_type2!=5
replace hmis_report_monthly = 1 if hmis_report_freq==5
label var hmis_report_monthly "Produces HMIS reports monthly or more often"
label val hmis_report_monthly yesno
ta hmis_report_freq  hmis_report_monthly if facility_type2!=5, m

*	Set up putexcel
putexcel set "PMAET_2019SDP_Analysis_$date.xlsx", sheet("Table5") modify
putexcel A1=("Table 5. Health management information system (HMIS)"), bold underline
putexcel B2=("Functional mechanism for summarizing outcome data") C2=("Produces reports for HMIS") D2=("Produces reports for HMIS monthly or more often") E2=("Number of facilities")
putexcel A3="Type" A9="Managing authority" A13="Region" A27="Total", bold

*	HMIS by facility type, sector, and region
local row = 4

foreach RowVar in facility_type2 sector region {

	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)

	forvalues i = 1/`RowCount' {

		sum hmis_system_yn if `RowVar'==`i'
		 
		if r(N)!=0 {
			
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum hmis_report if `RowVar'==`i'
			local mean2: disp %3.1f r(mean)*100
			
			sum hmis_report_monthly if `RowVar'==`i'
			local mean3: disp %3.1f r(mean)*100
			if r(N)!=0 local n_1= r(N)
			
			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2')  D`row'=(`mean3') E`row'=`n_1', left
			
			local row = `row' + 1
			}
		}
	local row=`row'+2
	}

*	HMIS overall
sum hmis_system_yn 
local mean1: disp %3.1f r(mean)*100
sum hmis_report 
local mean2: disp %3.1f r(mean)*100
sum hmis_report_monthly 
local mean3: disp %3.1f r(mean)*100
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2')  D`row'=(`mean3') E`row'=(`n_1'), left

*********************************************************
***   HMIS feedback and recommendations
*********************************************************	

*	Check completeness
mdesc fb_wordea fb_zonal_dept fb_hlth_bureau fb_ngo fb_fmoh fb_leadership fb_rec_action if hmis_report==1 & facility_type2!=5
tab1 fb_wordea fb_zonal_dept fb_hlth_bureau fb_ngo fb_fmoh fb_leadership fb_rec_action if hmis_report==1 & facility_type2!=5, m

*	Recode variables for those with don't know/no response
foreach var of varlist fb_wordea fb_zonal_dept fb_hlth_bureau fb_ngo fb_fmoh fb_leadership fb_rec_action {
		replace `var'=. if `var'==-77 | `var'==-88 | `var'==-99   
	}

*	Generate variable for receiving any feedback on reports
gen fb_any = 0 if hmis_report==1 & facility_type2!=5
replace fb_any = 1 if (fb_wordea==1 | fb_zonal_dept==1 | fb_hlth_bureau==1 | fb_ngo==1 | fb_fmoh==1 | fb_leadership==1) & hmis_report==1 & facility_type2!=5
replace fb_any = . if (fb_wordea==. & fb_zonal_dept==. & fb_hlth_bureau==. & fb_ngo==. & fb_fmoh==. & fb_leadership==.) & hmis_report==1 & facility_type2!=5
label var fb_any "Receives any feedback on reports"
label val fb_any yesno

*	Generate variable for receiving any external feedback on reports
gen fb_external = 0 if hmis_report==1 & facility_type2!=5
replace fb_external = 1 if (fb_wordea==1 | fb_zonal_dept==1 | fb_hlth_bureau==1 | fb_ngo==1 | fb_fmoh==1 ) & hmis_report==1 & facility_type2!=5
replace fb_external = . if (fb_wordea==. & fb_zonal_dept==. & fb_hlth_bureau==. & fb_ngo==. & fb_fmoh==.) & hmis_report==1 & facility_type2!=5
label var fb_external "Receives any external feedback on reports"
label val fb_external yesno

*	Recode feedback with recommendations variable so denominator includes all facilities that produce reports
ta fb_rec_action fb_any if hmis_report==1 & facility_type2!=5, m
replace fb_rec_action=0 if hmis_report==1 & facility_type2!=5 & fb_any==0 & fb_rec_action==.

*	Check completeness
mdesc fb_leadership fb_external fb_any fb_rec_action if hmis_report==1 & facility_type2!=5
misstable patterns fb_leadership fb_external fb_any fb_rec_action if hmis_report==1 & facility_type2!=5, freq

*	Set up putexcel
putexcel set "PMAET_2019SDP_Analysis_$date.xlsx", sheet("Table6") modify
putexcel A1=("Table 6. HMIS feedback and recommendations"), bold underline
putexcel A2=("Among health facilities that produce reports for HMIS, percentages that receive feedback on reports; and percentages that receive feedback that includes recommendations for action to improve quality of care"), italic
putexcel B3=("From facility's leadership team") C3=("From external stakeholders") D3=("From facility leadership and/or external stakeholders") E3="That include recommendations for action to improve quality of care" F3=("Number of facilities")
putexcel A4="Type" A10="Managing authority" A14="Region" A28="Total", bold

*	HMIS feedback and recommendations by facility type
local row = 5
foreach RowVar in facility_type2 sector region {

	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)

	forvalues i = 1/`RowCount' {
		sum fb_leadership if `RowVar'==`i' & hmis_report==1
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum fb_external if `RowVar'==`i' & hmis_report==1
			local mean2: disp %3.1f r(mean)*100
			
			sum fb_any if `RowVar'==`i' & hmis_report==1
			local mean3: disp %3.1f r(mean)*100
			
			sum fb_rec_action if `RowVar'==`i' & hmis_report==1
			local mean4: disp %3.1f r(mean)*100
			count if `RowVar'==`i' & hmis_report==1
			if r(N)!=0 local n_1= r(N)

			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2')  D`row'=(`mean3') E`row'=(`mean4') F`row'=`n_1', left	
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	HMIS feedback and recommendations overall

sum fb_leadership if hmis_report==1
local mean1: disp %3.1f r(mean)*100
sum fb_external if hmis_report==1
local mean2: disp %3.1f r(mean)*100
sum fb_any if hmis_report==1
local mean3: disp %3.1f r(mean)*100
sum fb_rec_action if hmis_report==1
local mean4: disp %3.1f r(mean)*100

count if hmis_report==1
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2')  D`row'=(`mean3') E`row'=(`mean4')  F`row'=(`n_1'), left

*********************************************************
***   Type of HMIS recommendations
*********************************************************	

*	Check completeness
mdesc review_effort review_facility improv_care resource_allocation resource_advocacy if hmis_report==1 & facility_type2!=5 & fb_rec_action==1
tab1 review_effort review_facility improv_care resource_allocation resource_advocacy if hmis_report==1 & facility_type2!=5 & fb_rec_action==1, m

*	Generate new variables for those with don't know/no response
foreach var of varlist fb_rec_action review_effort review_facility improv_care resource_allocation resource_advocacy {
		replace `var'=. if `var'==-77 | `var'==-88 | `var'==-99   
	}

*	Set up putexcel
putexcel set "PMAET_2019SDP_Analysis_$date.xlsx", sheet("Table7") modify
putexcel A1=("Table 7. Types of action-oriented recommendations made based on HMIS data"), bold underline
putexcel A2=("Among health facilities that receive feedback that includes recommendations for action to improve quality of care, percentages that receive each type of action-oriented recommendation made based on most recent HMIS data"), italic
putexcel B3=("Review effort") C3=("Review personnel responsibilities") D3=("Quality of care improvement") E3=("Resource allocation based on comparison by services") F3=("Advocacy for more resources by showing gaps") G3=("Number of facilities")
putexcel A4="Type" A10="Managing authority" A14="Region" A28="Total", bold

*	Type of HMIS recommendations by facility type
local row = 5
foreach RowVar in facility_type2 sector region {

	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)

	forvalues i = 1/`RowCount' {
		sum review_effort if `RowVar'==`i' & hmis_report==1 & fb_rec_action==1

		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum review_facility if `RowVar'==`i' & hmis_report==1 & fb_rec_action==1
			local mean2: disp %3.1f r(mean)*100
			
			sum improv_care if `RowVar'==`i' & hmis_report==1 & fb_rec_action==1
			local mean3: disp %3.1f r(mean)*100
			
			sum resource_allocation if `RowVar'==`i' & hmis_report==1 & fb_rec_action==1
			local mean4: disp %3.1f r(mean)*100
			
			sum resource_advocacy if `RowVar'==`i' & hmis_report==1 & fb_rec_action==1
			local mean5: disp %3.1f r(mean)*100
			
			count if `RowVar'==`i' & hmis_report==1 & fb_rec_action==1
			if r(N)!=0 local n_1= r(N)

			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`n_1'), left	
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	HMIS feedback and recommendations overall

sum review_effort if hmis_report==1 & fb_rec_action==1
local mean1: disp %3.1f r(mean)*100
sum review_facility if hmis_report==1 & fb_rec_action==1
local mean2: disp %3.1f r(mean)*100
sum improv_care if hmis_report==1 & fb_rec_action==1
local mean3: disp %3.1f r(mean)*100
sum resource_allocation if hmis_report==1 & fb_rec_action==1
local mean4: disp %3.1f r(mean)*100
sum resource_advocacy if hmis_report==1 & fb_rec_action==1
local mean5: disp %3.1f r(mean)*100

count if hmis_report==1 & fb_rec_action==1
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2')  D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`n_1'), left
	
*********************************************************
***   Performance monitoring teams
*********************************************************	

*	Check completeness
mdesc pmt pmt_meet pmt_meet_freq if (facility_type2==1 | facility_type2==2) & sector==1
tab1 pmt pmt_meet pmt_meet_freq if (facility_type2==1 | facility_type2==2) & sector==1

*	Generate variables for facilities with PMT that meets monthly or more often
gen pmt_meet_monthly = 0 if (facility_type2==1 | facility_type2==2) & sector==1
replace pmt_meet_monthly = 1 if pmt_meet_freq==5 & (facility_type2==1 | facility_type2==2) & sector==1
replace pmt_meet_monthly = . if pmt_meet_freq==-88 & (facility_type2==1 | facility_type2==2) & sector==1
label var pmt_meet_monthly "Facility has PMT that meets monthly or more often"
label val pmt_meet_monthly yesno
ta pmt_meet_monthly if (facility_type2==1 | facility_type2==2) & sector==1, m

*	Set up putexcel
putexcel set "PMAET_2019SDP_Analysis_$date.xlsx", sheet("Table8") modify
putexcel A1=("Table 8. Performance monitoring team (PMT)"), bold underline
putexcel A2=("Among government hospitals and health centers, percentages that have a Performance monitoring team (PMT) and percentages that have a PMT that meets monthly or more often"), italic
putexcel B3=("Has PMT") C3=("PMT meets monthly or more often") D3=("Number of facilities")
putexcel A4="Type" A8="Region" A22="Total", bold

*	Performance monitoring teams by facility type, managing authority, and region 
preserve 
keep if (facility_type2==1 | facility_type2==2) & sector==1 // restrict to public hospitals and healht centers 

local row = 5
foreach RowVar in facility_type2 region {

	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)

	forvalues i = 1/`RowCount' {
		sum pmt if `RowVar'==`i'
		
		if r(N)!=0 {
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum pmt_meet_monthly if `RowVar'==`i' 
			local mean2: disp %3.1f r(mean)*100

			count if `RowVar'==`i'
			if r(N)!=0 local n_1= r(N)

			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2')  D`row'=(`n_1'), left	
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	Performance monitoring teams overall
sum pmt
local mean1: disp %3.1f r(mean)*100
sum pmt_meet_monthly
local mean2: disp %3.1f r(mean)*100
count
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2')  D`row'=(`n_1'), left	

restore 

*********************************************************
***   Participatory performance reviews
*********************************************************	

*	Check completeness
mdesc perform_review perform_review_freq if (facility_type2==1 | facility_type2==2)
tab1 perform_review perform_review_freq if (facility_type2==1 | facility_type2==2)

*	Generate variables for facilities with performance reviews that occur monthly or more often
gen perform_review_monthly = 0 if (facility_type2==1 | facility_type2==2) 
replace perform_review_monthly = 1 if perform_review_freq==5 & (facility_type2==1 | facility_type2==2)
replace perform_review_monthly = . if perform_review==-88 & (facility_type2==1 | facility_type2==2) 
label var perform_review_monthly "Facility has participatory performance review that occurs monthly or more often"
label val perform_review_monthly yesno
ta perform_review_freq perform_review_monthly if (facility_type2==1 | facility_type2==2), m

*	Generate variables for facilities with performance reviews that occur quarterly
gen perform_review_quarterly = 0 if (facility_type2==1 | facility_type2==2) 
replace perform_review_quarterly = 1 if perform_review_freq==4 & (facility_type2==1 | facility_type2==2)
replace perform_review_quarterly = . if perform_review==-88 & (facility_type2==1 | facility_type2==2) 
label var perform_review_quarterly "Facility has participatory performance review that occurs quarterly"
label val perform_review_quarterly yesno
ta perform_review_freq perform_review_quarterly if (facility_type2==1 | facility_type2==2), m

*	Generate variables for facilities with performance reviews that occur less frequently or no defined frequency
gen perform_review_infreq = 0 if (facility_type2==1 | facility_type2==2) 
replace perform_review_infreq = 1 if (perform_review_freq==0 | perform_review_freq==2 | perform_review_freq==3) & (facility_type2==1 | facility_type2==2)
replace perform_review_infreq = . if perform_review==-88 & (facility_type2==1 | facility_type2==2) 
label var perform_review_infreq "Facility has infrequent participatory performance reviews"
label val perform_review_infreq yesno
ta perform_review_freq perform_review_infreq if (facility_type2==1 | facility_type2==2), m

*	Generate variables for facilities with no performance reviews
gen perform_review_none = 0 if (facility_type2==1 | facility_type2==2) 
replace perform_review_none = 1 if (perform_review==0) & (facility_type2==1 | facility_type2==2)
replace perform_review_none = . if perform_review==-88 & (facility_type2==1 | facility_type2==2) 
label var perform_review_none "Facility has no participatory performance reviews"
label val perform_review_none yesno
ta perform_review perform_review_none if (facility_type2==1 | facility_type2==2), m

*   Generate new variable for those with don't know/no response
foreach var of varlist perform_review {
		replace `var'=. if `var'==-77 | `var'==-88 | `var'==-99   
	}
mdesc perform_review if (facility_type2==1 | facility_type2==2)

*	Set up putexcel
putexcel set "PMAET_2019SDP_Analysis_$date.xlsx", sheet("Table9") modify
putexcel A1=("Table 9. Participatory performance review meetings"), bold underline
putexcel A2=("Among hospital and health centers, percentages that conduct participatory performance review meetings and frequency of meetings"), italic
putexcel B3=("Conduct participatory performance review meetings") C3=("Monthly or more often") D3=("Quality") E3=("Less often") F3=("Not at all") G3=("Number of facilities")
putexcel A4="Type" A8="Managing authority" A12="Region" A26="Total", bold

*	Participatory performance reviews by facility type, managing authority, and region 
preserve 
keep if facility_type2==1 | facility_type2==2 // restrict to hospitals and health centers

local row = 5
foreach RowVar in facility_type2 sector region {

	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)

	forvalues i = 1/`RowCount' {
		sum perform_review if `RowVar'==`i'

		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum perform_review_monthly if `RowVar'==`i' 
			local mean2: disp %3.1f r(mean)*100
			
			sum perform_review_quarterly if `RowVar'==`i' 
			local mean3: disp %3.1f r(mean)*100
			
			sum perform_review_infreq if `RowVar'==`i'
			local mean4: disp %3.1f r(mean)*100
			
			sum perform_review_none if `RowVar'==`i' 
			local mean5: disp %3.1f r(mean)*100
			
			count if `RowVar'==`i'
			if r(N)!=0 local n_1= r(N)

			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`n_1'), left	
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	Participatory performance reviews overall 
sum perform_review 
local mean1: disp %3.1f r(mean)*100
sum perform_review_monthly 
local mean2: disp %3.1f r(mean)*100
sum perform_review_quarterly 
local mean3: disp %3.1f r(mean)*100
sum perform_review_infreq 
local mean4: disp %3.1f r(mean)*100
sum perform_review_none 
local mean5: disp %3.1f r(mean)*100
count
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2')  D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`n_1'), left

restore 

**********************************************************
***   Availability of maternal and newborn health services
**********************************************************	

*	Check completeness
mdesc antenatal_yn labor_delivery_yn postnatal_yn surgery_yn transfusion_yn neonatal_yn if facility_type2!=5
tab1 antenatal_yn labor_delivery_yn postnatal_yn surgery_yn transfusion_yn neonatal_yn if facility_type2!=5

*	Generate new variable for those with don't know/no response
foreach var of varlist antenatal_yn surgery_yn {
		replace `var'=. if `var'==-77 | `var'==-88 | `var'==-99   
	}

mdesc antenatal_yn labor_delivery_yn postnatal_yn surgery_yn transfusion_yn neonatal_yn if facility_type2!=5
misstable pattern antenatal_yn labor_delivery_yn postnatal_yn surgery_yn transfusion_yn neonatal_yn if facility_type2!=5, freq

*	Generate variables for facilities that offer all MNH services
gen services_mnh_all = 0 if facility_type2!=5
replace services_mnh_all = 1 if antenatal_yn==1 & labor_delivery_yn==1 & postnatal_yn==1 & surgery_yn==1 & transfusion_yn==1 & neonatal_yn==1 & facility_type2!=5
label var services_mnh_all "Facility offers all MNH services (ANC, LD, PNC, c-section, transfusion, neonatal)"
label val services_mnh_all yesno
ta services_mnh_all facility_type2 if facility_type2!=5, m	

*	Set up putexcel
putexcel set "PMAET_2019SDP_Analysis_$date.xlsx", sheet("Table10") modify
putexcel A1=("Table 10. Availability of maternal and newborn health services"), bold underline
putexcel B3=("Antenatal care") C3=("Labor and delivery care") D3=("Postnatal care") E3=("Obstetric surgery") F3=("Blood transfusion") G3=("Neonatal intensive care") H3=("Number of facilities")
putexcel A4="Type" A10="Managing authority" A14="Region" A28="Total", bold

*	MNH service availability by facility type, managing authority, and region
local row = 5

foreach RowVar in facility_type2 sector region {

	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)

	forvalues i = 1/`RowCount' {
		sum antenatal_yn if `RowVar'==`i'
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum labor_delivery_yn if `RowVar'==`i'
			local mean2: disp %3.1f r(mean)*100
			
			sum postnatal_yn if `RowVar'==`i' 
			local mean3: disp %3.1f r(mean)*100
			
			sum surgery_yn if `RowVar'==`i' 
			local mean4: disp %3.1f r(mean)*100
			
			sum transfusion_yn if `RowVar'==`i' 
			local mean5: disp %3.1f r(mean)*100
			
			sum neonatal_yn if `RowVar'==`i' 
			local mean6: disp %3.1f r(mean)*100
			
			count if `RowVar'==`i' & facility_type2!=5
			if r(N)!=0 local n_1= r(N) 

			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6') H`row'=(`n_1'), left
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	MNH service availability overall 
sum antenatal_yn
local mean1: disp %3.1f r(mean)*100
sum labor_delivery_yn 
local mean2: disp %3.1f r(mean)*100
sum postnatal_yn 
local mean3: disp %3.1f r(mean)*100
sum surgery_yn 
local mean4: disp %3.1f r(mean)*100
sum transfusion_yn 
local mean5: disp %3.1f r(mean)*100
sum neonatal_yn 
local mean6: disp %3.1f r(mean)*100
count if facility_type2!=5
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2')  D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6') H`row'=(`n_1'), left

*********************************************************
***   ANC equipment, diagnostic capacity, commodities, and amenities
*********************************************************	

*	Check completeness
mdesc se_bpdevice se_fetal_stetho se_fetalscope se_dipstick indr_hiv_rapid outdr_hiv_rapid outdr_syphilis outdr_iron vax_tt rm_anc_setting if labor_delivery_yn==1 & facility_type2!=5
ta indr_hiv_rapid outdr_hiv_rapid if labor_delivery_yn==1 & facility_type2!=5, m
tab1 se_bpdevice se_fetal_stetho se_fetalscope se_dipstick indr_hiv_rapid outdr_hiv_rapid outdr_syphilis outdr_iron vax_tt rm_anc_setting if labor_delivery_yn==1 & facility_type2!=5

*	Generate variables
*	Generate dichotomous variable for whether hospital, health center/clinic, or neither
gen hospital=.
replace hospital=1 if facility_type==1
replace hospital=2 if facility_type==2 | facility_type==4
label var hospital "Type of facility" 
label define hospital_list 1 "Hospital" 2 "Health center/clinic" 
label val hospital hospital_list
ta facility_type hospital , m

*	Create dichotomous variable for whether or not medication/supplies is OBSERVED outside the delivery room on the day of the interview
foreach var of varlist se_bpdevice se_fetal_stetho se_fetalscope se_dipstick outdr_hiv_rapid outdr_syphilis outdr_iron vax_tt  {
		gen `var'_obs =0 if labor_delivery_yn==1 & facility_type2!=5
		replace `var'_obs=1 if `var'==2
		replace `var'_obs=. if `var'==. | `var'==-77 | `var'==-88 | `var'==-99   
		label variable `var'_obs "`var' observed outside delivery room on day of interview"
		label define `var'_obs 0 "not observed" 1 "observed"
		label val `var'_obs `var'_obs
	}

*	Create dichotomous variable for whether or not medication is OBSERVED inside the delivery room on the day of the interview
foreach var of varlist indr_hiv_rapid  {
		gen `var'_obs =0 if labor_delivery_yn==1 & facility_type2!=5
		replace `var'_obs=1 if `var'==2
		replace `var'_obs=. if `var'==. | `var'==-77 | `var'==-88 | `var'==-99   
		label variable `var'_obs "`var' available inside delivery room on day of interview"
		label define `var'_obs 0 "not observed" 1 "observed"
		label val `var'_obs `var'_obs
	}


*	Create dichotomous variable for whether medication is observed at facility on the day of the interview
local meds "hiv_rapid"
foreach x in `meds' {
		gen `x'_obs=0 if labor_delivery_yn==1 & facility_type2!=5
		replace `x'_obs=1 if indr_`x'_obs==1 | outdr_`x'_obs==1
		replace `x'_obs=. if indr_`x'_obs==. & outdr_`x'_obs==.
		label variable `x'_obs "`x' observed at facility on day of interview"
		label define `x'_obs 0 "not observed" 1 "observed"
		label val `x'_obs `x'_obs
	}

*	Create dichotomous variable for fetal stethoscope or fetal scope
gen se_fetal_either_obs=0 if labor_delivery_yn==1 & facility_type2!=5
replace se_fetal_either_obs=1 if (se_fetal_stetho_obs==1 | se_fetalscope_obs==1) & labor_delivery_yn==1 & facility_type2!=5
label var se_fetal_either_obs "Either fetal scope or fetal stethoscope observed on day of interview"
label define se_fetal_either_obs 0 "not observed" 1 "observed"
label val se_fetal_either_obs se_fetal_either_obs
ta se_fetal_stetho_obs se_fetalscope_obs if labor_delivery_yn==1 & facility_type2!=5, m

*	Create dichotomous variable for visual privacy in ANC room
gen anc_privacy=0 if labor_delivery_yn==1 & facility_type2!=5
replace anc_privacy=1 if (rm_anc_setting==1 | rm_anc_setting==2) & labor_delivery_yn==1 & facility_type2!=5
replace anc_privacy=. if rm_anc_setting==-99 & labor_delivery_yn==1 & facility_type2!=5
label var anc_privacy "Visual privacy"
label define anc_privacy 0 "No visual privacy" 1 "Visual privacy"
label val anc_privacy anc_privacy

mdesc se_bpdevice_obs se_fetal_either_obs se_dipstick_obs hiv_rapid_obs outdr_syphilis_obs outdr_iron_obs vax_tt_obs anc_privacy  if labor_delivery_yn==1 & facility_type2!=5
misstable pattern se_bpdevice_obs se_fetal_either_obs se_dipstick_obs hiv_rapid_obs outdr_syphilis_obs outdr_iron_obs vax_tt_obs anc_privacy  if labor_delivery_yn==1 & facility_type2!=5, freq

*	Shorten variable name
rename se_bpdevice_obs bp_apparatus_obs 

*	Set up putexcel
putexcel set "PMAET_2019SDP_Analysis_$date.xlsx", sheet("Table11") modify
putexcel A1=("Table 11. Equipment, diagnostic capacity, commodities, and amenities for antenatal care (ANC)"), bold underline
putexcel A2=("Among facilities offering delivery services, percentages that have indicated items observed on the day of the survey"), italic
putexcel B3=("Blood pressure apparatus") C3=("Fetal stethoscope and/or fetal scope") D3=("Urine dipstick") E3=("HIV rapid test") F3=("Syphilis testing (VDRL)") G3=("Iron and/or folic acid tablets") H3=("Tetanus toxoid vaccines") I3=("Visual privacy in ANC room") J3=("Number of facilities")
putexcel A4="Type" A8="Managing authority" A12="Region" A26="Total", bold

*	 ANC equipment, diagnostic capacity, commodities, and amenities by facility type, managing authority, and region
local row = 5
foreach RowVar in hospital sector region {

	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)

	forvalues i = 1/`RowCount' {
		sum bp_apparatus_obs if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum se_fetal_either_obs if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean2: disp %3.1f r(mean)*100
			
			sum se_dipstick_obs if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean3: disp %3.1f r(mean)*100
			
			sum hiv_rapid_obs if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean4: disp %3.1f r(mean)*100
			
			sum outdr_syphilis_obs if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean5: disp %3.1f r(mean)*100
			
			sum outdr_iron_obs if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean6: disp %3.1f r(mean)*100
			
			sum vax_tt_obs if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean7: disp %3.1f r(mean)*100
			
			sum anc_privacy if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean8: disp %3.1f r(mean)*100
			
			count if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			if r(N)!=0 local n_1= r(N) 

			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6') H`row'=(`mean7') I`row'=(`mean8') J`row'=(`n_1'), left
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	ANC equipment, diagnostic capacity, commodities, and amenities overall
sum bp_apparatus_obs if labor_delivery_yn==1 & hospital!=.
local mean1: disp %3.1f r(mean)*100
sum se_fetal_either_obs if labor_delivery_yn==1 & hospital!=.
local mean2: disp %3.1f r(mean)*100
sum se_dipstick_obs if labor_delivery_yn==1 & hospital!=.
local mean3: disp %3.1f r(mean)*100
sum hiv_rapid_obs if labor_delivery_yn==1 & hospital!=.
local mean4: disp %3.1f r(mean)*100
sum outdr_syphilis_obs if labor_delivery_yn==1 & hospital!=.
local mean5: disp %3.1f r(mean)*100
sum outdr_iron_obs if labor_delivery_yn==1 & hospital!=.
local mean6: disp %3.1f r(mean)*100
sum vax_tt_obs if labor_delivery_yn==1 & hospital!=.
local mean7: disp %3.1f r(mean)*100
sum anc_privacy if labor_delivery_yn==1 & hospital!=.
local mean8: disp %3.1f r(mean)*100

count if labor_delivery_yn==1 & hospital!=.
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6') H`row'=(`mean7') I`row'=(`mean8') J`row'=(`n_1'), left

*********************************************************
***   Staffing, guidelines, equipment for delivery
*********************************************************	

*	Check completeness
mdesc skilled_ba proc_fmoh_ob se_kit_delivery se_tie se_scissors se_suction se_suction_cath se_forceps se_vac_extract se_kit_dc se_mva se_resus_mask0 se_resus_mask1 se_resus_bag indr_ivsoln outdr_ivsoln se_ivcannula se_syringe rm_delivery_setting if labor_delivery_yn==1 & facility_type2!=5 
ta indr_ivsoln outdr_ivsoln if labor_delivery_yn==1 & facility_type2!=5, m 
tab1 skilled_ba proc_fmoh_ob se_kit_delivery se_tie se_scissors se_suction se_suction_cath se_forceps se_vac_extract se_kit_dc se_mva se_resus_mask0 se_resus_mask1 se_resus_bag indr_ivsoln outdr_ivsoln se_ivcannula se_syringe rm_delivery_setting if labor_delivery_yn==1 & facility_type2!=5 


*   Generate variables
*   Create dichotomous variable for whether or not equipment is OBSERVED and FUNCTIONING on the day of the interview
foreach var of varlist se_suction_cath se_vac_extract {
gen `var'_obs =0 if labor_delivery_yn==1 & facility_type2!=5
		replace `var'_obs=1 if `var'==4
		replace `var'_obs=. if `var'==. | `var'==-77 | `var'==-88 | `var'==-99 
		label variable `var'_obs "`var' observed and functional on day of interview"
		label define `var'_obs 0 "not observed/functional" 1 "observed and functional"
		label val `var'_obs `var'_obs
	}

*   Create dichotomous variable for whether or not medication/supplies is OBSERVED outside the delivery room on the day of the interview
foreach var of varlist se_kit_delivery se_tie se_scissors se_suction se_forceps se_kit_dc se_mva se_resus_mask0 se_resus_mask1 se_resus_bag outdr_ivsoln se_ivcannula se_syringe  {
		gen `var'_obs =0 if labor_delivery_yn==1 & facility_type2!=5
		replace `var'_obs=1 if `var'==2
		replace `var'_obs=. if `var'==. | `var'==-77 | `var'==-88 | `var'==-99   
		label variable `var'_obs "`var' observed outside delivery room on day of interview"
		label define `var'_obs 0 "not observed" 1 "observed"
		label val `var'_obs `var'_obs
	}

*   Create dichotomous variable for whether or not medication/guideline is OBSERVED inside the delivery room on the day of the interview
foreach var of varlist proc_fmoh_ob indr_ivsoln  {
		gen `var'_obs =0 if labor_delivery_yn==1 & facility_type2!=5
		replace `var'_obs=1 if `var'==2
		replace `var'_obs=. if `var'==. | `var'==-77 | `var'==-88 | `var'==-99   
		label variable `var'_obs "`var' available inside delivery room on day of interview"
		label define `var'_obs 0 "not observed" 1 "observed"
		label val `var'_obs `var'_obs
	}

*   Create dichotomous variable for whether medication is observed at facility on the day of the interview
local meds "ivsoln_obs"
foreach x in `meds' {
		gen `x'_obs=0 if labor_delivery_yn==1 & facility_type2!=5
		replace `x'_obs=1 if indr_`x'==1 | outdr_`x'==1
		replace `x'_obs=. if indr_`x'==. & outdr_`x'==.
		label variable `x'_obs "`x' observed at facility on day of interview"
		label define `x'_obs 0 "not observed" 1 "observed"
		label val `x'_obs `x'_obs
	}

*   Generate variable for both observed: clamps/tie and scissors/blade (either in kit or separate)
generate se_clamp_scissors_obs = 0 if labor_delivery_yn==1 & facility_type2!=5
replace se_clamp_scissors_obs =1 if  se_kit_delivery_obs==1 | (se_tie_obs==1 & se_scissors_obs==1)
replace se_clamp_scissors_obs =. if  se_kit_delivery_obs==. & se_tie_obs==. & se_scissors_obs==1.
label variable se_clamp_scissors_obs "both observed: clamps/tie and scissors/blade"
label define se_clamp_scissors_obs 0 "not observed" 1 "observed"
label value se_clamp_scissors_obs se_clamp_scissors_obs

*   Generate variable for at least one observed: functional suction apparatus or manual suction device
generate se_suction_either=0 if labor_delivery_yn==1 & facility_type2!=5
replace se_suction_either=1 if se_suction_obs==1 |  se_suction_cath_obs==1 
replace se_suction_either=. if  se_suction_obs==. &  se_suction_cath_obs==. 
label variable se_suction_either "At least one observed: Functional suction apparatus or manual suction device"
label define se_suction_either 0 "not observed" 1 "observed"
label value se_suction_either se_suction_either

*   Generate variable for at least one observed: forceps and/or vacuum extractor 
generate se_forceps_vac_obs=0 if labor_delivery_yn==1 & facility_type2!=5
replace se_forceps_vac_obs=1 if se_forceps_obs==1 | se_vac_extract_obs==1
replace se_forceps_vac_obs=. if se_forceps_obs==. & se_vac_extract_obs==.
label variable se_forceps_vac_obs "At least one observed: forceps and/or vacuum extractor"
label define se_forceps_vac_obs 0 "not observed" 1 "observed"
label value se_forceps_vac_obs se_forceps_vac_obs

*   Generate variable for at least one observed: D&C kit or MVA
generate se_dc_mva_obs=0 if labor_delivery_yn==1 & facility_type2!=5
replace se_dc_mva_obs=1 if se_kit_dc_obs==1 | se_mva_obs==1 
replace se_dc_mva_obs=. if  se_kit_dc_obs==. & se_mva_obs==. 
label variable se_dc_mva_obs "At least one observed: D&C kit or MVA"
label define se_dc_mva_obs 0 "not observed" 1 "observed"
label value se_dc_mva_obs se_dc_mva_obs

*   Generate variable for newborn resusitation masks (two sizes) and bag observed
generate se_resus_bag_masks=0 if labor_delivery_yn==1 & facility_type2!=5
replace se_resus_bag_masks=1 if se_resus_mask0_obs==1 & se_resus_mask1_obs==1 & se_resus_bag_obs==1
replace se_resus_bag_masks=. if  se_resus_mask0_obs==. & se_resus_mask1_obs==. & se_resus_bag_obs==.
label variable se_resus_bag_masks "newborn resusitation masks (two sizes) and bag observed"
label define se_resus_bag_masks 0 "not observed" 1 "observed"
label value se_resus_bag_masks se_resus_bag_masks

*   Generate variable for IV solution in facility and infusion set
generate ivkit = 0 if labor_delivery_yn==1 & facility_type2!=5
replace ivkit =1 if ivsoln_obs==1 & se_ivcannula_obs==1 & se_syringe_obs==1  
replace ivkit =. if ivsoln_obs==. & se_ivcannula_obs==. & se_syringe_obs==.  
label variable ivkit "IV solution and infusion set (cannula, needle, syringe)"
label define ivkit 0 "not observed" 1 "observed"
label value ivkit ivkit

*   Create dichotomous variable for whether visual privacy assured
gen rm_delivery_privacy =0 if labor_delivery_yn==1 & facility_type2!=5
replace rm_delivery_privacy=1 if rm_delivery_setting==1 | rm_delivery_setting==2
replace rm_delivery_privacy=. if rm_delivery_setting==. | rm_delivery_setting==-77 | rm_delivery_setting==-88 | rm_delivery_setting==-99   
label variable rm_delivery_privacy "Visual privacy in delivery room"
label define rm_delivery_privacy 0 "No visual privacy" 1 "Visual privacy"
label val rm_delivery_privacy rm_delivery_privacy

*	Set up putexcel
putexcel set "PMAET_2019SDP_Analysis_$date.xlsx", sheet("Table12") modify
putexcel A1=("Table 12. Staffing, guidelines, equipment, and amenities for delivery care"), bold underline
putexcel A2=("Among facilities offering delivery services, percentages that have indicated items observed on the day of the survey"), italic
putexcel B3=("Skilled birth attendant 24 hours/day") C3=("Management Protocol on Obstetric Topics") D3=("Delivery pack") E3=("Suction apparatus") F3=("Obstetric forceps and/or vacuum extractor") G3=("MVA and/or D&C kit") H3=("Neonatal bag and masks") I3=("Intravenous fluids with infusion set") J3=("Visual privacy in delivery room") K3=("Number of facilities")
putexcel A4="Type" A8="Managing authority" A12="Region" A26="Total", bold

*	 Staffing, guidelines, equipment for delivery by facility type, managing authority, and region
local row = 5
foreach RowVar in hospital sector region {

	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)

	forvalues i = 1/`RowCount' {
		sum skilled_ba if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum proc_fmoh_ob_obs if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean2: disp %3.1f r(mean)*100
			
			sum se_clamp_scissors_obs if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean3: disp %3.1f r(mean)*100
			
			sum se_suction_either if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean4: disp %3.1f r(mean)*100
			
			sum se_forceps_vac_obs if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean5: disp %3.1f r(mean)*100
			
			sum se_dc_mva_obs if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean6: disp %3.1f r(mean)*100
			
			sum se_resus_bag_masks if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean7: disp %3.1f r(mean)*100
			
			sum ivkit if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean8: disp %3.1f r(mean)*100
			
			sum rm_delivery_privacy if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean9: disp %3.1f r(mean)*100
			
			count if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			if r(N)!=0 local n_1= r(N) 

			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6') H`row'=(`mean7') I`row'=(`mean8') J`row'=(`mean9') K`row'=(`n_1'), left
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	ANC equipment, diagnostic capacity, commodities, and amenities overall	    
sum skilled_ba if labor_delivery_yn==1 & hospital!=.
local mean1: disp %3.1f r(mean)*100
sum proc_fmoh_ob_obs if labor_delivery_yn==1 & hospital!=.
local mean2: disp %3.1f r(mean)*100
sum se_clamp_scissors_obs if labor_delivery_yn==1 & hospital!=.
local mean3: disp %3.1f r(mean)*100
sum se_suction_either if labor_delivery_yn==1 & hospital!=.
local mean4: disp %3.1f r(mean)*100
sum se_forceps_vac_obs if labor_delivery_yn==1 & hospital!=.
local mean5: disp %3.1f r(mean)*100
sum se_dc_mva_obs if labor_delivery_yn==1 & hospital!=.
local mean6: disp %3.1f r(mean)*100
sum se_resus_bag_masks if labor_delivery_yn==1 & hospital!=.
local mean7: disp %3.1f r(mean)*100
sum ivkit if labor_delivery_yn==1 & hospital!=.
local mean8: disp %3.1f r(mean)*100
sum rm_delivery_privacy if labor_delivery_yn==1 & hospital!=.
local mean9: disp %3.1f r(mean)*100

count if labor_delivery_yn==1 & hospital!=.
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6') H`row'=(`mean7') I`row'=(`mean8') J`row'=(`mean9') K`row'=(`n_1'), left

*********************************************************
***  Availability of life-saving maternal and reproductive health medicines
*********************************************************	

*   Check completeness
mdesc outdr_inj_ampicillin outdr_azithromycin outdr_benzathine outdr_dexamethasone indr_inj_cagluc outdr_cefixime outdr_inj_gentamicin outdr_hydralazine outdr_inj_mgso4 outdr_methyldopa outdr_inj_metro outdr_mife outdr_miso outdr_nifedipine outdr_inj_oxt if labor_delivery_yn==1 & facility_type2!=5

mdesc indr_dexamethasone indr_inj_cagluc indr_hydralazine indr_inj_mgso4 indr_mife indr_miso indr_nifedipine indr_inj_oxt if labor_delivery_yn==1 & facility_type2!=5

summ indr_dexamethasone indr_inj_cagluc indr_hydralazine indr_inj_mgso4 indr_mife indr_miso indr_nifedipine indr_inj_oxt if labor_delivery_yn==1 & facility_type2!=5

*   Generate variables
*   Create dichotomous variable for whether or not medication is OBSERVED outside the delivery room on the day of the interview
foreach var of varlist outdr_inj_ampicillin outdr_azithromycin outdr_benzathine outdr_dexamethasone outdr_inj_cagluc outdr_cefixime outdr_inj_gentamicin outdr_hydralazine outdr_inj_mgso4 outdr_methyldopa outdr_inj_metro outdr_mife outdr_miso outdr_nifedipine outdr_inj_oxt {
		gen `var'_obs=0 if labor_delivery_yn==1 & facility_type2!=5
		replace `var'_obs=1 if `var'==2
		replace `var'_obs=. if `var'==. | `var'==-77 | `var'==-88 | `var'==-99   
		label variable `var'_obs "`var' observed outside delivery room on day of interview"
		label define `var'_obs 0 "not observed" 1 "observed"
		label val `var'_obs `var'_obs
	}

*   Create dichotomous variable for whether or not medication is OBSERVED inside the delivery room on the day of the interview
foreach var of varlist indr_dexamethasone indr_inj_cagluc indr_hydralazine indr_inj_mgso4 indr_mife indr_miso indr_nifedipine indr_inj_oxt {
		gen `var'_obs =0 if labor_delivery_yn==1 & facility_type2!=5
		replace `var'_obs=1 if `var'==2
		replace `var'_obs=. if `var'==. | `var'==-77 | `var'==-88 | `var'==-99   
		label variable `var'_obs "`var' available inside delivery room on day of interview"
		label define `var'_obs 0 "not observed" 1 "observed"
		label val `var'_obs `var'_obs
	}

*   Create dichotomous variable for whether medication is observed at facility on the day of the interview
local meds "dexamethasone_obs inj_cagluc_obs hydralazine_obs inj_mgso4_obs mife_obs miso_obs nifedipine_obs inj_oxt_obs"
foreach x in `meds' {
		gen `x'_obs=0 if labor_delivery_yn==1 & facility_type2!=5
		replace `x'_obs=1 if indr_`x'==1 | outdr_`x'==1
		replace `x'_obs=. if indr_`x'==. & outdr_`x'==. 
		label variable `x'_obs "`x' observed at facility on day of interview"
		label define `x'_obs 0 "not observed" 1 "observed"
		label val `x'_obs `x'_obs
	}

*   Check missingness		
mdesc outdr_inj_ampicillin_obs outdr_azithromycin_obs outdr_benzathine_obs dexamethasone_obs inj_cagluc_obs outdr_cefixime_obs outdr_inj_gentamicin_obs hydralazine_obs inj_mgso4_obs outdr_methyldopa_obs outdr_inj_metro_obs mife_obs miso_obs nifedipine_obs inj_oxt_obs ivsoln_obs vax_tt_obs  indr_dexamethasone indr_inj_cagluc indr_hydralazine indr_inj_mgso4 indr_mife indr_miso indr_nifedipine indr_inj_oxt indr_ivsoln if labor_delivery_yn==1 & hospital!=. 

misstable pattern outdr_inj_ampicillin_obs outdr_azithromycin_obs outdr_benzathine_obs dexamethasone_obs inj_cagluc_obs outdr_cefixime_obs outdr_inj_gentamicin_obs hydralazine_obs inj_mgso4_obs outdr_methyldopa_obs outdr_inj_metro_obs mife_obs miso_obs nifedipine_obs inj_oxt_obs ivsoln_obs vax_tt_obs  indr_dexamethasone indr_inj_cagluc indr_hydralazine indr_inj_mgso4 indr_mife indr_miso indr_nifedipine indr_inj_oxt indr_ivsoln if labor_delivery_yn==1 & hospital!=. , freq

*   Rename	
rename outdr_inj_ampicillin_obs inj_ampicillin_obs 
rename outdr_inj_gentamicin_obs inj_gentamicin_obs
rename outdr_inj_metro_obs inj_metronidazole_obs

*	Re-define label 
label variable inj_ampicillin_obs "Injectable ampicillin"
label variable outdr_azithromycin_obs "Azithromycin"
label variable outdr_benzathine_obs "Benzathine benzylpenicillin"
label variable dexamethasone_obs "Betamethasone or dexamethasone"
label variable inj_cagluc_obs "Injectable calcium gluconate"
label variable outdr_cefixime_obs "Cefixime"
label variable inj_gentamicin_obs "Injectable gentamicin"
label variable hydralazine_obs "Hydralazine"
label variable inj_mgso4_obs "Injectable magnesium sulfate"
label variable outdr_methyldopa_obs "Methyldopa"
label variable inj_metronidazole_obs "Injectable metronidazole"
label variable mife_obs "Mifepristone"
label variable miso_obs "Misoprostol tablet"
label variable nifedipine_obs "Nifedipine"
label variable inj_oxt_obs "Injectable oxytocin"
label variable ivsoln_obs "Intravenous solution for infusion"
label variable vax_tt_obs "Tetanus toxoid vaccine"

label variable indr_dexamethasone_obs "Betamethasone or dexamethasone"
label variable indr_inj_cagluc_obs "Injectable calcium gluconate"
label variable indr_hydralazine_obs "Hydralazine"
label variable indr_inj_mgso4_obs "Injectable magnesium sulfate"
label variable indr_mife_obs "Mifepristone"
label variable indr_miso_obs "Misoprostol tablet"
label variable indr_nifedipine_obs "Nifedipine"
label variable indr_inj_oxt_obs "Injectable oxytocin"
label variable indr_ivsoln_obs "Intravenous solution for infusion"

*   Staffing pattern in survey SDPs, condensed
putexcel set "PMAET_2019SDP_Analysis_$date.xlsx", sheet("Table13") modify
putexcel A1=("Table 13. Availability of life-saving maternal and reproductive health medicines"), bold underline
putexcel A2=("Among facilities offering delivery sevices, percentages with indicated priority medicines observed on the day of the survey, by facility characteristics"), italic
putexcel B3=("Hospital") C3=("Health center") D3=("Public") E3=("Private") F3=("Total")
putexcel A4=("Priority medicines observed in facility") A23=("Priority medicines observed in delivery room or nurse/staff station"), bold

*	Priority medicines observed in facility
local row=5
foreach v of varlist inj_ampicillin_obs outdr_azithromycin_obs outdr_benzathine_obs dexamethasone_obs inj_cagluc_obs outdr_cefixime_obs inj_gentamicin_obs hydralazine_obs inj_mgso4_obs outdr_methyldopa_obs inj_metronidazole_obs mife_obs miso_obs nifedipine_obs inj_oxt_obs ivsoln_obs vax_tt_obs {
		sum `v' if hospital==1 & labor_delivery_yn==1 & hospital!=.
		local varlabel: variable label `v'
		local mean1: disp %3.1f r(mean)*100

		sum `v' if hospital==2 & labor_delivery_yn==1 & hospital!=.
		local varlabel: variable label `v'
		local mean2: disp %3.1f r(mean)*100
		
		sum `v' if sector==1 & labor_delivery_yn==1 & hospital!=.
		local varlabel: variable label `v'
		local mean3: disp %3.1f r(mean)*100
		
		sum `v' if sector==2 & labor_delivery_yn==1 & hospital!=.
		local varlabel: variable label `v'
		local mean4: disp %3.1f r(mean)*100
			
		sum `v' if labor_delivery_yn==1 & hospital!=.
		local total: disp %3.1f r(mean)*100
		
		putexcel A`row'=("`varlabel'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`total'), left
		
		local row = `row' + 1
	}
	
*	Priority medicines observed in delivery room or nurse/staff station
local row = 24
foreach v of varlist indr_dexamethasone_obs indr_inj_cagluc_obs indr_hydralazine_obs indr_inj_mgso4_obs indr_mife_obs indr_miso_obs indr_nifedipine_obs indr_inj_oxt_obs indr_ivsoln_obs {
		sum `v' if hospital==1 & labor_delivery_yn==1 & hospital!=.
		local varlabel: variable label `v'
		local mean1: disp %3.1f r(mean)*100
		if r(N)!=0 local n_1= r(N) 

		sum `v' if hospital==2 & labor_delivery_yn==1 & hospital!=.
		local varlabel: variable label `v'
		local mean2: disp %3.1f r(mean)*100
		if r(N)!=0 local n_2= r(N) 
		
		sum `v' if sector==1 & labor_delivery_yn==1 & hospital!=.
		local varlabel: variable label `v'
		local mean3: disp %3.1f r(mean)*100
		if r(N)!=0 local n_3= r(N) 
		
		sum `v' if sector==2 & labor_delivery_yn==1 & hospital!=.
		local varlabel: variable label `v'
		local mean4: disp %3.1f r(mean)*100
		if r(N)!=0 local n_4= r(N) 
			
		sum `v' if labor_delivery_yn==1 & hospital!=.
		local total: disp %3.1f r(mean)*100
		if r(N)!=0 local n_5= r(N) 
		
		putexcel A`row'=("`varlabel'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`total'), left
		
		local row = `row' + 1
	}

local row = `row' + 1	
putexcel A`row'=("Number of SDPs") B`row'=(`n_1') C`row'=(`n_2') D`row'=(`n_3') E`row'=(`n_4') F`row'=(`n_5'), left

*********************************************************
***  Count: Availability of life-saving maternal and reproductive health medicines
*********************************************************	

*   Check completeness
mdesc inj_ampicillin_obs outdr_azithromycin_obs outdr_benzathine_obs dexamethasone_obs inj_cagluc_obs outdr_cefixime_obs inj_gentamicin_obs hydralazine_obs inj_mgso4_obs outdr_methyldopa_obs inj_metronidazole_obs mife_obs miso_obs nifedipine_obs inj_oxt_obs ivsoln_obs vax_tt_obs  if labor_delivery_yn==1 & hospital!=.
misstable pattern inj_ampicillin_obs outdr_azithromycin_obs outdr_benzathine_obs dexamethasone_obs inj_cagluc_obs outdr_cefixime_obs inj_gentamicin_obs hydralazine_obs inj_mgso4_obs outdr_methyldopa_obs inj_metronidazole_obs mife_obs miso_obs nifedipine_obs inj_oxt_obs ivsoln_obs vax_tt_obs  if labor_delivery_yn==1 & hospital!=., freq

*   Generate variable for whether facilities have all 17 life-saving medicines
gen meds_count = (inj_ampicillin_obs + outdr_azithromycin_obs + outdr_benzathine_obs + dexamethasone_obs + inj_cagluc_obs + outdr_cefixime_obs + inj_gentamicin_obs + hydralazine_obs + inj_mgso4_obs + outdr_methyldopa_obs + inj_metronidazole_obs + mife_obs + miso_obs + nifedipine_obs + inj_oxt_obs + ivsoln_obs + vax_tt_obs ) if labor_delivery_yn==1 & hospital!=.
replace meds_count = (inj_ampicillin_obs + outdr_azithromycin_obs + outdr_benzathine_obs + dexamethasone_obs + inj_cagluc_obs + outdr_cefixime_obs + inj_gentamicin_obs + hydralazine_obs + inj_mgso4_obs + outdr_methyldopa_obs + inj_metronidazole_obs + mife_obs + miso_obs + nifedipine_obs + inj_oxt_obs + ivsoln_obs ) if labor_delivery_yn==1 & hospital!=. & vax_tt_obs==.
replace meds_count = (inj_ampicillin_obs + outdr_azithromycin_obs + outdr_benzathine_obs + dexamethasone_obs + inj_cagluc_obs + inj_gentamicin_obs + hydralazine_obs + inj_mgso4_obs + outdr_methyldopa_obs + inj_metronidazole_obs + mife_obs + miso_obs + nifedipine_obs + inj_oxt_obs + ivsoln_obs + vax_tt_obs ) if labor_delivery_yn==1 & hospital!=. &  outdr_cefixime_obs==.
replace meds_count = (inj_ampicillin_obs + outdr_benzathine_obs + dexamethasone_obs + inj_cagluc_obs + outdr_cefixime_obs + inj_gentamicin_obs + hydralazine_obs + inj_mgso4_obs + outdr_methyldopa_obs + inj_metronidazole_obs + mife_obs + miso_obs + nifedipine_obs + inj_oxt_obs + ivsoln_obs + vax_tt_obs ) if labor_delivery_yn==1 & hospital!=. & outdr_azithromycin_obs==.
replace meds_count = (inj_ampicillin_obs + outdr_azithromycin_obs + dexamethasone_obs + inj_cagluc_obs + outdr_cefixime_obs + inj_gentamicin_obs + hydralazine_obs + inj_mgso4_obs + outdr_methyldopa_obs + inj_metronidazole_obs + mife_obs + miso_obs + nifedipine_obs + inj_oxt_obs + ivsoln_obs + vax_tt_obs ) if labor_delivery_yn==1 & hospital!=. & outdr_benzathine_obs==.
label variable meds_count "Count of life-saving meds observed at facility on day of interview"
ta meds_count if labor_delivery_yn==1 & hospital!=., m

*   Generate variable for whether facility has oxytocin and magnesium sulfate
gen both_oxt_mgso4 = 0 if labor_delivery_yn==1 & hospital!=.
replace both_oxt_mgso4 = 1 if labor_delivery_yn==1 & hospital!=. & inj_oxt_obs==1 & inj_mgso4_obs==1
label var  both_oxt_mgso4 "Both oxytocin and magnesium sulfate observed at facility on day of interview"
label define both_oxt_mgso4 0 "not observed" 1 "observed"
label val both_oxt_mgso4 both_oxt_mgso4
ta both_oxt_mgso4 if labor_delivery_yn==1 & hospital!=., m

*   Generate variable for whether facilities have at least 7 life-saving medicines, including oxytocin and magnesium sulfate
gen meds7 = 0  if labor_delivery_yn==1 & hospital!=.
replace meds7=1 if both_oxt_mgso4==1 & meds_count>=7 & labor_delivery_yn==1 & hospital!=.
label var meds7 "At least 7 life-saving medicines, including oxytocin and magnesium sulfate observed at facility"
label define  meds7 0 "not observed" 1 "observed"
label val meds7  meds7
ta meds_count meds7  if labor_delivery_yn==1 & hospital!=., m

*   Generate variable for whether facilities have at least 14 life-saving medicines, including oxytocin and magnesium sulfate
gen meds14 = 0 if labor_delivery_yn==1 & hospital!=.
replace meds14=1 if both_oxt_mgso4==1 & meds_count>=14 &  labor_delivery_yn==1 & hospital!=.
label var meds14 "At least 14 life-saving medicines, including oxytocin and magnesium sulfate observed at facility"
label define  meds14 0 "not observed" 1 "observed"
label val meds14 meds14
ta meds_count meds14 if labor_delivery_yn==1 & hospital!=., m

*   Generate variable for whether facilities have at least 10 life-saving medicines, including oxytocin and magnesium sulfate
gen meds17 = 0 if labor_delivery_yn==1 & hospital!=.
replace meds17=1 if meds_count>=17 & labor_delivery_yn==1 & hospital!=.
label var meds17 "All 17 life-saving medicines observed at facility"
label define  meds17 0 "not observed" 1 "observed"
label val meds17 meds17
ta meds_count meds17 if labor_delivery_yn==1 & hospital!=., m	

*	Set up putexcel
putexcel set "PMAET_2019SDP_Analysis_$date.xlsx", sheet("Table14") modify
putexcel A1=("Table 14. Summary of available life-saving maternal and reproductive health medicines"), bold underline
putexcel A2=("Among facilities offering delivery services, percentages with oxytocin and magnesium sulfate, at least 7, at least 14, and all 17 priority medicines observed in the facility on the day of the survey"), italic
putexcel B3=("Both observed: oxytocin and magnesium sulfate") C3=("At least 7 priority medicines, including oxytocin and magnesium sulfate") D3=("At least 14 priority medicines, including oxytocin and magnesium sulfate") E3=("All 17 priority medicines") F3=("Number of facilities")
putexcel A4="Type" A8="Managing authority" A12="Region" A26="Total", bold

*	 Availability of life-saving maternal and reproductive health medicines by facility type, managing authority, and region
local row = 5
foreach RowVar in hospital sector region {
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)

	forvalues i = 1/`RowCount' {
		sum both_oxt_mgso4 if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum meds7 if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean2: disp %3.1f r(mean)*100
			
			sum meds14 if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean3: disp %3.1f r(mean)*100
			
			sum meds17 if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean4: disp %3.1f r(mean)*100
			
			count if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			if r(N)!=0 local n_1= r(N) 

			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`n_1'), left
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	 Overall availability of life-saving maternal and reproductive health medicines 
sum both_oxt_mgso4 if labor_delivery_yn==1 & hospital!=.
local mean1: disp %3.1f r(mean)*100
sum meds7 if labor_delivery_yn==1 & hospital!=.
local mean2: disp %3.1f r(mean)*100
sum meds14 if labor_delivery_yn==1 & hospital!=.
local mean3: disp %3.1f r(mean)*100
sum meds17 if labor_delivery_yn==1 & hospital!=.
local mean4: disp %3.1f r(mean)*100

count if labor_delivery_yn==1 & hospital!=.
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`n_1'), left

*********************************************************
***   Infection control precautions
*********************************************************

*   Check completeness
mdesc se_sharps se_waste se_cl se_syringe se_handwash_soap se_handwash_water water_outlet se_etoh_scrub se_gloves se_mask se_gown se_goggles if labor_delivery_yn==1 & hospital!=.
tab1 se_sharps se_waste se_cl se_syringe se_handwash_soap se_handwash_water water_outlet se_etoh_scrub se_gloves se_mask se_gown se_goggles if labor_delivery_yn==1 & hospital!=.

*   Generate variables
*   Create dichotomous variable for whether or not item is OBSERVED on the day of the interview
foreach var of varlist se_sharps se_waste se_cl se_handwash_soap se_handwash_water se_etoh_scrub se_gloves se_mask se_gown se_goggles  {
		gen `var'_obs =0 if labor_delivery_yn==1 & hospital!=.
		replace `var'_obs=1 if `var'==2
		replace `var'_obs=. if `var'==. | `var'==-77 | `var'==-88 | `var'==-99   
		label variable `var'_obs "`var' observed on day of interview"
		label define `var'_obs 0 "not observed" 1 "observed"
		label val `var'_obs `var'_obs
	}

*   Generate variable for at least one observed: water outlet onsite or water for staff handwashing
generate se_water_either = 0 if labor_delivery_yn==1 & hospital!=.
replace se_water_either =1 if  se_handwash_water_obs==1 | water_outlet==1
replace se_water_either =. if  se_handwash_water_obs==. & water_outlet==.
label variable se_water_either "at least one observed: water outlet on-site or observed water for staff handwashing"
label define se_water_either 0 "not observed" 1 "observed"
label value se_water_either se_water_either

*   Generate variable for both water and soap for handwashing
generate se_soap_water = 0 if labor_delivery_yn==1 & hospital!=.
replace se_soap_water =1 if  se_water_either==1 & se_handwash_soap_obs==1
replace se_soap_water =. if  se_water_either==. & se_handwash_soap_obs==.
label variable se_soap_water "both observed: soap and water"
label define se_soap_water 0 "not observed" 1 "observed"
label value se_soap_water se_soap_water

*   Generate variable for at least one observed: alcohol hand scrub or soap and water for staff handwashing
generate se_scrub_soap = 0 if labor_delivery_yn==1 & hospital!=.
replace se_scrub_soap =1 if  se_etoh_scrub_obs==1 | se_soap_water==1 
replace se_scrub_soap =. if  se_etoh_scrub_obs==. & se_soap_water==.
label variable se_scrub_soap "at least one observed: (1) alcohol hand scrub or (2) soap and water"
label define se_scrub_soap 0 "not observed" 1 "observed"
label value se_scrub_soap se_scrub_soap

*   Check missingness	
mdesc se_sharps_obs se_waste_obs se_cl_obs se_syringe_obs se_soap_water se_etoh_scrub_obs se_gloves_obs se_mask_obs se_gown_obs se_goggles_obs if labor_delivery_yn==1 & hospital!=.
misstable pattern se_sharps_obs se_waste_obs se_cl_obs se_syringe_obs se_soap_water se_etoh_scrub_obs se_gloves_obs se_mask_obs se_gown_obs se_goggles_obs if labor_delivery_yn==1 & hospital!=., freq

*   Rename
rename se_mask_obs mask_delivery_obs
rename se_gown_obs gown_delivery_obs

*	Set up putexcel
putexcel set "PMAET_2019SDP_Analysis_$date.xlsx", sheet("Table15") modify
putexcel A1=("Table 15. Standard precautions for infection control"), bold underline
putexcel A2=("Among facilities offering delivery services, percentages that have indicated items observed on the day of the survey"), italic
putexcel B3=("Sharp container") C3=("Waste receptacle with lid and plastic line") D3=("Already mixed decontam-inating solution") E3=("Syringes and needle") F3=("Soap and water") G3=("Alcohol-based hand scrub") H3=("Sterile gloves") I3=("Medical mask") J3=("Delivery gown") K3=("Eye/face protection goggles") L3=("Number of facilities")
putexcel A4="Type" A8="Managing authority" A12="Region" A26="Total", bold

*	Infection control precautions by facility type, managing authority, and region
local row = 5
foreach RowVar in hospital sector region {
	
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)

	forvalues i = 1/`RowCount' {
		sum se_sharps_obs if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum se_waste_obs if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean2: disp %3.1f r(mean)*100
			
			sum se_cl_obs if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean3: disp %3.1f r(mean)*100
			
			sum se_syringe_obs if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean4: disp %3.1f r(mean)*100
			
			sum se_soap_water if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean5: disp %3.1f r(mean)*100
			
			sum se_etoh_scrub_obs if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean6: disp %3.1f r(mean)*100
			
			sum se_gloves_obs if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean7: disp %3.1f r(mean)*100
			
			sum mask_delivery_obs if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean8: disp %3.1f r(mean)*100
			
			sum gown_delivery_obs if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean9: disp %3.1f r(mean)*100
			
			sum se_goggles_obs if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean10: disp %3.1f r(mean)*100
			
			count if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			if r(N)!=0 local n_1= r(N) 

			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6') H`row'=(`mean7') I`row'=(`mean8') J`row'=(`mean9') K`row'=(`mean10') L`row'=(`n_1'), left
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}   
	
*	Infection control precautions overall 
sum se_sharps_obs if labor_delivery_yn==1 & hospital!=.
local mean1: disp %3.1f r(mean)*100
sum se_waste_obs if labor_delivery_yn==1 & hospital!=.
local mean2: disp %3.1f r(mean)*100
sum se_cl_obs if labor_delivery_yn==1 & hospital!=.
local mean3: disp %3.1f r(mean)*100
sum se_syringe_obs if labor_delivery_yn==1 & hospital!=.
local mean4: disp %3.1f r(mean)*100
sum se_soap_water if labor_delivery_yn==1 & hospital!=.
local mean5: disp %3.1f r(mean)*100
sum se_etoh_scrub_obs if labor_delivery_yn==1 & hospital!=.
local mean6: disp %3.1f r(mean)*100
sum se_gloves_obs if labor_delivery_yn==1 & hospital!=.
local mean7: disp %3.1f r(mean)*100
sum mask_delivery_obs if labor_delivery_yn==1 & hospital!=.
local mean8: disp %3.1f r(mean)*100
sum gown_delivery_obs if labor_delivery_yn==1 & hospital!=.
local mean9: disp %3.1f r(mean)*100
sum se_goggles_obs if labor_delivery_yn==1 & hospital!=.
local mean10: disp %3.1f r(mean)*100

count if labor_delivery_yn==1 & hospital!=.
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6') H`row'=(`mean7') I`row'=(`mean8') J`row'=(`mean9') K`row'=(`mean10') L`row'=(`n_1') , left

*********************************************************
***   Sterilization and disinfection equipment
*********************************************************

*   Check completeness
mdesc ster_elec_ac ster_elec_dry ster_nonelec_ac ster_nonelec_heat ster_elec_boiler ster_nonelec_pot ster_chem_soln if surgery_yn==1 & hospital==1
tab1 ster_elec_ac ster_elec_dry ster_nonelec_ac ster_nonelec_heat ster_elec_boiler ster_nonelec_pot ster_chem_soln if surgery_yn==1 & hospital==1

*   Generate variables
*   Create dichotomous variable for whether electric equipment is OBSERVED and FUNCTIONING on the day of the interview
foreach var of varlist ster_elec_ac ster_elec_dry ster_elec_boiler {
		gen `var'_obs =0 if surgery_yn==1 & hospital==1
		replace `var'_obs=1 if `var'==4
		replace `var'_obs=. if `var'==. | `var'==-77 | `var'==-88 | `var'==-99 
		label variable `var'_obs "`var' observed and functional on day of interview"
		label define `var'_obs 0 "not observed/functional" 1 "observed and functional"
		label val `var'_obs `var'_obs
	}

*   Create dichotomous variable for whether non-electric equipment is OBSERVED and has HEAT SOURCE on the day of the interview
foreach var of varlist ster_nonelec_ac ster_nonelec_pot {
		gen `var'_obs =0 if surgery_yn==1 & hospital==1
		replace `var'_obs=1 if `var'==2 & ster_nonelec_heat==2
		replace `var'_obs=. if `var'==. | `var'==-77 | `var'==-88 | `var'==-99   
		label variable `var'_obs "`var' available and observed, with heat source, at facility on day of interview"
		label define `var'_obs 0 "not observed" 1 "observed"
		label val `var'_obs `var'_obs
	}

*   Create dichotomous variable for whether chemical solution is OBSERVED on the day of the interview
foreach var of varlist ster_chem_soln {
		gen `var'_obs =0 if surgery_yn==1 & hospital==1
		replace `var'_obs=1 if `var'==2 
		replace `var'_obs=. if `var'==. | `var'==-77 | `var'==-88 | `var'==-99   
		label variable `var'_obs "`var' available and observed at facility on day of interview"
		label define `var'_obs 0 "not observed" 1 "observed"
		label val `var'_obs `var'_obs
	}
	
*   Generate variable for at least one functional sterilization equipment observed
generate ster_any_obs=0 if surgery_yn==1 & hospital==1
replace ster_any_obs=1 if ster_elec_ac_obs==1 | ster_nonelec_ac_obs==1 | ster_elec_dry_obs==1 
replace ster_any_obs=. if  ster_elec_ac_obs==. & ster_nonelec_ac_obs==. & ster_elec_dry_obs==. 
label variable ster_any_obs "At least one: autoclave or dry heat sterilizer observed and functional"
label define ster_any_obs 0 "not observed" 1 "observed"
label value ster_any_obs ster_any_obs

*   Generate variable for at least equipment for high-level disinfection observed
generate disinfect_any_obs=0 if surgery_yn==1 & hospital==1
replace disinfect_any_obs=1 if ster_elec_boiler_obs==1 | ster_nonelec_pot_obs==1 | ster_chem_soln_obs==1 
replace disinfect_any_obs=. if  ster_elec_boiler_obs==. & ster_nonelec_pot_obs==. & ster_chem_soln_obs==. 
label variable disinfect_any_obs "At least one: electric boiler, non-electric pot, or chemical solution for high-level disinfection"
label define disinfect_any_obs 0 "not observed" 1 "observed"
label value disinfect_any_obs disinfect_any_obs

mdesc ster_any_obs disinfect_any_obs if surgery_yn==1 & facility_type2!=5

*	Set up putexcel
putexcel set "PMAET_2019SDP_Analysis_$date.xlsx", sheet("Table16") modify
putexcel A1=("Table 16. Sterilization and high-level disinfection equipment"), bold underline
putexcel A2=("Among hospitals offering obstetric surgery, percentages with equipment for sterilization and high-level disinfection"), italic
putexcel B3=("Sterilization equipment") C3=("Equipment for high-level disinfection") D3=("Number of facilities")
putexcel A4="Managing authority" A8="Region" A22="Total", bold

*	 Sterilization and disinfection equipment by managing authority and region
local row = 5

preserve
keep if surgery_yn==1 & hospital==1

foreach RowVar in sector region {
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)

	forvalues i = 1/`RowCount' {
		sum ster_any_obs if `RowVar'==`i'
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum disinfect_any_obs if `RowVar'==`i'
			local mean2: disp %3.1f r(mean)*100
			
			count if `RowVar'==`i'
			if r(N)!=0 local n_1= r(N) 
			
			*	Suppress output where N<5
			if `n_1' >=5 {
				putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`n_1'), left
				} 
				else {
					putexcel A`row'=("`CellContents'") B`row'=("--") C`row'=("--") D`row'=("--"), left
					}
					
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}

*	 Sterilization and disinfection equipment overall 
sum ster_any_obs
local mean1: disp %3.1f r(mean)*100
sum disinfect_any_obs 
local mean2: disp %3.1f r(mean)*100
count
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`n_1'), left

restore

*********************************************************
***   Signal functions
*********************************************************	

*   Check completeness
mdesc medservice_abx obh_ut_3mo aed_3mo medservice_assist medservice_man_plac medservice_resus medservice_cortisteroids medservice_csection if labor_delivery_yn==1 & hospital!=.
tab1 medservice_abx obh_ut_3mo aed_3mo medservice_assist medservice_man_plac medservice_resus medservice_cortisteroids medservice_csection if labor_delivery_yn==1 & hospital!=.
misstable pattern medservice_abx obh_ut_3mo aed_3mo medservice_assist medservice_man_plac medservice_resus medservice_cortisteroids medservice_csection if labor_delivery_yn==1 & hospital!=., freq
mdesc medservice_transfuse if labor_delivery_yn==1 & hospital!=. & transfusion_yn==1

*	Set up putexcel
putexcel set "PMAET_2019SDP_Analysis_$date.xlsx", sheet("Table17") modify
putexcel A1=("Table 17. Performance of emergency obstetric and neonatal signal functions"), bold underline
putexcel A2=("Among facilities offering delivery services, percentages reporting performance of indicated signal function at least once during the past three months"), italic
putexcel B3=("Percentage that provided in past three months:") F3=("Percentage that performed in past three months:") 
putexcel L3=("Percentage:"), border(bottom) 
putexcel (B3:E3), merge hcenter vcenter border(bottom) txtwrap
putexcel (F3:I3), merge hcenter vcenter border(bottom) txtwrap
putexcel B4=("Parenteral antibiotics for infections") C4=("Uterotonics to prevent or treat postpartum hemorrhage") D4=("Parenteral anticonvulsants to manage high blood pressure in pregnancy") E4=("Antenatal corticosteroids for fetal lung maturation") F4=("Instrument/ assisted vaginal delivery") G4=("Manual removal of placenta") H4=("Neonatal resuscitation") I4=("Caesarean section") J4=("Number of facilities") L4=("Blood transfusion for maternity care") M4=("Number of facilities")
putexcel A5="Type" A9="Managing authority" A13="Region" A27="Total", bold

*	Signal function by facility type, managing authority, and region
local row = 6
foreach RowVar in hospital sector region {
         
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)

	forvalues i = 1/`RowCount' {
		sum medservice_abx if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum obh_ut_3mo if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean2: disp %3.1f r(mean)*100
			
			sum aed_3mo if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean3: disp %3.1f r(mean)*100
			
			sum medservice_assist if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean4: disp %3.1f r(mean)*100
			
			sum medservice_man_plac if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean5: disp %3.1f r(mean)*100
			
			sum medservice_resus if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean6: disp %3.1f r(mean)*100
			
			sum medservice_cortisteroids if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean7: disp %3.1f r(mean)*100
			
			sum medservice_csection if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean8: disp %3.1f r(mean)*100
			
			sum medservice_transfuse if `RowVar'==`i' & transfusion_yn==1 & labor_delivery_yn==1 & hospital!=. 
			local mean9: disp %3.1f r(mean)*100
			if r(N)!=0 local n_1= r(N) 
			
			count if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			if r(N)!=0 local n_2= r(N) 
			
			if `n_1' >=5 {
				putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6') H`row'=(`mean7') I`row'=(`mean8') J`row'=(`n_2') L`row'=(`mean9') M`row'=(`n_1'), left
				}
				
			if `n_1' < 5 {
				putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6') H`row'=(`mean7') I`row'=(`mean8') J`row'=(`n_2') L`row'=("--") M`row'=("--"), left
			}
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}   
         
*	Overall signal function 
sum medservice_abx if labor_delivery_yn==1 & hospital!=.
local mean1: disp %3.1f r(mean)*100
sum obh_ut_3mo if labor_delivery_yn==1 & hospital!=.
local mean2: disp %3.1f r(mean)*100
sum aed_3mo if labor_delivery_yn==1 & hospital!=.
local mean3: disp %3.1f r(mean)*100
sum medservice_assist if labor_delivery_yn==1 & hospital!=.
local mean4: disp %3.1f r(mean)*100
sum medservice_man_plac if labor_delivery_yn==1 & hospital!=.
local mean5: disp %3.1f r(mean)*100
sum medservice_resus if labor_delivery_yn==1 & hospital!=.
local mean6: disp %3.1f r(mean)*100
sum medservice_cortisteroids if labor_delivery_yn==1 & hospital!=.
local mean7: disp %3.1f r(mean)*100
sum medservice_csection if labor_delivery_yn==1 & hospital!=.
local mean8: disp %3.1f r(mean)*100
sum medservice_transfuse if transfusion_yn==1 & labor_delivery_yn==1 & hospital!=. 
local mean9: disp %3.1f r(mean)*100
if r(N)!=0 local n_1= r(N)

count if labor_delivery_yn==1 & hospital!=.
if r(N)!=0 local n_2= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6') H`row'=(`mean7') I`row'=(`mean8') J`row'=(`n_2') L`row'=(`mean9') M`row'=(`n_1'), left

*********************************************************
***   Referral readiness
*********************************************************	

*   Check completeness
mdesc antenatal_yn labor_delivery_yn postnatal_yn surgery_yn if facility_type2!=5 
mdesc phone transport refer_form_seen refer_report refer_care_preg refer_care_labor refer_care_pp refer_care_newborn if facility_type2!=5 & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1)
tab1 phone transport refer_form_seen refer_report refer_care_preg refer_care_labor refer_care_pp refer_care_newborn if facility_type2!=5 & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1)

*   Generate variables			
*   Create dichotomous variable for whether phone/radio system available at all times during past 7 days
gen phone_yn =0 if facility_type2!=5
replace phone_yn=1 if phone==1 | phone==2 | phone==3
replace phone_yn=. if phone==. | phone==-77 | phone==-88 | phone==-99   
label variable phone_yn "Phone/radio system available at all times during past 7 days"
label define phone_yn 0 "Not available" 1 "Available at all times"
label val phone_yn phone_yn

*   Create dichotomous variable for whether facility has access to emergency transport on-site
gen transport_yn=0 if facility_type2!=5
replace transport_yn=1 if transport==1 | transport==2 | transport==3
replace transport_yn=. if transport==. | transport==-77 | transport==-88 | transport==-99   
label variable transport_yn "Access to ambulance/car on-site for emergency transport"
label define transport_yn 0 "No emergency transport on-site" 1 "Access to emergency transport on-site"
label val transport_yn transport_yn

*   Create dichotomous variable for whether referral form is available and observed
gen refer_form_obs =0 if facility_type2!=5
replace refer_form_obs=1 if refer_form_seen==1 | refer_form_seen==2 
replace refer_form_obs=. if refer_form_seen==. 
replace refer_form_obs=0 if refer_form==0
label variable refer_form_obs "Referral form available and observed on day of assessment"
label define refer_form_obs 0 "Not available/observed" 1 "Available and observed"
label val refer_form_obs refer_form_obs	

*   Generate new variable for those with don't know/no response
foreach var of varlist refer_report {
		gen `var'_recode = `var'
		replace `var'_recode=. if `var'==-77 | `var'==-88 | `var'==-99   
		label val `var'_recode yesno
	}

*   Create dichotomous variable for whether facility makes referrals
gen refer_out = 0 if facility_type2!=5
replace refer_out = 1 if refer_care_preg==1 | refer_care_labor==1 | refer_care_pp==1 | refer_care_newborn==1 
replace refer_out = . if refer_care_preg==. & refer_care_labor==. & refer_care_pp==. & refer_care_newborn==. 
replace refer_out = . if refer_care_preg==-88 & refer_care_labor==-88 & refer_care_pp==-88 & refer_care_newborn==-88
label variable refer_out "Makes referrals"
label define refer_out 0 "No" 1 "Yes"
label val refer_out refer_out

*   Check missingness
mdesc refer_out if facility_type2!=5 & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1)
mdesc phone_yn transport_yn refer_form_obs refer_report_recode  if facility_type2!=5 & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1) & refer_out==1

*   Rename
rename refer_report_recode refer_report_recode 

*	Set up putexcel
putexcel set "PMAET_2019SDP_Analysis_$date.xlsx", sheet("Table18") modify
putexcel A1=("Table 18. Referral readiness for maternal and newborn health services"), bold underline
putexcel A2=("Among facilities offering maternal and newborn services, percentages that make referrals and percentages that have referral infrastructure and systems"), italic
putexcel E3=("Among facilities that make referrals, percentage that have:")
putexcel (E3:H3), merge hcenter vcenter border(bottom) txtwrap
putexcel B4=("Provides referrals for pregnant, laboring, or postpartum women and/or newborns") C4=("Number of facilities") E4=("Communication equipment") F4=("Emergency transport") G4=("Patient referral form") H4=("Functional mechanism for recording and sharing outcomes of cases referred in and out") I4=("Number of facilities")
putexcel A5="Type" A11="Managing authority" A15="Region" A29="Total", bold

*	Referral readiness by facility type, managing authority, and region
local row = 6
foreach RowVar in facility_type2 sector region {

	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)

	forvalues i = 1/`RowCount' {
		sum refer_out if `RowVar'==`i' & facility_type2!=5 & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1)
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			if r(N)!=0 local n_1= r(N) 
						
			sum phone_yn if `RowVar'==`i' & facility_type2!=5 & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1) & refer_out==1 
			local mean2: disp %3.1f r(mean)*100
			
			sum transport_yn if `RowVar'==`i' & facility_type2!=5 & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1) & refer_out==1 
			local mean3: disp %3.1f r(mean)*100
			
			sum refer_form_obs if `RowVar'==`i' & facility_type2!=5 & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1) & refer_out==1 
			local mean4: disp %3.1f r(mean)*100
			
			sum refer_report_recode if `RowVar'==`i' & facility_type2!=5 & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1) & refer_out==1 
			local mean5: disp %3.1f r(mean)*100
			
			count if `RowVar'==`i' & facility_type2!=5 & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1) & refer_out==1 
			if r(N)!=0 local n_2= r(N) 

			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`n_1') E`row'=(`mean2') F`row'=(`mean3') G`row'=(`mean4') H`row'=(`mean5') I`row'=(`n_2'), left
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}   
         
*	Overall signal function 
sum refer_out if facility_type2!=5 & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1)
local mean1: disp %3.1f r(mean)*100
if r(N)!=0 local n_1= r(N)
sum phone_yn if facility_type2!=5 & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1) & refer_out==1
local mean2: disp %3.1f r(mean)*100
sum transport_yn if facility_type2!=5 & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1) & refer_out==1
local mean3: disp %3.1f r(mean)*100
sum refer_form_obs if facility_type2!=5 & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1) & refer_out==1
local mean4: disp %3.1f r(mean)*100
sum refer_report_recode if facility_type2!=5 & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1) & refer_out==1
local mean5: disp %3.1f r(mean)*100
count if facility_type2!=5 & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1) & refer_out==1
if r(N)!=0 local n_2= r(N)

putexcel B`row'=(`mean1') C`row'=(`n_1') E`row'=(`mean2') F`row'=(`mean3') G`row'=(`mean4') H`row'=(`mean5') I`row'=(`n_2'), left

*********************************************************
***   Maternal death review
*********************************************************	

*   Check completeness
mdesc death_report if (facility_type2==1 |  facility_type2==2 |  facility_type2==3) & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1) 
mdesc review_death if (facility_type2==1 |  facility_type2==2) & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1) 
tab1 death_report review_death if (facility_type2==1 |  facility_type2==2 |  facility_type2==3) & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1) 

*   Generate variables
*   Generate new variable for those with don't know/no response
foreach var of varlist death_report review_death {
		gen `var'_recode = `var'
		replace `var'_recode=. if `var'==-77 | `var'==-88 | `var'==-99   
		label val `var'_recode yesno
	}

*   Check missingness
mdesc death_report_recode if (facility_type2==1 |  facility_type2==2 |  facility_type2==3) & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1) 
mdesc review_death_recode if (facility_type2==1 |  facility_type2==2) & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1) 

*	Set up putexcel
putexcel set "PMAET_2019SDP_Analysis_$date.xlsx", sheet("Table19") modify
putexcel A1=("Table 19. Systems for reporting and review of maternal deaths"), bold underline
putexcel A2=("Among facilities offering maternal and newborn health services, percentages that report data on maternal deaths and review maternal deaths at facility"), italic
putexcel B3=("Functional mechanism for reporting data on maternal deaths to the MPDSR") C3=("Number of hospitals, health centers, and health posts") E3=("Maternal deaths reviewed by providers at facility") F3=("Number of hospitals and health centers")
putexcel A4="Type" A9="Managing authority" A13="Region" A27="Total", bold

*	Maternal deaths review by facility type, managing authority, and region
local row = 5
foreach RowVar in facility_type2 sector region {

	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)

	forvalues i = 1/`RowCount' {
		sum death_report_recode if `RowVar'==`i' & (facility_type2==1 | facility_type2==2 | facility_type2==3) & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1)
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			if r(N)!=0 local n_1= r(N) 
						
			sum review_death_recode if `RowVar'==`i' & (facility_type2==1 | facility_type2==2) & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1)
			local mean2: disp %3.1f r(mean)*100
			count if `RowVar'==`i' & (facility_type2==1 | facility_type2==2) & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1)
			if r(N)!=0 local n_2= r(N) 
			
			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`n_1') E`row'=(`mean2') F`row'=(`n_2'), left
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}   
 
*	Overall maternal deaths review 
sum death_report_recode if (facility_type2==1 | facility_type2==2 | facility_type2==3) & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1)
local mean1: disp %3.1f r(mean)*100
count if (facility_type2==1 | facility_type2==2 | facility_type2==3) & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1)
if r(N)!=0 local n_1= r(N)

sum review_death_recode if (facility_type2==1 | facility_type2==2) & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1)
local mean2: disp %3.1f r(mean)*100
count if (facility_type2==1 | facility_type2==2) & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1)
if r(N)!=0 local n_2= r(N)

putexcel B`row'=(`mean1') C`row'=(`n_1') E`row'=(`mean2') F`row'=(`n_2'), left
putexcel E7=("n/a") F7=("n/a")

*********************************************************
***   Routine newborn care equipment and supplies
*********************************************************	

*   Check completeness
mdesc indr_tetracycline outdr_tetracycline indr_chlorhexidine outdr_chlorhexidine indr_inj_vitk outdr_inj_vitk vax_bcg vax_opv se_scale rm_newborn proc_bfi if labor_delivery_yn==1 & facility_type2!=5
tab1 indr_tetracycline outdr_tetracycline indr_chlorhexidine outdr_chlorhexidine indr_inj_vitk outdr_inj_vitk vax_bcg vax_opv se_scale rm_newborn proc_bfi if labor_delivery_yn==1 & facility_type2!=5

*   Generate variables
*   Create dichotomous variable for whether or not medication/supplies is OBSERVED outside the delivery room on the day of the interview
foreach var of varlist outdr_tetracycline outdr_chlorhexidine outdr_inj_vitk vax_bcg vax_opv se_scale {
		gen `var'_obs =0 if labor_delivery_yn==1 & facility_type2!=5
		replace `var'_obs=1 if `var'==2
		replace `var'_obs=. if `var'==. | `var'==-77 | `var'==-88 | `var'==-99   
		label variable `var'_obs "`var' observed outside delivery room on day of interview"
		label define `var'_obs 0 "not observed" 1 "observed"
		label val `var'_obs `var'_obs
	}

*   Create dichotomous variable for whether or not medication is OBSERVED inside the delivery room on the day of the interview
foreach var of varlist indr_tetracycline indr_chlorhexidine indr_inj_vitk proc_bfi {
		gen `var'_obs =0 if labor_delivery_yn==1 & facility_type2!=5
		replace `var'_obs=1 if `var'==2
		replace `var'_obs=. if `var'==. | `var'==-77 | `var'==-88 | `var'==-99   
		label variable `var'_obs "`var' available inside delivery room on day of interview"
		label define `var'_obs 0 "not observed" 1 "observed"
		label val `var'_obs `var'_obs
	}

*   Create dichotomous variable for whether medication is observed at facility on the day of the interview
local meds "tetracycline_obs chlorhexidine_obs inj_vitk_obs"
foreach x in `meds' {
		gen `x'_obs=0 if labor_delivery_yn==1 & facility_type2!=5
		replace `x'_obs=1 if outdr_`x'==1 | indr_`x'==1
		replace `x'_obs=. if outdr_`x'==. & indr_`x'==. 
		label variable `x'_obs "`x' observed at facility on day of interview"
		label define `x'_obs 0 "not observed" 1 "observed"
		label val `x'_obs `x'_obs
	}

mdesc tetracycline_obs chlorhexidine_obs inj_vitk_obs vax_bcg_obs vax_opv_obs se_scale_obs rm_newborn proc_bfi_obs if labor_delivery_yn==1 & facility_type2!=5
misstable pattern tetracycline_obs chlorhexidine_obs inj_vitk_obs vax_bcg_obs vax_opv_obs se_scale_obs rm_newborn proc_bfi_obs if labor_delivery_yn==1 & facility_type2!=5, freq

*	Set up putexcel
putexcel set "PMAET_2019SDP_Analysis_$date.xlsx", sheet("Table20") modify
putexcel A1=("Table 20. Guidelines, equipment, commodities, and amenities for routine newborn care"), bold underline
putexcel A2=("Among facilities offering delivery services, percentages that have indicated items observed to be available in facility on the day of the survey"), italic
putexcel B4=("Tetracycline ointment") C4=("Chlorhexidine") D4=("Injectable vitamin K") E4=("BCG vaccine") F4=("Oral polio vaccine (OPV)") G4=("Infant scale") H4=("Newborn corner") I4=("Baby Friendly Initiative guidelines1") J4=("Number of facilities")
putexcel A5="Type" A9="Managing authority" A13="Region" A27="Total", bold

*	Routine newborn serivce and supplies by facility type, managing authority, and region
local row = 6
foreach RowVar in hospital sector region {
           
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)

	forvalues i = 1/`RowCount' {
		sum tetracycline_obs if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum chlorhexidine_obs if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean2: disp %3.1f r(mean)*100
			
			sum inj_vitk_obs if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean3: disp %3.1f r(mean)*100
			
			sum vax_bcg_obs if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean4: disp %3.1f r(mean)*100
			
			sum vax_opv_obs if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean5: disp %3.1f r(mean)*100
			
			sum se_scale_obs if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean6: disp %3.1f r(mean)*100
			
			sum rm_newborn if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean7: disp %3.1f r(mean)*100
			
			sum proc_bfi_obs if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			local mean8: disp %3.1f r(mean)*100

			count if `RowVar'==`i' & labor_delivery_yn==1 & hospital!=.
			if r(N)!=0 local n_1= r(N) 

			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6') H`row'=(`mean7') I`row'=(`mean8') J`row'=(`n_1'), left
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}   
        
*	Overall rountine newborn sevrice and supplies 
sum tetracycline_obs if labor_delivery_yn==1 & hospital!=.
local mean1: disp %3.1f r(mean)*100
sum chlorhexidine_obs if labor_delivery_yn==1 & hospital!=.
local mean2: disp %3.1f r(mean)*100
sum inj_vitk_obs if labor_delivery_yn==1 & hospital!=.
local mean3: disp %3.1f r(mean)*100
sum vax_bcg_obs if labor_delivery_yn==1 & hospital!=.
local mean4: disp %3.1f r(mean)*100
sum vax_opv_obs if labor_delivery_yn==1 & hospital!=.
local mean5: disp %3.1f r(mean)*100
sum se_scale_obs if labor_delivery_yn==1 & hospital!=.
local mean6: disp %3.1f r(mean)*100
sum rm_newborn if labor_delivery_yn==1 & hospital!=.
local mean7: disp %3.1f r(mean)*100
sum proc_bfi_obs if labor_delivery_yn==1 & hospital!=.
local mean8: disp %3.1f r(mean)*100

count if labor_delivery_yn==1 & hospital!=.
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6') H`row'=(`mean7') I`row'=(`mean8') J`row'=(`n_1'), left

*********************************************************
***   Availablity of family planning services
*********************************************************	

*   Check completeness
mdesc fp_offered_yn 
mdesc adolescents adolescents_counseled adolescents_provided adolescents_prescribed if fp_offered_yn==1
tab1 adolescents adolescents_counseled adolescents_provided adolescents_prescribed if fp_offered_yn==1
count if adolescents=="-99" 

*   Generate new variable for those with don't know/no response
foreach var of varlist adolescents_counseled adolescents_provided adolescents_prescribed {
		gen `var'_r = `var'
		replace `var'_r=. if adolescents=="-99"   
		label val `var'_r yesno
	}

*   Missingness
mdesc adolescents_counseled_r adolescents_provided_r adolescents_prescribed_r if fp_offered_yn==1
misstable pattern adolescents_counseled_r adolescents_provided_r adolescents_prescribed_r if fp_offered_yn==1, freq

*	Set up putexcel
putexcel set "PMAET_2019SDP_Analysis_$date.xlsx", sheet("Table21") modify
putexcel A1=("Table 21. Availability of family planning services"), bold underline
putexcel A2=("Percentage of SDPs offering family planning services, and percentage offering indicated family planning services to unmarried adolescents aged 10-19"), italic
putexcel B3=("Among all SDPs") E3=("Among SDPs offering family planning, percentages that offer:"), border(bottom)
putexcel (E3:G3), merge hcenter vcenter border(bottom) txtwrap
putexcel B4=("Family planning") C4=("Number of SDPs") E4=("Counseling to unmarried adolescents aged 10-19") F4=("Provision of contraceptive methods to unmarried adolescents aged 10-19") G4=("Prescription/ referrals to unmarried adolescents aged 10-19") H4=("Number of SDPs")
putexcel A5="Type" A12="Managing authority" A16="Region" A30="Total", bold

*	Family planning servie by facility type, managing authority, and region
local row = 6
foreach RowVar in facility_type2 sector region {

	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)

	forvalues i = 1/`RowCount' {
		sum fp_offered_yn if `RowVar'==`i' 
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			if r(N)!=0 local n_1= r(N) 
			
			sum adolescents_counseled_r if `RowVar'==`i' & fp_offered_yn==1
			local mean2: disp %3.1f r(mean)*100
			
			sum adolescents_provided_r if `RowVar'==`i' & fp_offered_yn==1
			local mean3: disp %3.1f r(mean)*100
			
			sum adolescents_prescribed_r if `RowVar'==`i' & fp_offered_yn==1
			local mean4: disp %3.1f r(mean)*100

			count if `RowVar'==`i' & fp_offered_yn==1
			if r(N)!=0 local n_2= r(N) 

			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`n_1') E`row'=(`mean2') F`row'=(`mean3') G`row'=(`mean4') H`row'=(`n_2'), left
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}   
        
*	Family planning servie overall
sum fp_offered_yn
local mean1: disp %3.1f r(mean)*100
if r(N)!=0 local n_1= r(N)

sum adolescents_counseled_r if fp_offered_yn==1
local mean2: disp %3.1f r(mean)*100
sum adolescents_provided_r if fp_offered_yn==1
local mean3: disp %3.1f r(mean)*100
sum adolescents_prescribed_r if fp_offered_yn==1
local mean4: disp %3.1f r(mean)*100

count if fp_offered_yn==1
if r(N)!=0 local n_2= r(N)

putexcel B`row'=(`mean1') C`row'=(`n_1') E`row'=(`mean2') F`row'=(`mean3') G`row'=(`mean4') H`row'=(`n_2'), left

*********************************************************
***   Provision of contraceptive methods
*********************************************************	

*   Check completeness
mdesc provided_implants provided_iud provided_injectables provided_pills  if fp_offered_yn==1 
tab1 provided_implants provided_iud provided_injectables provided_pills  if fp_offered_yn==1 

mdesc visits_implants_total visits_iud_total visits_injectables_total visits_pill_total visits_male_condoms_total if fp_offered_yn==1 & facility_type2!=5
tab1 visits_implants_total visits_iud_total visits_injectables_total visits_pill_total visits_male_condoms_total if fp_offered_yn==1 & facility_type2!=5

*   Rename
rename visits_implants_total implants_tot
rename visits_pill_total pills_tot
rename visits_injectables_total injectables_tot
rename visits_male_condoms_total male_condoms_tot
rename visits_iud_total iud_tot
rename visits_female_condoms_total female_condoms_tot
rename visits_ec_total ec_tot

*   Generate variables
local methods "implants iud injectables pills ec male_condoms female_condoms"
foreach x in `methods'  {
		gen `x'_1mo = 0 if provided_`x'==0
		replace `x'_1mo = 0 if `x'_tot==0
		replace `x'_1mo = 1 if `x'_tot>0 & `x'_tot!=.
		replace `x'_1mo = . if `x'_tot==-77 | `x'_tot==-88 | `x'_tot==-99
		label val `x'_1mo yesno
		label var `x'_1mo "Provided `var' in last 1 month"
	}

*   Check missingness
mdesc implants_1mo iud_1mo injectables_1mo pills_1mo if fp_offered_yn==1 & facility_type2!=5
misstable pattern implants_1mo iud_1mo injectables_1mo pills_1mo if fp_offered_yn==1 & facility_type2!=5 , freq
ta male_condoms_1mo  provided_male_condoms if fp_offered_yn==1 & facility_type2!=5, m

*	Set up putexcel
putexcel set "PMAET_2019SDP_Analysis_$date.xlsx", sheet("Table22") modify
putexcel A1=("Table 22. Provision of contraceptive methods in previous month"), bold underline
putexcel A2=("Among health facilities offering family planning services, percentages which provided indicated method in previous month to at least one client"), italic
putexcel B3=("Implants") C3=("IUDs") D3=("Injectables") E3=("Pills") F3=("Number of facilities")
putexcel A4="Type" A10="Managing authority" A14="Region" A28="Total", bold

*	Provision of contraceptive methodsby facility type, managing authority, and region
local row = 5
foreach RowVar in facility_type2 sector region {

	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)

	forvalues i = 1/`RowCount' {
		sum implants_1mo if `RowVar'==`i' & fp_offered_yn==1 & facility_type2!=5
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum iud_1mo if `RowVar'==`i' & fp_offered_yn==1 & facility_type2!=5
			local mean2: disp %3.1f r(mean)*100
			
			sum injectables_1mo if `RowVar'==`i' & fp_offered_yn==1 & facility_type2!=5
			local mean3: disp %3.1f r(mean)*100
			
			sum pills_1mo if `RowVar'==`i' & fp_offered_yn==1 & facility_type2!=5
			local mean4: disp %3.1f r(mean)*100

			count if `RowVar'==`i' & fp_offered_yn==1 & facility_type2!=5
			if r(N)!=0 local n_1= r(N) 

			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`n_1'), left
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}   
        
*	Provision of contraceptive methods overall
sum implants_1mo if fp_offered_yn==1 & facility_type2!=5
local mean1: disp %3.1f r(mean)*100
sum iud_1mo if fp_offered_yn==1 & facility_type2!=5
local mean2: disp %3.1f r(mean)*100
sum injectables_1mo if fp_offered_yn==1 & facility_type2!=5
local mean3: disp %3.1f r(mean)*100
sum pills_1mo if fp_offered_yn==1 & facility_type2!=5
local mean4: disp %3.1f r(mean)*100

count if fp_offered_yn==1 & facility_type2!=5
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`n_1'), left

*********************************************************
***   Methods mix
*********************************************************	

*   Check missingness
mdesc implants_1mo iud_1mo injectables_1mo pills_1mo if fp_offered_yn==1 & facility_type2!=5
mdesc provided_male_condoms if fp_offered_yn==1 & facility_type2!=5

*   Generate summary variables
gen methods_5 = 0 if fp_offered_yn==1 & (facility_type2==1 | facility_type2==2 | facility_type2==4)
replace methods_5 = 1 if implants_1mo==1 & iud_1mo==1 & injectables_1mo==1 & pills_1mo==1 & provided_male_condoms==1
replace methods_5 = . if (implants_1mo==. | iud_1mo==. | injectables_1mo==. | pills_1mo==. | provided_male_condoms==.)
label val methods_5 yesno
label var methods_5 "Provided 2 long-acting and 3 short-term methods in last 1 month"	
ta methods_5  if fp_offered_yn==1 & (facility_type2==1 | facility_type2==2 | facility_type2==4), m

gen methods_4 = 0 if fp_offered_yn==1 & (facility_type2==3)
replace methods_4 = 1 if implants_1mo==1 & injectables_1mo==1 & pills_1mo==1 & provided_male_condoms==1
replace methods_4 = . if (implants_1mo==. | injectables_1mo==. | pills_1mo==. | provided_male_condoms==.)
label val methods_4 yesno
label var methods_4 "Provided 4 methods in last 1 month"	
ta methods_4  if fp_offered_yn==1 & (facility_type2==3), m

*	Set up putexcel
putexcel set "PMAET_2019SDP_Analysis_$date.xlsx", sheet("Table23") modify
putexcel A1=("Table 23. Provision of a mix of contraceptive methods in previous month"), bold underline
putexcel A2=("Among health facilities offering family planning services, percentages which provided a mix of methods in previous month"), italic

putexcel B4=("Among hospitals and health centers/clinics, percentages providing two long-acting and three short-acting family planning method") C4=("Number of facilities") E4=("Among health posts, percentages providing at least four family planning methods") F4=("Number of facilities")
putexcel A5="Type" A11="Managing authority" A15="Region" A29="Total", bold

*	Among hospitals and health centers/clinics, percentages providing two long-acting and three short-acting family planning methods, by facility type, managing authority, and region 

preserve
keep if fp_offered_yn==1

local row = 6
foreach RowVar in facility_type2 sector region {
               
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
      
	forvalues i = 1/`RowCount' {
		
		if "`RowVar'"=="facility_type2" &  `i'==3 {
			putexcel A`row'=("Health post") B`row'= ("n/a") C`row'= ("n/a")
			local row = `row' + 1
			}
		else {
			sum methods_5 if `RowVar'==`i' & (facility_type2==1 | facility_type2==2 | facility_type2==4)
				
			if r(N)!=0 {
			
				local RowValueLabelNum = word("`RowLevels'", `i')
				local CellContents : label `RowValueLabel' `RowValueLabelNum'
				local mean1: disp %3.1f r(mean)*100

				count if `RowVar'==`i' & (facility_type2==1 | facility_type2==2 | facility_type2==4)
				if r(N)!=0 local n_1= r(N) 

				if `n_1' >= 5 {
					putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`n_1'), left
					}
				if `n_1' < 5 {
					putexcel A`row'=("`CellContents'") B`row'=("--") C`row'=("--"), left
					}	
			local row = `row' + 1
				}
			}
				
		}
	local row=`row'+2
	}   

*	Among hospitals and health centers/clinics, percentages providing two long-acting and three short-acting family planning methods overll 
sum methods_5 if (facility_type2==1 | facility_type2==2 | facility_type2==4)
local mean1: disp %3.1f r(mean)*100
count if (facility_type2==1 | facility_type2==2 | facility_type2==4)
if r(N)!=0 local n_1= r(N)

if `n_1' >= 5 {
	putexcel B`row'=(`mean1') C`row'=(`n_1'), left
	}
if `n_1' < 5 {
	putexcel B`row'=("--") C`row'=("--"), left
	}
	
*	Among health posts, percentages providing at least four family planning methods, by region
local row = 6
foreach RowVar in facility_type2 sector region {
               
	tab `RowVar'
	local RowCount=`r(r)'
      
	forvalues i = 1/`RowCount' {
		
		if ("`RowVar'"=="facility_type2" & (`i'<=2| `i'==4)) | ("`RowVar'"=="sector" & `i'==2) | ("`RowVar'"=="region" & `i'==10) {
			putexcel E`row'=("n/a") F`row'=("n/a")	
			local row = `row' + 1	
			}
		else {
			sum methods_4 if `RowVar'==`i' & facility_type2==3
			
			if r(N)!=0 {
			
				local mean1: disp %3.1f r(mean)*100
			
				count if `RowVar'==`i' & facility_type2==3
				if r(N)!=0 local n_1= r(N) 

				if `n_1' >= 5 {
					putexcel E`row'=(`mean1') F`row'=(`n_1'), left
					}
				if `n_1' < 5 {
					putexcel E`row'=("--") F`row'=("--"), left
					}
				local row = `row' + 1
				}
			}
		}
	local row=`row'+2
	}   
	
*	Among health posts, percentages providing at least four family planning methods (overall)
sum methods_4 if facility_type2==3 
local mean1: disp %3.1f r(mean)*100

count if facility_type2==3
if r(N)!=0 local n_1= r(N)	

if `n_1' >= 5 {
	putexcel E`row'=(`mean1') F`row'=(`n_1'), left
	}
if `n_1' < 5 {
	putexcel E`row'=("--") F`row'=("--"), left
	}
	
restore 

*********************************************************
***   Availability of methods
*********************************************************	

*   Check completeness
mdesc stock_implants stock_iud stock_injectables stock_pills stock_ec stock_male_condoms stock_female_condoms if fp_offered_yn==1
mdesc provided_implants provided_iud provided_injectables provided_pills provided_ec provided_male_condoms provided_female_condoms if fp_offered_yn==1

*   Generate variables
local methods "implants iud injectables pills ec male_condoms female_condoms"
foreach x in `methods'  {
		gen `x'_obs = 0 if provided_`x'==0 | stock_`x'==0 | stock_`x'==1 
		replace `x'_obs = 1 if stock_`x'==2
		replace `x'_obs = . if stock_`x'==-77 | stock_`x'==-88 | stock_`x'==-99
		replace `x'_obs = . if provided_`x'==-77 | provided_`x'==-88 | provided_`x'==-99
		label val `x'_obs yesno
		label var `x'_obs "Observed `var' on day of assessment"
	}	

*   Check missingness
mdesc implants_obs iud_obs injectables_obs pills_obs ec_obs male_condoms_obs female_condoms_obs	if fp_offered_yn==1
tab1 implants_obs iud_obs injectables_obs pills_obs ec_obs male_condoms_obs female_condoms_obs	if fp_offered_yn==1
	
*	Set up putexcel
putexcel set "PMAET_2019SDP_Analysis_$date.xlsx", sheet("Table24") modify
putexcel A1=("Table 24. Availability of contraceptive methods"), bold underline
putexcel A2=("Among facilities offering family planning services, percentages where the indicated contraceptive method was observed to be available on the day of the survey"), italic
putexcel B4=("Implants") C4=("IUD") D4=("Injectables") E4=("Pills") F4=("Emergency contraception") G4=("Male condoms") H4=("Female condoms") I4=("Number of facilities")
putexcel A5="Type" A12="Managing authority" A16="Region" A30="Total", bold

*	Availability of methods by facility type, managing authority, and region
local row = 6
foreach RowVar in facility_type2 sector region {
           
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
      
	forvalues i = 1/`RowCount' {
		sum implants_obs if `RowVar'==`i' & fp_offered_yn==1
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum iud_obs if `RowVar'==`i' & fp_offered_yn==1
			local mean2: disp %3.1f r(mean)*100
			
			sum injectables_obs if `RowVar'==`i' & fp_offered_yn==1
			local mean3: disp %3.1f r(mean)*100
			
			sum pills_obs if `RowVar'==`i' & fp_offered_yn==1
			local mean4: disp %3.1f r(mean)*100
			
			sum ec_obs if `RowVar'==`i' & fp_offered_yn==1
			local mean5: disp %3.1f r(mean)*100
			
			sum male_condoms_obs if `RowVar'==`i' & fp_offered_yn==1
			local mean6: disp %3.1f r(mean)*100
			
			sum female_condoms_obs if `RowVar'==`i' & fp_offered_yn==1
			local mean7: disp %3.1f r(mean)*100

			count if `RowVar'==`i' & fp_offered_yn==1
			if r(N)!=0 local n_1= r(N) 

			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6') H`row'=(`mean7') I`row'=(`n_1'), left
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}   
        
*	Availability of methods overall
sum implants_obs if fp_offered_yn==1
local mean1: disp %3.1f r(mean)*100
sum iud_obs if fp_offered_yn==1
local mean2: disp %3.1f r(mean)*100
sum injectables_obs if fp_offered_yn==1
local mean3: disp %3.1f r(mean)*100
sum pills_obs if fp_offered_yn==1
local mean4: disp %3.1f r(mean)*100
sum ec_obs if fp_offered_yn==1
local mean5: disp %3.1f r(mean)*100
sum male_condoms_obs if fp_offered_yn==1
local mean6: disp %3.1f r(mean)*100
sum female_condoms_obs if fp_offered_yn==1
local mean7: disp %3.1f r(mean)*100

count if fp_offered_yn==1
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6') H`row'=(`mean7') I`row'=(`n_1'), left
putexcel B10=("n/a") C10=("n/a")

*********************************************************
***   Implant and IUD services
*********************************************************	

*   Check completeness
mdesc onsite_impl_ins onsite_impl_rm onsite_impl_rm_nonpal offsite_impl_know if provided_implants==1 & (stock_implants==1 | stock_implants==2)
tab1 onsite_impl_ins onsite_impl_rm onsite_impl_rm_nonpal offsite_impl_know if provided_implants==1 & (stock_implants==1 | stock_implants==2)
mdesc iud_remove if provided_iud==1
tab1 iud_remove if provided_iud==1

*   Check ability to remove standard implants vs. non-palpable implants
ta onsite_impl_rm_nonpal onsite_impl_rm if provided_implants==1 & (stock_implants==1 | stock_implants==2), m
*   Recode to "yes" for standard removal if non-palpable removal is "yes"
replace onsite_impl_rm =1 if onsite_impl_rm_nonpal==1
ta onsite_impl_rm_nonpal onsite_impl_rm if provided_implants==1 & (stock_implants==1 | stock_implants==2), m

*   Generate non-palpable implant removal categorical variable
gen impl_deep_cat = 0 if onsite_impl_rm_nonpal==0 & offsite_impl_know==0
replace impl_deep_cat = 1 if onsite_impl_rm_nonpal==1
replace impl_deep_cat = 2 if offsite_impl_know==1
replace impl_deep_cat = . if offsite_impl_know==-88
label define impl_deep_cat 0 "Neither" 1 "On-site removal" 2 "Referral to off-site removal"
label val impl_deep_cat impl_deep_cat
label var impl_deep_cat "Removal of non-palpable implant"
ta onsite_impl_rm_nonpal offsite_impl_know if provided_implants==1 & (stock_implants==1 | stock_implants==2), m
ta impl_deep_cat if provided_implants==1 & (stock_implants==1 | stock_implants==2), m

*   Recode referral to off-site removal to change denominator & create mutually exclusive category
gen offsite_impl_know_recode = 1 if offsite_impl_know==1
replace offsite_impl_know_recode = 0 if offsite_impl_know==0
replace offsite_impl_know_recode = 0 if onsite_impl_rm_nonpal==1 
replace offsite_impl_know_recode = . if offsite_impl_know==-88
label val offsite_impl_know_recode yesno
label var offsite_impl_know_recode "Referral to off-site removal of non-palpable implant"
ta offsite_impl_know_recode impl_deep_cat if provided_implants==1 & (stock_implants==1 | stock_implants==2), m
ta offsite_impl_know_recode offsite_impl_know if provided_implants==1 & (stock_implants==1 | stock_implants==2), m

*   Generate neither variable (does not remove nor aware of where to refer) 
gen impl_deep_neither = 1 if onsite_impl_rm_nonpal==0 & offsite_impl_know==0
replace impl_deep_neither= 0 if onsite_impl_rm_nonpal==1 | offsite_impl_know==1
replace impl_deep_neither = . if offsite_impl_know==-88
label val impl_deep_neither yesno
label var impl_deep_neither "Neither removes non-palpable implants nor refers"
ta impl_deep_neither impl_deep_cat if provided_implants==1 & (stock_implants==1 | stock_implants==2), m

*	Set up putexcel
putexcel set "PMAET_2019SDP_Analysis_$date.xlsx", sheet("Table25") modify
putexcel A1=("Table 25. Provision of implant and IUD services"), bold underline
putexcel B2=("Among SDPs that provide implants and have implants in stock, percentages with:") I2=("Among SDPs that provide IUDs, percentages that have:"), border(bottom)
putexcel B3=("Standard implants (palpable)") D3=("Non-palpable implants") I3=("IUDs") , bold border(bottom)
putexcel (B2:F2), merge hcenter txtwrap border(bottom)
putexcel (B3:C3), merge hcenter txtwrap border(bottom)
putexcel (D3:F3), merge hcenter txtwrap border(bottom)

putexcel B4=("Ability to insert an implant on day of interview") C4=("Ability to remove an implant on day of interview") D4=("Ability to remove non-palpable implants on day of interview") E4=("Awareness of where to refer for off-site removal of non-palpable implants") F4=("No ability to remove non-palpable implants nor awareness of where to refer") G4=("Number of SDPs") I4=("Trained personnel to remove IUDs") J4=("Number of SDPs")
putexcel A5="Type" A11="Managing authority" A15="Region" A29="Total", bold

*	Implant and IUD services by facility type, managing authority, and region
local row = 6
foreach RowVar in facility_type2 sector region {
           
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
      
	forvalues i = 1/`RowCount' {
		sum onsite_impl_ins if `RowVar'==`i' & provided_implants==1 & (stock_implants==1 | stock_implants==2)
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum onsite_impl_rm if `RowVar'==`i' & provided_implants==1 & (stock_implants==1 | stock_implants==2)
			local mean2: disp %3.1f r(mean)*100
			
			sum onsite_impl_rm_nonpal if `RowVar'==`i' & provided_implants==1 & (stock_implants==1 | stock_implants==2)
			local mean3: disp %3.1f r(mean)*100
			
			sum offsite_impl_know_recode if `RowVar'==`i' & provided_implants==1 & (stock_implants==1 | stock_implants==2)
			local mean4: disp %3.1f r(mean)*100
			
			sum impl_deep_neither if `RowVar'==`i' & provided_implants==1 & (stock_implants==1 | stock_implants==2)
			local mean5: disp %3.1f r(mean)*100
			
			sum iud_remove if `RowVar'==`i' & provided_iud==1
			local mean6: disp %3.1f r(mean)*100

			count if `RowVar'==`i' & provided_implants==1 & (stock_implants==1 | stock_implants==2)
			if r(N)!=0 local n_1= r(N) 
			count if `RowVar'==`i' & provided_iud==1
			if r(N)!=0 local n_2= r(N) 

			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`n_1') I`row'=(`mean6') J`row'=(`n_2'), left
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}   
      
*	Implant and IUD services overall
sum onsite_impl_ins if provided_implants==1 & (stock_implants==1 | stock_implants==2)
local mean1: disp %3.1f r(mean)*100
sum onsite_impl_rm if provided_implants==1 & (stock_implants==1 | stock_implants==2)
local mean2: disp %3.1f r(mean)*100
sum onsite_impl_rm_nonpal if provided_implants==1 & (stock_implants==1 | stock_implants==2)
local mean3: disp %3.1f r(mean)*100
sum offsite_impl_know_recode if provided_implants==1 & (stock_implants==1 | stock_implants==2)
local mean4: disp %3.1f r(mean)*100
sum impl_deep_neither if provided_implants==1 & (stock_implants==1 | stock_implants==2)
local mean5: disp %3.1f r(mean)*100
sum iud_remove if provided_iud==1
local mean6: disp %3.1f r(mean)*100

count if provided_implants==1 & (stock_implants==1 | stock_implants==2)
if r(N)!=0 local n_1= r(N)
count if provided_iud==1
if r(N)!=0 local n_2= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`n_1') I`row'=(`mean6') J`row'=(`n_2'), left

*********************************************************
***   Availability of SA & PAC
*********************************************************	

*   Check completeness
mdesc abt_provide_yn postabortion_yn if (facility_type2==1 | facility_type2==2 | facility_type2==4)
tab1 abt_provide_yn postabortion_yn if (facility_type2==1 | facility_type2==2 | facility_type2==4)
mdesc abt_couns abt_refer
bys facility_type2: tab1 abt_couns abt_refer

*	Set up putexcel
putexcel set "PMAET_2019SDP_Analysis_$date.xlsx", sheet("Table26") modify
putexcel A1=("Table 26. Availability of safe abortion and post-abortion care"), bold underline
putexcel B3=("Among health facilities, percentages that offer:") F3=("Among hospitals, health centers, and clinics, percentages that offer:"), border(bottom)
putexcel (B3:C3), merge hcenter txtwrap border(bottom)
putexcel (F3:G3), merge hcenter txtwrap border(bottom)

putexcel B4=("Counseling on safe abortion care") C4=("Referals for safe abortion care") D4=("Number of facilities") F4=("Safe abortion care") G4=("Postabortion care") H4=("Number of facilities") 
putexcel A5="Type" A11="Managing authority" A15="Region" A29="Total", bold

*	Availability of SA & PAC by facility type, managing authority, and region
local row = 6
foreach RowVar in facility_type2 sector region {
           
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
      
	forvalues i = 1/`RowCount' {
		sum abt_couns if `RowVar'==`i' & facility_type2!=5
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum abt_refer if `RowVar'==`i' & facility_type2!=5
			local mean2: disp %3.1f r(mean)*100
			
			sum abt_provide_yn if `RowVar'==`i' & (facility_type2==1 | facility_type2==2 | facility_type2==4)
			local mean3: disp %3.1f r(mean)*100
			
			sum postabortion_yn if `RowVar'==`i' & (facility_type2==1 | facility_type2==2 | facility_type2==4)
			local mean4: disp %3.1f r(mean)*100

			count if `RowVar'==`i' & facility_type2!=5
			if r(N)!=0 local n_1= r(N) 
			count if `RowVar'==`i' & (facility_type2==1 | facility_type2==2 | facility_type2==4)
			if r(N)!=0 local n_2= r(N) 

			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`n_1') F`row'=(`mean3') G`row'=(`mean4') H`row'=(`n_2'), left
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}   
      
*	Availability of SA & PAC overall
sum abt_couns if facility_type2!=5
local mean1: disp %3.1f r(mean)*100
sum abt_refer if facility_type2!=5
local mean2: disp %3.1f r(mean)*100
sum abt_provide_yn if (facility_type2==1 | facility_type2==2 | facility_type2==4)
local mean3: disp %3.1f r(mean)*100
sum postabortion_yn if (facility_type2==1 | facility_type2==2 | facility_type2==4)
local mean4: disp %3.1f r(mean)*100

count if facility_type2!=5
if r(N)!=0 local n_1= r(N)
count if (facility_type2==1 | facility_type2==2 | facility_type2==4)
if r(N)!=0 local n_2= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`n_1') F`row'=(`mean3') G`row'=(`mean4') H`row'=(`n_2'), left
putexcel F8=("n/a") G8=("n/a") H8=("n/a")

*********************************************************
***   Medicines and equipment for safe abortion and PAC
*********************************************************	

*   Check completeness
mdesc miso_obs mife_obs se_mva_obs se_kit_dc_obs if abt_provide_yn==1 & (facility_type2==1 | facility_type2==2)
misstable pattern miso_obs mife_obs se_mva_obs se_kit_dc_obs if abt_provide_yn==1 & (facility_type2==1 | facility_type2==2), freq

*	Set up putexcel
putexcel set "PMAET_2019SDP_Analysis_$date.xlsx", sheet("Table27") modify
putexcel A1=("Table 27. Medicines and equipment for safe abortion and postabortion care"), bold underline
putexcel A2=("Among hospitals and health centers that offer safe abortion care, percentages with indicated medicines and equipment observed on the day of the survey"), italic
putexcel B4=("Misoprostol") C4=("Mifepristone") D4=("Manual vacuum aspirator (MVA) and cannula") E4=("Dilatation and curettage (D&C) kit") F4=("Number of facilities") 
putexcel A5="Type" A9="Managing authority" A13="Region" A27="Total", bold

*	Medicines and equipment SAC & PAC by facility type, managing authority, and region
local row = 6
foreach RowVar in facility_type2 sector region {
           
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
      
	forvalues i = 1/`RowCount' {
		sum miso_obs if `RowVar'==`i' & abt_provide_yn==1 & (facility_type2==1 | facility_type2==2)
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum mife_obs if `RowVar'==`i' & abt_provide_yn==1 & (facility_type2==1 | facility_type2==2)
			local mean2: disp %3.1f r(mean)*100
			
			sum se_mva_obs if `RowVar'==`i' & abt_provide_yn==1 & (facility_type2==1 | facility_type2==2)
			local mean3: disp %3.1f r(mean)*100
			
			sum se_kit_dc_obs if `RowVar'==`i' & abt_provide_yn==1 & (facility_type2==1 | facility_type2==2)
			local mean4: disp %3.1f r(mean)*100

			count if `RowVar'==`i' & abt_provide_yn==1 & (facility_type2==1 | facility_type2==2)
			if r(N)!=0 local n_1= r(N) 
			
			if `n_1' > 5 {
				putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`n_1'), left
				}
				else {
					putexcel A`row'=("`CellContents'") B`row'=("--") C`row'=("--") D`row'=("--") E`row'=("--") F`row'=("--"), left
					}
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}   
      
*	Medicines and equipment SAC & PAC overall
sum miso_obs if abt_provide_yn==1 & (facility_type2==1 | facility_type2==2)
local mean1: disp %3.1f r(mean)*100
sum mife_obs if abt_provide_yn==1 & (facility_type2==1 | facility_type2==2)
local mean2: disp %3.1f r(mean)*100
sum se_mva_obs if abt_provide_yn==1 & (facility_type2==1 | facility_type2==2)
local mean3: disp %3.1f r(mean)*100
sum se_kit_dc_obs if abt_provide_yn==1 & (facility_type2==1 | facility_type2==2)
local mean4: disp %3.1f r(mean)*100

count if abt_provide_yn==1 & (facility_type2==1 | facility_type2==2)
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`n_1'), left

*********************************************************
***   Performance of SAC functions
*********************************************************	

*   Check completeness
mdesc abt_mva_1mo abt_dc_1mo abt_ec_1mo abt_meds_1mo if abt_provide_yn==1 
tab1 abt_mva_1mo abt_dc_1mo abt_ec_1mo abt_meds_1mo if abt_provide_yn==1 

*   Recode those with don't know/no response
foreach var of varlist abt_mva_1mo abt_dc_1mo abt_ec_1mo abt_meds_1mo  {
		replace `var'=. if `var'==-77 | `var'==-88 | `var'==-99   
	}

*   Check missing
mdesc abt_mva_1mo abt_dc_1mo abt_ec_1mo abt_meds_1mo if abt_provide_yn==1 	
misstable pattern abt_mva_1mo abt_dc_1mo abt_ec_1mo abt_meds_1mo  if abt_provide_yn==1, freq

*	Set up putexcel
putexcel set "PMAET_2019SDP_Analysis_$date.xlsx", sheet("Table28") modify
putexcel A1=("Table 28. Provision of safe abortion care"), bold underline
putexcel A2=("Among health facilities that offer safe abortion care, percentages that performed the indicated functions in the past month"), italic
putexcel B4=("Manual Vacuum Aspiration (MVA)") C4=("Dilation and curettage (D&C)") D4=("Dilation and evacuation (D&E)") E4=("Medical abortion (misoprostol, mifepristone)") F4=("Number of facilities") 
putexcel A5="Type" A10="Managing authority" A14="Region" A28="Total", bold
   
*	Provision of safe abortion care by facility type, managing authority, and region
local row = 6
foreach RowVar in facility_type2 sector region {
           
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
      
	forvalues i = 1/`RowCount' {
		sum abt_mva_1mo if `RowVar'==`i' & abt_provide_yn==1
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum abt_dc_1mo if `RowVar'==`i' & abt_provide_yn==1
			local mean2: disp %3.1f r(mean)*100
			
			sum abt_ec_1mo if `RowVar'==`i' & abt_provide_yn==1
			local mean3: disp %3.1f r(mean)*100
			
			sum abt_meds_1mo if `RowVar'==`i' & abt_provide_yn==1
			local mean4: disp %3.1f r(mean)*100

			count if `RowVar'==`i' & abt_provide_yn==1
			if r(N)!=0 local n_1= r(N) 
			
			if `n_1' > 5 {
				putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`n_1'), left
				}
				else {
					putexcel A`row'=("`CellContents'") B`row'=("--") C`row'=("--") D`row'=("--") E`row'=("--") F`row'=("--"), left
					}
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}   
      
*	Provision of safe abortion care overall
sum abt_mva_1mo if abt_provide_yn==1
local mean1: disp %3.1f r(mean)*100
sum abt_dc_1mo if abt_provide_yn==1 
local mean2: disp %3.1f r(mean)*100
sum abt_ec_1mo if abt_provide_yn==1 
local mean3: disp %3.1f r(mean)*100
sum abt_meds_1mo if abt_provide_yn==1
local mean4: disp %3.1f r(mean)*100

count if abt_provide_yn==1
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`n_1'), left

*********************************************************
***   Availability of child health services
*********************************************************	

*   Check completeness
mdesc infantcare_yn immunization_yn lab_yn if facility_type2!=5
tab1 infantcare_yn immunization_yn lab_yn if facility_type2!=5

*   Generate new variable for those with don't know/no response
foreach var of varlist infantcare_yn {
		replace `var'=. if `var'==-77 | `var'==-88 | `var'==-99   
	}

*   Check missingness
mdesc infantcare_yn immunization_yn lab_yn if facility_type2!=5
misstable pattern infantcare_yn immunization_yn lab_yn if facility_type2!=5, freq

*	Set up putexcel
putexcel set "PMAET_2019SDP_Analysis_$date.xlsx", sheet("Table29") modify
putexcel A1=("Table 29. Availability of child health services"), bold underline
putexcel A2=("Percentages of health facilities that offer indicated services"), italic
putexcel B3=("Sick child care") C3=("Immunization") D3=("Laboratory testing") E3=("Number of facilities") 
putexcel A5="Type" A11="Managing authority" A15="Region" A29="Total", bold
   
*	Availability of child health services by facility type, managing authority, and region
local row = 6
foreach RowVar in facility_type2 sector region {
           
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
      
	forvalues i = 1/`RowCount' {
		sum infantcare_yn if `RowVar'==`i' & facility_type2!=5
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum immunization_yn if `RowVar'==`i' & facility_type2!=5
			local mean2: disp %3.1f r(mean)*100
			
			sum lab_yn if `RowVar'==`i' & facility_type2!=5
			local mean3: disp %3.1f r(mean)*100

			count if `RowVar'==`i'
			if r(N)!=0 local n_1= r(N) 
			
			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`n_1'), left

			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}   
      
*	Availability of child health services overall
sum infantcare_yn if facility_type2!=5
local mean1: disp %3.1f r(mean)*100
sum immunization_yn if facility_type2!=5
local mean2: disp %3.1f r(mean)*100
sum lab_yn if facility_type2!=5
local mean3: disp %3.1f r(mean)*100

count if facility_type2!=5
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`n_1'), left

*********************************************************
***   Availability of basic child vaccines
*********************************************************	

*   Check completeness
mdesc vax_prv vax_opv vax_measles vax_bcg vax_ipv vax_pcv vax_rota if immunization_yn==1
tab1 vax_prv vax_opv vax_measles vax_bcg vax_ipv vax_pcv vax_rota if immunization_yn==1

*   Drop variables
drop vax_opv_obs vax_bcg_obs vax_opv_obs vax_bcg_obs 
label drop vax_opv_obs vax_bcg_obs 

*   Create dichotomous variable for whether or not vaccine is OBSERVED on the day of the interview
foreach var of varlist vax_prv vax_opv vax_measles vax_bcg vax_ipv vax_pcv vax_rota {
		gen `var'_obs =0 if immunization_yn==1
		replace `var'_obs=1 if `var'==2
		replace `var'_obs=. if `var'==. | `var'==-77 | `var'==-88 | `var'==-99   
		label variable `var'_obs "`var' observed on day of interview"
		label define `var'_obs 0 "not observed" 1 "observed"
		label val `var'_obs `var'_obs
	}

*   Generate variable for three vaccines: Penta+Polio+vax_measles
gen vaccine_3count =0 if immunization_yn==1
replace vaccine_3count=1 if  vax_prv_obs==1 & vax_opv_obs==1 & vax_measles_obs==1
replace vaccine_3count=. if  vax_prv_obs==. & vax_opv_obs==. & vax_measles_obs==.   
label variable vaccine_3count "Penta+OPV+vax_measles observed on day of interview"
label define vaccine_3count 0 "1 or more not observed" 1 "All 3 observed"
label val vaccine_3count vaccine_3count

*   Generate variable for all seven basic child vaccines
gen vaccine_7count =0 if immunization_yn==1
replace vaccine_7count=1 if  vax_prv_obs==1 & vax_opv_obs==1 & vax_measles_obs==1 & vax_bcg_obs==1 & vax_ipv_obs==1 & vax_pcv_obs==1 & vax_rota_obs==1
replace vaccine_7count=. if  vax_prv_obs==. & vax_opv_obs==. & vax_measles_obs==. & vax_bcg_obs==. & vax_ipv_obs==. & vax_pcv_obs==. & vax_rota_obs==.
label variable vaccine_7count "7 basic child vaccines observed on day of interview"
label define vaccine_7count 0 "1 or more not observed" 1 "All 7 observed"
label val vaccine_7count vaccine_7count

*   Check missingness
mdesc vax_prv_obs vax_opv_obs vax_measles_obs vaccine_3count vax_bcg_obs vax_ipv_obs vax_pcv_obs vax_rota_obs vaccine_7count if immunization_yn==1
misstable pattern vax_prv_obs vax_opv_obs vax_measles_obs vaccine_3count vax_bcg_obs vax_ipv_obs vax_pcv_obs vax_rota_obs vaccine_7count if immunization_yn==1, freq

*	Set up putexcel
putexcel set "PMAET_2019SDP_Analysis_$date.xlsx", sheet("Table30") modify
putexcel A1=("Table 30. Availability of basic child vaccines"), bold underline
putexcel A2=("Among facilities offering immunication services, percentages that have at least one valid dose of indicated vaccine observed on the day of the survey"), italic
putexcel B4=("Pentavalent") C4=("Oral polio vaccine (OPV)") D4=("Measles") E4=("All three (penta+OPV+Measles)") F4=("BCG") G4=("Inactivated polio vaccine (IPV)") H4=("Pneumococcal conjugate vaccine (PCV)") I4=("Rotavirus vaccine") J4=("All 7 basic child vaccine") K4=("Number of facilities")
putexcel A5="Type" A11="Managing authority" A15="Region" A29="Total", bold

*	Basic child vaccine by facility type, managing authority, and region
local row = 6
foreach RowVar in facility_type2 sector region {
                  
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
      
	forvalues i = 1/`RowCount' {
		sum vax_prv_obs if `RowVar'==`i' & immunization_yn==1
		
		if r(N)!=0 {
		
			local RowValueLabelNum = word("`RowLevels'", `i')
			local CellContents : label `RowValueLabel' `RowValueLabelNum'
			local mean1: disp %3.1f r(mean)*100
			
			sum vax_opv_obs if `RowVar'==`i' & immunization_yn==1
			local mean2: disp %3.1f r(mean)*100
			
			sum vax_measles_obs if `RowVar'==`i' & immunization_yn==1
			local mean3: disp %3.1f r(mean)*100
			
			sum vaccine_3count if `RowVar'==`i' & immunization_yn==1
			local mean4: disp %3.1f r(mean)*100
			
			sum vax_bcg_obs if `RowVar'==`i' & immunization_yn==1
			local mean5: disp %3.1f r(mean)*100
			
			sum vax_ipv_obs if `RowVar'==`i' & immunization_yn==1
			local mean6: disp %3.1f r(mean)*100
			
			sum vax_pcv_obs if `RowVar'==`i' & immunization_yn==1
			local mean7: disp %3.1f r(mean)*100
			
			sum vax_rota_obs if `RowVar'==`i' & immunization_yn==1
			local mean8: disp %3.1f r(mean)*100
			
			sum vaccine_7count if `RowVar'==`i' & immunization_yn==1
			local mean9: disp %3.1f r(mean)*100

			count if `RowVar'==`i' & immunization_yn==1
			if r(N)!=0 local n_1= r(N) 

			putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6') H`row'=(`mean7') I`row'=(`mean8') J`row'=(`mean9') K`row'=(`n_1'), left
			
			local row = `row' + 1	
			}
		}
	local row=`row'+2
	}   
        
*	Basic child vaccine overall
sum vax_prv_obs if immunization_yn==1
local mean1: disp %3.1f r(mean)*100
sum vax_opv_obs if immunization_yn==1
local mean2: disp %3.1f r(mean)*100
sum vax_measles_obs if immunization_yn==1
local mean3: disp %3.1f r(mean)*100
sum vaccine_3count if immunization_yn==1
local mean4: disp %3.1f r(mean)*100
sum vax_bcg_obs if immunization_yn==1
local mean5: disp %3.1f r(mean)*100
sum vax_ipv_obs if immunization_yn==1
local mean6: disp %3.1f r(mean)*100
sum vax_pcv_obs if immunization_yn==1
local mean7: disp %3.1f r(mean)*100
sum vax_rota_obs if immunization_yn==1
local mean8: disp %3.1f r(mean)*100
sum vaccine_7count if immunization_yn==1
local mean9: disp %3.1f r(mean)*100

count if immunization_yn==1
if r(N)!=0 local n_1= r(N)

putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=(`mean6') H`row'=(`mean7') I`row'=(`mean8') J`row'=(`mean9') K`row'=(`n_1'), left

*********************************************************
***   Registration booklet
*********************************************************	

*   Check completeness
mdesc imnci_2m imnci_2m_seen imnci_5y imnci_5y_seen if (facility_type2==1 | facility_type2==2) & sector==0 & infantcare_yn==1
tab1 imnci_2m imnci_2m_seen imnci_5y imnci_5y_seen if (facility_type2==1 | facility_type2==2) & sector==0 & infantcare_yn==1

mdesc iccm_2m iccm_2m_seen iccm_5y iccm_5y_seen if facility_type2==3  & sector==0  & infantcare_yn==1
tab1 iccm_2m iccm_2m_seen iccm_5y iccm_5y_seen if facility_type2==3  & sector==0  & infantcare_yn==1

*   Generate new variables
gen imnci_2mo_obs = 1 if imnci_2m_seen==1
replace imnci_2mo_obs = 0 if imnci_2m_seen==0
replace imnci_2mo_obs = 0 if imnci_2m==0
replace imnci_2mo_obs = . if imnci_2m==.
label variable imnci_2mo_obs  "Current use of IMNCI registration book (0-2 mos) and book observed on day of interview"
label val imnci_2mo_obs yesno
ta imnci_2m_seen imnci_2m if (facility_type2==1 | facility_type2==2) & sector==0 & infantcare_yn==1, m
ta imnci_2mo_obs if (facility_type2==1 | facility_type2==2) & sector==0 & infantcare_yn==1, m

gen imnci_5y_obs = 1 if imnci_5y_seen==1
replace imnci_5y_obs = 0 if imnci_5y_seen==0
replace imnci_5y_obs = 0 if imnci_5y==0
replace imnci_5y_obs = . if imnci_5y==.
label variable imnci_5y_obs  "Current use of IMNCI registration book (2-59 mos) and book observed on day of interview"
label val imnci_5y_obs yesno
ta imnci_5y_seen imnci_5y if (facility_type2==1 | facility_type2==2) & sector==0 & infantcare_yn==1, m
ta imnci_5y_obs if (facility_type2==1 | facility_type2==2) & sector==0 & infantcare_yn==1, m

gen iccm_2mo_obs = 1 if iccm_2m_seen==1
replace iccm_2mo_obs = 0 if iccm_2m_seen==0
replace iccm_2mo_obs = 0 if iccm_2m==0
replace iccm_2mo_obs = . if iccm_2m==.
label variable iccm_2mo_obs  "Current use of iCCM registration book (0-2 mos) and book observed on day of interview"
label val iccm_2mo_obs yesno
ta iccm_2m_seen iccm_2m if facility_type2==3  & sector==0  & infantcare_yn==1, m
ta iccm_2mo_obs if facility_type2==3  & sector==0  & infantcare_yn==1, m

gen iccm_5y_obs = 1 if iccm_5y_seen==1
replace iccm_5y_obs = 0 if iccm_5y_seen==0
replace iccm_5y_obs = 0 if iccm_5y==0
replace iccm_5y_obs = . if iccm_5y==.
label variable iccm_5y_obs "Current use of iCCM registration book (2-59 mos) and book observed on day of interview"
label val iccm_5y_obs yesno
ta iccm_5y_seen iccm_5y if facility_type2==3  & sector==0  & infantcare_yn==1, m
ta iccm_5y_obs if facility_type2==3  & sector==0  & infantcare_yn==1, m

*   Check missingess 
mdesc imnci_2mo_obs imnci_5y_obs if (facility_type2==1 | facility_type2==2) & sector==0 & infantcare_yn==1
misstable pattern imnci_2mo_obs imnci_5y_obs if (facility_type2==1 | facility_type2==2) & sector==0 & infantcare_yn==1, freq
mdesc iccm_2mo_obs iccm_5y_obs if facility_type2==3  & sector==0  & infantcare_yn==1

*	Set up putexcel
putexcel set "PMAET_2019SDP_Analysis_$date.xlsx", sheet("Table31") modify
putexcel A1=("Table 31. Registration books to assess and treat sick children") , bold underline
putexcel A2=("Among government facilities that offer sick child care (0-59 mos), percentages that use IMNCI registration books to assess and treat sick infants and children"), italic
putexcel B3=("Among government hospitals and health centers, percentages that are currently using:") F3=("Among government health posts, percentages that are currently using:")
putexcel (B3:C3), merge border(bottom) txtwrap hcenter
putexcel (F3:G3), merge border(bottom) txtwrap hcenter

putexcel B4=("IMNCI registration book to assess and treat sick young infants (0-2 mos)") C4=("IMNCI registration book to assess and treat sick children (2-59 mos)") D4=("Number of facilities") F4=("iCCM registration book to assess and treat sick young infants (0-2 mos)") G4=("iCCM registration book to assess and treat sick children (2-59 mos)") H4=("Number of facilities")
putexcel A5="Type" A10="Region" A24="Total", bold

*	IMNCI among hospitals and health centers by facility type and region
preserve
keep if sector==1 & infantcare_yn==1

local row = 6
foreach RowVar in facility_type2 region {
               
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
      
	forvalues i = 1/`RowCount' {
		if "`RowVar'"=="facility_type2" & `i'==3 {
			putexcel A`row'="Health post" B`row'="n/a" C`row'="n/a" D`row'="n/a"
			local row = `row' + 1	
			}
		else {
			sum imnci_2mo_obs if `RowVar'==`i' & (facility_type2==1 | facility_type2==2)
			
			if r(N)!=0 {
			
				local RowValueLabelNum = word("`RowLevels'", `i')
				local CellContents : label `RowValueLabel' `RowValueLabelNum'
				local mean1: disp %3.1f r(mean)*100
				
				sum imnci_5y_obs if `RowVar'==`i' & (facility_type2==1 | facility_type2==2) 
				local mean2: disp %3.1f r(mean)*100

				count if `RowVar'==`i' & (facility_type2==1 | facility_type2==2) & sector==1
				if r(N)!=0 local n_1= r(N) 

				if `n_1' >= 5 {
					putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2') D`row'=(`n_1'), left
					}
				if `n_1' < 5 {
					putexcel A`row'=("`CellContents'") B`row'=("--") C`row'=("--") D`row'=("--"), left
					}	
				local row = `row' + 1	
				}
			}
		}
	local row=`row'+2
	}   

*	IMNCI among hospitals and health centers overall
sum imnci_2mo_obs if (facility_type2==1 | facility_type2==2) 
local mean1: disp %3.1f r(mean)*100
sum imnci_5y_obs if (facility_type2==1 | facility_type2==2)
local mean2: disp %3.1f r(mean)*100
count if (facility_type2==1 | facility_type2==2)
if r(N)!=0 local n_1= r(N)

if `n_1' >= 5 {
	putexcel B`row'=(`mean1') C`row'=(`mean2') D`row'=(`n_1'), left
	}
if `n_1' < 5 {
	putexcel B`row'=("--") C`row'=("--") D`row'=("--"), left
	}
	
*	iCCM among host posts by facility type and region 
local row = 6
foreach RowVar in facility_type2 region {
               
	tab `RowVar'
	local RowCount=`r(r)'
	local RowValueLabel : value label `RowVar'
	levelsof `RowVar', local(RowLevels)
      
	forvalues i = 1/`RowCount' {
		if ("`RowVar'"=="facility_type2" & `i'<=2) |("`RowVar'"=="region" & `i'==10) {
			putexcel F`row'="n/a" G`row'="n/a" H`row'="n/a"
			local row = `row' + 1	
			}
		else {
			sum iccm_2mo_obs if `RowVar'==`i' & facility_type2==3
			
			if r(N)!=0 {
			
				local RowValueLabelNum = word("`RowLevels'", `i')
				local CellContents : label `RowValueLabel' `RowValueLabelNum'
				local mean1: disp %3.1f r(mean)*100
				
				sum iccm_5y_obs if `RowVar'==`i' & facility_type2==3
				local mean2: disp %3.1f r(mean)*100
			
				count if `RowVar'==`i' & facility_type2==3
				if r(N)!=0 local n_1= r(N) 

				if `n_1' >= 5 {
					putexcel F`row'=(`mean1') G`row'=(`mean2') H`row'=(`n_1'), left
					}
				if `n_1' < 5 {
					putexcel F`row'=("--") G`row'=("--") H`row'=("--"), left
					}
				local row = `row' + 1	
				}
			}
		}
	local row=`row'+2
	}   
	
*	iCCM overall 
sum iccm_2mo_obs if facility_type2==3 
local mean1: disp %3.1f r(mean)*100
sum iccm_5y_obs if facility_type2==3
local mean2: disp %3.1f r(mean)*100

count if facility_type2==3
if r(N)!=0 local n_1= r(N)	

if `n_1' >= 5 {
	putexcel F`row'=(`mean1') G`row'=(`mean2') H`row'=(`n_1'), left
	}
if `n_1' < 5 {
	putexcel F`row'=("--") G`row'=("--") H`row'=("--"), left
	}
	
restore 

*   Save data
save PMAET_2019SDP_Analysis_PR_$date.dta, replace


log close


