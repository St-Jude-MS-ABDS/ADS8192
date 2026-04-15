# Lecture 5: Lab – R Package Development (devtools)

## Motivation

Many research projects begin as scripts that only make sense to the
original author and only run in one working directory. Packaging forces
you to turn that private workflow into something installable,
documented, and reusable by other people.

This can also personally save you time and sanity in a variety of ways -
generic reuseability, minimal editing to apply to new
datasets/experiments, preparedness for publication, and not having to
remember exactly which script had which bit of code you used in that one
analysis 6 months ago.

### Learning Objectives

By the end of this lab, you will be able to:

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

------------------------------------------------------------------------

## Taking the Next Step

In Lecture 4, we created an “analysis core” — a set of functions in a
script. But scripts have limitations:

| Script                          | Package                                                                            |
|---------------------------------|------------------------------------------------------------------------------------|
| `source("path/to/file.R")`      | [`library(ADS8192)`](https://github.com/St-Jude-MS-ABDS/ADS8192)                   |
| Paths break when you move files | Installed; works anywhere                                                          |
| No formal dependency management | Explicit dependency management                                                     |
| No formal help documentation    | [`?run_pca`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_pca.md) works |
| Hard to share                   | `remotes::install_github("St-Jude-MS-ABDS/ADS8192")`                               |
| No tests to ensure correctness  | Automated testing simple to implement                                              |

An R package is barely more complicated than a script, but it provides
many benefits even if you’re the only one who will ever use it. It can
be a little intimating at first, but once you build a package once, it
becomes a natural way to organize code.

### Package Development Tools

Fortunately, there are a number of R packages that provide scaffolding
and convenience functions to make package development easier:

- `usethis` quickly generates package infrastructure (DESCRIPTION,
  NAMESPACE, R/ directory, README, data-raw/, etc) and automates common
  tasks like adding dependencies, creating documentation stubs, and
  setting up Github
- `devtools` standardizes the edit-document-test-check loop
- `roxygen2` parses specially formatted comments to generate
  documentation automatically
- `testthat` provides a framework for writing automated tests to ensure
  your code works as expected and to prevent regressions

We’ll use all of these tools to help build our package.

Note that these tools are **not required** for package development, you
could create all the files from scratch yourself. These tools just make
this process quicker and easier, particularly once you’ve used them once
or twice.

## Pre-Lab Checklist

Before we begin, ensure you have:

Your `analysis_core.R` script from Lecture 4 with analysis functions

Git installed and configured
(`git config --global user.name "Your Name"`)

A GitHub account

``` r
# Install development tools if needed
install.packages(c("devtools", "usethis", "roxygen2", "testthat"))
```

------------------------------------------------------------------------

## Part 1: Create the Package Skeleton

### Step 1: Create the Package

Open RStudio and create a new package:

``` r
library(usethis)

# Create the package (choose your own name!)
# This creates a new directory with the package structure
create_package("~/ADS8192")  # Or wherever you want it

# This will open a new RStudio session in the package directory
```

After running this, you’ll see:

    ADS8192/
    ├── .Rbuildignore
    ├── .gitignore
    ├── DESCRIPTION
    ├── NAMESPACE
    ├── R/
    └── ADS8192.Rproj

> **Note:** Two important files are created automatically by `usethis`:
>
> - **`.Rbuildignore`** — tells `R CMD build` which files to exclude
>   from the package tarball. For example, the `.Rproj` file,
>   `data-raw/` scripts, and development notes should be listed here.
>   They don’t belong in the installed package.
> - **`.gitignore`** — tells Git which files not to track. This
>   typically includes compiled artifacts (`.o`, `.so`), `.Rproj.user/`,
>   and temporary files. You rarely need to edit these manually —
>   `usethis` functions like `use_data_raw()` automatically add the
>   right entries.

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
# git remote add origin https://github.com/your-username/ADS8192.git
# git push -u origin main
```

### Step 4: Add a License

More on this in the next section.

``` r
# MIT License is a good default for open source
use_mit_license()

# This adds:
# - LICENSE.md file
# - License field in DESCRIPTION
```

------------------------------------------------------------------------

## Part 2: The DESCRIPTION File

The `DESCRIPTION` file is the heart of your package metadata. Open it
and edit:

``` yaml
Package: ADS8192
Title: ADS 8192 PCA Analysis Tools
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

We will add more to this file later. For now, make sure to fill in the
`Authors@R` field with your name and email, and optionally your ORCID.
The `Description` should be a concise summary of what your package does.
The `Roxygen` field tells roxygen2 to use markdown formatting in the
documentation, which allows for nicer formatting in help files.

### Software Licensing

Software can be published under various licenses. The [MIT
License](https://opensource.org/license/mit) is a permissive open-source
license that allows others to use, modify, and distribute your code with
minimal restrictions. By choosing the MIT License, you are allowing
others to freely use your code while also disclaiming any warranties or
liabilities. This is a common choice for academic software projects that
aim to maximize reuse and collaboration.

This is not the only license, but if you want people to be able to use
your code without worrying about legal issues, the MIT License is a good
default.

### Versioning

[Semantic versioning](https://semver.org/) is a common convention for
version numbers. The format is `MAJOR.MINOR.PATCH`. For development
versions, it’s common to use `0.0.0.9000` or similar to indicate that
it’s not a stable release yet. When you make a first stable release, you
might change it to `1.0.0`. Then, for bug fixes, you would increment the
PATCH version (e.g. `1.0.1`), and for new features that are backward
compatible, you would increment the MINOR version (e.g. `1.1.0`). For
breaking changes, you would increment the MAJOR version (e.g. `2.0.0`).
Much modern software uses semantic versioning to communicate the
stability and compatibility of releases.

In general, it’s best to keep major, breaking releases to a minimum.

### Adding Dependencies

**Critical:** In packages, we don’t use
[`library()`](https://rdrr.io/r/base/library.html). Instead, we declare
dependencies in DESCRIPTION.

``` r
# Add packages to Imports (required to run)
use_package("SummarizedExperiment")
use_package("ggplot2")

# Add packages to Suggests (optional, for examples/tests or optional features)
use_package("testthat", type = "Suggests")
use_package("knitr", type = "Suggests")
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

------------------------------------------------------------------------

## Part 3: Move Functions to R/

### Package Structure for Code

All R code goes in the `R/` directory. You can organize it however you
like, it’s typical to break up your functions into multiple files based
on functionality. For example:

    R/
    ├── data.R         # Functions for data handling (top_variable_features)
    ├── pca.R          # PCA-related functions
    ├── plotting.R     # Visualization functions
    └── ADS8192-package.R  # Package-level documentation

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

**Option 1: Full namespace**

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

Importing these functions makes your code cleaner, but you must ensure
that the package is listed in Imports and that you run `document()` to
update the NAMESPACE.

At times, you may run into conflicts between packages
(e.g. [`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html)
vs [`stats::filter()`](https://rdrr.io/r/stats/filter.html)). In those
cases, it is usually best to use the full namespace syntax to avoid
ambiguity.

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
#'
#' @importFrom SummarizedExperiment assay
#' @export
#'
#' @examples
#' # Assuming 'se' is a SummarizedExperiment
#' library(airway)
#' data(airway)
#'
#' airway_top <- top_variable_features(airway, n = 500)
top_variable_features <- function(se, n = 500, assay_name = "counts") {
    mat <- assay(se, assay_name)
    vars <- apply(mat, 1, var)
    top_idx <- order(vars, decreasing = TRUE)[seq_len(min(n, length(vars)))]
    se[top_idx, ]
}
```

Note the key additions:

- `#' @export` — Makes the function available to users
- `#' @param` — Documents each parameter, indicating expected types and
  defaults
- `#' @return` — Documents the return value, i.e. what the user gets
  back when they call the function
- `#' @examples` — Provides standalone runnable examples
- `pkg::fun()` syntax — Explicit namespacing

------------------------------------------------------------------------

## Part 4: Generate Documentation

We’ll talk more deeply about documentation in the next lecture, but for
now, writing very basic docstrings for our functions while they’re fresh
is quick and easy.

AI is *very* good at writing documentation, so there is no modern excuse
for poorly documented software.

### Docstrings with Roxygen2

Roxygen2 parses specially formatted comments (starting with `#'`) to
generate help files and the NAMESPACE. The format is simple but
powerful. Here’s an example for our
[`top_variable_features()`](https://st-jude-ms-abds.github.io/ADS8192/reference/top_variable_features.md)
function:

``` r
#' Select top variable features
#'
#' @param se A SummarizedExperiment object
#' @param n Number of top variable features to select (default: 500)
#' @param assay_name Name of assay to use (default: "counts")
#'
#' @return A SummarizedExperiment subset to the top n variable features
#'
#' @importFrom SummarizedExperiment assay
#' @export
#'
#' @examples
#' # Assuming 'se' is a SummarizedExperiment
#' library(airway)
#' data(airway)
#'
#' airway_top <- top_variable_features(airway, n = 500)
top_variable_features <- function(se, n = 500, assay_name = "counts") {
    mat <- assay(se, assay_name)
    vars <- apply(mat, 1, var)
    top_idx <- order(vars, decreasing = TRUE)[seq_len(min(n, length(vars)))]
    se[top_idx, ]
}
```

Note the key additions:

- The block starts with a title line.
- `#' @param` — Documents each parameter, indicating expected types and
  defaults
- `#' @return` — Documents the return value, i.e. what the user gets
  back when they call the function
- `#' @importFrom` — Specifies functions to import from other packages
  for use in the function
- `#' @export` — Makes the function available to users of the package -
  not all functions have to be exported
- `#' @examples` — Provides standalone runnable examples

We’ll talk about long-form documentation and best practices for
docstrings in the next lab, but this is a good start.

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

This file is what controls which functions are available to users when
they load the package. Only functions listed here can be accessed with
[`library(ADS8192)`](https://github.com/St-Jude-MS-ABDS/ADS8192).
Internal helper functions that are not exported will not be listed here
and cannot be accessed directly by users.

### Test the Help

``` r
# Load the package in development mode
load_all()

# Test help pages
?top_variable_features
?run_pca
```

------------------------------------------------------------------------

## Part 5: Add Example Data

Let’s include a small example dataset to the package so users (and
tests) can try the functions without loading external data.

``` r
# Create data-raw directory for data preparation scripts
use_data_raw("example_se")
```

This creates `data-raw/example_se.R`. Edit it with the raw data code for
your project.

For my example, I am generating a small simulated dataset. It’s often a
good idea to include an example dataset so users can try your code
easily, but you can also use existing small datasets if they’re a good
fit (for example, the `airway` dataset would have been a good choice
here).

``` r
# data-raw/example_se.R — creates example_se dataset

# Create a small example SummarizedExperiment
library(SummarizedExperiment)

set.seed(42)

# 10000 genes, 8 samples
n_genes <- 10000
n_samples <- 8

# Simulate counts (negative binomial-ish)
counts <- matrix(
    rpois(n_genes * n_samples, lambda = 100),
    nrow = n_genes,
    ncol = n_samples
)
rownames(counts) <- paste0("gene", seq_len(n_genes))
colnames(counts) <- paste0("sample", seq_len(n_samples))

# Add some structure: first 200 genes differ by treatment
treatment <- rep(c("control", "treated"), each = 4)
counts[1:200, treatment == "treated"] <- counts[1:200, treatment == "treated"] * 2

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

This script also serves as a record of how the data was generated.

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
#' A small SummarizedExperiment with 10000 genes and 8 samples.
#' Includes a treatment effect in the first 200 genes.
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
#' library(SummarizedExperiment)
#' data(example_se)
#' example_se
#' colData(example_se)
"example_se"
```

This tells the user what the dataset is, its source, and any other
relevant info. After running `document()`, users can access this info
with
[`?example_se`](https://st-jude-ms-abds.github.io/ADS8192/reference/example_se.md).

------------------------------------------------------------------------

## Part 6: R CMD check

Thankfully, R has strong tooling for checking package quality and
correctness. The `check()` function runs a battery of tests to ensure
your package meets minimal standards. It checks for:

- Missing documentation
- Undocumented arguments
- Missing imports
- Non-ASCII characters
- Examples that fail to run
- DESCRIPTION issues

And much more. If it passes, you have a valid package that can be built
and installed.

``` r
check()
```

If there are issues, it will categorize them as ERROR, WARNING, or NOTE.
Errors must be fixed before you can build/install the package. Warnings
and Notes should be reviewed and fixed if possible, but some may be
acceptable for early development. `check` is quite clear about the
specific issues, so read the output carefully and address each item. A
clean `check` is pretty much pure bliss.

It’s okay if you have some warnings/notes at this stage, but try to fix
all errors. If you have errors that you don’t understand, feel free to
ask for help.

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

**Fix:** Add the package to Suggests.

------------------------------------------------------------------------

## Part 7: Push to GitHub and Test Install

Now that you’ve hopefully got a useable package, it’s time to start
tracking the code properly.

### Commit and Push

``` r
# Stage all files
# git add .

# Commit
# git commit -m "Initial package structure with core functions"

# Push
# git push
```

There is also an easy to use [Desktop App](https://desktop.github.com/)
if you prefer a GUI for Git.

### Test Installation

Now we can try installing the package as an end-user would. Open a
**fresh R session** and try:

``` r
# Install from GitHub
remotes::install_github("St-Jude-MS-ABDS/ADS8192")

# Load and test your package, here's what mine looks like:
library(ADS8192)
data(example_se)

result <- run_pca(example_se)
plot_pca(result, color_by = "treatment")
```

------------------------------------------------------------------------

## Part 8: Add a README

The README is the first thing users see when they visit your GitHub
repo. It should provide a clear overview of what the package does, how
to install it, and a quick example of how to use it.

Repos with sucky READMEs are less likely to be used. Writing good
documentation often reveals flaws or rough edges in the software design,
and it can be an effective way to step back and think about the user
experience of your package.

You can be a flat out savant with code, but if your documentation is
bad, no one will use it. Conversely, even a mediocre package can be
widely used if it has clear, easy to follow documentation (…looking at
you again, `Seurat`).

We can use Rmd to create a README with rich formatting and examples.
`usethis` has a convenient function to set this up:

``` r
use_readme_rmd()
```

Then we can edit `README.Rmd` to add installation instructions, usage
examples, and any other relevant info. Here’s a simple example:

```` markdown
---
output: github_document
---

# ADS8192


ADS8192 provides tools for performing PCA on SummarizedExperiment objects.

## Installation

```r
# Install from GitHub
remotes::install_github("St-Jude-MS-ABDS/ADS8192")
```

## Quick Start

```r
library(ADS8192)

# Load example data
data(example_se)

# Run PCA
result <- run_pca(example_se, n_top = 500)

# Plot
plot_pca(result, color_by = "treatment")
```
````

Then build the README:

``` r
build_readme()
```

This will generate a `README.md` file that is rendered from the Rmd.
When you push this to GitHub, it will be displayed on the repo homepage.

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

We did a lot, give yourself a little pat on the back.

------------------------------------------------------------------------

## After-Class Tasks

### Reading

- Skim the [Bioconductor Contributions
  book](https://contributions.bioconductor.org/)
- See the [R Packages book](https://r-pkgs.org) for more in-depth
  details of package development

### Micro-task 1: Package-Level Documentation

Add a package-level documentation file:

``` r
use_package_doc()
```

Edit the resulting file to describe the package purpose and main
functions.

------------------------------------------------------------------------

## Cheatsheet

Always nice to have a handy reference lying around.

``` r
# Package development quick reference
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
use_package("ggplot2")              # to Imports
use_package("testthat", "Suggests") # to Suggests

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
    ##  [9] rmarkdown_2.31    lifecycle_1.0.5   cli_3.6.6         sass_0.4.10      
    ## [13] pkgdown_2.2.0     textshaping_1.0.5 jquerylib_0.1.4   systemfonts_1.3.2
    ## [17] compiler_4.5.3    tools_4.5.3       ragg_1.5.2        bslib_0.10.0     
    ## [21] evaluate_1.0.5    yaml_2.3.12       otel_0.2.0        jsonlite_2.0.0   
    ## [25] rlang_1.2.0       fs_2.0.1          htmlwidgets_1.6.4
