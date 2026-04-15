# Lecture 8: Lab – Shiny (R) – Packaging, Documentation, and Deployment

## Motivation

An app is only useful scientific software if other people can install
it, launch it, and trust that it behaves the same way outside your own
machine. Packaging and deployment turn an interesting interface into a
reproducible tool.

This lecture matters because deployment decisions shape maintainability.
Stable entry points, optional dependencies, and clean file lookup rules
save time for collaborators, reduce environment-specific failures, and
keep the app aligned with the same package core used everywhere else.

### Learning Objectives

By the end of this session, you will be able to:

1.  Add a Shiny application to the package as a function and document it
2.  Deploy the application to a hosting platform (Posit Cloud)
3.  Explain why packaging, optional dependencies, and deployment are
    reproducibility decisions as much as UI decisions
4.  Discuss basic testing strategies for Shiny apps

### Evaluation Checklist

Before packaging or deploying an app, ask:

- Is the app truly a thin layer over tested package functions?
- Which dependencies are essential, and which should stay optional?
- Can a user install and launch the app from a clean session?
- What interface failures need friendly validation or graceful fallback?
- Does the deployment choice fit the intended audience and maintenance
  model?
- Would packaging this app reduce manual setup more than another custom
  distribution method?

### Scientific Use Case

Your lab wants to share a small QC dashboard with collaborators at
another institution. Some users will explore the app interactively,
while others only want the package functions in scripts. How do you
package the app so both audiences are supported without forcing every
user into the same workflow?

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
  shows how to use it

------------------------------------------------------------------------

## Part 1: Package Structure for Shiny Apps

### Where Does the App Go?

The conventional location is `inst/app/`:

    ADS8192/
    ├── DESCRIPTION
    ├── NAMESPACE
    ├── R/
    │   ├── run_app.R        # Exported function to launch app
    │   ├── app_ui.R         # UI definition
    │   ├── app_server.R     # Server logic
    ├── inst/
    │   └── app/
    │       └── app.R        # App entry point (calls run_app)
    └── ...

Why `inst/`?

- Files in `inst/` are copied as-is when the package is installed
- They’re accessible via `system.file("app", package = "ADS8192")`
- The actual app logic lives in `R/` for documentation and testing

### Step 1: Create the Directory Structure

``` r
# In your package directory
dir.create("inst/app", recursive = TRUE)
```

### Step 2: Create App Files in R/

#### R/app_ui.R

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
```

### Step 3: Create inst/app/app.R

This file exists for deployment platforms like Posit Cloud that expect a
standalone `app.R` entry point. Rather than calling internal package
functions directly (which requires `:::` and is bad practice), it uses
`return_as_list = TRUE` to get the UI and server back as a plain list,
then passes them to
[`shinyApp()`](https://rdrr.io/pkg/shiny/man/shinyApp.html).

``` r
# inst/app/app.R
library(ADS8192)
library(shiny)

data("example_se")

app <- run_app(se = example_se, return_as_list = TRUE)

shinyApp(ui = app$ui, server = app$server)
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
use_package("rlang")  # For .data pronoun in ggplot2 aes()
```

Your DESCRIPTION now includes:

``` yaml
Suggests:
    bslib,
    DT,
    knitr,
    shiny,
    testthat (>= 3.0.0)
```

### Why Suggests?

- Users who only want the R API don’t need shiny
- Keeps the core package lightweight
- [`run_app()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_app.md)
  checks for packages at runtime
- The app works on any `SummarizedExperiment` — no extra data packages
  required

### Checking for Optional Dependencies

When your function requires a package that is in `Suggests`, you must
check for it at runtime and give a helpful error message if it’s
missing. Two approaches:

#### `requireNamespace()` — Lightweight Check

Best for checking inside a function body before using the package:

``` r
# In run_app() — checks happen before any work is done
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

    # Validate user-supplied data
    if (!methods::is(se, "SummarizedExperiment")) {
        stop("'se' must be a SummarizedExperiment object.", call. = FALSE)
    }

    # ... rest of function
}
```

#### Best Practice: Check Once at the Entry Point

For functions where an entire block of functionality depends on optional
packages (like
[`run_app()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_app.md)),
check all required packages **once at the top** of the function. Don’t
scatter checks throughout the code — it leads to confusing partial
failures:

``` r
# The actual ADS8192::run_app() — three focused checks, then proceed
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

    # All dependencies confirmed — proceed
    server <- function(input, output, session) {
        app_server(input, output, session, se = se)
    }
    app <- shiny::shinyApp(ui = app_ui(), server = server, ...)

    if (return_as_list) {
        return(list(ui = app_ui(), server = server))
    } else {
        app
    }
}
```

This pattern is exactly what the
[`ADS8192::run_app()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_app.md)
function uses.

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

After installing ADS8192, launch the interactive PCA explorer:

```r
library(ADS8192)
data("example_se")
run_app(se = example_se)
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
        app_dir = system.file("app", package = "ADS8192"),
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

After packaging the app inside your R package, you can make it available
to others in several ways. The right choice depends on your audience,
infrastructure, and maintenance capacity.

### Deployment Options

| Option                   | Audience               | Cost                | Infrastructure               |
|--------------------------|------------------------|---------------------|------------------------------|
| Posit Connect            | Internal/institutional | Subscription        | Posit-managed or self-hosted |
| Self-hosted Shiny Server | Any                    | Free (open source)  | Your own server              |
| Posit Cloud              | Teaching/demos         | Free tier available | Posit-managed                |

> **Note:** shinyapps.io has been deprecated and should not be used for
> new deployments.

#### Option 1: Posit Connect (Recommended for Institutions)

[Posit Connect](https://posit.co/products/enterprise/connect/) is a
publishing platform for R (and Python) content. It can host Shiny apps,
R Markdown reports, APIs, and more.

- **Posit-managed hosting**: Posit offers a hosted version — no server
  to maintain
- **Self-hosted**: Deploy on your institution’s own server (common in
  regulated environments like healthcare/research)
- Supports authentication, scheduled reports, and access control
- St. Jude users: check with your IT department for institutional access

``` r
# Deploy to Posit Connect using rsconnect
install.packages("rsconnect")
rsconnect::deployApp(
    appDir = system.file("app", package = "ADS8192"),
    appName = "ads8192-pca-explorer",
    server = "your-connect-server.example.com"
)
```

#### Option 2: Self-hosted Shiny Server (Open Source)

Run Shiny Server on any Linux VM or HPC login node:

``` bash
# On a Linux server
sudo apt-get install r-base
# Install Shiny Server: https://posit.co/download/shiny-server/
# Place your app.R in /srv/shiny-server/
```

Your app is then accessible at `http://your-server:3838/app-name/`.

- Free, open source
- Full control over the environment
- Requires server administration (updates, security, SSL)
- Good option for HPC environments or institutional clusters

#### Option 3: Posit Cloud (Teaching and Demos)

[Posit Cloud](https://posit.cloud/) is a browser-based RStudio
environment:

1.  Create a new project from Git
2.  Install your package: `remotes::install_github("you/ADS8192")`
3.  Use `inst/app/app.R` (already in your repo) which calls
    `run_app(se = example_se, return_as_list = TRUE)`
4.  Click **Publish** → **Shiny**

Best for course demonstrations and quick sharing. The free tier has
compute limitations that make it unsuitable for production use.

#### Choosing a Deployment Strategy

For scientific software in a research institution:

- **Internal tool for your lab**: Posit Connect on institutional
  infrastructure is the most maintainable option
- **Public-facing demo**: Posit Cloud is fast to set up
- **Pipeline-adjacent tool** on an HPC cluster: consider whether a Shiny
  app is the right interface at all — a CLI or R API may serve pipeline
  users better

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

Or access the deployed version at: <https://your-deployment-url/>

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

    ## Debrief & Reflection

    Before moving on, make sure you can answer:

    - Why is packaging the app part of the reproducibility story, not just a convenience feature?
    - Which app dependencies should be mandatory, and which should remain optional with graceful fallback?
    - If a collaborator never opens the app and only uses the R API, how does your package design still serve them well?

    ---

    # After-Class Tasks

    ## Micro-task 1: GitHub Test

    From a fresh R session:


    ``` r
    # Start clean
    .rs.restartR()

    # Install from GitHub
    remotes::install_github("you/ADS8192")

    # Run the app
    library(ADS8192)
    data("example_se")
    ADS8192::run_app(se = example_se)

### Micro-task 2: Update README

Add an “Interactive App” section to README with:

- Instructions to launch
- Screenshot or GIF (optional but nice!)
- Link to deployed version (if you deployed)

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
