*===============================================================================
* master.do - REPRODUCIBLE STATA WORD TABLES
*
* WHAT THIS DOES: edit the PARAMETERS block, run this file, and every table
* regenerates into one Microsoft Word document.
*
* NEEDS: Stata 18 or newer. Run from the repository root, or replace the
*        project_dir setting with the full path to your copy of the repository.
*        No community-contributed packages and no internet connection.
*
* MAKES: data/synthetic_study.dta         - regenerated synthetic input
*        output/stata_word_tables.docx     - Tables 1-3 in Microsoft Word
*        logs/stata_word_tables_run.log    - full Stata run log
*        logs/verification_receipt.txt    - short parameter and check receipt
*
* DEMO: change category_cut from 2 to 3. Run the whole file again. The group
* columns and model terms update together across all three tables.
*
* Last updated: 2026-08-25
*===============================================================================
version 18
clear all
set more off

**# PARAMETERS - THE ONLY SECTION TO EDIT --------------------------------------

* Use "." when Stata starts in the repository root. Otherwise paste the full
* repository path between the quotes. Forward slashes work on macOS and Windows.
local project_dir       "."

local category_cut      2
    // 2 = categories 0, 1, 2+
    // 3 = categories 0, 1, 2, 3+

local apply_exclusion   1
    // 1 = remove synthetic records flagged for exclusion
    // 0 = keep every synthetic record

local model_outcome     outcome_log
    // Outcome used in the primary regression table

local covariates        age_years i.group_indicator i.exposure_group
    // Adjustment variables used in both regression tables

local cluster_variable  cluster_id
    // Variable used for cluster-robust standard errors

local random_seed       20260822
    // Holds the synthetic dataset constant across repeated runs

*-------------------------------------------------------------------------------

cd `"`project_dir'"'
capture mkdir data
capture mkdir output
capture mkdir logs

* Regenerate the synthetic source every time so the full demo is reproducible.
do "do/make_synthetic_data.do" `"`project_dir'"' "`random_seed'"

capture log close
log using "logs/stata_word_tables_run.log", text replace

**# Validate parameters before analysis ----------------------------------------

* Explicit if-checks rather than -assert-: no data are in memory yet, and
* -assert- is satisfied vacuously when _N is zero.
if !inlist(`category_cut', 1, 2, 3, 4, 5) {
    display as error "category_cut must be an integer from 1 to 5. Current value: `category_cut'."
    error 198
}
if !inlist(`apply_exclusion', 0, 1) {
    display as error "apply_exclusion must be 0 or 1. Current value: `apply_exclusion'."
    error 198
}

display as text "REPORT PARAMETERS"
display as text "  category_cut      = `category_cut'"
display as text "  apply_exclusion   = `apply_exclusion'"
display as text "  model_outcome     = `model_outcome'"
display as text "  covariates        = `covariates'"
display as text "  cluster_variable  = `cluster_variable'"
display as text "  random_seed       = `random_seed'"

use "data/synthetic_study.dta", clear
isid participant_id

confirm numeric variable `model_outcome'
confirm numeric variable `cluster_variable'
assert !missing(`model_outcome', `cluster_variable')

**# Apply the parameters once --------------------------------------------------

recode burden_count (`category_cut'/max = `category_cut'), ///
    generate(burden_category)

capture label drop burdenlabel
forvalues category = 0/`category_cut' {
    if `category' == `category_cut' {
        label define burdenlabel `category' "`category'+", add
    }
    else {
        label define burdenlabel `category' "`category'", add
    }
}
label values burden_category burdenlabel
label variable burden_category "Burden category"

if `apply_exclusion' {
    drop if exclusion_flag
}

assert _N > 0
assert inrange(burden_category, 0, `category_cut')

count if burden_category == `category_cut'
local top_category_n = r(N)
assert `top_category_n' > 0

local analysis_n = _N
display as result "VERIFIED: analysis sample N = `analysis_n'"
display as result "VERIFIED: top category (`category_cut'+) N = " ///
    `top_category_n'
display as result "VERIFIED: parameter and data assertions passed."

**# Begin the Word document ----------------------------------------------------

putdocx clear
putdocx begin, pagesize(letter) margin(top, 1) margin(bottom, 1) ///
    margin(left, 1) margin(right, 1) font("Arial", 10)

putdocx paragraph, style(Title)
putdocx text ("Reproducible Stata Word Tables: demo")

putdocx paragraph
putdocx text ("Synthetic data only. "), bold
putdocx text ("Every table below was regenerated from one parameter block. ")
putdocx text ("category_cut = `category_cut'; ")
putdocx text ("exclusions applied = `apply_exclusion'; ")
putdocx text ("analysis N = `analysis_n'.")

**# Table 1: sample characteristics --------------------------------------------

dtable age_years i.group_indicator i.exposure_group outcome_score, ///
    by(burden_category) ///
    continuous(, statistics(mean sd)) ///
    factor(, statistics(fvpercent fvfrequency)) ///
    nformat(%4.2f mean sd fvpercent) ///
    nformat(%4.0f fvfrequency) ///
    sformat("(%s)" sd fvfrequency) ///
    sformat("%s%%" fvpercent) ///
    title(Table 1. Sample characteristics by burden category) ///
    nosample
collect style putdocx, width(100%) layout(autofitcontents) halign(center)
putdocx collect

**# Table 2: primary model ------------------------------------------------------

putdocx pagebreak
regress `model_outcome' i.burden_category `covariates', ///
    vce(cluster `cluster_variable')
matrix primary_results = r(table)

etable, title(Table 2. Primary model) column(dvlabel) ///
    cstat(_r_b, nformat(%4.2f)) ///
    cstat(_r_ci, nformat(%4.2f) sformat("[%s]") cidelimiter(", ")) ///
    cstat(_r_p, nformat(%5.3f)) ///
    note(Bold p-values indicate p < 0.05.) ///
    mstat(N)

collect style cell result[_r_p], minimum(0.001, label("<0.001"))
local primary_columns : colnames primary_results
foreach column of local primary_columns {
    scalar pvalue = primary_results[rownumb(primary_results, "pvalue"), ///
        colnumb(primary_results, "`column'")]
    if !missing(pvalue) & pvalue < 0.05 {
        collect style cell result[_r_p]#colname[`column'], font(, bold)
    }
}
collect style putdocx, width(75%) layout(autofitcontents) halign(center)
putdocx collect

**# Table 3: secondary model ----------------------------------------------------

putdocx pagebreak
regress outcome_score i.burden_category `covariates', ///
    vce(cluster `cluster_variable')
matrix secondary_results = r(table)

etable, title(Table 3. Secondary model: untransformed outcome) ///
    column(dvlabel) ///
    cstat(_r_b, nformat(%4.2f)) ///
    cstat(_r_ci, nformat(%4.2f) sformat("[%s]") cidelimiter(", ")) ///
    cstat(_r_p, nformat(%5.3f)) ///
    note(Bold p-values indicate p < 0.05.) ///
    mstat(N)

collect style cell result[_r_p], minimum(0.001, label("<0.001"))
local secondary_columns : colnames secondary_results
foreach column of local secondary_columns {
    scalar pvalue = secondary_results[rownumb(secondary_results, "pvalue"), ///
        colnumb(secondary_results, "`column'")]
    if !missing(pvalue) & pvalue < 0.05 {
        collect style cell result[_r_p]#colname[`column'], font(, bold)
    }
}
collect style putdocx, width(75%) layout(autofitcontents) halign(center)
putdocx collect

**# Save the document and write the short receipt -------------------------------

putdocx save "output/stata_word_tables.docx", replace
confirm file "output/stata_word_tables.docx"

file open receipt using "logs/verification_receipt.txt", ///
    write text replace
file write receipt "REPRODUCIBLE STATA WORD TABLES - VERIFICATION RECEIPT" _n
file write receipt "Synthetic data only" _n
file write receipt "random_seed=`random_seed'" _n
file write receipt "category_cut=`category_cut'" _n
file write receipt "apply_exclusion=`apply_exclusion'" _n
file write receipt "analysis_n=`analysis_n'" _n
file write receipt "top_category_n=`top_category_n'" _n
file write receipt "assertions=PASSED" _n
file write receipt "word_document=output/stata_word_tables.docx" _n
file close receipt

display as result "VERIFIED: output/stata_word_tables.docx written."
display as result "VERIFIED: logs/verification_receipt.txt written."
display as result "REPORT BUILD COMPLETE."

log close
clear
