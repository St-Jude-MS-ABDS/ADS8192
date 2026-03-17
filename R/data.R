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
