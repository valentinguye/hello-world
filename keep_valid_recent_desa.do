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

*keep valid and most recent mills
g valid_desa_id = (!mi(desa_id))
codebook firm_id if valid_desa_id == 1

by firm_id: egen most_recent_vld = max(year) if valid_desa_id == 1 

g polygon_4match = (valid_desa_id == 1 & year == most_recent_vld)

keep if polygon_4match == 1 

destring desa_id, replace

keep firm_id year min_year max_year desa_id prov_name district_name kec_name village_name workers_total_imp3 /// 
in_ton_ffb_imp1 in_ton_ffb_imp2 out_ton_cpo_imp1 out_ton_cpo_imp2 out_ton_pko_imp1 out_ton_pko_imp2 out_ton_rpo_imp1 out_ton_rpo_imp2 out_ton_rpko_imp1 out_ton_rpko_imp2  


/*recast float firm_id year workers_total_imp3 /// 
in_ton_ffb_imp1 in_ton_ffb_imp2 out_ton_cpo_imp1 out_ton_cpo_imp2 out_ton_pko_imp1 out_ton_pko_imp2 out_ton_rpo_imp1 out_ton_rpo_imp2 out_ton_rpko_imp1 out_ton_rpko_imp2, force 
 */
sort firm_id year

save "C:\Users\guyv\ownCloud\opalval\build\temp\mill_geolocalization\IBSmills_valid_desa.dta", replace

