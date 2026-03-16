# Lecture 9: Lab – CLI Tool Development (R) – CLI Design and Rapp Basics

## Learning Objectives

By the end of this session, you will be able to:

1.  Implement a simple CLI using Rapp that calls package functions
2.  Write usage/help text and define clear inputs/outputs for commands
3.  Test CLI functionality from the terminal and interpret exit behavior
4.  Explain why CLIs improve interoperability and pipeline integration

**Course Learning Outcomes (CLOs):** CLO 1, 2, 3, 5, 6

------------------------------------------------------------------------

## Why Build a CLI?

### The Three Interfaces

We’ve built:

- **R API**: For users working interactively in R
- **Shiny App**: For point-and-click exploration

Now we add:

- **CLI**: For pipeline integration and non-interactive use

### CLI Use Cases

``` bash
# Run analysis in a pipeline
snakemake_rule:
    sePCA pca --counts counts.csv --meta samples.csv --output results/

# Process multiple datasets
for dataset in data/*; do
    sePCA pca --counts "$dataset/counts.csv" --meta "$dataset/meta.csv" \
        --output "results/$(basename $dataset)/"
done

# Reproducible scripts
#!/bin/bash
sePCA pca --counts $1 --meta $2 --n-top 1000 --output pca_results/
```

Benefits:

- **Pipeline integration**: Works with Snakemake, Nextflow, Make
- **Scriptable**: Easy to automate many runs
- **Reproducible**: Command line is self-documenting
- **No IDE required**: Run on servers, HPC clusters

------------------------------------------------------------------------

## Part 1: CLI Design Principles

### Good CLI Design

#### 1. Clear Help Text

``` bash
$ sePCA pca --help

Usage: sePCA pca [OPTIONS]

Run PCA on a SummarizedExperiment and export results.

Options:
  --counts FILE       Path to counts matrix (TSV/CSV) [required]
  --meta FILE         Path to sample metadata (TSV/CSV) [required]
  --output DIR        Output directory [required]
  --n-top INT         Number of top variable genes [default: 500]
  --log-transform     Log-transform counts [default: true]
  --no-log-transform  Don't log-transform counts
  --color-by COL      Metadata column for plot coloring
  -h, --help          Show this message and exit

Examples:
  sePCA pca --counts counts.tsv --meta samples.tsv --output results/
  sePCA pca --counts counts.tsv --meta samples.tsv --output results/ --n-top 1000
```

#### 2. Explicit Inputs and Outputs

Don’t read from stdin/write to stdout for data (only for messages):

``` bash
# Good: explicit file arguments
sePCA pca --counts data.tsv --output results/

# Bad: implicit stdin/stdout
cat data.tsv | sePCA pca > results.tsv
```

#### 3. Reproducible Defaults

- Document all defaults in help text
- Same inputs → same outputs (deterministic)

#### 4. Meaningful Exit Codes

``` bash
$ sePCA pca --counts missing.tsv --meta meta.tsv --output out/
Error: File not found: missing.tsv

$ echo $?
1  # Non-zero = error
```

| Code | Meaning           |
|------|-------------------|
| 0    | Success           |
| 1    | General error     |
| 2    | Invalid arguments |

#### 5. Machine-Readable Outputs

``` bash
# Good: TSV for data
sePCA pca ... --output results/
# Creates: results/pca_scores.tsv, results/pca_variance.tsv

# Good: JSON for complex structured data
sePCA info --json > info.json
```

------------------------------------------------------------------------

### Exercise A: Design First

Before implementing, design the help output you want:

    Usage: sePCA pca [OPTIONS]

    Run PCA analysis on gene expression data.

    Required Arguments:
      --counts FILE      Path to counts matrix (genes × samples, TSV/CSV)
      --meta FILE        Path to sample metadata (TSV/CSV, row names = sample IDs)
      --output DIR       Directory for output files

    Optional Arguments:
      --n-top INT        Number of top variable genes [default: 500]
      --log-transform    Log2-transform counts (add pseudocount of 1) [default]
      --no-log-transform Skip log transformation
      --color-by COL     Metadata column for coloring (for plot)
      --assay NAME       Assay name in SE [default: "counts"]
      --help             Show this help message

    Outputs:
      {output}/pca_scores.tsv      PCA scores with sample metadata
      {output}/pca_variance.tsv    Variance explained by each PC
      {output}/pca_plot.png        PCA scatter plot (if --color-by specified)

    Examples:
      sePCA pca --counts counts.tsv --meta samples.tsv --output results/
      sePCA pca --counts counts.tsv --meta samples.tsv --output results/ \
          --n-top 1000 --color-by treatment

------------------------------------------------------------------------

## Part 2: Introduction to Rapp

### What is Rapp?

**Rapp** (R application) is a lightweight framework for building
command-line tools in R. It provides:

- Argument parsing and type coercion
- Help text generation (including `--help-yaml`)
- Subcommand support
- A clean path from script -\> CLI

Alternative options include `optparse`, `argparse`, and `docopt`, but in
this course we will use Rapp.

### Installation

``` r
# Install Rapp
install.packages("Rapp")

# Or from GitHub for the latest version
# remotes::install_github("r-lib/Rapp")
```

### How Rapp Declares a CLI

Rapp infers CLI structure from normal R code:

- `n_top <- 500L` becomes `--n-top 500`
- `log_transform <- TRUE` becomes `--log-transform` /
  `--no-log-transform`
- `path <- NULL` becomes a positional argument
- `switch("", cmd1 = { ... }, cmd2 = { ... })` declares commands

You can add help metadata using `#|` annotations:

``` r
#| description: Number of top variable genes
#| short: n
n_top <- 500L
```

**Note:** snake_case names automatically map to kebab-case flags
(`n_top` -\> `--n-top`).

Rapp provides built-in help:

- `--help` shows usage and options
- `--help-yaml` prints machine-readable metadata

------------------------------------------------------------------------

## Part 3: Implementing the CLI

### Step 1: Create the Rapp App in `exec/`

Create `exec/sePCA`:

``` r
#!/usr/bin/env Rapp
#| name: sePCA
#| title: sePCA CLI
#| description: PCA analysis for SummarizedExperiment data.

suppressPackageStartupMessages(library(sePCA))

# Helper to read TSV/CSV
read_data_file <- function(path) {
    ext <- tolower(tools::file_ext(path))
    if (ext == "csv") {
        read.csv(path, row.names = 1, check.names = FALSE)
    } else {
        read.table(path, sep = "\t", header = TRUE, row.names = 1, check.names = FALSE)
    }
}

switch(
    "",

    #| title: Run PCA analysis
    #| description: Run PCA and export results.
    pca = {
        #| description: Path to counts matrix (TSV/CSV)
        #| short: c
        counts <- ""

        #| description: Path to sample metadata (TSV/CSV)
        #| short: m
        meta <- ""

        #| description: Output directory
        #| short: o
        output <- ""

        #| description: Number of top variable genes
        #| short: n
        n_top <- 500L

        #| description: Log-transform counts
        log_transform <- TRUE

        #| description: Metadata column for plot coloring (optional)
        color_by <- ""

        if (counts == "" || meta == "" || output == "") {
            stop("--counts, --meta, and --output are required", call. = FALSE)
        }
        if (!file.exists(counts)) stop("File not found: ", counts, call. = FALSE)
        if (!file.exists(meta)) stop("File not found: ", meta, call. = FALSE)

        if (!dir.exists(output)) dir.create(output, recursive = TRUE)

        counts_df <- read_data_file(counts)
        meta_df <- read_data_file(meta)
        se <- make_se(as.matrix(counts_df), meta_df)

        result <- run_pca(se, n_top = n_top, log_transform = log_transform)

        scores_file <- file.path(output, "pca_scores.tsv")
        write.table(result$scores, scores_file, sep = "\t", row.names = FALSE, quote = FALSE)

        var_file <- file.path(output, "pca_variance.tsv")
        var_df <- pca_variance_explained(result)
        write.table(var_df, var_file, sep = "\t", row.names = FALSE, quote = FALSE)

        if (color_by != "") {
            plot_file <- file.path(output, "pca_plot.png")
            p <- plot_pca(result, color_by = color_by)
            ggplot2::ggsave(plot_file, p, width = 8, height = 6, dpi = 150)
        }
    },

    #| title: Validate input files
    #| description: Check that inputs exist, parse, and report dimensions.
    validate = {
        #| description: Path to counts matrix (TSV/CSV)
        counts <- ""

        #| description: Path to sample metadata (TSV/CSV)
        meta <- ""

        if (counts == "" || meta == "") {
            stop("--counts and --meta are required", call. = FALSE)
        }
        if (!file.exists(counts)) stop("File not found: ", counts, call. = FALSE)
        if (!file.exists(meta)) stop("File not found: ", meta, call. = FALSE)

        counts_df <- read_data_file(counts)
        meta_df <- read_data_file(meta)

        message("Counts dimensions: ", nrow(counts_df), " genes x ", ncol(counts_df), " samples")
        message("Metadata rows: ", nrow(meta_df))

        if (!all(colnames(counts_df) %in% rownames(meta_df))) {
            stop("Sample IDs in counts do not match metadata row names", call. = FALSE)
        }

        message("Inputs look valid.")
    }
)
```

### Step 2: Run During Development

``` bash
# Show top-level help
Rapp exec/sePCA --help

# Command-specific help
Rapp exec/sePCA pca --help

# Run PCA
Rapp exec/sePCA pca     --counts tests/testdata/counts.tsv     --meta tests/testdata/meta.tsv     --output tests/testdata/output/
```

### Step 3: Interactive Testing from R

``` r
# Run from an R session (useful for debugging)
Rapp::run("exec/sePCA", c(
    "pca",
    "--counts", "tests/testdata/counts.tsv",
    "--meta", "tests/testdata/meta.tsv",
    "--output", "tests/testdata/output/",
    "--n-top", "500"
))
```

------------------------------------------------------------------------

### Step 4: Export a Launcher Installer

Running `Rapp exec/sePCA pca --help` works during development, but after
a user installs your package from GitHub, the `exec/` directory is
buried inside the R library tree. Rapp solves this with **launchers** —
lightweight shell scripts (`.bat` on Windows) that live on `PATH` and
forward to the installed Rapp app.

#### How It Works

``` r
# One-liner: install launchers for every Rapp in a package's exec/
Rapp::install_pkg_cli_apps("sePCA")
```

After this, users can invoke the CLI directly:

``` bash
sePCA pca --help
sePCA pca --counts counts.tsv --meta meta.tsv --output results/
```

On Windows, `install_pkg_cli_apps()` creates `.bat` wrappers in
`%LOCALAPPDATA%\Programs\R\Rapp\bin` and adds that directory to `PATH`.
On macOS / Linux, launchers land in `~/.local/bin` (usually already on
`PATH`).

#### Export a Thin Wrapper

Rather than asking users to remember the
[`Rapp::install_pkg_cli_apps()`](https://rdrr.io/pkg/Rapp/man/install_pkg_cli_apps.html)
call, export your own convenience function. Create `R/install_cli.R`:

``` r
#' Install sePCA CLI launchers
#'
#' Places lightweight launcher scripts on the user's `PATH` so the
#' sePCA CLI can be invoked directly from a terminal (e.g. `sePCA pca --help`).
#'
#' @inheritDotParams Rapp::install_pkg_cli_apps -package -lib.loc
#' @export
install_sePCA_cli <- function(...) {
    Rapp::install_pkg_cli_apps(package = "sePCA", lib.loc = NULL, ...)
}
```

Then document it, `devtools::document()`, and users get:

``` r
remotes::install_github("you/sePCA")
sePCA::install_sePCA_cli()
```

…followed by seamless terminal usage.

#### Try It Now

``` bash
# Install launchers for sePCA (run once after installation)
Rscript -e "Rapp::install_pkg_cli_apps('sePCA')"

# Now use the CLI directly
sePCA --help
sePCA pca --help
```

Add the install instructions to your README so users know about it.

------------------------------------------------------------------------

## Part 4: Testing the CLI

### Manual Testing

#### Create Test Data

``` r
# Create small test files
library(SummarizedExperiment)
library(airway)
data(airway)

# Extract and save counts
counts <- assay(airway, "counts")[1:1000, ]  # First 1000 genes
write.table(
    counts,
    "tests/testdata/counts.tsv",
    sep = "\t",
    quote = FALSE
)

# Save metadata
meta <- as.data.frame(colData(airway))
write.table(
    meta,
    "tests/testdata/meta.tsv",
    sep = "\t",
    quote = FALSE
)
```

#### Run from Terminal

``` bash
# Navigate to package directory
cd sePCA

# Test help
Rapp exec/sePCA --help

# Test PCA command help
Rapp exec/sePCA pca --help

# Run PCA
Rapp exec/sePCA pca \
    --counts tests/testdata/counts.tsv \
    --meta tests/testdata/meta.tsv \
    --output tests/testdata/output/

# Check outputs
ls tests/testdata/output/
cat tests/testdata/output/pca_variance.tsv

# Test with plot
Rapp exec/sePCA pca \
    --counts tests/testdata/counts.tsv \
    --meta tests/testdata/meta.tsv \
    --output tests/testdata/output2/ \
    --color-by dex
```

### Testing Error Handling

``` bash
# Missing required argument
Rapp exec/sePCA pca --counts counts.tsv
# Should error: --counts, --meta, and --output are required

# Missing file
Rapp exec/sePCA pca \
    --counts nonexistent.tsv \
    --meta meta.tsv \
    --output out/
# Should error: File not found: nonexistent.tsv

# Check exit code
Rapp exec/sePCA pca --counts nonexistent.tsv --meta meta.tsv --output out/
echo $?  # Should be 1
```

------------------------------------------------------------------------

### Exercise B: Enhance Validate Command

Improve the `validate` subcommand so it:

1.  Checks if input files exist
2.  Checks if they can be parsed
3.  Reports dimensions
4.  Checks for sample ID matches

Example output:

``` bash
$ Rapp exec/sePCA validate --counts counts.tsv --meta meta.tsv

Validating counts file: counts.tsv
  ✓ File exists
  ✓ Can be parsed
  ✓ Dimensions: 10000 genes × 8 samples

Validating metadata file: meta.tsv
  ✓ File exists
  ✓ Can be parsed
  ✓ Rows: 8

Checking consistency:
  ✓ Sample IDs match
  ✓ Metadata columns: cell, dex, albut, Run, avgLength, Experiment, Sample, BioSample

Ready for analysis!
```

------------------------------------------------------------------------

### Exercise C: DRY Check

Verify that your CLI calls
[`run_pca()`](https://automatic-engine-4qp7m5e.pages.github.io/reference/run_pca.md)
from your package rather than re-implementing the PCA logic.

Look for:

- `run_pca(...)` call inside the `pca` command in `exec/sePCA`
- `plot_pca(...)` call for plotting when `--color-by` is set
- No direct calls to [`prcomp()`](https://rdrr.io/r/stats/prcomp.html)
  in the CLI script

------------------------------------------------------------------------

## Part 5: Versioning and Stability

### The Contract

CLI users depend on:

- **Argument names**: `--n-top` shouldn’t become `--ntop`
- **Output file names**: `pca_scores.tsv` shouldn’t become `scores.tsv`
- **Output format**: TSV columns shouldn’t change unexpectedly

### Semantic Versioning

- **MAJOR** (1.0.0 → 2.0.0): Breaking changes to CLI interface
- **MINOR** (1.0.0 → 1.1.0): New features, backward compatible
- **PATCH** (1.0.0 → 1.0.1): Bug fixes

### What’s Breaking?

| Change                        | Breaking?  |
|-------------------------------|------------|
| Rename `--n-top` to `--n_top` | Yes        |
| Add new optional flag         | No         |
| Remove a flag                 | Yes        |
| Change output column names    | Yes        |
| Add new output columns        | Usually no |
| Change default value          | Maybe      |

Document changes in a CHANGELOG!

------------------------------------------------------------------------

## Summary

Today we:

1.  Learned CLI design principles (help text, explicit I/O, exit codes)
2.  Built a CLI using Rapp with commands and options
3.  Implemented the `pca` command that calls our package functions
4.  Exported a launcher installer (`install_sePCA_cli()`) for seamless
    terminal use
5.  Tested error handling and exit codes
6.  Discussed versioning and stability

### Package Milestone

✅ A working CLI prototype with an exported launcher installer — users
can run `sePCA pca --help` directly from the terminal after installing
your package.

------------------------------------------------------------------------

## After-Class Tasks

### Micro-task 1: Add a Flag

Add one additional CLI flag (e.g., `--pcs 1,2` or `--n-top 500`) and
ensure it changes outputs appropriately.

### Micro-task 2: Document CLI + Launcher in README

Add a “Command Line Interface” section to README with:

- Launcher installation command (`yourpkg::install_yourpkg_cli()`)
- Basic usage example using the launcher (e.g., `sePCA pca --help`)
- List of available commands
- Fallback instructions (`Rapp exec/sePCA pca --help`) for users who
  skip the launcher

### Micro-task 3: pkgdown Article

Add a vignette/article for CLI usage:

``` r
usethis::use_vignette("cli", title = "Command Line Interface")
```

------------------------------------------------------------------------

## CLI Quick Reference

``` bash
# Install launchers (one-time, after package installation)
Rscript -e "sePCA::install_sePCA_cli()"
# Or equivalently:
Rscript -e "Rapp::install_pkg_cli_apps('sePCA')"

# After installing launchers — the primary way to use the CLI
sePCA --help
sePCA pca --help
sePCA pca \
    --counts counts.tsv \
    --meta samples.tsv \
    --output results/ \
    --n-top 500 \
    --color-by treatment

# During development (before launchers are installed)
Rapp exec/sePCA --help
Rapp exec/sePCA pca --help

# Check exit code
echo $?

# Redirect stderr (messages) vs stdout (none in our design)
sePCA pca ... 2> log.txt
```

------------------------------------------------------------------------

## Session Info

``` r
sessionInfo()
```

    ## R version 4.5.3 (2026-03-11)
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
    ## [13] pkgdown_2.2.0     textshaping_1.0.5 jquerylib_0.1.4   systemfonts_1.3.2
    ## [17] compiler_4.5.3    tools_4.5.3       ragg_1.5.1        bslib_0.10.0     
    ## [21] evaluate_1.0.5    yaml_2.3.12       otel_0.2.0        jsonlite_2.0.0   
    ## [25] rlang_1.1.7       fs_1.6.7          htmlwidgets_1.6.4
