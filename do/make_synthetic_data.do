*===============================================================================
* make_synthetic_data.do - BUILD THE DEMO DATASET
*
* WHAT THIS DOES: creates a deterministic, fully synthetic study dataset.
*
* NEEDS: Stata 18 or newer. No community-contributed packages.
*        Called by do/master.do with the project folder and random seed.
*
* MAKES: data/synthetic_study.dta - 400 synthetic participant records
*        logs/synthetic_data.log  - receipt for the data-generation run
*
* PRIVACY: every value is simulated. No person or study is represented.
*
* Last updated: 2026-08-22
*===============================================================================
version 18
clear
set more off

args project_dir random_seed

if `"`project_dir'"' == "" {
    local project_dir "."
}

if `"`random_seed'"' == "" {
    local random_seed 20260822
}

cd `"`project_dir'"'
capture mkdir data
capture mkdir logs

capture log close
log using "logs/synthetic_data.log", text replace

display as text "Synthetic-data seed: `random_seed'"
set seed `random_seed'
set obs 400

generate int participant_id = _n
label variable participant_id "Participant ID (synthetic)"

generate byte cluster_id = 1 + floor(runiform() * 8)
label variable cluster_id "Study cluster (synthetic)"

generate double age_years = round(rnormal(50, 12), 1)
replace age_years = 18 if age_years < 18
replace age_years = 85 if age_years > 85
label variable age_years "Age, years"

generate byte group_indicator = runiform() < 0.52
label define grouplabel 0 "Group A" 1 "Group B"
label values group_indicator grouplabel
label variable group_indicator "Study group"

generate byte exposure_group = 1 + floor(runiform() * 3)
label define exposurelabel 1 "Low" 2 "Moderate" 3 "High"
label values exposure_group exposurelabel
label variable exposure_group "Exposure group"

generate byte burden_count = min(rpoisson(1.6), 6)
label variable burden_count "Synthetic burden count"

generate byte exclusion_flag = runiform() < 0.06
label variable exclusion_flag "Meets synthetic exclusion rule"

generate double outcome_score = exp(1.25 + 0.11 * burden_count + ///
    0.006 * age_years + 0.08 * group_indicator + ///
    0.05 * (exposure_group == 3) + rnormal(0, 0.35))
label variable outcome_score "Synthetic outcome score"

generate double outcome_log = ln(outcome_score)
label variable outcome_log "Log synthetic outcome score"

isid participant_id
assert _N == 400
assert inrange(age_years, 18, 85)
assert inrange(burden_count, 0, 6)
assert !missing(cluster_id, age_years, group_indicator, exposure_group)
assert !missing(burden_count, exclusion_flag, outcome_score, outcome_log)

compress
save "data/synthetic_study.dta", replace

display as result "VERIFIED: data/synthetic_study.dta written. N = " _N
display as result "VERIFIED: all synthetic-data assertions passed."
log close
clear
