# Lecture 8: Lab – Shiny (R) – Packaging, Documentation, and Deployment

## Motivation

A standalone app using your data alone is useful. But *packaging* the
app into your R package makes it easier to maintain, share, and deploy.
It also makes it simple to keep the app code aligned with the core
package logic.

### Learning Objectives

By the end of this session, you will be able to:

1.  Add a Shiny application to the package as a function and document it
2.  Deploy the application to a hosting platform (Posit Cloud)
3.  Discuss basic testing strategies for Shiny apps

### Scientific Use Case

Your lab wants to share a small QC dashboard with collaborators at
another institution. Some users will explore the app interactively,
while others only want the package functions in scripts.

------------------------------------------------------------------------

## Why Package Your Shiny App?

### Current State: Standalone App

Right now, your Shiny app is a standalone `app.R` file. To run it, users
need to:

1.  Clone your repo (or copy the file)
2.  Install all dependencies manually
3.  Like change data inputs to point to their own files
4.  Run `shiny::runApp("path/to/app.R")`

### Goal: Packaged App

After packaging, users can easily run the app on arbitrary data.

``` r
library(ADS8192)

# Run with built-in example data
data("example_se")
run_app(se = example_se)

# Or supply your own SummarizedExperiment
library(airway)
data("airway")
run_app(se = airway)
```

Benefits:

- **Single install command** handles all dependencies
- **Works anywhere** — no file paths to manage
- **Works on any data** — pass any SummarizedExperiment
- **Version-controlled** — users get consistent behavior
- **Documented** —
  [`?run_app`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_app.md)
  shows how to use it, parameters, etc

------------------------------------------------------------------------

## Part 1: Package Structure for Shiny Apps

Functionizing a Shiny app and adding it to a package requires a few
adjustments to the typical Shiny app structure. The key is to separate
the UI and server logic into functions that can be called from a wrapper
function (e.g.,
[`run_app()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_app.md))
that returns the app.

We will also make a tweak to the directory structure to accommodate
deployment platforms that expect a standalone `app.R` file.

### Step 1: Create App Files in R/

#### R/app_ui.R

Now create `R/app_ui.R` with the UI definition. This is a standard Shiny
UI function, but it’s wrapped in a function that can be called from
[`run_app()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_app.md).

This should largely just require copy-pasting your existing UI code, but
it may require adjustments to your server logic to update the available
choices for some of the inputs based on the data provided.

``` r
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
```

#### R/app_server.R

Now create `R/app_server.R` with the server logic. This function takes
the Shiny `input`, `output`, and `session` objects, as well as the
`SummarizedExperiment` data, and contains all the reactive logic for the
app.

**R/app_server.R** (click to expand)

``` r
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
        updateNumericInput(session, "pc_x", max = ncol(se))
        updateNumericInput(session, "pc_y", max = ncol(se))
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
```

#### R/run_app.R

**R/run_app.R** (click to expand)

``` r
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
```

At this point, you should be able to run your app using this function,
and it should work with arbitrary data:

``` r
library(ADS8192)
data("example_se")
run_app(se = example_se)

# Should also work with other SummarizedExperiment objects
library(airway)
data("airway")
run_app(se = airway)
```

------------------------------------------------------------------------

## Part 2: Dependencies for the App

### Updating DESCRIPTION

The Shiny app needs additional packages. If we wanted to, we could make
these packages optional by putting them in `Suggests` instead of
`Imports`. This way, users who only want the R API don’t need to install
Shiny and its dependencies. If we did that, we’d also need to check for
those packages at runtime in
[`run_app()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_app.md)
and give a helpful error message if they’re missing.

``` r
library(usethis)

# Shiny app dependencies
use_package("shiny")
use_package("bslib")
use_package("DT")
```

> **Exercise A:** Ensure
> [`run_app()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_app.md)
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

You can either add to your existing vignette or create a new one focused
on the app, e.g.:

``` r
usethis::use_vignette("shiny-app", title = "Using the Shiny App")
```

At minimum, how to launch the app and what features it has. A screenshot
or GIF is a nice touch!

------------------------------------------------------------------------

## Part 4: Testing Shiny Apps

### The Challenge

Testing Shiny apps is harder than testing regular functions:

- Apps are stateful (inputs persist)
- Outputs depend on UI interactions
- Need a running R process

### Testing Strategy Options

#### 1. Test the Logic, Not the App

The simplest approach is to keep logic in testable functions and test
those:

``` r
# The core logic is already tested
test_that("run_pca works", { ... })
test_that("plot_pca works", { ... })

# The Shiny app just wires things together
```

#### 2. Smoke Tests with shinytest2

For more thorough testing, you can use
[shinytest2](https://rstudio.github.io/shinytest2/index.html) to
simulate user interactions and verify outputs. This is more complex to
set up and maintain, but it can catch issues that unit tests miss,
particularly when you have complex reactive logic.

#### 3. Manual Testing Checklist

For HW1, a manual checklist is acceptable:

App launches without error

Changing inputs updates things

Download button produces a file

No errors in the R console during use

------------------------------------------------------------------------

## Part 5: Deployment (Optional)

Allowing users to run your app locally is fine, but sometimes you may
want to deploy the application with your own data for a collaborator to
use, to serve as a companion app for a publication, or to serve as an
example to show off its functionality without requiring users to install
R or the package.

In our case, we want want an example of our app so that potential users
can test it out, for which we can use the example data.

**Note, you do not need to deploy your app for HW1.** This is an
optional step that can be done after the assignment is submitted (or not
at all), but it is worth knowing about this aspect of Shiny development.

### Deployment Options

| Option                   | Audience               | Cost                | Infrastructure               |
|--------------------------|------------------------|---------------------|------------------------------|
| Posit Connect            | Internal/institutional | Subscription        | Posit-managed or self-hosted |
| Self-hosted Shiny Server | Any                    | Free (open source)  | Your own server              |
| Posit Connect Cloud      | Any                    | Free tier available | Posit-managed                |

We’ll be deploying to [Posit Connect
Cloud](https://connect.posit.cloud/), which is a simple way to deploy a
Shiny application directly from a Github repository. It handles all the
infrastructure and scaling for you, and it integrates well with R
packages.

It also has a free tier that is sufficient for lightweight apps.

#### Deployment Steps

1.  Sign in to Posit Connect Cloud with your Github
2.  Push your package to GitHub (make sure
    [`run_app()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_app.md)
    works without local paths)
3.  Install your package in a fresh session locally,
    e.g. `remotes::install_github("St-Jude-MS-ABDS/ADS8192")` and verify
    [`run_app()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_app.md)
    works.
4.  Create an `app.r` file in `inst/app/` that calls
    `run_app(return_as_list = TRUE)` and passes the example data:

``` r
library(ADS8192)
data("example_se")
app <- run_app(se = example_se, return_as_list = TRUE)
shiny::shinyApp(ui = app$ui, server = app$server)
```

Using `return_as_list = TRUE` allows us to return the UI and server
functions without launching the app, which is necessary for deployment
platforms that expect a standalone `app.R` file.

5.  Create a `manifest.json` file in `inst/app/` that specifies the
    dependencies for the app. This is required for Posit Connect Cloud
    to know which packages to install.

This can be generated easily with the `rsconnect` package:

``` r
library(rsconnect)
writeManifest(appDir = "inst/app", appFiles = c("app.r"))   
```

6.  Deploy to Posit Connect Cloud, pointing to the `inst/app/app.R` file
    as the entry point.

### Record the URL

After deploying, add to your README:

``` markdown
## Interactive App

Run locally:

```r
library(ADS8192)
data("example_se")
ADS8192::run_app(se = example_se)
```

Or access the deployed example at: <https://your-deployment-url/>

    ---

    # Summary

    This lab we:

    1. Packaged the Shiny app with proper structure (`R/` for logic, `inst/app/` for deployed example)
    2. Added `run_app()` as a documented, exported function
    3. Discussed testing strategies
    4. Discussed app deployment options

    ## Package Milestone

    The Shiny app is shipped inside the package and can be launched by users after installing from GitHub.

    ---

    # After-Class Tasks

    ## Micro-task 1: GitHub Test

    From a fresh R session:


    ``` r
    # Install from GitHub
    remotes::install_github("St-Jude-MS-ABDS/ADS8192")

    # Run the app
    library(ADS8192)
    data("example_se")
    run_app(se = example_se)

------------------------------------------------------------------------

## Complete File Reference

### Final Directory Structure

    ADS8192/
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

    ## R version 4.5.3 (2026-03-11)
    ## Platform: x86_64-pc-linux-gnu
    ## Running under: Ubuntu 24.04.4 LTS
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
    ##  [5] xfun_0.57         cachem_1.1.0      knitr_1.51        htmltools_0.5.9  
    ##  [9] rmarkdown_2.31    lifecycle_1.0.5   cli_3.6.6         sass_0.4.10      
    ## [13] pkgdown_2.2.0     textshaping_1.0.5 jquerylib_0.1.4   systemfonts_1.3.2
    ## [17] compiler_4.5.3    tools_4.5.3       ragg_1.5.2        bslib_0.10.0     
    ## [21] evaluate_1.0.5    yaml_2.3.12       otel_0.2.0        jsonlite_2.0.0   
    ## [25] rlang_1.2.0       fs_2.0.1          htmlwidgets_1.6.4
