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
3.  Apply input validation and basic UI/UX principles (clarity,
    feedback, consistency) to a scientific app

------------------------------------------------------------------------

### Evaluation Checklist

Before adding an interactive interface, ask:

- Who is the audience, and what task is easier interactively than at the
  console?
- Which computations are expensive enough to deserve reactive caching?
- Can the app call the same core functions as the other interfaces?
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

## Why Shiny?

After
[Lecture06](https://st-jude-ms-abds.github.io/ADS8192/articles/Lecture06_Package_Development_pkgdown_testthat.html),
we now have an R package with solid functionality, good documentation,
and decent test coverage.

People are free to download and use said package from Github.

But this requires:

- Users to know R
- Manual iteration to explore different parameters
- No visual feedback during exploration

**Shiny** lets us wrap our package’s functionality or results in an
interactive web interface, enabling:

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
install.packages(c("shiny", "bslib", "DT", "plotly"))

library(shiny)
library(bslib)
library(ADS8192)
library(plotly)
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
            sliderInput("n", "N:", min = 1, max = 100, value = 50)
        ),
        mainPanel(
            textOutput("result")
        )
    )
)

server <- function(input, output, session) {
    output$result <- renderText({
        paste("You selected:", input$n)
    })
}

shinyApp(ui, server)
```

#### `navbarPage` — Multi-page Navigation

For apps with multiple distinct sections:

``` r
# Multi-page app with a navigation bar
ui <- navbarPage(
    title = "My App",
    tabPanel(
        "Analysis",
        sliderInput("n", "N:", min = 1, max = 100, value = 50),
        textOutput("result")
    ),
    tabPanel("About", p("About this app..."))
)

server <- function(input, output, session) {
    output$result <- renderText({
        paste("You selected:", input$n)
    })
}

shinyApp(ui, server)
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
    textOutput("result")
)

server <- function(input, output, session) {
    output$result <- renderText({
        paste("You selected:", input$n)
    })
}

shinyApp(ui, server)
```

> **Note:**
> [`bslib::page_sidebar()`](https://rstudio.github.io/bslib/reference/page_sidebar.html)
> is what the packaged ADS8192 Shiny app uses
> ([`run_app()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_app.md)).
> It provides a cleaner API and full Bootstrap 5s support.

#### Other Packages and Custom Inputs

The [base Shiny
inputs](https://shiny.posit.co/r/getstarted/shiny-basics/lesson3/) cover
most use cases, but you are not limited to them:

- **`shinydashboard`**: Provide dashboard-style layouts with cards,
  value boxes, and sidebars
- **`bslib`**: Offers
  [`accordion()`](https://rstudio.github.io/bslib/reference/accordion.html),
  [`card()`](https://rstudio.github.io/bslib/reference/card.html),
  [`value_box()`](https://rstudio.github.io/bslib/reference/value_box.html),
  and other Bootstrap 5 components
- **Custom inputs**: You can write your own input widgets using the
  `htmlwidgets` package or raw HTML/JavaScript — this is advanced but
  powerful for specialized scientific visualizations
- There are many other packages that provides additional UI components
  and input types.

------------------------------------------------------------------------

### Output Types

Shiny has a variety of output types that you can render in the UI, the
most common ones include:

- [`textOutput()`](https://rdrr.io/pkg/shiny/man/textOutput.html) +
  [`renderText()`](https://rdrr.io/pkg/shiny/man/renderPrint.html):
  Display text
- [`plotOutput()`](https://rdrr.io/pkg/shiny/man/plotOutput.html) +
  [`renderPlot()`](https://rdrr.io/pkg/shiny/man/renderPlot.html):
  Display static R plots
- [`DT::dataTableOutput()`](https://rdrr.io/pkg/DT/man/dataTableOutput.html) +
  [`DT::renderDataTable()`](https://rdrr.io/pkg/DT/man/dataTableOutput.html):
  Display interactive tables
- `plotlyOutput()` + `renderPlotly()`: Display interactive Plotly graphs
- [`verbatimTextOutput()`](https://rdrr.io/pkg/shiny/man/textOutput.html) +
  [`renderPrint()`](https://rdrr.io/pkg/shiny/man/renderPrint.html):
  Display raw R output (e.g. from
  [`summary()`](https://rdrr.io/r/base/summary.html))
- [`uiOutput()`](https://rdrr.io/pkg/shiny/man/htmlOutput.html) +
  [`renderUI()`](https://rdrr.io/pkg/shiny/man/renderUI.html):
  Dynamically generate UI components based on inputs

We’ll touch on a few of these below.

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
data(example_se)

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
                choices = c("treatment", "batch")
            )
        ),
        mainPanel(
            plotOutput("pca_plot", height = "500px")
        )
    )
)

server <- function(input, output, session) {
    output$pca_plot <- renderPlot({
        # Run PCA with user-selected parameters
        result <- run_pca(example_se, n_top = input$n_top)

        # Create plot
        plot_pca(result, color_by = input$color_by)
    })
}

shinyApp(ui, server)
```

Save this as `app.R` and run it. You should see a simple app where you
can adjust the number of top variable genes and the coloring of the PCA
plot.

### Step 2: Adding Reactive Expressions

There is a problem with the above app - take a close look at the
`server` function, can you spot any unintended behavior?

Hint

What would happen if you change the `color_by` input?

Answer

Every time you change `color_by`, it re-runs the entire PCA! That’s
wasteful — PCA only depends on `n_top`, not on how we color the points.

A solution

While re-running the PCA is quick in this instance, it could be very
slow with larger datasets or more complex analyses. We can use
[`reactive()`](https://rdrr.io/pkg/shiny/man/reactive.html) to cache the
PCA result and only recompute it when `n_top` changes.

Use [`reactive()`](https://rdrr.io/pkg/shiny/man/reactive.html) to cache
expensive computations:

``` r
server <- function(input, output, session) {

    # Reactive expression: only reruns when n_top changes
    pca_result <- reactive({
        run_pca(example_se, n_top = input$n_top)
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

### Reactive Contexts in Depth

All reactive code in Shiny must run inside a **reactive context** — a
special execution environment that tracks which reactive sources were
read so that Shiny knows what to invalidate when those sources change.
If you try to read `input$x` outside a reactive context, you will get an
error. This is by design: Shiny can only manage the invalidation graph
for code it controls.

The five most important reactive contexts are summarized below.

#### `render*()` — Outputs that display results

The `render*()` functions
(e.g. [`renderPlot()`](https://rdrr.io/pkg/shiny/man/renderPlot.html),
[`renderText()`](https://rdrr.io/pkg/shiny/man/renderPrint.html),
[`renderDataTable()`](https://rdrr.io/pkg/shiny/man/renderDataTable.html))
create reactive contexts that produce output values. They are the most
common way to display results in a Shiny app. Inside a `render*()`
block, you can read inputs and call reactive expressions, and Shiny will
automatically update the output whenever any of those dependencies
change.

``` r
output$pca_plot <- renderPlot({
    plot_pca(pca_result(), color_by = input$color_by)
})
```

#### `reactive()` — Cached computations

You have already seen
[`reactive()`](https://rdrr.io/pkg/shiny/man/reactive.html). It creates
a reactive expression: a value that is computed lazily, cached, and
recomputed only when its dependencies change. Call it like a function
(`pca_result()`) inside other reactive contexts.

Use [`reactive()`](https://rdrr.io/pkg/shiny/man/reactive.html) when you
have a computation that:

- Takes time (or has meaningful cost)
- Is consumed by more than one output
- Should not run more often than its inputs actually change

``` r
# Computed once; reused by multiple render functions
filtered_data <- reactive({
    example_se[, example_se$dex == input$dex_filter]
})
```

#### `observe()` — Side effects without a return value

[`observe()`](https://rdrr.io/pkg/shiny/man/observe.html) runs a block
of code whenever its reactive dependencies change, but it does **not**
produce a value. Use it for side effects that don’t need to generate
output: writing to a file, logging, or calling
[`updateSelectInput()`](https://rdrr.io/pkg/shiny/man/updateSelectInput.html)
to synchronize one input with another.

``` r
# Update shape_by choices whenever color_by changes
observe({
    current_color <- input$color_by
    remaining <- setdiff(c("None", "dex", "cell"), current_color)
    updateSelectInput(session, "shape_by", choices = remaining)
})
```

[`observe()`](https://rdrr.io/pkg/shiny/man/observe.html) runs
**eagerly** — as soon as any dependency changes — whereas
[`reactive()`](https://rdrr.io/pkg/shiny/man/reactive.html) is **lazy**
and only runs when something downstream requests its value.

#### `observeEvent()` and `eventReactive()` — Event-driven reactivity

Sometimes you want reactivity to fire only on a specific trigger (a
button click, a file upload) rather than every time any input changes.
The `...Event()` variants let you declare that explicitly.

| Function                        | Returns | Triggered by   | Use when                                |
|---------------------------------|---------|----------------|-----------------------------------------|
| `observeEvent(trigger, {...})`  | nothing | `trigger` only | side effects on a specific event        |
| `eventReactive(trigger, {...})` | a value | `trigger` only | expensive computation gated on a button |

``` r
# Only rerun PCA when the user clicks "Run"
pca_result <- eventReactive(input$run_button, {
    run_pca(example_se, n_top = input$n_top)
})

# Log every time a plot is downloaded
observeEvent(input$download_plot, {
    message("Plot downloaded at ", Sys.time())
})
```

This is particularly useful for expensive computations — you can let the
user configure several parameters and only trigger the analysis when
they explicitly click a button, rather than re-running on every
keystroke.

#### `isolate()` — Reading without creating a dependency

[`isolate()`](https://rdrr.io/pkg/shiny/man/isolate.html) lets you read
a reactive value inside a reactive context *without* registering a
dependency on it. The surrounding context will not be invalidated when
that value changes. This is useful when you want to capture the current
value of an input at the moment a computation runs, but you don’t want
that input to trigger recomputation.

This app has two inputs. Move the slider — the output updates
immediately. Change the label — nothing happens. The label is only
captured when the slider moves, via
[`isolate()`](https://rdrr.io/pkg/shiny/man/isolate.html):

``` r
library(shiny)

ui <- fluidPage(
    sliderInput("n", "Number:", min = 1, max = 10, value = 5),
    textInput("label", "Label:", value = "Result"),
    textOutput("result")
)

server <- function(input, output, session) {
    output$result <- renderText({
        # input$n    → dependency: output rerenders when slider changes
        # input$label → NOT a dependency: changing the text box does nothing
        paste0(isolate(input$label), ": ", input$n)
    })
}

shinyApp(ui, server)
```

[`isolate()`](https://rdrr.io/pkg/shiny/man/isolate.html) is a precision
tool. Overusing it defeats the purpose of the reactive graph, but it is
invaluable when you need to capture contextual state at the moment a
computation runs without making that state a trigger for recomputation.

#### Choosing the right context

    Need a value returned?  ──Yes──→  reactive() / eventReactive()
            │ No
            ↓
    Triggered by one event? ──Yes──→  observeEvent()
            │ No
            ↓
            observe()

------------------------------------------------------------------------

### Step 3: More Controls

Shiny has tons of [different types of
inputs](https://mastering-shiny.org/basic-ui.html#inputs) (checkboxes,
dropdowns, sliders, file uploads, color pickers, etc) that you can use
to control your app.

The type of input to use will depend on the parameter you’re trying to
control and the user experience you want to create.

Having to type “TRUE” to indicate a boolean is probaby a bad idea when
checkboxes exist. Proper input choice can help prevent invalid input and
make the app more intuitive.

Below I add a few more inputs to the app to control various inputs.

App with more controls

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
            example_se,
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

Shiny can be tricky to debug because of its reactive nature. When
something doesn’t update as expected or an error is thrown, it can be
hard to figure out why.

It can require careful tracing of inputs, reactive expressions, current
values, and outputs to identify where the disconnect is. More than
likely, your first real frustration in Shiny will stem from reactivity
issues.

### `message()`

The simplest way to debug is to sprinkle
[`message()`](https://rdrr.io/r/base/message.html) calls throughout your
server code to print out the current values of inputs and intermediate
variables. This can help you see when certain code is running and what
the current state is.

Using [`message()`](https://rdrr.io/r/base/message.html) is often enough
to identify root causes of many issues, but sometimes you have to dig
deeper, particularly when the reactive graph is complex and involves
multiple layers.

### `browser()` and `reactlog`

The [`browser()`](https://rdrr.io/r/base/browser.html) function creates
an interactive breakpoint in R code. When Shiny hits that line, it will
pause and give you a console to inspect variables and the current state
of the app.

Generally, you’ll be doing this inside a *reactive* context, i.e. inside
a [`reactive()`](https://rdrr.io/pkg/shiny/man/reactive.html) or
[`renderPlot()`](https://rdrr.io/pkg/shiny/man/renderPlot.html), which
means you can inspect the current values of inputs and any intermediate
variables to see why something isn’t updating as expected.

``` r
ui <- fluidPage(
    titlePanel("PCA Explorer"),
    sidebarLayout(
        sidebarPanel(
            numericInput("n_top", "Top variable genes:", value = 500, min = 50, max = 5000),
            selectInput("color_by", "Color by:", choices = c("treatment", "batch"))
        ),
        mainPanel(
            plotOutput("pca_plot")
        )
    )
)

server <- function(input, output, session) {
    pca_result <- reactive({
        browser() # App will pause here when this reactive expression runs
        run_pca(example_se, n_top = input$n_top)
    })

    output$pca_plot <- renderPlot({
        plot_pca(pca_result(), color_by = input$color_by)
    })
}

shinyApp(ui, server)
```

When the app pauses at
[`browser()`](https://rdrr.io/r/base/browser.html), you can type
variable names in the console to inspect them (e.g. `input$n_top`,
`pca_result()`), call `n` to execute the next line, or `c` to continue
until the breakpoint is hit again. Remove the
[`browser()`](https://rdrr.io/r/base/browser.html) call once you are
done debugging.

The `reactlog` package provides a way to visualize the reactive graph of
a Shiny app. This can help identify where things are not updating as
expected.

``` r
library(reactlog)

ui <- fluidPage(
    titlePanel("PCA Explorer"),
    sidebarLayout(
        sidebarPanel(
            numericInput("n_top", "Top variable genes:", value = 500, min = 50, max = 5000),
            selectInput("color_by", "Color by:", choices = c("treatment", "batch"))
        ),
        mainPanel(
            plotOutput("pca_plot")
        )
    )
)

server <- function(input, output, session) {
    pca_result <- reactive({
        run_pca(example_se, n_top = input$n_top)
    })

    output$pca_plot <- renderPlot({
        plot_pca(pca_result(), color_by = input$color_by)
    })
}

# Enable logging BEFORE launching the app
reactlog_enable()

shinyApp(ui, server)

# After interacting with the app, view the reactive graph
reactlogShow()

# Turn off the reactlog once done
reactlog_disable()
```

The graph shows every reactive input, conductor, and output, and
highlights which dependencies triggered a recomputation. Nodes that are
grayed out were not invalidated; highlighted nodes were re-executed.
This makes it easy to spot cases where a reactive expression is running
more often than expected — or not running when it should.

This graph can get very large and complex for larger apps, but it can be
useful for tricky reactivity issues, especially when you can extract a
minimal reproducible example that isolates the problem.

Troubleshooting Shiny apps is somewhere between an art and voodoo, but
you get better at it with practice and experience, much like art (and
presumably voodoo). Read more about debugging Shiny apps
[here](https://mastering-shiny.org/action-workflow.html#debugging).

### A Note on Getting Help

There are three groups of people in the world. Those who feel questions
can be stupid, those that think there are no stupid questions, and
rarely, those who think there are no stupid questions but there sure are
stupid ways to ask them.

I am a member of the third camp.

Asking good questions is a skill that can be learned and is essential
both for getting and giving effective help. When asking for help (from
humans or our more immediately available AI resources), **context** is
key. Neither computers nor people can read your mind, so you need to
provide enough information for them to understand the problem, reproduce
it, and solve it (as that’s what they’ll have to do to answer your
question if they don’t already know it).

At minimum, you should provide: - A clear description of the problem and
what you expected to happen - A minimal reproducible example (standalone
code + data, AKA a
“[reprex](https://mastering-shiny.org/action-workflow.html#reprex-basics)”)
that demonstrates the issue - Any error messages or unexpected outputs
you received - Any approaches you’ve already tried (and their
outputs/issues)

Those you’re asking for help shouldn’t have to ask you for those things
(though they may ask you to run ancillary commands to gather additional
info). If they do, you’re already starting off on the wrong foot.
Providing them shows that you’ve put in some effort and done your best
to solve the problem yourself. Help them help you.

Stack Overflow grew a reputation for being brutal to beginners, but it
was really just brutal to those who asked questions in bad ways. AI has
effectively killed that site and feedback, but you will get much faster,
accurate, and cheaper help if you frame your requests to AI agents (or
local experts) appropriately.

------------------------------------------------------------------------

## Part 4: Input Validation

What happens if a user:

- Selects PC 10 when there are only 8 samples?
- Enters a negative number of genes?
- Uploads a malformed file?

Without validation, you get ugly errors or crashes.

### Using `validate()` and `need()`

There are relatively simple ways to block invalid input and provide
helpful feedback to users. The
[`validate()`](https://rdrr.io/pkg/shiny/man/validate.html) function
lets you check conditions and display messages when they are not met.
You can use it inside any reactive context (reactive expressions, render
functions) to ensure that inputs are valid before proceeding.

``` r
ui <- fluidPage(
  checkboxGroupInput('in1', 'Check some letters', choices = head(LETTERS)),
  selectizeInput('in2', 'Select a state', choices = c("", state.name)),
  plotOutput('plot')
)

server <- function(input, output) {
  output$plot <- renderPlot({
    validate(
      need(input$in1, 'Check at least one letter!'),
      need(input$in2 != '', 'Please choose a state.')
    )
    plot(1:10, main = paste(c(input$in1, input$in2), collapse = ', '))
  })
}

shinyApp(ui, server)
```

When validation fails, Shiny displays a helpful message instead of an
error.

This keeps the user from breaking stuff.

------------------------------------------------------------------------

## Shiny Modules (They Exist)

As Shiny apps grow, it becomes difficult to keep `ui` and `server`
organized in a single file. [**Shiny
modules**](https://mastering-shiny.org/scaling-modules.html) let you
encapsulate a UI/server pair into a reusable, namespaced unit — similar
to how R functions encapsulate logic.

A module has two parts: 1. A **UI function** that wraps UI elements in a
namespace 2. A **server function** that contains the reactive logic for
those elements

The namespace prevents input/output ID collisions between modules or
between a module and the main app.

Most notably, once a module is defined, you can call it multiple times
in the same app with different IDs to create multiple independent
instances of that functionality. This could be used to easily
view/compare multiple datasets, decouple different analysis steps, or
build a library of reusable components.

We don’t cover their implementation here, but they are worth knowing
about as a tool for organizing larger applications.

### When to Use Modules

Consider using modules when:

- The same UI+server pattern appears multiple times in the app (e.g., a
  plot panel with controls)
- Your server function is getting very long (several 100 or 1000 lines)
  and has distinct logical sections
- You want to separate development of a sub-feature from the main app
- You’re building a reusable component for multiple apps

For small apps like the PCA explorer, modules are overkill - the app is
small enough to manage without them. But modules are good to know about
for more complex large applications.

In fact, this app is small enough that it could be easily made into a
module, thereby allowing the same PCA code/visualizations to be used in
a larger application without having to re-implement that functionality.

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

A functional Shiny app that uses the package’s core functions and is
structured for later packaging.

------------------------------------------------------------------------

### Debrief & Reflection

Before moving on, make sure you can answer:

- Which app computations should be cached reactively, and which should
  stay as direct rendering code?
- Which user-facing validations belong in the app?

------------------------------------------------------------------------

## After-Class Tasks

### Reading

- [Mastering Shiny](https://mastering-shiny.org/): Chapters 1-4 (Basic
  UI/Server), Chapter 8 (Reactivity)

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
