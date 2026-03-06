# Project Selection Guide

## Overview

For Homework 1, each student builds a complete R package that implements
a bioinformatics analysis using the **“three interfaces, one core”**
architecture taught in class:

1.  **R API** — exported functions with roxygen2 documentation
2.  **Shiny app** — interactive exploration via
    [`run_app()`](https://automatic-engine-4qp7m5e.pages.github.io/reference/run_app.md)
3.  **CLI** — command-line interface via Rapp in `exec/`

All projects share the same
[rubric](https://automatic-engine-4qp7m5e.pages.github.io/articles/HW1_Rubric.md)
(25 points) and structural requirements. What differs is the **core
analysis** and the **dataset**. Choose one of the 13 projects below, or
propose your own (see [Custom Projects](#custom-projects) at the end).

Each project uses a **different Bioconductor dataset** chosen to be
biologically appropriate for the analysis. Depending on the project,
your primary data structure will be either a **SummarizedExperiment**
(bulk experiments) or a **SingleCellExperiment** (single-cell
experiments). Your package must include:

- A constructor function
  ([`make_se()`](https://automatic-engine-4qp7m5e.pages.github.io/reference/make_se.md)
  or `make_sce()`) to build the appropriate container from raw inputs
- 3–5 additional exported analysis/visualization functions
- At least 8 testthat expectations across 2+ test files
- A pkgdown documentation site
- TSV file exports via the CLI
- A bundled example dataset in `data/` generated via a `data-raw/`
  script

------------------------------------------------------------------------

## How to Read Each Project Description

| Section                             | What it tells you                                                |
|-------------------------------------|------------------------------------------------------------------|
| **Rationale**                       | Why this analysis matters in genomics                            |
| **Dataset**                         | The Bioconductor dataset you will use, with a `data-raw/` script |
| **Data structure**                  | `SummarizedExperiment` or `SingleCellExperiment`                 |
| **What users should be able to do** | The capabilities your package must provide                       |
| **Key parameters**                  | User-facing arguments adjustable in all three interfaces         |
| **CLI outputs**                     | The TSV files your CLI subcommand must produce                   |
| **Shiny inputs**                    | What the user should be able to change interactively             |

The shared stack that every project uses: `ggplot2`, `rlang`, `shiny`,
`bslib`, `DT`, `Rapp`, `testthat`, `roxygen2`, `pkgdown`, plus either
`SummarizedExperiment` or `SingleCellExperiment` (or both).

------------------------------------------------------------------------

## Project 0: PCA Explorer (Reference Implementation)

> *This is the course example. You may NOT choose this project — it is
> provided as a reference for structure and style.*

**Package name:** ADS8192 (this repo)

**Rationale:** PCA is a very common first step in exploratory analysis
of high-dimensional data. It reduces thousands of features to a few
principal components that capture the dominant sources of variation for
the dataset.

### Dataset: Airway (Human bulk RNA-seq)

The `airway` package contains an RNA-seq experiment on human airway
smooth muscle cell lines treated with dexamethasone (a glucocorticoid).
8 samples, 4 treated and 4 untreated, with ~64,000 genes.

``` r
BiocManager::install("airway")
library(airway)
library(SummarizedExperiment)

data("airway")
```

**Data structure:** `SummarizedExperiment`

**What users should be able to do:**

- Construct a SummarizedExperiment from a counts matrix and sample
  metadata
- Select the most variable genes from the dataset
- Run PCA on filtered, optionally transformed expression data
- Summarize variance explained per principal component
- Visualize samples in PC space, colored and shaped by metadata columns
- Export PCA scores and variance summaries to TSV files

**Key parameters:** `n_top`, `log_transform`, `scale`, `color_by`,
`shape_by`

**CLI outputs:** `pca_scores.tsv`, `pca_variance.tsv`

**Shiny inputs:** Number of top genes, log-transform toggle, scale
toggle, PC axes, color/shape by metadata column, point size

------------------------------------------------------------------------

## Project 1: UMAP Embedding Explorer

**Rationale:** UMAP is a nonlinear dimensionality reduction method that
reveals biological structure — such as cell types — that PCA often
misses. It is the standard visualization in single-cell RNA-seq
analysis, and tuning its parameters (n_neighbors, min_dist) meaningfully
changes the result.

### Dataset: Zeisel Brain (Mouse scRNA-seq)

The Zeisel et al. (2015) dataset profiles 3,005 cells from the mouse
somatosensory cortex and hippocampus, classified into 7 major cell types
(interneurons, pyramidal neurons, oligodendrocytes, microglia,
astrocytes, endothelial, and mural cells). The clear cell-type structure
makes UMAP parameters visually interpretable.

``` r
## data-raw/example_sce.R
BiocManager::install("scRNAseq")
library(scRNAseq)
library(SingleCellExperiment)

sce <- ZeiselBrainData()
example_sce <- sce

# Keep only counts + key metadata
assays(example_sce) <- list(counts = counts(example_sce))
colData(example_sce) <- colData(example_sce)[, c("level1class", "level2class")]
colnames(colData(example_sce)) <- c("cell_type", "cell_subtype")

usethis::use_data(example_sce, overwrite = TRUE)
```

**Data structure:** `SingleCellExperiment`

**What users should be able to do:**

- Construct a SingleCellExperiment from a counts matrix and cell
  metadata
- Select the most variable genes for downstream analysis
- Run UMAP dimensionality reduction with configurable parameters
  (neighbors, min_dist, metric)
- Summarize the embedding (parameter values, spread statistics)
- Visualize cells in UMAP space, colored/shaped by metadata columns
- Export UMAP coordinates and parameter summaries to TSV files

**Key parameters:** `n_top`, `n_neighbors`, `min_dist`, `metric`
(euclidean/cosine), `color_by`, `shape_by`

**CLI outputs:** `umap_embeddings.tsv` (cell × UMAP1/UMAP2 + metadata),
`umap_params.tsv` (parameter values + spread stats)

**Shiny inputs:** n_top slider, n_neighbors slider (5–50), min_dist
slider (0.01–1.0), metric dropdown, color/shape by metadata

**Dependencies:** `SingleCellExperiment`, `uwot`, `scRNAseq` (data only)

------------------------------------------------------------------------

## Project 2: Sample Similarity & Clustering

**Rationale:** Before formal analysis, you must check whether samples
group by the expected biological variable (treatment, genotype) rather
than technical artifacts (batch, patient). A sample-by-sample
correlation heatmap with hierarchical clustering is the standard first
diagnostic.

### Dataset: Parathyroid Adenoma (Human bulk RNA-seq)

The `parathyroidSE` package contains RNA-seq data from 27 samples of
human parathyroid adenoma tissue: 3 patients × 3 treatments (Control,
DPN, OHT) × time points. The dual grouping by patient and treatment
creates an interesting similarity structure where both biological and
individual effects compete.

``` r
## data-raw/example_se.R
BiocManager::install("parathyroidSE")
library(parathyroidSE)
library(SummarizedExperiment)

data("parathyroidGenesSE")
se <- parathyroidGenesSE

# Subset to top 2000 genes by variance for package size
counts <- assay(se)
vars <- apply(counts, 1, var)
keep_genes <- names(sort(vars, decreasing = TRUE))[1:2000]
example_se <- se[keep_genes, ]

# Simplify colData
colData(example_se) <- colData(example_se)[, c("treatment", "patient", "time")]

usethis::use_data(example_se, overwrite = TRUE)
```

**Data structure:** `SummarizedExperiment`

**What users should be able to do:**

- Construct a SummarizedExperiment from a counts matrix and sample
  metadata
- Select the most variable genes
- Compute pairwise sample similarity (correlation or distance matrix)
- Perform hierarchical clustering, cut at a chosen k, and compute
  silhouette widths to assess cluster quality
- Visualize an annotated heatmap with dendrogram sidebars and metadata
  color bars
- Export the similarity matrix and cluster assignments to TSV files

**Key parameters:** `n_top`, `method` (pearson/spearman), `linkage`
(ward.D2/complete/average), `k`

**CLI outputs:** `similarity_matrix.tsv`, `cluster_assignments.tsv`

**Shiny inputs:** Correlation method, linkage method, k slider, n_top
slider, metadata columns for annotation bars

**Dependencies:** `SummarizedExperiment`, `parathyroidSE` (data only)

------------------------------------------------------------------------

## Project 3: Differential Expression Explorer

**Rationale:** The central question in most gene expression experiments:
which genes change between conditions? Per-gene statistical testing with
fold-change estimation, followed by volcano and MA plot visualization,
is the foundational analysis in transcriptomics.

### Dataset: Bottomly (Mouse bulk RNA-seq)

The Bottomly et al. (2011) dataset contains bulk RNA-seq data from two
inbred mouse strains — C57BL/6J and DBA/2J — with 10 and 11 biological
replicates respectively (21 samples total). These two strains have
well-characterized gene expression differences, making this a clean,
real-world dataset for demonstrating per-gene differential expression
testing. The balanced design and moderate sample size are ideal for both
t-test and Wilcoxon approaches. Available via `recount3` (project
SRP001540).

``` r
## data-raw/example_se.R
BiocManager::install("recount3")
library(recount3)
library(SummarizedExperiment)

# Access the Bottomly et al. dataset via recount3
human_projects <- available_projects()
proj <- subset(human_projects, file_source == "sra" &
                 project == "SRP001540")
rse <- create_rse(proj)

# Transform raw counts
assay(rse, "counts") <- transform_counts(rse)

# Simplify colData - extract strain from attributes
example_se <- rse
cd <- colData(example_se)
strain <- ifelse(grepl("C57BL/6J", cd$sra.sample_attributes),
                 "C57BL_6J", "DBA_2J")
colData(example_se) <- DataFrame(
  sample_id = colnames(example_se),
  strain = factor(strain)
)

usethis::use_data(example_se, overwrite = TRUE)
```

**Data structure:** `SummarizedExperiment`

**What users should be able to do:**

- Construct a SummarizedExperiment from a counts matrix and sample
  metadata
- Filter out genes with low expression across samples
- Run per-gene statistical testing (t-test or Wilcoxon) between two
  groups, computing log2 fold changes, p-values, and BH-adjusted
  p-values
- Summarize the number of significantly up/down/non-significant genes at
  given thresholds
- Visualize results as a volcano plot (log2FC vs. −log10 p) or MA plot
  (average expression vs. log2FC), with significant genes highlighted
- Export differential expression results and summary counts to TSV files

**Key parameters:** `group_column`, `ref_level`, `fc_threshold`,
`p_threshold`, `test_method` (t.test/wilcox), `plot_type` (volcano/ma)

**CLI outputs:** `de_results.tsv`, `de_summary.tsv`

**Shiny inputs:** Grouping column, reference level, FC threshold slider,
p-value threshold slider, test method toggle, volcano ↔︎ MA radio button

**Dependencies:** `SummarizedExperiment`, `recount3` (data only)

------------------------------------------------------------------------

## Project 4: K-means Cell Clustering

**Rationale:** K-means clustering partitions cells into k groups by
minimizing within-cluster variance. Choosing k is a real practical
decision — the elbow plot of within-cluster sum of squares is the
standard diagnostic. Single-cell data with many unlabeled cell types is
the natural application.

### Dataset: Baron Human Pancreas (scRNA-seq)

The Baron et al. (2016) dataset profiles ~8,500 cells from human
pancreatic islets, capturing 14 cell types including alpha, beta, delta,
gamma, acinar, and ductal cells. Students must discover the “right”
number of clusters from data alone — the elbow and silhouette
diagnostics should suggest k ≈ 8–14, matching the known biology.

``` r
## data-raw/example_sce.R
BiocManager::install("scRNAseq")
library(scRNAseq)
library(SingleCellExperiment)

sce <- BaronPancreasData("human")
example_sce <- sce

assays(example_sce) <- list(counts = counts(example_sce))
colData(example_sce) <- colData(example_sce)[, "label", drop = FALSE]
colnames(colData(example_sce)) <- "cell_type"

usethis::use_data(example_sce, overwrite = TRUE)
```

**Data structure:** `SingleCellExperiment`

**What users should be able to do:**

- Construct a SingleCellExperiment from a counts matrix and cell
  metadata
- Select the most variable genes
- Run k-means clustering across a range of k values (2..max_k)
- Compute clustering quality metrics (total within-cluster sum of
  squares, average silhouette width) for each k
- Visualize clusters on a PCA projection, colored by cluster assignment
- Generate an elbow plot (WSS vs. k) for choosing the optimal number of
  clusters
- Export cluster assignments and quality metrics to TSV files

**Key parameters:** `n_top`, `max_k`, `n_starts`, `selected_k`

**CLI outputs:** `cluster_assignments.tsv`, `kmeans_metrics.tsv`

**Shiny inputs:** n_top slider, max_k slider, selected k slider, toggle
between elbow plot and cluster scatter, color by cluster or cell_type
metadata

**Dependencies:** `SingleCellExperiment`, `cluster`, `scRNAseq` (data
only)

------------------------------------------------------------------------

## Project 5: Cell QC Dashboard

**Rationale:** Quality control is the essential first step in
single-cell analysis. Before any biological interpretation, low-quality
cells — those with too few detected genes, low library sizes, or high
spike-in proportions — must be identified and flagged. ERCC spike-in
controls provide a ground-truth reference for QC.

### Dataset: Lun Spike-In (Mouse scRNA-seq)

The Lun et al. (2017) dataset contains 192 mouse cells with ERCC
spike-in controls. It was specifically designed for benchmarking
normalization and QC methods. The spike-in proportions and library size
variation create natural QC outliers that students must detect.

``` r
## data-raw/example_sce.R
BiocManager::install("scRNAseq")
library(scRNAseq)
library(SingleCellExperiment)

sce <- LunSpikeInData()
example_sce <- sce

# Mark ERCC spike-ins in rowData
is_spike <- grepl("^ERCC-", rownames(example_sce))
rowData(example_sce)$is_spike <- is_spike

# Keep key metadata
colData(example_sce) <- colData(example_sce)[, c("cell_line", "plate")]

usethis::use_data(example_sce, overwrite = TRUE)
```

**Data structure:** `SingleCellExperiment`

**What users should be able to do:**

- Construct a SingleCellExperiment from a counts matrix and cell
  metadata
- Compute per-cell QC metrics: library size, number of genes detected,
  spike-in percentage, and Shannon entropy
- Flag outlier cells using MAD-based thresholds on QC metrics
- Visualize QC results in a multi-panel display: library size
  distribution, genes vs. library size scatter, spike-in percentage
  histogram, with outliers highlighted
- Export QC metrics and pass/fail flags to TSV files

**Key parameters:** `mad_threshold`, `min_genes`, `min_library_size`,
`max_spike_pct`

**CLI outputs:** `qc_metrics.tsv`, `qc_flags.tsv`

**Shiny inputs:** MAD threshold slider, minimum genes input, max
spike-in % slider; panels update to reflect pass/fail counts

**Dependencies:** `SingleCellExperiment`, `scRNAseq` (data only)

------------------------------------------------------------------------

## Project 6: Gene Variance Analysis

**Rationale:** Identifying highly variable genes (HVGs) is the critical
feature selection step before dimensionality reduction and clustering.
The mean-variance relationship in count data is non-trivial — high-mean
genes have high variance by default. Understanding and visualizing this
relationship teaches students why naive variance ranking is misleading
and why methods like the loess trend correction exist.

### Dataset: Macosko Retina (Mouse scRNA-seq)

The Macosko et al. (2015) Drop-seq dataset profiles ~44,000 cells from
the mouse retina, spanning ~40 cell clusters including rods, cones,
bipolar cells, amacrine cells, and ganglion cells. The enormous
cell-type diversity means HVG selection critically determines which
downstream structure is recovered — making this the ideal dataset for
exploring variance-based feature selection.

``` r
## data-raw/example_sce.R
BiocManager::install("scRNAseq")
library(scRNAseq)
library(SingleCellExperiment)

sce <- MacoskoRetinaData()
set.seed(42)
# Subsample to 10000 cells for package size (full dataset has ~44k cells)
keep_cells <- sample(ncol(sce), 10000)
example_sce <- sce[, keep_cells]

assays(example_sce) <- list(counts = counts(example_sce))
# Cluster labels from the original paper
colData(example_sce) <- colData(example_sce)[, "cluster", drop = FALSE]

usethis::use_data(example_sce, overwrite = TRUE)
```

**Data structure:** `SingleCellExperiment`

**What users should be able to do:**

- Construct a SingleCellExperiment from a counts matrix and cell
  metadata
- Filter out genes below a minimum mean expression threshold
- Compute per-gene statistics: mean, variance, coefficient of variation,
  and dispersion, with ranking
- Summarize the number of highly variable genes at different thresholds
  and fit a mean-variance trend
- Visualize the mean-variance relationship as a scatter plot with a
  loess trend line, highlighting selected HVGs
- Export gene statistics and the HVG list to TSV files

**Key parameters:** `min_mean`, `variance_threshold`, `n_top_genes`

**CLI outputs:** `gene_statistics.tsv`, `hvg_list.tsv`

**Shiny inputs:** Minimum mean slider, variance threshold or n_top
input, scatter with interactive HVG highlighting, linked gene table

**Dependencies:** `SingleCellExperiment`, `scRNAseq` (data only)

------------------------------------------------------------------------

## Project 7: Gene Set Scoring

**Rationale:** Rather than analyzing genes individually, biologists
often ask whether a predefined *set* of genes (a pathway, signature) is
collectively up- or down-regulated. Per-sample gene set scores reduce a
pathway to a single number per sample, enabling group comparisons. This
project combines expression data with external pathway knowledge from
MSigDB.

### Dataset: TCGA BRCA (Human bulk RNA-seq) + MSigDB Hallmark Gene Sets

The `curatedTCGAData` package provides access to The Cancer Genome Atlas
data. The BRCA (breast cancer) cohort includes RNA-seq expression data
from ~1,200 patients with rich clinical annotations (ER/PR/HER2 status,
PAM50 subtype, stage). Immune and proliferation-related gene sets from
MSigDB clearly distinguish molecular subtypes — making pathway-level
scoring biologically compelling. We subset to a manageable number of
samples for the example data.

``` r
## data-raw/example_se.R
BiocManager::install(c("curatedTCGAData", "TCGAutils"))
install.packages("msigdbr")
library(curatedTCGAData)
library(TCGAutils)
library(SummarizedExperiment)

# Download BRCA RNA-seq data
brca <- curatedTCGAData("BRCA", "RNASeq2*", version = "2.0.1",
                         dry.run = FALSE)
rse <- experiments(brca)[[1]]

# Subset to 200 samples for package size
set.seed(42)
keep_samples <- sample(ncol(rse), 200)
rse <- rse[, keep_samples]

# Subset to top 5000 variable genes
vars <- apply(assay(rse), 1, var, na.rm = TRUE)
keep_genes <- names(sort(vars, decreasing = TRUE))[1:5000]
rse <- rse[keep_genes, ]

# Get clinical data
clin <- colData(brca)
clin <- clin[colnames(rse), ]

example_se <- SummarizedExperiment(
  assays = list(exprs = assay(rse)),
  colData = DataFrame(
    sample_id   = colnames(rse),
    er_status   = clin$pathologic_stage,
    pam50       = clin$subtype_PAM50.mRNA
  )
)

# Bundle a small set of hallmark gene sets
library(msigdbr)
hallmarks <- msigdbr(species = "Homo sapiens", category = "H")
example_gene_sets <- split(hallmarks$gene_symbol, hallmarks$gs_name)
# Keep 10 immune/proliferation-relevant sets
keep_sets <- c(
  "HALLMARK_IL2_STAT5_SIGNALING", "HALLMARK_INFLAMMATORY_RESPONSE",
  "HALLMARK_INTERFERON_GAMMA_RESPONSE", "HALLMARK_ALLOGRAFT_REJECTION",
  "HALLMARK_MYC_TARGETS_V1", "HALLMARK_E2F_TARGETS",
  "HALLMARK_TNFA_SIGNALING_VIA_NFKB", "HALLMARK_APOPTOSIS",
  "HALLMARK_P53_PATHWAY", "HALLMARK_COMPLEMENT"
)
example_gene_sets <- example_gene_sets[keep_sets]

usethis::use_data(example_se, example_gene_sets, overwrite = TRUE)
```

**Data structure:** `SummarizedExperiment`

**What users should be able to do:**

- Construct a SummarizedExperiment from an expression matrix and sample
  metadata
- Read gene sets from a GMT file or named list of character vectors
- Compute per-sample gene set scores (e.g., mean z-score of set members)
- Summarize mean scores per group and compute effect sizes between
  conditions
- Visualize gene set scores as boxplots or violin plots, grouped by a
  clinical variable and faceted by gene set
- Export per-sample scores and group summaries to TSV files

**Key parameters:** `gene_sets` (list or GMT path), `score_method`
(mean_z, median_z), `group_column`

**CLI outputs:** `geneset_scores.tsv`, `scoring_summary.tsv`

**Shiny inputs:** Select built-in sets or upload GMT, score method
dropdown, grouping variable dropdown (ER status, PAM50 subtype), gene
set selector, boxplot ↔︎ violin toggle

**Dependencies:** `SummarizedExperiment`, `curatedTCGAData` (data only),
`msigdbr` (gene sets)

------------------------------------------------------------------------

## Project 8: Normalization Comparison Tool

**Rationale:** Raw counts must be normalized before cross-sample
comparison. Different methods (CPM, log2-CPM, quantile, upper-quartile)
make different assumptions. Visualizing how each method reshapes
per-sample distributions teaches students why normalization matters —
and why the “right” method depends on the data.

### Dataset: Muraro Human Pancreas (Human scRNA-seq)

The Muraro et al. (2016) dataset from `scRNAseq` profiles ~2,300 cells
from human donor pancreatic islets using CEL-Seq2. Cell types include
alpha, beta, delta, acinar, ductal, and more. The dramatic library size
variation across cells (typical of scRNA-seq) makes normalization
effects visually striking — CPM, log2-CPM, and quantile normalization
reshape per-cell distributions in very different ways.

``` r
## data-raw/example_sce.R
BiocManager::install("scRNAseq")
library(scRNAseq)
library(SingleCellExperiment)

sce <- MuraroPancreasData()
example_sce <- sce

assays(example_sce) <- list(counts = counts(example_sce))
colData(example_sce) <- colData(example_sce)[, "label", drop = FALSE]
colnames(colData(example_sce)) <- "cell_type"

usethis::use_data(example_sce, overwrite = TRUE)
```

**Data structure:** `SingleCellExperiment`

**What users should be able to do:**

- Construct a SingleCellExperiment from a counts matrix and cell
  metadata
- Filter out low-expression genes
- Apply multiple normalization methods (CPM, log2-CPM, quantile) and
  store the normalized values as new assays in the SCE
- Compute per-cell distributional statistics (median, IQR, CV) before
  and after each normalization method
- Visualize side-by-side distributions across methods as boxplots or
  density curves
- Export normalized counts and normalization statistics to TSV files

**Key parameters:** `methods` (character vector: “cpm”, “log2”,
“quantile”), `min_count`

**CLI outputs:** `normalized_counts.tsv`, `normalization_stats.tsv`

**Shiny inputs:** Checkbox group to select methods, boxplot ↔︎ density
toggle, per-cell or per-method view

**Dependencies:** `SingleCellExperiment`, `scRNAseq` (data only)

------------------------------------------------------------------------

## Project 9: Gene Correlation Network

**Rationale:** Co-expressed genes often share biological functions.
Building a gene-gene correlation network — computing pairwise
correlations, thresholding to an adjacency matrix, and identifying hub
genes — is a lightweight introduction to network biology. Cohorts with
many samples provide stable pairwise gene correlations that reveal known
co-regulation patterns.

### Dataset: GTEx Skeletal Muscle (Human bulk RNA-seq)

The `recount3` package provides access to the GTEx (Genotype-Tissue
Expression) project. The skeletal muscle tissue has one of the largest
sample sizes in GTEx (~800 samples), providing highly stable gene-gene
correlations. Known co-expression modules — such as mitochondrial
respiration genes, sarcomere components, and extracellular matrix genes
— are recoverable, making this a biologically rich dataset for network
analysis.

``` r
## data-raw/example_se.R
BiocManager::install("recount3")
library(recount3)
library(SummarizedExperiment)

# Access GTEx skeletal muscle data
human_projects <- available_projects()
proj <- subset(human_projects, file_source == "gtex" &
                 project == "MUSCLE")
rse <- create_rse(proj)

# Transform raw counts
assay(rse, "counts") <- transform_counts(rse)

# Subset to top 2000 genes by variance for tractable network computation
vars <- apply(assay(rse, "counts"), 1, var)
keep_genes <- names(sort(vars, decreasing = TRUE))[1:2000]

# Subset to 200 samples for package size
set.seed(42)
keep_samples <- sample(ncol(rse), min(200, ncol(rse)))

example_se <- rse[keep_genes, keep_samples]
assays(example_se) <- list(counts = assay(example_se, "counts"))
colData(example_se) <- colData(example_se)[, c("gtex.age", "gtex.sex"),
                                            drop = FALSE]

usethis::use_data(example_se, overwrite = TRUE)
```

**Data structure:** `SummarizedExperiment`

**What users should be able to do:**

- Construct a SummarizedExperiment from a counts matrix and sample
  metadata
- Select the most variable genes for network construction
- Compute a pairwise gene-gene correlation matrix
- Threshold the correlation matrix into a binary adjacency matrix and
  compute per-gene network statistics (degree, betweenness centrality)
- Summarize the network: total edge count, mean degree, hub genes above
  a connectivity threshold
- Visualize the network as a correlation heatmap with gene clustering,
  or as a force-directed layout
- Export correlations, network summary, and hub gene lists to TSV files

**Key parameters:** `n_top`, `cor_method` (pearson/spearman),
`cor_threshold`

**CLI outputs:** `gene_correlations.tsv`, `network_summary.tsv`,
`hub_genes.tsv`

**Shiny inputs:** Correlation threshold slider, method dropdown, n_top
slider, hub gene table, heatmap redraws on threshold change

**Dependencies:** `SummarizedExperiment`, `igraph` (Suggests, for
force-directed layout), `recount3` (data only)

------------------------------------------------------------------------

## Project 10: Expression Heatmap Builder

**Rationale:** The genes-by-samples heatmap is one of the most iconic
figures in genomics. Building one from scratch — row scaling,
hierarchical clustering of both axes, clinical annotation bars —
requires integrating several analysis steps into a single
publication-quality visualization.

### Dataset: TCGA GBM (Human bulk RNA-seq)

The `curatedTCGAData` package provides RNA-seq expression data from The
Cancer Genome Atlas. The GBM (glioblastoma multiforme) cohort includes
~170 patients with rich clinical annotations: transcriptional subtype
(Classical, Mesenchymal, Proneural, Neural), IDH mutation status, MGMT
methylation, age, and survival. The multiple clinical variables make
ideal column annotation bars, and the known molecular subtypes produce
distinctive gene module patterns in unsupervised clustering.

``` r
## data-raw/example_se.R
BiocManager::install(c("curatedTCGAData", "TCGAutils"))
library(curatedTCGAData)
library(TCGAutils)
library(SummarizedExperiment)

# Download GBM RNA-seq data
gbm <- curatedTCGAData("GBM", "RNASeq2*", version = "2.0.1",
                        dry.run = FALSE)
rse <- experiments(gbm)[[1]]

# Subset to top 2000 variable genes
vars <- apply(assay(rse), 1, var, na.rm = TRUE)
keep_genes <- names(sort(vars, decreasing = TRUE))[1:2000]
rse <- rse[keep_genes, ]

# Get clinical data
clin <- colData(gbm)

example_se <- SummarizedExperiment(
  assays = list(exprs = assay(rse)),
  colData = DataFrame(
    sample_id = colnames(rse),
    subtype   = clin[colnames(rse), "subtype_Transcriptome.Subtype"],
    age       = clin[colnames(rse), "years_to_birth"]
  )
)

usethis::use_data(example_se, overwrite = TRUE)
```

**Data structure:** `SummarizedExperiment`

**What users should be able to do:**

- Construct a SummarizedExperiment from an expression matrix and sample
  metadata
- Select the most variable genes
- Row-scale the expression matrix (z-score or min-max normalization)
- Perform hierarchical clustering on rows (genes) and cut at k to assign
  gene modules
- Generate a genes × samples heatmap with row dendrogram, column
  annotation bars from clinical metadata, and a gene module color strip
- Export the scaled expression matrix and gene module assignments to TSV
  files

**Key parameters:** `n_top`, `scale_method` (zscore/minmax/none),
`gene_k`, `column_split_by` (metadata column)

**CLI outputs:** `scaled_expression.tsv`, `gene_modules.tsv`

**Shiny inputs:** n_top slider, scale method dropdown, gene_k slider,
metadata column selector for annotation, heatmap updates reactively

**Dependencies:** `SummarizedExperiment`, `ComplexHeatmap` (Suggests),
`curatedTCGAData` (data only)

------------------------------------------------------------------------

## Project 11: Dimensionality Estimation Tool

**Rationale:** “How many principal components should I keep?” is a
fundamental question in single-cell workflows (the Seurat `ElbowPlot`
step). The broken-stick model, Kaiser criterion, and elbow heuristic
each encode different assumptions. Building tools to compare them
teaches critical thinking about method selection.

### Dataset: PBMC 3k (Human scRNA-seq)

The 10X Genomics PBMC 3k dataset (~2,700 peripheral blood mononuclear
cells) is the canonical Seurat tutorial dataset. It contains ~10 immune
cell types (T cells, B cells, NK cells, monocytes, dendritic cells), and
the “right” number of PCs is actively debated: Seurat defaults to 20,
but the intrinsic dimensionality for ~10 cell types may be closer to
10–15. This makes the estimation question genuinely interesting.

``` r
## data-raw/example_sce.R
BiocManager::install("TENxPBMCData")
library(TENxPBMCData)
library(SingleCellExperiment)

sce <- TENxPBMCData("pbmc3k")
example_sce <- sce

# Minimal colData — no pre-computed labels; that's fine for dim estimation
colData(example_sce) <- colData(example_sce)[, "Barcode", drop = FALSE]

usethis::use_data(example_sce, overwrite = TRUE)
```

**Data structure:** `SingleCellExperiment`

**What users should be able to do:**

- Construct a SingleCellExperiment from a counts matrix and cell
  metadata
- Select the most variable genes
- Run PCA and extract eigenvalues (variance per component, cumulative
  variance)
- Apply multiple dimensionality estimation methods (broken-stick model,
  Kaiser criterion, elbow heuristic) and report recommended number of
  components from each
- Visualize a scree plot with overlays for each estimation method
  (broken-stick curve, Kaiser line, elbow annotation)
- Export eigenvalue tables and dimensionality estimates to TSV files

**Key parameters:** `n_top`, `methods` (broken_stick/kaiser/elbow),
`max_pcs`

**CLI outputs:** `eigenvalues.tsv`, `dimension_estimates.tsv`

**Shiny inputs:** n_top slider, checkboxes to toggle overlay of each
method, max_pcs slider, summary table of recommendations

**Dependencies:** `SingleCellExperiment`, `TENxPBMCData` (data only)

------------------------------------------------------------------------

## Project 12: Batch Effect Assessment

**Rationale:** Batch effects — systematic technical variation from
processing date, lane, or operator — can dominate biological signal.
Quantifying how much variance each PC attributes to batch (via linear
regression R²) is the standard diagnostic before deciding whether
correction is needed.

### Dataset: Grun Human Pancreas (Human scRNA-seq)

The `scRNAseq` package provides the Grun et al. (2016) dataset: ~1,700
human pancreatic cells profiled across multiple donors using CEL-Seq.
The combination of donor (batch) and cell type (biology) creates a
realistic scenario where students must distinguish technical from
biological variation in PCA space. PCA colored by donor vs. cell type
reveals the batch effect immediately.

``` r
## data-raw/example_sce.R
BiocManager::install("scRNAseq")
library(scRNAseq)
library(SingleCellExperiment)

sce <- GrunPancreasData()
example_sce <- sce

assays(example_sce) <- list(counts = counts(example_sce))
colData(example_sce) <- colData(example_sce)[, c("donor", "sample")]
colnames(colData(example_sce)) <- c("batch", "cell_type")

usethis::use_data(example_sce, overwrite = TRUE)
```

**Data structure:** `SingleCellExperiment`

**What users should be able to do:**

- Construct a SingleCellExperiment from a counts matrix and cell
  metadata
- Select the most variable genes
- Quantify batch effects by fitting a linear model of each PC against
  the batch variable and extracting R² values
- Apply a simple batch correction (e.g., median-centering per batch) and
  return a corrected object
- Visualize dual-panel PCA plots (before and after correction) colored
  by batch, plus an R² bar chart showing the proportion of variance
  attributable to batch per PC
- Export batch variance quantification and corrected counts to TSV files

**Key parameters:** `batch_column`, `n_top`, `correct` (logical),
`bio_column`

**CLI outputs:** `batch_variance.tsv`, `corrected_counts.tsv`

**Shiny inputs:** Batch column dropdown, biological column dropdown,
n_top slider, correction toggle, before/after PCA panels, R² bar chart

**Dependencies:** `SingleCellExperiment`, `scRNAseq` (data only)

------------------------------------------------------------------------

## Project 13: Marker Gene Identification

**Rationale:** When cells fall into distinct types, identifying the
genes that best distinguish each type from the rest is fundamental — it
is the core of cell-type annotation. One-vs-rest testing produces ranked
marker lists; the dot plot (size = detection rate, color = mean
expression) is the standard single-cell visualization.

### Dataset: Baron Mouse Pancreas (Mouse scRNA-seq)

The Baron et al. (2016) mouse pancreatic islet dataset contains ~1,886
cells across 9 clearly defined cell types: alpha, beta, delta, gamma
(PP), acinar, ductal, stellate (activated and quiescent), immune, and
Schwann cells. Each cell type has well-known marker genes (e.g.,
*Ins1*/*Ins2* for beta cells, *Gcg* for alpha cells), enabling students
to validate their markers against published biology. Note: this is the
**mouse** version — Project 4 uses the human dataset from the same
study, so code cannot be directly shared.

``` r
## data-raw/example_sce.R
BiocManager::install("scRNAseq")
library(scRNAseq)
library(SingleCellExperiment)

sce <- BaronPancreasData("mouse")
example_sce <- sce

assays(example_sce) <- list(counts = counts(example_sce))
colData(example_sce) <- colData(example_sce)[, "label", drop = FALSE]
colnames(colData(example_sce)) <- "cell_type"

usethis::use_data(example_sce, overwrite = TRUE)
```

**Data structure:** `SingleCellExperiment`

**What users should be able to do:**

- Construct a SingleCellExperiment from a counts matrix and cell
  metadata
- Filter out low-expression genes
- Perform one-vs-rest statistical testing per cell type: compute log2
  fold changes, Wilcoxon p-values, BH-adjusted p-values, and rank genes
  per group
- Summarize the top N markers per group and compute overlap counts
  between groups
- Visualize markers as a dot plot: genes on y-axis, groups on x-axis,
  dot size encodes detection rate, dot color encodes mean expression
- Export marker gene lists and summaries to TSV files

**Key parameters:** `group_column`, `n_markers`, `fc_threshold`,
`detection_threshold`

**CLI outputs:** `marker_genes.tsv`, `marker_summary.tsv`

**Shiny inputs:** Grouping variable dropdown, n_markers slider, FC
threshold slider, detection threshold slider, dot plot + filterable gene
table

**Dependencies:** `SingleCellExperiment`, `scRNAseq` (data only)

------------------------------------------------------------------------

## Quick Comparison

| \#  | Project                 | Dataset                  | Organism | Structure | Primary Plot            | Extra Deps                      |
|-----|-------------------------|--------------------------|----------|-----------|-------------------------|---------------------------------|
| 1   | UMAP Embedding          | Zeisel brain             | Mouse    | SCE       | 2D scatter              | uwot                            |
| 2   | Sample Similarity       | Parathyroid adenoma      | Human    | SE        | heatmap + dendrogram    | —                               |
| 3   | Differential Expression | Bottomly (mouse strains) | Mouse    | SE        | volcano / MA            | —                               |
| 4   | K-means Clustering      | Baron human pancreas     | Human    | SCE       | scatter + elbow         | cluster                         |
| 5   | Cell QC Dashboard       | Lun spike-in             | Mouse    | SCE       | multi-panel             | —                               |
| 6   | Gene Variance           | Macosko retina           | Mouse    | SCE       | mean-variance scatter   | —                               |
| 7   | Gene Set Scoring        | TCGA BRCA + MSigDB       | Human    | SE        | boxplot / violin        | msigdbr, curatedTCGAData        |
| 8   | Normalization           | Muraro pancreas          | Human    | SCE       | density / boxplot       | —                               |
| 9   | Gene Corr Network       | GTEx skeletal muscle     | Human    | SE        | network / heatmap       | igraph (opt.), recount3         |
| 10  | Expression Heatmap      | TCGA GBM                 | Human    | SE        | genes × samples heatmap | ComplexHeatmap, curatedTCGAData |
| 11  | Dim Estimation          | PBMC 3k                  | Human    | SCE       | scree + overlays        | —                               |
| 12  | Batch Effect            | Grun human pancreas      | Human    | SCE       | before/after PCA + R²   | —                               |
| 13  | Marker Genes            | Baron mouse pancreas     | Mouse    | SCE       | dot plot                | —                               |

- **13 unique datasets** — all **human or mouse**, all **RNA-seq or
  scRNA-seq**
- **8 single-cell** (SCE) + **5 bulk** (SE) projects
- No two projects share both the same computation **and** visualization

------------------------------------------------------------------------

## Shared Requirements (All Projects)

Regardless of which project you choose, your package must satisfy
**all** of the following. These map directly to the [HW1
rubric](https://automatic-engine-4qp7m5e.pages.github.io/articles/HW1_Rubric.md)
(25 points).

### Package Structure (4 pts)

- Valid `DESCRIPTION` with Imports/Suggests correctly declared
- `NAMESPACE` generated by roxygen2
- Installs from GitHub via `remotes::install_github()`
- Includes bundled example data in `data/` loadable via
  [`data()`](https://rdrr.io/r/utils/data.html)
- `data-raw/` script that reproducibly generates the example data

### Core Functions (5 pts)

- [`make_se()`](https://automatic-engine-4qp7m5e.pages.github.io/reference/make_se.md)
  or `make_sce()` that constructs the appropriate container from a
  counts/expression matrix + metadata data.frame
- 3–4 additional exported functions for your specific analysis
- 1 plotting function returning a `ggplot` object
- All functions accept SE or SCE input and return well-defined types
- Input validation with informative
  [`stop()`](https://rdrr.io/r/base/stop.html) and/or
  [`warning()`](https://rdrr.io/r/base/warning.html) messages

### Testing (4 pts)

- testthat edition 3 infrastructure
- ≥ 8 expectations across ≥ 2 test files
- Both happy-path and error-case tests
- `devtools::test()` passes with 0 failures

### Documentation (4 pts)

- roxygen2 docs for all exports (`@param`, `@return`, `@export`,
  `@examples`)
- README with install instructions + quick-start example
- pkgdown site builds without error
- At least one vignette or article

### Shiny App (5 pts)

- [`run_app()`](https://automatic-engine-4qp7m5e.pages.github.io/reference/run_app.md)
  launches from a clean session
- Calls your package core functions (no copy-pasted analysis logic)
- ≥ 2 user-adjustable inputs that reactively update output
- Input validation with user-friendly messages (no red console errors)
- Deployed on Posit Connect

### CLI (3 pts)

- Rapp entry point in `exec/`
- `--help` displays usage
- Produces TSV output files by calling your core functions

------------------------------------------------------------------------

## Custom Projects

You are welcome to propose your own project of similar scope. To be
approved, your proposal must include:

1.  **One paragraph** describing the biological or analytical rationale
2.  **A Bioconductor dataset** with a `data-raw/` script showing how to
    prepare the example data
3.  **A capability list** describing what users should be able to do
    with the package (4–6 bullet points)
4.  **At least one non-trivial visualization** (not just a base R
    [`plot()`](https://rdrr.io/r/graphics/plot.default.html) call)
5.  **CLI outputs** — what TSV files will be produced?
6.  **Shiny inputs** — what will the user be able to adjust?

Submit your proposal as a GitHub Issue or by email **before starting
implementation**. The instructor will respond within 48 hours with
approval or suggested modifications.

**Ground rules for custom projects:**

- Must operate on `SummarizedExperiment` or `SingleCellExperiment` input
- Must include a constructor function as the entry point
- Must use a real human or mouse Bioconductor dataset (not simulated
  data); RNA-seq or scRNA-seq preferred (avoid microarray datasets)
- Must produce at least one `ggplot`-based visualization
- Must not duplicate an existing project from the list above
- Scope should be comparable — roughly 4–6 exported functions, not a
  full pipeline with 15 steps
