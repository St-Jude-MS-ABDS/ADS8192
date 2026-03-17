#' Create a PCA scatter plot
#'
#' Produces a ggplot2 scatter plot of PCA scores, with optional color and
#' shape aesthetics mapped to sample metadata columns.
#'
#' @param pca_result Output from \code{\link{run_pca}()}.
#' @param color_by Column name from \code{colData} to map to point color.
#'   Default: \code{NULL} (no color mapping).
#' @param shape_by Column name from \code{colData} to map to point shape.
#'   Default: \code{NULL} (no shape mapping).
#' @param pcs Integer vector of length 2 specifying which PCs to plot.
#'   Default: \code{c(1, 2)}.
#' @param point_size Numeric point size. Default: 4.
#'
#' @return A \code{\link[ggplot2]{ggplot}} object.
#'
#' @export
#'
#' @importFrom ggplot2 ggplot aes geom_point labs theme_minimal
#' @importFrom rlang .data
#'
#' @author Jared Andrews
#' @examples
#' data(airway, package = "airway")
#' result <- run_pca(airway, n_top = 50)
#' plot_pca(result, color_by = "dex")
plot_pca <- function(pca_result, color_by = NULL, shape_by = NULL,
                     pcs = c(1, 2), point_size = 4) {
    scores <- pca_result$scores
    var_exp <- pca_variance_explained(pca_result)

    # Build PC column names
    pc_x <- paste0("PC", pcs[1])
    pc_y <- paste0("PC", pcs[2])

    # Validate requested PCs exist
    if (!pc_x %in% colnames(scores)) {
        stop("PC", pcs[1], " not found in scores. Only ",
             sum(grepl("^PC\\d+$", colnames(scores))), " PCs available.",
             call. = FALSE)
    }
    if (!pc_y %in% colnames(scores)) {
        stop("PC", pcs[2], " not found in scores. Only ",
             sum(grepl("^PC\\d+$", colnames(scores))), " PCs available.",
             call. = FALSE)
    }

    # Get variance percentages for axis labels
    var_x <- round(var_exp$variance_percent[pcs[1]], 1)
    var_y <- round(var_exp$variance_percent[pcs[2]], 1)


    p <- ggplot(scores, aes(x = .data[[pc_x]], y = .data[[pc_y]])) +
        theme_bw(base_size = 14) +
        labs(
            x = paste0(pc_x, " (", var_x, "% variance)"),
            y = paste0(pc_y, " (", var_y, "% variance)"),
            title = "PCA Plot"
        )

    # Add aesthetics if specified
    if (!is.null(color_by)) {
        p <- p + aes(color = .data[[color_by]])
    }

    if (!is.null(shape_by)) {
        p <- p + aes(shape = .data[[shape_by]])
    }

    p <- p + geom_point(size = point_size)

    p
}


#' Plot variance explained by principal components
#'
#' Produces a bar chart showing the percentage of variance explained by each
#' principal component, using the output of \code{\link{run_pca}()}.
#'
#' @param pca_result Output from \code{\link{run_pca}()}.
#' @param n_pcs Maximum number of PCs to display. Default: 8.
#'
#' @return A \code{\link[ggplot2]{ggplot}} object.
#'
#' @export
#'
#' @importFrom ggplot2 ggplot aes geom_col geom_text labs ylim theme_bw
#' @importFrom rlang .data
#'
#' @author Jared Andrews
#' @examples
#' data(airway, package = "airway")
#' result <- run_pca(airway, n_top = 50)
#' plot_variance_explained(result)
plot_variance_explained <- function(pca_result, n_pcs = 8) {
    var_df <- pca_variance_explained(pca_result)
    var_df <- var_df[seq_len(min(n_pcs, nrow(var_df))), ]
    var_df$PC <- factor(var_df$PC, levels = var_df$PC)

    ggplot(var_df, aes(x = .data$PC, y = .data$variance_percent)) +
        geom_col(fill = "steelblue") +
        geom_text(
            aes(label = sprintf("%.1f%%", .data$variance_percent)),
            vjust = -0.5, size = 4
        ) +
        theme_bw(base_size = 14) +
        labs(
            x = "Principal Component",
            y = "Variance Explained (%)"
        ) +
        ylim(0, max(var_df$variance_percent) * 1.15)
}
