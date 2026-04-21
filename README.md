# ADS 8192 — Developing Scientific Applications

<!-- badges: start -->
[![R-CMD-check](https://github.com/St-Jude-MS-ABDS/ADS8192/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/St-Jude-MS-ABDS/ADS8192/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/St-Jude-MS-ABDS/ADS8192/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/St-Jude-MS-ABDS/ADS8192/actions/workflows/pkgdown.yaml)
<!-- badges: end -->

Course materials and reference implementation for **ADS 8192: Developing Scientific Applications — Unit 1**. This R package serves as both the source of all Unit 1 lecture content and the living reference implementation that students follow as they build their own packages.

At the end of the course, students will be able to: 

- Transform early-stage, exploratory research code into robust, maintainable, and scalable scientific applications and pipelines by applying software design principles, modular architectures, and well-defined interfaces. (CLO#1) 

- Develop reproducible and portable computational environments, including encapsulated application deployments, and validate consistent execution across operating systems and computing platforms. (CLO#2) 

- Utilize interoperable data structures and automated analytical workflows that support scalable execution, reuse, and integration within larger biomedical data science pipelines. (CLO#3) 

- Apply collaborative software development practices, including version control and quality assurance, while effectively leveraging AI-assisted tools to accelerate development, testing, and documentation in a responsible and transparent manner. (CLO#4) 

- Deploy and operate scientific applications on shared or remote computational infrastructures, and assess performance, reliability, cost, and resource trade-offs in applied biomedical settings. (CLO#5) 

- Produce comprehensive documentation, automated tests, and standardized outputs that enable reproducibility and clearly communicate methods, assumptions, and results to diverse scientific and stakeholder audiences. (CLO#6) 

This unit touches on all of these objectives, but places particular emphasis on CLOs 1, 3, 5, and 6.

## Unit 1 Overview

Unit 1 teaches graduate students to build **complete, reproducible scientific software in R** — from raw analysis functions through a fully packaged, documented, and deployable application. The unit is organized around a common software engineering principle that applies in any language or domain:

> **Separation of concerns.** Write your analysis logic once as small, testable, composable functions. Then add thin presentation layers — an R API, a Shiny web app, and a command-line interface — that delegate to those functions without duplicating logic.

This is the same layered-architecture idea you'll find in well-engineered software everywhere: keep the _what_ (computation) separate from the _how_ (delivery to users). Different audiences — scientists who want point-and-click exploration, developers who want composable functions, and bioinformatics cores who want scriptable CLI tools — all benefit from the same tested core.

### Paradigms & Themes Covered

| Theme | Key Tools / Concepts |
|-------|----------------------|
| Separation of concerns & layered design | Core analysis functions → thin presentation layers: R API (developers), Shiny (end-users/scientists), CLI (pipelines/automation) |
| Robust data modeling | `SummarizedExperiment`, `SingleCellExperiment`, S4 classes |
| R package development | `devtools`, `usethis`, `roxygen2`, `DESCRIPTION`, `NAMESPACE` |
| Automated testing | `testthat` (edition 3), happy-path + error-case coverage |
| Documentation & publishing | `roxygen2`, `pkgdown`, vignettes, README-driven onboarding |
| User experience & input validation | Informative errors (`rlang`/`stop()`), Shiny validation, CLI `--help` |
| Interactive applications | `shiny`, `bslib`, `DT`, reactive programming |
| CLI design | `Rapp` (argument parsing, subcommands, launcher installation) |
| Visualization | `ggplot2`, `ComplexHeatmap` |
| Reproducibility & collaboration | Git/GitHub, GitHub Actions CI/CD, `data-raw/` scripts, tagged releases, issues, pull requests, code review |

### Unit Objectives

After completing Unit 1, students will be able to:

- **Design small, testable, composable functions** that operate on robust data containers (`SummarizedExperiment` / `SingleCellExperiment`) and return well-defined types — making them easy to reason about, test, and reuse.
- **Build simple S4 classes** and determine when rolling their own class is worth the effort.
- **Separate analysis logic from presentation logic.** Core computation lives in exported R functions; Shiny, CLI, and scripting layers are thin wrappers that delegate to the core. This prevents copy-paste drift (DRY) and keeps every interface consistent.
- **Build software for multiple audiences.** Scientists want point-and-click exploration (Shiny); package/pipeline developers want composable R functions they can call programmatically; bioinformatics cores want non-interactive CLI tools that slot into automated workflows. One codebase should serve all of them.
- **Package R code for distribution.** Turn loose scripts into a valid, installable R package using `devtools` / `usethis` workflows so that others can `install_github()` and immediately use your work. Pave the road for submission to CRAN or Bioconductor and publication.
- **Document thoroughly.** Every exported function gets `roxygen2` documentation; the package ships a `pkgdown` site; a README and vignette provide onboarding for new users.
- **Test meaningfully.** `testthat` tests cover both expected behavior and informative error cases, giving confidence that changes don't silently break results.
- **Think about user experience.** Shiny apps include input validation with friendly messages; CLIs print help text and produce standard file formats (TSV); error messages tell the user *what went wrong and what to do about it*.
- **Practice reproducibility and collaboration.** Version control with Git/GitHub, CI/CD via GitHub Actions, reproducible data preparation (`data-raw/` scripts), and tagged releases make the work shareable and auditable.


## Lectures

All lectures are available as pkgdown articles on the [course site](https://st-jude-ms-abds.github.io/ADS8192/). Source `.Rmd` files live in `vignettes/articles/`.

| # | Topic | What Students Learn |
|---|-------|---------------------|
| 04 | Data Structures & R Ecosystems | Build an S4 class from scratch; differences in CRAN/Bioconductor; guts of a `SummarizedExperiment`; translating raw code to composable functions |
| 05 | R Package Development (devtools) | Turn functions into a valid R package; `DESCRIPTION`, `NAMESPACE`, `roxygen2` exports/imports, `devtools::check()` |
| 06 | R Package Documentation & Testing (pkgdown, testthat) | Write `testthat` tests (happy path + error cases); build and deploy a `pkgdown` documentation site; CI/CD with GitHub Actions |
| 07 | Shiny Reactivity & App Design | Understand the reactive graph; build a UI with `bslib`; connect inputs → reactive expressions → outputs; input validation |
| 08 | Shiny Packaging & Deployment | Embed a Shiny app inside an R package (`run_app()`); app documentation; deploy to Posit Connect |
| 09 | CLI Design & Development (Rapp) | Design a CLI with `Rapp`; argument types, defaults, help text; call package functions from `exec/` scripts; pipeline integration |
| 10 | GitHub Collaboration | Issues, pull requests, and code review; branch-based workflows; when lightweight vs. heavier process is appropriate |
| 11 | Unit 1 Review | Synthesis of all lectures; systematic debugging; end-to-end validation of all deliverables before submission |

Each lecture includes working code examples (using the `airway` dataset), in-class exercises, discussion prompts, and after-class micro-tasks.

## Assessments

- **Homework 1** (25 pts): Build a complete R package implementing one of [12 small computational analyses](https://st-jude-ms-abds.github.io/ADS8192/articles/project-selection.html) with all three interfaces. As we progress through the lectures/labs, we'll build out the reference implementation for one of these projects (PCA Explorer) in this repository. Students will follow the same design and structure to build their own package, but with their chosen analysis and dataset. 
  - See the [HW1 Rubric](https://st-jude-ms-abds.github.io/ADS8192/articles/HW1_Rubric.html) for full info.
- **Quiz** (10 pts, at the end of the week): A 20 question quiz covering theory, design rationale, and conceptual understanding. Open book, take as many times as you need on your own time, no pressure.


## Reference Implementation (This Package)

This repository **is** the reference implementation (Project 0: PCA Explorer) serving as an example of what will be built during the labs. Students cannot choose this project but use it as a structural guide. It demonstrates the full layered architecture (core analysis functions with R API, Shiny, and CLI) for a basic R package providing PCA and associated visualizations.

### Installation

```r
# Install the course package
remotes::install_github("St-Jude-MS-ABDS/ADS8192")
```

### Quick Start

```r
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

```r
library(ADS8192)
data(airway, package = "airway")
result <- run_pca(airway, n_top = 500)
plot_pca(result, color_by = "dex", shape_by = "cell")
save_pca_results(result, output_dir = "results/")
```

**Shiny App**

```r
ADS8192::run_app()
```

**Command-Line Interface (via Rapp)**

```bash
# Install CLI launcher (one-time)
Rscript -e "Rapp::install_pkg_cli_apps('ADS8192')"

# Run PCA from the terminal
ADS8192 pca --counts counts.tsv --meta samples.tsv --output results/ --color-by treatment

# Make toast (demo subcommand)
ADS8192 toast --bread sourdough --buttered
```

## Links

- **GitHub:** <https://github.com/St-Jude-MS-ABDS/ADS8192>

## License

MIT
