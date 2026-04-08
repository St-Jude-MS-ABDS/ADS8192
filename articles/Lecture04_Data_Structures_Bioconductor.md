# Lecture 4: Data Structures & R Ecosystems (Bioconductor)

## Motivation

The first half of “data science” is data. This key facet is often
overlooked and underappreciated, but how data is managed and structured
is a critical aspect of robust analysis and maintainable scientific
software. It can enable or constain how quickly and easily you can
perform analyses, build tools, and collaborate with others.

If your data structures are reliable and your code accepts and returns
well-defined objects, you can test them more easily, hand them to
collaborators with less explanation, and reuse the same code across
experiments and analyses more effectively.

Thus,

------------------------------------------------------------------------

## Group Discussion + Pseudocode: Designing a Gene Data Structure

**Prompt:** “How would you create a data structure to represent a gene?”

Discuss in groups and sketch a simple structure. Think about:

- Which fields are **core** (required) vs **derived** (can be computed)?
- Which fields are **optional** vs **always present**?
- How will you ensure **validity** (e.g., start \<= end, strand in
  {+,-})?

### Simple Pseudocode (List-Based)

For instance, if we just used a list with elements for fields we care
about, it might look like:

Example list-based structure

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

What are the most immediate issues of such a simple approach?

------------------------------------------------------------------------

## Object Oriented Programming in R

R has several systems for defining custom classes and methods, each with
their own advantages and tradeoffs:

- **[S3](https://adv-r.hadley.nz/s3.html)**: Informal, flexible, and
  widely used. Classes are just character vectors, and method dispatch
  is based on naming conventions (e.g., `print.myclass()`). No formal
  class definitions or validity checks.
- **[S4](https://adv-r.hadley.nz/s4.html)**: Formal class definitions
  with typed slots, validity checks, and formal method dispatch. More
  robust but more verbose and complex to set up.
- **[R6](https://adv-r.hadley.nz/r6.html)**: Reference classes with
  mutable state and object-oriented programming features. Less common in
  bioinformatics but useful for certain applications.

You can read more about these individual systems and [their
tradeoffs](https://adv-r.hadley.nz/oo-tradeoffs.html) in the Advanced R
book, but we will focus mostly on S4 for reasons described below.

## Why S4 in Bioconductor?

Bioconductor packages rely heavily on R’s **S4 classes** because they
provide:

- **Formal class definitions** (clear structure and types)
- **Validity checks** (catch invalid objects early)
- **Method dispatch** (functions behave differently based on object
  class)

These are very attractive features for building complex data structures
that need to be robust and interoperable across a large ecosystem of
packages. S3 is much more flexible and simpler, but it lacks the formal
structure and safety guarantees that S4 provides.

S3 provides limited mechanisms to keep users from doing really stupid
things with your objects, which is important when your objects are
complex and serve as the basis for many downstream analyses.

S4 also requires more upfront thought and design, which should generally
be encouraged for scientific software.

### S4-Style Sketch (Class + Constructor)

Building a custom S4 class for our gene above might look like this.

The first step is registering the class and its **slots** — the typed
fields every instance must carry:

``` r
# setClass() registers the class with R's S4 system.
# `slots` is a named character vector: name -> type.
# R enforces these types at construction time: passing a non-character to
# `gene_id` will throw an error immediately, not silently coerce it.
setClass("Gene",
         slots = c(
             gene_id = "character",
             symbol  = "character",
             chr     = "character",
             start   = "integer",
             end     = "integer",
             strand  = "character",
             biotype = "character"
         ))
```

`new("Gene", ...)` would work directly, but we wrap it in a
**constructor function** so callers don’t need to know the internal
class name — and so we have one place to coerce types, run checks, and
set defaults:

``` r
# The constructor is just a regular function. It:
#   1. Accepts user-friendly types (numeric start/end is fine)
#   2. Coerces them to the slot types the class expects
#   3. Delegates to new() with slot values already validated
#
# Users should never call new("Gene", ...) directly — always use Gene().
Gene <- function(gene_id, symbol, chr, start, end, strand, biotype) {
    new("Gene",
        gene_id = gene_id,
        symbol  = symbol,
        chr     = chr,
        start   = as.integer(start),   # coerce numeric → integer
        end     = as.integer(end),
        strand  = strand,
        biotype = biotype
    )
}
```

------------------------------------------------------------------------

### Step 2: Adding a Validity Method

A class with no validity check will happily hold nonsense — a gene where
`start > end`, or a `strand` character that is neither `"+"` nor `"-"`.

> **What is an invariant?**
>
> An invariant is a condition that must *always* be true for an object
> to be considered valid — regardless of how it was created or modified.
> For a genomic coordinate object, `start <= end` is an invariant: there
> is no meaningful gene where the end comes before the start.
> `strand %in% c("+", "-", "*")` is another — the strand field only
> makes sense for a fixed vocabulary of values. Invariants are distinct
> from *defaults* (which are suggestions) and *types* (which R enforces
> slot-by-slot) — they encode domain knowledge that the type system
> alone cannot express.

[`setValidity()`](https://rdrr.io/r/methods/validObject.html) lets you
encode these invariants as a function that is checked every time
[`validObject()`](https://rdrr.io/r/methods/validObject.html) is called
(and optionally on every [`new()`](https://rdrr.io/r/methods/new.html)):

``` r
setValidity("Gene", function(x) {
    errors <- character()

    # Invariant 1: strand must be one of the accepted values
    if (!x@strand %in% c("+", "-", "*")) {
        errors <- c(errors,
            paste0("strand must be '+', '-', or '*', got: '",
                   x@strand, "'"))
    }

    # Invariant 2: genomic coordinates must be positive
    if (x@start < 1L) {
        errors <- c(errors,
            paste0("start must be >= 1, got: ", x@start))
    }

    # Invariant 3: start must not exceed end
    if (x@start > x@end) {
        errors <- c(errors,
            paste0("start (", x@start, ") must be <= end (", x@end, ")"))
    }

    # Return TRUE when valid, or the error messages when invalid.
    # The S4 system will stop() with these messages automatically.
    if (length(errors) == 0) TRUE else errors
})
```

> **Key design point:** validity checks live in
> [`setValidity()`](https://rdrr.io/r/methods/validObject.html), *not*
> in the constructor. That way they fire whenever the object could be in
> an invalid state — including after programmatic slot replacement — not
> just at construction time.

------------------------------------------------------------------------

### Step 3: Generic Getters and Setters

Direct slot access with `@` works but leaks implementation details: if
you ever rename a slot, every caller breaks. **Generic functions** give
you a stable API that can evolve independently of the internal
representation:

``` r
# --- Getters ---
# setGeneric() creates a new generic if one doesn't already exist.
# The second argument is the default method body (usually just callNextMethod()
# or a forwarding call). Real dispatch happens in setMethod().

setGeneric("geneId",  function(x) standardGeneric("geneId"))
setGeneric("symbol",  function(x) standardGeneric("symbol"))
setGeneric("seqname", function(x) standardGeneric("seqname"))
setGeneric("gstart",  function(x) standardGeneric("gstart"))
setGeneric("gend",    function(x) standardGeneric("gend"))
setGeneric("strand",  function(x) standardGeneric("strand"))
setGeneric("biotype", function(x) standardGeneric("biotype"))

# setMethod() wires each generic to our Gene class.
# `x@slot_name` is how you read a slot *inside* the package;
# outsiders should use the getter, never @.
setMethod("geneId",  "Gene", function(x) x@gene_id)
setMethod("symbol",  "Gene", function(x) x@symbol)
setMethod("seqname", "Gene", function(x) x@chr)
setMethod("gstart",  "Gene", function(x) x@start)
setMethod("gend",    "Gene", function(x) x@end)
setMethod("strand",  "Gene", function(x) x@strand)
setMethod("biotype", "Gene", function(x) x@biotype)

# --- Setters ---
# The replacement generic follows the R convention: foo<-()
# `validObject()` re-runs setValidity() so invariants are enforced
# even after modification — you can't accidentally set start > end.

setGeneric("gstart<-", function(x, value) standardGeneric("gstart<-"))
setGeneric("gend<-",   function(x, value) standardGeneric("gend<-"))

setReplaceMethod("gstart", "Gene", function(x, value) {
    x@start <- as.integer(value)
    validObject(x)
    x
})

setReplaceMethod("gend", "Gene", function(x, value) {
    x@end <- as.integer(value)
    validObject(x)
    x
})
```

------------------------------------------------------------------------

### Step 4: A `show()` Method

By default, printing an S4 object dumps every slot in a hard-to-read
format. Overriding [`show()`](https://rdrr.io/r/methods/show.html) gives
users a clean summary — and it’s the method called automatically when
you type the object name at the prompt:

``` r
setMethod("show", "Gene", function(x) {
    cat("Gene:", x@symbol, "(", x@gene_id, ")\n")
    cat("  Location:", paste0("chr", x@chr, ":",
                              x@start, "-", x@end,
                              " (", x@strand, ")"), "\n")
    cat("  Biotype:", x@biotype, "\n")
    # Compute length on the fly — no need to store it as a slot
    cat("  Length:", x@end - x@start + 1L, "bp\n")
})
```

------------------------------------------------------------------------

### Step 5: A Computed Method (`length`)

Some properties are fully determined by existing slots — storing them
would create redundancy and a risk of inconsistency. Instead, define
them as methods that compute on demand:

``` r
# R already has a length() generic; we just add a method for our class.
setMethod("length", "Gene", function(x) {
    x@end - x@start + 1L
})
```

------------------------------------------------------------------------

### Full Usage Example

Putting it all together:

``` r
# Construction — types are coerced automatically
tp53 <- Gene(
    gene_id = "ENSG00000141510",
    symbol  = "TP53",
    chr     = "17",
    start   = 7661779,
    end     = 7687550,
    strand  = "-",
    biotype = "protein_coding"
)

# show() fires automatically — clean, readable output
tp53

# Getters — stable API, independent of slot names
geneId(tp53)      # "ENSG00000141510"
symbol(tp53)      # "TP53"
seqname(tp53)     # "17"
gstart(tp53)      # 7661779L
length(tp53)      # 25772L  (computed, not stored)

# Setter — validity is re-checked automatically
gend(tp53) <- 7688000
length(tp53)      # 26222L — updated correctly

# Validity catches nonsense immediately
tryCatch(
    Gene("X", "BAD", "1", start = 500, end = 100, strand = "?",
         biotype = "protein_coding"),
    error = function(e) message("Caught: ", conditionMessage(e))
)
# Caught: strand must be '+', '-', or '*', got: '?'
# (start > end would also be caught in the same call)
```

### S4 Best Practices (Design Checklist)

- Keep **slots minimal** and focused on essential fields
- Write **validity checks** for invariants (e.g., `start <= end`) via
  [`setValidity()`](https://rdrr.io/r/methods/validObject.html)
- Provide **constructor functions** so users never call
  [`new()`](https://rdrr.io/r/methods/new.html) directly
- Provide **generic getters/setters** via
  [`setGeneric()`](https://rdrr.io/r/methods/setGeneric.html) /
  [`setMethod()`](https://rdrr.io/r/methods/setMethod.html) instead of
  direct slot access (`@`)
- Call **[`validObject()`](https://rdrr.io/r/methods/validObject.html)**
  inside setters to re-enforce invariants after modification
- Override **[`show()`](https://rdrr.io/r/methods/show.html)** for a
  readable console representation
- Implement derived properties as **methods**, not stored slots
- Document **invariants** and expected slot types with roxygen2

------------------------------------------------------------------------

## On Wheel Reinvention

Based on that small example, you can see how much work goes into
building a robust data structure. Carelessly slapping together a data
structure can lead to serious headaches downstream that result in
constant reimplementations and refactors that can break backwards
compatibility (looking at you, `Seurat`).

Before embarking on such an endeavor, it is in your best interest to
determine if there are adequate already existing data structures for
your data modality and what you want to achieve.

In this case, Bioconductor already has battle-tested data structures for
many common assay types and ’omics-related elements — including
representations of genomic features (`GenomicFeatures`, `GenomicRanges`)
and general count data (`SummarizedExperiment` and domain-specific
extensions like `SingleCellExperiment`, `SpatialExperiment`). These
classes have been tested, documented, and widely adopted by the
community. They also interoperate with hundreds of downstream packages
that expect these containers.

### The “Do I Really Need to Roll My Own?” Checklist

Before you adopt or build a data structure, consider:

- **Problem fit**: Does an existing class match the sort of data you
  have?
- **Data model fit**: Can it represent the different facets of the data
  (counts, sample metadata, feature metadata) without hacks?
- **Contract clarity**: Are the accessors and invariants clear from the
  docs?
- **Interoperability**: Do downstream packages already expect this
  container?
- **Maintenance**: Is the package well documented and actively used?

Knowing how to design and build your own data structures is important,
but knowing when to reuse existing ones is just as crucial. Don’t
reinvent the wheel if a well-designed, community-supported solution
already exists.

![](https://imgs.xkcd.com/comics/standards.png)

If you *do* decide to build your own structure, design carefully, choose
an appropriate base class (S4 is not the only option), and ensure your
implementation is robust and well-documented.

------------------------------------------------------------------------

## Scientific Software Ecosystems

More often than not, you will be building on existing software
ecosystems rather than starting from scratch. This is especially true in
bioinformatics, where the complexity of the data and analyses often
necessitates building on top of established tools and data structures.

### CRAN - The Comprehensive R Archive Network

CRAN is the primary repository for general R packages. It has strict
submission guidelines to ensure quality and stability, but it is not
domain-specific. CRAN packages can be used in any context, but they may
not have the specialized data structures or methods needed for
bioinformatics. That said, many CRAN packages are widely used in
bioinformatics workflows (e.g., `ggplot2`, `dplyr`, `purrr`), and
Bioconductor packages often depend on CRAN packages for core
functionality.

Any time you install a package with
[`install.packages()`](https://rdrr.io/r/utils/install.packages.html),
you’re pulling from CRAN.

### Bioconductor - Open Source Software for Bioinformatics

[Bioconductor](https://www.bioconductor.org/) is a more specialized
repository focused on repeatable analysis of biological data.

It includes core packages that define data structures and methods for
common bioinformatics data types (e.g., `SummarizedExperiment`,
`SingleCellExperiment`, `GenomicRanges`), as well as hundreds of
downstream packages that build on these foundations to provide tools for
specific analyses (e.g., differential expression, clustering, gene set
analysis).

Bioconductor has their [own set of submission
guidelines](https://bioconductor.org/developers/package-submission/)
that emphasize interoperability, documentation, and testing. Submission
review is an interactive process performed on Github.

As you dive deeper into bioinformatics and computational biology, you’ll
find yourself becoming very familiar with Bioconductor’s core data
structures and methods, and you’ll likely be building your own tools
that operate on these objects. Understanding the design and structure of
these classes will help you write more robust and interoperable R code.

------------------------------------------------------------------------

## An Illustrative Example: SummarizedExperiment

Let’s take a look at a very common S4 class offered by Bioconductor -
[SummarizedExperiment](https://bioconductor.org/packages/devel/bioc/vignettes/SummarizedExperiment/inst/doc/SummarizedExperiment.html).

We’ll use the `airway` dataset, which contains RNA-seq data from airway
smooth muscle cells.

``` r
library(SummarizedExperiment)
library(airway)
library(ComplexHeatmap)
library(ggplot2)

data("airway")
```

### Exploring the Structure

#### What class is this object?

``` r
airway
```

`RangedSummarizedExperiment` is an extension of `SummarizedExperiment`
that also stores genomic ranges for each feature (gene).

#### The `SummarizedExperiment` Structure

Though it may at first seem complicated, the `SummarizedExperiment`
structure is elegantly intuitive once you understand the core
components. It consists of three main parts - `rowData`, `colData`, and
`assays` - that are designed to keep related information synchronized
and organized.

![](figures/image.png)

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

# Adding a new column is simple
airway$group <- paste(airway$cell, airway$dex, sep = "_")
# Equivalent to: colData(airway)$group <- paste(colData(airway)$cell, colData(airway)$dex, sep = "_")
```

#### Feature Metadata (rowData)

The
[`rowData()`](https://rdrr.io/pkg/SummarizedExperiment/man/SummarizedExperiment-class.html)
function extracts feature-level (gene) metadata:

``` r
rowData(airway)

# To add columns to rowData, it must be accessed directly rather than using `$` on
# the SummarizedExperiment object itself.
rowData(airway)$type <- ifelse(rowData(airway)$gene_id %in% c("ENSG00000141510", "ENSG00000171862"),
                                "important_gene", "other")

# Check the new column
table(rowData(airway)$type)
```

#### Assay Data (the actual values)

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

Note that a `SummarizedExperiment` can hold multiple assays (e.g., raw
counts, normalized counts, log-transformed values) in the same object,
each accessible by name.

`SingleCellExperiment` can even hold different experiments via
[`altExps()`](https://rdrr.io/pkg/SingleCellExperiment/man/altExps.html),
and other varieties offer other features, like spatial coordinates in
`SpatialExperiment`. But all of these data structures share the baseline
functionality and structure of `SummarizedExperiment`.

#### Basic Operations

Generally, you can interact with a `SummarizedExperiment` object as you
would with a typical matrix or data.frame, but it also has specialized
accessors for its components.

``` r
# Subsetting works like a matrix, but keeps everything in sync
airway_subset <- airway[1:100, 1:4]  # first 100 genes, first 4 samples

# Can see that rowData and colData are intact and subsetted accordingly
rowData(airway_subset)
colData(airway_subset)
```

#### Creating a `SummarizedExperiment` from Components

Actually creating a `SummarizedExperiment` is simple, you just need to
provide the assay matrix, sample metadata, and optionally feature
metadata. The constructor will check that everything is properly aligned
(matching row and column names) and will throw an error if not.

``` r
# Tiny example: 3 genes x 3 samples
counts_mat <- matrix(
    c(100, 200, 150,
       50,  80,  60,
      400, 350, 420),
    nrow = 3, ncol = 3,
    dimnames = list(
        c("GeneA", "GeneB", "GeneC"),
        c("S1", "S2", "S3")
    )
)

sample_meta <- data.frame(
    treatment = factor(c("ctrl", "trt", "trt")),
    row.names = c("S1", "S2", "S3")
)

# rowData is optional — omit it and SE still works fine
gene_meta <- data.frame(
    biotype = c("protein_coding", "lncRNA", "protein_coding"),
    row.names = c("GeneA", "GeneB", "GeneC")
)

se <- SummarizedExperiment(
    assays  = list(counts = counts_mat),
    colData = sample_meta,
    rowData = gene_meta   # optional
)

se
```

------------------------------------------------------------------------

## Building Functions

Now we’ll switch tack. If you haven’t already, take 5-10 minutes to
choose a project from the [Project Selection
Guide](https://st-jude-ms-abds.github.io/ADS8192/articles/project-selection.html).
Remember you cannot choose the same project as a classmate, so first
come first served.

For the rest of this unit, you’ll be building an R package around that
project.

You’ll note that each project has a “raw code” version of the analysis,
which is a single R script that performs the entire analysis from start
to finish. This is a common way to start an analysis — you just write
code that gets the job done, without worrying much about structure or
reusability.

Once the code/analysis is deemed useful, you might go back and refactor
it into a more modular, reusable form for future use or sharing with
others.

### Getting the Data

First, you’ll need data to operate on. All of the projects in the
project guide have code to pull real data for use. Some of them may
subset the data to make it easier to handle for development and testing
purposes.

There are all sorts of avenues to get data for testing and development —
from public repositories like GEO (Gene Expression Omnibus, which
contains much more than just gene expression data), to simulated data,
to data you’ve generated yourself.

For my package, I’ll use the airway dataset we used above.

### Planning Functions

Before the begin coding, it’s worth spending a few minutes to plan out
the functions you’ll want to build.

- What are the key steps in your analysis?
- Which parts of the code are most reusable?
- Which parameters should be adjustable for greatest flexibility?

Take ~10 minutes to sketch out a plan for the functions you think you
need. It’s often helpful to write out the pseudocode for each function —
what inputs it will take, what outputs it will produce, and the key
steps it will perform.

Generally, you want a function to do one or two things cleanly.
Sometimes, some complexity is necessary, but striving for simplicity is
usually a good thing. If you find yourself writing a function with 200+
lines or dozens of parameters, it’s probably a sign that you should
break it up into smaller pieces.

These projects should be in the 4-10 function range.

This doesn’t have to be perfect, it can and probably will change as you
start implementing. Having a rough plan tends to help you stay focused
and makes it easier to actually start breaking up what can be a daunting
analyis (particularly if you didn’t write it yourself).

In my case, I think I’ll need functions for the following: 1.
[`top_variable_features()`](https://st-jude-ms-abds.github.io/ADS8192/reference/top_variable_features.md):
Select the most variable genes for PCA 2.
[`run_pca()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_pca.md):
Perform PCA on the data 3.
[`pca_variance_explained()`](https://st-jude-ms-abds.github.io/ADS8192/reference/pca_variance_explained.md):
Helper function to calculate variance explained by PCs 4.
[`plot_pca()`](https://st-jude-ms-abds.github.io/ADS8192/reference/plot_pca.md):
Create a PCA scatter plot colored by sample metadata 5.
`save_results()`: Save PCA results and plots to disk

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
            ↑            ↑           ↑            
       ┌────┴────┐  ┌────┴────┐  ┌───┴─────┐
       │ R API   │  │ Shiny   │  │  CLI    │
       │ (users) │  │ (web)   │  │(scripts)│
       └─────────┘  └─────────┘  └─────────┘

#### Interface 1: R API (Lectures 5–6)

Users call your exported functions directly from R:

``` r
library(ADS8192)
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

suppressPackageStartupMessages(library(ADS8192))

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

## Session Info

``` r
sessionInfo()
```
