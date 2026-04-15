# Run the PCA Explorer Shiny Application

Launches an interactive Shiny application for exploring PCA results on
SummarizedExperiment data. The app allows users to select assays, adjust
PCA parameters, and visualize results with customizable options.

## Usage

``` r
run_app(se, return_as_list = FALSE, ...)
```

## Arguments

- se:

  A
  [`SummarizedExperiment`](https://rdrr.io/pkg/SummarizedExperiment/man/SummarizedExperiment-class.html)
  object to explore.

- return_as_list:

  If `TRUE`, returns a list containing the UI and server functions
  instead of launching the app. Useful for certain deployment scenarios.

- ...:

  Additional arguments passed to
  [`shinyApp()`](https://rdrr.io/pkg/shiny/man/shinyApp.html).

## Value

A Shiny app object or a named list containing the UI and server
functions if `return_as_list = TRUE`.

## Author

Jared Andrews

## Examples

``` r
if (interactive()) {
  library(ADS8192)
  data("example_se")
  run_app(se = example_se)
}
```
