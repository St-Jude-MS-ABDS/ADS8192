# Select top variable features

Subsets a
[`SummarizedExperiment`](https://rdrr.io/pkg/SummarizedExperiment/man/SummarizedExperiment-class.html)
to the `n` most variable features (genes), ranked by row variance.

## Usage

``` r
top_variable_features(se, n = 500, assay_name = "counts")
```

## Arguments

- se:

  A
  [`SummarizedExperiment`](https://rdrr.io/pkg/SummarizedExperiment/man/SummarizedExperiment-class.html)
  object.

- n:

  Number of top variable features to select. Default: 500.

- assay_name:

  Name of the assay to use. Default: `"counts"`.

## Value

A
[`SummarizedExperiment`](https://rdrr.io/pkg/SummarizedExperiment/man/SummarizedExperiment-class.html)
subset to the top `n` variable features, preserving all sample metadata.

## Examples

``` r
data(example_se)
se_top <- top_variable_features(example_se, n = 50)
dim(se_top)
#> [1] 50  8
```
