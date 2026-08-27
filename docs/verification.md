# Verification record

This page records what I tested. I verified the project locally on 2026-08-22 and reran it after the 2026-08-24 name change, using StataNow/MP 19.5. On 2026-08-27 I reran both passes and refreshed the shipped logs after hardening the failure paths, so they show the current checks in `do/master.do`: the wrong-folder check, the stale-file guard, and the model sample-size assertions. Both do-files pin `version 18`, and the project uses only commands available in Stata 18.

## Baseline run

Command, run from the repository root:

```shell
/Applications/StataNow/StataMP.app/Contents/MacOS/stata-mp -b do do/master.do
```

Stata batch mode writes its command output to logs rather than standard output. The run produced this receipt:

```text
REPRODUCIBLE STATA WORD TABLES - VERIFICATION RECEIPT
Synthetic data only
random_seed=20260822
category_cut=2
apply_exclusion=1
model_outcome=outcome_log
covariates=age_years i.group_indicator i.exposure_group
cluster_variable=cluster_id
analysis_n=373
top_category_n=182
assertions=PASSED
word_document=output/stata_word_tables.docx
```

The full run ended with:

```text
VERIFIED: output/stata_word_tables.docx written.
VERIFIED: logs/verification_receipt.txt written.
REPORT BUILD COMPLETE.
```

## One-parameter-change run

The only code change was:

```diff
-local category_cut      2
+local category_cut      3
```

I reran the same batch command, which produced this receipt:

```text
REPRODUCIBLE STATA WORD TABLES - VERIFICATION RECEIPT
Synthetic data only
random_seed=20260822
category_cut=3
apply_exclusion=1
model_outcome=outcome_log
covariates=age_years i.group_indicator i.exposure_group
cluster_variable=cluster_id
analysis_n=373
top_category_n=85
assertions=PASSED
word_document=output/stata_word_tables.docx
```

I confirmed the propagation by inspecting the full log and the rendered tables. Table 1's columns became 0, 1, 2, 3+, and Total, and the burden terms in both model tables became 1, 2, and 3+. The run again ended with `REPORT BUILD COMPLETE.`

After preserving both example outputs, I restored the tracked source to the default `category_cut = 2`.

## Word render review

I converted both Word files to page images with a LibreOffice-based document renderer. Each document rendered to three pages, and I inspected all six at full resolution. I found no clipped text, overlap, broken tables, missing glyphs, or bad page breaks. The default and changed Table 1 pages are included under `docs/images/`.

## What this verification covers

The batch runs above produced the two Word examples, their logs, their receipts, and the synthetic dataset. I regenerated both Word files after the project name changed. Afterward I made one edit to the shipped logs, replacing local absolute paths with `REPOSITORY_ROOT`, and changed nothing else in them.
