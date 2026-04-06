# Lecture 10: Lab – CLI Tool Development (R) – Packaging and Installation

## Learning Objectives

By the end of this session, you will be able to:

1.  Add the CLI entry point to the package so it works after
    installation
2.  Update the GitHub repository and verify installation and CLI
    execution in a clean session
3.  Confirm that CLI outputs match the package’s R function outputs for
    the same inputs
4.  Explain why clean-room testing, release discipline, and backward
    compatibility matter for automation users

**Course Learning Outcomes (CLOs):** CLO 1, 2, 3, 5, 6

### Motivation

For automated scientific tools, installation and release quality are
part of the user experience. If a CLI only works in development mode or
only on the author’s machine, it is not yet robust software.

This lecture matters because clean installs, output parity checks, and
release discipline save other people time. They catch hidden assumptions
early, prevent interface drift, and make it much more likely that a
pipeline user or collaborator will get the same result you saw during
development.

### Evaluation Checklist

Before you ship a CLI, ask:

- Can a user install and run it from a clean environment with only
  declared dependencies?
- Does the installed interface behave the same as the development
  version?
- Do CLI outputs match the package core for the same inputs?
- Which file names, flags, and output columns now form part of the user
  contract?
- What would break if you changed those interfaces in the next release?
- Are release steps reproducible enough for someone else in the lab to
  repeat?

### Scientific Use Case

An analysis group adds your CLI to a scheduled workflow and archives the
outputs for compliance. A month later you “clean up” some file names and
help text before tagging a release. Which changes are harmless
refactors, and which ones break their pipeline contract?

------------------------------------------------------------------------

## Where We Are

In Lecture 9, we built CLI functions that work during development and
**exported a launcher installer** (`install_ADS8192_cli()`) so users can
run the CLI directly from the terminal:

``` bash
# Works in development mode
Rapp exec/ADS8192 pca --help

# Works after installing launchers (Lecture 9)
ADS8192 pca --help
```

**Goal:** Verify that the full install-from-GitHub workflow works
end-to-end — package installation, launcher installation, and CLI
execution — in a clean R session.

------------------------------------------------------------------------

### Design Principle: Installation Is Part of the Product

If a tool only works on the developer’s machine, it is not ready for
scientific use. Clean-room testing and output parity checks matter
because they reveal hidden assumptions, missing dependencies, and
accidental drift between interfaces before users discover them the hard
way.

## Part 1: Package the CLI Entry Point

### Use Rapp’s `exec/` Directory

Rapp CLI apps live in a top-level `exec/` directory. Files in `exec/`
are installed with the package.

#### Create the Directory (if needed)

``` r
dir.create("exec", recursive = TRUE)
```

#### Add the Rapp App

Create `exec/ADS8192` (from Lecture 9). On Unix/Mac, mark it executable:

``` bash
chmod +x exec/ADS8192
```

> **Mac/Linux users:** You only need to run `chmod +x` once when you
> first create the file. If you clone the repo fresh on another machine,
> Git preserves the executable bit (if you committed it), so
> collaborators won’t need to repeat this step. Check with
> `git ls-files --stage exec/ADS8192` — you should see mode `100755`,
> not `100644`.

> **Required: trailing newline.** Rapp requires the script file to end
> with a blank newline. Make sure `exec/ADS8192` has an extra blank line
> at the very end of the file. Without it, Rapp may fail to parse the
> last command correctly. In most editors this is the default behavior,
> but it’s worth verifying.

#### Declare the Dependency

Add Rapp to DESCRIPTION so users have the runner available:

``` r
usethis::use_package("Rapp")
```

------------------------------------------------------------------------

## Part 2: Make the CLI Discoverable

### Install CLI Launchers

In Lecture 9 we exported an `install_ADS8192_cli()` function that wraps
[`Rapp::install_pkg_cli_apps()`](https://rdrr.io/pkg/Rapp/man/install_pkg_cli_apps.html).
Verify it works after a fresh install:

``` r
# Your exported wrapper (preferred)
ADS8192::install_ADS8192_cli()

# Or the direct Rapp call
Rapp::install_pkg_cli_apps("ADS8192")
```

### Where Rapp Installs Launchers

The launchers are placed in a platform-specific directory:

| Platform      | Launcher directory                    |
|---------------|---------------------------------------|
| macOS / Linux | `~/.local/bin/`                       |
| Windows       | `%LOCALAPPDATA%\Programs\R\Rapp\bin\` |

These directories should already be on your `PATH` after
[`Rapp::install_pkg_cli_apps()`](https://rdrr.io/pkg/Rapp/man/install_pkg_cli_apps.html)
runs — it handles `PATH` configuration automatically on first use. If
the command is not found after installation, check:

``` bash
# Unix/Mac: verify the launcher exists
ls ~/.local/bin/ADS8192

# Windows (PowerShell)
Get-Command ADS8192

# Check which ADS8192 is on PATH (Unix/Mac)
which ADS8192

# Check which ADS8192 is on PATH (Windows)
where ADS8192
```

If multiple versions are installed or the wrong one is found, check that
`~/.local/bin` (Unix) or the Rapp bin directory (Windows) appears before
any other `ADS8192` on `PATH`. You can verify the Rapp install path
with:

``` r
# See where Rapp would install launchers
Rapp::pkg_cli_apps_dir()
```

After this, users can run:

``` bash
ADS8192 pca --help
```

### Fallback: Run Directly from `exec/`

If launchers are not installed, you can still run the app directly:

``` bash
Rapp exec/ADS8192 pca --help
```

Or from R:

``` r
Rapp::run(system.file("exec", "ADS8192", package = "ADS8192"), c("pca", "--help"))
```

#### Required: Export the Launcher Installer

In Lecture 9 you created `R/install_cli.R` with an exported wrapper.
Make sure it is present and documented — this is a **rubric
requirement**:

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

------------------------------------------------------------------------

## Part 3: Documentation

### Update README

Add a CLI section:

```` markdown
## Command Line Interface

ADS8192 includes a command-line interface for pipeline integration.

### Quick Start

```bash
# Install the launcher (one-time)
Rscript -e "Rapp::install_pkg_cli_apps('ADS8192')"

# Run PCA analysis
ADS8192 pca \
    --counts counts.tsv \
    --meta samples.tsv \
    --output results/ \
    --n-top 500 \
    --color-by treatment
```

### Fallback (No Launcher)

```bash
Rapp exec/ADS8192 pca --help
```

### Available Commands

| Command | Description |
|---------|-------------|
| `pca` | Run PCA analysis and export results |
| `validate` | Validate input files |

Run `ADS8192 <command> --help` for detailed options.
````

### Add pkgdown Article

Create `vignettes/cli.Rmd`:

```` markdown
---
title: "Command Line Interface"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{Command Line Interface}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---

## Overview

The ADS8192 CLI allows you to run PCA analysis from the command line,
making it easy to integrate into pipelines.

## Installation

After installing ADS8192, install the CLI launcher:

```r
remotes::install_github("you/ADS8192")
Rapp::install_pkg_cli_apps("ADS8192")
```

## Usage

### Basic PCA Analysis

```bash
ADS8192 pca \
    --counts counts.tsv \
    --meta samples.tsv \
    --output results/
```

### Input File Formats

**Counts matrix** (`--counts`):
- Tab-separated or comma-separated
- First column: gene IDs (row names)
- Subsequent columns: sample counts
- Header row with sample IDs

```
gene_id    sample1    sample2    sample3
ENSG001    100        150        120
ENSG002    50         75         60
```

**Metadata** (`--meta`):
- Tab-separated or comma-separated
- First column: sample IDs (must match counts columns)
- Additional columns: sample attributes

```
sample_id    treatment    batch
sample1      control      A
sample2      treated      A
sample3      treated      B
```

### Output Files

| File | Description |
|------|-------------|
| `pca_scores.tsv` | PCA scores merged with sample metadata |
| `pca_variance.tsv` | Variance explained by each PC |
| `pca_plot.png` | PCA scatter plot (if `--color-by` specified) |

### Full Options

```
ADS8192 pca --help
```

## Pipeline Integration

### Snakemake

```python
rule pca:
    input:
        counts = "data/{sample}/counts.tsv",
        meta = "data/{sample}/meta.tsv"
    output:
        directory("results/{sample}/pca/")
    shell:
        """
        ADS8192 pca \
            --counts {input.counts} \
            --meta {input.meta} \
            --output {output}
        """
```

### Bash Loop

```bash
for dataset in data/*; do
    name=$(basename "$dataset")
    ADS8192 pca \
        --counts "$dataset/counts.tsv" \
        --meta "$dataset/meta.tsv" \
        --output "results/$name/"
done
```
````

------------------------------------------------------------------------

## Part 4: Clean Room Testing

### The Importance of Clean Testing

During development, `devtools::load_all()` makes your code available.
But users install the package — we need to verify that works too.

### Exercise A: Clean Room Test

#### Step 1: Install from GitHub

In a fresh R session (restart R first!):

``` r
# Remove any existing installation
remove.packages("ADS8192")

# Install fresh from GitHub
remotes::install_github("you/ADS8192")
```

#### Step 2: Verify Package Works

``` r
library(ADS8192)

# Test core functions
data(example_se)
result <- run_pca(example_se)
plot_pca(result, color_by = "treatment")

# Test Shiny app launches (close it after)
# run_app()

# Install CLI launcher
Rapp::install_pkg_cli_apps("ADS8192")
```

#### CLI Script: Namespace and Trailing Newline

Two common issues when testing the installed CLI for the first time:

**Namespace issues:** Even though
[`library(ADS8192)`](https://github.com/St-Jude-MS-ABDS/ADS8192) loads
the package, some base R functions may not be found if the search path
is not fully set up in the Rapp environment. Always use explicit
namespacing in your CLI script:

``` r
# In exec/ADS8192, load packages explicitly at the top
suppressPackageStartupMessages({
    library(ADS8192)
    library(utils)    # for write.table, read.table
    library(stats)    # for stats::var (used internally)
})

# And use fully-qualified calls for base functions where needed:
utils::write.table(result$scores, scores_file, sep = "\t",
                   row.names = FALSE, quote = FALSE)
```

**Trailing newline:** Rapp requires the `exec/ADS8192` file to end with
a blank line. If you see a parsing error on the last command, add an
extra newline at the end of the file.

#### Step 3: Test CLI from Terminal

First, create the test input files using R (this avoids tab/spacing
issues with shell heredocs):

``` r
# Create test inputs using R (cross-platform reliable)
dir.create("/tmp/cli_test", recursive = TRUE, showWarnings = FALSE)

counts <- data.frame(
  sample1 = c(100L, 50L, 200L, 30L, 80L),
  sample2 = c(150L, 75L, 180L, 45L, 100L),
  sample3 = c(120L, 60L, 210L, 35L, 90L),
  sample4 = c(180L, 90L, 240L, 55L, 110L),
  row.names = paste0("gene", 1:5)
)
utils::write.table(counts, "/tmp/cli_test/counts.tsv",
                   sep = "\t", quote = FALSE)

meta <- data.frame(
  treatment = c("control", "control", "treated", "treated"),
  batch     = c("A", "B", "A", "B"),
  row.names = paste0("sample", 1:4)
)
utils::write.table(meta, "/tmp/cli_test/meta.tsv",
                   sep = "\t", quote = FALSE)
```

Then run the CLI from the terminal:

``` bash
# Run CLI
ADS8192 pca \
    --counts /tmp/cli_test/counts.tsv \
    --meta /tmp/cli_test/meta.tsv \
    --output /tmp/cli_test/output/ \
    --n-top 5

# Check outputs
cat /tmp/cli_test/output/pca_scores.tsv
cat /tmp/cli_test/output/pca_variance.tsv
```

------------------------------------------------------------------------

## Part 5: Output Parity Testing

### What is Output Parity?

The CLI should produce the same results as calling the R functions
directly.

### Exercise B: Verify Output Parity

#### Step 1: Run Analysis via R

``` r
library(ADS8192)

# Load sample data
counts <- read.table("/tmp/cli_test/counts.tsv", header = TRUE, row.names = 1, sep = "\t")
meta <- read.table("/tmp/cli_test/meta.tsv", header = TRUE, row.names = 1, sep = "\t")

# Create SE and run PCA
se <- SummarizedExperiment::SummarizedExperiment(
    assays = list(counts = as.matrix(counts)),
    colData = meta
)
result <- run_pca(se, n_top = 5)

# Get scores
r_scores <- result$scores
```

#### Step 2: Compare with CLI Output

``` r
# Load CLI output
cli_scores <- read.table(
    "/tmp/cli_test/output/pca_scores.tsv",
    header = TRUE,
    sep = "\t"
)

# Compare structure
print(names(r_scores))
print(names(cli_scores))

# Compare values (allowing for floating point differences)
all.equal(r_scores$PC1, cli_scores$PC1)
all.equal(r_scores$PC2, cli_scores$PC2)
```

### Adding an Automated Test

Create `tests/testthat/test-cli.R`:

``` r
# tests/testthat/test-cli.R — CLI output parity test
test_that("CLI produces same output as R functions", {
    skip_on_cran()  # CLI tests may be slow

    # Create temp files
    tmp_dir <- tempdir()
    counts_file <- file.path(tmp_dir, "counts.tsv")
    meta_file <- file.path(tmp_dir, "meta.tsv")
    output_dir <- file.path(tmp_dir, "cli_output")

    # Create test data
    data(example_se, package = "ADS8192")
    counts <- SummarizedExperiment::assay(example_se, "counts")
    meta <- as.data.frame(SummarizedExperiment::colData(example_se))

    write.table(counts, counts_file, sep = "\t", quote = FALSE)
    write.table(meta, meta_file, sep = "\t", quote = FALSE)

    # Run via R
    se <- SummarizedExperiment::SummarizedExperiment(
        assays = list(counts = counts),
        colData = meta
    )
    r_result <- run_pca(se, n_top = 50)

    # Run via CLI
    Rapp::run(system.file("exec", "ADS8192", package = "ADS8192"), c(
        "pca",
        "--counts", counts_file,
        "--meta", meta_file,
        "--output", output_dir,
        "--n-top", "50"
    ))

    # Load CLI output
    cli_scores <- read.table(
        file.path(output_dir, "pca_scores.tsv"),
        header = TRUE,
        sep = "\t"
    )

    # Compare dimensions
    expect_equal(nrow(cli_scores), nrow(r_result$scores))
    expect_equal(ncol(cli_scores), ncol(r_result$scores))

    # Compare PC values (within tolerance)
    expect_equal(cli_scores$PC1, r_result$scores$PC1, tolerance = 1e-10)

    # Cleanup
    unlink(output_dir, recursive = TRUE)
})
```

------------------------------------------------------------------------

## Part 6: Release Checklist

### Pre-Release Checks

Before tagging a release:

``` r
# Run all checks
devtools::check()

# Run tests
devtools::test()

# Build documentation
pkgdown::build_site()

# Verify README renders
devtools::build_readme()
```

### Bump Version

``` r
# Use usethis to update version
usethis::use_version("minor")  # 0.0.1 -> 0.1.0
```

### Create GitHub Release

``` bash
# Tag the release
git tag -a v0.1.0 -m "First release with CLI support"
git push origin v0.1.0
```

On GitHub: 1. Go to Releases → Create a new release 2. Select tag v0.1.0
3. Add release notes:

``` markdown
## ADS8192 v0.1.0

### Features
- Core PCA analysis functions (`run_pca()`, `plot_pca()`)
- Shiny app for interactive exploration (`run_app()`)
- Command-line interface (Rapp app in `exec/`)
- pkgdown documentation site

### Installation
```r
remotes::install_github("you/ADS8192@v0.1.0")
```

    ---

    ## Exercise C: Help Quality

    ### Peer Review Test

    1. Pair up with a classmate
    2. Give them only your README and `--help` output
    3. Ask them to run the CLI on test data
    4. Note any confusion or questions
    5. Update documentation to address unclear points

    Questions to ask:
    - Could they install successfully?
    - Was the CLI invocation clear?
    - Did they understand what the outputs mean?
    - Any error messages that were confusing?

    ---

    # Summary

    Today we:

    1. Packaged the CLI as a Rapp app in `exec/`
    2. Installed launchers with `Rapp::install_pkg_cli_apps()`
    3. Updated documentation (README, pkgdown article)
    4. Performed clean-room installation testing
    5. Verified output parity between R and CLI
    6. Created a release checklist

    ## Package Milestone

    OK - The package installs from GitHub and exposes both `run_app()` and a working Rapp-based CLI.

    ---

    ## Debrief & Reflection

    Before moving on, make sure you can answer:

    - Why is installation quality part of the user contract for automation tools?
    - Which parts of your CLI output now count as backward-compatibility commitments?
    - How do clean-room testing and output parity checks protect users from hidden assumptions in your development environment?

    ---

    # After-Class Tasks

    ## Micro-task 1: R CMD check

    Verify your package passes `devtools::check()` and CI is green.

    ## Micro-task 2: Reproducibility Section

    Add a "Reproducibility" section to README:

    ```markdown
    ## Reproducibility

    This package was developed with:
    - R version 4.3.x
    - Bioconductor 3.18

    ### Installation

    ```r
    # Install from GitHub
    remotes::install_github("you/ADS8192")

    # Or from a specific version
    remotes::install_github("you/ADS8192@v0.1.0")

#### Session Info

Run [`sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html) after
loading the package to see your environment.

    ---

    # Final Package Structure

ADS8192/ ├── DESCRIPTION ├── NAMESPACE ├── LICENSE.md ├── README.Rmd ├──
README.md ├── NEWS.md \# Changelog ├── R/ │ ├── data.R │ ├── pca.R │ ├──
plotting.R │ ├── export.R │ ├── app_ui.R │ ├── app_server.R │ ├──
run_app.R │ └── cli_install.R ├── exec/ │ └── ADS8192 ├── inst/ │ └──
app/ │ └── app.R ├── data/ │ └── example_se.rda ├── data-raw/ │ └──
example_se.R ├── man/ │ └── \*.Rd ├── tests/ │ ├── testthat/ │ │ ├──
test-data.R │ │ ├── test-pca.R │ │ ├── test-cli_install.R │ │ └── … │
└── testthat.R ├── vignettes/ │ ├── getting-started.Rmd │ ├──
shiny-app.Rmd │ └── cli.Rmd ├── \_pkgdown.yml └── .github/ └──
workflows/ ├── R-CMD-check.yaml └── pkgdown.yaml

    ---

    # Session Info


    ``` r
    sessionInfo()

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
    ##  [9] rmarkdown_2.31    lifecycle_1.0.5   cli_3.6.5         sass_0.4.10      
    ## [13] pkgdown_2.2.0     textshaping_1.0.5 jquerylib_0.1.4   systemfonts_1.3.2
    ## [17] compiler_4.5.3    tools_4.5.3       ragg_1.5.2        bslib_0.10.0     
    ## [21] evaluate_1.0.5    yaml_2.3.12       otel_0.2.0        jsonlite_2.0.0   
    ## [25] rlang_1.1.7       fs_2.0.1          htmlwidgets_1.6.4
