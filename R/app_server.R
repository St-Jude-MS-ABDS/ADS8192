#' Shiny App Server
#'
#' @param input Shiny input
#' @param output Shiny output
#' @param session Shiny session
#' @param se A \code{SummarizedExperiment} object
#'
#' @return NULL (side effects only)
#' @noRd
#'
#' @import shiny
#' @importFrom SummarizedExperiment colData assayNames
#' @importFrom ggplot2 ggsave
#' @importFrom rlang .data
#' @importFrom utils data
#' @author Jared Andrews
app_server <- function(input, output, session, se) {
    se_data <- reactiveVal(se)

    # Update select inputs based on available metadata and assays
    observe({
        se <- se_data()
        req(se)
        cols <- colnames(colData(se))
        updateSelectInput(session, "color_by", choices = cols)
        updateSelectInput(session, "shape_by",
                                 choices = c("None", cols))
        updateSelectInput(session, "assay_name",
                                 choices = assayNames(se))
        updateNumericInput(session, "n_top",
                                  max = nrow(se))
    })

    # Compute PCA (cached; only re-runs when analysis params change)
    pca_result <- reactive({
        req(se_data(), input$n_top, input$assay_name)

        validate(
            need(input$n_top >= 10,
                        "Please select at least 10 genes"),
            need(input$n_top <= nrow(se_data()),
                        "Cannot select more genes than available")
        )

        run_pca(
            se_data(),
            assay_name = input$assay_name,
            n_top = input$n_top,
            log_transform = input$log_transform,
            scale = input$scale
        )
    })

    output$pca_plot <- renderPlot({
        req(pca_result(), input$color_by)

        n_pcs <- ncol(pca_result()$pca$x)
        validate(
            need(input$pc_x <= n_pcs,
                        paste("PC X must be <=", n_pcs)),
            need(input$pc_y <= n_pcs,
                        paste("PC Y must be <=", n_pcs)),
            need(input$pc_x != input$pc_y,
                        "Please select different PCs for X and Y"),
            need(input$point_size > 0,
                        "Point size must be positive")
        )

        shape <- if (is.null(input$shape_by) || input$shape_by == "None") {
            NULL
        } else {
            input$shape_by
        }

        plot_pca(
            pca_result(),
            color_by = input$color_by,
            shape_by = shape,
            pcs = c(input$pc_x, input$pc_y),
            point_size = input$point_size
        )
    })

    output$variance_plot <- renderPlot({
        req(pca_result())

        plot_variance_explained(pca_result())
    })

    output$scores_table <- DT::renderDataTable({
        req(pca_result())
        DT::datatable(
            pca_result()$scores,
            options = list(pageLength = 10, scrollX = TRUE)
        )
    })

    output$download_plot <- downloadHandler(
        filename = function() {
            paste0("pca_plot_", Sys.Date(), ".png")
        },
        content = function(file) {
            shape <- if (is.null(input$shape_by) ||
                         input$shape_by == "None") {
                NULL
            } else {
                input$shape_by
            }

            p <- plot_pca(
                pca_result(),
                color_by = input$color_by,
                shape_by = shape,
                point_size = input$point_size
            )

            ggsave(file, p, width = 8, height = 6, dpi = 300)
        }
    )
}
