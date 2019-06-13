*****MERGING IBS_OUTPUTS WITH IBS_INPUTS*****

use "C:\Users\guyv\ownCloud\opalval\download\input\prepared_IO\IBS_outputs_prep.dta", clear

merge 1:1 firm_id year using C:\Users\guyv\ownCloud\opalval\download\input\prepared_IO\IBS_inputs_prep.dta, update
*option update for industry_code as only overlapping variable, firm_id_year being removed. Replaces missing values of same-named variables in master with values from using
rename _merge merge_codes_io

save C:/Users/guyv/ownCloud/opalval/download/output/IBSIO.dta, replace 


*****MERGING IBS WITH IBS_IO***** 
use "C:\Users\guyv\ownCloud\opalval\download\input\IBS_panel_pre_tfp.dta", clear
drop workers_total workers_prod workers_other export_dummy inv_tot fc_add elec_qty inv_tot_imp fc_add_imp kbli1 kbli2 elec_qty_imp2 workers_total_imp2 workers_prod_imp2 workers_other_imp2 workers_total_imp1 workers_prod_imp1 workers_other_imp1 elec_qty_imp1 elec_qty_imp3 materials_tot_imp3 fc_land_est_imp1 fc_est_tot_imp1co fc_est_tot_imp2co fc_est_tot_imp3co fc_est_tot_imp4co fc_est_tot_imp1cd fc_est_tot_imp2cd fc_est_tot_imp3cd fc_est_tot_imp4cd fc_est_tot_imp5co fc_est_tot_imp5cd fc_est_tot_imp6co fc_est_tot_imp6cd fc_est_tot_imp7co fc_est_tot_imp7cd fc_est_tot_imp8co fc_est_tot_imp8cd fc_est_tot_imp9co fc_est_tot_imp10co fc_est_tot_imp11co elec_qty_ln workers_total_ln workers_prod_ln workers_other_ln elec_qty_imp1_ln workers_total_imp1_ln workers_prod_imp1_ln workers_other_imp1_ln elec_qty_imp2_ln workers_total_imp2_ln workers_prod_imp2_ln workers_other_imp2_ln workers_total_imp3_ln workers_prod_imp3_ln workers_other_imp3_ln elec_qty_imp3_ln fc_est_tot_imp1co_ln fc_est_tot_imp1cd_ln fc_est_tot_imp2co_ln fc_est_tot_imp2cd_ln fc_est_tot_imp3co_ln fc_est_tot_imp3cd_ln fc_est_tot_imp4co_ln fc_est_tot_imp4cd_ln fc_est_tot_imp5co_ln fc_est_tot_imp5cd_ln fc_est_tot_imp6co_ln fc_est_tot_imp6cd_ln fc_est_tot_imp7co_ln fc_est_tot_imp7cd_ln fc_est_tot_imp8co_ln fc_est_tot_imp8cd_ln fc_est_tot_imp9co_ln fc_est_tot_imp10co_ln fc_est_tot_imp11co_ln fc_add_ln inv_tot_ln fc_add_imp_ln inv_tot_imp_ln fc_land_est_imp1_ln
gen palm_oil = 1 if (industry_code == 10431 | industry_code==15141 | industry_code==31151 | industry_code==10432 | industry_code==15144 | industry_code==31154) & year >1997
*We add refining industry_code, just to see what we get. 
keep if palm_oil ==1
drop palm_oil 
sort firm_id year

merge 1:1 firm_id year using C:\Users\guyv\ownCloud\opalval\download\output\IBSIO.dta, update

save C:/Users/guyv/ownCloud/opalval/download/output/IBS_1998.dta, replace 
save C:/Users/guyv/ownCloud/opalval/build/input/IBS_1998.dta, replace
saveold C:/Users/guyv/desktop/IBS_1998old, version(12) replace
