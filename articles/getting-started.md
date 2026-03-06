# Getting Started with ADS 8192

## Overview

**ADS 8192: Developing Scientific Applications** teaches the “three
interfaces, one core” architecture for scientific software in R. This
package provides the reference implementation: a set of PCA analysis
functions for SummarizedExperiment objects, a Shiny interactive
explorer, and a command-line interface.

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

## The “Three Interfaces, One Core” Architecture

                    Package Core
      make_se() → run_pca() → plot_pca()
            ↑            ↑            ↑
       ┌────┴────┐  ┌────┴────┐  ┌───┴─────┐
       │ R API   │  │ Shiny   │  │  CLI    │
       │ (users) │  │ (web)   │  │(scripts)│
       └─────────┘  └─────────┘  └─────────┘

All three interfaces call the **same core functions**. Fix a bug once,
and it’s fixed everywhere.

### Interface 1: R API

``` r
library(ADS8192)
library(airway)
data("airway", package = "airway")
result <- run_pca(airway, n_top = 500)
plot_pca(result, color_by = "dex")
```

### Interface 2: Shiny App

``` r
ADS8192::run_app()
```

### Interface 3: CLI (via Rapp)

``` bash
ADS8192 pca --counts counts.tsv --meta samples.tsv --output results/
```

## Course Lectures

The package includes all lecture materials as pkgdown articles. See the
“Course Materials” dropdown in the navigation bar.
