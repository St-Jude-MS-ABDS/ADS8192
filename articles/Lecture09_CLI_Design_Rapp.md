# Lecture 9: Lab – CLI Tool Development (R) – CLI Design and Rapp Basics

## Motivation

Scientific software often needs to run without a human at the keyboard.
A command-line interface (CLI) makes your analysis tool usable in
pipelines, schedulers, shared compute environments, and repeatable
scripts.

A good CLI forces you to make the interface contract explicit: inputs,
outputs, defaults, and error behavior all become visible. That clarity
saves time for automation users and reduces drift between the command
line and the underlying package logic.

### Learning Objectives

By the end of this session, you will be able to:

1.  Add a Rapp-based CLI directly to your existing package
2.  Write usage/help text and define clear inputs/outputs for commands
3.  Test CLI functionality from the terminal and interpret exit behavior
4.  Decide when a CLI is worth adding and keep it a thin wrapper over
    package logic

### Scientific Use Case

A bioinformatics core wants to run your analysis across 40 cohorts in a
nightly workflow. They do not want a web app and they do not want to
source R files by hand. The CLI is the interface that lets them treat
your package as a reliable step in an automated pipeline.

------------------------------------------------------------------------

## Why Build a CLI?

We’ve already shown how to build two interfaces around the package core:

- **R API**: for users working interactively in R
- **Shiny app**: for point-and-click exploration

The CLI adds a third:

- **CLI**: for pipeline integration and non-interactive use

``` bash
# Typical pipeline use
ADS8192 pca --counts counts.tsv --meta samples.tsv --output results/
```

Benefits: pipeline integration (Snakemake, Nextflow, etc),
scriptability, reproducibility, and no IDE required on servers or
clusters.

### When Should You Add a CLI?

Add a CLI when users need automation, batch execution, scheduler
integration, or a stable entry point from another language or workflow
manager. Do not add one just because a terminal interface looks
advanced. A CLI is worthwhile when it exposes a clear contract around
existing package logic.

------------------------------------------------------------------------

## Part 1: CLI Design Principles

A good CLI behaves predictably under automation. Five principles keep it
that way.

#### 1. Clear Help Text

Help text *is* the interface for CLI users. Make it complete enough that
someone can use the tool without reading your R docs.

``` bash
$ ADS8192 pca --help

Usage: ADS8192 pca [OPTIONS]

Run PCA on a SummarizedExperiment and export results.

Options:
  --counts FILE       Path to counts matrix (TSV/CSV) [required]
  --meta FILE         Path to sample metadata (TSV/CSV) [required]
  --output DIR        Output directory [required]
  --n-top INT         Number of top variable genes [default: 500]
  --log-transform     Log-transform counts [default: true]
  --color-by COL      Metadata column for plot coloring
  -h, --help          Show this message and exit
```

#### 2. Explicit Inputs and Outputs

Use flags for data paths; do not read data from stdin or write data to
stdout. Reserve stdout/stderr for messages.

``` bash
# Good: explicit file arguments
ADS8192 pca --counts data.tsv --output results/

# Bad: implicit stdin/stdout for data
cat data.tsv | ADS8192 pca > results.tsv
```

#### 3. Reproducible Defaults

Document every default in help text. Same inputs should produce the same
outputs across runs.

#### 4. Meaningful Exit Codes

A non-zero exit code is how pipelines know something failed. Let errors
fail loudly, and return zero only on success.

| Code | Meaning           |
|------|-------------------|
| 0    | Success           |
| 1    | General error     |
| 2    | Invalid arguments |

#### 5. Machine-Readable Outputs

TSV for tabular data, JSON for structured output. Avoid clever
formatting that a script would have to parse around.

------------------------------------------------------------------------

## Part 2: Introduction to Rapp

### What is Rapp?

**Rapp** (R application) is a lightweight framework for building
command-line tools in R. It provides argument parsing, type coercion,
help text generation (including `--help-yaml`), subcommand support, and
a clean path from script to CLI.

### Installation

``` r
install.packages("Rapp")
```

We also need to add the `Rapp` *launcher* to our PATH.

``` r
Rapp::install_pkg_cli_apps("Rapp")
```

This adds the `Rapp` command to your terminal, which you can use to run
Rapp scripts during development.

### How Rapp Declares a CLI

Rapp infers CLI structure from normal R code:

- `n_top <- 500L` becomes `--n-top 500`
- `log_transform <- TRUE` becomes `--log-transform` /
  `--no-log-transform`
- `counts <- ""` becomes `--counts VALUE`
- `switch("", cmd1 = { ... }, cmd2 = { ... })` declares subcommands

You can add help metadata using `#|` annotations:

``` r
#| description: Number of top variable genes
#| short: n
n_top <- 500L
```

**Key rule:** snake_case variable names automatically become kebab-case
flags (`n_top` → `--n-top`). Do not rename variables to shape the flag
name — pick the variable name and the flag follows.

### Rapp Script Structure

A complete Rapp script has this overall shape:

``` r
#!/usr/bin/env Rapp         # Shebang marking this a Rapp executable
#| name: ADS8192            # CLI name (shown in --help)
#| title: ADS8192 PCA Tool & Toaster  # One-line title for help
#| description: PCA analysis for SummarizedExperiment data.

# Load packages explicitly (runs before any command)
suppressPackageStartupMessages({
    library(ADS8192)
    library(utils)
    library(stats)
})

# Optional helpers not exposed as CLI args
read_data_file <- function(path) { ... }

switch(
    "",           # Rapp substitutes the subcommand name at runtime

    #| title: Run PCA analysis
    #| description: Run PCA on counts + metadata, export results.
    pca = {
        #| description: Input file path
        counts <- ""

        #| description: Number of features
        n_top <- 500L

        # Command logic here
    }
)
```

Key structural points:

- **`switch("")`** is the Rapp idiom for declaring subcommands; Rapp
  substitutes the subcommand name at runtime.
- **Variable declarations inside each case** become that subcommand’s
  CLI arguments.
- **`#|` annotations** are YAML-parsed by Rapp and provide help text and
  short flags.
- **Type coercion** is automatic: `500L` → integer, `TRUE` → logical,
  `""` → character.

------------------------------------------------------------------------

## Part 3: Add the CLI to Your Package

You already have a package. The CLI lives inside that package from the
start. No separate script directory, no “move it in later” step.

### Step 1: Declare Rapp as a Dependency

From the package root, in R:

``` r
usethis::use_package("Rapp")
```

This adds `Rapp` to `DESCRIPTION` under `Imports:`.

### Step 2: Create the Rapp App in `exec/`

Rapp CLI apps live in the package’s top-level `exec/` directory. Files
in `exec/` are installed with the package, so the CLI travels with it.

``` r
dir.create("exec")
```

Now create `exec/ADS8192.R`. This defines your CLI. It is R code, but
with some special annotations for Rapp. Two things about this file
matter before you write anything else:

- **Explicit namespacing.** Even with
  [`library(ADS8192)`](https://github.com/St-Jude-MS-ABDS/ADS8192), the
  Rapp script runs in a minimal environment. Load base-R helper packages
  explicitly at the top
  ([`library(utils)`](https://rdrr.io/r/base/library.html),
  [`library(stats)`](https://rdrr.io/r/base/library.html)), and use
  [`utils::write.table()`](https://rdrr.io/r/utils/write.table.html) /
  [`utils::read.table()`](https://rdrr.io/r/utils/read.table.html) in
  the body.
- **Trailing newline required.** Rapp needs `exec/ADS8192.R` to end with
  a blank line. Most editors handle this by default — just verify.
  Without it, Rapp may fail to parse the last command.

Write the header and shared helpers first:

``` r
#!/usr/bin/env Rapp
#| name: ADS8192
#| title: ADS8192 PCA Tool & Toaster
#| description: PCA analysis for SummarizedExperiment data.

suppressPackageStartupMessages({
    library(ADS8192)
    library(utils)
    library(stats)
    library(ggplot2)
    library(SummarizedExperiment)
})

# Helper to read TSV/CSV (not exported; kept in CLI script)
read_data_file <- function(path) {
    ext <- tolower(tools::file_ext(path))
    if (ext == "csv") {
        utils::read.csv(path, row.names = 1, check.names = FALSE)
    } else {
        utils::read.table(path, sep = "\t", header = TRUE, row.names = 1,
                          check.names = FALSE)
    }
}
```

### Step 3: Add the `pca` Subcommand

The `pca` subcommand declares its arguments as R variables, validates
inputs, reads files, calls the **package core functions**, and writes
output:

``` r
switch(
    "",

    #| title: Run PCA analysis
    #| description: Run PCA on a counts matrix and sample metadata, export results.
    pca = {
        #| description: Path to counts matrix (TSV/CSV, genes x samples)
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

        # Validation
        if (counts == "" || meta == "" || output == "") {
            stop("--counts, --meta, and --output are required", call. = FALSE)
        }
        if (!file.exists(counts)) stop("File not found: ", counts, call. = FALSE)
        if (!file.exists(meta))   stop("File not found: ", meta, call. = FALSE)

        if (!dir.exists(output)) dir.create(output, recursive = TRUE)

        counts_df <- read_data_file(counts)
        meta_df   <- read_data_file(meta)

        se <- SummarizedExperiment(
            assays  = list(counts = as.matrix(counts_df)),
            colData = meta_df
        )
        result <- run_pca(se, n_top = n_top, log_transform = log_transform)

        save_pca_results(result, output)

        if (color_by != "") {
            plot_file <- file.path(output, "pca_plot.png")
            p <- plot_pca(result, color_by = color_by)
            png(plot_file, width = 8, height = 6, units = "in", res = 300)
            print(p)
            dev.off()
            message("Saved: ", plot_file)
        }

        message("Done.")
    }
)
```

Note how thin this is: the CLI reads files, builds an SE, calls
[`run_pca()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_pca.md)
and
[`plot_pca()`](https://st-jude-ms-abds.github.io/ADS8192/reference/plot_pca.md)
from the package, and writes output. No analysis logic lives in the CLI
script.

Click to expand the full CLI code

``` r
#!/usr/bin/env Rapp
#| name: ADS8192
#| title: ADS8192 PCA Tool & Toaster
#| description: PCA analysis for SummarizedExperiment data (ADS 8192 reference implementation).

suppressPackageStartupMessages(library(ADS8192))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(SummarizedExperiment))

# Helper to read TSV/CSV (not exported; kept in CLI script)
read_data_file <- function(path) {
    ext <- tolower(tools::file_ext(path))
    if (ext == "csv") {
        read.csv(path, row.names = 1, check.names = FALSE)
    } else {
        utils::read.table(path, sep = "\t", header = TRUE, row.names = 1,
                          check.names = FALSE)
    }
}

switch(
    "",

    #| title: Run PCA analysis
    #| description: Run PCA on a counts matrix and sample metadata, export results.
    pca = {
        #| description: Path to counts matrix (TSV/CSV, genes x samples)
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

        # Validation
        if (counts == "" || meta == "" || output == "") {
            stop("--counts, --meta, and --output are required", call. = FALSE)
        }
        if (!file.exists(counts)) {
            stop("File not found: ", counts, call. = FALSE)
        }
        if (!file.exists(meta)) {
            stop("File not found: ", meta, call. = FALSE)
        }

        if (!dir.exists(output)) dir.create(output, recursive = TRUE)

        # Read inputs
        counts_df <- read_data_file(counts)
        meta_df <- read_data_file(meta)

        # Run analysis using package core functions
        se <- SummarizedExperiment(
            assays = list(counts = as.matrix(counts_df)),
            colData = meta_df
        )
        result <- run_pca(se, n_top = n_top, log_transform = log_transform)

        save_pca_results(result, output)

        if (color_by != "") {
            plot_file <- file.path(output, "pca_plot.png")
            p <- plot_pca(result, color_by = color_by)
            png(plot_file, width = 8, height = 6, units = "in", res = 300)
            print(p)
            dev.off()
            message("Saved: ", plot_file)
        }

        message("Done.")
    },

    #| title: Make toast
    #| description: Make a slice of toast from the bread of your choice.
    toast = {
        #| description: Type of bread to use
        #| short: b
        bread <- ""

        #| description: Butter the toast
        buttered <- FALSE

        if (bread == "") {
            stop("--bread is required", call. = FALSE)
        }

        message(make_toast(bread = bread, buttered = buttered))
    }
)
```

### Step 4: Run It and Check Errors

During development, run the CLI directly from the terminal via `Rapp`:

``` bash
# Show top-level and subcommand help
Rapp exec/ADS8192.R --help
Rapp exec/ADS8192.R pca --help
```

Create test inputs from R so your command has something to chew on. A
small synthetic dataset with a treatment effect is enough to exercise
`--n-top` and `--color-by`:

``` r
dir.create("tests/testdata", recursive = TRUE, showWarnings = FALSE)

set.seed(1)
n_genes   <- 1000L
n_samples <- 8L
sample_ids <- sprintf("sample%02d", seq_len(n_samples))
gene_ids   <- sprintf("gene%04d", seq_len(n_genes))

meta <- data.frame(
    treatment = rep(c("control", "treated"), each = n_samples / 2),
    row.names = sample_ids
)

# Random baseline counts, then bump the first 100 genes in treated samples
counts <- matrix(sample(1:100, n_genes * n_samples, replace = TRUE),
                 nrow = n_genes,
                 dimnames = list(gene_ids, sample_ids))

treated <- meta$treatment == "treated"
counts[1:100, treated] <- counts[1:100, treated] + 100

utils::write.table(counts, "tests/testdata/counts.tsv",
                   sep = "\t", quote = FALSE)
utils::write.table(meta, "tests/testdata/meta.tsv",
                   sep = "\t", quote = FALSE)
```

You could also save your example dataset from the package to
`tests/testdata/` and use that.

Happy path — use a realistic `--n-top` and exercise `--color-by`:

``` bash
Rapp exec/ADS8192.R pca --counts tests/testdata/counts.tsv --meta tests/testdata/meta.tsv --output tests/testdata/output/ --n-top 500 --color-by treatment
```

Error path (missing file) — confirm a non-zero exit code:

``` bash
Rapp exec/ADS8192.R pca --counts nope.tsv --meta meta.tsv --output out/
echo %ERRORLEVEL%    # Windows: should print 1
```

If you see `Error: File not found: nope.tsv` and a non-zero exit code,
the CLI is failing the way a pipeline expects.

------------------------------------------------------------------------

## Part 4: Installing a Launcher

After installing your package, you want users to run the CLI directly
from the terminal without invoking `Rapp` or specifying the script path.
To do that, you need to install a *launcher*. We already did this
previous with `Rapp::install_pkg_cli_apps("Rapp")`, which adds the
`Rapp` command to your PATH. Now we need to add a launcher for our
specific app.

After package installation, we can instruct users to run this same
command to add the launcher for our app:

``` r
Rapp::install_pkg_cli_apps("ADS8192")
```

This adds the `Rapp` command to your terminal, which you can use to run
Rapp scripts during development. After running the launcher installer,
the CLI works cleanly directly from the terminal:

``` bash
ADS8192 pca --help
```

Instructions for this process should be added to your README CLI
section.

------------------------------------------------------------------------

## Part 5: The CLI Is a Contract

Once anyone automates against your CLI, **argument names, output file
names, and output column names become a contract**. Pipeline users
hard-code those strings, and renaming them breaks downstream work
silently.

### What’s Breaking?

| Change                        | Breaking?  |
|-------------------------------|------------|
| Rename `--n-top` to `--n_top` | Yes        |
| Add new optional flag         | No         |
| Remove a flag                 | Yes        |
| Change output column names    | Yes        |
| Add new output columns        | Usually no |
| Change default value          | Maybe      |

### Semantic Versioning

- **MAJOR** (1.0.0 → 2.0.0): breaking CLI interface changes
- **MINOR** (1.0.0 → 1.1.0): new features, backward compatible
- **PATCH** (1.0.0 → 1.0.1): bug fixes

Document every interface change in `NEWS.md`. If you have to break
something, do it in a major bump with a clear migration note — not
quietly in a patch.

------------------------------------------------------------------------

## Summary

Today we:

1.  Learned five CLI design principles: help text, explicit I/O,
    reproducible defaults, exit codes, machine-readable output
2.  Introduced Rapp and its `switch("")` subcommand idiom
3.  Added a Rapp app to the existing ADS8192 package (`exec/ADS8192.R`,
    `Rapp` in `DESCRIPTION`)
4.  Demonstrated how a CLI launcher can be easily installed with
    [`Rapp::install_pkg_cli_apps()`](https://rdrr.io/pkg/Rapp/man/install_pkg_cli_apps.html)
5.  Ran the CLI during development and checked error behavior

### Package Milestone

**The ADS8192 package now has a working CLI in `exec/` that is easily
installed as an executable on the user’s PATH.**

------------------------------------------------------------------------

### Debrief & Reflection

Before moving on, make sure you can answer:

- When is a CLI genuinely useful, and when is it an unnecessary extra
  interface?
- How does `Rapp` let you avoid reinventing plumbing so you can focus on
  I/O contracts and DRY reuse of the package core?

------------------------------------------------------------------------

## After-Class Tasks

### Micro-task 1: Consider a `validate` Subcommand

Consider a second subcommand that checks inputs without running PCA —
useful for pipeline pre-flight checks. It could:

1.  Check that `--counts` and `--meta` exist and parse
2.  Report dimensions
3.  Check that counts column names match metadata row names

Add it as a second case in the same
[`switch()`](https://rdrr.io/r/base/switch.html) call alongside `pca`.

------------------------------------------------------------------------

## CLI Quick Reference

``` bash
# During development
Rapp exec/ADS8192.R --help
Rapp exec/ADS8192.R pca --help

Rapp exec/ADS8192.R pca \
    --counts counts.tsv \
    --meta samples.tsv \
    --output results/ \
    --n-top 500 \
    --color-by treatment

# Check exit code (Windows)
echo %ERRORLEVEL%
```

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
    ## [25] rlang_1.2.0       fs_2.1.0          htmlwidgets_1.6.4
