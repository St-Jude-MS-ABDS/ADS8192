#' Shiny App UI
#'
#' @return A Shiny UI definition
#' @noRd
app_ui <- function() {
    bslib::page_sidebar(
        title = "ADS 8192 PCA Explorer",
        theme = bslib::bs_theme(bootswatch = "flatly"),
        sidebar = bslib::sidebar(
            shiny::h4(shiny::icon("cogs"), "Analysis Settings"),
            shiny::numericInput(
                "n_top",
                "Top variable genes:",
                value = 500, min = 50, max = 10000, step = 50
            ),
            shiny::checkboxInput("log_transform", "Log-transform counts", TRUE),
            shiny::checkboxInput("scale", "Scale features", TRUE),
            shiny::hr(),
            shiny::h4(shiny::icon("palette"), "Visualization"),
            shiny::selectInput("color_by", "Color by:", choices = NULL),
            shiny::selectInput("shape_by", "Shape by:", choices = NULL),
            shiny::fluidRow(
                shiny::column(
                    6,
                    shiny::numericInput("pc_x", "PC X:",
                        value = 1,
                        min = 1, max = 8
                    )
                ),
                shiny::column(
                    6,
                    shiny::numericInput("pc_y", "PC Y:",
                        value = 2,
                        min = 1, max = 8
                    )
                )
            ),
            shiny::sliderInput("point_size", "Point size:",
                value = 4,
                min = 1, max = 10, step = 1
            ),
            shiny::hr(),
            shiny::downloadButton("download_plot", "Download Plot")
        ),
        bslib::navset_card_tab(
            bslib::nav_panel(
                "PCA Plot",
                shiny::plotOutput("pca_plot", height = "500px")
            ),
            bslib::nav_panel(
                "Variance",
                shiny::plotOutput("variance_plot", height = "400px")
            ),
            bslib::nav_panel(
                "Sample Data",
                DT::dataTableOutput("scores_table")
            )
        )
    )
}
