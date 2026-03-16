# Lecture 7: Lab - Shiny (R) - Reactivity and App Design

## Learning Objectives

By the end of this session, you will be able to:

1.  Build a reactive Shiny app that calls package functions rather than
    duplicating logic
2.  Use reactive expressions to cache expensive computations and manage
    reactivity
3.  Apply input validation and basic UI/UX principles (clarity,
    feedback, consistency) to a scientific app

**Course Learning Outcomes (CLOs):** CLO 1, 4, 5, 6

------------------------------------------------------------------------

## Why Shiny?

### From Functions to Interactions

We have a powerful analysis core:

``` r
library(sePCA)
result <- run_pca(se, n_top = 500)
plot_pca(result, color_by = "treatment")
```

But this requires:

- Users to know R
- Manual iteration to explore different parameters
- No visual feedback during exploration

**Shiny** lets us wrap these functions in an interactive web interface:

- Point-and-click exploration
- Immediate visual feedback
- Accessible to non-programmers

### Key Principle: No Code Duplication

    ┌─────────────────────────────────────────────────────┐
    │                 Package Core                         │
    │  make_se() → run_pca() → plot_pca()                 │
    └─────────────────────────────────────────────────────┘
            ↑                    ↑                    ↑
            │                    │                    │
       ┌────┴────┐         ┌────┴────┐         ┌────┴────┐
       │ R API   │         │ Shiny   │         │ CLI     │
       │ (users) │         │ (web)   │         │(scripts)│
       └─────────┘         └─────────┘         └─────────┘

The Shiny app calls the same
[`run_pca()`](https://automatic-engine-4qp7m5e.pages.github.io/reference/run_pca.md)
and
[`plot_pca()`](https://automatic-engine-4qp7m5e.pages.github.io/reference/plot_pca.md)
functions — it never reimplements the analysis!

------------------------------------------------------------------------

## Part 1: Shiny Basics

### Installation

``` r
install.packages(c("shiny", "bslib"))

# Optional but useful:
install.packages(c("DT", "plotly", "shinycssloaders"))
```

``` r
library(shiny)
library(bslib)
library(sePCA)
library(airway)
```

### Minimal Shiny App Structure

Every Shiny app has two parts:

``` r
# UI: What the user sees
ui <- fluidPage(
    titlePanel("Hello Shiny!"),
    
    sidebarLayout(
        sidebarPanel(
            sliderInput("n", "Number:", min = 1, max = 100, value = 50)
        ),
        mainPanel(
            textOutput("result")
        )
    )
)

# Server: What happens behind the scenes
server <- function(input, output, session) {
    output$result <- renderText({
        paste("You selected:", input$n)
    })
}

# Run the app
shinyApp(ui, server)
```

### The Reactive Graph

Shiny uses **reactivity** to automatically update outputs when inputs
change:

    ┌──────────┐     ┌───────────────┐     ┌──────────────┐
    │  input$n │ ──→ │ renderText()  │ ──→ │ output$result│
    │ (source) │     │  (conductor)  │     │   (endpoint) │
    └──────────┘     └───────────────┘     └──────────────┘

- **Sources**: Inputs that change (input\$n, reactive values)
- **Conductors**: Computations that depend on sources (reactive(),
  renderX)
- **Endpoints**: Outputs that display results (output\$X)

When a source changes, Shiny automatically reruns all dependent code.

------------------------------------------------------------------------

## Part 2: Building the PCA Explorer

### Step 1: Minimal Working App

Let’s build a PCA explorer step by step. First, a minimal version:

``` r
library(shiny)
library(sePCA)
library(airway)

# Pre-load data
data(airway)

ui <- fluidPage(
    theme = bslib::bs_theme(bootswatch = "flatly"),
    
    titlePanel("PCA Explorer"),
    
    sidebarLayout(
        sidebarPanel(
            h4("Settings"),
            numericInput(
                "n_top",
                "Number of top variable genes:",
                value = 500,
                min = 50,
                max = 5000,
                step = 50
            ),
            selectInput(
                "color_by",
                "Color by:",
                choices = c("dex", "cell")
            )
        ),
        mainPanel(
            h4("PCA Plot"),
            plotOutput("pca_plot", height = "500px")
        )
    )
)

server <- function(input, output, session) {
    output$pca_plot <- renderPlot({
        # Run PCA with user-selected parameters
        result <- run_pca(airway, n_top = input$n_top)
        
        # Create plot
        plot_pca(result, color_by = input$color_by)
    })
}

shinyApp(ui, server)
```

**Save this as `app.R` and run it!**

### Step 2: Adding Reactive Expressions

The above app has a problem: every time you change `color_by`, it
re-runs the entire PCA! That’s wasteful — PCA only depends on `n_top`.

**Solution: Use
[`reactive()`](https://rdrr.io/pkg/shiny/man/reactive.html) to cache
expensive computations:**

``` r
server <- function(input, output, session) {
    
    # Reactive expression: only reruns when n_top changes
    pca_result <- reactive({
        run_pca(airway, n_top = input$n_top)
    })
    
    output$pca_plot <- renderPlot({
        # Use the cached result
        plot_pca(pca_result(), color_by = input$color_by)
    })
}
```

Now the reactive graph looks like:

    input$n_top ──→ pca_result() ──→ renderPlot() ──→ output$pca_plot
                                           ↑
    input$color_by ────────────────────────┘

- Changing `n_top` → reruns `pca_result()` → reruns plot
- Changing `color_by` → only reruns plot (uses cached PCA)

> **Exercise A:** Add a second `selectInput` for `shape_by` and update
> the plot to use both aesthetics. Verify that changing shape doesn’t
> re-run PCA.

------------------------------------------------------------------------

### Step 3: More Controls

Let’s add more user controls:

``` r
ui <- fluidPage(
    theme = bslib::bs_theme(bootswatch = "flatly"),
    
    titlePanel("PCA Explorer"),
    
    sidebarLayout(
        sidebarPanel(
            h4("PCA Settings"),
            numericInput(
                "n_top",
                "Top variable genes:",
                value = 500, min = 50, max = 5000, step = 50
            ),
            checkboxInput(
                "log_transform",
                "Log-transform counts",
                value = TRUE
            ),
            checkboxInput(
                "scale",
                "Scale features",
                value = TRUE
            ),
            
            hr(),
            h4("Plot Settings"),
            
            selectInput("color_by", "Color by:", choices = c("dex", "cell")),
            selectInput("shape_by", "Shape by:", choices = c("None", "dex", "cell")),
            
            fluidRow(
                column(6, numericInput("pc_x", "PC X:", value = 1, min = 1, max = 8)),
                column(6, numericInput("pc_y", "PC Y:", value = 2, min = 1, max = 8))
            ),
            
            sliderInput(
                "point_size",
                "Point size:",
                value = 4, min = 1, max = 10
            )
        ),
        
        mainPanel(
            tabsetPanel(
                tabPanel(
                    "PCA Plot",
                    plotOutput("pca_plot", height = "500px")
                ),
                tabPanel(
                    "Variance Explained",
                    plotOutput("variance_plot", height = "400px")
                ),
                tabPanel(
                    "Sample Data",
                    DT::dataTableOutput("scores_table")
                )
            )
        )
    )
)

server <- function(input, output, session) {
    
    # Cached PCA result
    pca_result <- reactive({
        run_pca(
            airway,
            n_top = input$n_top,
            log_transform = input$log_transform,
            scale = input$scale
        )
    })
    
    # PCA scatter plot
    output$pca_plot <- renderPlot({
        shape <- if (input$shape_by == "None") NULL else input$shape_by
        
        plot_pca(
            pca_result(),
            color_by = input$color_by,
            shape_by = shape,
            pcs = c(input$pc_x, input$pc_y),
            point_size = input$point_size
        )
    })
    
    # Variance plot
    output$variance_plot <- renderPlot({
        var_df <- pca_variance_explained(pca_result())
        
        # Only show first 8 PCs
        var_df <- var_df[1:min(8, nrow(var_df)), ]
        var_df$PC <- factor(var_df$PC, levels = var_df$PC)
        
        ggplot2::ggplot(var_df, ggplot2::aes(x = PC, y = variance_percent)) +
            ggplot2::geom_col(fill = "steelblue") +
            ggplot2::geom_text(
                ggplot2::aes(label = sprintf("%.1f%%", variance_percent)),
                vjust = -0.5
            ) +
            ggplot2::theme_minimal(base_size = 14) +
            ggplot2::labs(
                x = "Principal Component",
                y = "Variance Explained (%)",
                title = "Variance Explained by Each PC"
            ) +
            ggplot2::ylim(0, max(var_df$variance_percent) * 1.1)
    })
    
    # Scores table
    output$scores_table <- DT::renderDataTable({
        pca_result()$scores
    }, options = list(pageLength = 10, scrollX = TRUE))
}

shinyApp(ui, server)
```

------------------------------------------------------------------------

## Part 3: Debugging Reactivity

### Common Issue: Plot Not Updating

**Symptom:** You change an input but the plot doesn’t update.

**Diagnosis:**

1.  Is the input wired correctly? Check `input$name` matches the input
    ID
2.  Is the reactive graph connected? Use `reactlog` to visualize:

``` r
# Enable reactlog
options(shiny.reactlog = TRUE)

# Run your app, then press Ctrl+F3 to see the reactive graph
```

3.  Is there an error being silently swallowed?

### Exercise: Debug This App

``` r
# BROKEN APP - Find the bug!
ui <- fluidPage(
    selectInput("color", "Color:", choices = c("dex", "cell")),
    plotOutput("plot")
)

server <- function(input, output, session) {
    se <- airway::airway  # Load data
    
    result <- run_pca(se)  # BUG: Not reactive!
    
    output$plot <- renderPlot({
        plot_pca(result, color_by = input$color)
    })
}
```

**What’s wrong?**

`result` is computed once when the app starts, but it’s not a reactive
expression. Changes to any input won’t affect it.

**Fix:**

``` r
server <- function(input, output, session) {
    result <- reactive({
        run_pca(airway)
    })
    
    output$plot <- renderPlot({
        plot_pca(result(), color_by = input$color)  # Note: result() with parentheses!
    })
}
```

------------------------------------------------------------------------

## Part 4: Input Validation

### The Problem

What happens if a user:

- Selects PC 10 when there are only 8 samples?
- Enters a negative number of genes?
- Uploads a malformed file?

Without validation, you get ugly errors or crashes.

### Using `validate()` and `need()`

``` r
server <- function(input, output, session) {
    pca_result <- reactive({
        # Validate inputs before computing
        validate(
            need(input$n_top >= 10, "Please select at least 10 genes"),
            need(input$n_top <= nrow(airway), "Cannot select more genes than available")
        )
        
        run_pca(airway, n_top = input$n_top)
    })
    
    output$pca_plot <- renderPlot({
        # Validate PC selection
        n_samples <- ncol(airway)
        validate(
            need(input$pc_x <= n_samples, paste("PC X must be ≤", n_samples)),
            need(input$pc_y <= n_samples, paste("PC Y must be ≤", n_samples)),
            need(input$pc_x != input$pc_y, "Please select different PCs for X and Y")
        )
        
        plot_pca(
            pca_result(),
            color_by = input$color_by,
            pcs = c(input$pc_x, input$pc_y)
        )
    })
}
```

When validation fails, Shiny displays a helpful message instead of an
error.

> **Exercise B:** Add validation to prevent `point_size` from being zero
> or negative.

------------------------------------------------------------------------

## Part 5: UI/UX Principles

### Warm-up Discussion: Worst UI Ever

Think of a time you used a confusing interface. What made it bad?

Common problems:

- No feedback when something is loading
- Cryptic error messages
- Too many options visible at once
- Inconsistent styling
- No explanation of what things do

### Practical Improvements

#### 1. Loading Indicators

``` r
library(shinycssloaders)

# Wrap outputs in withSpinner()
mainPanel(
    withSpinner(plotOutput("pca_plot"))
)
```

#### 2. Help Text

``` r
numericInput(
    "n_top",
    "Top variable genes:",
    value = 500, min = 50, max = 5000
),
helpText("Higher values include more genes but take longer to compute.")
```

#### 3. Tooltips

``` r
library(bslib)

numericInput(
    "n_top",
    tooltip(
        span("Top variable genes", icon("question-circle")),
        "PCA will be computed using only the N most variable genes."
    ),
    value = 500
)
```

#### 4. Clear Section Headers

``` r
sidebarPanel(
    h4(icon("cogs"), "Analysis Settings"),
    # ... inputs
    
    hr(),
    
    h4(icon("palette"), "Visualization"),
    # ... more inputs
)
```

------------------------------------------------------------------------

## Optional: Modules at a Glance (Not Required)

Shiny modules can help in large apps, but they are **not required** for
this project. This is a tiny reference example only:

``` r
pcaPlotUI <- function(id) plotOutput(NS(id)("plot"))
pcaPlotServer <- function(id, pca_result) {
    moduleServer(id, function(input, output, session) {
        output$plot <- renderPlot(plot_pca(pca_result()))
    })
}
```

------------------------------------------------------------------------

## Summary

Today we:

1.  Built a reactive Shiny app that wraps our package functions
2.  Used [`reactive()`](https://rdrr.io/pkg/shiny/man/reactive.html) to
    cache expensive computations
3.  Added input validation with
    [`validate()`](https://rdrr.io/pkg/shiny/man/validate.html) and
    [`need()`](https://rdrr.io/pkg/shiny/man/validate.html)
4.  Applied UI/UX improvements

### Package Milestone

✅ A functional Shiny PCA explorer that uses the package’s core
functions and is structured for later packaging.

------------------------------------------------------------------------

## After-Class Tasks

### Reading

- Mastering Shiny: Chapters 1-4 (Basic UI/Server), Chapter 8
  (Reactivity)
- <https://mastering-shiny.org/>

### Micro-task 1: Add Features

Add one additional visualization output (e.g., a loadings plot or sample
distance heatmap) and one download handler to export the current plot or
data.

``` r
# Add to UI
downloadButton("download_plot", "Download Plot")

# Add to server
output$download_plot <- downloadHandler(
    filename = function() {
        paste0("pca_plot_", Sys.Date(), ".png")
    },
    content = function(file) {
        s <- settings()
        p <- plot_pca(pca_result(), color_by = s$color_by, pcs = s$pcs)
        ggplot2::ggsave(file, p, width = 8, height = 6, dpi = 150)
    }
)
```

### Micro-task 2: Clean Session Test

Ensure the Shiny app can be run from a clean R session and does not rely
on objects in the global environment.

------------------------------------------------------------------------

## Session Info

``` r
sessionInfo()
```

    ## R version 4.5.3 (2026-03-11)
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
    ## [13] pkgdown_2.2.0     textshaping_1.0.5 jquerylib_0.1.4   systemfonts_1.3.2
    ## [17] compiler_4.5.3    tools_4.5.3       ragg_1.5.1        bslib_0.10.0     
    ## [21] evaluate_1.0.5    yaml_2.3.12       otel_0.2.0        jsonlite_2.0.0   
    ## [25] rlang_1.1.7       fs_1.6.7          htmlwidgets_1.6.4
