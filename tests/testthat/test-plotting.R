# tests/testthat/test-plotting.R
# Tests for plot_pca()

test_that("plot_pca returns a ggplot object", {
    data(airway, package = "airway")
    result <- run_pca(airway, n_top = 50)

    p <- plot_pca(result)

    expect_s3_class(p, "ggplot")
})

test_that("plot_pca works with color_by", {
    data(airway, package = "airway")
    result <- run_pca(airway, n_top = 50)

    p <- plot_pca(result, color_by = "dex")

    expect_s3_class(p, "ggplot")
})

test_that("plot_pca works with color_by and shape_by", {
    data(airway, package = "airway")
    result <- run_pca(airway, n_top = 50)

    p <- plot_pca(result, color_by = "dex", shape_by = "cell")

    expect_s3_class(p, "ggplot")
})

test_that("plot_pca works with different PCs", {
    data(airway, package = "airway")
    result <- run_pca(airway, n_top = 50)

    p <- plot_pca(result, pcs = c(2, 3))

    expect_s3_class(p, "ggplot")
})

test_that("plot_pca errors on invalid PCs", {
    data(airway, package = "airway")
    result <- run_pca(airway, n_top = 50)

    expect_error(plot_pca(result, pcs = c(1, 99)), "not found")
})

test_that("plot_pca respects point_size", {
    data(airway, package = "airway")
    result <- run_pca(airway, n_top = 50)

    # Just verify it doesn't error with different sizes
    p <- plot_pca(result, point_size = 2)
    expect_s3_class(p, "ggplot")

    p <- plot_pca(result, point_size = 8)
    expect_s3_class(p, "ggplot")
})
