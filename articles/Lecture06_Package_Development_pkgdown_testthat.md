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
# Create a test file for pca functions
use_test("pca")
```

This creates `tests/testthat/test-pca.R`. Edit it:

``` r
# tests/testthat/test-pca.R

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
test_file("tests/testthat/test-pca.R")

# In RStudio: Ctrl+Shift+T

# devtools::check() will also run all tests in a package by default
```

Expected output:

    ℹ Testing ADS8192
    ✔ | F W S  OK | Context
    ✔ |         4 | pca

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

### Writing a Few More Tests

Below are examples of a covering a few more bases for inspiration.

Click to expand more test examples

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

[pkgdown](https://pkgdown.r-lib.org/) converts your package
documentation into a nicely formatted, automatically-generated website
that provides:

- A landing page showing your README content
- Rendered vignettes/articles
- Function reference with nice formatting
- Search functionality
- Can deploy automatically via GitHub Pages

### Setting Up pkgdown

[pkgdown](https://pkgdown.r-lib.org/) is easy to setup. We want to host
our pkgdown site on GitHub Pages, which is free and integrates well with
GitHub Actions for automatic deployment.

To do so, we’re going to take a little shortcut provided by `usethis`,
the
[use_pkgdown_github_pages()](https://usethis.r-lib.org/reference/use_pkgdown_github_pages.html)
function.

``` r
# Add pkgdown infrastructure
use_pkgdown_github_pages()
```

This will:

- Create `_pkgdown.yml` — Configuration file for pkgdown
- Update `.Rbuildignore` to ignore the site files
- Add `pkgdown` to Suggests in DESCRIPTION
- Configure GitHub Pages to serve from the `gh-pages` branch
- Add a [GitHub Actions](https://docs.github.com/en/actions) workflow
  for building and deploying the site (we’ll cover this in the CI
  section)
- Add the pkgdown site URL to the DESCRIPTION file, the pkgdown YAML,
  and to the Github repo (in the sidebar).

### Build the Site Locally

``` r
# Build the documentation site
pkgdown::build_site()
```

This creates a `docs/` directory with the website. Open
`docs/index.html` in a browser to preview - it should just show your
README content for now.

Git will ignore the `docs/` directory because of the .Rbuildignore
entry, so you can build and test locally without worrying about
committing these files.

### Customize the Site

To [customise your
site](https://pkgdown.r-lib.org/articles/customise.html), you can edit
`_pkgdown.yml` as you’d like. Theming, navbar structure, content
organization and more can be customized here.

For example, if you had several functions all related to data handling,
you could group them together in the reference section. Or the same for
plotting functions.

For example, this entire unit is just a series of articles hosted on a
pkgdown site, and I use the config to group them together under a
“Course Materials” dropdown in the navbar:

Click to see the full \_pkgdown.yml

``` yaml
url: https://st-jude-ms-abds.github.io/ADS8192/
template:
  bootstrap: 5
  bootswatch: flatly
  light-switch: true
navbar:
  structure:
    left:
    - intro
    - reference
    - articles
    right:
    - search
    - github
  components:
    articles:
      text: Course Materials
      menu:
      - text: Course Setup
        href: articles/course-setup.html
      - text: Getting Started
        href: articles/getting-started.html
      - text: Project Selection Guide
        href: articles/project-selection.html
      - text: 'Homework 1 Rubric'
        href: articles/HW1_Rubric.html
      - text: '---'
      - text: Lectures
      - text: 'Lecture 04: Data Structures & R Ecosystems'
        href: articles/Lecture04_Data_Structures_Bioconductor.html
      - text: 'Lecture 05: R Package Development (devtools)'
        href: articles/Lecture05_Package_Development_devtools.html
      - text: 'Lecture 06: R Package Documentation & Testing (pkgdown, testthat)'
        href: articles/Lecture06_Package_Development_pkgdown_testthat.html
      - text: 'Lecture 07: Shiny Application Development'
        href: articles/Lecture07_Shiny_Reactivity.html
      - text: 'Lecture 08: Shiny Application Packaging & Deployment'
        href: articles/Lecture08_Shiny_Packaging_Deployment.html
      - text: 'Lecture 09: CLI Design & Development (Rapp)'
        href: articles/Lecture09_CLI_Design_Rapp.html
      - text: 'Lecture 10: CLI Packaging & Installation'
        href: articles/Lecture10_CLI_Packaging_Installation.html
      - text: 'Lecture 11: Review & Q/A'
        href: articles/Lecture11_Review_QA.html
reference:
- title: Data Handling
  desc: Create and manipulate SummarizedExperiment objects
  contents:
  - top_variable_features
- title: PCA Analysis
  desc: Run and analyze PCA
  contents:
  - run_pca
  - pca_variance_explained
- title: Visualization
  desc: Create plots
  contents:
  - plot_pca
  - plot_variance_explained
- title: Export
  desc: Save results to files
  contents: save_pca_results
- title: Interactive App
  desc: Shiny web application
  contents: run_app
articles:
- title: Getting Started
  navbar: ~
  contents:
  - "`getting-started`"
  - "`articles/course-setup`"
- title: Assessments
  navbar: ~
  contents:
  - "`articles/project-selection`"
  - "`articles/HW1_Rubric`"
- title: Lectures
  navbar: ~
  contents:
  - "`articles/Lecture04_Data_Structures_Bioconductor`"
  - "`articles/Lecture05_Package_Development_devtools`"
  - "`articles/Lecture06_Package_Development_pkgdown_testthat`"
  - "`articles/Lecture07_Shiny_Reactivity`"
  - "`articles/Lecture08_Shiny_Packaging_Deployment`"
  - "`articles/Lecture09_CLI_Design_Rapp`"
  - "`articles/Lecture10_CLI_Packaging_Installation`"
  - "`articles/Lecture11_Review_QA`"
```

### Creating a “Getting Started” Article

[Vignettes](https://r-pkgs.org/vignettes.html) are long-form articles
that can include code, text, and figures. They’re great for tutorials
and detailed explanations. They allow you to provide rationale, context,
and examples that go beyond what function documentation can cover.

Nobody will use your package if they don’t understand what it offers and
how to use it. So take your time to show off what your package can do.

``` r
use_vignette("getting-started", title = "Getting Started with ADS8192")
```

This creates `vignettes/getting-started.Rmd`. This is an
[Rmarkdown](https://rmarkdown.rstudio.com/) file, so you can write in
markdown and include code chunks that will be rendered when the vignette
is built.

[markdown](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax)
is a simple markup language that allows you to easily format text,
create lists, add hyperlinks, etc. Rmarkdown extends this by allowing
you to include executable R code chunks that can generate output and
figures directly in the document.

See a handy [cheatsheet for
Rmarkdown](https://github.com/rstudio/cheatsheets/raw/main/rmarkdown-2.0.pdf)
if you’d like to learn more about it.

Now we can edit this file to include a tutorial:

```` markdown
---
title: "Getting Started with ADS8192"
output: rmarkdown::html_vignette
author: "Jared Andrews"
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

Your vignette should probably be a bit more expansive than this.

------------------------------------------------------------------------

## Part 3: Continuous Integration with GitHub Actions

### What is CI?

**Continuous Integration (CI)** automatically runs some set of actions
at specific times (like when you open a pull request, push a commit,
etc). These actions can span lots of things, but common cases include
running tests, building/compiling releases, checking code validity,
running linter/formatting tools, and more.

For us, CI ensures:

- Tests pass on multiple platforms (Linux, Mac, Windows)
- R CMD check passes on multiple platforms and/or R versions
- The pkgdown site builds and deploys successfully

This isn’t just an R thing. CI is a standard practice in software
development that helps catch issues early and maintain high code
quality.

### Set Up GitHub Actions

CI is simple to set up with [GitHub
Actions](https://docs.github.com/en/actions). Technically, we’ve already
set up an actions workflow with `use_pkgdown_github_pages()`, so you
should already have a `.github/workflows/pkgdown.yaml` file in your
repo.

There are other useful pre-built workflows for R packages that you can
use with a single command to run `check` on multiple platforms/R
versions every time the code is changed.

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
      fail-fast: false
      matrix:
        config:
          - {os: macos-latest,   r: 'release'}
          - {os: windows-latest, r: 'release'}
          - {os: ubuntu-latest,  r: 'release'}

    env:
      GITHUB_PAT: ${{ secrets.GITHUB_TOKEN }}
      R_KEEP_PKG_SOURCE: yes

    steps:
      - uses: actions/checkout@v4

      - uses: r-lib/actions/setup-pandoc@v2

      - uses: r-lib/actions/setup-r@v2
        with:
          r-version: ${{ matrix.config.r }}
          http-user-agent: ${{ matrix.config.http-user-agent }}
          use-public-rspm: true

      - uses: r-lib/actions/setup-r-dependencies@v2
        with:
          extra-packages: any::rcmdcheck
          needs: check

      - uses: r-lib/actions/check-r-package@v2
        with:
          upload-snapshots: true
          build_args: 'c("--no-manual","--compact-vignettes=gs+qpdf")'
```

This file is pretty simple. “on” specifies the events that trigger the
workflow (push or PR to main/master, you could add other branches if
wanted). “jobs” defines the tasks to run, and “strategy” sets up a
matrix of OS and R version combinations to test against. “env” sets
environment variables, and “steps” lists the individual steps to
execute, such as checking out the code, setting up R and pandoc,
installing dependencies, and running R CMD check.

There are a whole host of pre-built general and language-task specific
actions/workflows for R packages that you can find in the [usethis
documentation](https://usethis.r-lib.org/reference/use_github_action.html)
and the [GitHub Actions
Marketplace](https://github.com/marketplace?type=actions).

CI is powerful and easy to set up. You can do some very complex things
with it, but it doesn’t have to be complex to be extremely useful.

### Adding Badges

You may have noticed badges on Github repos that show the result of CI
workflows or link to package repositories, etc. These are a nice way to
show off the health of your package and provide quick links to important
resources.

Let’s add those to our repo as well:

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

These badges will show green if the workflow is passing and red if it’s
failing, providing a quick visual indicator of your package’s health.

It lets potential users know that you both have a valid package and a
documentation site, which is always a good look.

### Push and Verify

After adding all of this, go ahead and push your changes to Github:

``` r
# Commit all changes
# git add .
# git commit -m "Add tests, pkgdown, and CI"
# git push
```

Go to your GitHub repo → Actions tab to watch the workflows run. They
provide logs in real-time, and if they fail, you can see which step
failed and the error messages to help you debug. You’ll also get an
email if a workflow fails, which can be helpful to catch issues on
previously “stable” repos when something changes in the environment
(like a new R version or a dependency update).

------------------------------------------------------------------------

## Part 4: The Complete Workflow

Let’s practice the full feature ritual by adding a small feature.

### Feature: Add `save_pca_results()` Function

I want to add a function that just dumps all the PCA results to files so
I can use them in other contexts, share them easily, maybe use them in a
publication, etc.

#### Step 1: Implement

``` r
use_r("export")
```

``` r
# R/export.R — save_pca_results() function

#' Save PCA results to files
#'
#' @param pca_result Output from `run_pca()`
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
# git add .
# git commit -m "Add save_pca_results() for exporting PCA outputs"
# git push
```

Once our actions run, we should see the new function on our pkgdown
site, and we should have a new passing test in our CI workflow.

This is the power of the feature ritual. It ensures that every change we
make is well-documented, tested, and integrated into our package in a
way that maintains quality and reliability.

This process is particularly important in scientific software, where
silent failures can be dreadful. By following this ritual, we can have
confidence that our package continues to work as intended even as we add
new features and make improvements over time. As a codebase grows, this
discipline will save you from many headaches and allow others to
contribute more easily as well.

It can feel like extra work in the moment, but it saves you time and
stress in the long run.

------------------------------------------------------------------------

## Summary

Today we:

1.  Set up testthat and wrote unit tests
2.  Practiced test-driven development (TDD)
3.  Added pkgdown for documentation websites
4.  Configured GitHub Actions for CI/CD
5.  Practiced the complete feature ritual

### Package Milestone

Package has tests and CI, and a pkgdown site built directly from GitHub.

At this point, people could indepedently find, understand, and actually
use your package. This is a point that many projects never hit, but it’s
also the point at which software becomes a real product.

This is especially true in science, where community usage and
contribution is essential for software to have an impact on a field. If
many people are already regularly using your software, then you will
have a much easier time both maintaining it (as you’ll have power users
capable of understanding and contributing to the codebase) and
publishing it (as its usefulness has already been demonstrated by the
user base).

------------------------------------------------------------------------

### Debrief & Reflection

Before moving on, make sure you can answer:

- Which parts of your package deserve tests?
- How do `testthat`, `pkgdown`, and CI help you be more efficient and
  build better quality software?

------------------------------------------------------------------------

## After-Class Tasks

### Task 1: Add Tests

If you haven’t already, add tests to cover the main functionality of
your package. Ensure all tests pass (locally and in CI).

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
