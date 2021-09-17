/*******************************************************************************
*******  PMA Ethiopia 2019 SDP Technical Report Public Release .do file  *******

*   The following .do file will create the .xls file output that PMA Ethiopia used
*	to produce the 2019 Technical Report using PMA Ethiopia's publicly 
*	available Service Delivery Point dataset.
*
*
*   If you have any questions on how to use this .do files, please contact 
*	XXX (I'm happy to be the point of contact, but let me know what you think! - Ellie)
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
*					PMAET_2019SDP_Analysis_Staff_DATE.xls
*   LOG FILE OUT: 	PMAET_2019SDP_Analysis_DATE.log
*
*******************************************************************************/


/*******************************************************************************
*   
*   INSTRUCTIONS:
*   Please update directories in SECTION 2 to set up and run the .do file
*
*	NOTE:
*	All indicators except for staffing pattern is output into PMAET_2019SDP_Analysis_DATE.xls
*	Tables on staffing pattern are saved into PMAET_2019SDP_Analysis_Staff_DATE.xls
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
replace sector=0 if managing_authority==1 
replace sector=1 if managing_authority!=1 & managing_authority!=.
ta sector managing_authority, m

*	Label sector variable
label define sectorl 0 "Public" 1 "Private"
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
putexcel A1="Table 1. Response rate of sampled service delivery points, by background characteristics", bold 
putexcel B2="Completed" C2="Not at facility" D2="Partly completed" E2="Other" F2="Number of SDPs in sample"
putexcel A3="Type" A9="Managing authority" A12="Region", bold

*	Response rate by facility type
local RowVar = "facility_type2"
local ColVar = "SDP_result"
tab `RowVar' if !missing(`ColVar'), matcell(rowtotals)
tab `RowVar' `ColVar', matcell(cellcounts)
local RowCount = r(r)
local ColCount = r(c)
 
local RowValueLabel : value label `RowVar'
levelsof `RowVar', local(RowLevels)
local ColValueLabel : value label `ColVar'
levelsof `ColVar', local(ColLevels)
 
putexcel set PMAET_2019SDP_Analysis_$date.xlsx, sheet(Table1) modify
forvalues row = 1/`RowCount' {
		local RowValueLabelNum = word("`RowLevels'", `row')
		local CellContents : label `RowValueLabel' `RowValueLabelNum'
		local Cell = char(64 + 1) + string(`row' + 3)
		putexcel `Cell' = "`CellContents'", left
			 
		local CellContents = rowtotals[`row',1]
		local Cell = char(64 + `ColCount' + 2) + string(`row' + 3)
		putexcel `Cell' = `CellContents', left
	 
		forvalues col = 1/`ColCount' {
			local cellcount = cellcounts[`row',`col']
			local cellpercent = string(100*`cellcount'/rowtotals[`row',1],"%9.1f")
			local CellContents = "`cellpercent'"
			local Cell = char(64 + `col' + 1) + string(`row' + 3)
			putexcel `Cell' = `CellContents', left			
		}
	}

*	Response rate by managing authority
local RowVar = "sector"
tab `RowVar' if !missing(`ColVar'), matcell(rowtotals)
tab `RowVar' `ColVar', matcell(cellcounts)
local RowCount = r(r)
local ColCount = r(c)
 
local RowValueLabel : value label `RowVar'
levelsof `RowVar', local(RowLevels)

putexcel set PMAET_2019SDP_Analysis_$date.xlsx, sheet(Table1) modify
forvalues row = 1/`RowCount' {
		local RowValueLabelNum = word("`RowLevels'", `row')
		local CellContents : label `RowValueLabel' `RowValueLabelNum'
		local Cell = char(64 + 1) + string(`row' + 9)
		putexcel `Cell' = "`CellContents'", left
			 
		local CellContents = rowtotals[`row',1]
		local Cell = char(64 + `ColCount' + 2) + string(`row' + 9)
		putexcel `Cell' = `CellContents', left
	 
		forvalues col = 1/`ColCount' {
			local cellcount = cellcounts[`row',`col']
			local cellpercent = string(100*`cellcount'/rowtotals[`row',1],"%9.1f")
			local CellContents = "`cellpercent'"
			local Cell = char(64 + `col' + 1) + string(`row' + 9)
			putexcel `Cell' = `CellContents', left
		}
	}

*	Response rate by region 
local RowVar = "region"
tab `RowVar' if !missing(`ColVar'), matcell(rowtotals)
tab `RowVar' `ColVar', matcell(cellcounts)
local RowCount = r(r)
local ColCount = r(c)
 
local RowValueLabel : value label `RowVar'
levelsof `RowVar', local(RowLevels)

putexcel set PMAET_2019SDP_Analysis_$date.xlsx, sheet(Table1) modify
forvalues row = 1/`RowCount' {
		local RowValueLabelNum = word("`RowLevels'", `row')
		local CellContents : label `RowValueLabel' `RowValueLabelNum'
		local Cell = char(64 + 1) + string(`row' + 12)
		putexcel `Cell' = "`CellContents'", left
			 
		local CellContents = rowtotals[`row',1]
		local Cell = char(64 + `ColCount' + 2) + string(`row' + 12)
		putexcel `Cell' = `CellContents', left
	 
		forvalues col = 1/`ColCount' {
			local cellcount = cellcounts[`row',`col']
			local cellpercent = string(100*`cellcount'/rowtotals[`row',1],"%9.1f")
			local CellContents = "`cellpercent'"
			local Cell = char(64 + `col' + 1) + string(`row' + 12)
			putexcel `Cell' = `CellContents', left
		}
	}

*	Overall response rate 
putexcel A24="Total", bold left
quietly {
		count 
		local totalSDP = r(N)
		count if SDP_result==1 
		local complete = string(r(N) / `totalSDP' * 100, "%5.1f")
		count if SDP_result==2
		local na = string(r(N) / `totalSDP' * 100, "%5.1f")
		count if SDP_result==5
		local par_complete = string(r(N) / `totalSDP' * 100, "%5.1f")
		count if SDP_result==96
		local other = string(r(N) / `totalSDP' * 100, "%5.1f")
	}

putexcel B24 = `complete' C24 = `na' D24 = `par_complete' E24=`other' F24=`totalSDP', left 

*	Keep only completed surveys (n=799) 
keep if SDP_result==1

********************************************************************************
***   SECTION 5: SDP BACKGROUND CHARACTERISTICS
********************************************************************************	

putexcel set PMAET_2019SDP_Analysis_$date.xlsx, sheet(Table2) modify
putexcel A1=("Table 2. Distribution of surveyed service delivery points, by facility characteristics"), bold
putexcel B2="Percent distribution of surveyed SDPs" C2="Number of SDPs" 
putexcel A3="Type" A9="Managing authority" A12="Region", bold

*	Facility type 
tabulate facility_type2, matcell(freq) matrow(names)
local rows = rowsof(names)
local row = 4
 
forvalues i = 1/`rows' {
        local val = names[`i',1]
        local val_lab : label (facility_type2) `val'
        local freq_val = freq[`i',1]
        local percent_val = `freq_val'/`r(N)'*100
        local percent_val : display %9.1f `percent_val'
 
        putexcel A`row'=("`val_lab'") B`row'=(`percent_val') C`row'=(`freq_val'), left
        local row = `row' + 1
}

*	Managing authority
tabulate sector, matcell(freq) matrow(names)
local rows = rowsof(names)
local row = 10
 
forvalues i = 1/`rows' {
        local val = names[`i',1]
        local val_lab : label (sector) `val'
        local freq_val = freq[`i',1]
        local percent_val = `freq_val'/`r(N)'*100
        local percent_val : display %9.1f `percent_val'
 
        putexcel A`row'=("`val_lab'") B`row'=(`percent_val') C`row'=(`freq_val'), left
        local row = `row' + 1
}

*	Region 
tabulate region, matcell(freq) matrow(names)
local rows = rowsof(names)
local row = 13
 
forvalues i = 1/`rows' {
        local val = names[`i',1]
        local val_lab : label (region) `val'
        local freq_val = freq[`i',1]
        local percent_val = `freq_val'/`r(N)'*100
        local percent_val : display %9.1f `percent_val'
 
        putexcel A`row'=("`val_lab'") B`row'=(`percent_val') C`row'=(`freq_val'), left
        local row = `row' + 1
}

putexcel A`row'=("Total"), left bold
putexcel B`row'=(100.0) C`row'=(r(N)), left


/*
*	Descriptive statistics by background characteristics
foreach var in facility_type2 sector region {
		tabout `var' using "PMAET_2019SDP_Analysis_$date.xls", append c(col freq) clab(% n) f(1 0) h2("Distribution of surveyed service delivery points, by background characteristics") show(none)
	}

*/

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
putexcel A1="Table 3.1 Staffing pattern in service delivery points: expanded", bold
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
putexcel A1="Table 3.2 Staffing pattern in service delivery points: expanded", bold
putexcel A2="Median number (25th to 75th percentile) of providers who work at facility, by type of provider and type of facility, PMA Ethiopia 2019", italic
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

putexcel set "PMAET_2019SDP_Analysis_$date.xlsx", sheet("Table4") modify
putexcel A1="Table 4. Availability of basic amenities for client services", bold 
putexcel B2=("Regular electricity") C2=("Continuous electricity") D2=("Water outlet onsite") E2=("Client toilet") F2=("Internet") G2=("Number of facilities")
putexcel A3="Type" A8="Managing authority" A11="Region" A23="Total", bold

*	Basic amenities by facility type
local row = 4
local RowValueLabel : value label facility_type2
levelsof facility_type2, local(RowLevels)

forvalues i = 1/4 {
		sum electricity_regular if facility_type2==`i'
		local RowValueLabelNum = word("`RowLevels'", `i')
		local CellContents : label `RowValueLabel' `RowValueLabelNum'
		local mean1: disp %3.1f r(mean)*100
		
		sum electricity_binary if facility_type2==`i'
		local mean2: disp %3.1f r(mean)*100
		
		sum water_outlet if facility_type2==`i'
		local mean3: disp %3.1f r(mean)*100
		
		sum toilet_pt if facility_type2==`i'
		local mean4: disp %3.1f r(mean)*100
		
		sum internet_binary if facility_type2==`i'
		local mean5: disp %3.1f r(mean)*100
		if r(N)!=0 local n_1= r(N)
		
		putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2')  D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=`n_1', left
		
		local row = `row' + 1
	}

*	Basic amenities by managing authority
gen sector_new = sector + 1
label define sectorl_new 1 "Public" 2 "Private"
label values sector_new sectorl_new

local row = 9
local RowValueLabel : value label sector_new
levelsof sector_new, local(RowLevels)

forvalues i = 1/2 {
		sum electricity_regular if sector_new==`i'
		local RowValueLabelNum = word("`RowLevels'", `i')
		local CellContents : label `RowValueLabel' `RowValueLabelNum'
		local mean1: disp %3.1f r(mean)*100
		
		sum electricity_binary if sector_new==`i'
		local mean2: disp %3.1f r(mean)*100
		
		sum water_outlet if sector_new==`i'
		local mean3: disp %3.1f r(mean)*100
		
		sum toilet_pt if sector_new==`i'
		local mean4: disp %3.1f r(mean)*100
		
		sum internet_binary if sector_new==`i'
		local mean5: disp %3.1f r(mean)*100
		if r(N)!=0 local n_1= r(N)
		
		putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2')  D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=`n_1', left
		
		local row = `row' + 1
	}

*	Basic amenities by region
local row = 12
local RowValueLabel : value label region
levelsof region, local(RowLevels)

forvalues i = 1/11 {
		sum electricity_regular if region==`i'
		local RowValueLabelNum = word("`RowLevels'", `i')
		local CellContents : label `RowValueLabel' `RowValueLabelNum'
		local mean1: disp %3.1f r(mean)*100
		
		sum electricity_binary if region==`i'
		local mean2: disp %3.1f r(mean)*100
		
		sum water_outlet if region==`i'
		local mean3: disp %3.1f r(mean)*100
		
		sum toilet_pt if region==`i'
		local mean4: disp %3.1f r(mean)*100
		
		sum internet_binary if region==`i'
		local mean5: disp %3.1f r(mean)*100
		if r(N)!=0 local n_1= r(N)
		
		putexcel A`row'=("`CellContents'") B`row'=(`mean1') C`row'=(`mean2')  D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=`n_1', left
		
		local row = `row' + 1
	}

*	Overall amenities
local row = 23
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

putexcel B`row'=(`mean1') C`row'=(`mean2')  D`row'=(`mean3') E`row'=(`mean4') F`row'=(`mean5') G`row'=`n_1', left
	
/*	Recode yes/no variables as percentages on scale of 0 to 100
foreach v of varlist electricity_regular electricity_binary water_outlet toilet_pt internet_binary {
		recode `v' (1 = 100), gen(percent_`v')
	}

*	Basic amenities by background characteristics (tabout)
tabout facility_type2 if facility_type2!=5 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_electricity_regular mean percent_electricity_binary mean percent_water_outlet mean percent_toilet_pt mean percent_internet_binary) f(1) npos(col) sum append  h2("Availability of basic amenities for client services") show(none)
tabout sector if facility_type2!=5 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_electricity_regular mean percent_electricity_binary mean percent_water_outlet mean percent_toilet_pt mean percent_internet_binary) f(1) npos(col) sum append  h2("Availability of basic amenities for client services") show(none)
tabout region if facility_type2!=5 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_electricity_regular mean percent_electricity_binary mean percent_water_outlet mean percent_toilet_pt mean percent_internet_binary) f(1) npos(col) sum append  h2("Availability of basic amenities for client services") show(none) */


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

*	Recode yes/no variables as percentages on scale of 0 to 100
foreach v of varlist hmis_system_yn hmis_report hmis_report_monthly {
		recode `v' (1 = 100), gen(percent_`v')
	}

*	Health management information system (tabout)
tabout facility_type2 if facility_type2!=5 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_hmis_system_yn mean percent_hmis_report mean percent_hmis_report_monthly) f(1) npos(col) sum append  h2("Health management information systems") show(none)
tabout sector if facility_type2!=5 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_hmis_system_yn mean percent_hmis_report mean percent_hmis_report_monthly) f(1) npos(col) sum append  h2("Health management information systems") show(none)
tabout region if facility_type2!=5 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_hmis_system_yn mean percent_hmis_report mean percent_hmis_report_monthly) f(1) npos(col) sum append  h2("Health management information systems") show(none)


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

*	Recode yes/no variables as percentages on scale of 0 to 100
foreach v of varlist fb_leadership fb_external fb_any fb_rec_action {
		recode `v' (1 = 100), gen(percent_`v')
	}

*   HMIS feedback (tabout)
tabout facility_type2 if hmis_report==1 & facility_type2!=5 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_fb_leadership mean percent_fb_external mean percent_fb_any mean percent_fb_rec_action) f(1) npos(col) sum append  h2("HMIS feedback") show(none)
tabout sector if hmis_report==1 & facility_type2!=5 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_fb_leadership mean percent_fb_external mean percent_fb_any mean percent_fb_rec_action) f(1) npos(col) sum append  h2("HMIS feedback") show(none)
tabout region if hmis_report==1 & facility_type2!=5 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_fb_leadership mean percent_fb_external mean percent_fb_any mean percent_fb_rec_action ) f(1) npos(col) sum append  h2("HMIS feedback") show(none)

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

*	Recode yes/no variables as percentages on scale of 0 to 100
foreach v of varlist review_effort review_facility improv_care resource_allocation resource_advocacy {
		recode `v' (1 = 100), gen(perc_`v')
	}

*	HMIS recommendations (tabout)
tabout facility_type2 if hmis_report==1 & facility_type2!=5 & fb_rec_action==1 using "PMAET_2019SDP_Analysis_$date.xls", c(mean perc_review_effort mean perc_review_facility mean perc_improv_care mean perc_resource_allocation mean perc_resource_advocacy) f(1) npos(col) sum append  h2("Type of HMIS recs") show(none)
tabout sector if hmis_report==1 & facility_type2!=5 & fb_rec_action==1 using "PMAET_2019SDP_Analysis_$date.xls", c(mean perc_review_effort mean perc_review_facility mean perc_improv_care mean perc_resource_allocation mean perc_resource_advocacy) f(1) npos(col) sum append  h2("Type of HMIS recs") show(none)
tabout region if hmis_report==1 & facility_type2!=5 & fb_rec_action==1 using "PMAET_2019SDP_Analysis_$date.xls", c(mean perc_review_effort mean perc_review_facility mean perc_improv_care mean perc_resource_allocation mean perc_resource_advocacy) f(1) npos(col) sum append  h2("Type of HMIS recs") show(none)


*********************************************************
***   Performance monitoring teams
*********************************************************	

*	Check completeness
mdesc pmt pmt_meet pmt_meet_freq if (facility_type2==1 | facility_type2==2) & sector==0
tab1 pmt pmt_meet pmt_meet_freq if (facility_type2==1 | facility_type2==2) & sector==0

*	Generate variables for facilities with PMT that meets monthly or more often
gen pmt_meet_monthly = 0 if (facility_type2==1 | facility_type2==2) & sector==0
replace pmt_meet_monthly = 1 if pmt_meet_freq==5 & (facility_type2==1 | facility_type2==2) & sector==0
replace pmt_meet_monthly = . if pmt_meet_freq==-88 & (facility_type2==1 | facility_type2==2) & sector==0
label var pmt_meet_monthly "Facility has PMT that meets monthly or more often"
label val pmt_meet_monthly yesno
ta pmt_meet_monthly if (facility_type2==1 | facility_type2==2) & sector==0, m

*	Recode yes/no variables as percentages on scale of 0 to 100
foreach v of varlist pmt pmt_meet_monthly {
		recode `v' (1 = 100), gen(percent_`v')
	}

*	PMT (tabout)
tabout facility_type2 if (facility_type2==1 | facility_type2==2) & sector==0 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_pmt mean percent_pmt_meet_monthly) f(1) npos(col) sum append  h2("PMT") show(none)
tabout region if (facility_type2==1 | facility_type2==2) & sector==0 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_pmt mean percent_pmt_meet_monthly) f(1) npos(col) sum append  h2("PMT") show(none)


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


*	Recode yes/no variables as percentages on scale of 0 to 100
foreach v of varlist perform_review perform_review_monthly perform_review_quarterly perform_review_infreq perform_review_none{
		recode `v' (1 = 100), gen(percent_`v')
	}

*	Participatory performance review (tabout)
tabout facility_type2 if (facility_type2==1 | facility_type2==2) using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_perform_review mean percent_perform_review_monthly mean percent_perform_review_quarterly mean percent_perform_review_infreq mean percent_perform_review_none) f(1) npos(col) sum append  h2("Participatory performance review") show(none)
tabout sector if (facility_type2==1 | facility_type2==2) using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_perform_review mean percent_perform_review_monthly mean percent_perform_review_quarterly mean percent_perform_review_infreq mean percent_perform_review_none) f(1) npos(col) sum append  h2("Participatory performance review") show(none)
tabout region if (facility_type2==1 | facility_type2==2) using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_perform_review mean percent_perform_review_monthly mean percent_perform_review_quarterly mean percent_perform_review_infreq mean percent_perform_review_none) f(1) npos(col) sum append  h2("Participatory performance review") show(none)


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

*	Recode yes/no variables as percentages on scale of 0 to 100
foreach v of varlist antenatal_yn labor_delivery_yn postnatal_yn surgery_yn transfusion_yn neonatal_yn {
		recode `v' (1 = 100), gen(percent_`v')
	}

*	MNH Service Availability (tabout)
tabout facility_type2 if facility_type2!=5 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_antenatal_yn mean percent_labor_delivery_yn mean percent_postnatal_yn mean percent_surgery_yn mean percent_transfusion_yn mean percent_neonatal_yn ) f(1) npos(col) sum append  h2("Availability of maternal and newborn health services") show(none)
tabout sector if facility_type2!=5 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_antenatal_yn mean percent_labor_delivery_yn mean percent_postnatal_yn mean percent_surgery_yn mean percent_transfusion_yn mean percent_neonatal_yn ) f(1) npos(col) sum append  h2("Availability of maternal and newborn health services") show(none)
tabout region if facility_type2!=5 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_antenatal_yn mean percent_labor_delivery_yn mean percent_postnatal_yn mean percent_surgery_yn mean percent_transfusion_yn mean percent_neonatal_yn ) f(1) npos(col) sum append  h2("Availability of maternal and newborn health services") show(none)


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

*	Recode yes/no variables as percentages on scale of 0 to 100
foreach v of varlist bp_apparatus_obs se_fetal_either_obs se_dipstick_obs hiv_rapid_obs outdr_syphilis_obs outdr_iron_obs vax_tt_obs anc_privacy  {
		recode `v' (1 = 100), gen(percent_`v')
	}

*	ANC equipment, diagnostic capacity, commodities, and amenities (tabout)
tabout hospital if labor_delivery_yn==1 & hospital!=. using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_bp_apparatus_obs mean percent_se_fetal_either_obs mean percent_se_dipstick_obs mean percent_hiv_rapid_obs mean percent_outdr_syphilis_obs mean percent_outdr_iron_obs mean percent_vax_tt_obs mean percent_anc_privacy ) f(1) npos(col) sum append  h2("ANC equipment") show(none)
tabout sector if labor_delivery_yn==1 & hospital!=. using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_bp_apparatus_obs mean percent_se_fetal_either_obs mean percent_se_dipstick_obs mean percent_hiv_rapid_obs mean percent_outdr_syphilis_obs mean percent_outdr_iron_obs mean percent_vax_tt_obs mean percent_anc_privacy ) f(1) npos(col) sum append  h2("ANC equipment") show(none)
tabout region if labor_delivery_yn==1 & hospital!=. using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_bp_apparatus_obs mean percent_se_fetal_either_obs mean percent_se_dipstick_obs mean percent_hiv_rapid_obs mean percent_outdr_syphilis_obs mean percent_outdr_iron_obs mean percent_vax_tt_obs mean percent_anc_privacy ) f(1) npos(col) sum append  h2("ANC equipment") show(none)


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

*   Check missingness
mdesc skilled_ba proc_fmoh_ob_obs se_clamp_scissors_obs se_suction_either se_forceps_vac_obs se_dc_mva_obs se_resus_bag_masks ivkit rm_delivery_privacy if labor_delivery_yn==1 & facility_type2!=5

*   Recode yes/no variables as percentages on scale of 0 to 100
foreach v of varlist skilled_ba proc_fmoh_ob_obs se_clamp_scissors_obs se_suction_either 	///
		se_forceps_vac_obs se_dc_mva_obs se_resus_bag_masks ivkit rm_delivery_privacy  {
			recode `v' (1 = 100), gen(percent_`v')
		}

*   Staffing, guidelines, equipment for delivery(tabout)
tabout hospital if labor_delivery_yn==1 & hospital!=. using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_skilled_ba mean percent_proc_fmoh_ob_obs mean percent_se_clamp_scissors_obs mean percent_se_suction_either mean percent_se_forceps_vac_obs mean percent_se_dc_mva_obs mean percent_se_resus_bag_masks mean percent_ivkit mean percent_rm_delivery_privacy) f(1) npos(col) sum append  h2("Delivery staffing and equipment") show(none)
tabout sector if labor_delivery_yn==1 & hospital!=. using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_skilled_ba mean percent_proc_fmoh_ob_obs mean percent_se_clamp_scissors_obs mean percent_se_suction_either mean percent_se_forceps_vac_obs mean percent_se_dc_mva_obs mean percent_se_resus_bag_masks mean percent_ivkit mean percent_rm_delivery_privacy) f(1) npos(col) sum append  h2("Delivery staffing and equipment") show(none)
tabout region if labor_delivery_yn==1 & hospital!=. using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_skilled_ba mean percent_proc_fmoh_ob_obs mean percent_se_clamp_scissors_obs mean percent_se_suction_either mean percent_se_forceps_vac_obs mean percent_se_dc_mva_obs mean percent_se_resus_bag_masks mean percent_ivkit mean percent_rm_delivery_privacy) f(1) npos(col) sum append  h2("Delivery staffing and equipment") show(none)


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

*   Recode yes/no variables as percentages on scale of 0 to 100
foreach v of varlist inj_ampicillin_obs outdr_azithromycin_obs outdr_benzathine_obs dexamethasone_obs inj_cagluc_obs outdr_cefixime_obs inj_gentamicin_obs hydralazine_obs inj_mgso4_obs outdr_methyldopa_obs inj_metronidazole_obs mife_obs miso_obs nifedipine_obs inj_oxt_obs ivsoln_obs indr_dexamethasone_obs indr_inj_cagluc_obs indr_hydralazine_obs indr_inj_mgso4_obs indr_mife_obs indr_miso_obs indr_nifedipine_obs indr_inj_oxt_obs indr_ivsoln_obs  {
		recode `v' (1 = 100), gen(percent_`v')
	}

*   Availability of life-saving meds (tabout)
tabout hospital if labor_delivery_yn==1 & hospital!=. using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_inj_ampicillin_obs mean percent_outdr_azithromycin_obs mean percent_outdr_benzathine_obs mean percent_dexamethasone_obs mean percent_inj_cagluc_obs mean percent_outdr_cefixime_obs mean percent_inj_gentamicin_obs mean percent_hydralazine_obs mean percent_inj_mgso4_obs mean percent_outdr_methyldopa_obs mean percent_inj_metronidazole_obs mean percent_mife_obs mean percent_miso_obs mean percent_nifedipine_obs mean percent_inj_oxt_obs mean percent_ivsoln_obs mean percent_vax_tt_obs) f(1) npos(col) sum append  h2("Availability of life-saving medicines") show(none)

tabout sector if labor_delivery_yn==1 & hospital!=. using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_inj_ampicillin_obs mean percent_outdr_azithromycin_obs mean percent_outdr_benzathine_obs mean percent_dexamethasone_obs mean percent_inj_cagluc_obs mean percent_outdr_cefixime_obs mean percent_inj_gentamicin_obs mean percent_hydralazine_obs mean percent_inj_mgso4_obs mean percent_outdr_methyldopa_obs mean percent_inj_metronidazole_obs mean percent_mife_obs mean percent_miso_obs mean percent_nifedipine_obs mean percent_inj_oxt_obs mean percent_ivsoln_obs mean percent_vax_tt_obs) f(1) npos(col) sum append  h2("Availability of life-saving medicines") show(none)

tabout hospital if labor_delivery_yn==1 & hospital!=. using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_indr_dexamethasone_obs mean percent_indr_inj_cagluc_obs mean percent_indr_hydralazine_obs mean percent_indr_inj_mgso4_obs mean percent_indr_mife_obs mean percent_indr_miso_obs mean percent_indr_nifedipine_obs mean percent_indr_inj_oxt_obs mean percent_indr_ivsoln_obs) f(1) npos(col) sum append  h2("Availability of priority medicines in delivery room") show(none)
tabout sector if labor_delivery_yn==1 & hospital!=. using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_indr_dexamethasone_obs mean percent_indr_inj_cagluc_obs mean percent_indr_hydralazine_obs mean percent_indr_inj_mgso4_obs mean percent_indr_mife_obs mean percent_indr_miso_obs mean percent_indr_nifedipine_obs mean percent_indr_inj_oxt_obs mean percent_indr_ivsoln_obs) f(1) npos(col) sum append  h2("Availability of priority medicines in delivery room") show(none)


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

*   Recode yes/no variables as percentages on scale of 0 to 100
foreach v of varlist both_oxt_mgso4 meds7 meds14 meds17 {
		recode `v' (1 = 100), gen(percent_`v')
	}

*   Count of life-saving medicines (tabout)
tabout hospital if labor_delivery_yn==1 & hospital!=. using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_both_oxt_mgso4 mean percent_meds7 mean percent_meds14 mean percent_meds17) f(1) npos(col) sum append  h2("Count of life-saving medicines") show(none)
tabout sector if labor_delivery_yn==1 & hospital!=. using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_both_oxt_mgso4 mean percent_meds7 mean percent_meds14 mean percent_meds17) f(1) npos(col) sum append  h2("Count of life-saving medicines") show(none)
tabout region if labor_delivery_yn==1 & hospital!=. using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_both_oxt_mgso4 mean percent_meds7 mean percent_meds14 mean percent_meds17) f(1) npos(col) sum append  h2("Count of life-saving medicines") show(none)


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

*   Recode yes/no variables as percentages on scale of 0 to 100
foreach v of varlist se_sharps_obs se_waste_obs se_cl_obs se_syringe_obs se_soap_water se_etoh_scrub_obs se_gloves_obs mask_delivery_obs gown_delivery_obs se_goggles_obs {
		recode `v' (1 = 100), gen(percent_`v')
	}

*   Infection prevention (tabout)
tabout hospital if labor_delivery_yn==1 & hospital!=. using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_se_sharps_obs mean percent_se_waste_obs mean percent_se_cl_obs mean percent_se_syringe_obs mean percent_se_soap_water mean percent_se_etoh_scrub_obs mean percent_se_gloves_obs mean percent_mask_delivery_obs mean percent_gown_delivery_obs mean percent_se_goggles_obs) f(1) npos(col) sum append  h2("Infection control procedures") show(none)
tabout sector if labor_delivery_yn==1 & hospital!=. using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_se_sharps_obs mean percent_se_waste_obs mean percent_se_cl_obs mean percent_se_syringe_obs mean percent_se_soap_water mean percent_se_etoh_scrub_obs mean percent_se_gloves_obs mean percent_mask_delivery_obs mean percent_gown_delivery_obs mean percent_se_goggles_obs) f(1) npos(col) sum append  h2("Infection control procedures") show(none)
tabout region if labor_delivery_yn==1 & hospital!=. using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_se_sharps_obs mean percent_se_waste_obs mean percent_se_cl_obs mean percent_se_syringe_obs mean percent_se_soap_water mean percent_se_etoh_scrub_obs mean percent_se_gloves_obs mean percent_mask_delivery_obs mean percent_gown_delivery_obs mean percent_se_goggles_obs) f(1) npos(col) sum append  h2("Infection control procedures") show(none)


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

*   Recode yes/no variables as percentages on scale of 0 to 100
foreach v of varlist ster_any_obs disinfect_any_obs {
		recode `v' (1 = 100), gen(percent_`v')
	}

*   Sterilization and disinfection equipment (tabout)
tabout sector if surgery_yn==1 & hospital==1 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_ster_any_obs mean percent_disinfect_any_obs ) f(1) npos(col) sum append  h2("Sterilization and disinfection") show(none)
tabout region if surgery_yn==1 & hospital==1 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_ster_any_obs mean percent_disinfect_any_obs ) f(1) npos(col) sum append  h2("Sterilization and disinfection") show(none)


*********************************************************
***   Signal functions
*********************************************************	

*   Check completeness
mdesc medservice_abx obh_ut_3mo aed_3mo medservice_assist medservice_man_plac medservice_resus medservice_cortisteroids medservice_csection if labor_delivery_yn==1 & hospital!=.
tab1 medservice_abx obh_ut_3mo aed_3mo medservice_assist medservice_man_plac medservice_resus medservice_cortisteroids medservice_csection if labor_delivery_yn==1 & hospital!=.
misstable pattern medservice_abx obh_ut_3mo aed_3mo medservice_assist medservice_man_plac medservice_resus medservice_cortisteroids medservice_csection if labor_delivery_yn==1 & hospital!=., freq
mdesc medservice_transfuse if labor_delivery_yn==1 & hospital!=. & transfusion_yn==1

*   Recode yes/no variables as percentages on scale of 0 to 100
foreach v of varlist medservice_abx obh_ut_3mo aed_3mo medservice_assist medservice_man_plac medservice_resus medservice_cortisteroids medservice_csection medservice_transfuse  {
		recode `v' (1 = 100), gen(percent_`v')
	}

*   Signal functions (tabout)
tabout hospital if labor_delivery_yn==1 & hospital!=. using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_medservice_abx mean percent_obh_ut_3mo mean percent_aed_3mo mean percent_medservice_cortisteroids mean percent_medservice_assist mean percent_medservice_man_plac mean percent_medservice_resus  mean percent_medservice_csection ) f(1) npos(col) sum append  h2("Signal functions") show(none)
tabout sector if labor_delivery_yn==1 & hospital!=. using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_medservice_abx mean percent_obh_ut_3mo mean percent_aed_3mo mean percent_medservice_cortisteroids mean percent_medservice_assist mean percent_medservice_man_plac mean percent_medservice_resus  mean percent_medservice_csection ) f(1) npos(col) sum append  h2("Signal functions") show(none)
tabout region if labor_delivery_yn==1 & hospital!=. using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_medservice_abx mean percent_obh_ut_3mo mean percent_aed_3mo mean percent_medservice_cortisteroids mean percent_medservice_assist mean percent_medservice_man_plac mean percent_medservice_resus  mean percent_medservice_csection ) f(1) npos(col) sum append  h2("Signal functions") show(none)

tabout hospital if transfusion_yn==1 & labor_delivery_yn==1 & hospital!=. using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_medservice_transfuse) f(1) npos(col) sum append  h2("Transfusion") show(none)
tabout sector if transfusion_yn==1 & labor_delivery_yn==1 & hospital!=. using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_medservice_transfuse) f(1) npos(col) sum append  h2("Transfusion") show(none)
tabout region if transfusion_yn==1 & labor_delivery_yn==1 & hospital!=. using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_medservice_transfuse) f(1) npos(col) sum append  h2("Transfusion") show(none)


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

*   Recode yes/no variables as percentages on scale of 0 to 100
foreach v of varlist refer_out phone_yn transport_yn refer_form_obs refer_report_recode {
		recode `v' (1 = 100), gen(percent_`v')
	}

*   Makes referrals (tabout)
tabout facility_type2 if facility_type2!=5 & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1)  using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_refer_out) f(1) npos(col) sum append  h2("Makes referrals") show(none)
tabout sector if facility_type2!=5 & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1)  using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_refer_out) f(1) npos(col) sum append  h2("Makes referrals") show(none)
tabout region if facility_type2!=5 & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1)  using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_refer_out) f(1) npos(col) sum append  h2("Makes referrals") show(none)

*   Referral readiness (tabout)
tabout facility_type2 if facility_type2!=5 & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1) & refer_out==1  using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_phone_yn mean percent_transport_yn mean percent_refer_form_obs mean percent_refer_report_recode) f(1) npos(col) sum append  h2("Referral readiness") show(none)
tabout sector if facility_type2!=5 & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1) & refer_out==1  using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_phone_yn mean percent_transport_yn mean percent_refer_form_obs mean percent_refer_report_recode) f(1) npos(col) sum append  h2("Referral readiness") show(none)
tabout region if facility_type2!=5 & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1) & refer_out==1  using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_phone_yn mean percent_transport_yn mean percent_refer_form_obs mean percent_refer_report_recode) f(1) npos(col) sum append  h2("Referral readiness") show(none)


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

*   Recode yes/no variables as percentages on scale of 0 to 100
foreach v of varlist death_report_recode review_death_recode {
		recode `v' (1 = 100), gen(percent_`v')
	}

*   Maternal death reporting and review (tabout)
tabout facility_type2 if (facility_type2==1 |  facility_type2==2 |  facility_type2==3) & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1)  using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_death_report) f(1) npos(col) sum append  h2("MDSR") show(none)
tabout sector if (facility_type2==1 |  facility_type2==2 |  facility_type2==3) & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1)  using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_death_report) f(1) npos(col) sum append  h2("MDSR") show(none)
tabout region if (facility_type2==1 |  facility_type2==2 |  facility_type2==3) & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1)  using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_death_report) f(1) npos(col) sum append  h2("MDSR") show(none)

tabout facility_type2 if (facility_type2==1 |  facility_type2==2) & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1) using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_review_death_recode) f(1) npos(col) sum append  h2("Maternal death reviews") show(none)
tabout sector if (facility_type2==1 |  facility_type2==2) & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1) using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_review_death_recode) f(1) npos(col) sum append  h2("Maternal death reviews") show(none)
tabout region if (facility_type2==1 |  facility_type2==2) & (antenatal_yn==1 | labor_delivery_yn==1 | postnatal_yn==1 | surgery_yn==1) using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_review_death_recode) f(1) npos(col) sum append  h2("Maternal death reviews") show(none)


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

*   Recode yes/no variables as percentages on scale of 0 to 100
foreach v of varlist tetracycline_obs chlorhexidine_obs inj_vitk_obs vax_bcg_obs vax_opv_obs se_scale_obs rm_newborn proc_bfi_obs {
		recode `v' (1 = 100), gen(percent_`v')
	}

*   Equipment and medicines for routine newborn care (tabout)
tabout hospital if labor_delivery_yn==1 & hospital!=. using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_tetracycline_obs mean percent_chlorhexidine_obs mean percent_inj_vitk_obs mean percent_vax_bcg_obs mean percent_vax_opv_obs mean percent_se_scale_obs mean percent_rm_newborn mean percent_proc_bfi_obs) f(1) npos(col) sum append  h2("Routine newborn care") show(none)
tabout sector if labor_delivery_yn==1 & hospital!=. using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_tetracycline_obs mean percent_chlorhexidine_obs mean percent_inj_vitk_obs mean percent_vax_bcg_obs mean percent_vax_opv_obs mean percent_se_scale_obs mean percent_rm_newborn mean percent_proc_bfi_obs) f(1) npos(col) sum append  h2("Routine newborn care") show(none)
tabout region if labor_delivery_yn==1 & hospital!=. using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_tetracycline_obs mean percent_chlorhexidine_obs mean percent_inj_vitk_obs mean percent_vax_bcg_obs mean percent_vax_opv_obs mean percent_se_scale_obs mean percent_rm_newborn mean percent_proc_bfi_obs) f(1) npos(col) sum append  h2("Routine newborn care") show(none)


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

*   Recode yes/no variables as percentages on scale of 0 to 100
foreach v of varlist fp_offered_yn adolescents_counseled_r adolescents_provided_r adolescents_prescribed_r {
		recode `v' (1 = 100), gen(percent_`v')
	}

*   FP availability (tabout)
tabout facility_type2 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_fp_offered_yn) f(1) npos(col) sum append  h2("Family planning availability") show(none)
tabout sector using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_fp_offered_yn) f(1) npos(col) sum append  h2("Family planning availability") show(none)
tabout region using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_fp_offered_yn) f(1) npos(col) sum append  h2("Family planning availability") show(none)

tabout facility_type2 if fp_offered_yn==1 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_adolescents_counseled_r mean percent_adolescents_provided_r mean percent_adolescents_prescribed_r) f(1) npos(col) sum append  h2("Adolescent FP") show(none)
tabout sector if fp_offered_yn==1 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_adolescents_counseled_r mean percent_adolescents_provided_r mean percent_adolescents_prescribed_r) f(1) npos(col) sum append  h2("Adolescent FP") show(none)
tabout region if fp_offered_yn==1 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_adolescents_counseled_r mean percent_adolescents_provided_r mean percent_adolescents_prescribed_r) f(1) npos(col) sum append  h2("Adolescent FP") show(none)


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

*   Recode yes/no variables as percentages on scale of 0 to 100
foreach v of varlist implants_1mo iud_1mo injectables_1mo pills_1mo male_condoms_1mo {
		recode `v' (1 = 100), gen(percent_`v')
	}

*   Provision of contraceptive methods (tabout)
tabout facility_type2 if fp_offered_yn==1 & facility_type2!=5 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_implants_1mo mean percent_iud_1mo mean percent_injectables_1mo mean percent_pills_1mo) f(1) npos(col) sum append  h2("Provision of methods") show(none)
tabout sector if fp_offered_yn==1 & facility_type2!=5 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_implants_1mo mean percent_iud_1mo mean percent_injectables_1mo mean percent_pills_1mo) f(1) npos(col) sum append  h2("Provision of methods") show(none)
tabout region if fp_offered_yn==1 & facility_type2!=5 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_implants_1mo mean percent_iud_1mo mean percent_injectables_1mo mean percent_pills_1mo ) f(1) npos(col) sum append  h2("Provision of methods") show(none)


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

*   Recode yes/no variables as percentages on scale of 0 to 100
foreach v of varlist methods_5 methods_4 {
		recode `v' (1 = 100), gen(percent_`v')
	}

*   Mix of methods (tabout)
tabout facility_type2 if fp_offered_yn==1 & (facility_type2==1 | facility_type2==2 | facility_type2==4) using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_methods_5) f(1) npos(col) sum append  h2("Method mix") show(none)
tabout sector if fp_offered_yn==1 & (facility_type2==1 | facility_type2==2 | facility_type2==4) using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_methods_5) f(1) npos(col) sum append  h2("Method mix") show(none)
tabout region if fp_offered_yn==1 & (facility_type2==1 | facility_type2==2 | facility_type2==4) using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_methods_5) f(1) npos(col) sum append  h2("Method mix") show(none)

tabout facility_type2 if fp_offered_yn==1 & facility_type2==3 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_methods_4) f(1) npos(col) sum append  h2("Method mix - health posts") show(none)
tabout sector if fp_offered_yn==1 & facility_type2==3 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_methods_4) f(1) npos(col) sum append  h2("Method mix - health posts") show(none)
tabout region if fp_offered_yn==1 & facility_type2==3 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_methods_4) f(1) npos(col) sum append  h2("Method mix - health posts") show(none)


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
		
*   Recode yes/no variables as percentages on scale of 0 to 100
foreach v of varlist implants_obs iud_obs injectables_obs pills_obs ec_obs male_condoms_obs female_condoms_obs {
		recode `v' (1 = 100), gen(percent_`v')
	}

*   Availability of methods (tabout)
tabout facility_type2 if fp_offered_yn==1 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_implants_obs mean percent_iud_obs mean percent_injectables_obs mean percent_pills_obs mean percent_ec_obs mean percent_male_condoms_obs mean percent_female_condoms_obs) f(1) npos(col) sum append  h2("Availability of methods") show(none)
tabout sector if fp_offered_yn==1 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_implants_obs mean percent_iud_obs mean percent_injectables_obs mean percent_pills_obs mean percent_ec_obs mean percent_male_condoms_obs mean percent_female_condoms_obs) f(1) npos(col) sum append  h2("Availability of methods") show(none)
tabout region if fp_offered_yn==1 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_implants_obs mean percent_iud_obs mean percent_injectables_obs mean percent_pills_obs mean percent_ec_obs mean percent_male_condoms_obs mean percent_female_condoms_obs) f(1) npos(col) sum append  h2("Availability of methods") show(none)


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


*   Recode yes/no variables as percentages on scale of 0 to 100
foreach v of varlist onsite_impl_ins onsite_impl_rm onsite_impl_rm_nonpal offsite_impl_know_recode impl_deep_neither iud_remove {
		recode `v' (1 = 100), gen(percent_`v')
	}

*   Implant removal (tabout)
tabout facility_type2 if provided_implants==1 & (stock_implants==1 | stock_implants==2) using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_onsite_impl_ins mean percent_onsite_impl_rm mean percent_onsite_impl_rm_nonpal mean percent_offsite_impl_know_recode mean percent_impl_deep_neither) f(1) npos(col) sum append  h2("Implant removal") show(none)
tabout sector if provided_implants==1 & (stock_implants==1 | stock_implants==2) using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_onsite_impl_ins mean percent_onsite_impl_rm mean percent_onsite_impl_rm_nonpal mean percent_offsite_impl_know_recode mean percent_impl_deep_neither) f(1) npos(col) sum append  h2("Implant removal") show(none)
tabout region if provided_implants==1 & (stock_implants==1 | stock_implants==2) using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_onsite_impl_ins mean percent_onsite_impl_rm mean percent_onsite_impl_rm_nonpal mean percent_offsite_impl_know_recode mean percent_impl_deep_neither) f(1) npos(col) sum append  h2("Implant removal") show(none)

*   IUD removal (tabout)
tabout facility_type2 if provided_iud==1 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_iud_remove) f(1) npos(col) sum append  h2("IUD removal") show(none)
tabout sector if provided_iud==1 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_iud_remove) f(1) npos(col) sum append  h2("IUD removal") show(none)
tabout region if provided_iud==1 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_iud_remove) f(1) npos(col) sum append  h2("IUD removal") show(none)


*********************************************************
***   Availability of SA & PAC
*********************************************************	

*   Check completeness
mdesc abt_provide_yn postabortion_yn if (facility_type2==1 | facility_type2==2 | facility_type2==4)
tab1 abt_provide_yn postabortion_yn if (facility_type2==1 | facility_type2==2 | facility_type2==4)
mdesc abt_couns abt_refer
bys facility_type2: tab1 abt_couns abt_refer

*   Recode yes/no variables as percentages on scale of 0 to 100
foreach v of varlist abt_provide_yn postabortion_yn abt_couns abt_refer {
		recode `v' (1 = 100), gen(percent_`v')
	}

*   Service availability (tabout)
tabout facility_type2 if facility_type2!=5 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_abt_couns mean percent_abt_refer) f(1) npos(col) sum append  h2("Counseling and referral") show(none)
tabout sector if facility_type2!=5 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_abt_couns mean percent_abt_refer) f(1) npos(col) sum append  h2("Counseling and referral") show(none)
tabout region if facility_type2!=5 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_abt_couns mean percent_abt_refer) f(1) npos(col) sum append  h2("Counseling and referral") show(none)

tabout facility_type2 if (facility_type2==1 | facility_type2==2 | facility_type2==4) using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_abt_provide_yn mean percent_postabortion_yn) f(1) npos(col) sum append  h2("SA and PAC availability") show(none)
tabout sector if (facility_type2==1 | facility_type2==2 | facility_type2==4) using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_abt_provide_yn mean percent_postabortion_yn) f(1) npos(col) sum append  h2("SA and PAC availability") show(none)
tabout region if (facility_type2==1 | facility_type2==2 | facility_type2==4) using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_abt_provide_yn mean percent_postabortion_yn) f(1) npos(col) sum append  h2("SA and PAC availability") show(none)


*********************************************************
***   Medicines and equipment for safe abortion and PAC
*********************************************************	

*   Check completeness
mdesc miso_obs mife_obs se_mva_obs se_kit_dc_obs if abt_provide_yn==1 & (facility_type2==1 | facility_type2==2)
misstable pattern miso_obs mife_obs se_mva_obs se_kit_dc_obs if abt_provide_yn==1 & (facility_type2==1 | facility_type2==2), freq

*   Recode yes/no variables as percentages on scale of 0 to 100
foreach v of varlist se_mva_obs se_kit_dc_obs {
		recode `v' (1 = 100), gen(percent_`v')
	}

*   Meds and equipment (tabout)
tabout facility_type2 if abt_provide_yn==1 & (facility_type2==1 | facility_type2==2) using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_miso_obs mean percent_mife_obs mean percent_se_mva_obs mean percent_se_kit_dc_obs) f(1) npos(col) sum append  h2("SA/PAC meds and equipment") show(none)
tabout sector  if abt_provide_yn==1 & (facility_type2==1 | facility_type2==2) using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_miso_obs mean percent_mife_obs mean percent_se_mva_obs mean percent_se_kit_dc_obs) f(1) npos(col) sum append  h2("SA/PAC meds and equipment") show(none)
tabout region  if abt_provide_yn==1 & (facility_type2==1 | facility_type2==2) using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_miso_obs mean percent_mife_obs mean percent_se_mva_obs mean percent_se_kit_dc_obs) f(1) npos(col) sum append  h2("SA/PAC meds and equipment") show(none)


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

*   Recode yes/no variables as percentages on scale of 0 to 100
foreach v of varlist abt_mva_1mo abt_dc_1mo abt_ec_1mo abt_meds_1mo {
		recode `v' (1 = 100), gen(percent_`v')
	}

*   Meds and equipment (tabout)
tabout facility_type2 if abt_provide_yn==1 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_abt_mva_1mo mean percent_abt_dc_1mo mean percent_abt_ec_1mo mean percent_abt_meds_1mo) f(1) npos(col) sum append  h2("SAC functions") show(none)
tabout sector if abt_provide_yn==1 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_abt_mva_1mo mean percent_abt_dc_1mo mean percent_abt_ec_1mo mean percent_abt_meds_1mo) f(1) npos(col) sum append  h2("SAC functions") show(none)
tabout region if abt_provide_yn==1 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_abt_mva_1mo mean percent_abt_dc_1mo mean percent_abt_ec_1mo mean percent_abt_meds_1mo) f(1) npos(col) sum append  h2("SAC functions") show(none)


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

*   Recode yes/no variables as percentages on scale of 0 to 100
foreach v of varlist infantcare_yn immunization_yn lab_yn {
		recode `v' (1 = 100), gen(percent_`v')
	}

*   Availability of child health services (tabout)
tabout facility_type2 if facility_type2!=5 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_infantcare_yn mean percent_immunization_yn mean percent_lab_yn) f(1) npos(col) sum append  h2("Availability of child health services") show(none)
tabout sector if facility_type2!=5 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_infantcare_yn mean percent_immunization_yn mean percent_lab_yn) f(1) npos(col) sum append  h2("Availability of child health services") show(none)
tabout region if facility_type2!=5 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_infantcare_yn mean percent_immunization_yn mean percent_lab_yn) f(1) npos(col) sum append  h2("Availability of child health services") show(none)


*********************************************************
***   Availability of basic child vaccines
*********************************************************	

*   Check completeness
mdesc vax_prv vax_opv vax_measles vax_bcg vax_ipv vax_pcv vax_rota if immunization_yn==1
tab1 vax_prv vax_opv vax_measles vax_bcg vax_ipv vax_pcv vax_rota if immunization_yn==1

*   Drop variables
drop vax_opv_obs vax_bcg_obs percent_vax_opv_obs percent_vax_bcg_obs 
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


*   Recode yes/no variables as percentages on scale of 0 to 100
foreach v of varlist vax_prv_obs vax_opv_obs vax_measles_obs vaccine_3count vax_bcg_obs vax_ipv_obs vax_pcv_obs vax_rota_obs vaccine_7count {
		recode `v' (1 = 100), gen(percent_`v')
	}

*   Child vaccines(tabout)
tabout facility_type2 if immunization_yn==1 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_vax_prv_obs mean percent_vax_opv_obs mean percent_vax_measles_obs mean percent_vaccine_3count mean percent_vax_bcg_obs mean percent_vax_ipv_obs mean percent_vax_pcv_obs mean percent_vax_rota_obs mean percent_vaccine_7count) f(1) npos(col) sum append  h2("Child vaccines") show(none)
tabout sector if immunization_yn==1 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_vax_prv_obs mean percent_vax_opv_obs mean percent_vax_measles_obs mean percent_vaccine_3count mean percent_vax_bcg_obs mean percent_vax_ipv_obs mean percent_vax_pcv_obs mean percent_vax_rota_obs mean percent_vaccine_7count) f(1) npos(col) sum append  h2("Child vaccines") show(none)
tabout region if immunization_yn==1 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_vax_prv_obs mean percent_vax_opv_obs mean percent_vax_measles_obs mean percent_vaccine_3count mean percent_vax_bcg_obs mean percent_vax_ipv_obs mean percent_vax_pcv_obs mean percent_vax_rota_obs mean percent_vaccine_7count) f(1) npos(col) sum append  h2("Child vaccines") show(none)


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

*   Recode yes/no variables as percentages on scale of 0 to 100
foreach v of varlist imnci_2mo_obs imnci_5y_obs iccm_2mo_obs iccm_5y_obs {
		recode `v' (1 = 100), gen(percent_`v')
	}

*   Registration book (tabout)
tabout facility_type2 if (facility_type2==1 | facility_type2==2) & sector==0 & infantcare_yn==1 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_imnci_2mo_obs mean percent_imnci_5y_obs) f(1) npos(col) sum append  h2("IMNCI books") show(none)
tabout region if (facility_type2==1 | facility_type2==2) & sector==0 & infantcare_yn==1 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_imnci_2mo_obs mean percent_imnci_5y_obs) f(1) npos(col) sum append  h2("IMNCI books") show(none)

tabout facility_type2 if facility_type2==3  & sector==0  & infantcare_yn==1 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_iccm_2mo_obs mean percent_iccm_5y_obs) f(1) npos(col) sum append  h2("iCCM Books") show(none)
tabout region if facility_type2==3  & sector==0  & infantcare_yn==1 using "PMAET_2019SDP_Analysis_$date.xls", c(mean percent_iccm_2mo_obs mean percent_iccm_5y_obs) f(1) npos(col) sum append  h2("iCCM Books") show(none)


*   Save data
save PMAET_2019SDP_Analysis_PR_$date.dta, replace


log close


