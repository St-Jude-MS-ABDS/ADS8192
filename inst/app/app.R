# Launch the ADS8192 PCA Explorer Shiny application.
# This file exists for compatibility with shiny::runApp().
# Preferred method: ADS8192::run_app()

if (!requireNamespace("ADS8192", quietly = TRUE)) {
    stop("Please install ADS8192 first: remotes::install_github('YOUR-USERNAME/ADS8192')")
}

shiny::shinyApp(
    ui = ADS8192:::app_ui(),
    server = ADS8192:::app_server
)
