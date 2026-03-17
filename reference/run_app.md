# Run the PCA Explorer Shiny Application

Launches an interactive Shiny application for exploring PCA results on
SummarizedExperiment data. The app uses the `airway` dataset by default
and wraps the package's core analysis functions.

## Usage

``` r
run_app(...)
```

## Arguments

- ...:

  Additional arguments passed to
  [`shinyApp()`](https://rdrr.io/pkg/shiny/man/shinyApp.html).

## Value

A Shiny app object (invisibly).

## Author

Jared Andrews

## Examples

``` r
if (FALSE) { # \dontrun{
run_app()
} # }
```
