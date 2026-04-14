# Project Selection Guide

## Overview

For Homework 1, each student will create an R package derived from a raw
analysis script. The package must provide the same core analysis and
outputs as the raw script, but in a more modular, reusable form.

Students will offer three interfaces to the same core functionality from
the package:

1.  **R API** — exported functions with roxygen2 documentation
2.  **Shiny app** — interactive analysis/visualization
3.  **CLI** — command-line interface via
    [Rapp](https://github.com/r-lib/Rapp)

All projects share the same
[rubric](https://st-jude-ms-abds.github.io/ADS8192/articles/HW1_Rubric.html)
(25 points) and structural requirements. What differs is the **core
analysis** and the **dataset**. Choose one of the 12 projects below, or
propose your own (see [Custom Projects](#custom-projects) at the end).

Each project uses a **different dataset** chosen to be at least somewhat
appropriate for the analysis.

The analysis is secondary here, though you might be interested in
reading more about them. Some of the single cell projects may take a few
minutes to run, as they may contain thousands of cells.

Depending on the project, your primary data structure will be either a
**SummarizedExperiment** (bulk experiments) or a
**SingleCellExperiment** (single-cell experiments).

Generally, your package will at minimum contain:

- A valid R package, installable from Github, with properly documented
  functions, example data, and tests
- A Shiny app that allows users to interactively explore/analyze/plot
  the data and results
- A CLI that runs the analysis end-to-end with adjustable parameters and
  writes results to disk
- A documentation website with a brief vignette describing how to use
  the package

See the [grading
rubric](https://st-jude-ms-abds.github.io/ADS8192/articles/HW1_Rubric.html)
for exact requirements.

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

If you see function calls you aren’t familiar with in the raw code
blocks, looking them on in R is your friend, e.g. `?prcomcp`.

------------------------------------------------------------------------

## Project 0: PCA Explorer (Reference Implementation)

> *This is the course example.* You may *NOT* choose this project — it
> is provided as a reference for structure and style. The lectures will
> demonstrate the process of this project being converted into a full R
> package with a Shiny app and CLI, documentation, and tests.

**Rationale:** PCA is a very common first step in exploratory analysis
of high-dimensional data. It reduces thousands of features to a few
principal components that capture the dominant sources of variation for
the dataset.

### Dataset: Simulated RNA-seq

The `example_se` dataset contains a simulated RNA-seq experiment with 8
samples, 4 treated and 4 untreated, with 10,000 genes. The first 200
genes have a strong treatment effect, while the rest are noise. This
structure should be clearly visible in the PCA plot, with treated and
untreated samples separating along PC1.

Data preparation code

``` r
set.seed(42)

# 10000 genes, 8 samples
n_genes <- 10000
n_samples <- 8

# Simulate counts (negative binomial-ish)
counts <- matrix(
  rpois(n_genes * n_samples, lambda = 100),
  nrow = n_genes,
  ncol = n_samples
)
rownames(counts) <- paste0("gene", seq_len(n_genes))
colnames(counts) <- paste0("sample", seq_len(n_samples))

# Add some structure: first 500 genes differ by treatment
treatment <- rep(c("control", "treated"), each = 4)
counts[1:500, treatment == "treated"] <- counts[1:500, treatment == "treated"] * 2

# Sample metadata
sample_data <- data.frame(
  sample_id = colnames(counts),
  treatment = treatment,
  batch = rep(c("A", "B"), times = 4),
  row.names = colnames(counts)
)

# Gene metadata
gene_data <- data.frame(
  gene_id = rownames(counts),
  gene_symbol = paste0("SYM", seq_len(n_genes)),
  row.names = rownames(counts)
)

# Create SummarizedExperiment
example_se <- SummarizedExperiment(
  assays = list(counts = counts),
  colData = sample_data,
  rowData = gene_data
)

usethis::use_data(example_se, overwrite = TRUE)
```

**Data structure:** `SummarizedExperiment`

**What users should be able to do:**

- Select the X most variable genes from the dataset
- Run PCA on filtered, optionally transformed expression data
- Summarize variance explained per principal component
- Visualize samples in PC space, colored and shaped by metadata columns
- Export PCA scores and variance summaries to TSV files

**Key parameters:** `n_top`, `log_transform`, `scale`, `color_by`,
`shape_by`

**CLI outputs:** `pca_scores.tsv`, `pca_variance.tsv`

**Shiny inputs:** Number of top genes, log-transform toggle, scale
toggle, PC axes, color/shape by metadata column, point size

Raw analysis code

``` r
library(SummarizedExperiment)
library(airway)
library(ggplot2)

set.seed(42)

# 10000 genes, 8 samples
n_genes <- 10000
n_samples <- 8

# Simulate counts (negative binomial-ish)
counts <- matrix(
  rpois(n_genes * n_samples, lambda = 100),
  nrow = n_genes,
  ncol = n_samples
)
rownames(counts) <- paste0("gene", seq_len(n_genes))
colnames(counts) <- paste0("sample", seq_len(n_samples))

# Add some structure: first 500 genes differ by treatment
treatment <- rep(c("control", "treated"), each = 4)
counts[1:500, treatment == "treated"] <- counts[1:500, treatment == "treated"] * 2

# Sample metadata
sample_data <- data.frame(
  sample_id = colnames(counts),
  treatment = treatment,
  batch = rep(c("A", "B"), times = 4),
  row.names = colnames(counts)
)

# Gene metadata
gene_data <- data.frame(
  gene_id = rownames(counts),
  gene_symbol = paste0("SYM", seq_len(n_genes)),
  row.names = rownames(counts)
)

# Create SummarizedExperiment
example_se <- SummarizedExperiment(
  assays = list(counts = counts),
  colData = sample_data,
  rowData = gene_data
)

# ============================================================================
# Everything above is upstream data preparation — belongs in data-raw/.
# Everything below is core analysis — should be functionized in R/.
# ============================================================================

# --- Feature selection: top 200 most variable genes ---
mat <- assay(example_se, "counts")
vars <- apply(mat, 1, stats::var)
top_idx <- order(vars, decreasing = TRUE)[seq_len(200)]
se_top <- example_se[top_idx, ]

# --- PCA ---
mat <- assay(se_top, "counts")
mat <- log2(mat + 1)                 # log-transform with pseudocount
mat_t <- t(mat)                      # prcomp expects samples as rows
pca_result <- prcomp(mat_t, scale. = TRUE, center = TRUE)

# Build scores data.frame merged with sample metadata
scores <- as.data.frame(pca_result$x)
scores$sample_id <- rownames(scores)
col_data <- as.data.frame(colData(example_se))
col_data$sample_id <- rownames(col_data)
scores <- merge(scores, col_data, by = "sample_id")
scores <- scores[order(scores$sample_id), ]
rownames(scores) <- NULL

# --- Variance explained ---
var_explained <- pca_result$sdev^2 / sum(pca_result$sdev^2) * 100
var_df <- data.frame(
    PC = paste0("PC", seq_along(var_explained)),
    variance_percent = var_explained
)

# --- PCA scatter plot ---
var_x <- round(var_df$variance_percent[1], 1)
var_y <- round(var_df$variance_percent[2], 1)

p_pca <- ggplot(scores, aes(x = .data[["PC1"]], y = .data[["PC2"]])) +
    geom_point(aes(color = .data[["treatment"]]), size = 4) +
    theme_bw(base_size = 14) +
    labs(x = paste0("PC1 (", var_x, "% variance)"),
         y = paste0("PC2 (", var_y, "% variance)"),
         title = "PCA Plot")
print(p_pca)

# --- Variance explained bar chart ---
var_top <- var_df[1:8, ]
var_top$PC <- factor(var_top$PC, levels = var_top$PC)

p_var <- ggplot(var_top, aes(x = .data$PC, y = .data$variance_percent)) +
    geom_col(fill = "steelblue") +
    geom_text(aes(label = sprintf("%.1f%%", .data$variance_percent)),
              vjust = -0.5, size = 4) +
    theme_bw(base_size = 14) +
    labs(x = "Principal Component", y = "Variance Explained (%)") +
    ylim(0, max(var_top$variance_percent) * 1.15)
print(p_var)

# --- Export TSVs ---
output_dir <- file.path(tempdir(), "pca_output")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

write.table(scores, file.path(output_dir, "pca_scores.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)
write.table(var_df, file.path(output_dir, "pca_variance.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)

cat("Wrote results to:", output_dir, "\n")
list.files(output_dir)
```

------------------------------------------------------------------------

## Project 1: UMAP Embedding Explorer

**Rationale:**
[UMAP](https://alleninstitute.org/resource/what-is-a-umap/) is a
nonlinear dimensionality reduction method that reveals biological
structure, such as cell types, that PCA may struggle to cleanly reveal.
It is a standard visualization in single-cell RNA-seq analysis, and
tuning its parameters (n_neighbors, min_dist) meaningfully changes the
result.

For large datasets, PCA is often used as a pre-reduction step before
UMAP to speed up computation and reduce noise. Evaluating the quality of
a UMAP embedding is an open question. One common approach is to compute
k-nearest-neighbor preservation, which quantifies how well the local
neighborhood structure of the original high-dimensional data is
preserved in the UMAP embedding.

Examining k-NN preservation *per cell type* (rather than only as a
global mean) adds biological interpretability: cell types with low
preservation scores may have diffuse or intermixed structure in the
original PCA space, suggesting that subclustering or finer resolution
analysis could be warranted for those populations.

### Dataset: Zeisel Brain (Mouse scRNA-seq)

The [Zeisel et al. (2015)](https://pubmed.ncbi.nlm.nih.gov/25700174/)
dataset profiles 3,005 cells from the mouse somatosensory cortex and
hippocampus, classified into 7 major cell types (interneurons, pyramidal
neurons, oligodendrocytes, microglia, astrocytes, endothelial, and mural
cells) and 47 subtypes. The clear cell-type structure makes UMAP
parameters visually interpretable.

Data preparation code

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

- Select the most variable genes for downstream analysis
- Run PCA as a pre-reduction step before UMAP (standard practice in
  scRNA-seq workflows — reduces noise and speeds up computation)
- Run UMAP on the PCA-reduced data with configurable parameters
  (neighbors, min_dist, metric, number of PCs to use as input)
- Compute an embedding quality metric: k-nearest-neighbor preservation
  (what fraction of each cell’s k nearest neighbors in the
  high-dimensional PCA space are preserved in UMAP space)
- Break down k-NN preservation by cell type to identify populations
  whose local neighborhood structure is poorly captured by the
  embedding, which may indicate candidates for subclustering
- Summarize the embedding (parameter values, spread statistics, global
  and per-cell-type quality scores)
- Visualize cells in UMAP space, colored/shaped by metadata columns
- Visualize per-cell-type k-NN preservation as a violin/box plot to flag
  populations with low embedding fidelity
- Export UMAP coordinates, parameter summaries, and quality metrics to
  TSV files

**Key parameters:** `n_top`, `n_pcs` (number of PCs to use as UMAP
input, default 30), `n_neighbors`, `min_dist`, `metric`
(euclidean/cosine), `color_by`, `shape_by`

**CLI outputs:** `umap_embeddings.tsv` (cell × UMAP1/UMAP2 + metadata +
`knn_preserved` per-cell score), `umap_params.tsv` (parameter values +
spread stats + global and per-cell-type quality scores)

**Shiny inputs:** n_top slider, n_pcs slider (10–50), n_neighbors slider
(5–50), min_dist slider (0.01–1.0), metric dropdown, color/shape by
metadata, per-cell-type k-NN preservation violin plot

**Dependencies:** `SingleCellExperiment`, `scuttle`, `uwot`, `scRNAseq`
(data only)

Raw analysis code

``` r
library(SingleCellExperiment)
library(scRNAseq)
library(scuttle)
library(uwot)
library(ggplot2)

set.seed(42) # UMAP has randomness so we set a seed for reproducibility

# --- Load data ---
sce <- ZeiselBrainData()
counts_mat <- counts(sce)
cell_type <- colData(sce)$level1class

# ============================================================================
# Everything above is upstream data preparation — belongs in data-raw/.
# Everything below is core analysis — should be functionized in R/.
# ============================================================================

# --- Log-normalize using scuttle ---
# Normalize on the full SCE so size factors reflect the complete library
sce <- logNormCounts(sce)

# --- Feature selection: top 2000 most variable genes ---
gene_vars <- apply(counts_mat, 1, var)
top_idx <- order(gene_vars, decreasing = TRUE)[seq_len(2000)]
mat_norm <- as.matrix(logcounts(sce)[top_idx, ])

# --- PCA on the top 2000 most variable genes using the transformed counts ---
n_pcs <- 30
pca_result <- prcomp(t(mat_norm), scale. = TRUE, center = TRUE)
pca_mat <- pca_result$x[, seq_len(n_pcs)]

# --- Run UMAP on PCA-reduced data ---
n_neighbors <- 15
min_dist    <- 0.1
metric      <- "euclidean"
umap_coords <- umap(pca_mat,
                     n_neighbors = n_neighbors,
                     min_dist    = min_dist,
                     metric      = metric,
                     n_components = 2)

# --- k-NN preservation: quality metric ---
# For each cell, check how many of its k nearest neighbors in PCA space
# are also neighbors in UMAP space
k_eval <- 15 # Note this should be <= n_neighbors used for UMAP - setting them the same makes sense
pca_dists  <- as.matrix(dist(pca_mat))
umap_dists <- as.matrix(dist(umap_coords))
n_cells_eval <- nrow(pca_mat)
preserved <- numeric(n_cells_eval)
for (i in seq_len(n_cells_eval)) {
    pca_nn  <- order(pca_dists[i, ])[2:(k_eval + 1)]
    umap_nn <- order(umap_dists[i, ])[2:(k_eval + 1)]
    preserved[i] <- length(intersect(pca_nn, umap_nn)) / k_eval
}
knn_preservation <- mean(preserved)
cat("k-NN preservation:", round(knn_preservation, 3), "\n")

# --- Per-cell-type k-NN preservation ---
knn_df <- data.frame(
    cell_id        = colnames(sce),
    cell_type      = cell_type,
    knn_preserved  = preserved
)

# Global mean per cell type — flag types with mean below overall mean
knn_by_type <- tapply(knn_df$knn_preserved, knn_df$cell_type, mean)
cat("Per-cell-type mean k-NN preservation:\n")
print(round(sort(knn_by_type), 3))

# Violin + box plot: per-cell-type distribution, sorted by median
cell_type_order <- names(sort(tapply(knn_df$knn_preserved, knn_df$cell_type, median)))
knn_df$cell_type <- factor(knn_df$cell_type, levels = cell_type_order)

p_knn <- ggplot(knn_df, aes(x = cell_type, y = knn_preserved, fill = cell_type)) +
    geom_violin(trim = FALSE, alpha = 0.6) +
    geom_boxplot(width = 0.15, outlier.size = 0.8, alpha = 0.9) +
    geom_hline(yintercept = knn_preservation, lty = 2, color = "black") +
    theme_bw(base_size = 14) +
    theme(axis.text.x = element_text(angle = 30, hjust = 1),
          legend.position = "none") +
    labs(x = "Cell Type",
         y = paste0("k-NN Preservation (k = ", k_eval, ")"),
         title = paste0("Per-Cell-Type k-NN Preservation (global mean = ",
                        round(knn_preservation, 3), ")"),
         caption = "Dashed line = global mean. Low-scoring types may benefit from subclustering.")
print(p_knn)

# --- Build embeddings data.frame ---
embeddings <- data.frame(
    cell_id       = colnames(sce),
    UMAP1         = umap_coords[, 1],
    UMAP2         = umap_coords[, 2],
    cell_type     = cell_type,
    knn_preserved = preserved
)

# --- Parameter summary ---
params <- data.frame(
    parameter = c("n_neighbors", "min_dist", "metric", "n_pcs",
                  "n_genes", "n_cells",
                  "UMAP1_range", "UMAP2_range",
                  "UMAP1_sd", "UMAP2_sd",
                  "knn_preservation"),
    value = c(n_neighbors, min_dist, metric, n_pcs,
              nrow(mat), ncol(mat),
              round(diff(range(umap_coords[, 1])), 2),
              round(diff(range(umap_coords[, 2])), 2),
              round(sd(umap_coords[, 1]), 2),
              round(sd(umap_coords[, 2]), 2),
              round(knn_preservation, 4))
)

# Append per-cell-type k-NN preservation to params
knn_type_rows <- data.frame(
    parameter = paste0("knn_pres_", names(knn_by_type)),
    value     = as.character(round(knn_by_type, 4))
)
params <- rbind(params, knn_type_rows)

# --- UMAP scatter plot ---
p <- ggplot(embeddings, aes(x = UMAP1, y = UMAP2, color = cell_type)) +
    geom_point(size = 0.8, alpha = 0.7) +
    theme_bw(base_size = 14) +
    labs(title = paste0("UMAP — Zeisel Brain (k-NN pres: ",
                        round(knn_preservation, 2), ")"),
         color = "Cell type")
print(p)

# --- Export ---
output_dir <- file.path(tempdir(), "umap_output")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

write.table(embeddings, file.path(output_dir, "umap_embeddings.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)
write.table(params, file.path(output_dir, "umap_params.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)

list.files(output_dir)
```

------------------------------------------------------------------------

## Project 2: Sample Similarity & Clustering

**Rationale:** Before formal analysis, you often must check whether
samples group by the expected biological variable (treatment, genotype)
rather than technical artifacts (batch, patient). A sample-by-sample
correlation heatmap with hierarchical clustering is a common diagnostic
and can also be used to display sample groupings with additional
metadata annotations. It can also be useful for identifying outlier
samples that should perhaps be investigated more closely.

### Dataset: Macrophage Stimulation (Human bulk RNA-seq)

The `macrophage` package ([Alasoo et al.,
2018](https://pubmed.ncbi.nlm.nih.gov/29379200/)) contains RNA-seq data
from human monocyte-derived macrophages: 6 donors × 4 stimulation
conditions (naive, IFNγ, Salmonella, and IFNγ + Salmonella) for 24
samples total. The dual grouping by stimulation and donor creates an
interesting similarity structure where immune activation effects and
donor-specific variation compete — stimulated conditions should cluster
together, with donor effects visible within each treatment group.

Data preparation code

``` r
## data-raw/example_se.R
BiocManager::install(c("macrophage", "tximeta"))
library(macrophage)
library(tximeta)
library(SummarizedExperiment)

# Import salmon quantifications via tximeta
dir <- system.file("extdata", package = "macrophage")
coldata <- read.csv(file.path(dir, "coldata.csv"))
coldata$files <- file.path(dir, "quants", coldata$names, "quant.sf.gz")
coldata$names <- coldata$sample_id

se <- tximeta(coldata)
gse <- summarizeToGene(se)

# Simplify colData
colData(gse) <- DataFrame(
  condition = factor(gse$condition_name),
  donor = factor(gse$line_id)
)

usethis::use_data(gse, overwrite = TRUE)
```

**Data structure:** `SummarizedExperiment`

**What users should be able to do:**

- Select the most variable genes
- Compute pairwise sample similarity (correlation or distance matrix)
- Perform hierarchical clustering, cut at a chosen k, and compute
  silhouette widths to assess cluster quality
- Compute cophenetic correlation to assess how well the dendrogram
  preserves the original dissimilarity structure
- Assess cluster stability via bootstrap resampling: resample genes N
  times, recluster, and compute Jaccard overlap of cluster memberships
- Visualize an annotated heatmap with dendrogram sidebars and metadata
  color bars
- Export the similarity matrix, cluster assignments, and stability
  results to TSV files

**Key parameters:** `n_top`, `method` (pearson/spearman), `linkage`
(ward.D2/complete/average), `k`, `n_bootstrap` (number of bootstrap
iterations for stability)

**CLI outputs:** `similarity_matrix.tsv`, `cluster_assignments.tsv`,
`cluster_stability.tsv`

**Shiny inputs:** Correlation method, linkage method, k slider, n_top
slider, n_bootstrap slider, metadata columns for annotation bars,
stability bar chart

**Dependencies:** `SummarizedExperiment`, `macrophage` + `tximeta` (data
only)

Raw analysis code

``` r
library(SummarizedExperiment)
library(macrophage)
library(tximeta)
library(ComplexHeatmap)
library(cluster)
library(ggplot2)

# --- Load data via tximeta ---
dir <- system.file("extdata", package = "macrophage")
coldata <- read.csv(file.path(dir, "coldata.csv"))
coldata$files <- file.path(dir, "quants", coldata$names, "quant.sf.gz")
coldata$names <- coldata$sample_id
se <- tximeta(coldata)
gse <- summarizeToGene(se)

# Simplify metadata
condition <- factor(gse$condition_name)
donor     <- factor(gse$line_id)

# ============================================================================
# Everything above is upstream data preparation — belongs in data-raw/.
# Everything below is core analysis — should be functionized in R/.
# ============================================================================

# --- Feature selection: top 2000 most variable genes ---
mat <- assay(gse, "counts")
gene_vars <- apply(mat, 1, var)
top_idx <- order(gene_vars, decreasing = TRUE)[seq_len(2000)]
mat_top <- mat[top_idx, ]

# Log-transform
mat_log <- log2(mat_top + 1)

# --- Pairwise sample correlation ---
cor_mat <- cor(mat_log, method = "pearson")

# --- Hierarchical clustering ---
hc <- hclust(as.dist(1 - cor_mat), method = "ward.D2")
k <- 4
clusters <- cutree(hc, k = k)

# --- Silhouette widths ---
sil <- silhouette(clusters, dist = as.dist(1 - cor_mat))
avg_sil <- mean(sil[, "sil_width"])
cat("Average silhouette width:", round(avg_sil, 3), "\n")

# --- Cophenetic correlation ---
coph <- cor(as.dist(1 - cor_mat), cophenetic(hc))
cat("Cophenetic correlation:", round(coph, 3), "\n")

# --- Bootstrap cluster stability ---
n_bootstrap <- 50
set.seed(42)
boot_jaccard <- matrix(NA, nrow = n_bootstrap, ncol = k)
for (b in seq_len(n_bootstrap)) {
    boot_genes <- sample(nrow(mat_top), replace = TRUE)
    boot_log <- log2(mat_top[boot_genes, ] + 1)
    boot_cor <- cor(boot_log, method = "pearson")
    boot_hc <- hclust(as.dist(1 - boot_cor), method = "ward.D2")
    boot_cl <- cutree(boot_hc, k = k)
    for (ci in seq_len(k)) {
        orig_members <- names(clusters[clusters == ci])
        boot_members <- names(boot_cl[boot_cl == ci])
        jaccard <- length(intersect(orig_members, boot_members)) /
                   length(union(orig_members, boot_members))
        boot_jaccard[b, ci] <- jaccard
    }
}
stability <- data.frame(
    cluster = seq_len(k),
    mean_jaccard = colMeans(boot_jaccard),
    sd_jaccard   = apply(boot_jaccard, 2, sd)
)

# --- Annotated heatmap ---
col_anno <- HeatmapAnnotation(
    condition = condition,
    donor     = donor,
    cluster   = factor(clusters)
)
ht <- Heatmap(cor_mat, name = "Pearson r",
              top_annotation = col_anno,
              show_row_names = TRUE, show_column_names = TRUE,
              column_title = "Sample Similarity")
draw(ht)

# --- Export ---
output_dir <- file.path(tempdir(), "similarity_output")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

write.table(as.data.frame(cor_mat),
            file.path(output_dir, "similarity_matrix.tsv"),
            sep = "\t", quote = FALSE)

assignments <- data.frame(
    sample    = colnames(gse),
    condition = as.character(condition),
    donor     = as.character(donor),
    cluster   = clusters,
    silhouette_width = sil[, "sil_width"]
)
write.table(assignments, file.path(output_dir, "cluster_assignments.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)

write.table(stability, file.path(output_dir, "cluster_stability.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)

list.files(output_dir)
```

------------------------------------------------------------------------

## Project 3: Differential Expression with DESeq2

**Rationale:** One of the most common ’omics analyses is differential
expression analysis.
[DESeq2](https://bioconductor.org/packages/devel/bioc/vignettes/DESeq2/inst/doc/DESeq2.html)
is a common package for differential analysis of count data (RNA-seq or
otherwise) — it models the mean-variance relationship with a negative
binomial distribution, shares information across features to stabilize
fold-change estimates, and provides log2 fold-change shrinkage for
reliable ranking. Volcano and MA plots of differential results are
bog-standard visualizations for count-based data.

### Dataset: Tissue-Resident Regulatory T Cells (Mouse bulk RNA-seq)

The `tissueTreg` package provides htseq count data from [Delacher et
al. (2017)](https://pubmed.ncbi.nlm.nih.gov/28783152/), profiling
regulatory T cells (Tregs) isolated from four mouse tissues — fat,
liver, lymph node, and skin — alongside conventional T cells (Tconv)
from lymph nodes. This 5-group design lets students choose their own
comparison (e.g., lymph-node Treg vs. Tconv, or fat vs. liver Tregs).
The dataset is accessible directly via `ExperimentHub` (ID `EH1075`) and
contains 21,935 genes × 15 samples with raw integer counts ready for
DESeq2.

Data preparation code

``` r
## data-raw/example_se.R
BiocManager::install("ExperimentHub")
library(ExperimentHub)
library(SummarizedExperiment)

eh <- ExperimentHub()
se <- eh[["EH1075"]]  # Tissue Tregs — htseq counts, Mus musculus

# Parse tissue and cell type from the combined tissue_cell column
cd <- colData(se)
tissue_cell <- as.character(cd[["tissue_cell"]])
cell_type <- ifelse(grepl("Tcon", tissue_cell), "Tconv", "Treg")
tissue    <- sub("-Tre?[a-z]*", "", tissue_cell)  # strip cell-type suffix
tissue    <- sub("-Tcon", "", tissue)

example_se <- SummarizedExperiment(
  assays  = list(counts = assay(se, "counts")),
  colData = DataFrame(
    sample_id   = rownames(cd),
    cell_type   = factor(cell_type),
    tissue      = factor(tissue)
  )
)

usethis::use_data(example_se, overwrite = TRUE)
```

**Data structure:** `SummarizedExperiment`

**What users should be able to do:**

- Filter out genes with low expression across samples (e.g., minimum
  total count threshold)
- Run DESeq2 differential expression analysis between two groups,
  producing log2 fold changes, p-values, and BH-adjusted p-values
- Apply log2 fold-change shrinkage for more reliable effect-size
  estimates
- Summarize the number of significantly up/down/non-significant genes at
  given thresholds
- Compute independent filtering diagnostics: evaluate how the
  pre-filtering threshold (minimum count per group) affects the number
  of discoveries, enabling users to choose an informed threshold
- Visualize results as a volcano plot (log2FC vs. −log10 p) or MA plot
  (mean expression vs. log2FC), with significant genes highlighted
- Export differential expression results, summary counts, and filtering
  diagnostics to TSV files

**Key parameters:** `group_column`, `ref_level`, `fc_threshold`,
`p_threshold`, `shrinkage` (apeglm/ashr/normal/none), `plot_type`
(volcano/ma), `min_count_per_group` (minimum mean count per group for
gene filtering)

**CLI outputs:** `de_results.tsv`, `de_summary.tsv`,
`filtering_diagnostics.tsv`

**Shiny inputs:** Grouping column, reference level, FC threshold slider,
p-value threshold slider, shrinkage method dropdown, volcano ↔︎ MA radio
button, min count per group slider, filtering diagnostics plot

**Dependencies:** `SummarizedExperiment`, `DESeq2`, `ExperimentHub`
(data retrieval)

Raw analysis code

``` r
library(SummarizedExperiment)
library(ExperimentHub)
library(DESeq2)
library(apeglm)
library(ggplot2)

# --- Load data ---
eh <- ExperimentHub()
se <- eh[["EH1075"]]  # Tissue Tregs — 21,935 genes x 15 samples

# Parse tissue and cell type from tissue_cell column
cd <- colData(se)
tissue_cell <- as.character(cd[["tissue_cell"]])
cell_type <- ifelse(grepl("Tcon", tissue_cell), "Tconv", "Treg")
tissue    <- sub("-Tre?[a-z]*", "", tissue_cell)
tissue    <- sub("-Tcon", "", tissue)

# Build clean SE
se_clean <- SummarizedExperiment(
    assays  = list(counts = assay(se, "counts")),
    colData = DataFrame(cell_type = factor(cell_type),
                        tissue    = factor(tissue))
)

# --- Filter: keep lymph-node samples only, for Treg vs Tconv ---
keep <- se_clean$tissue == "Lymph-N"
se_ln <- se_clean[, keep]
se_ln$cell_type <- droplevels(se_ln$cell_type)

# ============================================================================
# Everything above is upstream data preparation — belongs in data-raw/.
# Everything below is core analysis — should be functionized in R/.
# ============================================================================

# Filter low-count genes
keep_genes <- rowSums(assay(se_ln, "counts")) >= 10
se_ln <- se_ln[keep_genes, ]
cat("Genes after filtering:", nrow(se_ln), "\n")

# --- DESeq2 ---
dds <- DESeqDataSet(se_ln, design = ~ cell_type)
dds$cell_type <- relevel(dds$cell_type, ref = "Tconv")
dds <- DESeq(dds)

# Log2 fold-change shrinkage
coef_name <- resultsNames(dds)[2]  # "cell_type_Treg_vs_Tconv"
res_shrunk <- lfcShrink(dds, coef = coef_name, type = "apeglm")
res_df <- as.data.frame(res_shrunk)
res_df$gene <- rownames(res_df)

# --- Summary ---
p_threshold  <- 0.05
fc_threshold <- 0.5
res_df$direction <- "ns"
res_df$direction[res_df$padj < p_threshold & res_df$log2FoldChange >  fc_threshold] <- "up"
res_df$direction[res_df$padj < p_threshold & res_df$log2FoldChange < -fc_threshold] <- "down"

summary_df <- as.data.frame(table(res_df$direction))
colnames(summary_df) <- c("direction", "count")
print(summary_df)

# --- Volcano plot ---
res_df$neg_log10p <- -log10(res_df$pvalue)
p <- ggplot(res_df, aes(x = log2FoldChange, y = neg_log10p, color = direction)) +
    geom_point(size = 0.8, alpha = 0.6) +
    scale_color_manual(values = c(down = "blue", ns = "grey70", up = "red")) +
    theme_bw(base_size = 14) +
    labs(x = "log2 Fold Change (Treg vs Tconv)",
         y = expression(-log[10](p)),
         title = "Volcano Plot — Lymph Node Treg vs Tconv") +
    geom_vline(xintercept = c(-fc_threshold, fc_threshold), lty = 2) +
    geom_hline(yintercept = -log10(p_threshold), lty = 2)
print(p)

# --- Independent filtering diagnostics ---
# Evaluate how the minimum count threshold affects number of discoveries
count_thresholds <- c(0, 1, 5, 10, 20, 50, 100, 200, 500)
filtering_diag <- data.frame(threshold = count_thresholds, n_tested = NA_integer_,
                              n_significant = NA_integer_)
for (j in seq_along(count_thresholds)) {
    thresh <- count_thresholds[j]
    keep_t <- rowSums(assay(se_ln, "counts")) >= thresh
    if (sum(keep_t) < 2) {
        filtering_diag$n_tested[j] <- sum(keep_t)
        filtering_diag$n_significant[j] <- 0
        next
    }
    dds_t <- DESeqDataSet(se_ln[keep_t, ], design = ~ cell_type)
    dds_t$cell_type <- relevel(dds_t$cell_type, ref = "Tconv")
    dds_t <- DESeq(dds_t, quiet = TRUE)
    res_t <- results(dds_t, alpha = p_threshold)
    filtering_diag$n_tested[j] <- sum(keep_t)
    filtering_diag$n_significant[j] <- sum(res_t$padj < p_threshold, na.rm = TRUE)
}

# --- Export ---
output_dir <- file.path(tempdir(), "de_output")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

write.table(res_df, file.path(output_dir, "de_results.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)
write.table(summary_df, file.path(output_dir, "de_summary.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)
write.table(filtering_diag, file.path(output_dir, "filtering_diagnostics.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)

list.files(output_dir)
```

------------------------------------------------------------------------

## Project 4: K-means Cell Clustering

**Rationale:** [K-means
clustering](https://stanford.edu/~cpiech/cs221/handouts/kmeans.html)
partitions samples into `k` groups by minimizing within-cluster
variance. Choosing k when you don’t know the real value is a real
practical decision — the elbow plot of within-cluster sum of squares is
one diagnostic. K-means clustering is also a simple way to split a
dataset into a specific number of groups, which can be useful when
qualitative groups are obvious (e.g. via PCA). Evaluating cluster
quality is an open question, but silhouette widths and gap statistics
are common metrics. When reference labels are available, the Adjusted
Rand Index (ARI) quantifies how well the clusters match known groups.

### Dataset: Baron Human Pancreas (scRNA-seq)

The [Baron et al. (2016)
dataset](https://pubmed.ncbi.nlm.nih.gov/27667365/) profiles ~8,500
cells from human pancreatic islets, capturing 14 cell types including
alpha, beta, delta, gamma, acinar, and ductal cells. Students must build
a project to provide elbow and silhouette diagnostics to help users
select the optimal number of clusters.

Data preparation code

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

- Select the most variable genes
- Run k-means clustering across a range of k values (2..max_k), see
  [`?kmeans`](https://rdrr.io/r/stats/kmeans.html)
- Compute clustering quality metrics (total within-cluster sum of
  squares, average silhouette width, and gap statistic) for each k, see
  [`?silhouette`](https://rdrr.io/pkg/cluster/man/silhouette.html) and
  [`?clusGap`](https://rdrr.io/pkg/cluster/man/clusGap.html)
- Evaluate cluster assignments against known cell type labels using the
  Adjusted Rand Index (ARI) when reference labels are available
- Visualize clusters on a PCA projection, colored by cluster assignment
- Generate an elbow plot (WSS vs. k) and silhouette/gap plots for
  choosing the optimal number of clusters
- Export cluster assignments, quality metrics, and evaluation results to
  TSV files

**Key parameters:** `n_top`, `max_k`, `n_starts`, `selected_k`,
`reference_column` (metadata column for ARI, optional)

**CLI outputs:** `cluster_assignments.tsv`, `kmeans_metrics.tsv`,
`cluster_evaluation.tsv`

**Shiny inputs:** n_top slider, max_k slider, selected k slider, toggle
between elbow plot and cluster scatter, color by cluster or cell_type
metadata

**Dependencies:** `SingleCellExperiment`, `scuttle`, `cluster`,
`scRNAseq` (data only)

Raw analysis code

``` r
library(SingleCellExperiment)
library(scRNAseq)
library(scuttle)
library(cluster)
library(ggplot2)

# --- Load data ---
sce <- BaronPancreasData("human")
counts_mat <- counts(sce)
cell_type <- colData(sce)$label

# ============================================================================
# Everything above is upstream data preparation — belongs in data-raw/.
# Everything below is core analysis — should be functionized in R/.
# ============================================================================

# --- Log-normalize using scuttle ---
# Normalize on the full SCE so size factors reflect the complete library
sce <- logNormCounts(sce)

# --- Feature selection: top 2000 most variable genes ---
gene_vars <- apply(counts_mat, 1, var)
top_idx <- order(gene_vars, decreasing = TRUE)[seq_len(2000)]
mat_norm <- as.matrix(logcounts(sce)[top_idx, ])

# --- PCA ---
pca <- prcomp(t(mat_norm), scale. = TRUE, center = TRUE)
pca_mat <- pca$x[, 1:20]  # first 20 PCs for clustering

# --- K-means across k = 5..20 ---
max_k <- 20
n_starts <- 25
set.seed(42)

metrics <- data.frame(k = 5:max_k, wss = NA_real_, avg_silhouette = NA_real_)
km_list <- list()
for (k in 5:max_k) {
    km <- kmeans(pca_mat, centers = k, nstart = n_starts)
    km_list[[as.character(k)]] <- km
    metrics$wss[k - 1] <- km$tot.withinss # Total within-cluster sum of squares
    sil <- silhouette(km$cluster, dist(pca_mat))
    metrics$avg_silhouette[k - 1] <- mean(sil[, "sil_width"])
}

# --- Gap statistic ---
gap_stat <- clusGap(pca_mat, FUN = kmeans, nstart = n_starts,
                    K.max = max_k, B = 20)
gap_tab <- as.data.frame(gap_stat$Tab)
metrics$gap <- gap_tab$gap[5:max_k]
metrics$gap_se <- gap_tab$SE.sim[5:max_k]

# --- Adjusted Rand Index vs known cell types ---
evaluation <- data.frame(k = 5:max_k, ari = NA_real_)
for (k in 5:max_k) {
    pred <- km_list[[as.character(k)]]$cluster
    tab <- table(cell_type, pred)
    n <- sum(tab)
    sum_comb <- function(x) x * (x - 1) / 2
    sum_rows <- sum(sum_comb(rowSums(tab)))
    sum_cols <- sum(sum_comb(colSums(tab)))
    sum_all  <- sum(sum_comb(tab))
    expected <- sum_rows * sum_cols / sum_comb(n)
    max_index <- (sum_rows + sum_cols) / 2
    ari <- if (max_index == expected) 0 else (sum_all - expected) / (max_index - expected)
    evaluation$ari[k - 1] <- ari
}

# --- Elbow plot ---
p_elbow <- ggplot(metrics, aes(x = k, y = wss)) +
    geom_line() + geom_point(size = 2) +
    theme_bw(base_size = 14) +
    labs(x = "Number of Clusters (k)",
         y = "Total Within-Cluster Sum of Squares",
         title = "Elbow Plot")
print(p_elbow)

# --- Cluster scatter for selected k ---
selected_k <- 14
km_sel <- km_list[[as.character(selected_k)]]
scatter_df <- data.frame(
    PC1 = pca$x[, 1], PC2 = pca$x[, 2],
    cluster   = factor(km_sel$cluster),
    cell_type = cell_type
)
p_scatter <- ggplot(scatter_df, aes(x = PC1, y = PC2, color = cluster)) +
    geom_point(size = 0.6, alpha = 0.6) +
    theme_bw(base_size = 14) +
    labs(title = paste0("K-means (k=", selected_k, ") on PCA"))
print(p_scatter)

# --- Export ---
output_dir <- file.path(tempdir(), "kmeans_output")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

assignments <- data.frame(
    cell_id   = colnames(sce),
    cell_type = cell_type,
    cluster   = km_sel$cluster
)
write.table(assignments, file.path(output_dir, "cluster_assignments.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)
write.table(metrics, file.path(output_dir, "kmeans_metrics.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)
write.table(evaluation, file.path(output_dir, "cluster_evaluation.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)

list.files(output_dir)
```

------------------------------------------------------------------------

## Project 5: Cell QC Dashboard

**Rationale:** Quality control is the essential first step in scRNA-seq
analysis. Before any biological interpretation, low-quality cells (those
with too few detected genes, low library sizes, or high spike-in
proportions) must be identified and flagged. ERCC spike-in controls
provide a ground-truth reference for QC.

### Dataset: Lun Spike-In (Mouse scRNA-seq)

The Lun et al. (2017) dataset contains 192 mouse cells with ERCC
spike-in controls. It was specifically designed for benchmarking
normalization and QC methods. The spike-in proportions and library size
variation create natural QC outliers that students must detect.

**Important note on data structure:**
[`LunSpikeInData()`](https://rdrr.io/pkg/scRNAseq/man/LunSpikeInData.html)
stores the ERCC spike-in counts in an *alternative experiment*
(`altExp`), not alongside endogenous genes in the main assay. This is
the standard Bioconductor convention for spike-ins: `rownames(sce)`
contains only the ~9,000 endogenous mouse genes, while
`altExp(sce, "ERCC")` is itself a `SingleCellExperiment` holding the 92
ERCC control counts for the same cells. To compute spike-in percentage
per cell, sum across `counts(altExp(sce, "ERCC"))` and divide by the
total library size (endogenous + spike-in counts).

Data preparation code

``` r
## data-raw/example_sce.R
BiocManager::install(c("scRNAseq", "org.Mm.eg.db", "AnnotationDbi"))
library(scRNAseq)
library(SingleCellExperiment)
library(org.Mm.eg.db)
library(AnnotationDbi)

sce <- LunSpikeInData()
example_sce <- sce

# ERCC spike-ins are already in altExp(example_sce, "ERCC") — the standard
# Bioconductor convention. Do NOT look for ERCC rows in rownames(example_sce);
# they live in the alternative experiment, accessed via:
#   altExp(example_sce, "ERCC")          # the ERCC SCE
#   counts(altExp(example_sce, "ERCC"))  # ERCC count matrix (92 controls x 192 cells)

# Keep key metadata — note column names use spaces in the raw object;
# rename to R-friendly names
colData(example_sce) <- DataFrame(
  cell_line = colData(sce)[["cell line"]],
  block     = colData(sce)[["block"]]
)

# Add gene symbols to rowData via annotation package, needed for mitochondrial gene QC
gene_ids <- rownames(example_sce)
gene_symbols <- mapIds(org.Mm.eg.db, keys = gene_ids, column = "SYMBOL", keytype = "ENSEMBL", multiVals = "first")
rowData(example_sce)$symbol <- gene_symbols

usethis::use_data(example_sce, overwrite = TRUE)
```

**Data structure:** `SingleCellExperiment`

**What users should be able to do:**

- Compute per-cell QC metrics: library size, number of genes detected,
  spike-in percentage (from `altExp(sce, "ERCC")`), mitochondrial gene
  percentage (the standard QC metric for detecting dying cells), and
  novelty score (log10 genes / log10 UMI — detects low-complexity cells)
- Flag outlier cells using MAD-based thresholds on QC metrics
- Visualize QC results in a multi-panel display: library size
  distribution, genes vs. library size scatter, spike-in percentage
  histogram, mitochondrial percentage violin plot, with outliers
  highlighted
- Export QC metrics and pass/fail flags to TSV files

**Key parameters:** `mad_threshold`, `min_genes`, `min_library_size`,
`max_spike_pct`, `max_mito_pct`, `min_novelty`

**CLI outputs:** `qc_metrics.tsv`, `qc_flags.tsv`

**Shiny inputs:** MAD threshold slider, minimum genes input, max
spike-in % slider, max mito % slider, min novelty slider; panels update
to reflect pass/fail counts

**Dependencies:** `SingleCellExperiment`, `scRNAseq` (data only)

Raw analysis code

``` r
library(SingleCellExperiment)
library(scRNAseq)
library(ggplot2)
library(patchwork)
library(AnnotationDbi)
library(org.Mm.eg.db)

# --- Load data ---
sce <- LunSpikeInData()

gene_ids <- rownames(sce)
gene_symbols <- mapIds(org.Mm.eg.db, keys = gene_ids, column = "SYMBOL", keytype = "ENSEMBL", multiVals = "first")
rowData(sce)$symbol <- gene_symbols


# ============================================================================
# Everything above is upstream data preparation — belongs in data-raw/.
# Everything below is core analysis — should be functionized in R/.
# ============================================================================

counts_mat <- counts(sce)

# --- Compute per-cell QC metrics ---
lib_size     <- colSums(counts_mat)
n_genes      <- colSums(counts_mat > 0)

# Spike-in counts from altExp
ercc_counts  <- counts(altExp(sce, "ERCC"))
ercc_total   <- colSums(ercc_counts)
total_counts <- lib_size + ercc_total
spike_pct    <- ercc_total / total_counts * 100

# Shannon entropy of count distribution per cell
shannon <- apply(counts_mat, 2, function(x) {
    p <- x[x > 0] / sum(x[x > 0])
    -sum(p * log(p))
})

# Mitochondrial gene percentage
# In mouse data, mitochondrial genes typically start with "mt-"
is_mito <- grepl("^mt-", rowData(sce)$symbol, ignore.case = TRUE)
mito_total <- colSums(counts_mat[is_mito, , drop = FALSE])
mito_pct <- mito_total / lib_size * 100

# Novelty score: log10(genes detected) / log10(UMI counts)
# Cells with low complexity (e.g., dominated by a few genes) score low
novelty_score <- log10(n_genes) / log10(lib_size)
# Handle edge cases where lib_size is 0 or 1
novelty_score[!is.finite(novelty_score)] <- 0

qc_metrics <- data.frame(
    cell_id    = colnames(sce),
    cell_line  = colData(sce)[["cell line"]],
    block      = colData(sce)[["block"]],
    lib_size   = lib_size,
    n_genes    = n_genes,
    spike_pct  = spike_pct,
    mito_pct   = mito_pct,
    novelty    = novelty_score,
    entropy    = shannon
)

# --- MAD-based outlier flagging ---
mad_threshold <- 3
flag_low_lib   <- qc_metrics$lib_size   < median(lib_size)   - mad_threshold * mad(lib_size)
flag_low_genes <- qc_metrics$n_genes    < median(n_genes)    - mad_threshold * mad(n_genes)
flag_hi_spike  <- qc_metrics$spike_pct  > median(spike_pct)  + mad_threshold * mad(spike_pct)
flag_hi_mito   <- qc_metrics$mito_pct   > median(mito_pct)   + mad_threshold * mad(mito_pct)
flag_low_novelty <- qc_metrics$novelty  < median(novelty_score) - mad_threshold * mad(novelty_score)

qc_metrics$pass <- !(flag_low_lib | flag_low_genes | flag_hi_spike |
                      flag_hi_mito | flag_low_novelty)
cat("Cells passing QC:", sum(qc_metrics$pass), "/", nrow(qc_metrics), "\n")

# --- Multi-panel QC visualization ---
qc_metrics$status <- ifelse(qc_metrics$pass, "pass", "fail")

p1 <- ggplot(qc_metrics, aes(x = lib_size, fill = status)) +
    geom_histogram(bins = 30, alpha = 0.7) +
    theme_bw() + labs(x = "Library Size", title = "Library Size Distribution")

p2 <- ggplot(qc_metrics, aes(x = lib_size, y = n_genes, color = status)) +
    geom_point(size = 1.5, alpha = 0.7) +
    theme_bw() + labs(x = "Library Size", y = "Genes Detected")

p3 <- ggplot(qc_metrics, aes(x = spike_pct, fill = status)) +
    geom_histogram(bins = 30, alpha = 0.7) +
    theme_bw() + labs(x = "Spike-in %", title = "ERCC Spike-in Percentage")

p4 <- ggplot(qc_metrics, aes(x = n_genes, y = entropy, color = status)) +
    geom_point(size = 1.5, alpha = 0.7) +
    theme_bw() + labs(x = "Genes Detected", y = "Shannon Entropy")

# Print panels (use patchwork or gridExtra for combined layout)
(p1 | p2) / (p3 | p4)

# --- Export ---
output_dir <- file.path(tempdir(), "qc_output")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

write.table(qc_metrics, file.path(output_dir, "qc_metrics.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)

qc_flags <- data.frame(
    cell_id        = qc_metrics$cell_id,
    pass           = qc_metrics$pass,
    flag_low_lib   = flag_low_lib,
    flag_low_genes = flag_low_genes,
    flag_hi_spike  = flag_hi_spike,
    flag_hi_mito   = flag_hi_mito,
    flag_low_novelty = flag_low_novelty
)
write.table(qc_flags, file.path(output_dir, "qc_flags.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)

list.files(output_dir)
```

------------------------------------------------------------------------

## Project 6: Gene Set Scoring

**Rationale:** Rather than analyzing genes individually, biologists
often ask whether a predefined *set* of genes (a pathway, signature) is
collectively up- or down-regulated. Per-sample gene set scores reduce
genes composing a pathway or contributing to a given biological process
to a single number per sample, enabling group comparisons. This project
combines expression data with external pathway knowledge from MSigDB.

### Dataset: Airway (Human bulk RNA-seq) + MSigDB Hallmark Gene Sets

The `airway` Bioconductor package provides RNA-seq count data from
[Himes et al. (2014)](https://pubmed.ncbi.nlm.nih.gov/24926665/),
profiling four human airway smooth muscle cell lines treated with
dexamethasone (a glucocorticoid) versus untreated controls (8 samples
total). Dexamethasone activates inflammatory and stress-response
pathways that are well-represented in MSigDB Hallmark gene sets — making
this a compact, self-contained dataset for demonstrating pathway-level
scoring without requiring large data downloads.

In this case, you wouldn’t really have to prepare the data yourself or
include it in your package - it’s already readily available in the
format you need. But for the sake of the exercise, go ahead and save it
as an internal dataset in your package. This will give you practice with
packaging and documenting data, even if it’s not strictly necessary for
this particular dataset.

Data preparation code

``` r
## data-raw/example_se.R
library(airway)
library(SummarizedExperiment)

data(airway)

example_se <- airway

usethis::use_data(example_se, overwrite = TRUE)
```

**Data structure:** `SummarizedExperiment`

**What users should be able to do:**

- Read gene sets from a GMT file or named list of character vectors
- Compute per-sample gene set scores using two methods: mean z-score and
  rank-based scoring (ssGSEA-like: rank genes per sample, compute
  enrichment from ranks of set members) — comparing methods is essential
  since results can differ substantially
- Compute per-gene contribution scores within a gene set (individual
  gene z-scores across samples) to understand which genes drive the
  overall score
- Summarize mean scores per group and compute effect sizes between
  conditions
- Visualize gene set scores as boxplots or violin plots, grouped by a
  clinical variable and faceted by gene set; also visualize per-gene
  contributions as a heatmap strip for a selected gene set
- Export per-sample scores (with method column), group summaries, and
  per-gene contributions to TSV files

**Key parameters:** `gene_sets` (list or GMT path), `score_method`
(mean_z, rank_based, or both), `group_column`

**CLI outputs:** `geneset_scores.tsv`, `scoring_summary.tsv`,
`gene_contributions.tsv`

**Shiny inputs:** Select built-in sets or upload GMT, score method
dropdown, grouping variable dropdown (dex treatment, cell line), gene
set selector, boxplot ↔︎ violin toggle

**Dependencies:** `SummarizedExperiment`, `airway` (data only),
`msigdbr` (gene sets)

Raw analysis code

``` r
library(airway)
library(SummarizedExperiment)
library(msigdbr)
library(ggplot2)

# --- Load airway data ---
data(airway)

# log2-CPM normalize counts for scoring
counts_mat <- assay(airway, "counts")
lib_sizes   <- colSums(counts_mat)
mat         <- log2(t(t(counts_mat) / lib_sizes * 1e6) + 1)
dex         <- colData(airway)$dex  # "trt" or "untrt"

# Convert Ensembl IDs to gene symbols for MSigDB overlap
library(org.Hs.eg.db)
library(AnnotationDbi)
symbols <- mapIds(org.Hs.eg.db, keys = rownames(mat),
                  column = "SYMBOL", keytype = "ENSEMBL",
                  multiVals = "first")
keep <- !is.na(symbols)
mat  <- mat[keep, ]
rownames(mat) <- symbols[keep]

# --- Get MSigDB Hallmark gene sets ---
hallmarks <- msigdbr(species = "Homo sapiens", collection = "H")
gene_sets <- split(hallmarks$gene_symbol, hallmarks$gs_name)

# ============================================================================
# Everything above is upstream data preparation — belongs in data-raw/.
# Everything below is core analysis — should be functionized in R/.
# ============================================================================

# --- Compute per-sample gene set scores ---
mat_z <- t(scale(t(mat)))  # z-score each gene across samples

# Method 1: mean z-score
scores_meanz <- lapply(names(gene_sets), function(gs_name) {
    genes_in_set <- intersect(gene_sets[[gs_name]], rownames(mat_z))
    if (length(genes_in_set) < 5) return(NULL)
    per_sample <- colMeans(mat_z[genes_in_set, , drop = FALSE], na.rm = TRUE)
    data.frame(sample_id = colnames(mat), gene_set = gs_name,
               score = per_sample, method = "mean_z",
               dex = as.character(dex))
})

# Method 2: rank-based (ssGSEA-like)
scores_rank <- lapply(names(gene_sets), function(gs_name) {
    genes_in_set <- intersect(gene_sets[[gs_name]], rownames(mat))
    if (length(genes_in_set) < 5) return(NULL)
    # Rank genes per sample (higher expression = higher rank)
    ranks <- apply(mat, 2, rank)
    n <- nrow(ranks)
    in_set <- rownames(ranks) %in% genes_in_set
    # Enrichment score: mean rank of set members, normalized
    per_sample <- colMeans(ranks[in_set, , drop = FALSE]) / n
    data.frame(sample_id = colnames(mat), gene_set = gs_name,
               score = per_sample, method = "rank_based",
               dex = as.character(dex))
})

scores_df <- do.call(rbind, c(scores_meanz, scores_rank))

# --- Per-gene contribution for a selected gene set ---
selected_set <- names(gene_sets)[1]
contrib_genes <- intersect(gene_sets[[selected_set]], rownames(mat_z))
gene_contrib <- as.data.frame(t(mat_z[contrib_genes, , drop = FALSE]))
gene_contrib$sample_id <- colnames(mat)
gene_contrib$dex <- as.character(dex)

# --- Group summary ---
summary_df <- aggregate(score ~ gene_set + dex, data = scores_df,
                        FUN = function(x) c(mean = mean(x), sd = sd(x)))
summary_df <- do.call(data.frame, summary_df)
colnames(summary_df) <- c("gene_set", "dex", "mean_score", "sd_score")

# --- Horizontal grouped bar chart (mean ± SE per treatment group, faceted by method) ---
method_labels <- c(mean_z = "Mean Z-Score", rank_based = "Rank-Based (ssGSEA-like)")

p <- ggplot(scores_df, aes(x = gene_set, y = score, fill = dex)) +
    stat_summary(fun = mean, geom = "bar",
                 position = position_dodge(1.0), width = 0.6) +
    stat_summary(fun.data = mean_se, geom = "errorbar",
                 position = position_dodge(1.0), width = 0.2) +
    scale_fill_manual(values = c(trt = "#E64B35", untrt = "#4DBBD5"),
                      labels = c(trt = "Treated", untrt = "Untreated")) +
    facet_wrap(~ method, scales = "free_x", labeller = labeller(method = method_labels)) +
    coord_flip() +
    theme_bw(base_size = 9) +
    theme(legend.position = "top") +
    labs(x = "Gene Set", y = "Mean Gene Set Score",
         fill = "Dexamethasone",
         title = "Hallmark Gene Set Scores by Dexamethasone Treatment")
print(p)

# --- Export ---
output_dir <- file.path(tempdir(), "geneset_output")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

write.table(scores_df, file.path(output_dir, "geneset_scores.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)
write.table(summary_df, file.path(output_dir, "scoring_summary.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)
write.table(gene_contrib, file.path(output_dir, "gene_contributions.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)

list.files(output_dir)
```

------------------------------------------------------------------------

## Project 7: Gene Expression Profiler

**Rationale:** After cell types are annotated, a common question is “How
is gene X expressed across these groups?” Biologists routinely look up
known marker genes to sanity-check annotations, explore candidate genes
for follow-up experiments, or compare expression patterns between
related genes. This tool provides per-group expression statistics and
figures visualizations for any user-specified set of genes.

### Dataset: Muraro Human Pancreas (Human scRNA-seq)

The [Muraro et al. (2016)
dataset](https://pubmed.ncbi.nlm.nih.gov/27693023/) from `scRNAseq`
profiles ~2,300 cells from human donor pancreatic islets using CEL-Seq2.
Cell types include alpha, beta, delta, acinar, ductal, and more. The
well-characterized marker genes for each pancreatic cell type (INS for
beta cells, GCG for alpha, SST for delta, PRSS1 for acinar, KRT19 for
ductal) make results immediately interpretable — students can verify
their tool produces biologically expected patterns.

Data preparation code

``` r
## data-raw/example_sce.R
BiocManager::install("scRNAseq")
library(scRNAseq)
library(SingleCellExperiment)

sce <- MuraroPancreasData()
example_sce <- sce

assays(example_sce) <- list(counts = counts(example_sce))

# Note: rownames have a "__chrN" suffix (e.g. "INS__chr11") —
rownames(example_sce) <- sub("__chr.*$", "", rownames(example_sce))

# Remove cells with NA cell type (unlabeled)
example_sce <- example_sce[, !is.na(colData(example_sce)$label)]

usethis::use_data(example_sce, overwrite = TRUE)
```

**Data structure:** `SingleCellExperiment`

**What users should be able to do:**

- Normalize raw counts using
  [`scuttle::logNormCounts()`](https://rdrr.io/pkg/scuttle/man/logNormCounts.html)
  — the standard Bioconductor approach (library-size-based size
  factors + log2 transform)
- Look up a set of genes by name, with validation against the dataset
  (report which genes were found and which were missing)
- Compute per-group expression statistics for each queried gene: mean
  expression, median expression, and detection rate (fraction of cells
  in each group with non-zero counts)
- Compute a gene specificity score for each gene — a [Gini
  coefficient](https://en.wikipedia.org/wiki/Gini_coefficient) measuring
  how concentrated a gene’s expression is in one group versus spread
  evenly across all groups (0 = uniform, 1 = perfectly specific)
- Visualize expression as faceted violin plots (one panel per gene, x =
  cell type, colored by group) and as a co-expression scatter plot (two
  selected genes plotted against each other, colored by cell type)
- Export per-group expression statistics and gene specificity scores to
  TSV files

**Key parameters:** `genes` (character vector of gene names to query),
`group_column` (metadata column for grouping, default `"cell_type"`),
`min_detection` (minimum fraction of cells detecting a gene in at least
one group to include it in results)

**CLI outputs:** `expression_stats.tsv`, `gene_specificity.tsv`

**Shiny inputs:** Gene name text input (comma-separated), grouping
variable dropdown, plot type toggle (violin / co-expression scatter),
gene pair selectors for scatter view, detection threshold slider

**Dependencies:** `SingleCellExperiment`, `scuttle`, `scRNAseq` (data
only)

Raw analysis code

``` r
library(SingleCellExperiment)
library(scRNAseq)
library(scuttle)
library(ggplot2)

# --- Load data ---
sce <- MuraroPancreasData()

# Muraro rownames have a "__chrN" suffix — strip it for readable gene names
rownames(sce) <- sub("__chr.*$", "", rownames(sce))

# Remove cells with NA cell type (unlabeled)
sce <- sce[, !is.na(colData(sce)$label)]
cell_type <- colData(sce)$label

# --- Normalize using scuttle (standard Bioconductor scRNA-seq pipeline) ---
# logNormCounts() computes library-size-based size factors, normalizes,
# and log2-transforms, storing the result in logcounts(sce)
sce <- logNormCounts(sce)
mat_norm <- as.matrix(logcounts(sce))

# ============================================================================
# Everything above is upstream data preparation — belongs in data-raw/.
# Everything below is core analysis — should be functionized in R/.
# ============================================================================

# --- Define query genes (well-known pancreatic markers) ---
query_genes <- c("INS", "GCG", "SST", "PPY", "PRSS1", "KRT19")

# Validate: check which genes are present in the dataset
found <- query_genes %in% rownames(mat_norm)
cat("Found:", paste(query_genes[found], collapse = ", "), "\n")
if (any(!found)) cat("Missing:", paste(query_genes[!found], collapse = ", "), "\n")
query_genes <- query_genes[found]

# --- Build long-format expression data frame ---
n_cells <- ncol(mat_norm)
expr_vals <- c()
for (g in query_genes) expr_vals <- c(expr_vals, mat_norm[g, ])

expr_long <- data.frame(
    cell_id   = rep(colnames(mat_norm), length(query_genes)),
    gene      = rep(query_genes, each = n_cells),
    expr      = expr_vals,
    cell_type = rep(cell_type, length(query_genes)),
    stringsAsFactors = FALSE
)

# --- Per-group expression statistics ---
groups <- unique(cell_type)
counts_mat <- as.matrix(counts(sce))
stats_list <- vector("list", length(query_genes) * length(groups))
k <- 1
for (gene in query_genes) {
    vals <- mat_norm[gene, ]
    raw_vals <- counts_mat[gene, ]
    for (ct in groups) {
        idx <- which(cell_type == ct)
        stats_list[[k]] <- data.frame(
            gene           = gene,
            cell_type      = ct,
            mean_expr      = mean(vals[idx]),
            median_expr    = median(vals[idx]),
            detection_rate = mean(raw_vals[idx] > 0),
            n_cells        = length(idx),
            stringsAsFactors = FALSE
        )
        k <- k + 1
    }
}
expr_stats <- do.call(rbind, stats_list)
head(expr_stats)

# --- Gene specificity: Gini coefficient of mean expression across groups ---
# Gini = 0 means the gene is equally expressed in all groups
# Gini = 1 means the gene is expressed in only one group
gini <- function(x) {
    x <- sort(x[x >= 0])
    n <- length(x)
    if (n == 0 || sum(x) == 0) return(0)
    indices <- seq_len(n)
    2 * sum(indices * x) / (n * sum(x)) - (n + 1) / n
}

spec_list <- vector("list", length(query_genes))
for (i in seq_along(query_genes)) {
    gene <- query_genes[i]
    group_means <- tapply(mat_norm[gene, ], cell_type, mean)
    top_group <- names(which.max(group_means))
    spec_list[[i]] <- data.frame(
        gene         = gene,
        gini_score   = gini(as.numeric(group_means)),
        top_group    = top_group,
        top_mean     = max(group_means),
        overall_mean = mean(mat_norm[gene, ]),
        stringsAsFactors = FALSE
    )
}
specificity <- do.call(rbind, spec_list)
specificity <- specificity[order(specificity$gini_score, decreasing = TRUE), ]
print(specificity)

# --- Violin plot: one panel per gene, x = cell type ---
p_violin <- ggplot(expr_long, aes(x = cell_type, y = expr, fill = cell_type)) +
    geom_violin(trim = FALSE, alpha = 0.7, scale = "width") +
    geom_boxplot(width = 0.15, fill = "white", outlier.size = 0.3) +
    facet_wrap(~ gene, scales = "free_y", ncol = 3) +
    theme_bw(base_size = 13) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 9),
          legend.position = "none") +
    labs(x = "Cell Type", y = "Normalized Expression (log2)",
         title = "Gene Expression Across Cell Types")
print(p_violin)

# --- Co-expression scatter: INS vs GCG, colored by cell type ---
gene_a <- "INS"
gene_b <- "GCG"
scatter_df <- data.frame(
    expr_a    = mat_norm[gene_a, ],
    expr_b    = mat_norm[gene_b, ],
    cell_type = cell_type
)

p_scatter <- ggplot(scatter_df, aes(x = expr_a, y = expr_b, color = cell_type)) +
    geom_point(size = 1.5, alpha = 1) +
    theme_bw(base_size = 13) +
    labs(x = paste0(gene_a, " (log-normalized)"),
         y = paste0(gene_b, " (log-normalized)"),
         color = "Cell Type",
         title = paste0("Co-Expression: ", gene_a, " vs. ", gene_b),
         subtitle = "Mutually exclusive in alpha vs. beta cells")
print(p_scatter)

# --- Export ---
output_dir <- file.path(tempdir(), "expr_output")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

write.table(expr_stats, file.path(output_dir, "expression_stats.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)

write.table(specificity, file.path(output_dir, "gene_specificity.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)

list.files(output_dir)
```

------------------------------------------------------------------------

## Project 8: Gene Correlation Network

**Rationale:** Co-expressed genes often share biological functions.
Building a gene-gene correlation network by computing pairwise
correlations, thresholding to an adjacency matrix, and identifying hub
genes is a lightweight introduction to network biology. Datasets with
many samples provide stable pairwise gene correlations that reveal known
co-regulation patterns.

### Dataset: GTEx Skeletal Muscle (Human bulk RNA-seq)

The [`recount3` package](https://rna.recount.bio/) provides access to
the [GTEx (Genotype-Tissue Expression)
project](https://gtexportal.org/home/). The skeletal muscle tissue has
one of the largest sample sizes in GTEx (~800 samples), providing highly
stable gene-gene correlations. Known co-expression modules — such as
mitochondrial respiration genes, sarcomere components, and extracellular
matrix genes — are recoverable, making this a biologically rich dataset
for network analysis.

Data preparation code

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

- Select the most variable genes for network construction
- Compute a pairwise gene-gene correlation matrix
- Threshold the correlation matrix into a binary adjacency matrix and
  compute per-gene network statistics (degree, betweenness centrality)
- Detect gene modules/communities in the network using Louvain or
  walktrap algorithms, and summarize per-module statistics (size,
  within-module density)
- Summarize the network: total edge count, mean degree, modularity
  score, hub genes above a connectivity threshold
- Visualize the network as a correlation heatmap with gene clustering,
  or as a force-directed layout colored by module, with top hub genes
  labeled by gene symbol
- Export correlations, network summary, per-node statistics (degree,
  betweenness, module for all genes), hub gene lists, module
  assignments, and per-module summaries to TSV files

**Key parameters:** `n_top`, `cor_method` (pearson/spearman),
`cor_threshold`, `community_method` (louvain/walktrap)

**CLI outputs:** `gene_correlations.tsv`, `network_summary.tsv`,
`hub_genes.tsv`, `module_assignments.tsv`, `node_stats.tsv`,
`module_summary.tsv`

**Shiny inputs:** Correlation threshold slider, method dropdown, n_top
slider, hub gene table, heatmap redraws on threshold change

**Dependencies:** `SummarizedExperiment`, `igraph` (Suggests, for
force-directed layout), `recount3` (data only)

Raw analysis code

``` r
library(SummarizedExperiment)
library(recount3)
library(igraph)
library(ComplexHeatmap)
library(ggplot2)

# --- Load GTEx skeletal muscle data ---
human_projects <- available_projects()
proj <- subset(human_projects, file_source == "gtex" & project == "MUSCLE")
rse <- create_rse(proj)
assay(rse, "counts") <- transform_counts(rse)

# Subset to top 500 variable genes (for tractable pairwise correlations)
vars <- apply(assay(rse, "counts"), 1, var)
keep_genes <- names(sort(vars, decreasing = TRUE))[1:500]

# Subset to 200 random samples
set.seed(42) # Needed for network layout reproducibility
keep_samples <- sample(ncol(rse), min(200, ncol(rse)))
se <- rse[keep_genes, keep_samples]
mat <- log2(assay(se, "counts") + 1)

# --- Remap row identifiers to gene symbols ---
# rowData(rse)$gene_name holds HGNC symbols; fall back to Ensembl ID on NA
gene_symbols <- rowData(se)$gene_name
gene_symbols[is.na(gene_symbols) | gene_symbols == ""] <- rownames(se)[
    is.na(gene_symbols) | gene_symbols == ""
]
rownames(mat) <- make.unique(gene_symbols)  # resolve rare duplicates

# ============================================================================
# Everything above is upstream data preparation — belongs in data-raw/.
# Everything below is core analysis — should be functionized in R/.
# ============================================================================

# --- Pairwise Pearson correlation ---
cor_mat <- cor(t(mat), method = "pearson")

# --- Threshold to adjacency matrix ---
cor_threshold <- 0.7
adj_mat <- (abs(cor_mat) >= cor_threshold) * 1
diag(adj_mat) <- 0

# --- Network statistics via igraph ---
g <- graph_from_adjacency_matrix(adj_mat, mode = "undirected")
deg <- degree(g)
betw <- betweenness(g)

# --- Community/module detection ---
comm <- cluster_louvain(g)
modules <- membership(comm)
modularity_score <- modularity(comm)
cat("Modularity:", round(modularity_score, 3), "\n")
cat("Modules found:", max(modules), "\n")

module_assignments <- data.frame(
    gene   = names(modules),
    module = paste0("M", modules),
    degree = deg[names(modules)]
)

net_summary <- data.frame(
    metric = c("n_genes", "n_edges", "mean_degree",
               "median_degree", "n_hubs_deg20",
               "n_modules", "modularity"),
    value  = c(vcount(g), ecount(g), round(mean(deg), 2),
               median(deg), sum(deg >= 20),
               max(modules), round(modularity_score, 4))
)
print(net_summary)

# Hub genes: top 20 by degree
hub_df <- data.frame(
    gene        = names(deg),
    degree      = deg,
    betweenness = betw,
    module      = paste0("M", modules[names(deg)])
)
hub_df <- hub_df[order(hub_df$degree, decreasing = TRUE), ]
hub_genes <- head(hub_df, 20)

# --- Correlation heatmap ---
ht <- Heatmap(cor_mat, name = "Pearson r",
              show_row_names = FALSE, show_column_names = FALSE,
              column_title = "Gene-Gene Correlation (top 500 genes)")
draw(ht)

# --- Force-directed network graph (hub-focused subgraph) ---
# Subset to top 80 hub genes to keep layout readable
hub_names <- head(hub_df$gene, 80)
g_sub <- induced_subgraph(g, vids = hub_names)

# Module membership and degree for the subgraph
V(g_sub)$module   <- as.character(modules[V(g_sub)$name])
V(g_sub)$degree   <- degree(g_sub)
V(g_sub)$is_top20 <- V(g_sub)$name %in% hub_genes$gene

# Layout 
layout_fr <- layout_with_fr(g_sub)

# Build a ggplot-friendly data frame from the igraph layout
node_df <- data.frame(
    gene        = V(g_sub)$name,   # gene symbol (or Ensembl fallback)
    x           = layout_fr[, 1],
    y           = layout_fr[, 2],
    degree      = V(g_sub)$degree,
    module      = paste0("M", V(g_sub)$module),
    is_hub      = V(g_sub)$is_top20,
    stringsAsFactors = FALSE
)

edge_list <- as_edgelist(g_sub)
edge_df <- data.frame(
    x    = layout_fr[match(edge_list[, 1], V(g_sub)$name), 1],
    y    = layout_fr[match(edge_list[, 1], V(g_sub)$name), 2],
    xend = layout_fr[match(edge_list[, 2], V(g_sub)$name), 1],
    yend = layout_fr[match(edge_list[, 2], V(g_sub)$name), 2]
)

p_net <- ggplot() +
    geom_segment(data = edge_df,
                 aes(x = x, y = y, xend = xend, yend = yend),
                 color = "grey75", linewidth = 0.25, alpha = 0.5) +
    geom_point(data = node_df,
               aes(x = x, y = y, size = degree, color = module),
               alpha = 0.85) +
    geom_label(data = subset(node_df, is_hub),
               aes(x = x, y = y, label = gene),
               size = 2.5, label.padding = unit(0.15, "lines"),
               label.size = 0.2, alpha = 0.85) +
    scale_size_continuous(range = c(2, 8), name = "Degree") +
    scale_color_brewer(palette = "Set2", name = "Module") +
    theme_void() +
    labs(title = "Hub Gene Co-expression Network",
         subtitle = paste0("Top 80 genes by degree | cor threshold = ",
                           cor_threshold,
                           " | Louvain modules = ", max(modules)))
print(p_net)

# --- Export ---
output_dir <- file.path(tempdir(), "network_output")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# Write top correlations (flattened, filtered to |r| >= threshold)
# rownames are gene symbols after the remap above
upper_idx <- which(upper.tri(cor_mat) & abs(cor_mat) >= cor_threshold,
                   arr.ind = TRUE)
cor_edges <- data.frame(
    gene1       = rownames(cor_mat)[upper_idx[, 1]],
    gene2       = colnames(cor_mat)[upper_idx[, 2]],
    correlation = cor_mat[upper_idx]
)
write.table(cor_edges, file.path(output_dir, "gene_correlations.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)
write.table(net_summary, file.path(output_dir, "network_summary.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)
write.table(hub_genes, file.path(output_dir, "hub_genes.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)
write.table(module_assignments, file.path(output_dir, "module_assignments.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)

# All-node statistics (degree + betweenness + module for every gene)
node_stats <- data.frame(
    gene        = names(deg),
    degree      = deg,
    betweenness = betw,
    module      = paste0("M", modules[names(deg)])
)
node_stats <- node_stats[order(node_stats$degree, decreasing = TRUE), ]
write.table(node_stats, file.path(output_dir, "node_stats.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)

# Per-module summary: size, mean degree, mean betweenness
mod_summary <- do.call(rbind, lapply(unique(node_stats$module), function(m) {
    sub <- node_stats[node_stats$module == m, ]
    data.frame(
        module          = m,
        n_genes         = nrow(sub),
        mean_degree     = round(mean(sub$degree), 2),
        mean_betweenness = round(mean(sub$betweenness), 2),
        top_hub         = sub$gene[which.max(sub$degree)]
    )
}))
mod_summary <- mod_summary[order(mod_summary$n_genes, decreasing = TRUE), ]
write.table(mod_summary, file.path(output_dir, "module_summary.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)

list.files(output_dir)
```

------------------------------------------------------------------------

## Project 9: Expression Heatmap Builder

**Rationale:** The genes-by-samples heatmap is one of the most iconic
figures in genomics. Building one from scratch — row scaling,
hierarchical clustering of both axes, sample metadata annotation bars —
requires integrating several analysis steps into a single
publication-quality visualization.

### Dataset: Fission yeast stress response (*S. pombe* RNA-seq)

The [`fission` Bioconductor
package](https://bioconductor.org/packages/fission) provides RNA-seq
count data for 36 *Schizosaccharomyces pombe* samples from [Rhind et
al. (2011)](https://pubmed.ncbi.nlm.nih.gov/21511999/). Cells were
sampled at six time points (0, 15, 30, 60, 120, 180 minutes) following
oxidative stress treatment, across two genetic backgrounds: wild-type
and an atf21Δ mutant that knocks out a key stress-response transcription
factor. The mutant completely fails to mount the normal transcriptional
response, producing a dramatic, biologically interpretable separation
between `wt` and `mut` columns in unsupervised clustering — gene modules
corresponding to early-response, sustained-response, and housekeeping
genes are immediately visible.

In this case, you wouldn’t really have to prepare the data yourself or
include it in your package - it’s already readily available in the
format you need. But for the sake of the exercise, go ahead and save it
as an internal dataset in your package. This will give you practice with
packaging and documenting data, even if it’s not strictly necessary for
this particular dataset.

Data preparation code

``` r
## data-raw/example_se.R
BiocManager::install("fission")
library(fission)
library(SummarizedExperiment)

data(fission)

# fission is already a SummarizedExperiment with counts and colData
example_se <- fission

usethis::use_data(example_se, overwrite = TRUE)
```

**Data structure:** `SummarizedExperiment`

**What users should be able to do:**

- Select the most variable genes
- Row-scale the expression matrix (z-score or min-max normalization)
- Perform k-means clustering on rows (genes) directly inside the
  [`Heatmap()`](https://rdrr.io/pkg/ComplexHeatmap/man/Heatmap.html)
  call and extract the resulting module assignments post-draw
- Generate a genes × samples heatmap with k-means row splits, column
  annotation bars from sample metadata (`strain`, `minute`), and column
  splits by strain
- Export the scaled expression matrix, per-gene module assignments (long
  format), and per-module gene lists with gene counts (wide format) to
  TSV files

**Key parameters:** `n_top`, `scale_method` (zscore/minmax/none),
`gene_k`, `column_split_by` (metadata column)

**CLI outputs:** `scaled_expression.tsv`, `gene_modules.tsv`,
`module_gene_lists.tsv`

**Shiny inputs:** n_top slider, scale method dropdown, gene_k slider,
metadata column selector for annotation and column splitting, heatmap
updates reactively

**Dependencies:** `SummarizedExperiment`, `ComplexHeatmap` (Suggests),
`fission` (data only)

Raw analysis code

``` r
library(fission)
library(SummarizedExperiment)
library(ComplexHeatmap)

# --- Load fission yeast data ---
data(fission)
mat    <- assay(fission, "counts")
strain <- fission$strain   # wt / mut
minute <- fission$minute   # 0, 15, 30, 60, 120, 180

# ============================================================================
# Everything above is upstream data preparation — belongs in data-raw/.
# Everything below is core analysis — should be functionized in R/.
# ============================================================================

# --- Log-normalize counts (log2-CPM) ---
# This reduces the dynamic range and makes the scaling more interpretable
lib_sizes  <- colSums(mat)
mat_norm   <- log2(t(t(mat) / lib_sizes * 1e6) + 1)

# --- Select top 500 most variable genes ---
gene_vars  <- apply(mat_norm, 1, var)
top_genes  <- names(sort(gene_vars, decreasing = TRUE))[1:500]
mat_top    <- mat_norm[top_genes, ]

# --- Z-score row scaling ---
mat_scaled <- t(scale(t(mat_top)))  # z-score each gene across samples

# --- Annotated heatmap with k-means row clustering ---
gene_k <- 5

# Explicit color palettes for each annotation track
strain_colors <- c(wt  = "#027a2a", mut = "#a50181")

minute_colors <- c("0"   = "#a1a1a0",
                   "15"  = "#FDCC8A",
                   "30"  = "#FC8D59",
                   "60"  = "#E34A33",
                   "120" = "#B30000",
                   "180" = "#7A0000")

# One color per k-means module (length must equal gene_k)
module_colors <- c("#3C5488", "#00A087", "#ffee01", "#f80404", "#00e1ff")

col_anno <- HeatmapAnnotation(
    strain = strain,
    minute = as.character(minute),
    na_col = "grey90",
    col    = list(strain = strain_colors,
                  minute = minute_colors)
)

# Left annotation block: colors each k-means split and labels it M1–M5
row_anno <- rowAnnotation(
    module = anno_block(
        gp        = gpar(fill = module_colors),
        labels    = paste0("M", seq_len(gene_k)),
        labels_gp = gpar(col = "white", fontsize = 10)
    )
)

ht <- Heatmap(mat_scaled, name = "Z-score",
              top_annotation    = col_anno,
              left_annotation   = row_anno,
              row_km            = gene_k,   # k-means on rows inside the heatmap
              column_split      = strain,
              show_row_names    = FALSE,
              show_column_names = FALSE,
              column_title      = "Fission Yeast Stress Response (top 500 genes)")
ht_drawn <- draw(ht)

# --- Extract k-means module assignments from the drawn heatmap ---
row_clusters <- row_order(ht_drawn)   # named list: one element per k-means group
gene_modules <- integer(nrow(mat_scaled))
for (i in seq_along(row_clusters)) {
    gene_modules[row_clusters[[i]]] <- i
}
names(gene_modules) <- rownames(mat_scaled)

module_df <- data.frame(
    gene   = names(gene_modules),
    module = paste0("M", gene_modules)
)

# --- Export ---
output_dir <- file.path(tempdir(), "heatmap_output")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

scaled_out       <- as.data.frame(mat_scaled)
scaled_out$gene  <- rownames(mat_scaled)
write.table(scaled_out, file.path(output_dir, "scaled_expression.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)

# Per-gene module assignments (long format: one row per gene)
write.table(module_df, file.path(output_dir, "gene_modules.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)

# Per-module gene lists (wide format: one row per module, genes comma-separated)
module_gene_list <- do.call(rbind, lapply(sort(unique(module_df$module)), function(m) {
    genes <- module_df$gene[module_df$module == m]
    data.frame(module   = m,
               n_genes  = length(genes),
               genes    = paste(genes, collapse = ","),
               stringsAsFactors = FALSE)
}))
write.table(module_gene_list, file.path(output_dir, "module_gene_lists.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)

list.files(output_dir)
```

------------------------------------------------------------------------

## Project 10: Dimensionality Estimation Tool

**Rationale:** Determining the meaningful number of principal components
after PCA is a common task. Use too many and you’re effectively
including noise; use too few and you may miss real variation. The
broken-stick model, Kaiser criterion, and elbow heuristic each encode
different assumptions. Looking at these metrics can help users determine
the number of principal components to retain for downstream analyses
like additional dimensionality reduction (e.g., t-SNE, UMAP) and
clustering.

### Dataset: PBMC 3k (Human scRNA-seq)

The 10X Genomics PBMC 3k dataset (~2,700 peripheral blood mononuclear
cells) is the canonical Seurat tutorial dataset. It contains ~10 immune
cell types (T cells, B cells, NK cells, monocytes, dendritic cells), and
the meaningful number of PCs is unknown.

Data preparation code

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

**Dependencies:** `SingleCellExperiment`, `scuttle`, `TENxPBMCData`
(data only)

Raw analysis code

``` r
library(SingleCellExperiment)
library(TENxPBMCData)
library(scuttle)
library(ggplot2)
library(matrixStats)

# --- Load data ---
sce <- TENxPBMCData("pbmc3k")
counts_mat <- counts(sce)

# --- Log-normalize using scuttle ---
# Normalize on the full SCE so size factors reflect the complete library
sce <- logNormCounts(sce)

# ============================================================================
# Everything above is upstream data preparation — belongs in data-raw/.
# Everything below is core analysis — should be functionized in R/.
# ============================================================================

# --- Feature selection: top 2000 most variable genes ---
gene_vars <- rowVars(counts_mat)
top_idx <- order(gene_vars, decreasing = TRUE)[seq_len(2000)]
mat_norm <- as.matrix(logcounts(sce)[top_idx, ])

# --- PCA ---
pca <- prcomp(t(mat_norm), scale. = TRUE, center = TRUE)
max_pcs <- min(50, ncol(pca$x))
eigenvalues <- pca$sdev[1:max_pcs]^2
var_pct <- eigenvalues / sum(pca$sdev^2) * 100
cum_var <- cumsum(var_pct)

eigenvalue_df <- data.frame(
    PC         = seq_len(max_pcs),
    eigenvalue = eigenvalues,
    var_pct    = var_pct,
    cum_var    = cum_var
)

# --- Broken-stick model ---
bs_vals <- numeric(max_pcs)
for (i in seq_len(max_pcs)) bs_vals[i] <- sum(1 / (i:max_pcs))
bs_vals <- bs_vals / max_pcs * 100  # as percentage of total

# --- Kaiser criterion: eigenvalue > mean eigenvalue ---
kaiser_threshold <- mean(eigenvalues)
kaiser_n <- sum(eigenvalues > kaiser_threshold)

# --- Elbow heuristic: largest drop between consecutive PCs ---
diffs <- -diff(eigenvalues)
elbow_n <- which.max(diffs)

# --- Estimates ---
bs_n <- sum(var_pct > bs_vals)
estimates <- data.frame(
    method   = c("broken_stick", "kaiser", "elbow"),
    n_dims   = c(bs_n, kaiser_n, elbow_n),
    criterion = c("var% > broken-stick%",
                  paste0("eigenvalue > ", round(kaiser_threshold, 2)),
                  paste0("largest drop at PC", elbow_n))
)
print(estimates)

# --- Scree plot with overlays ---
plot_df <- data.frame(
    PC = seq_len(max_pcs),
    observed = var_pct,
    broken_stick = bs_vals
)
p <- ggplot(plot_df, aes(x = PC)) +
    geom_line(aes(y = observed), color = "black", linewidth = 1) +
    geom_point(aes(y = observed), size = 2) +
    geom_line(aes(y = broken_stick), color = "red", lty = 2) +
    geom_hline(yintercept = mean(var_pct), color = "blue", lty = 3) +
    geom_vline(xintercept = elbow_n, color = "darkgreen", lty = 4) +
    annotate("text", x = max_pcs * 0.7, y = max(var_pct) * 0.9,
             label = paste0("Broken-stick: ", bs_n, " PCs\n",
                            "Kaiser: ", kaiser_n, " PCs\n",
                            "Elbow: ", elbow_n, " PCs"),
             hjust = 0, size = 4) +
    theme_bw(base_size = 14) +
    labs(x = "Principal Component", y = "Variance Explained (%)",
         title = "Scree Plot with Dimensionality Estimates")
print(p)

# --- Export ---
output_dir <- file.path(tempdir(), "dim_output")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

write.table(eigenvalue_df, file.path(output_dir, "eigenvalues.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)
write.table(estimates, file.path(output_dir, "dimension_estimates.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)

list.files(output_dir)
```

------------------------------------------------------------------------

## Project 11: Batch Effect Assessment

**Rationale:** Batch effects (systematic technical variation from
processing date, lane, or operator) can muddy biological signal.
Quantifying how much variance each PC attributes to batch (via linear
regression R²) is a common diagnostic before deciding whether batch
correction or modeling is needed.

This analysis takes several minutes to run.

### Dataset: Tasic + Zeisel Mouse Brain (Mouse scRNA-seq, two technologies)

The `scRNAseq` package provides two independent mouse brain single-cell
datasets: [Zeisel et
al. (2015)](https://pubmed.ncbi.nlm.nih.gov/25700174/) (~3,000 cells
from mouse cortex and hippocampus sequenced with STRT-seq) and [Tasic et
al. (2016)](https://pubmed.ncbi.nlm.nih.gov/26727548/) (~1,800 cells
from mouse primary visual cortex sequenced with SMART-Seq v4). Both
datasets profile overlapping cell types — excitatory neurons, inhibitory
neurons, astrocytes, oligodendrocytes, and microglia — but the dramatic
technology difference (STRT-seq vs SMART-Seq) creates a textbook-visible
batch effect: PCA before correction separates cells almost entirely by
dataset rather than by cell type. After `fastMNN` correction the
cell-type signal dominates, providing an unambiguous before/after
demonstration. The datasets share thousands of common genes and load
with single function calls from `scRNAseq`.

Data preparation code

``` r
## data-raw/example_sce.R
library(scRNAseq)
library(SingleCellExperiment)
library(scuttle)
library(batchelor)

sce_z <- ZeiselBrainData()
sce_t <- TasicBrainData()

# QC: remove low-quality cells using mitochondrial gene percentage
# Note: mito gene prefix differs between the two datasets
sce_z <- addPerCellQC(sce_z, subsets = list(Mito = grep("mt-", rownames(sce_z))))
qc_z  <- quickPerCellQC(colData(sce_z), sub.fields = "subsets_Mito_percent")
sce_z <- sce_z[, !qc_z$discard]

sce_t <- addPerCellQC(sce_t, subsets = list(Mito = grep("mt_", rownames(sce_t))))
qc_t  <- quickPerCellQC(colData(sce_t), sub.fields = "subsets_Mito_percent")
sce_t <- sce_t[, !qc_t$discard]

# Subset to the common set of genes
universe <- intersect(rownames(sce_z), rownames(sce_t))
sce_z    <- sce_z[universe, ]
sce_t    <- sce_t[universe, ]

# Cross-batch normalization: downscale to the least-sequenced batch
out   <- multiBatchNorm(sce_z, sce_t)
sce_z <- out[[1]]
sce_t <- out[[2]]

# Save cell-type labels before replacing colData
ct_z <- as.character(sce_z$level1class)
ct_t <- as.character(sce_t$broad_type)

# Unify cell-type vocabulary across the two datasets so matching types share
# the same label and colour in downstream plots.
# Zeisel uses lowercase/underscore conventions; Tasic uses title case.
ct_map_z <- c(
    "pyramidal CA1"        = "Excitatory Neuron",
    "pyramidal SS"         = "Excitatory Neuron",
    "interneurons"         = "Inhibitory Neuron",
    "oligodendrocytes"     = "Oligodendrocyte",
    "astrocytes_ependymal" = "Astrocyte",
    "microglia"            = "Microglia",
    "endothelial-mural"    = "Endothelial"
)
ct_map_t <- c(
    "Glutamatergic Neuron" = "Excitatory Neuron",
    "GABA-ergic Neuron"    = "Inhibitory Neuron",
    "Astrocyte"            = "Astrocyte",
    "Oligodendrocyte"      = "Oligodendrocyte",
    "Microglia"            = "Microglia",
    "Endothelial Cell"     = "Endothelial",
    "OPC"                  = "OPC"
)
ct_z <- unname(ct_map_z[ct_z]); ct_z[is.na(ct_z)] <- "Other"
ct_t <- unname(ct_map_t[ct_t]); ct_t[is.na(ct_t)] <- "Other"

# Drop altExps (ERCC spike-ins, repeats) so cbind works without error
altExps(sce_z) <- NULL
altExps(sce_t) <- NULL

# Harmonize colData to two columns used downstream
colData(sce_z) <- DataFrame(batch = "Zeisel", cell_type = ct_z)
colData(sce_t) <- DataFrame(batch = "Tasic",  cell_type = ct_t)

example_sce <- cbind(sce_z, sce_t)

usethis::use_data(example_sce, overwrite = TRUE)
```

**Data structure:** `SingleCellExperiment`

**What users should be able to do:**

- Select highly variable genes jointly across both batches using `scran`
  (`modelGeneVar`, `combineVar`, `getTopHVGs`)
- Quantify batch effects by fitting a linear model of each PC against
  the batch variable and extracting R² values
- Apply batch correction using
  [`fastMNN()`](https://rdrr.io/pkg/batchelor/man/fastMNN.html) from the
  `batchelor` package (mutual nearest-neighbour alignment in PCA space
  across donor batches) and extract the corrected low-dimensional
  embedding
- Visualize dual-panel scatter plots (PCA before vs. MNN-corrected
  embedding after) colored by batch, plus a side-by-side R² bar chart
  comparing batch variance before and after correction
- Export the combined before/after R² table and the corrected embedding
  to TSV files

**Key parameters:** `batch_column`, `n_top`, `correct` (logical),
`bio_column`

**CLI outputs:** `batch_variance.tsv`, `corrected_embedding.tsv`

**Shiny inputs:** Batch column dropdown, biological column dropdown,
n_top slider, correction toggle, before/after scatter panels, R² bar
chart

**Dependencies:** `SingleCellExperiment`, `batchelor`, `scran`,
`scuttle`, `scRNAseq` (data only)

Raw analysis code

``` r
library(scRNAseq)
library(SingleCellExperiment)
library(scuttle)
library(batchelor)
library(scran)
library(ggplot2)
library(patchwork)

set.seed(42)  # For reproducibility of PCA and MNN results

# --- Load both datasets ---
sce_z <- ZeiselBrainData()
sce_t <- TasicBrainData()

# --- QC: remove low-quality cells ---
sce_z <- addPerCellQC(sce_z, subsets = list(Mito = grep("mt-", rownames(sce_z))))
qc_z  <- quickPerCellQC(colData(sce_z), sub.fields = "subsets_Mito_percent")
sce_z <- sce_z[, !qc_z$discard]

sce_t <- addPerCellQC(sce_t, subsets = list(Mito = grep("mt_", rownames(sce_t))))
qc_t  <- quickPerCellQC(colData(sce_t), sub.fields = "subsets_Mito_percent")
sce_t <- sce_t[, !qc_t$discard]

# --- Subset to common genes ---
universe <- intersect(rownames(sce_z), rownames(sce_t))
sce_z    <- sce_z[universe, ]
sce_t    <- sce_t[universe, ]

# --- Cross-batch normalization ---
out   <- multiBatchNorm(sce_z, sce_t)
sce_z <- out[[1]]
sce_t <- out[[2]]

# --- Combine into a single SCE and set batch / cell_type ---
ct_z <- as.character(sce_z$level1class)
ct_t <- as.character(sce_t$broad_type)

# Unify cell-type vocabulary across both datasets
ct_map_z <- c(
    "pyramidal CA1"        = "Excitatory Neuron",
    "pyramidal SS"         = "Excitatory Neuron",
    "interneurons"         = "Inhibitory Neuron",
    "oligodendrocytes"     = "Oligodendrocyte",
    "astrocytes_ependymal" = "Astrocyte",
    "microglia"            = "Microglia",
    "endothelial-mural"    = "Endothelial"
)
ct_map_t <- c(
    "Glutamatergic Neuron" = "Excitatory Neuron",
    "GABA-ergic Neuron"    = "Inhibitory Neuron",
    "Astrocyte"            = "Astrocyte",
    "Oligodendrocyte"      = "Oligodendrocyte",
    "Microglia"            = "Microglia",
    "Endothelial Cell"     = "Endothelial",
    "OPC"                  = "OPC"
)
ct_z <- unname(ct_map_z[ct_z]); ct_z[is.na(ct_z)] <- "Other"
ct_t <- unname(ct_map_t[ct_t]); ct_t[is.na(ct_t)] <- "Other"

altExps(sce_z) <- NULL
altExps(sce_t) <- NULL

colData(sce_z) <- DataFrame(batch = "Zeisel", cell_type = ct_z)
colData(sce_t) <- DataFrame(batch = "Tasic",  cell_type = ct_t)

sce_all   <- cbind(sce_z, sce_t)
batch     <- sce_all$batch
cell_type <- sce_all$cell_type

# ============================================================================
# Everything above is upstream data preparation — belongs in data-raw/.
# Everything below is core analysis — should be functionized in R/.
# ============================================================================

# --- HVG selection: model gene variance per batch, combine, pick top 5000 ---
dec_z        <- modelGeneVar(sce_z)
dec_t        <- modelGeneVar(sce_t)
combined_dec <- combineVar(dec_z, dec_t)
chosen_hvgs  <- getTopHVGs(combined_dec, n = 5000)
cat("HVGs selected:", length(chosen_hvgs), "\n")

# --- PCA (before correction) on log-normalized HVGs ---
mat_all    <- as.matrix(logcounts(sce_all)[chosen_hvgs, ])
pca_before <- prcomp(t(mat_all), scale. = TRUE, center = TRUE)
n_pcs <- 10

# --- Quantify batch effect: R² of each PC ~ batch ---
r2_df <- data.frame(PC = paste0("PC", 1:n_pcs), R2 = NA_real_)
for (i in 1:n_pcs) {
    fit        <- lm(pca_before$x[, i] ~ batch)
    r2_df$R2[i] <- summary(fit)$r.squared
}
print(r2_df)

# --- Batch correction ---
out_mnn        <- fastMNN(sce_all, batch = sce_all$batch, subset.row = chosen_hvgs)
corrected_embed <- reducedDim(out_mnn, "corrected")  # cells × 50 matrix

# --- Quantify residual batch effect in the corrected embedding ---
n_dims      <- min(n_pcs, ncol(corrected_embed))
r2_after_df <- data.frame(dim = paste0("dim", seq_len(n_dims)), R2 = NA_real_)
for (i in seq_len(n_dims)) {
    fit               <- lm(corrected_embed[, i] ~ batch)
    r2_after_df$R2[i] <- summary(fit)$r.squared
}

# Combine before/after R²
r2_compare <- rbind(
    data.frame(dim = r2_df$PC,        R2 = r2_df$R2,       stage = "before"),
    data.frame(dim = r2_after_df$dim, R2 = r2_after_df$R2, stage = "after")
)
# Order dimensions numerically (PC1–PC10 / dim1–dim10) and set stage order
dim_order <- paste0(c(rep("PC", n_pcs), rep("dim", n_dims)),
                    c(seq_len(n_pcs), seq_len(n_dims)))
dim_order <- unique(dim_order[order(as.integer(sub("\\D+", "", dim_order)))])
r2_compare$dim   <- factor(r2_compare$dim,   levels = dim_order)
r2_compare$stage <- factor(r2_compare$stage, levels = c("before", "after"))
print(r2_compare)

# --- Before/after scatter plots ---
df_before <- data.frame(x = pca_before$x[, 1], y = pca_before$x[, 2],
                         batch = batch, cell_type = cell_type)
df_after  <- data.frame(x = corrected_embed[, 1], y = corrected_embed[, 2],
                         batch = batch, cell_type = cell_type)

# Row 1: colored by batch — reveals the technical confound
p1 <- ggplot(df_before, aes(x = x, y = y, color = batch)) +
    geom_point(size = 0.8, alpha = 0.5) +
    theme_bw(base_size = 12) +
    labs(x = "PC1", y = "PC2", title = "Before — colored by batch",
         subtitle = "Cells separate by technology")
p2 <- ggplot(df_after, aes(x = x, y = y, color = batch)) +
    geom_point(size = 0.8, alpha = 0.5) +
    theme_bw(base_size = 12) +
    labs(x = "MNN dim 1", y = "MNN dim 2", title = "After — colored by batch",
         subtitle = "Batch signal is reduced")

# Row 2: colored by cell type — shows the biological signal that emerges
p3 <- ggplot(df_before, aes(x = x, y = y, color = cell_type)) +
    geom_point(size = 0.8, alpha = 0.5) +
    theme_bw(base_size = 12) +
    labs(x = "PC1", y = "PC2", title = "Before — colored by cell type",
         subtitle = "Cell types mixed across batch clusters")
p4 <- ggplot(df_after, aes(x = x, y = y, color = cell_type)) +
    geom_point(size = 0.8, alpha = 0.5) +
    theme_bw(base_size = 12) +
    labs(x = "MNN dim 1", y = "MNN dim 2", title = "After — colored by cell type",
         subtitle = "Cell-type signal dominates")

# Row 3: R² bar chart
r2_compare$dim_num <- as.integer(sub("\\D+", "", as.character(r2_compare$dim)))

p_r2 <- ggplot(r2_compare, aes(x = dim_num, y = R2, fill = stage)) +
    geom_col(position = position_dodge(0.8), width = 0.7) +
    scale_x_continuous(breaks = seq_len(n_pcs), labels = seq_len(n_pcs)) +
    scale_fill_manual(values = c(before = "#fcc100", after = "#00b5dd")) +
    theme_bw(base_size = 12) +
    labs(x = "Dimension", y = expression(R^2 ~ "(batch)"),
         fill = NULL,
         title = "Batch Variance Before vs After fastMNN")

(p1 + p2) / (p3 + p4) / p_r2

# --- Export ---
output_dir <- file.path(tempdir(), "batch_output")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

write.table(r2_compare, file.path(output_dir, "batch_variance.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)

corrected_out           <- as.data.frame(corrected_embed)
corrected_out$cell      <- colnames(sce_all)
corrected_out$batch     <- batch
corrected_out$cell_type <- cell_type
write.table(corrected_out, file.path(output_dir, "corrected_embedding.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)

list.files(output_dir)
```

------------------------------------------------------------------------

## Project 12: Marker Gene Identification

**Rationale:** After clustering samples in scRNA-seq data, identifying
the genes that best distinguish each cluster from the others.
One-vs-rest testing produces ranked marker lists that help you assign a
cell type or state to each cluster (e.g. T cells, monocytes, B cells,
etc). This task often requires manual review, expert knowledge, and some
literature searching to validate the markers against known biology. The
dot plot (size = detection rate, color = mean expression) is a common
way to summarize marker expression patterns across clusters or cell
types.

This code takes a few minutes to run, single cell analysis is
computationally expensive.

### Dataset: Baron Mouse Pancreas (Mouse scRNA-seq)

The [Baron et al. (2016) mouse pancreatic islet
dataset](https://pubmed.ncbi.nlm.nih.gov/27667365/) contains ~1,886
cells across 9 clearly defined cell types: alpha, beta, delta, gamma
(PP), acinar, ductal, stellate (activated and quiescent), immune, and
Schwann cells. Each cell type has well-known marker genes (e.g.,
*Ins1*/*Ins2* for beta cells, *Gcg* for alpha cells), enabling a sanity
check for what’s returned.

Note: this is the **mouse** version — Project 4 uses the human dataset
from the same study, so code cannot be directly shared.

Data preparation code

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

**Dependencies:** `SingleCellExperiment`, `scuttle`, `scRNAseq` (data
only)

Raw analysis code

``` r
library(SingleCellExperiment)
library(scRNAseq)
library(scuttle)
library(ggplot2)

# --- Load data ---
sce <- BaronPancreasData("mouse")
counts_mat <- counts(sce)
cell_type <- colData(sce)$label

# ============================================================================
# Everything above is upstream data preparation — belongs in data-raw/.
# Everything below is core analysis — should be functionized in R/.
# ============================================================================

# --- Filter genes detected in < 5% of cells ---
detect_rate_all <- rowSums(counts_mat > 0) / ncol(counts_mat)
keep_genes <- detect_rate_all >= 0.05
sce <- sce[keep_genes, ]
counts_mat <- counts(sce)
cat("Genes after filtering:", nrow(sce), "\n")

# --- Log-normalize using scuttle ---
sce <- logNormCounts(sce)
mat_norm <- as.matrix(logcounts(sce))

# --- One-vs-rest Wilcoxon testing per cell type ---
cell_types <- unique(cell_type)
n_markers <- 5

marker_list <- lapply(cell_types, function(ct) {
    is_target <- cell_type == ct
    # Log2 fold change: mean(target) - mean(rest)
    mean_target <- rowMeans(mat_norm[, is_target, drop = FALSE])
    mean_rest   <- rowMeans(mat_norm[, !is_target, drop = FALSE])
    log2fc <- mean_target - mean_rest

    # Detection rate in target vs rest
    detect_target <- rowSums(counts_mat[, is_target, drop = FALSE] > 0) / sum(is_target)
    detect_rest   <- rowSums(counts_mat[, !is_target, drop = FALSE] > 0) / sum(!is_target)

    # Wilcoxon rank-sum test (subset of genes for speed)
    pvals <- sapply(seq_len(nrow(mat_norm)), function(i) {
        wilcox.test(mat_norm[i, is_target], mat_norm[i, !is_target],
                    alternative = "greater")$p.value
    })

    data.frame(
        gene         = rownames(mat_norm),
        cell_type    = ct,
        log2fc       = log2fc,
        detect_target = detect_target,
        detect_rest  = detect_rest,
        pvalue       = pvals,
        padj         = p.adjust(pvals, method = "BH"),
        stringsAsFactors = FALSE
    )
})
all_markers <- do.call(rbind, marker_list)

# --- Select top N markers per cell type ---
top_markers <- do.call(rbind, lapply(cell_types, function(ct) {
    sub <- all_markers[all_markers$cell_type == ct, ]
    sub <- sub[order(sub$log2fc, decreasing = TRUE), ]
    head(sub, n_markers)
}))

# --- Summary: overlap counts between groups ---
marker_summary <- data.frame(
    cell_type   = cell_types,
    n_sig       = sapply(cell_types, function(ct) {
        sum(all_markers$cell_type == ct & all_markers$padj < 0.05 &
            all_markers$log2fc > 1)
    }),
    top_marker  = sapply(cell_types, function(ct) {
        sub <- all_markers[all_markers$cell_type == ct, ]
        sub$gene[which.max(sub$log2fc)]
    })
)

# --- Dot plot ---
# gene ordering: use the unique marker genes in their natural ranking order
gene_levels <- unique(as.character(top_markers$gene))
ct_levels   <- as.character(cell_types)

# Pull every (gene x cell_type) row from all_markers for the selected genes
# detect_target here is the detection rate of that gene *within* that cell type
plot_df <- all_markers[all_markers$gene %in% gene_levels, ]

# Add mean expression per (gene, cell_type) combination
plot_df$mean_expr <- mapply(function(g, ct) {
    mean(as.numeric(mat_norm[g, cell_type == ct]))
}, plot_df$gene, plot_df$cell_type)

plot_df$gene      <- factor(plot_df$gene,      levels = rev(gene_levels))
plot_df$cell_type <- factor(plot_df$cell_type, levels = ct_levels)

p <- ggplot(plot_df, aes(x = cell_type, y = gene,
                          size = detect_target, color = mean_expr)) +
    geom_point() +
    scale_size_continuous(range = c(1, 6), name = "Detection Rate") +
    scale_color_viridis_c(name = "Mean Expression") +
    theme_bw(base_size = 12) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    labs(title = "Top Marker Genes per Cell Type")
print(p)

# --- Export ---
output_dir <- file.path(tempdir(), "marker_output")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

write.table(all_markers, file.path(output_dir, "marker_genes.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)
write.table(marker_summary, file.path(output_dir, "marker_summary.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)

list.files(output_dir)
```

------------------------------------------------------------------------

## Quick Comparison

| \#  | Project                 | Dataset                       | Organism   | Structure | Primary Plot              | Extra Deps              |
|-----|-------------------------|-------------------------------|------------|-----------|---------------------------|-------------------------|
| 1   | UMAP Embedding          | Zeisel brain                  | Mouse      | SCE       | 2D scatter                | uwot                    |
| 2   | Sample Similarity       | Macrophage stimulation        | Human      | SE        | heatmap + dendrogram      | —                       |
| 3   | Differential Expression | Tissue Tregs (Treg vs Tconv)  | Mouse      | SE        | volcano / MA              | DESeq2                  |
| 4   | K-means Clustering      | Baron human pancreas          | Human      | SCE       | scatter + elbow           | cluster                 |
| 5   | Cell QC Dashboard       | Lun spike-in                  | Mouse      | SCE       | multi-panel               | —                       |
| 6   | Gene Set Scoring        | airway + MSigDB               | Human      | SE        | boxplot / violin          | msigdbr, airway         |
| 7   | Normalization           | Muraro pancreas               | Human      | SCE       | density / boxplot         | —                       |
| 8   | Gene Corr Network       | GTEx skeletal muscle          | Human      | SE        | network / heatmap         | igraph (opt.), recount3 |
| 9   | Expression Heatmap      | Fission yeast stress response | *S. pombe* | SE        | genes × samples heatmap   | ComplexHeatmap, fission |
| 10  | Dim Estimation          | PBMC 3k                       | Human      | SCE       | scree + overlays          | —                       |
| 11  | Batch Effect            | Tasic + Zeisel brain          | Mouse      | SCE       | before/after scatter + R² | batchelor               |
| 12  | Marker Genes            | Baron mouse pancreas          | Mouse      | SCE       | dot plot                  | —                       |

- **12 unique datasets** — all **human or mouse**, all **RNA-seq or
  scRNA-seq**
- **8 single-cell** (SCE) + **4 bulk** (SE) projects
- No two projects share both the same computation **and** visualization

------------------------------------------------------------------------

## Custom Projects

You are welcome to propose your own project of similar scope. To be
approved, your proposal must include:

1.  **One paragraph** describing the biological or analytical rationale
2.  **A dataset** with a `data-raw/` script showing how to prepare the
    example data
3.  **A capability list** describing what users should be able to do
    with the package (4–6 bullet points)
4.  **At least one non-trivial visualization** (not just a base R
    [`plot()`](https://rdrr.io/r/graphics/plot.default.html) call)
5.  **CLI outputs** — what TSV/plot files will be produced?
6.  **Shiny inputs** — what will the user be able to adjust?

Submit your proposal as a GitHub Issue or by email **before starting
implementation**. The instructor will respond within 48 hours with
approval or suggested modifications.

**Ground rules for custom projects:**

- Must operate on `SummarizedExperiment` or `SingleCellExperiment` input
- Must use a real dataset; RNA-seq or scRNA-seq preferred
- Must produce at least one `ggplot`-based visualization
- Must not duplicate an existing project from the list above
- Scope should be comparable
