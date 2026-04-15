#' Shiny App UI
#'
#' @import shiny
#' @importFrom bslib page_sidebar sidebar navset_card_tab nav_panel bs_theme
#' @return A Shiny UI definition
#' @noRd
app_ui <- function() {
    page_sidebar(
        title = "ADS 8192 PCA Explorer",
        theme = bs_theme(bootswatch = "flatly"),
        sidebar = sidebar(
            h4(icon("cogs"), "Analysis Settings"),
            selectInput("assay_name", "Assay:", choices = NULL),
            numericInput(
                "n_top",
                "Top variable genes:",
                value = 500, min = 5, step = 50
            ),
            checkboxInput("log_transform", "Log-transform counts", TRUE),
            checkboxInput("scale", "Scale features", TRUE),
            hr(),
            h4(icon("palette"), "Visualization"),
            selectInput("color_by", "Color by:", choices = NULL),
            selectInput("shape_by", "Shape by:", choices = NULL),
            fluidRow(
                column(
                    6,
                    numericInput("pc_x", "PC X:",
                        value = 1,
                        min = 1, max = 8
                    )
                ),
                column(
                    6,
                    numericInput("pc_y", "PC Y:",
                        value = 2,
                        min = 1, max = 8
                    )
                )
            ),
            sliderInput("point_size", "Point size:",
                value = 4,
                min = 1, max = 10, step = 1
            ),
            hr(),
            downloadButton("download_plot", "Download Plot")
        ),
        navset_card_tab(
            nav_panel(
                "PCA Plot",
                plotOutput("pca_plot", height = "500px")
            ),
            nav_panel(
                "Variance",
                plotOutput("variance_plot", height = "400px")
            ),
            nav_panel(
                "Sample Data",
                DT::dataTableOutput("scores_table")
            )
        )
    )
}
