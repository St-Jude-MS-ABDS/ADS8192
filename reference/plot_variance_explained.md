# Plot variance explained by principal components

Produces a bar chart showing the percentage of variance explained by
each principal component, using the output of
[`run_pca()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_pca.md).

## Usage

``` r
plot_variance_explained(pca_result, n_pcs = 8)
```

## Arguments

- pca_result:

  Output from
  [`run_pca()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_pca.md).

- n_pcs:

  Maximum number of PCs to display. Default: 8.

## Value

A [`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Author

Jared Andrews

## Examples

``` r
data(airway, package = "airway")
result <- run_pca(airway, n_top = 50)
plot_variance_explained(result)
```
