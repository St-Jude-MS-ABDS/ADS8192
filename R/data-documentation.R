#' Example SummarizedExperiment for testing
#'
#' A small SummarizedExperiment with 10000 genes and 8 samples.
#' Includes a treatment effect in the first 500 genes.
#'
#' @format A SummarizedExperiment with:
#' \describe{
#'   \item{assays}{counts - raw count matrix}
#'   \item{colData}{sample_id, treatment (control/treated), batch (A/B)}
#'   \item{rowData}{gene_id, gene_symbol}
#' }
#'
#' @source Simulated data for teaching purposes
#'
#' @examples
#' library(SummarizedExperiment)
#' data(example_se)
#' example_se
#' colData(example_se)
"example_se"
