# ADS 8192 — Developing Scientific Applications

Course materials and reference implementation for **ADS 8192: Developing
Scientific Applications — Unit 1**. This R package serves as both the
source of all Unit 1 lecture content and the living reference
implementation that students follow as they build their own packages.

At the end of the course, students will be able to:

- Transform early-stage, exploratory research code into robust,
  maintainable, and scalable scientific applications and pipelines by
  applying software design principles, modular architectures, and
  well-defined interfaces. (CLO#1)

- Develop reproducible and portable computational environments,
  including encapsulated application deployments, and validate
  consistent execution across operating systems and computing platforms.
  (CLO#2)

- Utilize interoperable data structures and automated analytical
  workflows that support scalable execution, reuse, and integration
  within larger biomedical data science pipelines. (CLO#3)

- Apply collaborative software development practices, including version
  control and quality assurance, while effectively leveraging
  AI-assisted tools to accelerate development, testing, and
  documentation in a responsible and transparent manner. (CLO#4)

- Deploy and operate scientific applications on shared or remote
  computational infrastructures, and assess performance, reliability,
  cost, and resource trade-offs in applied biomedical settings. (CLO#5)

- Produce comprehensive documentation, automated tests, and standardized
  outputs that enable reproducibility and clearly communicate methods,
  assumptions, and results to diverse scientific and stakeholder
  audiences. (CLO#6)

This unit touches on all of these objectives, but places particular
emphasis on CLOs 1, 3, 5, and 6.

## Unit 1 Overview

Unit 1 teaches graduate students to build **complete, reproducible
scientific software in R** — from raw analysis functions through a fully
packaged, documented, and deployable application. The unit is organized
around a common software engineering principle that applies in any
language or domain:

> **Separation of concerns.** Write your analysis logic once as small,
> testable, composable functions. Then add thin presentation layers — an
> R API, a Shiny web app, and a command-line interface — that delegate
> to those functions without duplicating logic.

This is the same layered-architecture idea you’ll find in
well-engineered software everywhere: keep the *what* (computation)
separate from the *how* (delivery to users). Different audiences —
scientists who want point-and-click exploration, developers who want
composable functions, and bioinformatics cores who want scriptable CLI
tools — all benefit from the same tested core.

### Fundamental Unit Objectives

After completing Unit 1, students will be able to:

- **Design small, testable, composable functions** that operate on
  robust data containers (`SummarizedExperiment` /
  `SingleCellExperiment`) and return well-defined types — making them
  easy to reason about, test, and reuse.
- **Separate analysis logic from presentation logic.** Core computation
  lives in exported R functions; Shiny, CLI, and scripting layers are
  thin wrappers that delegate to the core. This prevents copy-paste
  drift (DRY) and keeps every interface consistent.
- **Build software for multiple audiences.** Scientists want
  point-and-click exploration (Shiny); package/pipeline developers want
  composable R functions they can call programmatically; bioinformatics
  cores want non-interactive CLI tools that slot into automated
  workflows. One codebase should serve all of them.
- **Package R code for distribution.** Turn loose scripts into a valid,
  installable R package using `devtools` / `usethis` workflows so that
  others can `install_github()` and immediately use your work. Pave the
  road for submission to CRAN or Bioconductor and publication.
- **Document thoroughly.** Every exported function gets `roxygen2`
  documentation; the package ships a `pkgdown` site; a README and
  vignette provide onboarding for new users.
- **Test meaningfully.** `testthat` tests cover both expected behavior
  and informative error cases, giving confidence that changes don’t
  silently break results.
- **Think about user experience.** Shiny apps include input validation
  with friendly messages; CLIs print help text and produce standard file
  formats (TSV); error messages tell the user *what went wrong and what
  to do about it*.
- **Practice reproducibility and collaboration.** Version control with
  Git/GitHub, CI/CD via GitHub Actions, reproducible data preparation
  (`data-raw/` scripts), and tagged releases make the work shareable and
  auditable.

### Paradigms & Themes

| Theme                                   | Key Tools / Concepts                                                                                                             |
|-----------------------------------------|----------------------------------------------------------------------------------------------------------------------------------|
| Separation of concerns & layered design | Core analysis functions → thin presentation layers: R API (developers), Shiny (end-users/scientists), CLI (pipelines/automation) |
| Robust data modeling                    | `SummarizedExperiment`, `SingleCellExperiment`, S4 classes                                                                       |
| R package development                   | `devtools`, `usethis`, `roxygen2`, `DESCRIPTION`, `NAMESPACE`                                                                    |
| Automated testing                       | `testthat` (edition 3), happy-path + error-case coverage                                                                         |
| Documentation & publishing              | `roxygen2`, `pkgdown`, vignettes, README-driven onboarding                                                                       |
| User experience & input validation      | Informative errors (`rlang`/[`stop()`](https://rdrr.io/r/base/stop.html)), Shiny validation, CLI `--help`                        |
| Interactive applications                | `shiny`, `bslib`, `DT`, reactive programming                                                                                     |
| CLI design                              | `Rapp` (argument parsing, subcommands, launcher installation)                                                                    |
| Visualization                           | `ggplot2`, `ComplexHeatmap`                                                                                                      |
| Reproducibility & collaboration         | Git/GitHub, GitHub Actions CI/CD, `data-raw/` scripts, tagged releases                                                           |

## Lectures

All lectures are available as pkgdown articles on the [course
site](https://st-jude-ms-abds.github.io/ADS8192/). Source `.Rmd` files
live in `vignettes/articles/`.

| \#  | Topic                                   | What Students Learn                                                                                                                                               |
|-----|-----------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 04  | Data Structures & Bioconductor          | Build an S4 class from scratch; translating raw code to composable functions                                                                                      |
| 05  | Package Development (devtools)          | Turn functions into a valid R package; `DESCRIPTION`, `NAMESPACE`, `roxygen2` exports/imports, `devtools::check()`                                                |
| 06  | Package Development (pkgdown, testthat) | Write `testthat` tests (happy path + error cases); build and deploy a `pkgdown` documentation site                                                                |
| 07  | Shiny Reactivity                        | Understand the reactive graph; build a UI with `bslib`; connect inputs → reactive expressions → outputs                                                           |
| 08  | Shiny Packaging & Deployment            | Embed a Shiny app inside an R package ([`run_app()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_app.md)); deploy to Posit Connect                    |
| 09  | CLI Design (Rapp)                       | Design a CLI with `Rapp`; argument types, defaults, help text; call package functions from `exec/` scripts                                                        |
| 10  | CLI Packaging & Installation            | Ship the CLI with the package; [`Rapp::install_pkg_cli_apps()`](https://rdrr.io/pkg/Rapp/man/install_pkg_cli_apps.html); launcher functions; README documentation |
| 11  | Review & Q/A                            | Systematic debugging workflow; end-to-end validation of all deliverables before submission                                                                        |

Each lecture includes working code examples (using the `airway`
dataset), in-class exercises, discussion prompts, and after-class
micro-tasks.

## Assessments

- **Homework 1** (25 pts): Build a complete R package implementing one
  of 12 small computational analyses with all three interfaces. See the
  [HW1
  Rubric](https://st-jude-ms-abds.github.io/ADS8192/articles/HW1_Rubric.html)
  and [Project Selection
  Guide](https://st-jude-ms-abds.github.io/ADS8192/articles/project-selection.html).
- **Quiz** (10 pts, at the end of the week): A 20 question quiz covering
  theory, design rationale, and conceptual understanding. Open book,
  take as many times as you need on your own time, no pressure.

### Homework 1

Homework 1 is the capstone deliverable for Unit 1 and will be what
students work on during labs.

Each student selects a project (or proposes a custom one) and delivers a
public GitHub repository containing an R package with:

| Category                         | Points | Key Requirements                                                                                                                         |
|----------------------------------|--------|------------------------------------------------------------------------------------------------------------------------------------------|
| Package Structure & Installation | 4      | Valid `DESCRIPTION`, `NAMESPACE`, installs from GitHub, bundled example data                                                             |
| Core Analysis Functions          | 5      | Analysis, summary, and plotting functions operating on common data structures                                                            |
| Testing                          | 4      | ≥ 8 `testthat` expectations, happy-path + error-case coverage                                                                            |
| Documentation                    | 4      | `roxygen2` help pages, README, deployed `pkgdown` site                                                                                   |
| Shiny App                        | 4      | [`run_app()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_app.md) calls core functions reactively; deployed on Posit Connect |
| Command-Line Interface           | 4      | `Rapp` entry point in `exec/`, `--help`, TSV output files                                                                                |
| **Total**                        | **25** |                                                                                                                                          |

Projects span bulk RNA-seq (`SummarizedExperiment`) and single-cell
RNA-seq (`SingleCellExperiment`) analyses — PCA, UMAP, differential
expression, clustering, QC, normalization, heatmaps, gene set scoring,
correlation networks, and more. All use real Bioconductor datasets.

As we progress through the lectures, we’ll build out the reference
implementation for one of these projects (PCA Explorer) in this
repository. Students will follow the same design and structure to build
their own package, but with their chosen analysis and dataset.

## Reference Implementation (This Package)

This repository **is** the reference implementation (Project 0: PCA
Explorer) serving as an example of what will be built during the labs.
Students cannot choose this project but use it as a structural guide. It
demonstrates the full layered architecture — core analysis functions
with R API, Shiny, and CLI presentation layers — for a basic R package
providing PCA and associated visualizations.

### Installation

``` r
# Install the course package
remotes::install_github("St-Jude-MS-ABDS/ADS8192")
```

### Quick Start

``` r
library(ADS8192)
library(airway)
data(airway)

# Run PCA on the top 500 variable genes
result <- run_pca(airway, n_top = 500)

# Visualize
plot_pca(result, color_by = "dex", shape_by = "cell")

# Check variance explained
pca_variance_explained(result)
```

### Presentation Layers

**R API**

``` r
library(ADS8192)
data(airway, package = "airway")
result <- run_pca(airway, n_top = 500)
plot_pca(result, color_by = "dex", shape_by = "cell")
save_pca_results(result, output_dir = "results/")
```

**Shiny App**

``` r
ADS8192::run_app()
```

**Command-Line Interface (via Rapp)**

``` bash
# Install CLI launcher (one-time)
Rscript -e "Rapp::install_pkg_cli_apps('ADS8192')"

# Run PCA from the terminal
ADS8192 pca --counts counts.tsv --meta samples.tsv --output results/ --color-by treatment
```

## Links

- **GitHub:** <https://github.com/St-Jude-MS-ABDS/ADS8192>

## License

MIT
