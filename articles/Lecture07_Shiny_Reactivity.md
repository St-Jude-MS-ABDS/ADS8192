# Lecture 7: Lab - Shiny (R) - Reactivity and App Design

## Motivation

The most time-consuming component of computational biology,
bioinformatics, and general data science is rarely the analysis. The
interpretation of results is the killer. Often, you may be handed data
or a project that you are just not very familiar with, it could be a new
field, biology that you just don’t know much about, or a complicated
experiment that requires expert knowledge to derive trustworthy
conclusions.

In such cases, you often need to work with other scientists and experts
to interpret analysis results in a robust and expedient manner. Getting
people to look through your analysis results can be an unexpected
challenge - digging through tables is tedious and boring. Everybody is
trying to avoid death by Excel.

You know what’s not boring? A pretty picture. In science, a solid figure
is truly worth 10000 words. Effective data visualization is a skill unto
itself, beyond the scope of what we’ll cover here. But even if you
create beautiful, useful figures, your collaborators and colleagues will
always want tweaks or the ability to look at things themselves. That’s a
good thing!

It gets more eyeballs on the data, empowers bench scientists to make
real insights and construct a scientific narrative more easily, and will
save you time if you provide such avenues rather than re-generating the
same figure in 20 different shades of purple yourself.

Interactive scientific applications have become a common way to
distribute analysis results, and it is becoming more common for them to
be published alongside articles. The ability to quickly develop these
applications is a sought after skill.

So we continue onwards in our pursuit of scientific figure aesthetic
perfection.

### Learning Objectives

By the end of this session, you will be able to:

1.  Build a reactive Shiny app that calls package functions rather than
    duplicating logic
2.  Use reactive expressions to cache expensive computations and manage
    reactivity
3.  Treat reactivity as an abstraction boundary rather than a second
    implementation of the analysis
4.  Apply input validation and basic UI/UX principles (clarity,
    feedback, consistency) to a scientific app

------------------------------------------------------------------------

### Evaluation Checklist

Before adding an interactive interface, ask:

- Who is the audience, and what task is easier interactively than at the
  console?
- Which computations are expensive enough to deserve reactive caching?
- What inputs need validation at the interface boundary?
- Does the app call the same core functions as the other interfaces?
- Will the UI help users reason about the science, or just expose every
  possible knob?
- Would a thin interface around existing package functions be enough?

### Scientific Use Case

A wet-lab collaborator wants to explore how PCA changes when they switch
from 500 to 2000 highly variable genes and color points by treatment,
batch, or donor. They do not want to read R code, but they do need the
same computation your package already exposes programmatically. What
belongs in the app, and what must remain in the core?

------------------------------------------------------------------------

## UI/UX Design Principles

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

## Why Shiny?

After Lecture06, we now have an R package with solid functionality, good
documentation, and decent test coverage.

People are free to download and use said package from Github.

But this requires:

- Users to know R
- Manual iteration to explore different parameters
- No visual feedback during exploration

**Shiny** lets us wrap our package’s functionality in an interactive web
interface, enabling:

- Point-and-click exploration
- Immediate visual feedback
- Accessibility to non-programmers - just go to a link in the browser

Importantly, our Shiny app can call the same
[`run_pca()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_pca.md)
and
[`plot_pca()`](https://st-jude-ms-abds.github.io/ADS8192/reference/plot_pca.md)
functions — there is no need to reimplement functionality, just wire up
an interface to control the input parameters and display outputs.

------------------------------------------------------------------------

## Part 1: Shiny Basics

### Installation

``` r
install.packages(c("shiny", "bslib", "DT", "plotly", "shinycssloaders"))

library(shiny)
library(bslib)
library(ADS8192)
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

### UI Layout Options

Shiny is flexible about how you structure the overall page. Here are the
most common patterns:

#### `fluidPage` + `sidebarLayout`

The classic layout (shown above) — a sidebar for controls and a main
area for outputs:

``` r
# Classic: sidebar + main panel
ui <- fluidPage(
    titlePanel("My App"),
    sidebarLayout(
        sidebarPanel(
            # Controls here
            sliderInput("n", "N:", min = 1, max = 100, value = 50)
        ),
        mainPanel(
            # Outputs here
            plotOutput("plot")
        )
    )
)
```

#### `navbarPage` — Multi-page Navigation

For apps with multiple distinct sections:

``` r
# Multi-page app with a navigation bar
ui <- navbarPage(
    title = "My App",
    tabPanel("Analysis", plotOutput("plot")),
    tabPanel("Data", DT::dataTableOutput("table")),
    tabPanel("About", p("About this app..."))
)
```

#### `bslib::page_sidebar()` — Modern Bootstrap 5

The modern alternative to `sidebarLayout`, using Bootstrap 5 components:

``` r
library(bslib)

# Modern equivalent of sidebarLayout
ui <- page_sidebar(
    title = "My App",
    theme = bs_theme(bootswatch = "flatly"),
    sidebar = sidebar(
        sliderInput("n", "N:", min = 1, max = 100, value = 50)
    ),
    plotOutput("plot")
)
```

> **Note:**
> [`bslib::page_sidebar()`](https://rstudio.github.io/bslib/reference/page_sidebar.html)
> is what the packaged ADS8192 Shiny app uses
> ([`run_app()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_app.md)).
> It provides a cleaner API and full Bootstrap 5 support.

#### Other Packages and Custom Inputs

The base Shiny inputs cover most use cases, but you are not limited to
them:

- **`shinydashboard`** and **`bs4Dash`**: Provide dashboard-style
  layouts with cards, value boxes, and sidebars
- **`bslib`**: Offers
  [`accordion()`](https://rstudio.github.io/bslib/reference/accordion.html),
  [`card()`](https://rstudio.github.io/bslib/reference/card.html),
  [`value_box()`](https://rstudio.github.io/bslib/reference/value_box.html),
  and other Bootstrap 5 components
- **Custom inputs**: You can write your own input widgets using the
  `htmlwidgets` package or raw HTML/JavaScript — this is advanced but
  powerful for specialized scientific visualizations
- Other packages in the ecosystem (e.g., `plotly`, `leaflet`) provide
  their own output widgets that integrate seamlessly with Shiny’s
  reactive system

For most scientific apps, the built-in Shiny inputs plus `bslib`
components will cover all your needs.

------------------------------------------------------------------------

### The First Wall: Reactivity

At the core of `shiny` is the concept of “reactivity”.

Reactive expressions are useful because they let you say, “recompute
this result only when the relevant inputs change.” That is an
abstraction and caching boundary, not a new place to re-implement PCA.
If
[`run_pca()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_pca.md)
changes, the app should benefit automatically because it still delegates
to the same core function.

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

## Part 2: Building an Application

### Step 1: Minimal Working App

Let’s build a PCA explorer step by step. First, a minimal version:

``` r
library(shiny)
library(ADS8192)
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
# Full PCA Explorer app — Step 3 (UI + server with tabs, reactive caching, and multiple outputs)
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

## Shiny Modules

### What Are Modules?

As Shiny apps grow, it becomes difficult to keep `ui` and `server`
organized in a single file. **Shiny modules** let you encapsulate a
UI/server pair into a reusable, namespaced unit — similar to how R
functions encapsulate logic.

A module has two parts: 1. A **UI function** that wraps UI elements in a
namespace 2. A **server function** that contains the reactive logic for
those elements

The namespace prevents input/output ID collisions between modules or
between a module and the main app.

### When to Use Modules

Consider using modules when:

- The same UI+server pattern appears multiple times in the app (e.g., a
  plot panel with controls)
- Your server function is getting very long (\> ~200 lines) and has
  distinct logical sections
- You want to separate development of a sub-feature from the main app
- You’re building a reusable component for multiple apps

For small apps like the PCA explorer in this course, modules are
**optional** — the app is compact enough to manage without them. But
understanding modules prepares you for larger apps.

### How Modules Work

The key mechanism is `NS(id)` (namespace), which prefixes all IDs with
the module ID so they don’t conflict.

``` r
# --- Module UI ---
# NS(id) wraps all input/output IDs in a namespace
pcaPlotUI <- function(id) {
    ns <- NS(id)
    tagList(
        selectInput(ns("color_by"), "Color by:", choices = NULL),
        plotOutput(ns("pca_plot"))
    )
}

# --- Module Server ---
# moduleServer handles the ns() scoping automatically
pcaPlotServer <- function(id, pca_result, metadata_cols) {
    moduleServer(id, function(input, output, session) {
        # Update choices from reactive input
        observe({
            updateSelectInput(session, "color_by", choices = metadata_cols())
        })

        output$pca_plot <- renderPlot({
            req(pca_result(), input$color_by)
            plot_pca(pca_result(), color_by = input$color_by)
        })
    })
}

# --- Using the Module in the Main App ---
ui <- fluidPage(
    pcaPlotUI("main_plot"),   # Instantiate the module UI
    pcaPlotUI("compare_plot") # A second instance — no ID conflicts!
)

server <- function(input, output, session) {
    pca_result <- reactive({ run_pca(airway, n_top = 500) })
    cols <- reactive({ colnames(SummarizedExperiment::colData(airway)) })

    pcaPlotServer("main_plot",   pca_result, cols)
    pcaPlotServer("compare_plot", pca_result, cols)
}
```

### Key Points

- `NS(id)` creates the namespace function — call it once at the top of
  the UI function
- Inside
  [`moduleServer()`](https://rdrr.io/pkg/shiny/man/moduleServer.html),
  you use `input$color_by` directly (no `ns()` needed) because the
  namespace is handled automatically
- Pass reactive expressions (not their values) into server modules so
  the module stays reactive
- Modules are just functions — test them like functions

### Further Reading

For a thorough treatment of Shiny modules, see the [Mastering Shiny
chapter on modules](https://mastering-shiny.org/scaling-modules.html),
which covers communication between modules, testing, and advanced
patterns.

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

### Debrief & Reflection

Before moving on, make sure you can answer:

- Which app computations should be cached reactively, and which should
  stay as direct rendering code?
- How does Shiny help you avoid reinventing a custom web interface while
  still keeping the scientific logic reusable?
- Which user-facing validations belong in the app because they protect
  the interface boundary?

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
