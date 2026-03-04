#' Run the PCA Explorer Shiny Application
#'
#' Launches an interactive Shiny application for exploring PCA results
#' on SummarizedExperiment data. The app uses the \code{airway} dataset
#' by default and wraps the package's core analysis functions.
#'
#' @param ... Additional arguments passed to \code{\link[shiny]{shinyApp}()}.
#'
#' @return A Shiny app object (invisibly).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' run_app()
#' }
run_app <- function(...) {
    if (!requireNamespace("shiny", quietly = TRUE)) {
        stop("Package 'shiny' is required. Install with: ",
             "install.packages('shiny')", call. = FALSE)
    }
    if (!requireNamespace("bslib", quietly = TRUE)) {
        stop("Package 'bslib' is required. Install with: ",
             "install.packages('bslib')", call. = FALSE)
    }
    if (!requireNamespace("DT", quietly = TRUE)) {
        stop("Package 'DT' is required. Install with: ",
             "install.packages('DT')", call. = FALSE)
    }
    if (!requireNamespace("airway", quietly = TRUE)) {
        stop("Package 'airway' is required. Install with: ",
             "BiocManager::install('airway')", call. = FALSE)
    }

    app <- shiny::shinyApp(
        ui = app_ui(),
        server = app_server,
        ...
    )

    shiny::runApp(app)
}
