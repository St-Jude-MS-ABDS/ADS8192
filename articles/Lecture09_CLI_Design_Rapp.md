# Lecture 9: Lab – CLI Tool Development (R) – CLI Design and Rapp Basics

## Motivation

Scientific software often needs to run without a human at the keyboard.
A command-line interface (CLI) makes your analysis tool usable in
pipelines, schedulers, shared compute environments, and repeatable
scripts.

A good CLI forces you to make the interface contract explicit: inputs,
outputs, defaults, and error behavior all become visible. That clarity
saves time for automation users and reduces drift between the command
line and the underlying package logic.

### Learning Objectives

By the end of this session, you will be able to:

1.  Add a Rapp-based CLI directly to your existing package
2.  Write usage/help text and define clear inputs/outputs for commands
3.  Test CLI functionality from the terminal and interpret exit behavior
4.  Decide when a CLI is worth adding and keep it a thin wrapper over
    package logic

### Scientific Use Case

A bioinformatics core wants to run your analysis across 40 cohorts in a
nightly workflow. They do not want a web app and they do not want to
source R files by hand. The CLI is the interface that lets them treat
your package as a reliable step in an automated pipeline.

------------------------------------------------------------------------

## Why Build a CLI?

We’ve already shown how to build two interfaces around the package core:

- **R API**: for users working interactively in R
- **Shiny app**: for point-and-click exploration

The CLI adds a third:

- **CLI**: for pipeline integration and non-interactive use

``` bash
# Typical pipeline use
ADS8192 pca --counts counts.tsv --meta samples.tsv --output results/
```

Benefits: pipeline integration (Snakemake, Nextflow, etc),
scriptability, reproducibility, and no IDE required on servers or
clusters.

### When Should You Add a CLI?

Add a CLI when users need automation, batch execution, scheduler
integration, or a stable entry point from another language or workflow
manager. Do not add one just because a terminal interface looks
advanced. A CLI is worthwhile when it exposes a clear contract around
existing package logic.

------------------------------------------------------------------------

## Part 1: CLI Design Principles

A good CLI behaves predictably under automation. Five principles keep it
that way.

#### 1. Clear Help Text

Help text *is* the interface for CLI users. Make it complete enough that
someone can use the tool without reading your R docs.

``` bash
$ ADS8192 pca --help

Usage: ADS8192 pca [OPTIONS]

Run PCA on a SummarizedExperiment and export results.

Options:
  --counts FILE       Path to counts matrix (TSV/CSV) [required]
  --meta FILE         Path to sample metadata (TSV/CSV) [required]
  --output DIR        Output directory [required]
  --n-top INT         Number of top variable genes [default: 500]
  --log-transform     Log-transform counts [default: true]
  --color-by COL      Metadata column for plot coloring
  -h, --help          Show this message and exit
```

#### 2. Explicit Inputs and Outputs

Use flags for data paths; do not read data from stdin or write data to
stdout. Reserve stdout/stderr for messages.

``` bash
# Good: explicit file arguments
ADS8192 pca --counts data.tsv --output results/

# Bad: implicit stdin/stdout for data
cat data.tsv | ADS8192 pca > results.tsv
```

#### 3. Reproducible Defaults

Document every default in help text. Same inputs should produce the same
outputs across runs.

#### 4. Meaningful Exit Codes

A non-zero exit code is how pipelines know something failed. Let errors
fail loudly, and return zero only on success.

| Code | Meaning           |
|------|-------------------|
| 0    | Success           |
| 1    | General error     |
| 2    | Invalid arguments |

#### 5. Machine-Readable Outputs

TSV for tabular data, JSON for structured output. Avoid clever
formatting that a script would have to parse around.

------------------------------------------------------------------------

## Part 2: Introduction to Rapp

### What is Rapp?

**Rapp** (R application) is a lightweight framework for building
command-line tools in R. It provides argument parsing, type coercion,
help text generation (including `--help-yaml`), subcommand support, and
a clean path from script to CLI.

### Installation

``` r
install.packages("Rapp")
```

### How Rapp Declares a CLI

Rapp infers CLI structure from normal R code:

- `n_top <- 500L` becomes `--n-top 500`
- `log_transform <- TRUE` becomes `--log-transform` /
  `--no-log-transform`
- `counts <- ""` becomes `--counts VALUE`
- `switch("", cmd1 = { ... }, cmd2 = { ... })` declares subcommands

You can add help metadata using `#|` annotations:

``` r
#| description: Number of top variable genes
#| short: n
n_top <- 500L
```

**Key rule:** snake_case variable names automatically become kebab-case
flags (`n_top` → `--n-top`). Do not rename variables to shape the flag
name — pick the variable name and the flag follows.

### Rapp Script Structure

A complete Rapp script has this overall shape:

``` r
#!/usr/bin/env Rapp         # Shebang marking this a Rapp executable
#| name: ADS8192            # CLI name (shown in --help)
#| title: ADS8192 PCA Tool
#| description: PCA analysis for SummarizedExperiment data.

# Load packages explicitly (runs before any command)
suppressPackageStartupMessages({
    library(ADS8192)
    library(utils)
    library(stats)
})

# Optional helpers not exposed as CLI args
read_data_file <- function(path) { ... }

switch(
    "",           # Rapp substitutes the subcommand name at runtime

    #| title: Run PCA analysis
    #| description: Run PCA on counts + metadata, export results.
    pca = {
        #| description: Input file path
        counts <- ""

        #| description: Number of features
        n_top <- 500L

        # Command logic here
    }
)
```

Key structural points:

- **`switch("")`** is the Rapp idiom for declaring subcommands; Rapp
  substitutes the subcommand name at runtime.
- **Variable declarations inside each case** become that subcommand’s
  CLI arguments.
- **`#|` annotations** are YAML-parsed by Rapp and provide help text and
  short flags.
- **Type coercion** is automatic: `500L` → integer, `TRUE` → logical,
  `""` → character.

------------------------------------------------------------------------

## Part 3: Add the CLI to Your Package

You already have a package — the ADS8192 package you built in Lectures
5–8. The CLI lives inside that package from the start. No separate
script directory, no “move it in later” step.

### Step 1: Declare Rapp as a Dependency

From the package root, in R:

``` r
usethis::use_package("Rapp")
```

This adds `Rapp` to `DESCRIPTION` under `Imports:`.

### Step 2: Create the Rapp App in `exec/`

Rapp CLI apps live in the package’s top-level `exec/` directory. Files
in `exec/` are installed with the package, so the CLI travels with it.

``` r
dir.create("exec")
```

Now create `exec/ADS8192` — the full Rapp script. Two things about this
file matter before you write anything else:

- **Explicit namespacing.** Even with
  [`library(ADS8192)`](https://github.com/St-Jude-MS-ABDS/ADS8192), the
  Rapp script runs in a minimal environment. Load base-R helper packages
  explicitly at the top
  ([`library(utils)`](https://rdrr.io/r/base/library.html),
  [`library(stats)`](https://rdrr.io/r/base/library.html)), and use
  [`utils::write.table()`](https://rdrr.io/r/utils/write.table.html) /
  [`utils::read.table()`](https://rdrr.io/r/utils/read.table.html) in
  the body.
- **Trailing newline required.** Rapp needs `exec/ADS8192` to end with a
  blank line. Most editors handle this by default — just verify. Without
  it, Rapp may fail to parse the last command.

Write the header and shared helpers first:

``` r
# exec/ADS8192 — header and helpers
#!/usr/bin/env Rapp
#| name: ADS8192
#| title: ADS8192 PCA Tool
#| description: PCA analysis for SummarizedExperiment data.

suppressPackageStartupMessages({
    library(ADS8192)
    library(utils)
    library(stats)
})

# Helper to read TSV/CSV (not exported; kept in CLI script)
read_data_file <- function(path) {
    ext <- tolower(tools::file_ext(path))
    if (ext == "csv") {
        utils::read.csv(path, row.names = 1, check.names = FALSE)
    } else {
        utils::read.table(path, sep = "\t", header = TRUE, row.names = 1,
                          check.names = FALSE)
    }
}
```

### Step 3: Add the `pca` Subcommand

The `pca` subcommand declares its arguments as R variables, validates
inputs, reads files, calls the **package core functions**, and writes
output:

``` r
switch(
    "",

    #| title: Run PCA analysis
    #| description: Run PCA on a counts matrix and sample metadata, export results.
    pca = {
        #| description: Path to counts matrix (TSV/CSV, genes x samples)
        #| short: c
        counts <- ""

        #| description: Path to sample metadata (TSV/CSV)
        #| short: m
        meta <- ""

        #| description: Output directory
        #| short: o
        output <- ""

        #| description: Number of top variable genes
        #| short: n
        n_top <- 500L

        #| description: Log-transform counts
        log_transform <- TRUE

        #| description: Metadata column for plot coloring (optional)
        color_by <- ""

        # Validation
        if (counts == "" || meta == "" || output == "") {
            stop("--counts, --meta, and --output are required", call. = FALSE)
        }
        if (!file.exists(counts)) stop("File not found: ", counts, call. = FALSE)
        if (!file.exists(meta))   stop("File not found: ", meta, call. = FALSE)

        if (!dir.exists(output)) dir.create(output, recursive = TRUE)

        counts_df <- read_data_file(counts)
        meta_df   <- read_data_file(meta)

        se <- SummarizedExperiment::SummarizedExperiment(
            assays  = list(counts = as.matrix(counts_df)),
            colData = meta_df
        )
        result <- run_pca(se, n_top = n_top, log_transform = log_transform)

        save_pca_results(result, output)

        if (color_by != "") {
            plot_file <- file.path(output, "pca_plot.png")
            p <- plot_pca(result, color_by = color_by)
            ggplot2::ggsave(plot_file, p, width = 8, height = 6, dpi = 150)
            message("Saved: ", plot_file)
        }

        message("Done.")
    }
)
```

Note how thin this is: the CLI reads files, builds an SE, calls
[`run_pca()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_pca.md)
and
[`plot_pca()`](https://st-jude-ms-abds.github.io/ADS8192/reference/plot_pca.md)
from the package, and writes output. No analysis logic lives in the CLI
script.

**DRY check:** the CLI calls
[`run_pca()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_pca.md)
and
[`plot_pca()`](https://st-jude-ms-abds.github.io/ADS8192/reference/plot_pca.md)
— it does not call [`prcomp()`](https://rdrr.io/r/stats/prcomp.html)
directly. If you find yourself duplicating analysis logic here, move it
into the package and call it from both places.

### Step 4: Export a Launcher Installer

Running `Rapp exec/ADS8192 pca --help` works during development, but
after a user installs your package, the `exec/` directory lives inside
the R library tree. Rapp solves this with **launchers** — lightweight
shell scripts (`.bat` on Windows) that live on `PATH` and forward to the
installed Rapp app.

Create `R/install_cli.R`:

``` r
#' Install ADS8192 CLI launchers
#'
#' Places lightweight launcher scripts on the user's `PATH` so the
#' ADS8192 CLI can be invoked directly from a terminal
#' (e.g. `ADS8192 pca --help`).
#'
#' @inheritDotParams Rapp::install_pkg_cli_apps -package -lib.loc
#' @export
install_ADS8192_cli <- function(...) {
    Rapp::install_pkg_cli_apps(package = "ADS8192", lib.loc = NULL, ...)
}
```

Then `devtools::document()` to generate the Rd and export entry. Users
will later run:

``` r
remotes::install_github("you/ADS8192")
ADS8192::install_ADS8192_cli()
```

…and then invoke the CLI directly from a terminal. Installation
logistics are the focus of Lecture 10.

### Step 5: Run It and Check Errors

During development, run the CLI directly via `Rapp` (launchers come in
Lecture 10):

``` bash
# Show top-level and subcommand help
Rapp exec/ADS8192 --help
Rapp exec/ADS8192 pca --help
```

Create tiny test inputs from R so your command has something to chew on:

``` r
dir.create("tests/testdata", recursive = TRUE, showWarnings = FALSE)

counts <- data.frame(
    sample1 = c(100L, 50L, 200L, 30L, 80L),
    sample2 = c(150L, 75L, 180L, 45L, 100L),
    sample3 = c(120L, 60L, 210L, 35L, 90L),
    sample4 = c(180L, 90L, 240L, 55L, 110L),
    row.names = paste0("gene", 1:5)
)
utils::write.table(counts, "tests/testdata/counts.tsv",
                   sep = "\t", quote = FALSE)

meta <- data.frame(
    treatment = c("control", "control", "treated", "treated"),
    batch     = c("A", "B", "A", "B"),
    row.names = paste0("sample", 1:4)
)
utils::write.table(meta, "tests/testdata/meta.tsv",
                   sep = "\t", quote = FALSE)
```

Happy path:

``` bash
Rapp exec/ADS8192 pca \
    --counts tests/testdata/counts.tsv \
    --meta tests/testdata/meta.tsv \
    --output tests/testdata/output/ \
    --n-top 5
```

Error path (missing file) — confirm a non-zero exit code:

``` bash
Rapp exec/ADS8192 pca --counts nope.tsv --meta meta.tsv --output out/
echo %ERRORLEVEL%    # Windows: should print 1
```

If you see `Error: File not found: nope.tsv` and a non-zero exit code,
the CLI is failing the way a pipeline expects.

You can also drive the CLI from an R session while iterating — it avoids
spawning a new R process on every run:

``` r
Rapp::run("exec/ADS8192", c(
    "pca",
    "--counts", "tests/testdata/counts.tsv",
    "--meta",   "tests/testdata/meta.tsv",
    "--output", "tests/testdata/output/",
    "--n-top",  "5"
))
```

------------------------------------------------------------------------

## Part 4: The CLI Is a Contract

Once anyone automates against your CLI, **argument names, output file
names, and output column names become a contract**. Pipeline users
hard-code those strings, and renaming them breaks downstream work
silently.

### What’s Breaking?

| Change                        | Breaking?  |
|-------------------------------|------------|
| Rename `--n-top` to `--n_top` | Yes        |
| Add new optional flag         | No         |
| Remove a flag                 | Yes        |
| Change output column names    | Yes        |
| Add new output columns        | Usually no |
| Change default value          | Maybe      |

### Semantic Versioning

- **MAJOR** (1.0.0 → 2.0.0): breaking CLI interface changes
- **MINOR** (1.0.0 → 1.1.0): new features, backward compatible
- **PATCH** (1.0.0 → 1.0.1): bug fixes

Document every interface change in `NEWS.md`. If you have to break
something, do it in a major bump with a clear migration note — not
quietly in a patch.

------------------------------------------------------------------------

## Summary

Today we:

1.  Learned five CLI design principles: help text, explicit I/O,
    reproducible defaults, exit codes, machine-readable output
2.  Introduced Rapp and its `switch("")` subcommand idiom
3.  Added a Rapp app to the existing ADS8192 package (`exec/ADS8192`,
    `Rapp` in `DESCRIPTION`)
4.  Exported a launcher installer (`install_ADS8192_cli()`)
5.  Ran the CLI during development and checked error behavior
6.  Treated argument and output names as a stability contract

### Package Milestone

**The ADS8192 package now has a working CLI in `exec/` and an exported
launcher installer.** Users can call `Rapp exec/ADS8192 pca` today;
Lecture 10 covers installed use, clean-room testing, and output parity.

------------------------------------------------------------------------

### Debrief & Reflection

Before moving on, make sure you can answer:

- When is a CLI genuinely useful, and when is it an unnecessary extra
  interface?
- Which parts of the CLI are stable user contract, and which are
  replaceable implementation details?
- How does `Rapp` let you avoid reinventing plumbing so you can focus on
  I/O contracts and DRY reuse of the package core?

------------------------------------------------------------------------

## After-Class Tasks

### Micro-task 1: Add a `validate` Subcommand

Add a second subcommand that checks inputs without running PCA — useful
for pipeline pre-flight checks. It should:

1.  Check that `--counts` and `--meta` exist and parse
2.  Report dimensions
3.  Check that counts column names match metadata row names

Add it as a second case in the same
[`switch()`](https://rdrr.io/r/base/switch.html) call alongside `pca`.

### Micro-task 2: Snapshot Test for Output Stability

Add a `testthat` snapshot test that captures the column names of
`result$scores`. Future changes to output structure will fail the test
until you deliberately review the snapshot:

``` r
test_that("pca output columns are stable", {
    data(example_se, package = "ADS8192")
    result <- run_pca(example_se, n_top = 50)
    expect_snapshot(colnames(result$scores))
})
```

### Micro-task 3: Read Ahead — Preventing Interface Drift

Before Lecture 10, skim the Rapp documentation section on how snake_case
→ kebab-case conversion works, and think about which of *your*
function’s defaults might be risky to change later. For reference when
revisiting later:

- Use literal output file names (`"pca_scores.tsv"`), never derive them
  from inputs.
- Column names in output files are part of the contract. Adding columns
  is usually safe; renaming them is not.
- When you intentionally change output structure, update the snapshot
  with
  [`testthat::snapshot_review()`](https://testthat.r-lib.org/reference/snapshot_accept.html)
  and bump the version.

------------------------------------------------------------------------

## CLI Quick Reference

``` bash
# During development
Rapp exec/ADS8192 --help
Rapp exec/ADS8192 pca --help

Rapp exec/ADS8192 pca \
    --counts counts.tsv \
    --meta samples.tsv \
    --output results/ \
    --n-top 500 \
    --color-by treatment

# Check exit code (Windows)
echo %ERRORLEVEL%
```

------------------------------------------------------------------------

## Session Info

``` r
sessionInfo()
```

    ## R version 4.5.3 (2026-03-11)
    ## Platform: x86_64-pc-linux-gnu
    ## Running under: Ubuntu 24.04.4 LTS
    ## 
    ## Matrix products: default
    ## BLAS:   /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3 
    ## LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so;  LAPACK version 3.12.0
    ## 
    ## locale:
    ##  [1] LC_CTYPE=C.UTF-8       LC_NUMERIC=C           LC_TIME=C.UTF-8       
    ##  [4] LC_COLLATE=C.UTF-8     LC_MONETARY=C.UTF-8    LC_MESSAGES=C.UTF-8   
    ##  [7] LC_PAPER=C.UTF-8       LC_NAME=C              LC_ADDRESS=C          
    ## [10] LC_TELEPHONE=C         LC_MEASUREMENT=C.UTF-8 LC_IDENTIFICATION=C   
    ## 
    ## time zone: UTC
    ## tzcode source: system (glibc)
    ## 
    ## attached base packages:
    ## [1] stats     graphics  grDevices utils     datasets  methods   base     
    ## 
    ## loaded via a namespace (and not attached):
    ##  [1] digest_0.6.39     desc_1.4.3        R6_2.6.1          fastmap_1.2.0    
    ##  [5] xfun_0.57         cachem_1.1.0      knitr_1.51        htmltools_0.5.9  
    ##  [9] rmarkdown_2.31    lifecycle_1.0.5   cli_3.6.6         sass_0.4.10      
    ## [13] pkgdown_2.2.0     textshaping_1.0.5 jquerylib_0.1.4   systemfonts_1.3.2
    ## [17] compiler_4.5.3    tools_4.5.3       ragg_1.5.2        bslib_0.10.0     
    ## [21] evaluate_1.0.5    yaml_2.3.12       otel_0.2.0        jsonlite_2.0.0   
    ## [25] rlang_1.2.0       fs_2.0.1          htmlwidgets_1.6.4
