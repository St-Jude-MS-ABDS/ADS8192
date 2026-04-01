# Lecture 3: Data Structures & R Ecosystems (Bioconductor)

## Learning Objectives

By the end of this session, you will be able to:

1.  Generate a `SummarizedExperiment` object from raw assay data and
    sample metadata
2.  Find and use Bioconductor package documentation (vignettes/manuals)
    to select an appropriate existing container before building anything
    custom
3.  Build a complete analysis core: constructor, feature selection,
    analysis, summary, plotting, and export functions
4.  Prepare a bundled example dataset using a `data-raw/` script
5.  Write small, testable functions with input validation that take
    structured objects as input and return well-defined outputs
6.  See how one set of core functions powers three interfaces (R API,
    Shiny, CLI)

**Course Learning Outcomes (CLOs):** CLO 1, 3

### Motivation

Scientific software becomes fragile very quickly when assay matrices,
sample metadata, and feature annotations drift out of sync. A good data
model prevents entire classes of silent mistakes before you ever write a
plot, app, or pipeline.

This lecture matters because robust containers and clear function
contracts save time later. If your data structure is reliable and your
core functions accept and return well-defined objects, you can test them
more easily, hand them to collaborators with less explanation, and reuse
the same analysis logic across package code, Shiny apps, and CLIs
without constant rewrites.

### Evaluation Checklist

Before you adopt or build a data structure, ask:

- Does it fit the scientific problem and expected scale?
- Does its data model keep related pieces synchronized?
- Is the input/output contract explicit and documented?
- Does it interoperate with packages your collaborators already use?
- Is it maintained and broadly understood in the community?
- Would a thin wrapper around an existing container be safer than a new
  class?

### Scientific Use Case

A collaborator gives you raw counts, sample metadata, and gene
annotations as three CSV files from a pilot RNA-seq experiment. You need
exploratory analysis this week, but six months from now the same work
may need to support a package, dashboard, or pipeline. Which design
choices now will keep that future refactor small?

------------------------------------------------------------------------

## Why Structured Data Containers?

### The Problem with Loose Data

Imagine you’re analyzing gene expression data. You might have:

- A **counts matrix**: genes × samples
- A **sample metadata table**: sample info (treatment, batch, etc.)
- A **gene annotation table**: gene symbols, descriptions, etc.

If these are three separate objects, you face several problems:

``` r
# Dangerous: Three separate objects that can get out of sync
counts <- read.csv("counts.csv", row.names = 1)
sample_info <- read.csv("sample_metadata.csv")
gene_info <- read.csv("gene_annotations.csv")

# What happens if you subset counts but forget to subset sample_info?
counts_subset <- counts[, 1:5]
# sample_info still has all samples - now mismatched!

# What if you accidentally reorder one but not the others?
counts <- counts[, order(colnames(counts))]
# Now sample_info doesn't match the column order!
```

### The Solution: Structured Containers

Bioconductor’s `SummarizedExperiment` class keeps everything
synchronized:

                        colData (sample metadata)
                        ┌───────────────────────┐
                        │ sample treatment batch │
                        │ S1     trt      A     │
                        │ S2     ctrl     A     │
                        │ S3     trt      B     │
                        └───────────────────────┘
                                  ↓
                  ┌───────────────────────────────┐
                  │        assays (counts)         │
       rowData    │         S1    S2    S3         │
       (genes)  → │ gene1  100   150   120         │
                  │ gene2   50    75    60         │
                  │ gene3  200   180   210         │
                  └───────────────────────────────┘

When you subset or reorder a `SummarizedExperiment`, all components stay
synchronized automatically!

------------------------------------------------------------------------

## Group Discussion + Pseudocode: Designing a Gene Data Structure

**Prompt:** “How would you create a data structure to represent a gene?”

Discuss in groups and sketch a simple structure. Think about:

- Which fields are **core** (required) vs **derived** (can be computed)?
- Which fields are **optional** vs **always present**?
- How will you ensure **validity** (e.g., start \<= end, strand in
  {+,-})?

#### Simple Pseudocode (List-Based)

``` r
gene <- list(
    gene_id = "ENSG00000141510",
    symbol = "TP53",
    chr = "17",
    start = 7661779,
    end = 7687550,
    strand = "-",
    biotype = "protein_coding",
    length = 7687550 - 7661779 + 1  # derived
)
```

#### S4-Style Sketch (Class + Constructor)

``` r
setClass("Gene",
         slots = c(
             gene_id = "character",
             symbol = "character",
             chr = "character",
             start = "integer",
             end = "integer",
             strand = "character",
             biotype = "character"
         ))

Gene <- function(gene_id, symbol, chr, start, end, strand, biotype) {
    new("Gene",
        gene_id = gene_id,
        symbol = symbol,
        chr = chr,
        start = as.integer(start),
        end = as.integer(end),
        strand = strand,
        biotype = biotype
    )
}
```

------------------------------------------------------------------------

### Why S4 in Bioconductor?

Bioconductor packages rely heavily on **S4 classes** because they
provide:

- **Formal class definitions** (clear structure and types)
- **Validity checks** (catch invalid objects early)
- **Method dispatch** (functions behave differently based on object
  class)

`SummarizedExperiment` is an S4 class. Its formal structure and methods
keep assays, rowData, and colData synchronized and enforce consistency.

### S4 Best Practices (Design Checklist)

- Keep **slots minimal** and focused on essential fields
- Write **validity checks** for invariants (e.g., `start <= end`)
- Provide **constructor functions** so users don’t call
  [`new()`](https://rdrr.io/r/methods/new.html) directly
- Use **accessor methods** instead of direct slot access (`@`)
- Document **invariants** and expected slot types
- Avoid storing **redundant derived values** when they can be computed

------------------------------------------------------------------------

## Finding Existing Bioconductor Solutions

Before you create a new class or container, spend a few minutes checking
whether the ecosystem already solved the problem:

``` r
# Read the class help and vignette first
?SummarizedExperiment
browseVignettes(package = "SummarizedExperiment")

# If you expect single-cell-specific behavior, compare the next layer up
?SingleCellExperiment
browseVignettes(package = "SingleCellExperiment")
```

Look for:

- **Problem fit**: Does the class match bulk RNA-seq, single-cell, or
  another assay type?
- **Data model fit**: Can it represent assays, feature metadata, and
  sample metadata without hacks?
- **Contract clarity**: Are the accessors and invariants clear from the
  docs?
- **Interoperability**: Do downstream packages already expect this
  container?
- **Maintenance**: Is the package well documented and actively used?

For this course we rebuild a tiny example to make the design visible. In
professional work, the default should be to reuse and extend an existing
ecosystem type unless you have a concrete reason not to.

------------------------------------------------------------------------

## Setup: Installing Required Packages

If you haven’t already, install the required Bioconductor packages:

``` r
if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

BiocManager::install(c(
    "SummarizedExperiment",
    "airway",
    "ComplexHeatmap"
))

# Also install ggplot2 for visualization
install.packages("ggplot2")
```

Now load the libraries:

``` r
library(SummarizedExperiment)
library(airway)
library(ComplexHeatmap)
library(ggplot2)
```

------------------------------------------------------------------------

## The `airway` Dataset

We’ll use the `airway` dataset, which contains RNA-seq data from airway
smooth muscle cells. The experiment compared cells treated with
dexamethasone (a corticosteroid) to untreated cells.

``` r
data("airway")
airway
```

### Exploring the Structure

#### What class is this object?

``` r
class(airway)
```

`RangedSummarizedExperiment` is a subclass of `SummarizedExperiment`
that also stores genomic ranges for each feature (gene).

#### Dimensions: How many genes and samples?

``` r
dim(airway)
nrow(airway)  # genes (features)
ncol(airway)  # samples
```

#### Sample Metadata (colData)

The
[`colData()`](https://rdrr.io/pkg/SummarizedExperiment/man/SummarizedExperiment-class.html)
function extracts sample-level metadata:

``` r
colData(airway)
```

Key variables: - `cell`: Cell line identifier - `dex`: Treatment
status - “trt” (dexamethasone) or “untrt” (control)

``` r
# Access as a data.frame
as.data.frame(colData(airway))

# Access specific columns
airway$dex
airway$cell
```

#### Gene/Feature Data (rowData)

The
[`rowData()`](https://rdrr.io/pkg/SummarizedExperiment/man/SummarizedExperiment-class.html)
function extracts feature-level (gene) metadata:

``` r
rowData(airway)
```

#### Assay Data (the counts!)

The actual expression data is stored in “assays”. This dataset has one
assay called “counts”:

``` r
# What assays are available?
assayNames(airway)

# Get the counts matrix
counts_matrix <- assay(airway, "counts")
# Or equivalently: assays(airway)$counts

# Check dimensions
dim(counts_matrix)

# Preview first few genes and samples
counts_matrix[1:5, 1:4]
```

> **Exercise A (Warm-up):** Use
> [`head()`](https://rdrr.io/r/utils/head.html) and
> [`tail()`](https://rdrr.io/r/utils/head.html) to explore the counts
> matrix. What is the range of count values? Use
> [`summary()`](https://rdrr.io/r/base/summary.html) on a single column
> to find out.

------------------------------------------------------------------------

## Building the Analysis Core

Now we’ll build a set of reusable functions that form the “analysis
core” of our package. These functions will later be:

1.  Packaged into an R package (Lecture 5)
2.  Wrapped by a Shiny app (Lectures 7-8)
3.  Exposed via a CLI (Lectures 9-10)

### Creating a SummarizedExperiment from Components

The
[`SummarizedExperiment()`](https://rdrr.io/pkg/SummarizedExperiment/man/SummarizedExperiment-class.html)
constructor is straightforward — pass a named list of assay matrices, a
sample metadata data.frame, and optionally gene metadata:

``` r
# Extract components from airway
test_counts <- assay(airway, "counts")
test_meta <- as.data.frame(colData(airway))

# Create a new SE directly — the constructor is already a clear one-liner
my_se <- SummarizedExperiment(
    assays = list(counts = test_counts),
    colData = test_meta
)

# Verify it worked
my_se
dim(my_se)
colData(my_se)
```

> **Exercise B:** Modify the constructor call above to also include
> `rowData`. Extract it from `airway` first, then pass it via the
> `rowData` argument.

------------------------------------------------------------------------

### Function 1: `top_variable_features()` — Select Most Variable Genes

For PCA, we typically want to focus on the most variable genes:

``` r
#' Select top variable features
#'
#' @param se A SummarizedExperiment object
#' @param n Number of top variable features to select (default: 500)
#' @param assay_name Name of assay to use (default: "counts")
#'
#' @return A SummarizedExperiment subset to the top n variable features
top_variable_features <- function(se, n = 500, assay_name = "counts") {
    # Get the assay data
    mat <- assay(se, assay_name)
    
    # Calculate variance for each gene (row)
    vars <- apply(mat, 1, var)
    
    # Get indices of top n most variable
    top_idx <- order(vars, decreasing = TRUE)[seq_len(min(n, length(vars)))]
    
    # Subset the SummarizedExperiment
    se[top_idx, ]
}
```

``` r
# Get top 500 variable genes
se_top <- top_variable_features(airway, n = 500)
dim(se_top)
```

> **Discussion:** Why do we return the subsetted `SummarizedExperiment`
> rather than just a matrix of values? What advantage does this provide?

------------------------------------------------------------------------

### Function 2: `run_pca()` — Perform PCA

Now let’s run PCA on our data:

``` r
#' Run PCA on a SummarizedExperiment
#'
#' @param se A SummarizedExperiment object
#' @param assay_name Name of assay to use (default: "counts")
#' @param n_top Number of top variable features to use (default: 500)
#' @param scale Logical; should features be scaled? (default: TRUE)
#' @param log_transform Logical; should counts be log-transformed? (default: TRUE)
#'
#' @return A list with:
#'   - pca: The prcomp object
#'   - scores: A data.frame of PC scores merged with sample metadata
run_pca <- function(se, assay_name = "counts", n_top = 500, 
                    scale = TRUE, log_transform = TRUE) {
    # Subset to top variable features
    se_top <- top_variable_features(se, n = n_top, assay_name = assay_name)
    
    # Get the data matrix
    mat <- assay(se_top, assay_name)
    
    # Log-transform if requested (add pseudocount to avoid log(0))
    if (log_transform) {
        mat <- log2(mat + 1)
    }
    
    # Transpose: prcomp expects samples as rows
    mat_t <- t(mat)
    
    # Run PCA
    pca_result <- prcomp(mat_t, scale. = scale, center = TRUE)
    
    # Create scores data.frame with sample metadata
    scores <- as.data.frame(pca_result$x)
    scores$sample_id <- rownames(scores)
    
    # Merge with colData
    col_data <- as.data.frame(colData(se))
    col_data$sample_id <- rownames(col_data)
    scores <- merge(scores, col_data, by = "sample_id")
    
    return(list(
        pca = pca_result,
        scores = scores
    ))
}
```

``` r
# Run PCA on airway data
pca_result <- run_pca(airway, n_top = 500)

# Examine the scores
head(pca_result$scores)

# Check variance explained
summary(pca_result$pca)
```

------------------------------------------------------------------------

### Function 3: `pca_variance_explained()` — Helper for Variance

``` r
#' Get variance explained by each PC
#'
#' @param pca_result Output from run_pca()
#'
#' @return A data.frame with PC names and percent variance explained
pca_variance_explained <- function(pca_result) {
    pca <- pca_result$pca
    var_explained <- pca$sdev^2 / sum(pca$sdev^2) * 100
    
    data.frame(
        PC = paste0("PC", seq_along(var_explained)),
        variance_percent = var_explained
    )
}
```

``` r
var_df <- pca_variance_explained(pca_result)
head(var_df)
```

------------------------------------------------------------------------

### Function 4: `plot_pca()` — Visualize PCA Results

``` r
#' Create a PCA scatter plot
#'
#' @param pca_result Output from run_pca()
#' @param color_by Column name from colData to color points by
#' @param shape_by Optional column name to map to point shape
#' @param pcs Which PCs to plot (default: c(1, 2))
#' @param point_size Size of points (default: 4)
#'
#' @return A ggplot object
plot_pca <- function(pca_result, color_by = NULL, shape_by = NULL, 
                     pcs = c(1, 2), point_size = 4) {
    scores <- pca_result$scores
    var_exp <- pca_variance_explained(pca_result)
    
    # Build PC column names
    pc_x <- paste0("PC", pcs[1])
    pc_y <- paste0("PC", pcs[2])
    
    # Get variance percentages for axis labels
    var_x <- round(var_exp$variance_percent[pcs[1]], 1)
    var_y <- round(var_exp$variance_percent[pcs[2]], 1)
    
    # Build the plot
    p <- ggplot(scores, aes(x = .data[[pc_x]], y = .data[[pc_y]])) +
        theme_minimal(base_size = 14) +
        labs(
            x = paste0(pc_x, " (", var_x, "% variance)"),
            y = paste0(pc_y, " (", var_y, "% variance)"),
            title = "PCA Plot"
        )
    
    # Add color aesthetic if specified
    if (!is.null(color_by)) {
        p <- p + aes(color = .data[[color_by]])
    }
    
    # Add shape aesthetic if specified
    if (!is.null(shape_by)) {
        p <- p + aes(shape = .data[[shape_by]])
    }
    
    # Add points
    p <- p + geom_point(size = point_size)
    
    return(p)
}
```

#### Creating PCA Visualizations

``` r
# Basic PCA plot colored by treatment
plot_pca(pca_result, color_by = "dex")
```

``` r
# Color by treatment, shape by cell line
plot_pca(pca_result, color_by = "dex", shape_by = "cell")
```

> **Exercise C:** Create a PCA plot showing PC2 vs PC3 instead of PC1 vs
> PC2. What do you observe?

------------------------------------------------------------------------

### Function 5: `save_pca_results()` — Export Results to Files

The CLI and reproducible scripts need to write analysis outputs to disk.
This function exports PCA scores, variance, and optionally a plot — the
same outputs your CLI subcommand will produce:

``` r
#' Save PCA results to files
#'
#' @param pca_result Output from run_pca()
#' @param output_dir Directory to save files (created if it doesn't exist)
#' @param color_by Optional: metadata column for PCA plot coloring
#'
#' @return Invisible NULL; called for side effects (writing files)
save_pca_results <- function(pca_result, output_dir, color_by = NULL) {
    if (!is.character(output_dir) || length(output_dir) != 1) {
        stop("output_dir must be a single directory path")
    }
    
    if (!dir.exists(output_dir)) {
        dir.create(output_dir, recursive = TRUE)
    }
    
    # Export PCA scores
    scores_file <- file.path(output_dir, "pca_scores.tsv")
    write.table(pca_result$scores, scores_file, sep = "\t",
                row.names = FALSE, quote = FALSE)
    message("Wrote: ", scores_file)
    
    # Export variance explained
    var_df <- pca_variance_explained(pca_result)
    var_file <- file.path(output_dir, "pca_variance.tsv")
    write.table(var_df, var_file, sep = "\t",
                row.names = FALSE, quote = FALSE)
    message("Wrote: ", var_file)
    
    # Optionally save the plot
    if (!is.null(color_by)) {
        plot_file <- file.path(output_dir, "pca_plot.png")
        p <- plot_pca(pca_result, color_by = color_by)
        ggplot2::ggsave(plot_file, p, width = 8, height = 6, dpi = 150)
        message("Wrote: ", plot_file)
    }
    
    invisible(NULL)
}
```

``` r
# Save results to a temporary directory
tmp_out <- file.path(tempdir(), "pca_output")
save_pca_results(pca_result, tmp_out, color_by = "dex")

# Check what was created
list.files(tmp_out)

# Read back and verify
scores_back <- read.table(file.path(tmp_out, "pca_scores.tsv"),
                          header = TRUE, sep = "\t")
head(scores_back)
```

> **Note:** Every project in the [Project Selection
> Guide](https://st-jude-ms-abds.github.io/ADS8192/articles/project-selection.md)
> must produce TSV files from the CLI. Your export function is the
> bridge between the analysis core and the command line.

------------------------------------------------------------------------

## Visualization with ComplexHeatmap

Let’s visualize the top variable genes using a heatmap. This is a common
way to explore patterns in gene expression data.

``` r
# Get top 20 most variable genes for visualization
se_top20 <- top_variable_features(airway, n = 20)

# Extract and log-transform the counts
heatmap_mat <- log2(assay(se_top20, "counts") + 1)

# Scale by row (gene) for better visualization
heatmap_mat <- t(scale(t(heatmap_mat)))
```

``` r
# Create annotation for columns (samples)
col_anno <- HeatmapAnnotation(
    treatment = airway$dex,
    cell_line = airway$cell,
    col = list(
        treatment = c("trt" = "steelblue", "untrt" = "salmon"),
        cell_line = c("N052611" = "#E41A1C", "N061011" = "#377EB8", 
                      "N080611" = "#4DAF4A", "N61311" = "#984EA3")
    )
)

# Create the heatmap
Heatmap(
    heatmap_mat,
    name = "Z-score",
    top_annotation = col_anno,
    show_row_names = TRUE,
    show_column_names = TRUE,
    column_title = "Top 20 Variable Genes",
    row_names_gp = gpar(fontsize = 8)
)
```

> **Exercise D:** Modify the code to show the top 50 variable genes. You
> may need to adjust `show_row_names` for readability.

------------------------------------------------------------------------

## Preparing Example Data (`data-raw/`)

Every package you build for
[HW1](https://st-jude-ms-abds.github.io/ADS8192/articles/HW1_Rubric.md)
must include a **bundled example dataset** in `data/` that is loadable
via [`data()`](https://rdrr.io/r/utils/data.html). The dataset should be
generated by a reproducible script in `data-raw/`. Here is the pattern
for our reference package, starting from the full `airway` dataset:

``` r
## data-raw/example_se.R
## -----------------------------------------------------------
## This script creates a small example SummarizedExperiment
## from the airway dataset for use in package examples and tests.
## -----------------------------------------------------------
library(SummarizedExperiment)
library(airway)

data("airway")

# Keep top 100 most variable genes + 400 random genes = 500 total
counts <- assay(airway, "counts")
vars <- apply(counts, 1, var)
top100 <- names(sort(vars, decreasing = TRUE))[1:100]

set.seed(42)
rest <- sample(setdiff(rownames(counts), top100), 400)

example_se <- airway[c(top100, rest), ]

# Simplify colData to the columns students will use
colData(example_se) <- colData(example_se)[, c("cell", "dex")]
colnames(colData(example_se)) <- c("cell_line", "treatment")

# Save to data/
usethis::use_data(example_se, overwrite = TRUE)
```

After running this script, `data/example_se.rda` is created and users
can load it with `data("example_se")`.

> **For your project:** Adapt this pattern for your chosen dataset. See
> the `data-raw/` scripts in each [project
> description](https://st-jude-ms-abds.github.io/ADS8192/articles/project-selection.md).
> Single-cell projects will save an `example_sce` instead.

------------------------------------------------------------------------

## Summary: The Analysis Core

We now have five core functions that work together — everything a
student package needs for the [HW1
rubric](https://st-jude-ms-abds.github.io/ADS8192/articles/HW1_Rubric.md):

| Rubric Category       | Function                                                                                                    | Input                   | Output            |
|-----------------------|-------------------------------------------------------------------------------------------------------------|-------------------------|-------------------|
| Analysis \#1 (1 pt)   | [`top_variable_features()`](https://st-jude-ms-abds.github.io/ADS8192/reference/top_variable_features.md)   | SE + n                  | Subsetted SE      |
| Analysis \#2 (1 pt)   | [`run_pca()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_pca.md)                               | SE + parameters         | list(pca, scores) |
| Summary/metric (1 pt) | [`pca_variance_explained()`](https://st-jude-ms-abds.github.io/ADS8192/reference/pca_variance_explained.md) | PCA result              | data.frame        |
| Plotting (1 pt)       | [`plot_pca()`](https://st-jude-ms-abds.github.io/ADS8192/reference/plot_pca.md)                             | PCA result + aesthetics | ggplot            |
| Export (CLI)          | [`save_pca_results()`](https://st-jude-ms-abds.github.io/ADS8192/reference/save_pca_results.md)             | PCA result + output dir | TSV files on disk |

Design principles shared by all five:

- **Take structured objects as input** — Not loose matrices that can get
  out of sync
- **Return well-defined outputs** — Predictable return types make them
  composable
- **Validate inputs with [`stop()`](https://rdrr.io/r/base/stop.html)**
  — Informative error messages, not silent failures
- **Are small and testable** — Each does one thing well
- **Are reusable** — They don’t depend on global variables or specific
  file paths

------------------------------------------------------------------------

## Three Interfaces, One Core

The five functions above form the **analysis core**. For HW1, you will
expose them through **three interfaces** — each calling the same core
functions:

                        Analysis Core
      run_pca() → plot_pca() → save_pca_results()
            ↑            ↑            ↑            
       ┌────┴────┐  ┌────┴────┐  ┌───┴─────┐
       │ R API   │  │ Shiny   │  │  CLI    │
       │ (users) │  │ (web)   │  │(scripts)│
       └─────────┘  └─────────┘  └─────────┘

#### Interface 1: R API (Lectures 5–6)

Users call your exported functions directly from R:

``` r
library(sePCA)
data("example_se")
result <- run_pca(example_se, n_top = 500)
plot_pca(result, color_by = "treatment")
save_pca_results(result, "results/")
```

#### Interface 2: Shiny App (Lectures 7–8)

The Shiny server calls the same functions reactively:

``` r
# Inside app_server.R (simplified)
result <- reactive({
    run_pca(data(), n_top = input$n_top)
})

output$pca_plot <- renderPlot({
    plot_pca(result(), color_by = input$color_by)
})
```

#### Interface 3: CLI via Rapp (Lectures 9–10)

The CLI script in `exec/` parses arguments and calls the same functions:

``` r
#!/usr/bin/env Rapp
#| name: sePCA
#| description: PCA analysis for SummarizedExperiment data.

suppressPackageStartupMessages(library(sePCA))

counts <- ""   # --counts FILE
meta   <- ""   # --meta   FILE
output <- ""   # --output DIR
n_top  <- 500L # --n-top  INT

# Read data, build SE, run analysis, save results
counts_df <- read.table(counts, sep = "\t", header = TRUE, row.names = 1)
meta_df   <- read.table(meta,   sep = "\t", header = TRUE, row.names = 1)
se     <- SummarizedExperiment(
    assays = list(counts = as.matrix(counts_df)),
    colData = meta_df
)
result <- run_pca(se, n_top = n_top)
save_pca_results(result, output)
```

> **Key insight:** Fix a bug in
> [`run_pca()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_pca.md)
> and it’s fixed in all three interfaces. Add a feature to
> [`plot_pca()`](https://st-jude-ms-abds.github.io/ADS8192/reference/plot_pca.md)
> and the Shiny app and CLI both benefit. This is the power of the
> “three interfaces, one core” architecture.

------------------------------------------------------------------------

## Debrief & Reflection

Before leaving this lecture, make sure you can answer:

- Why is reusing `SummarizedExperiment` usually better than inventing a
  custom container?
- Which parts of today’s PCA workflow are domain logic, and which parts
  are interface or packaging concerns?
- If your future project needs a new abstraction, could it be a thin
  wrapper around an existing Bioconductor class instead of a brand-new
  data structure?

------------------------------------------------------------------------

## After-Class Tasks

### Micro-task 1: Create `analysis_core.R`

Put all five functions into a single script called `analysis_core.R`:
[`top_variable_features()`](https://st-jude-ms-abds.github.io/ADS8192/reference/top_variable_features.md),
[`run_pca()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_pca.md),
[`pca_variance_explained()`](https://st-jude-ms-abds.github.io/ADS8192/reference/pca_variance_explained.md),
[`plot_pca()`](https://st-jude-ms-abds.github.io/ADS8192/reference/plot_pca.md),
and
[`save_pca_results()`](https://st-jude-ms-abds.github.io/ADS8192/reference/save_pca_results.md).

Requirements:

- roxygen2-style comment header for every function (`#' @param`,
  `#' @return`)
- Input validation using [`stop()`](https://rdrr.io/r/base/stop.html) in
  [`save_pca_results()`](https://st-jude-ms-abds.github.io/ADS8192/reference/save_pca_results.md)
- No [`library()`](https://rdrr.io/r/base/library.html) calls inside the
  functions (we’ll handle dependencies properly in Lecture 5)

### Micro-task 2: Choose Your Project & Write `data-raw/`

Browse the [Project Selection
Guide](https://st-jude-ms-abds.github.io/ADS8192/articles/project-selection.md)
and pick your HW1 project. Then write the `data-raw/example_se.R` (or
`example_sce.R`) script that downloads your chosen Bioconductor dataset
and prepares a bundled example object. Verify that your script runs
end-to-end and that you can call `usethis::use_data()` on the result.

### Micro-task 3: Reflection

Write 3-5 sentences describing why a structured container
(`SummarizedExperiment`) is preferable to passing 3 separate
`data.frames` around. Consider:

- What happens when you subset?
- What happens when you reorder?
- How does it affect function signatures?

### Reading

- [Project Selection
  Guide](https://st-jude-ms-abds.github.io/ADS8192/articles/project-selection.md)
  — choose your project!
- [HW1
  Rubric](https://st-jude-ms-abds.github.io/ADS8192/articles/HW1_Rubric.md)
  — the grading criteria
- Advanced R sections on OOP + S4 (alignment workbook links)
- SummarizedExperiment vignette (run
  [`vignette("SummarizedExperiment")`](https://bioconductor.org/packages/release/bioc/vignettes/SummarizedExperiment/inst/doc/SummarizedExperiment.html))

------------------------------------------------------------------------

## Appendix: Complete Function Reference

``` r
# SAVE THIS AS: analysis_core.R

#' Select top variable features
top_variable_features <- function(se, n = 500, assay_name = "counts") {
    mat <- assay(se, assay_name)
    vars <- apply(mat, 1, var)
    top_idx <- order(vars, decreasing = TRUE)[seq_len(min(n, length(vars)))]
    se[top_idx, ]
}

#' Run PCA on a SummarizedExperiment
run_pca <- function(se, assay_name = "counts", n_top = 500, 
                    scale = TRUE, log_transform = TRUE) {
    se_top <- top_variable_features(se, n = n_top, assay_name = assay_name)
    mat <- assay(se_top, assay_name)
    if (log_transform) mat <- log2(mat + 1)
    mat_t <- t(mat)
    pca_result <- prcomp(mat_t, scale. = scale, center = TRUE)
    scores <- as.data.frame(pca_result$x)
    scores$sample_id <- rownames(scores)
    col_data <- as.data.frame(colData(se))
    col_data$sample_id <- rownames(col_data)
    scores <- merge(scores, col_data, by = "sample_id")
    list(pca = pca_result, scores = scores)
}

#' Get variance explained by each PC
pca_variance_explained <- function(pca_result) {
    pca <- pca_result$pca
    var_explained <- pca$sdev^2 / sum(pca$sdev^2) * 100
    data.frame(PC = paste0("PC", seq_along(var_explained)), 
               variance_percent = var_explained)
}

#' Create a PCA scatter plot
plot_pca <- function(pca_result, color_by = NULL, shape_by = NULL, 
                     pcs = c(1, 2), point_size = 4) {
    scores <- pca_result$scores
    var_exp <- pca_variance_explained(pca_result)
    pc_x <- paste0("PC", pcs[1])
    pc_y <- paste0("PC", pcs[2])
    var_x <- round(var_exp$variance_percent[pcs[1]], 1)
    var_y <- round(var_exp$variance_percent[pcs[2]], 1)
    p <- ggplot(scores, aes(x = .data[[pc_x]], y = .data[[pc_y]])) +
        theme_minimal(base_size = 14) +
        labs(x = paste0(pc_x, " (", var_x, "% variance)"),
             y = paste0(pc_y, " (", var_y, "% variance)"),
             title = "PCA Plot")
    if (!is.null(color_by)) p <- p + aes(color = .data[[color_by]])
    if (!is.null(shape_by)) p <- p + aes(shape = .data[[shape_by]])
    p + geom_point(size = point_size)
}

#' Save PCA results to files
save_pca_results <- function(pca_result, output_dir, color_by = NULL) {
    if (!is.character(output_dir) || length(output_dir) != 1) {
        stop("output_dir must be a single directory path")
    }
    if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
    scores_file <- file.path(output_dir, "pca_scores.tsv")
    write.table(pca_result$scores, scores_file, sep = "\t",
                row.names = FALSE, quote = FALSE)
    var_df <- pca_variance_explained(pca_result)
    var_file <- file.path(output_dir, "pca_variance.tsv")
    write.table(var_df, var_file, sep = "\t",
                row.names = FALSE, quote = FALSE)
    if (!is.null(color_by)) {
        plot_file <- file.path(output_dir, "pca_plot.png")
        p <- plot_pca(pca_result, color_by = color_by)
        ggplot2::ggsave(plot_file, p, width = 8, height = 6, dpi = 150)
    }
    invisible(NULL)
}
```

------------------------------------------------------------------------

## Session Info

``` r
sessionInfo()
```
