# Lecture 8: Lab – Shiny (R) – Packaging, Documentation, and Deployment

## Learning Objectives

By the end of this session, you will be able to:

1.  Add a Shiny application to the package as a function and document it
2.  Deploy the application to a hosting platform (shinyapps.io or Posit
    Cloud)
3.  Add inputs for flexibility and interactive elements in outputs
4.  Discuss and (optionally) implement a basic testing strategy for
    Shiny apps

**Course Learning Outcomes (CLOs):** CLO 1, 4, 5, 6

------------------------------------------------------------------------

## Why Package Your Shiny App?

### Current State: Standalone App

Right now, your Shiny app is a standalone `app.R` file. To run it, users
need to:

1.  Clone your repo (or copy the file)
2.  Install all dependencies manually
3.  Run `shiny::runApp("path/to/app.R")`

### Goal: Packaged App

After packaging, users can:

``` r
# Install once
remotes::install_github("you/sePCA")

# Run anywhere
sePCA::run_app()
```

Benefits:

- **Single install command** handles all dependencies
- **Works anywhere** — no file paths to manage  
- **Version-controlled** — users get consistent behavior
- **Documented** —
  [`?run_app`](https://automatic-engine-4qp7m5e.pages.github.io/reference/run_app.md)
  shows how to use it

------------------------------------------------------------------------

## Part 1: Package Structure for Shiny Apps

### Where Does the App Go?

The conventional location is `inst/app/`:

    sePCA/
    ├── DESCRIPTION
    ├── NAMESPACE
    ├── R/
    │   ├── run_app.R        # Exported function to launch app
    │   ├── app_ui.R         # UI definition
    │   ├── app_server.R     # Server logic
    │   └── mod_*.R          # Module files
    ├── inst/
    │   └── app/
    │       └── app.R        # App entry point (calls run_app)
    └── ...

Why `inst/`?

- Files in `inst/` are copied as-is when the package is installed
- They’re accessible via `system.file("app", package = "sePCA")`
- The actual app logic lives in `R/` for documentation and testing

### Step 1: Create the Directory Structure

``` r
# In your package directory
dir.create("inst/app", recursive = TRUE)
```

### Step 2: Create App Files in R/

#### R/app_ui.R

``` r
# R/app_ui.R

#' Shiny App UI
#'
#' @return A Shiny UI definition
#' @noRd
app_ui <- function() {
    bslib::page_sidebar(
        title = "sePCA Explorer",
        theme = bslib::bs_theme(bootswatch = "flatly"),
        
        sidebar = bslib::sidebar(
            shiny::h4(shiny::icon("cogs"), "Analysis Settings"),
            
            shiny::numericInput(
                "n_top",
                "Top variable genes:",
                value = 500, min = 50, max = 5000, step = 50
            ),
            shiny::checkboxInput("log_transform", "Log-transform counts", TRUE),
            shiny::checkboxInput("scale", "Scale features", TRUE),
            
            shiny::hr(),
            shiny::h4(shiny::icon("palette"), "Visualization"),
            
            shiny::selectInput("color_by", "Color by:", choices = NULL),
            shiny::selectInput("shape_by", "Shape by:", choices = NULL),
            shiny::sliderInput("point_size", "Point size:", 4, 1, 10, 1),
            
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
```

#### R/app_server.R

``` r
# R/app_server.R

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
#' @importFrom ggplot2 ggplot aes geom_col geom_text theme_minimal labs ylim
#' @importFrom rlang .data
app_server <- function(input, output, session) {
    # Load example data
    # In a real app, you might want to let users upload their own data
    se_data <- shiny::reactive({
        data("airway", package = "airway", envir = environment())
        get("airway", envir = environment())
    })
    
    # Update select inputs based on available metadata
    shiny::observe({
        se <- se_data()
        cols <- colnames(SummarizedExperiment::colData(se))
        shiny::updateSelectInput(session, "color_by", choices = cols)
        shiny::updateSelectInput(session, "shape_by", choices = c("None", cols))
    })
    
    # Compute PCA
    pca_result <- shiny::reactive({
        shiny::req(se_data(), input$n_top)
        
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
        
        shape <- if (is.null(input$shape_by) || input$shape_by == "None") {
            NULL
        } else {
            input$shape_by
        }
        
        plot_pca(
            pca_result(),
            color_by = input$color_by,
            shape_by = shape,
            point_size = input$point_size
        )
    })
    
    # Variance plot
    output$variance_plot <- shiny::renderPlot({
        shiny::req(pca_result())
        
        var_df <- pca_variance_explained(pca_result())
        var_df <- var_df[seq_len(min(8, nrow(var_df))), ]
        var_df$PC <- factor(var_df$PC, levels = var_df$PC)
        
        ggplot2::ggplot(var_df, ggplot2::aes(x = .data$PC, y = .data$variance_percent)) +
            ggplot2::geom_col(fill = "steelblue") +
            ggplot2::geom_text(
                ggplot2::aes(label = sprintf("%.1f%%", .data$variance_percent)),
                vjust = -0.5, size = 4
            ) +
            ggplot2::theme_minimal(base_size = 14) +
            ggplot2::labs(
                x = "Principal Component",
                y = "Variance Explained (%)"
            ) +
            ggplot2::ylim(0, max(var_df$variance_percent) * 1.15)
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
            shape <- if (is.null(input$shape_by) || input$shape_by == "None") {
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
            
            ggplot2::ggsave(file, p, width = 8, height = 6, dpi = 150)
        }
    )
}
```

#### R/run_app.R

``` r
# R/run_app.R

#' Run the sePCA Shiny Application
#'
#' Launches an interactive Shiny application for exploring PCA results
#' on SummarizedExperiment data.
#'
#' @param ... Additional arguments passed to [shiny::shinyApp()]
#'
#' @return A Shiny app object (invisibly)
#' @export
#'
#' @examples
#' \dontrun{
#' run_app()
#' }
run_app <- function(...) {
    # Check for required packages
    if (!requireNamespace("shiny", quietly = TRUE)) {
        stop("Package 'shiny' is required. Install with: install.packages('shiny')")
    }
    if (!requireNamespace("bslib", quietly = TRUE)) {
        stop("Package 'bslib' is required. Install with: install.packages('bslib')")
    }
    if (!requireNamespace("DT", quietly = TRUE)) {
        stop("Package 'DT' is required. Install with: install.packages('DT')")
    }
    if (!requireNamespace("airway", quietly = TRUE)) {
        stop("Package 'airway' is required. Install with: BiocManager::install('airway')")
    }
    
    app <- shiny::shinyApp(
        ui = app_ui(),
        server = app_server,
        ...
    )
    
    shiny::runApp(app)
}
```

### Step 3: Create inst/app/app.R (Optional Entry Point)

This allows running the app via
`shiny::runApp(system.file("app", package = "sePCA"))`:

``` r
# inst/app/app.R

# Launch the sePCA Shiny application
# This file exists for compatibility with runApp()
# Preferred method: sePCA::run_app()

if (!requireNamespace("sePCA", quietly = TRUE)) {
    stop("Please install sePCA first: remotes::install_github('you/sePCA')")
}

sePCA:::app_ui
sePCA:::app_server

shiny::shinyApp(
    ui = sePCA:::app_ui(),
    server = sePCA:::app_server
)
```

------------------------------------------------------------------------

## Part 2: Dependencies for the App

### Updating DESCRIPTION

The Shiny app needs additional packages. Add them as Suggests (not
Imports) so the core package works without them:

``` r
library(usethis)

# Shiny app dependencies
use_package("shiny", type = "Suggests")
use_package("bslib", type = "Suggests")
use_package("DT", type = "Suggests")
use_package("airway", type = "Suggests")
use_package("rlang")  # For .data pronoun in ggplot2 aes()
```

Your DESCRIPTION now includes:

``` yaml
Suggests:
    airway,
    bslib,
    DT,
    knitr,
    shiny,
    testthat (>= 3.0.0)
```

### Why Suggests?

- Users who only want the R API don’t need shiny
- Keeps the core package lightweight
- [`run_app()`](https://automatic-engine-4qp7m5e.pages.github.io/reference/run_app.md)
  checks for packages at runtime

### Graceful Fallbacks

What if DT isn’t installed? Handle it gracefully:

``` r
# In app_ui.R, instead of:
DT::dataTableOutput("table")

# Use:
if (requireNamespace("DT", quietly = TRUE)) {
    DT::dataTableOutput("table")
} else {
    shiny::tableOutput("table")  # Basic fallback
}
```

> **Exercise A:** Ensure
> [`run_app()`](https://automatic-engine-4qp7m5e.pages.github.io/reference/run_app.md)
> works after installing from GitHub (no local relative paths). Test in
> a fresh R session.

------------------------------------------------------------------------

## Part 3: Documentation

### Document run_app()

We already added roxygen2 documentation. Run:

``` r
devtools::document()
```

Verify:

``` r
devtools::load_all()
?run_app
```

### Add pkgdown Article

``` r
usethis::use_vignette("shiny-app", title = "Using the Shiny App")
```

Edit `vignettes/shiny-app.Rmd`:

```` markdown
---
title: "Using the Shiny App"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{Using the Shiny App}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---

## Launching the App

After installing sePCA, launch the interactive PCA explorer:

```r
library(sePCA)
run_app()
```

## Features

### Analysis Settings

- **Top variable genes**: Number of most variable genes to include in PCA
- **Log-transform**: Apply log2(x + 1) transformation to counts
- **Scale features**: Center and scale genes before PCA

### Visualization Options

- **Color by**: Choose a metadata column to color samples
- **Shape by**: Optionally map a second variable to point shape
- **Point size**: Adjust point size for visibility

### Outputs

1. **PCA Plot**: Interactive scatter plot of principal components
2. **Variance**: Bar chart showing variance explained by each PC
3. **Sample Data**: Table of PCA scores merged with sample metadata

### Downloading Results

Click "Download Plot" to save the current PCA plot as a PNG file.
````

> **Exercise B:** Add screenshots to your vignette to make it more
> visual.

------------------------------------------------------------------------

## Part 4: Advanced Interactions

### Adding Tabs with Multiple Views

``` r
bslib::navset_card_tab(
    bslib::nav_panel("PCA Plot", plotOutput("pca_plot")),
    bslib::nav_panel("Loadings", plotOutput("loadings_plot")),
    bslib::nav_panel("Heatmap", plotOutput("heatmap")),
    bslib::nav_panel("Data", DT::dataTableOutput("scores_table"))
)
```

### Interactive Brushing

Let users select points on the plot:

``` r
# UI
plotOutput("pca_plot", brush = brushOpts(id = "plot_brush"))

# Server
output$selected_samples <- renderTable({
    req(input$plot_brush)
    scores <- pca_result()$scores
    brushedPoints(scores, input$plot_brush, xvar = "PC1", yvar = "PC2")
})
```

### Download Handlers

#### Download Plot

``` r
output$download_plot <- downloadHandler(
    filename = function() paste0("pca_", Sys.Date(), ".png"),
    content = function(file) {
        ggplot2::ggsave(file, current_plot(), width = 8, height = 6)
    }
)
```

#### Download Data (TSV)

``` r
output$download_scores <- downloadHandler(
    filename = function() paste0("pca_scores_", Sys.Date(), ".tsv"),
    content = function(file) {
        write.table(pca_result()$scores, file, sep = "\t", row.names = FALSE)
    }
)
```

> **Exercise C:** Pair up. Try to crash your partner’s app with weird
> inputs (extreme values, rapid clicking, etc.). Add validation to
> prevent it.

------------------------------------------------------------------------

## Part 5: Testing Shiny Apps

### The Challenge

Testing Shiny apps is harder than testing regular functions:

- Apps are stateful (inputs persist)
- Outputs depend on UI interactions
- Need a running R process

### Testing Strategy Options

#### 1. Test the Logic, Not the App

The best approach: keep logic in testable functions, test those:

``` r
# The core logic is already tested
test_that("run_pca works", { ... })
test_that("plot_pca works", { ... })

# The Shiny app just wires things together
```

#### 2. Smoke Tests with shinytest2

For end-to-end testing:

``` r
# Install
install.packages("shinytest2")

# Set up
shinytest2::use_shinytest2()
```

Create `tests/testthat/test-app.R`:

``` r
test_that("app starts without error", {
    skip_on_cran()  # Skip on CRAN (no display)
    skip_if_not_installed("shinytest2")
    
    app <- shinytest2::AppDriver$new(
        app_dir = system.file("app", package = "sePCA"),
        name = "pca-app"
    )
    
    # Check initial state
    expect_equal(app$get_value(input = "n_top"), 500)
    
    # Change an input
    app$set_inputs(n_top = 1000)
    
    # Wait for outputs to update
    app$wait_for_idle()
    
    # Take a snapshot (optional)
    app$expect_screenshot()
    
    app$stop()
})
```

#### 3. Manual Testing Checklist

For HW1, a manual checklist is acceptable:

App launches without error

Changing n_top updates the plot

Changing color_by updates colors

Download button produces a file

No errors in the R console during use

------------------------------------------------------------------------

## Part 6: Deployment

Naturally, we want to share our app with others! There are a few
different approaches to do this, but the simplest is to deploy to Posit
Cloud for free.

### Option 1: Posit Cloud

1.  Create a new project from Git
2.  Install your package: `remotes::install_github("you/sePCA")`
3.  Create an `app.R` that calls `sePCA::run_app()`
4.  Click “Publish”

### Record the URL

After deploying, add to your README:

``` markdown
## Interactive App

Try the app online: https://your-account.shinyapps.io/sePCA/

Or run locally:

```r
sePCA::run_app()
```

    ---

    # Summary

    Today we:

    1. Packaged the Shiny app with proper structure (`R/` for logic, `inst/app/` for entry point)
    2. Added `run_app()` as a documented, exported function
    3. Used Suggests for optional Shiny dependencies
    4. Added interactive features (tabs, download handlers)
    5. Discussed testing strategies

    ## Package Milestone

    ✅ The Shiny app is shipped inside the package and can be launched by users after installing from GitHub.

    ---

    # After-Class Tasks

    ## Micro-task 1: GitHub Test

    From a fresh R session:


    ``` r
    # Start clean
    .rs.restartR()

    # Install from GitHub
    remotes::install_github("you/sePCA")

    # Run the app
    sePCA::run_app()

### Micro-task 2: Update README

Add an “Interactive App” section to README with:

- Instructions to launch
- Screenshot or GIF (optional but nice!)
- Link to deployed version (if you deployed)

### Optional: Deploy

Deploy to shinyapps.io and record the URL in your README.

------------------------------------------------------------------------

## Complete File Reference

### Final Directory Structure

    sePCA/
    ├── DESCRIPTION
    ├── NAMESPACE
    ├── LICENSE.md
    ├── README.Rmd
    ├── README.md
    ├── R/
    │   ├── data.R
    │   ├── pca.R
    │   ├── plotting.R
    │   ├── export.R
    │   ├── app_ui.R
    │   ├── app_server.R
    │   └── run_app.R
    ├── inst/
    │   └── app/
    │       └── app.R
    ├── man/
    │   ├── run_app.Rd
    │   └── ...
    ├── tests/
    │   ├── testthat/
    │   │   └── ...
    │   └── testthat.R
    ├── vignettes/
    │   ├── getting-started.Rmd
    │   └── shiny-app.Rmd
    └── _pkgdown.yml

------------------------------------------------------------------------

## Session Info

``` r
sessionInfo()
```

    ## R version 4.5.2 (2025-10-31)
    ## Platform: x86_64-pc-linux-gnu
    ## Running under: Ubuntu 24.04.3 LTS
    ## 
    ## Matrix products: default
    ## BLAS:   /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3 
    ## LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so;  LAPACK version 3.12.0
    ## 
    ## locale:
    ##  [1] LC_CTYPE=C.UTF-8       LC_NUMERIC=C           LC_TIME=C.UTF-8       
    ##  [4] LC_COLLATE=C.UTF-8     LC_MONETARY=C.UTF-8    LC_MESSAGES=C.UTF-8   
    ##  [7] LC_PAPER=C.UTF-8       LC_NAME=C              LC_ADDRESS=C          
    ## [10] LC_TELEPHONE=C         LC_MEASUREMENT=C.UTF-8 LC_IDENTIFICATION=C   
    ## 
    ## time zone: UTC
    ## tzcode source: system (glibc)
    ## 
    ## attached base packages:
    ## [1] stats     graphics  grDevices utils     datasets  methods   base     
    ## 
    ## loaded via a namespace (and not attached):
    ##  [1] digest_0.6.39     desc_1.4.3        R6_2.6.1          fastmap_1.2.0    
    ##  [5] xfun_0.56         cachem_1.1.0      knitr_1.51        htmltools_0.5.9  
    ##  [9] rmarkdown_2.30    lifecycle_1.0.5   cli_3.6.5         sass_0.4.10      
    ## [13] pkgdown_2.2.0     textshaping_1.0.4 jquerylib_0.1.4   systemfonts_1.3.2
    ## [17] compiler_4.5.2    tools_4.5.2       ragg_1.5.0        bslib_0.10.0     
    ## [21] evaluate_1.0.5    yaml_2.3.12       otel_0.2.0        jsonlite_2.0.0   
    ## [25] rlang_1.1.7       fs_1.6.6          htmlwidgets_1.6.4
