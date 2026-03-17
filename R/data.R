#' Create a SummarizedExperiment from counts and metadata
#'
#' Constructs a \code{\link[SummarizedExperiment]{SummarizedExperiment}} from
#' a counts matrix and sample metadata data.frame. Optionally includes
#' row (gene/feature) metadata.
#'
#' @param counts A matrix of counts (genes x samples). Row names should be
#'   gene identifiers, column names should be sample identifiers. If not a
#'   matrix, will be coerced via \code{as.matrix()}.
#' @param col_data A data.frame of sample metadata. Row names must match
#'   column names of \code{counts}.
#' @param row_data Optional data.frame of gene/feature metadata. Row names
#'   must match row names of \code{counts}. Default: \code{NULL}.
#'
#' @return A \code{\link[SummarizedExperiment]{SummarizedExperiment}} object
#'   with one assay named \code{"counts"}.
#'
#' @export
#'
#' @importFrom SummarizedExperiment SummarizedExperiment
#'
#' @author Jared Andrews
#' @examples
#' counts <- matrix(rpois(100, 50), nrow = 10, ncol = 10)
#' rownames(counts) <- paste0("gene", 1:10)
#' colnames(counts) <- paste0("sample", 1:10)
#' meta <- data.frame(
#'   treatment = rep(c("ctrl", "trt"), each = 5),
#'   row.names = colnames(counts)
#' )
#' se <- make_se(counts, meta)
#' se
make_se <- function(counts, col_data, row_data = NULL) {
    if (!is.matrix(counts)) {
        counts <- as.matrix(counts)
    }

    if (!is.numeric(counts)) {
        stop("counts must be a numeric matrix", call. = FALSE)
    }

    if (!is.data.frame(col_data)) {
        stop("col_data must be a data.frame", call. = FALSE)
    }

    if (!all(colnames(counts) %in% rownames(col_data))) {
        stop("Column names of counts must match row names of col_data",
             call. = FALSE)
    }

    # Reorder col_data to match counts column order
    col_data <- col_data[colnames(counts), , drop = FALSE]

    if (is.null(row_data)) {
        SummarizedExperiment(
            assays = list(counts = counts),
            colData = col_data
        )
    } else {
        if (!is.data.frame(row_data)) {
            stop("row_data must be a data.frame", call. = FALSE)
        }
        row_data <- row_data[rownames(counts), , drop = FALSE]
        SummarizedExperiment(
            assays = list(counts = counts),
            colData = col_data,
            rowData = row_data
        )
    }
}


#' Select top variable features
#'
#' Subsets a \code{\link[SummarizedExperiment]{SummarizedExperiment}} to the
#' \code{n} most variable features (genes), ranked by row variance.
#'
#' @param se A \code{\link[SummarizedExperiment]{SummarizedExperiment}} object.
#' @param n Number of top variable features to select. Default: 500.
#' @param assay_name Name of the assay to use. Default: \code{"counts"}.
#'
#' @return A \code{\link[SummarizedExperiment]{SummarizedExperiment}} subset
#'   to the top \code{n} variable features, preserving all sample metadata.
#'
#' @export
#'
#' @importFrom SummarizedExperiment assay
#'
#' @examples
#' data(airway, package = "airway")
#' se_top <- top_variable_features(airway, n = 50)
#' dim(se_top)
top_variable_features <- function(se, n = 500, assay_name = "counts") {
    mat <- assay(se, assay_name)
    vars <- apply(mat, 1, var)
    top_idx <- order(vars, decreasing = TRUE)[seq_len(min(n, length(vars)))]
    se[top_idx, ]
}
