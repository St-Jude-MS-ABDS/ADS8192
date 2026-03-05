# ADS 8192 — Developing Scientific Applications

Course materials and reference implementation for **ADS 8192: Developing
Scientific Applications**. This R package demonstrates the “three
interfaces, one core” architecture for scientific software.

## Installation

``` r
# Install Bioconductor dependencies
if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install(c("SummarizedExperiment", "airway"))

# Install the course package
remotes::install_github("YOUR-USERNAME/ADS8192")
```

## Quick Start

``` r
library(ADS8192)

# Load example data (100 genes, 8 samples with treatment effect)
data(example_se)

# Run PCA on the top 50 variable genes
result <- run_pca(example_se, n_top = 50)

# Visualize
plot_pca(result, color_by = "treatment")

# Check variance explained
pca_variance_explained(result)
```

## Three Interfaces, One Core

All three interfaces call the **same core functions** — no duplicated
logic.

### R API

``` r
library(ADS8192)
library(airway)
data(airway)
result <- run_pca(airway, n_top = 500)
plot_pca(result, color_by = "dex", shape_by = "cell")
```

### Shiny App

``` r
ADS8192::run_app()
```

### Command-Line Interface (via Rapp)

``` bash
# Install CLI launcher (one-time)
Rscript -e "Rapp::install_pkg_cli_apps('ADS8192')"

# Run PCA
ADS8192 pca --counts counts.tsv --meta samples.tsv --output results/ --color-by treatment

# Validate inputs
ADS8192 validate --counts counts.tsv --meta samples.tsv
```

## Core Functions

| Function                                                                                                           | Purpose                                            |
|--------------------------------------------------------------------------------------------------------------------|----------------------------------------------------|
| [`make_se()`](https://automatic-engine-4qp7m5e.pages.github.io/reference/make_se.md)                               | Create SummarizedExperiment from counts + metadata |
| [`top_variable_features()`](https://automatic-engine-4qp7m5e.pages.github.io/reference/top_variable_features.md)   | Select N most variable genes                       |
| [`run_pca()`](https://automatic-engine-4qp7m5e.pages.github.io/reference/run_pca.md)                               | Run PCA, return scores + metadata                  |
| [`pca_variance_explained()`](https://automatic-engine-4qp7m5e.pages.github.io/reference/pca_variance_explained.md) | Variance % per PC                                  |
| [`plot_pca()`](https://automatic-engine-4qp7m5e.pages.github.io/reference/plot_pca.md)                             | PCA scatter plot (ggplot2)                         |
| [`save_pca_results()`](https://automatic-engine-4qp7m5e.pages.github.io/reference/save_pca_results.md)             | Export results to TSV files                        |
| [`run_app()`](https://automatic-engine-4qp7m5e.pages.github.io/reference/run_app.md)                               | Launch Shiny PCA Explorer                          |

## Course Materials

Lectures are in `Unit1/Lectures/` and available as pkgdown articles:

| \#  | Topic                                   |
|-----|-----------------------------------------|
| 03  | Data Structures & Bioconductor          |
| 05  | Package Development (devtools)          |
| 06  | Package Development (pkgdown, testthat) |
| 07  | Shiny Reactivity                        |
| 08  | Shiny Packaging & Deployment            |
| 09  | CLI Design (Rapp)                       |
| 10  | CLI Packaging & Installation            |
| 11  | Review & Q/A                            |

## Assessments

- Quizzes: `Unit1/Assessments/Quiz*.docx`
- **[HW1 Grading
  Rubric](https://automatic-engine-4qp7m5e.pages.github.io/Unit1/Assessments/HW1_Rubric.md)**
  (25 points)

## Repository Structure

    ADS8192/
    ├── R/                      # Package source code (core functions + Shiny app)
    ├── exec/                   # Rapp CLI entry point
    ├── inst/app/               # Shiny app.R entry point
    ├── data/                   # Example dataset (example_se.rda)
    ├── tests/testthat/         # Unit tests
    ├── vignettes/              # Getting started guide + lecture articles
    ├── man/                    # Generated help files
    ├── Unit1/
    │   ├── Lectures/           # RMarkdown lecture documents
    │   └── Assessments/        # Quizzes (.docx) and HW1 rubric
    ├── DESCRIPTION             # Package metadata
    ├── NAMESPACE               # Exports/imports
    ├── _pkgdown.yml            # Documentation site config
    └── generate_quizzes.py     # Quiz generation script

## License

MIT
