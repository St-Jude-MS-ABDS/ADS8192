# Lecture 10: Lab – CLI Tool Development (R) – Packaging and Installation

## Motivation

For automated scientific tools, installation and release quality are
part of the user experience. If a CLI only works in development mode on
the author’s machine, it is not yet robust software.

Clean installs, output parity checks, and release discipline save other
people time. They catch hidden assumptions early, prevent interface
drift, and make it much more likely that a pipeline user or collaborator
will get the same result you saw during development.

### Learning Objectives

By the end of this session, you will be able to:

1.  Install your package from GitHub and verify the CLI runs in a clean
    R session
2.  Document the CLI in the package README and the Getting Started
    vignette
3.  Confirm that CLI outputs match the package’s R function outputs for
    the same inputs
4.  Explain why clean-room testing, release discipline, and backward
    compatibility matter for automation users

### Evaluation Checklist

Before you ship a CLI, ask:

- Can a user install and run it from a clean environment with only
  declared dependencies?
- Does the installed interface behave the same as the development
  version?
- Do CLI outputs match the package core for the same inputs?
- Which file names, flags, and output columns now form part of the user
  contract?
- Are release steps reproducible enough for someone else in the lab to
  repeat?

### Scientific Use Case

An analysis group adds your CLI to a scheduled workflow and archives the
outputs for compliance. A month later you “clean up” some file names and
help text before tagging a release. Which changes are harmless
refactors, and which ones break their pipeline contract?

------------------------------------------------------------------------

## Where We Are

In Lecture 9 we built the CLI **inside** the package:

- `exec/ADS8192` — the Rapp app
- `Rapp` declared in `DESCRIPTION`
- `R/install_cli.R` — the exported `install_ADS8192_cli()` wrapper

Everything worked through `Rapp exec/ADS8192` during development. The
question now is: **does it still work after `remotes::install_github()`
on a clean machine?** That is what makes it real software rather than a
local script.

------------------------------------------------------------------------

## Part 1: Installation and Discoverability

### Package Entry Point (Recap)

Because you already created `exec/ADS8192` inside the package and added
`Rapp` to `DESCRIPTION` in Lecture 9, the entry point is already
packaged. Files in `exec/` are installed along with everything else when
someone runs `remotes::install_github("you/ADS8192")`. No relocation
step is needed.

One quick sanity check: `exec/ADS8192` must end with a blank newline or
Rapp will fail to parse the last command. Open it and verify.

### Install CLI Launchers

After installation, the `exec/` directory lives inside the R library
tree. Users should not have to type
`Rapp /path/to/library/ADS8192/exec/ADS8192 pca` every time. Rapp
provides **launchers** — lightweight wrapper scripts placed on `PATH` —
for exactly this.

Your `install_ADS8192_cli()` wrapper from Lecture 9 does the work:

``` r
ADS8192::install_ADS8192_cli()
# or the direct Rapp call
Rapp::install_pkg_cli_apps("ADS8192")
```

#### Where Launchers Land

| Platform      | Launcher directory                    |
|---------------|---------------------------------------|
| Windows       | `%LOCALAPPDATA%\Programs\R\Rapp\bin\` |
| macOS / Linux | `~/.local/bin/`                       |

Rapp handles `PATH` configuration automatically on first use. If the
command is not found after installation, verify:

``` powershell
# Windows (PowerShell): confirm the launcher exists and PATH resolves it
Get-Command ADS8192
where.exe ADS8192
```

You can also ask Rapp directly where it would install:

``` r
Rapp::pkg_cli_apps_dir()
```

Once installed, users can run:

``` bash
ADS8192 pca --help
```

#### Fallback: Run From `exec/`

If launchers are not installed, you can still invoke the app directly:

``` bash
Rapp exec/ADS8192 pca --help
```

Or from R:

``` r
Rapp::run(system.file("exec", "ADS8192", package = "ADS8192"), c("pca", "--help"))
```

### Document the CLI

Users should be able to find the CLI from your package’s front door. You
only need two brief additions — no separate pkgdown article.

#### README

Add a short **Command Line Interface** section to the package
`README.Rmd` (or `README.md`) with a one-line install step, a minimal
invocation, and the fallback:

```` markdown
## Command Line Interface

ADS8192 includes a CLI for pipeline integration.

```r
# One-time launcher install
ADS8192::install_ADS8192_cli()
```

```bash
# Usage
ADS8192 pca --counts counts.tsv --meta samples.tsv --output results/

# Fallback (no launcher)
Rapp exec/ADS8192 pca --help
```
````

Knit the README (`devtools::build_readme()`) so the rendered `README.md`
stays in sync.

#### Getting Started Vignette

In your existing `vignettes/getting-started.Rmd`, add a short “From the
command line” subsection at the end — three or four lines showing the
same install + one invocation. Pointing at the README is fine; the goal
is that a reader of the vignette knows the CLI exists.

------------------------------------------------------------------------

## Part 2: Clean-Room Testing

`devtools::load_all()` makes your code available during development, but
users **install** the package. You have to verify the installed path
works.

### Exercise A: Clean-Room Install

#### Step 1: Install from GitHub

Restart R first so nothing is loaded, then:

``` r
# Remove any existing installation
remove.packages("ADS8192")

# Install fresh from GitHub
remotes::install_github("you/ADS8192")
```

#### Step 2: Verify the Package Loads

``` r
library(ADS8192)

# Core functions
data(example_se)
result <- run_pca(example_se)
plot_pca(result, color_by = "treatment")

# Install launchers
ADS8192::install_ADS8192_cli()
```

#### Step 3: Run the CLI from a Terminal

Create test inputs from R (cross-platform and avoids tab/spacing
surprises):

``` r
dir.create("cli_test", recursive = TRUE, showWarnings = FALSE)

counts <- data.frame(
    sample1 = c(100L, 50L, 200L, 30L, 80L),
    sample2 = c(150L, 75L, 180L, 45L, 100L),
    sample3 = c(120L, 60L, 210L, 35L, 90L),
    sample4 = c(180L, 90L, 240L, 55L, 110L),
    row.names = paste0("gene", 1:5)
)
utils::write.table(counts, "cli_test/counts.tsv",
                   sep = "\t", quote = FALSE)

meta <- data.frame(
    treatment = c("control", "control", "treated", "treated"),
    batch     = c("A", "B", "A", "B"),
    row.names = paste0("sample", 1:4)
)
utils::write.table(meta, "cli_test/meta.tsv",
                   sep = "\t", quote = FALSE)
```

Then from a terminal:

``` bash
ADS8192 pca \
    --counts cli_test/counts.tsv \
    --meta cli_test/meta.tsv \
    --output cli_test/output/ \
    --n-top 5

# Inspect outputs
type cli_test\output\pca_scores.tsv
type cli_test\output\pca_variance.tsv
```

If the launcher is not yet on `PATH`, use the `Rapp exec/ADS8192 ...`
fallback instead.

**This single end-to-end run — install from GitHub, install launcher,
run CLI on small inputs — is the core clean-room test.** If this passes,
a collaborator who follows your README has a real chance of getting the
same result.

------------------------------------------------------------------------

## Part 3: Output Parity

A CLI is supposed to be a thin wrapper. That means: the same inputs
should produce the same results whether you call
[`run_pca()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_pca.md)
in R or invoke the CLI.

### Manual Parity Check

You do not need to write automated parity tests for this class — a
manual comparison is enough to catch most regressions.

Run the analysis via R:

``` r
library(ADS8192)

counts <- utils::read.table("cli_test/counts.tsv",
                            header = TRUE, row.names = 1, sep = "\t")
meta   <- utils::read.table("cli_test/meta.tsv",
                            header = TRUE, row.names = 1, sep = "\t")

se <- SummarizedExperiment::SummarizedExperiment(
    assays  = list(counts = as.matrix(counts)),
    colData = meta
)
r_result <- run_pca(se, n_top = 5)
r_scores <- r_result$scores
```

Then load the CLI output and eyeball it:

``` r
cli_scores <- utils::read.table(
    "cli_test/output/pca_scores.tsv",
    header = TRUE, sep = "\t"
)

# Column names should match
print(names(r_scores))
print(names(cli_scores))

# Values should match within floating-point tolerance
all.equal(r_scores$PC1, cli_scores$PC1)
all.equal(r_scores$PC2, cli_scores$PC2)
```

If [`all.equal()`](https://rdrr.io/r/base/all.equal.html) prints `TRUE`
and the column names agree, parity is fine.

### What an Automated Test Would Look Like

**You do not need to implement this.** Included only so you know the
shape if you decide to add one later:

``` r
test_that("CLI produces same output as R functions", {
    skip_on_cran()
    # ... write test counts/meta to tempfiles, call Rapp::run() on the CLI,
    #     read the CLI output back in, then:
    expect_equal(cli_scores$PC1, r_result$scores$PC1, tolerance = 1e-10)
})
```

Automated parity tests are valuable on long-lived projects where many
hands touch the code. For this course, a manual comparison after any
substantive change is enough.

------------------------------------------------------------------------

## Part 4: Release Discipline

Before you tag a release, run through a short checklist. The goal is to
catch problems in the last calm moment before users start relying on a
version number.

``` r
devtools::check()          # R CMD check, all clean
devtools::test()           # tests pass
pkgdown::build_site()      # docs build
devtools::build_readme()   # README re-knits
usethis::use_version()     # bump version + NEWS.md stub
```

Then:

``` bash
git push
git tag -a v0.1.0 -m "First release with CLI support"
git push origin v0.1.0
gh release create v0.1.0
```

Write short release notes that explicitly list **what is new, what
changed, and what (if anything) broke**. Pipeline users scan release
notes for flag and output-name changes before they upgrade.

------------------------------------------------------------------------

## Summary

Today we:

1.  Confirmed the packaged `exec/` entry point installs with the rest of
    the package
2.  Installed launchers via `install_ADS8192_cli()` and verified
    discoverability on `PATH`
3.  Added brief CLI documentation to the README and Getting Started
    vignette
4.  Performed a clean-room install-from-GitHub test
5.  Manually verified output parity between R and CLI
6.  Ran through a short pre-release checklist

### Package Milestone

**The ADS8192 package installs from GitHub and exposes a working CLI end
to end — install, launcher, run, output — in a clean R session.**

------------------------------------------------------------------------

### Debrief & Reflection

Before moving on, make sure you can answer:

- Why is installation quality part of the user contract for automation
  tools?
- Which parts of your CLI output now count as backward-compatibility
  commitments?
- How do clean-room testing and output parity checks protect users from
  hidden assumptions in your development environment?

------------------------------------------------------------------------

## After-Class Tasks

### Micro-task 1: R CMD check

Verify your package passes `devtools::check()` cleanly and that CI is
green.

### Micro-task 2: Reproducibility Note in README

Add a short “Reproducibility” section to the README with R version, any
Bioconductor release you built against, and a pinned install example:

``` markdown
## Reproducibility

Built with R 4.3.x, Bioconductor 3.18.

```r
# Install a specific version
remotes::install_github("you/ADS8192@v0.1.0")
```

    ## Micro-task 3: Release Notes Template

    Draft release notes for your first tagged version. Cover: what is new, what changed, and what (if anything) is a breaking change for CLI users (renamed flags, renamed output columns, changed defaults).

    ---

    # Final Package Structure

ADS8192/ ├── DESCRIPTION ├── NAMESPACE ├── LICENSE.md ├── README.Rmd ├──
README.md ├── NEWS.md ├── R/ │ ├── data.R │ ├── pca.R │ ├── plotting.R │
├── export.R │ ├── app_ui.R │ ├── app_server.R │ ├── run_app.R │ └──
install_cli.R ├── exec/ │ └── ADS8192 ├── inst/ │ └── app/ │ └── app.R
├── data/ │ └── example_se.rda ├── data-raw/ │ └── example_se.R ├── man/
│ └── \*.Rd ├── tests/ │ ├── testthat/ │ │ ├── test-data.R │ │ ├──
test-pca.R │ │ └── … │ └── testthat.R ├── vignettes/ │ ├──
getting-started.Rmd │ └── shiny-app.Rmd ├── \_pkgdown.yml └── .github/
└── workflows/ ├── R-CMD-check.yaml └── pkgdown.yaml

    ---

    # Session Info


    ``` r
    sessionInfo()

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
