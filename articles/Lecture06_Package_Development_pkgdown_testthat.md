# Lecture 6: Lab – R Package Development (pkgdown, testthat)

## Learning Objectives

By the end of this session, you will be able to:

1.  Add pkgdown functionality to the package and build a local
    documentation website
2.  Set up CI to run R CMD check and deploy a pkgdown site (GitHub
    Pages)
3.  Create and run basic unit tests locally with testthat
4.  Explain why tests are essential for maintainability and safe
    refactoring

**Course Learning Outcomes (CLOs):** CLO 1, 4, 6

------------------------------------------------------------------------

## The Feature Ritual

From this point forward, every feature we add follows this ritual:

    ┌─────────────┐    ┌───────────┐    ┌────────┐    ┌─────────┐    ┌────────┐
    │ Implement   │ → │ Document  │ → │ Test   │ → │ Check   │ → │ Commit │
    └─────────────┘    └───────────┘    └────────┘    └─────────┘    └────────┘

1.  **Implement** — Write or modify code
2.  **Document** — Add/update roxygen2 docs and README
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
    [`run_pca()`](https://automatic-engine-4qp7m5e.pages.github.io/reference/run_pca.md)
    and it works
2.  A month later, you optimize
    [`top_variable_features()`](https://automatic-engine-4qp7m5e.pages.github.io/reference/top_variable_features.md)
    for speed
3.  You accidentally change the output format
4.  [`run_pca()`](https://automatic-engine-4qp7m5e.pages.github.io/reference/run_pca.md)
    now silently returns wrong results
5.  You don’t notice until a reviewer questions your paper’s figures

**Tests prevent this.** They’re automated checks that verify your code
still works after changes.

### Setting Up testthat

``` r
library(devtools)
library(usethis)

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

test_that("make_se creates correct class", {
    counts <- matrix(rpois(100, 50), nrow = 10, ncol = 10)
    rownames(counts) <- paste0("gene", 1:10)
    colnames(counts) <- paste0("sample", 1:10)
    meta <- data.frame(
        treatment = rep(c("ctrl", "trt"), each = 5),
        row.names = colnames(counts)
    )
    
    se <- make_se(counts, meta)
    
    expect_s4_class(se, "SummarizedExperiment")
})

test_that("make_se has correct dimensions", {
    counts <- matrix(rpois(100, 50), nrow = 10, ncol = 10)
    rownames(counts) <- paste0("gene", 1:10)
    colnames(counts) <- paste0("sample", 1:10)
    meta <- data.frame(
        treatment = rep(c("ctrl", "trt"), each = 5),
        row.names = colnames(counts)
    )
    
    se <- make_se(counts, meta)
    
    expect_equal(nrow(se), 10)
    expect_equal(ncol(se), 10)
})

test_that("make_se errors on mismatched samples", {
    counts <- matrix(rpois(100, 50), nrow = 10, ncol = 10)
    rownames(counts) <- paste0("gene", 1:10)
    colnames(counts) <- paste0("sample", 1:10)
    meta <- data.frame(
        treatment = rep(c("ctrl", "trt"), each = 5),
        row.names = paste0("wrong", 1:10)  # Wrong names!
    )
    
    expect_error(make_se(counts, meta), "must match")
})

test_that("top_variable_features returns subset", {
    data(example_se, package = "sePCA")
    
    se_top <- top_variable_features(example_se, n = 50)
    
    expect_equal(nrow(se_top), 50)
    expect_equal(ncol(se_top), ncol(example_se))  # Same samples
})
```

### Test Structure: The Three A’s

Every test follows this pattern:

``` r
test_that("description of what we're testing", {
    # ARRANGE - Set up data and conditions
    counts <- matrix(...)
    
    # ACT - Run the code being tested
    result <- make_se(counts, meta)
    
    # ASSERT - Check the results
    expect_equal(nrow(result), expected_value)
})
```

### Running Tests

``` r
# Run all tests
test()

# Run a specific test file
test_file("tests/testthat/test-data.R")

# In RStudio: Ctrl+Shift+T
```

Expected output:

    ℹ Testing sePCA
    ✔ | F W S  OK | Context
    ✔ |         4 | data

    ══ Results ═════════════════════════════════════════════════════════════════
    [ FAIL 0 | WARN 0 | SKIP 0 | PASS 4 ]

------------------------------------------------------------------------

### Exercise A: Test-First Development

Let’s practice **test-driven development (TDD)**: write the test before
fixing the bug.

#### The Bug

Currently,
[`make_se()`](https://automatic-engine-4qp7m5e.pages.github.io/reference/make_se.md)
doesn’t check if the counts matrix has numeric values. Let’s fix that.

#### Step 1: Write a Failing Test

``` r
test_that("make_se errors on non-numeric counts", {
    counts <- matrix(letters[1:100], nrow = 10, ncol = 10)  # Character!
    rownames(counts) <- paste0("gene", 1:10)
    colnames(counts) <- paste0("sample", 1:10)
    meta <- data.frame(
        treatment = rep(c("ctrl", "trt"), each = 5),
        row.names = colnames(counts)
    )
    
    expect_error(make_se(counts, meta), "numeric")
})
```

#### Step 2: Run Test (Should Fail)

``` r
test()  # This should show 1 failure
```

#### Step 3: Fix the Code

Add to
[`make_se()`](https://automatic-engine-4qp7m5e.pages.github.io/reference/make_se.md):

``` r
make_se <- function(counts, col_data, row_data = NULL) {
    if (!is.matrix(counts)) {
        counts <- as.matrix(counts)
    }
    
    # ADD THIS CHECK
    if (!is.numeric(counts)) {
        stop("counts must be a numeric matrix")
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
    data(example_se, package = "sePCA")
    
    result <- run_pca(example_se, n_top = 50)
    
    expect_type(result, "list")
    expect_named(result, c("pca", "scores"))
    expect_s3_class(result$pca, "prcomp")
    expect_s3_class(result$scores, "data.frame")
})

test_that("run_pca scores contain sample metadata", {
    data(example_se, package = "sePCA")
    
    result <- run_pca(example_se, n_top = 50)
    
    # Should have treatment column from colData
    expect_true("treatment" %in% colnames(result$scores))
    expect_true("sample_id" %in% colnames(result$scores))
})

test_that("run_pca returns expected number of PCs", {
    data(example_se, package = "sePCA")
    
    result <- run_pca(example_se, n_top = 50)
    
    # Should have PCs equal to min(n_samples, n_features)
    n_samples <- ncol(example_se)
    expect_true(paste0("PC", 1) %in% colnames(result$scores))
    expect_true(paste0("PC", n_samples) %in% colnames(result$scores))
})

test_that("pca_variance_explained returns percentages", {
    data(example_se, package = "sePCA")
    
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
url: https://your-username.github.io/sePCA/

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
      - make_se
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
use_vignette("getting-started", title = "Getting Started with sePCA")
```

This creates `vignettes/getting-started.Rmd`. Edit it to include a
tutorial:

```` markdown
---
title: "Getting Started with sePCA"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{Getting Started with sePCA}
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

sePCA makes it easy to run PCA on RNA-seq data stored in SummarizedExperiment objects.

## Quick Example

```{r example}
library(sePCA)

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
3.  GitHub Pages serves it at `https://username.github.io/sePCA/`

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
[![R-CMD-check](https://github.com/user/sePCA/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/user/sePCA/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/user/sePCA/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/user/sePCA/actions/workflows/pkgdown.yaml)
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
# R/export.R

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
    data(example_se, package = "sePCA")
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

## After-Class Tasks

### Micro-task 1: Add Tests

Add at least 5 test expectations across ≥2 test files. Ensure all tests
pass.

Ideas: - Test
[`plot_pca()`](https://automatic-engine-4qp7m5e.pages.github.io/reference/plot_pca.md)
returns a ggplot object - Test
[`plot_pca()`](https://automatic-engine-4qp7m5e.pages.github.io/reference/plot_pca.md)
with different `pcs` values - Test edge cases (what happens with n_top
\> nrow?)

### Micro-task 2: Build pkgdown

Build the pkgdown site locally and commit the config changes
(`_pkgdown.yml`).

### Optional: Badges

Add R CMD check and pkgdown badges to your README.

------------------------------------------------------------------------

## Common testthat Expectations

``` r
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

## Session Info

``` r
sessionInfo()
```

    ## R version 4.5.2 (2025-10-31)
    ## Platform: x86_64-pc-linux-gnu
    ## Running under: Ubuntu 24.04.3 LTS
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
    ##  [5] xfun_0.56         cachem_1.1.0      knitr_1.51        htmltools_0.5.9  
    ##  [9] rmarkdown_2.30    lifecycle_1.0.5   cli_3.6.5         sass_0.4.10      
    ## [13] pkgdown_2.2.0     textshaping_1.0.4 jquerylib_0.1.4   systemfonts_1.3.1
    ## [17] compiler_4.5.2    tools_4.5.2       ragg_1.5.0        bslib_0.10.0     
    ## [21] evaluate_1.0.5    yaml_2.3.12       otel_0.2.0        jsonlite_2.0.0   
    ## [25] rlang_1.1.7       fs_1.6.6          htmlwidgets_1.6.4
