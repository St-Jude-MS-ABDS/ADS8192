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
data(airway, package = "airway")
result <- run_pca(airway, n_top = 50)
head(result$scores)
#>    sample_id       PC1       PC2        PC3        PC4        PC5        PC6
#> 1 SRR1039508 -1.021870  4.652070  1.1585189 -2.1414957 -0.6403940  1.3717145
#> 2 SRR1039509 -4.051689 -1.145142  2.3345624 -1.7637762 -0.6733209 -1.5512002
#> 3 SRR1039512  4.167483  1.619350 -3.7715469  0.5743035 -1.4207341 -0.8681717
#> 4 SRR1039513 -7.668804 -2.707200  0.1466844  2.6982673 -0.6280659  0.6664711
#> 5 SRR1039516  4.630196  2.950546  3.0805204  2.0666453  0.8775858 -0.7225060
#> 6 SRR1039517  7.190889 -5.541529  0.9585495 -0.3052646 -0.2680932  1.0310825
#>          PC7          PC8 SampleName    cell   dex albut        Run avgLength
#> 1  0.5946982 1.401520e-14 GSM1275862  N61311 untrt untrt SRR1039508       126
#> 2 -0.6065219 1.391260e-14 GSM1275863  N61311   trt untrt SRR1039509       126
#> 3  0.2236849 1.404321e-14 GSM1275866 N052611 untrt untrt SRR1039512       126
#> 4  0.2523142 1.345068e-14 GSM1275867 N052611   trt untrt SRR1039513        87
#> 5  0.4532575 1.459183e-14 GSM1275870 N080611 untrt untrt SRR1039516       120
#> 6 -0.5337418 1.402032e-14 GSM1275871 N080611   trt untrt SRR1039517       126
#>   Experiment    Sample    BioSample
#> 1  SRX384345 SRS508568 SAMN02422669
#> 2  SRX384346 SRS508567 SAMN02422675
#> 3  SRX384349 SRS508571 SAMN02422678
#> 4  SRX384350 SRS508572 SAMN02422670
#> 5  SRX384353 SRS508575 SAMN02422682
#> 6  SRX384354 SRS508576 SAMN02422673
```
