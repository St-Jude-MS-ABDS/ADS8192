# tests/testthat/test-data.R
# Tests for make_se() and top_variable_features()

test_that("make_se creates a SummarizedExperiment with correct class", {
    counts <- matrix(rpois(100, 50), nrow = 10, ncol = 10)
    rownames(counts) <- paste0("gene", 1:10)
    colnames(counts) <- paste0("sample", 1:10)
    meta <- data.frame(
        treatment = rep(c("ctrl", "trt"), each = 5),
        row.names = colnames(counts)
    )

    se <- make_se(counts, meta)

    expect_s4_class(se, "SummarizedExperiment")
})

test_that("make_se has correct dimensions", {
    counts <- matrix(rpois(100, 50), nrow = 10, ncol = 10)
    rownames(counts) <- paste0("gene", 1:10)
    colnames(counts) <- paste0("sample", 1:10)
    meta <- data.frame(
        treatment = rep(c("ctrl", "trt"), each = 5),
        row.names = colnames(counts)
    )

    se <- make_se(counts, meta)

    expect_equal(nrow(se), 10)
    expect_equal(ncol(se), 10)
})

test_that("make_se preserves colData", {
    counts <- matrix(rpois(60, 50), nrow = 10, ncol = 6)
    rownames(counts) <- paste0("gene", 1:10)
    colnames(counts) <- paste0("sample", 1:6)
    meta <- data.frame(
        treatment = rep(c("ctrl", "trt"), each = 3),
        batch = rep(c("A", "B", "C"), 2),
        row.names = colnames(counts)
    )

    se <- make_se(counts, meta)

    expect_equal(
        as.data.frame(SummarizedExperiment::colData(se))$treatment,
        meta[colnames(counts), "treatment"]
    )
})

test_that("make_se includes rowData when provided", {
    counts <- matrix(rpois(60, 50), nrow = 10, ncol = 6)
    rownames(counts) <- paste0("gene", 1:10)
    colnames(counts) <- paste0("sample", 1:6)
    meta <- data.frame(
        treatment = rep(c("ctrl", "trt"), each = 3),
        row.names = colnames(counts)
    )
    row_meta <- data.frame(
        symbol = paste0("SYM", 1:10),
        row.names = rownames(counts)
    )

    se <- make_se(counts, meta, row_data = row_meta)

    expect_equal(
        as.data.frame(SummarizedExperiment::rowData(se))$symbol,
        row_meta$symbol
    )
})

test_that("make_se errors on mismatched sample IDs", {
    counts <- matrix(rpois(100, 50), nrow = 10, ncol = 10)
    rownames(counts) <- paste0("gene", 1:10)
    colnames(counts) <- paste0("sample", 1:10)
    meta <- data.frame(
        treatment = rep(c("ctrl", "trt"), each = 5),
        row.names = paste0("wrong", 1:10)
    )

    expect_error(make_se(counts, meta), "must match")
})

test_that("make_se errors on non-numeric counts", {
    counts <- matrix(letters[1:100], nrow = 10, ncol = 10)
    rownames(counts) <- paste0("gene", 1:10)
    colnames(counts) <- paste0("sample", 1:10)
    meta <- data.frame(
        treatment = rep(c("ctrl", "trt"), each = 5),
        row.names = colnames(counts)
    )

    expect_error(make_se(counts, meta), "numeric")
})

test_that("make_se errors when col_data is not a data.frame", {
    counts <- matrix(rpois(100, 50), nrow = 10, ncol = 10)
    rownames(counts) <- paste0("gene", 1:10)
    colnames(counts) <- paste0("sample", 1:10)

    expect_error(make_se(counts, "not a data.frame"), "data.frame")
})

test_that("make_se coerces non-matrix input", {
    counts_df <- data.frame(
        sample1 = rpois(5, 50),
        sample2 = rpois(5, 50),
        row.names = paste0("gene", 1:5)
    )
    meta <- data.frame(
        treatment = c("ctrl", "trt"),
        row.names = c("sample1", "sample2")
    )

    se <- make_se(counts_df, meta)
    expect_s4_class(se, "SummarizedExperiment")
    expect_equal(nrow(se), 5)
    expect_equal(ncol(se), 2)
})

# --- top_variable_features ---

test_that("top_variable_features returns correct subset size", {
    data(airway, package = "airway")

    se_top <- top_variable_features(airway, n = 50)

    expect_equal(nrow(se_top), 50)
    expect_equal(ncol(se_top), ncol(airway))
})

test_that("top_variable_features handles n > nrow gracefully", {
    data(airway, package = "airway")

    se_all <- top_variable_features(airway, n = 9999)

    expect_equal(nrow(se_all), nrow(airway))
})

test_that("top_variable_features returns most variable genes first", {
    data(airway, package = "airway")

    se_top <- top_variable_features(airway, n = 10)
    mat <- SummarizedExperiment::assay(se_top, "counts")
    vars <- apply(mat, 1, var)

    # All variances in top-10 should be >= the 11th highest
    full_mat <- SummarizedExperiment::assay(airway, "counts")
    full_vars <- sort(apply(full_mat, 1, var), decreasing = TRUE)
    expect_true(all(vars >= full_vars[11]))
})
