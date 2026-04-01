# Get variance explained by each PC

Extracts the percentage of variance explained by each principal
component from the output of
[`run_pca`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_pca.md).

## Usage

``` r
pca_variance_explained(pca_result)
```

## Arguments

- pca_result:

  Output from
  [`run_pca()`](https://st-jude-ms-abds.github.io/ADS8192/reference/run_pca.md).

## Value

A data.frame with columns:

- PC:

  Character, e.g. `"PC1"`, `"PC2"`.

- variance_percent:

  Numeric, percentage of total variance explained.

## Author

Jared Andrews

## Examples

``` r
data(airway, package = "airway")
result <- run_pca(airway, n_top = 50)
var_df <- pca_variance_explained(result)
head(var_df)
#>    PC variance_percent
#> 1 PC1        49.168360
#> 2 PC2        27.958056
#> 3 PC3        11.167149
#> 4 PC4         6.293835
#> 5 PC5         2.284729
#> 6 PC6         2.114628
```
