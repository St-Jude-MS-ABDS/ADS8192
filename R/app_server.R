#' Shiny App Server
#'
#' @param input Shiny input
#' @param output Shiny output
#' @param session Shiny session
#'
#' @return NULL (side effects only)
#' @noRd
#'
#' @importFrom SummarizedExperiment colData
#' @importFrom ggplot2 ggplot aes geom_col geom_text theme_minimal labs ylim ggsave
#' @importFrom rlang .data
#' @importFrom utils data
app_server <- function(input, output, session) {
    # Load example data (airway dataset)
    se_data <- shiny::reactive({
        if (!requireNamespace("airway", quietly = TRUE)) {
            shiny::showNotification(
                "airway package required. Install with: BiocManager::install('airway')",
                type = "error"
            )
            return(NULL)
        }
        env <- new.env(parent = emptyenv())
        data("airway", package = "airway", envir = env)
        env$airway
    })

    # Update select inputs based on available metadata
    shiny::observe({
        se <- se_data()
        shiny::req(se)
        cols <- colnames(colData(se))
        shiny::updateSelectInput(session, "color_by", choices = cols)
        shiny::updateSelectInput(session, "shape_by",
                                 choices = c("None", cols))
    })

    # Compute PCA (cached; only re-runs when analysis params change)
    pca_result <- shiny::reactive({
        shiny::req(se_data(), input$n_top)

        shiny::validate(
            shiny::need(input$n_top >= 10,
                        "Please select at least 10 genes"),
            shiny::need(input$n_top <= nrow(se_data()),
                        "Cannot select more genes than available")
        )

        run_pca(
            se_data(),
            n_top = input$n_top,
            log_transform = input$log_transform,
            scale = input$scale
        )
    })

    # PCA scatter plot
    output$pca_plot <- shiny::renderPlot({
        shiny::req(pca_result(), input$color_by)

        n_pcs <- ncol(pca_result()$pca$x)
        shiny::validate(
            shiny::need(input$pc_x <= n_pcs,
                        paste("PC X must be <=", n_pcs)),
            shiny::need(input$pc_y <= n_pcs,
                        paste("PC Y must be <=", n_pcs)),
            shiny::need(input$pc_x != input$pc_y,
                        "Please select different PCs for X and Y"),
            shiny::need(input$point_size > 0,
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

    # Variance plot
    output$variance_plot <- shiny::renderPlot({
        shiny::req(pca_result())

        var_df <- pca_variance_explained(pca_result())
        var_df <- var_df[seq_len(min(8, nrow(var_df))), ]
        var_df$PC <- factor(var_df$PC, levels = var_df$PC)

        ggplot(var_df, aes(x = .data$PC, y = .data$variance_percent)) +
            geom_col(fill = "steelblue") +
            geom_text(
                aes(label = sprintf("%.1f%%", .data$variance_percent)),
                vjust = -0.5, size = 4
            ) +
            theme_minimal(base_size = 14) +
            labs(
                x = "Principal Component",
                y = "Variance Explained (%)"
            ) +
            ylim(0, max(var_df$variance_percent) * 1.15)
    })

    # Scores table
    output$scores_table <- DT::renderDataTable({
        shiny::req(pca_result())
        DT::datatable(
            pca_result()$scores,
            options = list(pageLength = 10, scrollX = TRUE)
        )
    })

    # Download handler
    output$download_plot <- shiny::downloadHandler(
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

            ggsave(file, p, width = 8, height = 6, dpi = 150)
        }
    )
}
