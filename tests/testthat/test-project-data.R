# Tests for all project data generation scripts from the Project Selection Guide.
# These tests verify that each Bioconductor dataset can be loaded and the
# resulting objects have the expected structure.
#
# These tests require internet access and several Bioconductor packages.
# They are skipped on CRAN and when the required packages are not installed.

# Helper: skip if a package is not installed
skip_if_not_installed_bioc <- function(pkg) {
  testthat::skip_if_not_installed(pkg)
}

# ---------------------------------------------------------------------------
# Project 0: PCA Explorer (Reference) — airway
# ---------------------------------------------------------------------------
test_that("Project 0: airway dataset loads and subsets correctly", {
  skip_if_not_installed_bioc("airway")
  skip_if_not_installed_bioc("SummarizedExperiment")
  skip_on_cran()

  library(airway)
  library(SummarizedExperiment)

  data("airway")
  expect_s4_class(airway, "RangedSummarizedExperiment")
  expect_gt(ncol(airway), 0)
  expect_gt(nrow(airway), 0)

  # Test the subsetting logic from data-raw
  counts <- assay(airway)
  vars <- apply(counts, 1, var)
  top100 <- names(sort(vars, decreasing = TRUE))[1:100]
  expect_length(top100, 100)

  set.seed(42)
  rest <- sample(setdiff(rownames(counts), top100), 400)
  subset_se <- airway[c(top100, rest), ]
  expect_equal(nrow(subset_se), 500)
  expect_equal(ncol(subset_se), ncol(airway))
})

# ---------------------------------------------------------------------------
# Project 1: UMAP Embedding Explorer — Zeisel Brain
# ---------------------------------------------------------------------------
test_that("Project 1: ZeiselBrainData loads correctly", {
  skip_if_not_installed_bioc("scRNAseq")
  skip_if_not_installed_bioc("SingleCellExperiment")
  skip_on_cran()

  library(scRNAseq)
  library(SingleCellExperiment)

  sce <- ZeiselBrainData()
  expect_s4_class(sce, "SingleCellExperiment")
  expect_gt(ncol(sce), 0)
  expect_gt(nrow(sce), 0)

  # Check expected metadata columns exist
  cd <- colData(sce)
  expect_true("level1class" %in% colnames(cd))
  expect_true("level2class" %in% colnames(cd))
})

# ---------------------------------------------------------------------------
# Project 2: Sample Similarity & Clustering — Macrophage Stimulation
# ---------------------------------------------------------------------------
test_that("Project 2: macrophage package files are accessible", {
  skip_if_not_installed_bioc("macrophage")
  skip_if_not_installed_bioc("SummarizedExperiment")
  skip_on_cran()

  library(macrophage)

  dir <- system.file("extdata", package = "macrophage")
  expect_true(nchar(dir) > 0, label = "macrophage extdata directory found")

  coldata_path <- file.path(dir, "coldata.csv")
  expect_true(file.exists(coldata_path), label = "coldata.csv exists")

  coldata <- read.csv(coldata_path)
  expect_true("condition_name" %in% colnames(coldata))
  expect_true("line_id" %in% colnames(coldata))
  expect_gt(nrow(coldata), 0)
})

# ---------------------------------------------------------------------------
# Project 3: Differential Expression — Tissue Tregs (ExperimentHub EH1075)
# ---------------------------------------------------------------------------
test_that("Project 3: EH1075 tissue Treg dataset loads and structures correctly", {
  skip_if_not_installed_bioc("ExperimentHub")
  skip_if_not_installed_bioc("SummarizedExperiment")
  skip_on_cran()

  library(ExperimentHub)
  library(SummarizedExperiment)

  eh <- ExperimentHub()
  se <- eh[["EH1075"]]

  expect_s4_class(se, "SummarizedExperiment")
  expect_gt(nrow(se), 10000)
  expect_equal(ncol(se), 15)

  # Must have raw integer counts
  expect_true("counts" %in% assayNames(se))
  expect_true(is.integer(assay(se, "counts")))

  # Must have the tissue_cell grouping column
  cd <- colData(se)
  expect_true("tissue_cell" %in% colnames(cd))

  # All expected groups present
  expected_groups <- c("Fat-Treg", "Liver-Treg", "Lymph-N-Tcon",
                       "Lymph-N-Treg", "Skin-Treg")
  expect_setequal(unique(as.character(cd[["tissue_cell"]])), expected_groups)

  # Verify the data-raw construction produces a valid SE
  tissue_cell <- as.character(cd[["tissue_cell"]])
  cell_type   <- ifelse(grepl("Tcon", tissue_cell), "Tconv", "Treg")
  tissue      <- sub("-Tre?[a-z]*", "", tissue_cell)
  tissue      <- sub("-Tcon", "", tissue)

  example_se <- SummarizedExperiment(
    assays  = list(counts = assay(se, "counts")),
    colData = DataFrame(
      sample_id = rownames(cd),
      cell_type = factor(cell_type),
      tissue    = factor(tissue)
    )
  )
  expect_s4_class(example_se, "SummarizedExperiment")
  expect_true(all(c("sample_id", "cell_type", "tissue") %in%
                    colnames(colData(example_se))))
  expect_setequal(levels(colData(example_se)[["cell_type"]]), c("Tconv", "Treg"))
})

# ---------------------------------------------------------------------------
# Project 4: K-means Cell Clustering — Baron Human Pancreas
# ---------------------------------------------------------------------------
test_that("Project 4: BaronPancreasData (human) loads correctly", {
  skip_if_not_installed_bioc("scRNAseq")
  skip_if_not_installed_bioc("SingleCellExperiment")
  skip_on_cran()

  library(scRNAseq)
  library(SingleCellExperiment)

  sce <- BaronPancreasData("human")
  expect_s4_class(sce, "SingleCellExperiment")
  expect_gt(ncol(sce), 0)

  cd <- colData(sce)
  expect_true("label" %in% colnames(cd))
})

# ---------------------------------------------------------------------------
# Project 5: Cell QC Dashboard — Lun Spike-In
# ---------------------------------------------------------------------------
test_that("Project 5: LunSpikeInData loads correctly", {
  skip_if_not_installed_bioc("scRNAseq")
  skip_if_not_installed_bioc("SingleCellExperiment")
  skip_on_cran()

  library(scRNAseq)
  library(SingleCellExperiment)

  sce <- LunSpikeInData()
  expect_s4_class(sce, "SingleCellExperiment")
  expect_gt(ncol(sce), 0)

  # ERCC spike-ins are stored in an altExp named "ERCC", not in the main assay.
  # rownames(sce) contains only endogenous genes.
  expect_true("ERCC" %in% altExpNames(sce),
              label = "ERCC spike-in altExp present")
  ercc_alt <- altExp(sce, "ERCC")
  expect_gt(nrow(ercc_alt), 0, label = "ERCC altExp has rows")
  expect_true(all(grepl("^ERCC-", rownames(ercc_alt))),
              label = "ERCC altExp rownames are ERCC IDs")

  cd <- colData(sce)
  expect_true("cell line" %in% colnames(cd),
              label = "'cell line' column present in LunSpikeInData colData")
  expect_true("block" %in% colnames(cd),
              label = "'block' column present in LunSpikeInData colData")
})

# ---------------------------------------------------------------------------
# Project 6: Gene Variance Analysis — Macosko Retina
# ---------------------------------------------------------------------------
test_that("Project 6: MacoskoRetinaData loads correctly", {
  skip_if_not_installed_bioc("scRNAseq")
  skip_if_not_installed_bioc("SingleCellExperiment")
  skip_on_cran()

  library(scRNAseq)
  library(SingleCellExperiment)

  sce <- MacoskoRetinaData()
  expect_s4_class(sce, "SingleCellExperiment")
  expect_gt(ncol(sce), 1000)

  cd <- colData(sce)
  expect_true("cluster" %in% colnames(cd))
})

# ---------------------------------------------------------------------------
# Project 7: Gene Set Scoring — TCGA BRCA + MSigDB
# ---------------------------------------------------------------------------
test_that("Project 7: curatedTCGAData BRCA loads correctly", {
  skip_if_not_installed_bioc("curatedTCGAData")
  skip_if_not_installed_bioc("SummarizedExperiment")
  skip_on_cran()

  library(curatedTCGAData)
  library(SummarizedExperiment)

  brca <- curatedTCGAData("BRCA", "RNASeq2*", version = "2.0.1",
                           dry.run = FALSE)
  expect_s4_class(brca, "MultiAssayExperiment")
  exps <- experiments(brca)
  expect_gt(length(exps), 0)
  expect_gt(ncol(exps[[1]]), 0)
})

test_that("Project 7: msigdbr hallmark gene sets load correctly", {
  skip_if_not_installed("msigdbr")
  skip_on_cran()

  library(msigdbr)

  hallmarks <- msigdbr(species = "Homo sapiens", collection = "H")
  expect_s3_class(hallmarks, "data.frame")
  expect_gt(nrow(hallmarks), 0)
  expect_true("gs_name" %in% colnames(hallmarks))
  expect_true("gene_symbol" %in% colnames(hallmarks))

  gene_sets <- split(hallmarks$gene_symbol, hallmarks$gs_name)
  expect_gt(length(gene_sets), 10)
})

# ---------------------------------------------------------------------------
# Project 8: Normalization Comparison — Muraro Pancreas
# ---------------------------------------------------------------------------
test_that("Project 8: MuraroPancreasData loads correctly", {
  skip_if_not_installed_bioc("scRNAseq")
  skip_if_not_installed_bioc("SingleCellExperiment")
  skip_on_cran()

  library(scRNAseq)
  library(SingleCellExperiment)

  sce <- MuraroPancreasData()
  expect_s4_class(sce, "SingleCellExperiment")
  expect_gt(ncol(sce), 0)

  cd <- colData(sce)
  expect_true("label" %in% colnames(cd))
})

# ---------------------------------------------------------------------------
# Project 9: Gene Correlation Network — GTEx Skeletal Muscle (recount3)
# ---------------------------------------------------------------------------
test_that("Project 9: GTEx Muscle project available via recount3", {
  skip_if_not_installed_bioc("recount3")
  skip_if_not_installed_bioc("SummarizedExperiment")
  skip_on_cran()

  library(recount3)
  library(SummarizedExperiment)

  human_projects <- available_projects()
  proj <- subset(human_projects, file_source == "gtex" &
                   project == "MUSCLE")
  expect_gt(nrow(proj), 0, label = "GTEx MUSCLE project found in recount3")

  rse <- create_rse(proj)
  expect_s4_class(rse, "RangedSummarizedExperiment")
  expect_gt(ncol(rse), 100)
  expect_gt(nrow(rse), 0)
})

# ---------------------------------------------------------------------------
# Project 10: Expression Heatmap Builder — TCGA GBM
# ---------------------------------------------------------------------------
test_that("Project 10: curatedTCGAData GBM loads correctly", {
  skip_if_not_installed_bioc("curatedTCGAData")
  skip_if_not_installed_bioc("SummarizedExperiment")
  skip_on_cran()

  library(curatedTCGAData)
  library(SummarizedExperiment)

  gbm <- curatedTCGAData("GBM", "RNASeq2*", version = "2.0.1",
                          dry.run = FALSE)
  expect_s4_class(gbm, "MultiAssayExperiment")
  exps <- experiments(gbm)
  expect_gt(length(exps), 0)
  expect_gt(ncol(exps[[1]]), 0)
})

# ---------------------------------------------------------------------------
# Project 11: Dimensionality Estimation — PBMC 3k
# ---------------------------------------------------------------------------
test_that("Project 11: TENxPBMCData pbmc3k loads correctly", {
  skip_if_not_installed_bioc("TENxPBMCData")
  skip_if_not_installed_bioc("SingleCellExperiment")
  skip_on_cran()

  library(TENxPBMCData)
  library(SingleCellExperiment)

  sce <- TENxPBMCData("pbmc3k")
  expect_s4_class(sce, "SingleCellExperiment")
  expect_gt(ncol(sce), 2000)
  expect_gt(nrow(sce), 0)

  cd <- colData(sce)
  expect_true("Barcode" %in% colnames(cd))
})

# ---------------------------------------------------------------------------
# Project 12: Batch Effect Assessment — Grun Pancreas
# ---------------------------------------------------------------------------
test_that("Project 12: GrunPancreasData loads correctly", {
  skip_if_not_installed_bioc("scRNAseq")
  skip_if_not_installed_bioc("SingleCellExperiment")
  skip_on_cran()

  library(scRNAseq)
  library(SingleCellExperiment)

  sce <- GrunPancreasData()
  expect_s4_class(sce, "SingleCellExperiment")
  expect_gt(ncol(sce), 0)

  cd <- colData(sce)
  expect_true("donor" %in% colnames(cd))
  expect_true("sample" %in% colnames(cd))
})

# ---------------------------------------------------------------------------
# Project 13: Marker Gene Identification — Baron Mouse Pancreas
# ---------------------------------------------------------------------------
test_that("Project 13: BaronPancreasData (mouse) loads correctly", {
  skip_if_not_installed_bioc("scRNAseq")
  skip_if_not_installed_bioc("SingleCellExperiment")
  skip_on_cran()

  library(scRNAseq)
  library(SingleCellExperiment)

  sce <- BaronPancreasData("mouse")
  expect_s4_class(sce, "SingleCellExperiment")
  expect_gt(ncol(sce), 0)

  cd <- colData(sce)
  expect_true("label" %in% colnames(cd))
})
