#' Example SummarizedExperiment for testing
#'
#' A small simulated \code{\link[SummarizedExperiment]{SummarizedExperiment}}
#' with 100 genes and 8 samples, designed for testing and examples.
#' The first 20 genes have a simulated treatment effect (2x higher counts
#' in treated samples).
#'
#' @format A \code{\link[SummarizedExperiment]{SummarizedExperiment}} with:
#' \describe{
#'   \item{assays}{\code{counts} — raw count matrix (100 genes x 8 samples)}
#'   \item{colData}{\code{sample_id}, \code{treatment} (control/treated),
#'     \code{batch} (A/B)}
#'   \item{rowData}{\code{gene_id}, \code{gene_symbol}}
#' }
#'
#' @source Simulated data for teaching purposes.
#'
#' @examples
#' data(example_se)
#' example_se
#' SummarizedExperiment::colData(example_se)
"example_se"
