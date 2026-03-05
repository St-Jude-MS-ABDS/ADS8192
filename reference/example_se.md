# Example SummarizedExperiment for testing

A small simulated
[`SummarizedExperiment`](https://rdrr.io/pkg/SummarizedExperiment/man/SummarizedExperiment-class.html)
with 100 genes and 8 samples, designed for testing and examples. The
first 20 genes have a simulated treatment effect (2x higher counts in
treated samples).

## Usage

``` r
example_se
```

## Format

A
[`SummarizedExperiment`](https://rdrr.io/pkg/SummarizedExperiment/man/SummarizedExperiment-class.html)
with:

- assays:

  `counts` — raw count matrix (100 genes x 8 samples)

- colData:

  `sample_id`, `treatment` (control/treated), `batch` (A/B)

- rowData:

  `gene_id`, `gene_symbol`

## Source

Simulated data for teaching purposes.

## Examples

``` r
data(example_se)
example_se
#> class: SummarizedExperiment 
#> dim: 100 8 
#> metadata(0):
#> assays(1): counts
#> rownames(100): gene1 gene2 ... gene99 gene100
#> rowData names(2): gene_id gene_symbol
#> colnames(8): sample1 sample2 ... sample7 sample8
#> colData names(3): sample_id treatment batch
SummarizedExperiment::colData(example_se)
#> DataFrame with 8 rows and 3 columns
#>           sample_id   treatment       batch
#>         <character> <character> <character>
#> sample1     sample1     control           A
#> sample2     sample2     control           B
#> sample3     sample3     control           A
#> sample4     sample4     control           B
#> sample5     sample5     treated           A
#> sample6     sample6     treated           B
#> sample7     sample7     treated           A
#> sample8     sample8     treated           B
```
