# Lecture 5: Lab – R Package Development (devtools)

## Learning Objectives

By the end of this session, you will be able to:

1.  Use `usethis` and `devtools` to scaffold package infrastructure
    instead of hand-building it
2.  Define a small public API and distinguish exported functions from
    internal helpers
3.  Define and validate a correct DESCRIPTION file, including
    dependencies and metadata
4.  Add roxygen2 documentation and generate help files/NAMESPACE
5.  Publish the package to a Git repository and install it from GitHub
6.  Diagnose and resolve common development issues (namespacing, missing
    Imports, R CMD check warnings)

**Course Learning Outcomes (CLOs):** CLO 1, 4, 6

### Motivation

Many research projects begin as scripts that only make sense to the
original author and only run in one working directory. Packaging forces
you to turn that private workflow into something installable,
documented, and reusable by other people.

That matters for scientific software because package boundaries make
assumptions visible. A small public API, explicit dependencies, and
generated documentation save time for your future self, reduce
onboarding time for collaborators, and make it far easier to test or
extend the code without breaking everything around it.

### Evaluation Checklist

Before you introduce a packaging tool or workflow, ask:

- Does it solve infrastructure that should not be custom work?
- Does it make the package contract clearer for users and collaborators?
- Does it reduce hidden state, manual steps, or copy-paste setup?
- Does it align with standard R package workflows that others already
  know?
- Will it make clean installs, testing, and maintenance easier six
  months from now?
- Are you using it to support a clear API, or just generating files
  without design intent?

### Scientific Use Case

You inherit a 700-line exploratory RNA-seq script from a graduate
student who is graduating next month. The code “works on their laptop,”
but a collaborator now wants to install it from GitHub, read help pages,
and call only two functions from another project. What has to change
first: the science, or the software boundaries?

------------------------------------------------------------------------

## Why Package Your Code?

### From Script to Application

In Lecture 3, we created an “analysis core” — a set of functions in a
script. But scripts have limitations:

| Script                          | Package                                                                            |
|---------------------------------|------------------------------------------------------------------------------------|
| `source("path/to/file.R")`      | [`library(sePCA)`](https://rdrr.io/r/base/library.html)                            |
| Paths break when you move files | Installed; works anywhere                                                          |
| Dependency conflicts            | Explicit dependency management                                                     |
| No help documentation           | [`?run_pca`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_pca.md) works |
| Hard to share                   | `install_github("you/sePCA")`                                                      |
| No tests                        | Automated testing with testthat                                                    |

**A package is the fundamental unit of shareable, reproducible code in
R.**

------------------------------------------------------------------------

### Why Reuse Package Tooling?

The package files in this lecture are not an invitation to manually
recreate package infrastructure forever. In production work:

- `usethis` gives you consistent scaffolding faster than hand-editing
  every file
- `devtools` standardizes the edit-document-test-check loop
- `roxygen2` keeps documentation close to the code it describes

Reinventing any of those layers is usually wasted effort. The design
work that still belongs to you is deciding what the package should
expose, what it should hide, and how users should move through the API.

## Pre-Lab Checklist

Before we begin, ensure you have:

Your `analysis_core.R` script from Lecture 3 with the five functions

Git installed and configured
(`git config --global user.name "Your Name"`)

A GitHub account

RStudio (recommended) or another IDE with R support

``` r
# Install development tools if needed
install.packages(c("devtools", "usethis", "roxygen2", "testthat"))
```

------------------------------------------------------------------------

## Part 1: Define the Package API

Before writing code, let’s define the **user story** and **public API**.

### User Story

> As a bioinformatics researcher, I want to quickly run PCA on a
> SummarizedExperiment and create publication-ready visualizations, so
> that I can explore batch effects and sample groupings in my RNA-seq
> data.

### Public API (Exported Functions)

| Function                                                                                                    | Exported? | Reason                              |
|-------------------------------------------------------------------------------------------------------------|-----------|-------------------------------------|
| [`top_variable_features()`](https://st-jude-ms-abds.github.io/ADS8192/reference/top_variable_features.md)   | Yes       | Users may want to filter separately |
| [`run_pca()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_pca.md)                               | Yes       | Core analysis function              |
| [`pca_variance_explained()`](https://st-jude-ms-abds.github.io/ADS8192/reference/pca_variance_explained.md) | Yes       | Useful standalone                   |
| [`plot_pca()`](https://st-jude-ms-abds.github.io/ADS8192/reference/plot_pca.md)                             | Yes       | Core visualization                  |

> **Exercise A:** Are there any functions you might add later that
> should be **internal** (not exported)? What distinguishes an exported
> function from an internal helper?

------------------------------------------------------------------------

## Part 2: Create the Package Skeleton

### Step 1: Create the Package

Open RStudio and create a new package:

``` r
library(usethis)

# Create the package (choose your own name!)
# This creates a new directory with the package structure
create_package("~/sePCA")  # Or wherever you want it

# This will open a new RStudio session in the package directory
```

After running this, you’ll see:

    sePCA/
    ├── .Rbuildignore
    ├── .gitignore
    ├── DESCRIPTION
    ├── NAMESPACE
    ├── R/
    └── sePCA.Rproj

### Step 2: Initialize Git

``` r
# Initialize git repository
use_git()

# This will:
# 1. Create a .git directory
# 2. Make an initial commit
# 3. Potentially restart RStudio
```

### Step 3: Connect to GitHub

``` r
# Create a GitHub repository and push
use_github()

# This will:
# 1. Create a new repo on GitHub
# 2. Add the remote
# 3. Push your initial commit

# If this doesn't work, you can create the repo manually on GitHub
# and then add the remote via the terminal:
# git remote add origin https://github.com/your-username/sePCA.git
# git push -u origin main
```

### Step 4: Add a License

``` r
# MIT License is a good default for open source
use_mit_license()

# This adds:
# - LICENSE.md file
# - License field in DESCRIPTION
```

------------------------------------------------------------------------

## Part 3: The DESCRIPTION File

The `DESCRIPTION` file is the heart of your package metadata. Open it
and edit:

``` yaml
Package: sePCA
Title: PCA Analysis for SummarizedExperiment Objects
Version: 0.0.0.9000
Authors@R: 
    person("Your", "Name", email = "you@example.com", role = c("aut", "cre"),
           comment = c(ORCID = "YOUR-ORCID-ID"))
Description: Provides functions to perform principal component analysis (PCA)
    on SummarizedExperiment objects. Includes tools for selecting top variable
    features, running PCA, and creating publication-ready visualizations.
    Designed as a teaching example for scientific application development.
License: MIT + file LICENSE
Encoding: UTF-8
Roxygen: list(markdown = TRUE)
RoxygenNote: 7.2.3
```

### Adding Dependencies

**Critical:** In packages, we don’t use
[`library()`](https://rdrr.io/r/base/library.html). Instead, we declare
dependencies in DESCRIPTION.

``` r
# Add packages to Imports (required to run)
use_package("SummarizedExperiment")
use_package("ggplot2")
use_package("rlang")  # For .data pronoun in ggplot aes()

# Add packages to Suggests (optional, for examples/tests)
use_package("testthat", type = "Suggests")
use_package("knitr", type = "Suggests")

# NOTE: For Bioconductor packages, you may also need:
# BiocManager::install("SummarizedExperiment")
# and add 'biocViews:' to your DESCRIPTION (can be left empty)
```

After running these, your DESCRIPTION will include:

``` yaml
Imports:
    ggplot2,
    SummarizedExperiment
Suggests:
    knitr,
    testthat
```

> **Exercise B:** Why do we put `testthat` in Suggests rather than
> Imports? What’s the difference?

------------------------------------------------------------------------

## Part 4: Move Functions to R/

### Package Structure for Code

All R code goes in the `R/` directory. You can organize it however you
like, but a common pattern:

    R/
    ├── data.R         # Functions for data handling (top_variable_features)
    ├── pca.R          # PCA-related functions
    ├── plotting.R     # Visualization functions
    └── sePCA-package.R  # Package-level documentation

### Create the Files

``` r
# Create R files (this just opens them in RStudio)
use_r("data")      # For top_variable_features()
use_r("pca")       # For run_pca(), pca_variance_explained()
use_r("plotting")  # For plot_pca()
```

### Move and Adapt Your Functions

Copy your functions from `analysis_core.R`, but make these changes:

#### Before (Script Style)

``` r
library(SummarizedExperiment)  # DON'T do this in packages!
library(ggplot2)

top_variable_features <- function(se, n = 500, assay_name = "counts") {
  mat <- assay(se, assay_name)  # Uses assay() directly
  # ...
}
```

#### After (Package Style)

Two options for using functions from other packages:

**Option 1: Full namespace (recommended for clarity)**

``` r
# In R/data.R
top_variable_features <- function(se, n = 500, assay_name = "counts") {
  # Use pkg::fun() syntax
  mat <- SummarizedExperiment::assay(se, assay_name)
  # ...
}
```

**Option 2: Import via roxygen2**

``` r
#' @importFrom SummarizedExperiment assay colData rowData
top_variable_features <- function(se, n = 500, assay_name = "counts") {
  # Can use function directly because it's imported
  mat <- assay(se, assay_name)
  # ...
}
```

#### Complete Example: R/data.R

``` r
# R/data.R

#' Select top variable features
#'
#' @param se A SummarizedExperiment object
#' @param n Number of top variable features to select (default: 500)
#' @param assay_name Name of assay to use (default: "counts")
#'
#' @return A SummarizedExperiment subset to the top n variable features
#' @export
#'
#' @examples
#' # Assuming 'se' is a SummarizedExperiment
#' # se_top <- top_variable_features(se, n = 500)
top_variable_features <- function(se, n = 500, assay_name = "counts") {
    mat <- SummarizedExperiment::assay(se, assay_name)
    vars <- apply(mat, 1, var)
    top_idx <- order(vars, decreasing = TRUE)[seq_len(min(n, length(vars)))]
    se[top_idx, ]
}
```

Note the key additions:

- `#' @export` — Makes the function available to users
- `#' @param` — Documents each parameter
- `#' @return` — Documents the return value
- `#' @examples` — Provides runnable examples
- `pkg::fun()` syntax — Explicit namespacing

------------------------------------------------------------------------

## Part 5: Generate Documentation

### Run roxygen2

``` r
library(devtools)

# Generate documentation and NAMESPACE
document()
```

This creates:

- `man/top_variable_features.Rd` — Help file for each documented
  function
- `NAMESPACE` — Updated with exports and imports

Check your `NAMESPACE` file:

    # Generated by roxygen2: do not edit by hand

    export(pca_variance_explained)
    export(plot_pca)
    export(run_pca)
    export(top_variable_features)

### Test the Help

``` r
# Load the package in development mode
load_all()

# Test help pages
?top_variable_features
?run_pca
```

------------------------------------------------------------------------

## Part 6: Add Example Data

Let’s include a small example dataset so users (and tests) can try the
functions without loading external data.

``` r
# Create data-raw directory for data preparation scripts
use_data_raw("example_se")
```

This creates `data-raw/example_se.R`. Edit it:

``` r
# data-raw/example_se.R

# Create a small example SummarizedExperiment
library(SummarizedExperiment)

set.seed(42)

# 100 genes, 8 samples
n_genes <- 100
n_samples <- 8

# Simulate counts (negative binomial-ish)
counts <- matrix(
    rpois(n_genes * n_samples, lambda = 100),
    nrow = n_genes,
    ncol = n_samples
)
rownames(counts) <- paste0("gene", seq_len(n_genes))
colnames(counts) <- paste0("sample", seq_len(n_samples))

# Add some structure: first 20 genes differ by treatment
treatment <- rep(c("control", "treated"), each = 4)
counts[1:20, treatment == "treated"] <- counts[1:20, treatment == "treated"] * 2

# Sample metadata
sample_data <- data.frame(
    sample_id = colnames(counts),
    treatment = treatment,
    batch = rep(c("A", "B"), times = 4),
    row.names = colnames(counts)
)

# Gene metadata
gene_data <- data.frame(
    gene_id = rownames(counts),
    gene_symbol = paste0("SYM", seq_len(n_genes)),
    row.names = rownames(counts)
)

# Create SummarizedExperiment
example_se <- SummarizedExperiment(
    assays = list(counts = counts),
    colData = sample_data,
    rowData = gene_data
)

# Save to data/
usethis::use_data(example_se, overwrite = TRUE)
```

Run the script to create the data:

``` r
source("data-raw/example_se.R")
```

Now document the data:

``` r
use_r("data-documentation")
```

Add to `R/data-documentation.R`:

``` r
#' Example SummarizedExperiment for testing
#'
#' A small SummarizedExperiment with 100 genes and 8 samples.
#' Includes a treatment effect in the first 20 genes.
#'
#' @format A SummarizedExperiment with:
#' \describe{
#'   \item{assays}{counts - raw count matrix}
#'   \item{colData}{sample_id, treatment (control/treated), batch (A/B)}
#'   \item{rowData}{gene_id, gene_symbol}
#' }
#'
#' @source Simulated data for teaching purposes
#'
#' @examples
#' data(example_se)
#' example_se
#' colData(example_se)
"example_se"
```

------------------------------------------------------------------------

## Part 7: R CMD check

This is the moment of truth! `R CMD check` runs ~50 checks to validate
your package.

``` r
# Run the full check
check()
```

### Common Issues and Fixes

#### 1. Missing Imports

    Error: could not find function "SummarizedExperiment"

**Fix:** Add `#' @importFrom` or use `pkg::fun()` syntax.

#### 2. Undocumented Arguments

    Warning: Undocumented arguments in documentation object 'top_variable_features'
      'row_data'

**Fix:** Add `@param row_data` to your roxygen2 block.

#### 3. Non-ASCII Characters

    Warning: found non-ASCII string

**Fix:** Replace special characters (curly quotes, em-dashes) with ASCII
equivalents.

#### 4. Missing Suggests for Examples

    Package suggested but not available: 'foo'

**Fix:** Wrap example code in `\dontrun{}` or add the package to
Suggests.

> **Exercise C:** Run `check()` on your package. Categorize each WARNING
> and NOTE as either “must fix” or “acceptable for now.”

------------------------------------------------------------------------

## Part 8: Push to GitHub and Test Install

### Commit and Push

``` r
# Stage all files
# git add -A

# Commit
# git commit -m "Initial package structure with core PCA functions"

# Push
# git push
```

In RStudio, use the Git pane (Ctrl+Alt+M to commit).

### Test Installation

Open a **fresh R session** (important!) and try:

``` r
# Install from GitHub
# remotes::install_github("your-username/sePCA")

# Load and test
library(sePCA)
data(example_se)

result <- run_pca(example_se)
plot_pca(result, color_by = "treatment")
```

------------------------------------------------------------------------

## Part 9: Add a README

``` r
use_readme_rmd()
```

Edit `README.Rmd`:

```` markdown
---
output: github_document
---

# sePCA

<!-- badges: start -->
<!-- badges: end -->

sePCA provides tools for performing PCA on SummarizedExperiment objects.

## Installation
 
```r
# Install from GitHub
remotes::install_github("your-username/sePCA")
```

## Quick Start

```r
library(sePCA)
library(airway)

# Load example data
data(airway)

# Run PCA
result <- run_pca(airway, n_top = 500)

# Plot
plot_pca(result, color_by = "dex")
```
````

Then build the README:

``` r
build_readme()
```

------------------------------------------------------------------------

## Summary

Today we:

1.  Created a package skeleton with `usethis::create_package()`
2.  Set up Git and GitHub for version control
3.  Configured DESCRIPTION with proper metadata and dependencies
4.  Moved our functions to R/ with roxygen2 documentation
5.  Created example data for testing
6.  Ran `devtools::check()` and fixed issues
7.  Published to GitHub and tested installation

### Package Milestone

✅ A valid GitHub-hosted R package that installs successfully and
exposes the analysis core as documented exported functions.

------------------------------------------------------------------------

### Debrief & Reflection

Before moving on, make sure you can explain:

- Why is `usethis` worth reusing instead of hand-writing package
  scaffolding?
- Which of your current functions are true user-facing API, and which
  should become internal helpers?
- If a collaborator only reads the README and function help, what
  package design choices will make the code feel coherent instead of
  script-like?

------------------------------------------------------------------------

## After-Class Tasks

### Reading

- Skim the Bioconductor Contributions book sections on package structure
- R Packages book: <https://r-pkgs.org> (chapters 1-7)

### Micro-task 1: Package-Level Documentation

Add a package-level documentation file:

``` r
use_package_doc()
```

Edit `R/sePCA-package.R` to describe the package purpose and main
functions.

### Micro-task 2: Fresh Install Test

From a fresh R session (restart R first!):

1.  Install your package: `remotes::install_github("you/sePCA")`
2.  Run the README example
3.  Fix any issues

------------------------------------------------------------------------

## Quick Reference

``` r
# Package development workflow
library(devtools)
library(usethis)

# Create package
create_package("path/to/pkgname")

# Add infrastructure
use_git()
use_github()
use_mit_license()
use_readme_rmd()

# Add dependencies
use_package("ggplot2")              # Imports
use_package("testthat", "Suggests") # Suggests

# Create files
use_r("filename")                   # R code
use_data_raw("dataname")            # Data prep script

# Development cycle
load_all()      # Load package for testing (Ctrl+Shift+L)
document()      # Generate docs (Ctrl+Shift+D)
check()         # Run R CMD check (Ctrl+Shift+E)
test()          # Run tests (Ctrl+Shift+T)
build_readme()  # Render README.Rmd

# Install
install()       # Install locally
# install_github("user/repo")  # From GitHub
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
    ##  [9] rmarkdown_2.31    lifecycle_1.0.5   cli_3.6.5         sass_0.4.10      
    ## [13] pkgdown_2.2.0     textshaping_1.0.5 jquerylib_0.1.4   systemfonts_1.3.2
    ## [17] compiler_4.5.3    tools_4.5.3       ragg_1.5.2        bslib_0.10.0     
    ## [21] evaluate_1.0.5    yaml_2.3.12       otel_0.2.0        jsonlite_2.0.0   
    ## [25] rlang_1.1.7       fs_2.0.1          htmlwidgets_1.6.4
