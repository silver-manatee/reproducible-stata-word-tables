# Extend the project

## First decide which kind of change you have

**Parameter change:** the do-file already knows how to make the requested result, such as a different category cut, exclusion toggle, outcome, covariate list, or clustering variable. Change one setting and rerun the whole file.

**Structural change:** the do-file doesn't yet know how to make the requested result, such as a new table, a new model family, a different confidence-interval format, or a recurring choice that's still hardcoded. Revise the machinery, then test it on synthetic data.

**Statistical decision:** a choice about what analysis is scientifically appropriate. The statistician owns this. A programmer or AI assistant should implement the requested model, not silently choose it.

## A safe extension loop

1. Preserve the last verified `do/master.do`, Word output, and run log.
2. Describe the requested change and what must stay unchanged.
3. Ask for a short implementation plan before any edit.
4. Make the smallest code change that can satisfy the request.
5. Use only synthetic or approved de-identified data during development.
6. Run the complete do-file in Stata. Don't test only the changed lines.
7. Review the first Stata error, the analysis sample, the estimates, the table layout, and the log.
8. If the choice will recur, expose it as a labeled parameter instead of leaving it hardcoded.
9. Update the README or this guide when the expected inputs, outputs, or test change.

## What to give an AI assistant

Attach:

- `do/master.do`
- the latest `logs/stata_word_tables_run.log`
- a synthetic data dictionary or a small synthetic dataset
- a table shell or screenshot showing the requested structure

Don't attach confidential datasets, unpublished study logic, direct identifiers, credentials, or restricted manuscript material.

## Prompt patterns

### Add a recurring variable choice

> I need to switch between `[variable A]` and `[variable B]` across every relevant table and model. Add one clearly labeled parameter near the top of `do/master.do`. Identify every downstream use. Add a log line showing the active choice. Do not change any other model or format. Give me a test for both settings before editing.

### Add a table

> Add a new table with `[rows]`, `[columns]`, and `[statistics]`. Use the same formatting conventions as the existing tables. Build and test it with synthetic data. Keep the current tables unchanged. Add a visible verification line to the log. Explain the plan before editing.

### Change table formatting

> Change confidence intervals from `[lower, upper]` to `(lower to upper)` in every model table. Do not change estimates, model specifications, p-values, or significance rules. After editing, rerun the full file and describe a focused formatting check that is separate from statistical validation.

### Diagnose a failed run

> Here are `do/master.do` and the latest log. Find the first actual Stata error. Explain its cause in plain language. Propose the smallest fix and no unrelated changes. Tell me the exact full-run command and the output that confirms the repair.

## Verification checklist

- The synthetic-data assertions pass.
- The parameter values printed in the log match the requested run.
- The analysis sample is plausible and nonzero.
- The complete do-file ends with `REPORT BUILD COMPLETE.`
- The current run replaced `output/stata_word_tables.docx` with a fresh copy.
- Every affected table reflects the change.
- Unaffected estimates and formatting remain unchanged.
- The statistician reviews the model and table values. A polished Word document is not statistical validation.
