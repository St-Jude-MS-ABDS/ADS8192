#' Run PCA on a SummarizedExperiment
#'
#' Performs principal component analysis on a
#' \code{\link[SummarizedExperiment]{SummarizedExperiment}}, first selecting
#' the top variable features, optionally log-transforming and scaling.
#'
#' @param se A \code{\link[SummarizedExperiment]{SummarizedExperiment}} object.
#' @param assay_name Name of the assay to use. Default: \code{"counts"}.
#' @param n_top Number of top variable features for PCA. Default: 500.
#' @param scale Logical; should features be scaled? Default: \code{TRUE}.
#' @param log_transform Logical; should counts be log2-transformed (with
#'   pseudocount of 1)? Default: \code{TRUE}.
#'
#' @return A list with two elements:
#' \describe{
#'   \item{pca}{The \code{\link[stats]{prcomp}} result object.}
#'   \item{scores}{A data.frame of PC scores merged with sample metadata
#'     from \code{colData(se)}.}
#' }
#'
#' @export
#'
#' @importFrom SummarizedExperiment assay colData
#'
#' @examples
#' data(airway, package = "airway")
#' result <- run_pca(airway, n_top = 50)
#' head(result$scores)
run_pca <- function(se, assay_name = "counts", n_top = 500,
                    scale = TRUE, log_transform = TRUE) {
    # Subset to top variable features
    se_top <- top_variable_features(se, n = n_top, assay_name = assay_name)

    # Get the data matrix
    mat <- assay(se_top, assay_name)

    # Log-transform if requested (add pseudocount to avoid log(0))
    if (log_transform) {
        mat <- log2(mat + 1)
    }

    # Transpose: prcomp expects samples as rows
    mat_t <- t(mat)

    # Run PCA
    pca_result <- prcomp(mat_t, scale. = scale, center = TRUE)

    # Create scores data.frame with sample metadata
    scores <- as.data.frame(pca_result$x)
    scores$sample_id <- rownames(scores)

    # Merge with colData, preserving sample order
    col_data <- as.data.frame(colData(se))
    col_data$sample_id <- rownames(col_data)
    scores <- merge(scores, col_data, by = "sample_id")

    # Sort by sample_id for deterministic output
    scores <- scores[order(scores$sample_id), ]
    rownames(scores) <- NULL

    list(
        pca = pca_result,
        scores = scores
    )
}


#' Get variance explained by each PC
#'
#' Extracts the percentage of variance explained by each principal component
#' from the output of \code{\link{run_pca}}.
#'
#' @param pca_result Output from \code{\link{run_pca}()}.
#'
#' @return A data.frame with columns:
#' \describe{
#'   \item{PC}{Character, e.g. \code{"PC1"}, \code{"PC2"}.}
#'   \item{variance_percent}{Numeric, percentage of total variance explained.}
#' }
#'
#' @export
#'
#' @examples
#' data(airway, package = "airway")
#' result <- run_pca(airway, n_top = 50)
#' var_df <- pca_variance_explained(result)
#' head(var_df)
pca_variance_explained <- function(pca_result) {
    pca <- pca_result$pca
    var_explained <- pca$sdev^2 / sum(pca$sdev^2) * 100

    data.frame(
        PC = paste0("PC", seq_along(var_explained)),
        variance_percent = var_explained
    )
}
