#' @keywords internal
"_PACKAGE"

#' @name ADS8192-package
#' @aliases ADS8192
#'
#' @title ADS 8192: Developing Scientific Applications
#'
#' @description
#' Course materials and reference implementation for ADS 8192.
#' Demonstrates the "three interfaces, one core" architecture:
#' PCA analysis functions for SummarizedExperiment objects,
#' a Shiny interactive explorer, and a command-line interface via Rapp.
#'
#' @section Core Analysis Functions:
#' \itemize{
#'   \item \code{\link{make_se}}: Create a SummarizedExperiment from counts
#'     and metadata
#'   \item \code{\link{top_variable_features}}: Select the most variable genes
#'   \item \code{\link{run_pca}}: Run PCA on a SummarizedExperiment
#'   \item \code{\link{pca_variance_explained}}: Get variance explained by
#'     each PC
#'   \item \code{\link{plot_pca}}: Create PCA scatter plots
#'   \item \code{\link{save_pca_results}}: Export PCA results to files
#' }
#'
#' @section Interactive App:
#' \itemize{
#'   \item \code{\link{run_app}}: Launch the Shiny PCA Explorer
#' }
#'
#' @importFrom rlang .data
#' @importFrom methods is
#' @importFrom stats prcomp var
#' @importFrom utils write.table read.table
NULL
