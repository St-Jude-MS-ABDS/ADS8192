# tests/testthat/test-plotting.R
# Tests for plot_pca()

test_that("plot_pca returns a ggplot object", {
    data(example_se, package = "ADS8192")
    result <- run_pca(example_se, n_top = 50)

    p <- plot_pca(result)

    expect_s3_class(p, "ggplot")
})

test_that("plot_pca works with color_by", {
    data(example_se, package = "ADS8192")
    result <- run_pca(example_se, n_top = 50)

    p <- plot_pca(result, color_by = "treatment")

    expect_s3_class(p, "ggplot")
})

test_that("plot_pca works with color_by and shape_by", {
    data(example_se, package = "ADS8192")
    result <- run_pca(example_se, n_top = 50)

    p <- plot_pca(result, color_by = "treatment", shape_by = "batch")

    expect_s3_class(p, "ggplot")
})

test_that("plot_pca works with different PCs", {
    data(example_se, package = "ADS8192")
    result <- run_pca(example_se, n_top = 50)

    p <- plot_pca(result, pcs = c(2, 3))

    expect_s3_class(p, "ggplot")
})

test_that("plot_pca errors on invalid PCs", {
    data(example_se, package = "ADS8192")
    result <- run_pca(example_se, n_top = 50)

    expect_error(plot_pca(result, pcs = c(1, 99)), "not found")
})

test_that("plot_pca respects point_size", {
    data(example_se, package = "ADS8192")
    result <- run_pca(example_se, n_top = 50)

    # Just verify it doesn't error with different sizes
    p <- plot_pca(result, point_size = 2)
    expect_s3_class(p, "ggplot")

    p <- plot_pca(result, point_size = 8)
    expect_s3_class(p, "ggplot")
})
