#' Save PCA results to files
#'
#' Writes PCA scores and variance explained to tab-separated files.
#' Optionally saves a PCA plot as PNG.
#'
#' @param pca_result Output from \code{\link{run_pca}()}.
#' @param output_dir Directory to save files. Created if it does not exist.
#' @param prefix Prefix for filenames. Default: \code{"pca"}.
#'
#' @return Invisible \code{NULL}; files are written to \code{output_dir}:
#' \describe{
#'   \item{\code{{prefix}_scores.tsv}}{PCA scores with sample metadata.}
#'   \item{\code{{prefix}_variance.tsv}}{Variance explained by each PC.}
#' }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' data(airway, package = "airway")
#' result <- run_pca(airway, n_top = 50)
#' save_pca_results(result, tempdir())
#' }
save_pca_results <- function(pca_result, output_dir, prefix = "pca") {
    if (!dir.exists(output_dir)) {
        dir.create(output_dir, recursive = TRUE)
    }

    # Save scores
    scores_file <- file.path(output_dir, paste0(prefix, "_scores.tsv"))
    write.table(
        pca_result$scores,
        scores_file,
        sep = "\t",
        row.names = FALSE,
        quote = FALSE
    )

    # Save variance explained
    var_file <- file.path(output_dir, paste0(prefix, "_variance.tsv"))
    var_df <- pca_variance_explained(pca_result)
    write.table(
        var_df,
        var_file,
        sep = "\t",
        row.names = FALSE,
        quote = FALSE
    )

    message("Saved: ", scores_file)
    message("Saved: ", var_file)

    invisible(NULL)
}
