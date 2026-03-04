# data-raw/example_se.R
# Script to create the example_se dataset shipped with the package.

library(SummarizedExperiment)

set.seed(42)

# 100 genes, 8 samples
n_genes <- 100
n_samples <- 8

# Simulate counts (Poisson-distributed)
counts <- matrix(
    rpois(n_genes * n_samples, lambda = 100),
    nrow = n_genes,
    ncol = n_samples
)
rownames(counts) <- paste0("gene", seq_len(n_genes))
colnames(counts) <- paste0("sample", seq_len(n_samples))

# Add treatment effect: first 20 genes are 2x higher in treated
treatment <- rep(c("control", "treated"), each = 4)
counts[1:20, treatment == "treated"] <-
    counts[1:20, treatment == "treated"] * 2

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
