# Getting Started with ADS 8192

## Overview

**ADS 8192: Developing Scientific Applications** teaches graduate
students to build scientific software in R using established software
engineering principles — separation of concerns, DRY (Don’t Repeat
Yourself), composability, and layered architecture. This package
provides the reference implementation: a set of PCA analysis functions
for SummarizedExperiment objects, a Shiny interactive explorer, and a
command-line interface.

## Installation

``` r
# Install Bioconductor dependencies first
if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install(c("SummarizedExperiment", "airway"))

# Install the course package
remotes::install_github("St-Jude-MS-ABDS/ADS8192")
```

## Quick Start

``` r
library(ADS8192)
library(airway)

# Load the airway dataset (RNA-seq, dexamethasone treatment vs. control)
data("airway", package = "airway")
airway
```

### Run PCA

``` r
result <- run_pca(airway, n_top = 500)

# View the PCA scores merged with sample metadata
head(result$scores)
```

### Visualize

``` r
plot_pca(result, color_by = "dex")
```

``` r
plot_pca(result, color_by = "dex", shape_by = "cell")
```

### Check Variance Explained

``` r
pca_variance_explained(result)
```

## Architecture: Separation of Concerns

The package is organized around a principle that shows up in virtually
every well-engineered codebase: **separate *what* you compute from *how*
users access it**. The analysis logic lives in small, testable,
composable R functions (the core layer). Presentation layers — an R API,
a Shiny app, and a CLI — are thin wrappers that delegate to those same
core functions.

                 Core Analysis Functions
      make_se() → run_pca() → plot_pca()
            ↑            ↑            ↑
       ┌────┴────┐  ┌────┴────┐  ┌───┴─────┐
       │ R API   │  │ Shiny   │  │  CLI    │
       │ (users) │  │ (web)   │  │(scripts)│
       └─────────┘  └─────────┘  └─────────┘

Because every interface calls the **same core functions**, you get
several properties for free:

- **DRY (Don’t Repeat Yourself)** — fix a bug or add a feature once, and
  every interface benefits immediately.
- **Testability** — core functions are pure R with well-defined inputs
  and outputs, so unit tests cover the real computation regardless of
  how it’s invoked.
- **Composability** — each function does one thing, so users (and other
  packages) can recombine them in ways you didn’t anticipate.

This layered design is why the package — and the course lectures — are
structured the way they are: we build the core functions first (Lecture
03), package and test them (Lectures 05–06), then add presentation
layers one at a time (Shiny in 07–08, CLI in 09–10).

### R API

``` r
library(ADS8192)
library(airway)
data("airway", package = "airway")
result <- run_pca(airway, n_top = 500)
plot_pca(result, color_by = "dex")
```

### Shiny App

``` r
ADS8192::run_app()
```

### CLI (via Rapp)

``` bash
ADS8192 pca --counts counts.tsv --meta samples.tsv --output results/
```

## Course Lectures

The package includes all lecture materials as pkgdown articles. See the
“Course Materials” dropdown in the navigation bar.
