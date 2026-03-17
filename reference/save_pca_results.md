# Save PCA results to files

Writes PCA scores and variance explained to tab-separated files.
Optionally saves a PCA plot as PNG.

## Usage

``` r
save_pca_results(pca_result, output_dir, prefix = "pca")
```

## Arguments

- pca_result:

  Output from
  [`run_pca()`](https://automatic-engine-4qp7m5e.pages.github.io/reference/run_pca.md).

- output_dir:

  Directory to save files. Created if it does not exist.

- prefix:

  Prefix for filenames. Default: `"pca"`.

## Value

Invisible `NULL`; files are written to `output_dir`:

- `{prefix}_scores.tsv`:

  PCA scores with sample metadata.

- `{prefix}_variance.tsv`:

  Variance explained by each PC.

## Author

Jared Andrews

## Examples

``` r
if (FALSE) { # \dontrun{
data(airway, package = "airway")
result <- run_pca(airway, n_top = 50)
save_pca_results(result, tempdir())
} # }
```
