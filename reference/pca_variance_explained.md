# Get variance explained by each PC

Extracts the percentage of variance explained by each principal
component from the output of
[`run_pca`](https://automatic-engine-4qp7m5e.pages.github.io/reference/run_pca.md).

## Usage

``` r
pca_variance_explained(pca_result)
```

## Arguments

- pca_result:

  Output from
  [`run_pca()`](https://automatic-engine-4qp7m5e.pages.github.io/reference/run_pca.md).

## Value

A data.frame with columns:

- PC:

  Character, e.g. `"PC1"`, `"PC2"`.

- variance_percent:

  Numeric, percentage of total variance explained.

## Examples

``` r
data(example_se)
result <- run_pca(example_se, n_top = 50)
var_df <- pca_variance_explained(result)
head(var_df)
#>    PC variance_percent
#> 1 PC1        44.818328
#> 2 PC2        15.015215
#> 3 PC3        13.465500
#> 4 PC4         9.167293
#> 5 PC5         7.225522
#> 6 PC6         5.971530
```
