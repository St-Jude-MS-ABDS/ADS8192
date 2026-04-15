# tests/testthat/test-export.R
# Tests for save_pca_results()

test_that("save_pca_results creates output files", {
    data(example_se)
    result <- run_pca(example_se, n_top = 50)

    tmp_dir <- file.path(tempdir(), "test_export")
    on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

    expect_message(
        save_pca_results(result, tmp_dir, prefix = "test"),
        "Saved"
    )

    expect_true(file.exists(file.path(tmp_dir, "test_scores.tsv")))
    expect_true(file.exists(file.path(tmp_dir, "test_variance.tsv")))
})

test_that("save_pca_results scores file has correct structure", {
    data(example_se)
    result <- run_pca(example_se, n_top = 50)

    tmp_dir <- file.path(tempdir(), "test_export2")
    on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

    suppressMessages(save_pca_results(result, tmp_dir))

    scores <- utils::read.table(
        file.path(tmp_dir, "pca_scores.tsv"),
        header = TRUE, sep = "\t"
    )

    expect_true("PC1" %in% colnames(scores))
    expect_true("sample_id" %in% colnames(scores))
    expect_true("treatment" %in% colnames(scores))
    expect_equal(nrow(scores), ncol(example_se))
})

test_that("save_pca_results variance file has correct structure", {
    data(example_se)
    result <- run_pca(example_se, n_top = 50)

    tmp_dir <- file.path(tempdir(), "test_export3")
    on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

    suppressMessages(save_pca_results(result, tmp_dir))

    var_df <- utils::read.table(
        file.path(tmp_dir, "pca_variance.tsv"),
        header = TRUE, sep = "\t"
    )

    expect_named(var_df, c("PC", "variance_percent"))
    expect_equal(sum(var_df$variance_percent), 100, tolerance = 0.01)
})

test_that("save_pca_results creates output directory if needed", {
    data(example_se)
    result <- run_pca(example_se, n_top = 50)

    tmp_dir <- file.path(tempdir(), "test_nested", "deep", "dir")
    on.exit(unlink(file.path(tempdir(), "test_nested"), recursive = TRUE),
            add = TRUE)

    expect_false(dir.exists(tmp_dir))
    suppressMessages(save_pca_results(result, tmp_dir))
    expect_true(dir.exists(tmp_dir))
})
