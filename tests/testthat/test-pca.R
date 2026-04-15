# tests/testthat/test-pca.R
# Tests for run_pca() and pca_variance_explained()

test_that("run_pca returns correct structure", {
    data(example_se)

    result <- run_pca(example_se, n_top = 50)

    expect_type(result, "list")
    expect_named(result, c("pca", "scores"))
    expect_s3_class(result$pca, "prcomp")
    expect_s3_class(result$scores, "data.frame")
})

test_that("run_pca scores contain sample metadata", {
    data(example_se)

    result <- run_pca(example_se, n_top = 50)

    expect_true("treatment" %in% colnames(result$scores))
    expect_true("sample_id" %in% colnames(result$scores))
    expect_true("cell" %in% colnames(result$scores))
})

test_that("run_pca scores contain PC columns", {
    data(example_se)

    result <- run_pca(example_se, n_top = 50)

    expect_true("PC1" %in% colnames(result$scores))
    expect_true("PC2" %in% colnames(result$scores))
    # n_samples = 8, so at most 8 PCs
    n_samples <- ncol(example_se)
    expect_true(paste0("PC", n_samples) %in% colnames(result$scores))
})

test_that("run_pca works with log_transform = FALSE", {
    data(example_se)

    result <- run_pca(example_se, n_top = 50, log_transform = FALSE)

    expect_type(result, "list")
    expect_s3_class(result$pca, "prcomp")
})

test_that("run_pca works with scale = FALSE", {
    data(example_se)

    result <- run_pca(example_se, n_top = 50, scale = FALSE)

    expect_type(result, "list")
    expect_s3_class(result$pca, "prcomp")
})

test_that("run_pca produces deterministic output", {
    data(example_se)

    result1 <- run_pca(example_se, n_top = 50)
    result2 <- run_pca(example_se, n_top = 50)

    expect_equal(result1$scores$PC1, result2$scores$PC1)
    expect_equal(result1$scores$PC2, result2$scores$PC2)
})

# --- pca_variance_explained ---

test_that("pca_variance_explained returns percentages that sum to 100", {
    data(example_se)

    result <- run_pca(example_se, n_top = 50)
    var_df <- pca_variance_explained(result)

    expect_equal(sum(var_df$variance_percent), 100, tolerance = 0.01)
})

test_that("pca_variance_explained is sorted descending", {
    data(example_se)

    result <- run_pca(example_se, n_top = 50)
    var_df <- pca_variance_explained(result)

    expect_true(var_df$variance_percent[1] >= var_df$variance_percent[2])
})

test_that("pca_variance_explained has correct column names", {
    data(example_se)

    result <- run_pca(example_se, n_top = 50)
    var_df <- pca_variance_explained(result)

    expect_named(var_df, c("PC", "variance_percent"))
    expect_true(all(grepl("^PC\\d+$", var_df$PC)))
})
