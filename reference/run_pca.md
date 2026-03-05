# Run PCA on a SummarizedExperiment

Performs principal component analysis on a
[`SummarizedExperiment`](https://rdrr.io/pkg/SummarizedExperiment/man/SummarizedExperiment-class.html),
first selecting the top variable features, optionally log-transforming
and scaling.

## Usage

``` r
run_pca(
  se,
  assay_name = "counts",
  n_top = 500,
  scale = TRUE,
  log_transform = TRUE
)
```

## Arguments

- se:

  A
  [`SummarizedExperiment`](https://rdrr.io/pkg/SummarizedExperiment/man/SummarizedExperiment-class.html)
  object.

- assay_name:

  Name of the assay to use. Default: `"counts"`.

- n_top:

  Number of top variable features for PCA. Default: 500.

- scale:

  Logical; should features be scaled? Default: `TRUE`.

- log_transform:

  Logical; should counts be log2-transformed (with pseudocount of 1)?
  Default: `TRUE`.

## Value

A list with two elements:

- pca:

  The [`prcomp`](https://rdrr.io/r/stats/prcomp.html) result object.

- scores:

  A data.frame of PC scores merged with sample metadata from
  `colData(se)`.

## Examples

``` r
data(example_se)
result <- run_pca(example_se, n_top = 50)
head(result$scores)
#>   sample_id       PC1       PC2        PC3        PC4        PC5        PC6
#> 1   sample1 -3.661089  1.400546  1.1513110 -2.9495180 -2.9900017  0.8073388
#> 2   sample2 -4.690739 -2.460840 -2.0430942  3.2092803 -0.9257690  1.9138380
#> 3   sample3 -5.210003 -2.364561  0.1337717 -0.8679711  0.5684443 -3.1293259
#> 4   sample4 -4.068511  3.959228  1.0888244  0.3559802  3.1898969  0.7659579
#> 5   sample5  4.404284  1.097518 -3.2408775 -1.8398335  0.2241627  1.0180449
#> 6   sample6  4.321797 -3.339700 -1.0686472 -1.3597673  1.6525663  0.1609117
#>          PC7          PC8 treatment batch
#> 1  1.0179046 6.865967e-15   control     A
#> 2 -0.1096081 7.192660e-15   control     B
#> 3 -1.1712973 7.213094e-15   control     A
#> 4  0.4207278 6.214588e-15   control     B
#> 5 -2.2998585 6.303431e-15   treated     A
#> 6  2.3134294 6.697588e-15   treated     B
```
