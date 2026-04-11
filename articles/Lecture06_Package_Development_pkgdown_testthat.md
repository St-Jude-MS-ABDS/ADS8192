# Lecture 6: Lab – R Package Development (pkgdown, testthat)

## Motivation

Scientific software is rarely finished when the first version works. It
changes when data sets grow, parameters are tuned, bugs are fixed, and
collaborators ask for new outputs. Testing, documentation, and CI are
the tools that keep those changes from quietly breaking results.

These practices save time because they turn vague trust into concrete
checks. Clear tests protect user-facing behavior, documentation lowers
the cost of reuse, and CI catches hidden environment problems before a
user (potentially you) discovers them the hard way.

### Learning Objectives

By the end of this session, you will be able to:

1.  Add pkgdown functionality to the package and build a local
    documentation website
2.  Set up CI to run R CMD check and deploy a pkgdown site (GitHub
    Pages)
3.  Create and run meaningful unit tests locally with testthat
4.  Distinguish public behavior that should be tested from
    implementation details that should stay flexible
5.  Explain why tests and CI are essential for maintainability,
    refactoring safety, and hidden-assumption detection

------------------------------------------------------------------------

## The Feature Ritual

From this point forward, every feature we add follows this ritual:

    ┌─────────────┐    ┌───────────┐    ┌────────┐    ┌─────────┐    ┌────────┐
    │ Implement   │ →  │ Document  │ →  │ Test   │ →  │ Check   │ →  │ Commit │
    └─────────────┘    └───────────┘    └────────┘    └─────────┘    └────────┘

1.  **Implement** — Write or modify code
2.  **Document** — Add/update roxygen2 docs and README, run
    `devtools::document()`
3.  **Test** — Add/update testthat tests
4.  **Check** — Run `devtools::check()`
5.  **Commit** — Push to GitHub

Today, we add the testing and documentation infrastructure that makes
this workflow sustainable.

------------------------------------------------------------------------

## Part 1: Unit Testing with testthat

### Why Test?

> “Tests are essential for maintainability and safe refactoring.”

Consider this scenario:

1.  You write
    [`run_pca()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_pca.md)
    and it works
2.  A month later, you optimize
    [`top_variable_features()`](https://st-jude-ms-abds.github.io/ADS8192/reference/top_variable_features.md)
    for speed
3.  You accidentally change the output format
4.  [`run_pca()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_pca.md)
    now silently returns wrong results
5.  You don’t notice until you’ve submitted a paper using these improper
    results
6.  You cry a bit

**Tests prevent this.** They’re automated checks that verify your code
still works in the way you intended after changes.

### What Should Tests Protect?

In scientific software, the highest-value tests usually protect:

- **Public contracts**: returned classes, column names, file outputs,
  and error messages that users rely on
- **Assumptions**: dimensionality, valid parameter ranges, and
  meaningful edge cases
- **Cross-interface behavior**:

Avoid overfitting tests to incidental implementation details such as
temporary variable names or the exact internal sequence of helper calls.
Good tests make refactoring safer; brittle tests make refactoring
harder.

### A Note on Pointless Testing

Much like the American education system, pointless tests are a real
detriment to proper code maintenance and software robustness.

Tests should be meaningful.

Before you add a test, ask:

- What public behavior or assumption am I protecting?
- Would this failure matter to a user or downstream interface?
- Will the check run in a clean environment with only declared
  dependencies?
- If the code changes, will these checks catch regressions that matter?

------------------------------------------------------------------------

### Setting Up testthat

Setting up test scaffolding for your package is super simple.

``` r
library(devtools)
library(usethis)
library(testthat)

# Initialize testthat infrastructure
use_testthat()
```

This creates:

    tests/
    ├── testthat/           # Your test files go here
    └── testthat.R          # Test runner script

And adds to DESCRIPTION:

``` yaml
Suggests:
    testthat (>= 3.0.0)
Config/testthat/edition: 3
```

### Writing Your First Test

``` r
# Create a test file for data functions
use_test("data")
```

This creates `tests/testthat/test-data.R`. Edit it:

``` r
# tests/testthat/test-data.R

test_that("top_variable_features returns correct subset size", {
    data(example_se, package = "ADS8192")

    se_top <- top_variable_features(example_se, n = 50)

    expect_equal(nrow(se_top), 50)
    expect_equal(ncol(se_top), ncol(example_se))  # Same samples
})

test_that("top_variable_features returns most variable genes", {
    data(example_se, package = "ADS8192")

    se_top <- top_variable_features(example_se, n = 10)
    mat <- SummarizedExperiment::assay(se_top, "counts")
    vars <- apply(mat, 1, var)

    # All variances in top-10 should be >= the 11th highest
    full_mat <- SummarizedExperiment::assay(example_se, "counts")
    full_vars <- sort(apply(full_mat, 1, var), decreasing = TRUE)
    expect_true(all(vars >= full_vars[11]))
})

test_that("top_variable_features handles n > nrow gracefully", {
    data(example_se, package = "ADS8192")

    se_all <- top_variable_features(example_se, n = 100000)

    expect_equal(nrow(se_all), nrow(example_se))
})

test_that("run_pca returns correct structure", {
    data(example_se, package = "ADS8192")

    result <- run_pca(example_se, n_top = 50)

    expect_type(result, "list")
    expect_named(result, c("pca", "scores"))
})
```

### Test Structure: The Three A’s

Every test follows this pattern:

``` r
test_that("description of what we're testing", {
    # ARRANGE - Set up data and conditions
    data(example_se, package = "ADS8192")

    # ACT - Run the code being tested
    result <- top_variable_features(example_se, n = 50)

    # ASSERT - Check the results
    expect_equal(nrow(result), 50)
})
```

### Running Tests

Actually running the tests is also simple.

``` r
# Run all tests
test()

# Run a specific test file
test_file("tests/testthat/test-data.R")

# In RStudio: Ctrl+Shift+T

# devtools::check() will also run all tests in a package by default
```

Expected output:

    ℹ Testing ADS8192
    ✔ | F W S  OK | Context
    ✔ |         4 | data

    ══ Results ═════════════════════════════════════════════════════════════════
    [ FAIL 0 | WARN 0 | SKIP 0 | PASS 4 ]

------------------------------------------------------------------------

### Common testthat Expectations

[testthat](https://st-jude-ms-abds.github.io/ADS8192/articles/) includes
many ways to check for expected results from specific scenarios. Some of
the most common ones include:

``` r
# Common testthat expect_*() functions — reference

# Equality
expect_equal(x, y)           # Equal with tolerance
expect_identical(x, y)       # Exactly identical

# Types and classes
expect_type(x, "list")       # Base R type
expect_s3_class(x, "data.frame")  # S3 class
expect_s4_class(x, "SummarizedExperiment")  # S4 class

# Logical
expect_true(x)
expect_false(x)
expect_null(x)

# Errors and warnings
expect_error(f(), "pattern")     # Function errors with message
expect_warning(f(), "pattern")   # Function warns with message
expect_message(f(), "pattern")   # Function messages

# Comparisons
expect_gt(x, y)   # x > y
expect_lt(x, y)   # x < y
expect_gte(x, y)  # x >= y
expect_lte(x, y)  # x <= y

# Collections
expect_length(x, 5)
expect_named(x, c("a", "b"))
expect_contains(x, "value")

# Output
expect_output(print(x), "pattern")
expect_snapshot(x)  # For complex output comparisons
```

------------------------------------------------------------------------

### Test-Driven Development (TDD)

**Test-driven development (TDD)** is a development process where you
write tests before writing the code that implements the functionality.
The cycle is:

1.  Write one or more tests that define a desired functionality (these
    tests will fail because the functionality doesn’t exist yet)
2.  Write the minimum amount of code needed to make the tests pass
3.  Refactor the code while ensuring the tests still pass

This process helps ensure that your code is testable, that you only
write code that is necessary to meet the requirements, and that you have
a safety net of tests to catch regressions as you refactor.

This can be especially helpful in scientific software, where the
“requirements” are often defined by the expected behavior of the
analysis rather than a strict specification. By writing tests first, you
can clarify your assumptions and ensure that your code meets the
intended behavior from the start.

TDD can feel a bit unnatural at first, but it can be a powerful approach
to writing reliable and elegant code that actually does what you need it
to do.

As a bonus, AI agents are *very* good at writing code to meet test
specifications as it has a ground truth to work towards. This can make
TDD a great way to leverage AI assistance effectively while minimizing
how much handholding is required.

#### An Example

Currently,
[`run_pca()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_pca.md)
doesn’t validate that `n_top` is a positive integer. Let’s fix that.

#### Step 1: Write a Failing Test

``` r
test_that("run_pca errors on negative n_top", {
    data(example_se, package = "ADS8192")

    expect_error(run_pca(example_se, n_top = -5), "positive")
})
```

#### Step 2: Run Test (Should Fail)

``` r
test()  # This should show 1 failure
```

#### Step 3: Fix the Code

Add to
[`run_pca()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_pca.md):

``` r
run_pca <- function(se, assay_name = "counts", n_top = 500,
                    scale = TRUE, log_transform = TRUE) {
    # ADD THIS CHECK
    if (!is.numeric(n_top) || n_top <= 0) {
        stop("n_top must be a positive number")
    }

    # ... rest of function
}
```

#### Step 4: Run Test (Should Pass)

``` r
test()  # All tests should pass now
```

------------------------------------------------------------------------

### Write Tests for PCA Functions

``` r
use_test("pca")
```

``` r
# tests/testthat/test-pca.R

test_that("run_pca returns correct structure", {
    data(example_se, package = "ADS8192")

    result <- run_pca(example_se, n_top = 50)

    expect_type(result, "list")
    expect_named(result, c("pca", "scores"))
    expect_s3_class(result$pca, "prcomp")
    expect_s3_class(result$scores, "data.frame")
})

test_that("run_pca scores contain sample metadata", {
    data(example_se, package = "ADS8192")

    result <- run_pca(example_se, n_top = 50)

    # Should have treatment column from colData
    expect_true("treatment" %in% colnames(result$scores))
    expect_true("sample_id" %in% colnames(result$scores))
})

test_that("run_pca returns expected number of PCs", {
    data(example_se, package = "ADS8192")

    result <- run_pca(example_se, n_top = 50)

    # Should have PCs equal to min(n_samples, n_features)
    n_samples <- ncol(example_se)
    expect_true(paste0("PC", 1) %in% colnames(result$scores))
    expect_true(paste0("PC", n_samples) %in% colnames(result$scores))
})

test_that("pca_variance_explained returns percentages", {
    data(example_se, package = "ADS8192")

    result <- run_pca(example_se, n_top = 50)
    var_df <- pca_variance_explained(result)

    # Variance should sum to 100
    expect_equal(sum(var_df$variance_percent), 100, tolerance = 0.01)

    # Should be sorted descending (PC1 explains most)
    expect_true(var_df$variance_percent[1] >= var_df$variance_percent[2])
})
```

------------------------------------------------------------------------

## Part 2: Documentation Website with pkgdown

### Why pkgdown?

pkgdown converts your package documentation into a beautiful website:

- Auto-generated from your roxygen2 docs and README
- Hosts vignettes (long-form articles)
- Function reference with nice formatting
- Search functionality
- Can deploy automatically via GitHub Pages

### Setting Up pkgdown

``` r
# Add pkgdown infrastructure
use_pkgdown()
```

This creates:

- `_pkgdown.yml` — Configuration file
- Updates `.Rbuildignore` to ignore the site files

### Build the Site Locally

``` r
# Build the documentation site
pkgdown::build_site()
```

This creates a `docs/` directory with the website. Open
`docs/index.html` in a browser to preview.

### Customize the Site

Edit `_pkgdown.yml`:

``` yaml
url: https://your-username.github.io/ADS8192/

template:
  bootstrap: 5
  bootswatch: flatly

navbar:
  structure:
    left:  [intro, reference, articles]
    right: [search, github]

reference:
  - title: "Data Handling"
    desc: "Create and manipulate SummarizedExperiment objects"
    contents:
      - top_variable_features

  - title: "PCA Analysis"
    desc: "Run and analyze PCA"
    contents:
      - run_pca
      - pca_variance_explained

  - title: "Visualization"
    desc: "Create plots"
    contents:
      - plot_pca

articles:
  - title: "Getting Started"
    contents:
      - getting-started
```

### Create a “Getting Started” Article

``` r
use_vignette("getting-started", title = "Getting Started with ADS8192")
```

This creates `vignettes/getting-started.Rmd`. Edit it to include a
tutorial:

```` markdown
---
title: "Getting Started with ADS8192"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{Getting Started with ADS8192}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
```

## Introduction

ADS8192 makes it easy to run PCA on RNA-seq data stored in SummarizedExperiment objects.

## Quick Example

```{r example}
library(ADS8192)

# Load example data
data(example_se)
example_se

# Run PCA
result <- run_pca(example_se, n_top = 50)

# Plot
plot_pca(result, color_by = "treatment")
```

## Using Real Data

```{r airway}
library(airway)
data(airway)

# Run PCA on airway data
result <- run_pca(airway, n_top = 500)

# Visualize treatment effect
plot_pca(result, color_by = "dex", shape_by = "cell")
```
````

> **Exercise B:** Ensure every argument of your exported functions is
> documented. Check by building the pkgdown site and clicking through
> each function’s reference page.

------------------------------------------------------------------------

## Part 3: Continuous Integration with GitHub Actions

### What is CI?

**Continuous Integration (CI)** automatically runs tests and checks
whenever you push code. This ensures:

- Tests pass on multiple platforms (Linux, Mac, Windows)
- R CMD check passes
- The pkgdown site builds successfully

### Set Up GitHub Actions

``` r
# R CMD check on push/PR
use_github_action("check-standard")
```

This creates `.github/workflows/R-CMD-check.yaml`:

``` yaml
on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]

name: R-CMD-check

jobs:
  R-CMD-check:
    runs-on: ${{ matrix.config.os }}
    name: ${{ matrix.config.os }} (${{ matrix.config.r }})
    strategy:
      matrix:
        config:
          - {os: macos-latest,   r: 'release'}
          - {os: windows-latest, r: 'release'}
          - {os: ubuntu-latest,  r: 'release'}
```

### Add pkgdown Deployment

``` r
# Auto-deploy pkgdown site to GitHub Pages
use_github_action("pkgdown")
```

This creates `.github/workflows/pkgdown.yaml` that:

1.  Builds the pkgdown site
2.  Deploys to the `gh-pages` branch
3.  GitHub Pages serves it at `https://username.github.io/ADS8192/`

### Configure GitHub Pages

After pushing, go to your GitHub repo:

1.  Settings → Pages
2.  Source: Deploy from a branch
3.  Branch: `gh-pages` / `root`
4.  Save

### Push and Verify

``` r
# Commit all changes
# git add -A
# git commit -m "Add tests, pkgdown, and CI"
# git push
```

Go to your GitHub repo → Actions tab to watch the workflows run.

------------------------------------------------------------------------

### Adding Badges

Show off your CI status on your README:

``` r
use_github_actions_badge("R-CMD-check")
use_github_actions_badge("pkgdown")
```

This adds to your README:

``` markdown
<!-- badges: start -->
[![R-CMD-check](https://github.com/user/ADS8192/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/user/ADS8192/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/user/ADS8192/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/user/ADS8192/actions/workflows/pkgdown.yaml)
<!-- badges: end -->
```

------------------------------------------------------------------------

## Part 4: The Complete Workflow

Let’s practice the full feature ritual by adding a small feature.

### Feature: Add `save_pca_results()` Function

#### Step 1: Implement

``` r
use_r("export")
```

``` r
# R/export.R — save_pca_results() function

#' Save PCA results to files
#'
#' @param pca_result Output from run_pca()
#' @param output_dir Directory to save files
#' @param prefix Prefix for filenames (default: "pca")
#'
#' @return Invisible NULL; files are written to output_dir
#' @export
#'
#' @examples
#' \dontrun{
#' result <- run_pca(se)
#' save_pca_results(result, "output/")
#' }
save_pca_results <- function(pca_result, output_dir, prefix = "pca") {
    if (!dir.exists(output_dir)) {
        dir.create(output_dir, recursive = TRUE)
    }

    # Save scores
    scores_file <- file.path(output_dir, paste0(prefix, "_scores.tsv"))
    utils::write.table(
        pca_result$scores,
        scores_file,
        sep = "\t",
        row.names = FALSE,
        quote = FALSE
    )

    # Save variance explained
    var_file <- file.path(output_dir, paste0(prefix, "_variance.tsv"))
    var_df <- pca_variance_explained(pca_result)
    utils::write.table(
        var_df,
        var_file,
        sep = "\t",
        row.names = FALSE,
        quote = FALSE
    )

    message("Saved: ", scores_file)
    message("Saved: ", var_file)

    invisible(NULL)
}
```

#### Step 2: Document

``` r
document()  # Generate Rd file
```

#### Step 3: Test

``` r
use_test("export")
```

``` r
# tests/testthat/test-export.R

test_that("save_pca_results creates files", {
    data(example_se, package = "ADS8192")
    result <- run_pca(example_se, n_top = 50)

    # Use a temporary directory
    tmp_dir <- tempdir()
    output_dir <- file.path(tmp_dir, "test_output")

    save_pca_results(result, output_dir, prefix = "test")

    # Check files exist
    expect_true(file.exists(file.path(output_dir, "test_scores.tsv")))
    expect_true(file.exists(file.path(output_dir, "test_variance.tsv")))

    # Check scores file has correct structure
    scores <- read.table(
        file.path(output_dir, "test_scores.tsv"),
        header = TRUE,
        sep = "\t"
    )
    expect_true("PC1" %in% colnames(scores))
    expect_true("sample_id" %in% colnames(scores))

    # Clean up
    unlink(output_dir, recursive = TRUE)
})
```

#### Step 4: Check

``` r
check()  # Should pass with 0 errors, 0 warnings
```

#### Step 5: Commit

``` r
# git add -A
# git commit -m "Add save_pca_results() for exporting PCA outputs"
# git push
```

------------------------------------------------------------------------

## Summary

Today we:

1.  Set up testthat and wrote unit tests
2.  Practiced test-driven development (TDD)
3.  Added pkgdown for documentation websites
4.  Configured GitHub Actions for CI/CD
5.  Practiced the complete feature ritual

### Package Milestone

✅ Package has tests and CI, and a pkgdown site can be built (and
optionally deployed) from GitHub.

------------------------------------------------------------------------

### Debrief & Reflection

Before moving on, make sure you can answer:

- Which parts of your package are true contracts that deserve tests?
- Which failures would only appear on a clean machine or another
  platform if CI did not exist?
- How do `testthat`, `pkgdown`, and CI let you avoid reinventing
  infrastructure so you can focus on analysis quality?

------------------------------------------------------------------------

## After-Class Tasks

### Micro-task 1: Add Tests

Add at least 5 test expectations across ≥2 test files. Ensure all tests
pass.

Ideas: - Test
[`plot_pca()`](https://st-jude-ms-abds.github.io/ADS8192/reference/plot_pca.md)
returns a ggplot object - Test
[`plot_pca()`](https://st-jude-ms-abds.github.io/ADS8192/reference/plot_pca.md)
with different `pcs` values - Test edge cases (what happens with n_top
\> nrow?)

### Micro-task 2: Build pkgdown

Build the pkgdown site locally and commit the config changes
(`_pkgdown.yml`).

### Optional: Badges

Add R CMD check and pkgdown badges to your README.

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
