/* Giving clean geographic information for all observations 1998-2015 has been done in IBS_1998_cleaned.do, 
This script makes several subsampling for different purposes. 
*/
* We want to have the first year for all mills, even those that appeared before we have economic information on them (i.e. before 1998). 
* /// MAY BE WE SHOULD USE ANOTHER DATASET THAN FINAL_PANEL? \\\
* keep the oldest year for all IBS firms that existed before 1998. 
use  "C:\Users\guyv\ownCloud\opal (2)\build\output\IBS_final_panel.dta", clear
keep firm_id year 
keep if year < 1998
bys firm_id (year): egen min_year = min(year)
keep if year == min_year 
* among these old firms, keep only palm oil mills. 
merge 1:m firm_id using "C:\Users\guyv\ownCloud\opalval\build\output\IBS_1998_cleaned.dta", generate(merge_mill_id) keepusing(firm_id year)
keep if merge_mill_id == 3 
drop merge_mill_id min_year
duplicates drop firm_id year, force 
* reintroduce the mill dataset, and now compute the min year. 
append using "C:\Users\guyv\ownCloud\opalval\build\output\IBS_1998_cleaned.dta"
sort firm_id year
order year, after(firm_id)
bys firm_id (year): egen min_year = min(year)
bys firm_id (year): egen max_year = max(year)
order max_year, after(year)
order min_year, after(year)

******************************************************************************************************************************
***** Prepare manual matching sheet ******************************************************************************************************
/* Keep only those mills that we want to match manually
These are the 59 mills (out of 972 distinct ones before 2011) that had not been sent to spatial join in R because 
*all* their annual observations were originally mi(desa_id) or flagged for misreporting desa_id in a split. 
PLUS the *76* mills that could actually not be matched to a desa polygon with their desa_id.   
*/
sort firm_id year 
drop if year < 1998
*this will be useful to filter only obs. with no invalid desa_id that are appearing before 2011 (and excluding those that appeared before 1998 and come back wierdly after 2010)
bys firm_id (year): egen min_year2 = min(year)
** those with no annual valid desa_id observation (59 mills)
g valid_desa_id = (!mi(desa_id))
bys firm_id (year) : egen any_valid_desa_id_2 = total(valid_desa_id) 

codebook firm_id if any_valid_desa_id_2 == 0 & min_year2 < 2011 
/*
browse firm_id year desa_id valid_desa_id any_valid_desa_id if any_valid_desa_id == 0 
sum max_year if any_valid_desa_id == 0
browse firm_id year any_valid_desa_id
*/
** and those with at least one valid desa_id obs. but that were matched to no desa polygon. 
merge m:1 firm_id using "C:\Users\guyv\ownCloud\opalval\build\temp\mill_geolocalization\pre2011_bad_desa_id.dta", generate(merge_baddesa) keepusing(firm_id)
codebook year if merge_baddesa == 3

keep if (any_valid_desa_id_2 == 0 & min_year2 < 2011 ) | merge_baddesa == 3 
* there remains 135 mills with 671 obs. 
codebook firm_id 

rename kec_name subdistrict_name 
keep firm_id year min_year max_year workers_total_imp3 district_name subdistrict_name village_name
order district_name, before(subdistrict_name)
gen mill_name = ""
gen double latitude = . 
gen double longitude = .
sort firm_id year
export excel using "C:\Users\guyv\ownCloud\opalval\build\temp\mill_geolocalization\mills_to_georeference_pre2011.xls", firstrow(variables) replace
******************************************************************************************************************************
******************************************************************************************************************************




******************************************************************************************************************************
***** Prepare noto sheet ******************************************************************************************************
merge m:m firm_id using "C:\Users\guyv\ownCloud\opalval\build\temp\mill_geolocalization\noto.dta", generate(merge_noto)

bys firm_id (year): egen min_year = min(year)
*drop if workers_total_imp3 >=. 
keep if merge_noto == 3 
keep firm_id year desa_id workers_total_imp3 min_year est_year parent_co mill_name lat lon grp  
order grp, before(firm_id)
sort grp firm_id year 

export excel using "C:\Users\guyv\ownCloud\opalval\build\temp\mill_geolocalization\noto.xls", firstrow(variables) replace
******************************************************************************************************************************
******************************************************************************************************************************










