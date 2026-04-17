# Lecture 09 Lecturer Notes

## Pacing

Target: one hour, including reflection.

- 10 min: who the CLI is for, the three-interfaces framing, and the five design principles (Part 1)
- 8 min: Rapp basics and the `switch("")` structure (Part 2)
- 30 min: guided build of the `pca` subcommand **inside the existing package** — `use_package("Rapp")`, `exec/ADS8192`, `install_ADS8192_cli()`, run, error-path check (Part 3)
- 7 min: the CLI-as-contract discussion (Part 4) and Package Milestone
- 5 min: reflection and hand-off to Lecture 10
- If time is tight, cut syntax repetition in Part 2 before cutting the audience/contract conversation. The `validate` subcommand has been moved to After-Class; do not teach it live.

## Non-Negotiable Points

- Not every project needs a CLI; the point is to recognize when automation users actually benefit from one.
- The CLI must stay a thin wrapper over package logic — it calls `run_pca()`, it does not reimplement PCA.
- The CLI lives **inside the package** (`exec/` + `DESCRIPTION` + `R/install_cli.R`) from the first keystroke; there is no "standalone script we package later" phase.
- Inputs, outputs, help text, and exit codes are part of the user contract.

## Worth Mentioning Briefly

- Implicit working-directory assumptions are a common source of fragile CLI behavior.
- Stable file formats are often more important than clever command structure.
- A CLI should feel boring and predictable to automation users.

## Safe Skips If Time Is Tight

- Do not over-explain every flag once the `pca` command is working end to end.
- Compress terminal syntax examples after the contract pattern is clear.
- The Rapp variable-mapping and Rapp-vs-other-packages reference tables have been removed from the lecture; do not re-introduce them live.
- Treat the "What's Breaking?" table as the core of Part 4; semver bullets can be read on students' own time.

## Common Misconceptions

- "A CLI is just another way to run the same code." Only if it stays DRY and thin.
- "Help text is documentation fluff." For CLI users, it is the interface.
- "Renaming flags later is harmless." Pipeline users often depend on those names.
