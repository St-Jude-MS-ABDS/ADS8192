# Tests for raw analysis code in project-selection.Rmd
# These replicate each project's raw script and verify TSV outputs.
# Requires internet + Bioconductor packages; skipped when packages missing.

# skip_if_not_installed_bioc <- function(pkg) {
#     testthat::skip_if_not_installed(pkg)
# }

# # ── Project 0: PCA Explorer ─────────────────────────────────────────────────
# test_that("Project 0: raw PCA analysis runs and exports correctly", {
#     skip_if_not_installed_bioc("SummarizedExperiment")
#     skip_on_cran()

#     library(SummarizedExperiment)
#     library(ggplot2)

#     data("example_se")

#     mat <- assay(example_se, "counts")
#     vars <- apply(mat, 1, stats::var)
#     top_idx <- order(vars, decreasing = TRUE)[seq_len(500)]
#     se_top <- example_se[top_idx, ]
#     mat <- assay(se_top, "counts")
#     mat <- log2(mat + 1)
#     pca_result <- prcomp(t(mat), scale. = TRUE, center = TRUE)

#     scores <- as.data.frame(pca_result$x)
#     scores$sample_id <- rownames(scores)
#     col_data <- as.data.frame(colData(example_se))
#     col_data$sample_id <- rownames(col_data)
#     scores <- merge(scores, col_data, by = "sample_id")
#     scores <- scores[order(scores$sample_id), ]

#     var_explained <- pca_result$sdev^2 / sum(pca_result$sdev^2) * 100
#     var_df <- data.frame(PC = paste0("PC", seq_along(var_explained)),
#                          variance_percent = var_explained)

#     # PCA plot
#     p <- ggplot(scores, aes(x = .data[["PC1"]], y = .data[["PC2"]])) +
#         geom_point(aes(color = .data[["treatment"]]), size = 4) +
#         theme_bw()
#     expect_s3_class(p, "ggplot")

#     # Export
#     output_dir <- file.path(tempdir(), "test_p0_raw")
#     dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
#     write.table(scores, file.path(output_dir, "pca_scores.tsv"),
#                 sep = "\t", row.names = FALSE, quote = FALSE)
#     write.table(var_df, file.path(output_dir, "pca_variance.tsv"),
#                 sep = "\t", row.names = FALSE, quote = FALSE)

#     expect_true(file.exists(file.path(output_dir, "pca_scores.tsv")))
#     expect_true(file.exists(file.path(output_dir, "pca_variance.tsv")))

#     scores_back <- read.table(file.path(output_dir, "pca_scores.tsv"),
#                               header = TRUE, sep = "\t")
#     expect_gt(nrow(scores_back), 0)
#     expect_true("PC1" %in% colnames(scores_back))
#     expect_true("sample_id" %in% colnames(scores_back))

#     var_back <- read.table(file.path(output_dir, "pca_variance.tsv"),
#                            header = TRUE, sep = "\t")
#     expect_gt(nrow(var_back), 0)
#     expect_true("variance_percent" %in% colnames(var_back))
#     expect_equal(sum(var_back$variance_percent), 100, tolerance = 0.01)

#     unlink(output_dir, recursive = TRUE)
# })

# # ── Project 1: UMAP Embedding ───────────────────────────────────────────────
# test_that("Project 1: raw UMAP analysis runs and exports correctly", {
#     skip_if_not_installed_bioc("scRNAseq")
#     skip_if_not_installed_bioc("SingleCellExperiment")
#     skip_if_not_installed("uwot")
#     skip_on_cran()

#     library(SingleCellExperiment)
#     library(scRNAseq)
#     library(uwot)

#     sce <- ZeiselBrainData()
#     counts_mat <- as.matrix(counts(sce))
#     cell_type <- colData(sce)$level1class

#     gene_vars <- apply(counts_mat, 1, var)
#     top_idx <- order(gene_vars, decreasing = TRUE)[seq_len(2000)]
#     mat <- counts_mat[top_idx, ]

#     lib_sizes <- colSums(counts_mat)
#     mat_norm <- log2(t(t(mat) / lib_sizes * 1e6) + 1)

#     set.seed(42)
#     umap_coords <- umap(t(mat_norm), n_neighbors = 15, min_dist = 0.1,
#                         metric = "euclidean", n_components = 2)

#     embeddings <- data.frame(
#         cell_id = colnames(sce), UMAP1 = umap_coords[, 1],
#         UMAP2 = umap_coords[, 2], cell_type = cell_type
#     )
#     params <- data.frame(
#         parameter = c("n_neighbors", "min_dist", "metric", "n_genes", "n_cells"),
#         value     = c(15, 0.1, "euclidean", nrow(mat), ncol(mat))
#     )

#     output_dir <- file.path(tempdir(), "test_p1_raw")
#     dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
#     write.table(embeddings, file.path(output_dir, "umap_embeddings.tsv"),
#                 sep = "\t", row.names = FALSE, quote = FALSE)
#     write.table(params, file.path(output_dir, "umap_params.tsv"),
#                 sep = "\t", row.names = FALSE, quote = FALSE)

#     expect_true(file.exists(file.path(output_dir, "umap_embeddings.tsv")))
#     expect_true(file.exists(file.path(output_dir, "umap_params.tsv")))

#     emb_back <- read.table(file.path(output_dir, "umap_embeddings.tsv"),
#                            header = TRUE, sep = "\t")
#     expect_equal(nrow(emb_back), ncol(sce))
#     expect_true(all(c("UMAP1", "UMAP2", "cell_type") %in% colnames(emb_back)))

#     unlink(output_dir, recursive = TRUE)
# })

# # ── Project 2: Sample Similarity ────────────────────────────────────────────
# test_that("Project 2: raw similarity analysis runs and exports correctly", {
#     skip_if_not_installed_bioc("macrophage")
#     skip_if_not_installed_bioc("tximeta")
#     skip_if_not_installed_bioc("SummarizedExperiment")
#     skip_on_cran()

#     library(SummarizedExperiment)
#     library(macrophage)
#     library(tximeta)
#     library(cluster)

#     dir <- system.file("extdata", package = "macrophage")
#     coldata <- read.csv(file.path(dir, "coldata.csv"))
#     coldata$files <- file.path(dir, "quants", coldata$names, "quant.sf.gz")
#     coldata$names <- coldata$sample_id
#     se <- tximeta(coldata)
#     gse <- summarizeToGene(se)

#     condition <- factor(gse$condition_name)
#     mat <- assay(gse, "counts")
#     gene_vars <- apply(mat, 1, var)
#     top_idx <- order(gene_vars, decreasing = TRUE)[seq_len(1000)]
#     mat_log <- log2(mat[top_idx, ] + 1)
#     cor_mat <- cor(mat_log, method = "pearson")

#     hc <- hclust(as.dist(1 - cor_mat), method = "ward.D2")
#     clusters <- cutree(hc, k = 4)
#     sil <- silhouette(clusters, dist = as.dist(1 - cor_mat))

#     output_dir <- file.path(tempdir(), "test_p2_raw")
#     dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

#     write.table(as.data.frame(cor_mat),
#                 file.path(output_dir, "similarity_matrix.tsv"),
#                 sep = "\t", quote = FALSE)
#     assignments <- data.frame(
#         sample = colnames(gse), condition = as.character(condition),
#         cluster = clusters, silhouette_width = sil[, "sil_width"]
#     )
#     write.table(assignments, file.path(output_dir, "cluster_assignments.tsv"),
#                 sep = "\t", row.names = FALSE, quote = FALSE)

#     expect_true(file.exists(file.path(output_dir, "similarity_matrix.tsv")))
#     expect_true(file.exists(file.path(output_dir, "cluster_assignments.tsv")))

#     assign_back <- read.table(file.path(output_dir, "cluster_assignments.tsv"),
#                               header = TRUE, sep = "\t")
#     expect_equal(nrow(assign_back), ncol(gse))
#     expect_true("cluster" %in% colnames(assign_back))
#     expect_true("silhouette_width" %in% colnames(assign_back))

#     unlink(output_dir, recursive = TRUE)
# })

# # ── Project 3: Differential Expression ──────────────────────────────────────
# test_that("Project 3: raw DE analysis runs and exports correctly", {
#     skip_if_not_installed_bioc("ExperimentHub")
#     skip_if_not_installed_bioc("SummarizedExperiment")
#     skip_if_not_installed_bioc("DESeq2")
#     skip_if_not_installed_bioc("apeglm")
#     skip_on_cran()

#     library(SummarizedExperiment)
#     library(ExperimentHub)
#     library(DESeq2)
#     library(apeglm)

#     eh <- ExperimentHub()
#     se <- eh[["EH1075"]]

#     cd <- colData(se)
#     tissue_cell <- as.character(cd[["tissue_cell"]])
#     cell_type <- ifelse(grepl("Tcon", tissue_cell), "Tconv", "Treg")
#     tissue <- sub("-Tre?[a-z]*", "", tissue_cell)
#     tissue <- sub("-Tcon", "", tissue)

#     se_clean <- SummarizedExperiment(
#         assays = list(counts = assay(se, "counts")),
#         colData = DataFrame(cell_type = factor(cell_type), tissue = factor(tissue))
#     )

#     keep <- se_clean$tissue == "Lymph-N"
#     se_ln <- se_clean[, keep]
#     se_ln$cell_type <- droplevels(se_ln$cell_type)
#     keep_genes <- rowSums(assay(se_ln, "counts")) >= 10
#     se_ln <- se_ln[keep_genes, ]

#     dds <- DESeqDataSet(se_ln, design = ~ cell_type)
#     dds$cell_type <- relevel(dds$cell_type, ref = "Tconv")
#     dds <- DESeq(dds)

#     coef_name <- resultsNames(dds)[2]
#     res_shrunk <- lfcShrink(dds, coef = coef_name, type = "apeglm")
#     res_df <- as.data.frame(res_shrunk)
#     res_df$gene <- rownames(res_df)

#     res_df$direction <- "ns"
#     res_df$direction[res_df$padj < 0.05 & res_df$log2FoldChange > 1] <- "up"
#     res_df$direction[res_df$padj < 0.05 & res_df$log2FoldChange < -1] <- "down"
#     summary_df <- as.data.frame(table(res_df$direction))
#     colnames(summary_df) <- c("direction", "count")

#     output_dir <- file.path(tempdir(), "test_p3_raw")
#     dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
#     write.table(res_df, file.path(output_dir, "de_results.tsv"),
#                 sep = "\t", row.names = FALSE, quote = FALSE)
#     write.table(summary_df, file.path(output_dir, "de_summary.tsv"),
#                 sep = "\t", row.names = FALSE, quote = FALSE)

#     expect_true(file.exists(file.path(output_dir, "de_results.tsv")))
#     expect_true(file.exists(file.path(output_dir, "de_summary.tsv")))

#     de_back <- read.table(file.path(output_dir, "de_results.tsv"),
#                           header = TRUE, sep = "\t")
#     expect_gt(nrow(de_back), 100)
#     expect_true(all(c("log2FoldChange", "padj", "direction") %in% colnames(de_back)))

#     summ_back <- read.table(file.path(output_dir, "de_summary.tsv"),
#                             header = TRUE, sep = "\t")
#     expect_true(all(c("direction", "count") %in% colnames(summ_back)))

#     unlink(output_dir, recursive = TRUE)
# })

# # ── Project 4: K-means Clustering ───────────────────────────────────────────
# test_that("Project 4: raw k-means analysis runs and exports correctly", {
#     skip_if_not_installed_bioc("scRNAseq")
#     skip_if_not_installed_bioc("SingleCellExperiment")
#     skip_if_not_installed("cluster")
#     skip_on_cran()

#     library(SingleCellExperiment)
#     library(scRNAseq)
#     library(cluster)

#     sce <- BaronPancreasData("human")
#     counts_mat <- as.matrix(counts(sce))
#     cell_type <- colData(sce)$label

#     gene_vars <- apply(counts_mat, 1, var)
#     top_idx <- order(gene_vars, decreasing = TRUE)[seq_len(2000)]
#     mat <- counts_mat[top_idx, ]
#     lib_sizes <- colSums(counts_mat)
#     mat_norm <- log2(t(t(mat) / lib_sizes * 1e6) + 1)
#     pca <- prcomp(t(mat_norm), scale. = TRUE, center = TRUE)
#     pca_mat <- pca$x[, 1:20]

#     set.seed(42)
#     max_k <- 8  # smaller range for test speed
#     metrics <- data.frame(k = 2:max_k, wss = NA_real_, avg_silhouette = NA_real_)
#     for (k in 2:max_k) {
#         km <- kmeans(pca_mat, centers = k, nstart = 10)
#         metrics$wss[k - 1] <- km$tot.withinss
#         sil <- silhouette(km$cluster, dist(pca_mat))
#         metrics$avg_silhouette[k - 1] <- mean(sil[, "sil_width"])
#     }
#     km_sel <- kmeans(pca_mat, centers = 5, nstart = 10)

#     output_dir <- file.path(tempdir(), "test_p4_raw")
#     dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

#     assignments <- data.frame(cell_id = colnames(sce), cell_type = cell_type,
#                               cluster = km_sel$cluster)
#     write.table(assignments, file.path(output_dir, "cluster_assignments.tsv"),
#                 sep = "\t", row.names = FALSE, quote = FALSE)
#     write.table(metrics, file.path(output_dir, "kmeans_metrics.tsv"),
#                 sep = "\t", row.names = FALSE, quote = FALSE)

#     expect_true(file.exists(file.path(output_dir, "cluster_assignments.tsv")))
#     expect_true(file.exists(file.path(output_dir, "kmeans_metrics.tsv")))

#     assign_back <- read.table(file.path(output_dir, "cluster_assignments.tsv"),
#                               header = TRUE, sep = "\t")
#     expect_equal(nrow(assign_back), ncol(sce))
#     expect_true("cluster" %in% colnames(assign_back))

#     met_back <- read.table(file.path(output_dir, "kmeans_metrics.tsv"),
#                            header = TRUE, sep = "\t")
#     expect_true(all(c("k", "wss", "avg_silhouette") %in% colnames(met_back)))

#     unlink(output_dir, recursive = TRUE)
# })

# # ── Project 5: Cell QC Dashboard ────────────────────────────────────────────
# test_that("Project 5: raw QC analysis runs and exports correctly", {
#     skip_if_not_installed_bioc("scRNAseq")
#     skip_if_not_installed_bioc("SingleCellExperiment")
#     skip_on_cran()

#     library(SingleCellExperiment)
#     library(scRNAseq)

#     sce <- LunSpikeInData()
#     counts_mat <- as.matrix(counts(sce))

#     lib_size <- colSums(counts_mat)
#     n_genes <- colSums(counts_mat > 0)
#     ercc_counts <- as.matrix(counts(altExp(sce, "ERCC")))
#     ercc_total <- colSums(ercc_counts)
#     total_counts <- lib_size + ercc_total
#     spike_pct <- ercc_total / total_counts * 100

#     qc_metrics <- data.frame(
#         cell_id = colnames(sce), lib_size = lib_size,
#         n_genes = n_genes, spike_pct = spike_pct
#     )

#     mad_threshold <- 3
#     flag_low_lib <- qc_metrics$lib_size < median(lib_size) - mad_threshold * mad(lib_size)
#     flag_low_genes <- qc_metrics$n_genes < median(n_genes) - mad_threshold * mad(n_genes)
#     flag_hi_spike <- qc_metrics$spike_pct > median(spike_pct) + mad_threshold * mad(spike_pct)
#     qc_metrics$pass <- !(flag_low_lib | flag_low_genes | flag_hi_spike)

#     output_dir <- file.path(tempdir(), "test_p5_raw")
#     dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

#     write.table(qc_metrics, file.path(output_dir, "qc_metrics.tsv"),
#                 sep = "\t", row.names = FALSE, quote = FALSE)
#     qc_flags <- data.frame(
#         cell_id = qc_metrics$cell_id, pass = qc_metrics$pass,
#         flag_low_lib = flag_low_lib, flag_low_genes = flag_low_genes,
#         flag_hi_spike = flag_hi_spike
#     )
#     write.table(qc_flags, file.path(output_dir, "qc_flags.tsv"),
#                 sep = "\t", row.names = FALSE, quote = FALSE)

#     expect_true(file.exists(file.path(output_dir, "qc_metrics.tsv")))
#     expect_true(file.exists(file.path(output_dir, "qc_flags.tsv")))

#     met_back <- read.table(file.path(output_dir, "qc_metrics.tsv"),
#                            header = TRUE, sep = "\t")
#     expect_equal(nrow(met_back), ncol(sce))
#     expect_true(all(c("lib_size", "n_genes", "spike_pct", "pass") %in%
#                     colnames(met_back)))

#     flags_back <- read.table(file.path(output_dir, "qc_flags.tsv"),
#                              header = TRUE, sep = "\t")
#     expect_true("flag_hi_spike" %in% colnames(flags_back))

#     unlink(output_dir, recursive = TRUE)
# })

# # ── Project 6: Gene Variance ────────────────────────────────────────────────
# test_that("Project 6: raw gene variance analysis runs and exports correctly", {
#     skip_if_not_installed_bioc("scRNAseq")
#     skip_if_not_installed_bioc("SingleCellExperiment")
#     skip_on_cran()

#     library(SingleCellExperiment)
#     library(scRNAseq)

#     sce <- MacoskoRetinaData()
#     set.seed(42)
#     # Use smaller subset for test speed
#     sce <- sce[, sample(ncol(sce), 2000)]
#     counts_mat <- as.matrix(counts(sce))

#     lib_sizes <- colSums(counts_mat)
#     mat_cpm <- t(t(counts_mat) / lib_sizes * 1e6)
#     mat_log <- log2(mat_cpm + 1)

#     gene_mean <- rowMeans(mat_log)
#     gene_var <- apply(mat_log, 1, var)

#     gene_stats <- data.frame(gene = rownames(counts_mat),
#                              mean = gene_mean, variance = gene_var)
#     gene_stats <- gene_stats[gene_stats$mean > 0.01, ]

#     loess_fit <- loess(log10(variance) ~ log10(mean), data = gene_stats)
#     gene_stats$trend <- 10^predict(loess_fit)
#     gene_stats$resid <- gene_stats$variance / gene_stats$trend
#     gene_stats$is_hvg <- gene_stats$resid > quantile(gene_stats$resid, 0.9)

#     hvg_list <- gene_stats[gene_stats$is_hvg, c("gene", "mean", "variance", "resid")]

#     output_dir <- file.path(tempdir(), "test_p6_raw")
#     dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

#     write.table(gene_stats, file.path(output_dir, "gene_statistics.tsv"),
#                 sep = "\t", row.names = FALSE, quote = FALSE)
#     write.table(hvg_list, file.path(output_dir, "hvg_list.tsv"),
#                 sep = "\t", row.names = FALSE, quote = FALSE)

#     expect_true(file.exists(file.path(output_dir, "gene_statistics.tsv")))
#     expect_true(file.exists(file.path(output_dir, "hvg_list.tsv")))

#     gs_back <- read.table(file.path(output_dir, "gene_statistics.tsv"),
#                           header = TRUE, sep = "\t")
#     expect_gt(nrow(gs_back), 100)
#     expect_true(all(c("gene", "mean", "variance", "is_hvg") %in% colnames(gs_back)))

#     hvg_back <- read.table(file.path(output_dir, "hvg_list.tsv"),
#                            header = TRUE, sep = "\t")
#     expect_gt(nrow(hvg_back), 0)

#     unlink(output_dir, recursive = TRUE)
# })

# # ── Project 7: Gene Set Scoring ─────────────────────────────────────────────
# test_that("Project 7: raw gene set scoring runs and exports correctly", {
#     skip_if_not_installed_bioc("curatedTCGAData")
#     skip_if_not_installed_bioc("TCGAutils")
#     skip_if_not_installed_bioc("SummarizedExperiment")
#     skip_if_not_installed("msigdbr")
#     skip_on_cran()

#     library(SummarizedExperiment)
#     library(curatedTCGAData)
#     library(TCGAutils)
#     library(msigdbr)

#     brca <- curatedTCGAData("BRCA", "RNASeq2*", version = "2.0.1",
#                              dry.run = FALSE)
#     rse <- experiments(brca)[[1]]

#     set.seed(42)
#     keep_samples <- sample(ncol(rse), min(50, ncol(rse)))  # small for speed
#     rse <- rse[, keep_samples]
#     vars <- apply(assay(rse), 1, var, na.rm = TRUE)
#     keep_genes <- names(sort(vars, decreasing = TRUE))[1:2000]
#     rse <- rse[keep_genes, ]

#     # Assign a simple group label per sample (avoids fragile PAM50 column lookup)
#     group <- rep(c("A", "B"), length.out = ncol(rse))

#     mat <- assay(rse)
#     mat_z <- t(scale(t(mat)))

#     hallmarks <- msigdbr(species = "Homo sapiens", category = "H")
#     gene_sets <- split(hallmarks$gene_symbol, hallmarks$gs_name)
#     gene_sets <- gene_sets[1:3]  # just 3 sets for speed

#     scores_list <- lapply(names(gene_sets), function(gs_name) {
#         genes_in_set <- intersect(gene_sets[[gs_name]], rownames(mat_z))
#         if (length(genes_in_set) < 5) return(NULL)
#         per_sample <- colMeans(mat_z[genes_in_set, , drop = FALSE], na.rm = TRUE)
#         data.frame(sample_id = colnames(mat), gene_set = gs_name,
#                    score = per_sample, pam50 = group)
#     })
#     scores_df <- do.call(rbind, scores_list)

#     summary_df <- aggregate(score ~ gene_set + pam50, data = scores_df,
#                             FUN = function(x) c(mean = mean(x)))
#     colnames(summary_df) <- c("gene_set", "pam50", "mean_score")

#     output_dir <- file.path(tempdir(), "test_p7_raw")
#     dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

#     write.table(scores_df, file.path(output_dir, "geneset_scores.tsv"),
#                 sep = "\t", row.names = FALSE, quote = FALSE)
#     write.table(summary_df, file.path(output_dir, "scoring_summary.tsv"),
#                 sep = "\t", row.names = FALSE, quote = FALSE)

#     expect_true(file.exists(file.path(output_dir, "geneset_scores.tsv")))
#     expect_true(file.exists(file.path(output_dir, "scoring_summary.tsv")))

#     gs_back <- read.table(file.path(output_dir, "geneset_scores.tsv"),
#                           header = TRUE, sep = "\t")
#     expect_gt(nrow(gs_back), 0)
#     expect_true(all(c("gene_set", "score", "pam50") %in% colnames(gs_back)))

#     unlink(output_dir, recursive = TRUE)
# })

# # ── Project 8: Normalization Comparison ─────────────────────────────────────
# test_that("Project 8: raw normalization analysis runs and exports correctly", {
#     skip_if_not_installed_bioc("scRNAseq")
#     skip_if_not_installed_bioc("SingleCellExperiment")
#     skip_on_cran()

#     library(SingleCellExperiment)
#     library(scRNAseq)

#     sce <- MuraroPancreasData()
#     counts_mat <- as.matrix(counts(sce))

#     keep_genes <- rowSums(counts_mat > 0) >= 5
#     counts_mat <- counts_mat[keep_genes, ]
#     lib_sizes <- colSums(counts_mat)

#     # CPM
#     mat_cpm <- t(t(counts_mat) / lib_sizes * 1e6)
#     # log2-CPM
#     mat_log2 <- log2(mat_cpm + 1)

#     compute_stats <- function(mat, method_name) {
#         data.frame(
#             method = method_name,
#             median = apply(mat, 2, median),
#             iqr    = apply(mat, 2, IQR)
#         )
#     }
#     stats_raw <- compute_stats(as.matrix(counts_mat), "raw")
#     stats_cpm <- compute_stats(mat_cpm, "cpm")
#     stats_log2 <- compute_stats(mat_log2, "log2_cpm")
#     all_stats <- rbind(stats_raw, stats_cpm, stats_log2)

#     output_dir <- file.path(tempdir(), "test_p8_raw")
#     dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

#     subset_genes <- rownames(mat_log2)[1:min(100, nrow(mat_log2))]
#     write.table(as.data.frame(mat_log2[subset_genes, ]),
#                 file.path(output_dir, "normalized_counts.tsv"),
#                 sep = "\t", quote = FALSE)
#     write.table(all_stats, file.path(output_dir, "normalization_stats.tsv"),
#                 sep = "\t", row.names = FALSE, quote = FALSE)

#     expect_true(file.exists(file.path(output_dir, "normalized_counts.tsv")))
#     expect_true(file.exists(file.path(output_dir, "normalization_stats.tsv")))

#     stats_back <- read.table(file.path(output_dir, "normalization_stats.tsv"),
#                              header = TRUE, sep = "\t")
#     expect_gt(nrow(stats_back), 0)
#     expect_true("method" %in% colnames(stats_back))

#     unlink(output_dir, recursive = TRUE)
# })

# # ── Project 9: Gene Correlation Network ─────────────────────────────────────
# test_that("Project 9: raw gene network analysis runs and exports correctly", {
#     skip_if_not_installed_bioc("recount3")
#     skip_if_not_installed_bioc("SummarizedExperiment")
#     skip_if_not_installed("igraph")
#     skip_on_cran()

#     library(SummarizedExperiment)
#     library(recount3)
#     library(igraph)

#     human_projects <- available_projects()
#     proj <- subset(human_projects, file_source == "gtex" & project == "MUSCLE")
#     rse <- create_rse(proj)
#     assay(rse, "counts") <- transform_counts(rse)

#     vars <- apply(assay(rse, "counts"), 1, var)
#     keep_genes <- names(sort(vars, decreasing = TRUE))[1:100]  # small for speed
#     set.seed(42)
#     keep_samples <- sample(ncol(rse), min(50, ncol(rse)))
#     se <- rse[keep_genes, keep_samples]
#     mat <- log2(assay(se, "counts") + 1)

#     cor_mat <- cor(t(mat), method = "pearson")
#     cor_threshold <- 0.7
#     adj_mat <- (abs(cor_mat) >= cor_threshold) * 1
#     diag(adj_mat) <- 0

#     g <- graph_from_adjacency_matrix(adj_mat, mode = "undirected")
#     deg <- degree(g)
#     betw <- betweenness(g)

#     net_summary <- data.frame(
#         metric = c("n_genes", "n_edges", "mean_degree"),
#         value  = c(vcount(g), ecount(g), round(mean(deg), 2))
#     )
#     hub_df <- data.frame(gene = names(deg), degree = deg, betweenness = betw)
#     hub_df <- hub_df[order(hub_df$degree, decreasing = TRUE), ]
#     hub_genes <- head(hub_df, 10)

#     upper_idx <- which(upper.tri(cor_mat) & abs(cor_mat) >= cor_threshold,
#                        arr.ind = TRUE)
#     if (nrow(upper_idx) > 0) {
#         cor_edges <- data.frame(
#             gene1 = rownames(cor_mat)[upper_idx[, 1]],
#             gene2 = colnames(cor_mat)[upper_idx[, 2]],
#             correlation = cor_mat[upper_idx]
#         )
#     } else {
#         cor_edges <- data.frame(gene1 = character(), gene2 = character(),
#                                 correlation = numeric())
#     }

#     output_dir <- file.path(tempdir(), "test_p9_raw")
#     dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

#     write.table(cor_edges, file.path(output_dir, "gene_correlations.tsv"),
#                 sep = "\t", row.names = FALSE, quote = FALSE)
#     write.table(net_summary, file.path(output_dir, "network_summary.tsv"),
#                 sep = "\t", row.names = FALSE, quote = FALSE)
#     write.table(hub_genes, file.path(output_dir, "hub_genes.tsv"),
#                 sep = "\t", row.names = FALSE, quote = FALSE)

#     expect_true(file.exists(file.path(output_dir, "gene_correlations.tsv")))
#     expect_true(file.exists(file.path(output_dir, "network_summary.tsv")))
#     expect_true(file.exists(file.path(output_dir, "hub_genes.tsv")))

#     ns_back <- read.table(file.path(output_dir, "network_summary.tsv"),
#                           header = TRUE, sep = "\t")
#     expect_true(all(c("metric", "value") %in% colnames(ns_back)))

#     unlink(output_dir, recursive = TRUE)
# })

# # ── Project 10: Expression Heatmap ──────────────────────────────────────────
# test_that("Project 10: raw heatmap analysis runs and exports correctly", {
#     skip_if_not_installed_bioc("curatedTCGAData")
#     skip_if_not_installed_bioc("TCGAutils")
#     skip_if_not_installed_bioc("SummarizedExperiment")
#     skip_on_cran()

#     library(SummarizedExperiment)
#     library(curatedTCGAData)
#     library(TCGAutils)

#     gbm <- curatedTCGAData("GBM", "RNASeq2*", version = "2.0.1",
#                             dry.run = FALSE)
#     rse <- experiments(gbm)[[1]]

#     vars <- apply(assay(rse), 1, var, na.rm = TRUE)
#     keep_genes <- names(sort(vars, decreasing = TRUE))[1:100]  # small for speed
#     rse <- rse[keep_genes, ]

#     mat <- assay(rse)
#     mat_scaled <- t(scale(t(mat)))

#     gene_k <- 5
#     hc_genes <- hclust(dist(mat_scaled), method = "ward.D2")
#     gene_modules <- cutree(hc_genes, k = gene_k)
#     module_df <- data.frame(gene = names(gene_modules),
#                             module = paste0("M", gene_modules))

#     output_dir <- file.path(tempdir(), "test_p10_raw")
#     dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

#     scaled_out <- as.data.frame(mat_scaled)
#     scaled_out$gene <- rownames(mat_scaled)
#     write.table(scaled_out, file.path(output_dir, "scaled_expression.tsv"),
#                 sep = "\t", row.names = FALSE, quote = FALSE)
#     write.table(module_df, file.path(output_dir, "gene_modules.tsv"),
#                 sep = "\t", row.names = FALSE, quote = FALSE)

#     expect_true(file.exists(file.path(output_dir, "scaled_expression.tsv")))
#     expect_true(file.exists(file.path(output_dir, "gene_modules.tsv")))

#     mod_back <- read.table(file.path(output_dir, "gene_modules.tsv"),
#                            header = TRUE, sep = "\t")
#     expect_equal(nrow(mod_back), length(keep_genes))
#     expect_true(all(c("gene", "module") %in% colnames(mod_back)))

#     unlink(output_dir, recursive = TRUE)
# })

# # ── Project 11: Dimensionality Estimation ────────────────────────────────────
# test_that("Project 11: raw dim estimation runs and exports correctly", {
#     skip_if_not_installed_bioc("TENxPBMCData")
#     skip_if_not_installed_bioc("SingleCellExperiment")
#     skip_on_cran()

#     library(SingleCellExperiment)
#     library(TENxPBMCData)

#     sce <- TENxPBMCData("pbmc3k")
#     counts_mat <- as.matrix(counts(sce))

#     gene_vars <- apply(counts_mat, 1, var)
#     top_idx <- order(gene_vars, decreasing = TRUE)[seq_len(1000)]
#     mat <- counts_mat[top_idx, ]

#     lib_sizes <- colSums(counts_mat)
#     mat_norm <- log2(t(t(mat) / lib_sizes * 1e6) + 1)

#     pca <- prcomp(t(as.matrix(mat_norm)), scale. = TRUE, center = TRUE)
#     max_pcs <- min(30, ncol(pca$x))
#     eigenvalues <- pca$sdev[1:max_pcs]^2
#     var_pct <- eigenvalues / sum(pca$sdev^2) * 100

#     eigenvalue_df <- data.frame(PC = seq_len(max_pcs), eigenvalue = eigenvalues,
#                                 var_pct = var_pct)

#     # Broken stick
#     broken_stick <- function(n) {
#         bs <- numeric(n)
#         for (i in seq_len(n)) bs[i] <- sum(1 / (i:n))
#         bs / n * 100
#     }
#     bs_vals <- broken_stick(max_pcs)
#     bs_n <- sum(var_pct > bs_vals)

#     # Kaiser
#     kaiser_n <- sum(eigenvalues > mean(eigenvalues))

#     # Elbow
#     diffs <- -diff(eigenvalues)
#     elbow_n <- which.max(diffs)

#     estimates <- data.frame(
#         method = c("broken_stick", "kaiser", "elbow"),
#         n_dims = c(bs_n, kaiser_n, elbow_n)
#     )

#     output_dir <- file.path(tempdir(), "test_p11_raw")
#     dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

#     write.table(eigenvalue_df, file.path(output_dir, "eigenvalues.tsv"),
#                 sep = "\t", row.names = FALSE, quote = FALSE)
#     write.table(estimates, file.path(output_dir, "dimension_estimates.tsv"),
#                 sep = "\t", row.names = FALSE, quote = FALSE)

#     expect_true(file.exists(file.path(output_dir, "eigenvalues.tsv")))
#     expect_true(file.exists(file.path(output_dir, "dimension_estimates.tsv")))

#     eig_back <- read.table(file.path(output_dir, "eigenvalues.tsv"),
#                            header = TRUE, sep = "\t")
#     expect_equal(nrow(eig_back), max_pcs)
#     expect_true(all(c("PC", "eigenvalue", "var_pct") %in% colnames(eig_back)))

#     est_back <- read.table(file.path(output_dir, "dimension_estimates.tsv"),
#                            header = TRUE, sep = "\t")
#     expect_equal(nrow(est_back), 3)
#     expect_true(all(est_back$n_dims > 0))

#     unlink(output_dir, recursive = TRUE)
# })

# # ── Project 12: Batch Effect Assessment ─────────────────────────────────────
# test_that("Project 12: raw batch effect analysis runs and exports correctly", {
#     skip_if_not_installed_bioc("scRNAseq")
#     skip_if_not_installed_bioc("SingleCellExperiment")
#     skip_on_cran()

#     library(SingleCellExperiment)
#     library(scRNAseq)

#     sce <- GrunPancreasData()
#     counts_mat <- as.matrix(counts(sce))
#     batch <- colData(sce)$donor
#     cell_type <- colData(sce)$sample

#     keep <- !is.na(cell_type)
#     counts_mat <- counts_mat[, keep]
#     batch <- batch[keep]
#     cell_type <- cell_type[keep]

#     # Remove cells with zero total counts to avoid Inf in log normalization
#     lib_sizes <- colSums(counts_mat)
#     nonzero <- lib_sizes > 0
#     counts_mat <- counts_mat[, nonzero]
#     batch <- batch[nonzero]
#     cell_type <- cell_type[nonzero]
#     lib_sizes <- lib_sizes[nonzero]

#     gene_vars <- apply(counts_mat, 1, var)
#     top_idx <- order(gene_vars, decreasing = TRUE)[seq_len(1000)]
#     mat <- counts_mat[top_idx, ]

#     mat_norm <- log2(t(t(mat) / lib_sizes * 1e6) + 1)

#     pca_before <- prcomp(t(as.matrix(mat_norm)), scale. = TRUE, center = TRUE)
#     n_pcs <- 5
#     r2_df <- data.frame(PC = paste0("PC", 1:n_pcs), R2 = NA_real_)
#     for (i in 1:n_pcs) {
#         fit <- lm(pca_before$x[, i] ~ batch)
#         r2_df$R2[i] <- summary(fit)$r.squared
#     }

#     # Median-center correction
#     mat_corrected <- mat_norm
#     for (b in unique(batch)) {
#         idx <- batch == b
#         batch_median <- apply(mat_corrected[, idx], 1, median)
#         global_median <- apply(mat_corrected, 1, median)
#         mat_corrected[, idx] <- mat_corrected[, idx] - batch_median + global_median
#     }

#     output_dir <- file.path(tempdir(), "test_p12_raw")
#     dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

#     write.table(r2_df, file.path(output_dir, "batch_variance.tsv"),
#                 sep = "\t", row.names = FALSE, quote = FALSE)
#     corrected_out <- as.data.frame(as.matrix(mat_corrected[1:100, ]))
#     corrected_out$gene <- rownames(mat_corrected)[1:100]
#     write.table(corrected_out, file.path(output_dir, "corrected_counts.tsv"),
#                 sep = "\t", row.names = FALSE, quote = FALSE)

#     expect_true(file.exists(file.path(output_dir, "batch_variance.tsv")))
#     expect_true(file.exists(file.path(output_dir, "corrected_counts.tsv")))

#     r2_back <- read.table(file.path(output_dir, "batch_variance.tsv"),
#                           header = TRUE, sep = "\t")
#     expect_equal(nrow(r2_back), n_pcs)
#     expect_true(all(c("PC", "R2") %in% colnames(r2_back)))
#     expect_true(all(r2_back$R2 >= 0 & r2_back$R2 <= 1))

#     unlink(output_dir, recursive = TRUE)
# })

# # ── Project 13: Marker Gene Identification ──────────────────────────────────
# test_that("Project 13: raw marker gene analysis runs and exports correctly", {
#     skip_if_not_installed_bioc("scRNAseq")
#     skip_if_not_installed_bioc("SingleCellExperiment")
#     skip_on_cran()

#     library(SingleCellExperiment)
#     library(scRNAseq)

#     sce <- BaronPancreasData("mouse")
#     counts_mat <- as.matrix(counts(sce))
#     cell_type <- colData(sce)$label

#     # Filter genes detected in < 5% of cells
#     detect_rate_all <- rowSums(counts_mat > 0) / ncol(counts_mat)
#     keep_genes <- detect_rate_all >= 0.05
#     counts_mat <- counts_mat[keep_genes, ]

#     lib_sizes <- colSums(counts_mat)
#     mat_norm <- log2(t(t(counts_mat) / lib_sizes * 1e6) + 1)

#     # Test with 2 cell types for speed
#     cell_types <- unique(cell_type)[1:2]
#     keep_cells <- cell_type %in% cell_types
#     counts_sub <- counts_mat[, keep_cells]
#     mat_sub <- mat_norm[, keep_cells]
#     ct_sub <- cell_type[keep_cells]

#     n_markers <- 3
#     marker_list <- lapply(cell_types, function(ct) {
#         is_target <- ct_sub == ct
#         mean_target <- rowMeans(mat_sub[, is_target, drop = FALSE])
#         mean_rest <- rowMeans(mat_sub[, !is_target, drop = FALSE])
#         log2fc <- mean_target - mean_rest
#         detect_target <- rowSums(counts_sub[, is_target, drop = FALSE] > 0) /
#             sum(is_target)

#         # Wilcoxon only on top 200 genes by FC for speed
#         top_fc <- order(log2fc, decreasing = TRUE)[1:200]
#         pvals <- rep(1, nrow(mat_sub))
#         for (i in top_fc) {
#             pvals[i] <- wilcox.test(mat_sub[i, is_target],
#                                      mat_sub[i, !is_target],
#                                      alternative = "greater")$p.value
#         }

#         data.frame(
#             gene = rownames(mat_sub), cell_type = ct, log2fc = log2fc,
#             detect_target = detect_target, pvalue = pvals,
#             padj = p.adjust(pvals, method = "BH"),
#             stringsAsFactors = FALSE
#         )
#     })
#     all_markers <- do.call(rbind, marker_list)

#     marker_summary <- data.frame(
#         cell_type = cell_types,
#         n_sig = sapply(cell_types, function(ct) {
#             sum(all_markers$cell_type == ct & all_markers$padj < 0.05 &
#                 all_markers$log2fc > 1)
#         })
#     )

#     output_dir <- file.path(tempdir(), "test_p13_raw")
#     dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

#     write.table(all_markers, file.path(output_dir, "marker_genes.tsv"),
#                 sep = "\t", row.names = FALSE, quote = FALSE)
#     write.table(marker_summary, file.path(output_dir, "marker_summary.tsv"),
#                 sep = "\t", row.names = FALSE, quote = FALSE)

#     expect_true(file.exists(file.path(output_dir, "marker_genes.tsv")))
#     expect_true(file.exists(file.path(output_dir, "marker_summary.tsv")))

#     mg_back <- read.table(file.path(output_dir, "marker_genes.tsv"),
#                           header = TRUE, sep = "\t")
#     expect_gt(nrow(mg_back), 0)
#     expect_true(all(c("gene", "cell_type", "log2fc", "padj") %in%
#                     colnames(mg_back)))

#     ms_back <- read.table(file.path(output_dir, "marker_summary.tsv"),
#                           header = TRUE, sep = "\t")
#     expect_true("n_sig" %in% colnames(ms_back))

#     unlink(output_dir, recursive = TRUE)
# })
