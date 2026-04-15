#' Run the PCA Explorer Shiny Application
#'
#' Launches an interactive Shiny application for exploring PCA results
#' on SummarizedExperiment data. The app allows users to select assays, adjust PCA parameters,
#' and visualize results with customizable options.
#'
#' @param se A \code{\link[SummarizedExperiment]{SummarizedExperiment}} object
#'   to explore.
#' @param return_as_list If \code{TRUE}, returns a list containing the UI and
#'   server functions instead of launching the app. Useful for certain deployment
#'   scenarios.
#' @param ... Additional arguments passed to \code{\link[shiny]{shinyApp}()}.
#'
#' @return A Shiny app object or a named list containing the UI and
#'   server functions if \code{return_as_list = TRUE}.
#'
#'
#' @import shiny
#' @importFrom methods is
#' @export
#' @author Jared Andrews
#'
#' @examples
#' if (interactive()) {
#'   library(ADS8192)
#'   data("example_se")
#'   run_app(se = example_se)
#' }
run_app <- function(se, return_as_list = FALSE, ...) {
    if (!requireNamespace("shiny", quietly = TRUE)) {
        stop("Package 'shiny' is required for app usage. Install with: ",
             "install.packages('shiny')", call. = FALSE)
    }
    if (!requireNamespace("bslib", quietly = TRUE)) {
        stop("Package 'bslib' is required for app usage. Install with: ",
             "install.packages('bslib')", call. = FALSE)
    }
    if (!requireNamespace("DT", quietly = TRUE)) {
        stop("Package 'DT' is required for app usage. Install with: ",
             "install.packages('DT')", call. = FALSE)
    }

    if (!is(se, "SummarizedExperiment")) {
        stop("'se' must be a SummarizedExperiment object.", call. = FALSE)
    }

    server <- function(input, output, session) {
        app_server(input, output, session, se = se)
    }

    app <- shiny::shinyApp(
        ui = app_ui(),
        server = server,
        ...
    )

    if (return_as_list) {
        return(list(ui = app_ui(), server = server))
    } else {
        app
    }
}
