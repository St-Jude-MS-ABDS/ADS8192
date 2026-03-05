# Copilot Instructions for ADS 8192

## Course Overview

This repository contains lecture materials and assessments for **ADS
8192 — Developing Scientific Applications**. The course teaches graduate
students to build complete, reproducible scientific software in R: from
analysis functions through packaged R packages with Shiny apps and CLI
interfaces.

## Repository Structure

    ADS8192/
    ├── DESCRIPTION
    ├── NAMESPACE
    ├── LICENSE.md
    ├── README.md
    ├── R/                      # Package source (core functions + Shiny app)
    │   ├── ADS8192-package.R
    │   ├── data.R              # make_se(), top_variable_features()
    │   ├── pca.R               # run_pca(), pca_variance_explained()
    │   ├── plotting.R          # plot_pca()
    │   ├── export.R            # save_pca_results()
    │   ├── app_ui.R            # Shiny UI
    │   ├── app_server.R        # Shiny server
    │   ├── run_app.R           # run_app() exported function
    │   └── data-documentation.R
    ├── exec/                   # Rapp CLI entry point
    │   └── ADS8192
    ├── inst/app/               # Shiny app.R (runApp compatibility)
    ├── data/                   # Example dataset
    │   └── example_se.rda
    ├── data-raw/               # Script to generate example data
    ├── tests/
    │   ├── testthat.R
    │   └── testthat/           # Unit tests
    ├── vignettes/
    │   ├── getting-started.Rmd
    │   └── articles/           # Lectures as pkgdown articles
    ├── man/                    # Generated help files (roxygen2)
    ├── Unit1/
    │   ├── Lectures/           # RMarkdown lecture/lab documents (.Rmd)
    │   └── Assessments/        # Quizzes (.docx) + HW1 rubric (.md)
    ├── _pkgdown.yml            # Documentation site config
    ├── .Rbuildignore
    ├── .github/
    │   └── copilot-instructions.md
    └── generate_quizzes.py     # Quiz generation script (Python)

## Technology Stack

- **Language:** R (primary), Python (tooling/scripting only)
- **Local R installation:** `C:\Program Files\R\R-devel\bin\R.exe`
- **Core R packages:** SummarizedExperiment, airway, devtools, usethis,
  roxygen2, testthat, pkgdown, shiny, bslib, ggplot2, ComplexHeatmap,
  rlang, Rapp
- **Package example name:** `sePCA` (students choose their own names for
  homework)
- **Dataset:** Bioconductor `airway` dataset (RNA-seq, dexamethasone
  treatment vs. control)
- **Python (tooling):** python-docx for generating Word documents; use
  the `.venv` in the repo root
- **This repo is itself an R package** providing the reference
  implementation

## Lecture Conventions

- Lectures are numbered 03, 05–11 (matching the course calendar)
- Each lecture is a self-contained RMarkdown document with:
  - YAML header (title, author “ADS 8192”, date, `html_document` output
    with toc/theme)
  - Learning objectives at the top
  - Course Learning Outcome (CLO) references
  - Working code examples using the `airway` dataset and `sePCA` package
  - In-class exercises labeled “Exercise A”, “Exercise B”, etc.
  - Discussion prompts
  - After-class micro-tasks and reading assignments
  - Session info block at the end
- Code chunks use
  `knitr::opts_chunk$set(echo = TRUE, message = FALSE, warning = FALSE)`
- Functions are documented with roxygen2-style comments even in lecture
  code

## Assessment Conventions

- Quizzes are Word documents (.docx) stored in `Unit1/Assessments/`
- Each quiz has 4–5 questions: mix of multiple choice,
  select-all-that-apply, and short answer
- Questions focus on **theory, design rationale, and conceptual
  understanding** — not syntax recall or implementation details
- Quizzes include an answer key section at the end (separated by a page
  break)
- Students should be able to answer all questions correctly if they
  attended and paid attention

## Content Guidelines

- Use Bioconductor ecosystem conventions (S4 classes, BiocManager,
  vignettes)
- Emphasize the “three interfaces, one core” architecture: R functions →
  Shiny app → CLI, all sharing the same analysis core
- Prefer `devtools`/`usethis` workflows for package development
- CLI lectures use Rapp (CRAN package from r-lib) for argument parsing
- Testing uses `testthat` (edition 3)
- Shiny apps use `bslib` for theming
- GitHub Actions for CI/CD

## Style Preferences

- Write in a direct, practical teaching style
- Prefer working code over pseudocode
- Show the “wrong” way first, then the right way, to motivate design
  decisions
- Keep functions small, testable, and composable
- Use tidyverse-style formatting in R code (pipes, snake_case)
