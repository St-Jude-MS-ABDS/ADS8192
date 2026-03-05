# Create a SummarizedExperiment from counts and metadata

Constructs a
[`SummarizedExperiment`](https://rdrr.io/pkg/SummarizedExperiment/man/SummarizedExperiment-class.html)
from a counts matrix and sample metadata data.frame. Optionally includes
row (gene/feature) metadata.

## Usage

``` r
make_se(counts, col_data, row_data = NULL)
```

## Arguments

- counts:

  A matrix of counts (genes x samples). Row names should be gene
  identifiers, column names should be sample identifiers. If not a
  matrix, will be coerced via
  [`as.matrix()`](https://rdrr.io/r/base/matrix.html).

- col_data:

  A data.frame of sample metadata. Row names must match column names of
  `counts`.

- row_data:

  Optional data.frame of gene/feature metadata. Row names must match row
  names of `counts`. Default: `NULL`.

## Value

A
[`SummarizedExperiment`](https://rdrr.io/pkg/SummarizedExperiment/man/SummarizedExperiment-class.html)
object with one assay named `"counts"`.

## Examples

``` r
counts <- matrix(rpois(100, 50), nrow = 10, ncol = 10)
rownames(counts) <- paste0("gene", 1:10)
colnames(counts) <- paste0("sample", 1:10)
meta <- data.frame(
  treatment = rep(c("ctrl", "trt"), each = 5),
  row.names = colnames(counts)
)
se <- make_se(counts, meta)
se
#> class: SummarizedExperiment 
#> dim: 10 10 
#> metadata(0):
#> assays(1): counts
#> rownames(10): gene1 gene2 ... gene9 gene10
#> rowData names(0):
#> colnames(10): sample1 sample2 ... sample9 sample10
#> colData names(1): treatment
```
