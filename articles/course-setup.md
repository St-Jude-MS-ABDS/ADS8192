# Course Setup

## Overview

This guide installs **every** R package you may need for ADS 8192 — the
shared development stack, the course reference package, and the
dataset/analysis packages for all 13 homework projects. Running the code
block below once on a fresh R installation will get you fully set up.

> **Tip:** If you have already installed some of these packages,
> re-running
> [`install.packages()`](https://rdrr.io/r/utils/install.packages.html)
> or
> [`BiocManager::install()`](https://bioconductor.github.io/BiocManager/reference/install.html)
> will simply skip packages that are already up to date.

## Prerequisites

- **R ≥ 4.5.0** — install from [CRAN](https://cran.r-project.org/)
- If on Windows, install Rtools from
  [CRAN](https://cran.r-project.org/bin/windows/Rtools/) - this is
  required to compile some packages with C/C++ code.
- **RStudio** (recommended) or Positron
  - Download from [RStudio](https://posit.co/download/rstudio-desktop/)
- Bioconductor v3.22

## Install All Packages

Copy and run the entire block below in your R console. It installs:

1.  BiocManager (needed to install Bioconductor packages)
2.  CRAN packages (development tools, Shiny stack, analysis
    dependencies)
3.  Bioconductor packages (data containers, datasets, annotation tools)

``` r
if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager")

cran_pkgs <- c(
  # Development & documentation
  "devtools", "usethis", "roxygen2", "testthat", "pkgdown",
  "knitr", "rmarkdown", "remotes",
  # Shiny
  "shiny", "bslib", "DT",
  # Core
  "ggplot2", "rlang",
  # CLI
  "Rapp",
  # Project-specific
  "uwot",
  "cluster",
  "msigdbr",
  "igraph"
)

install.packages(cran_pkgs)

bioc_pkgs <- c(
  # Data containers
  "SummarizedExperiment",
  "SingleCellExperiment",
  # Analysis
  "DESeq2",
  # Visualization
  "ComplexHeatmap",
  "dittoSeq",
  # Datasets
  "airway",
  "macrophage",
  "scRNAseq",
  "tximeta",
  "recount3",
  "curatedTCGAData",
  "TCGAutils",
  "TENxPBMCData"
)

BiocManager::install(bioc_pkgs, version = "3.22")
```

## Verify Installation

After installation, run the following to confirm the key packages load
without error:

``` r
library(devtools)
library(SummarizedExperiment)
library(SingleCellExperiment)
library(ggplot2)
library(shiny)
library(testthat)
```

If any package fails to load, re-run the relevant
[`install.packages()`](https://rdrr.io/r/utils/install.packages.html) or
[`BiocManager::install()`](https://bioconductor.github.io/BiocManager/reference/install.html)
call for that package and check the error message.

## Install the Course Reference Package

The ADS8192 reference package can be installed directly from GitHub:

``` r
remotes::install_github("St-Jude-MS-ABDS/ADS8192")
```

## Session Info

``` r
sessionInfo()
```
