# tests/testthat/test-data.R
# Tests for top_variable_features()

# --- top_variable_features ---

test_that("top_variable_features returns correct subset size", {
    data(example_se)

    se_top <- top_variable_features(example_se, n = 50)

    expect_equal(nrow(se_top), 50)
    expect_equal(ncol(se_top), ncol(example_se))
})

test_that("top_variable_features handles n > nrow gracefully", {
    data(example_se)

    se_all <- top_variable_features(example_se, n = 100000)

    expect_equal(nrow(se_all), nrow(example_se))
})

test_that("top_variable_features returns most variable genes first", {
    data(example_se)

    se_top <- top_variable_features(example_se, n = 10)
    mat <- SummarizedExperiment::assay(se_top, "counts")
    vars <- apply(mat, 1, var)

    # All variances in top-10 should be >= the 11th highest
    full_mat <- SummarizedExperiment::assay(example_se, "counts")
    full_vars <- sort(apply(full_mat, 1, var), decreasing = TRUE)
    expect_true(all(vars >= full_vars[11]))
})
