#!/usr/bin/env Rapp
#| name: ADS8192
#| title: ADS8192 PCA Tool
#| description: PCA analysis for SummarizedExperiment data (ADS 8192 reference implementation).

suppressPackageStartupMessages(library(ADS8192))
suppressPackageStartupMessages(library(SummarizedExperiment))
suppressPackageStartupMessages(library(ggplot2))

# Helper to read TSV/CSV (not exported; kept in CLI script)
read_data_file <- function(path) {
    ext <- tolower(tools::file_ext(path))
    if (ext == "csv") {
        read.csv(path, row.names = 1, check.names = FALSE)
    } else {
        utils::read.table(path, sep = "\t", header = TRUE, row.names = 1,
                          check.names = FALSE)
    }
}

switch(
    "",

    #| title: Run PCA analysis
    #| description: Run PCA on a counts matrix and sample metadata, export results.
    pca = {
        #| description: Path to counts matrix (TSV/CSV, genes x samples)
        #| short: c
        counts <- ""

        #| description: Path to sample metadata (TSV/CSV)
        #| short: m
        meta <- ""

        #| description: Output directory
        #| short: o
        output <- ""

        #| description: Number of top variable genes
        #| short: n
        n_top <- 500L

        #| description: Log-transform counts
        log_transform <- TRUE

        #| description: Metadata column for plot coloring (optional)
        color_by <- ""

        # Validation
        if (counts == "" || meta == "" || output == "") {
            stop("--counts, --meta, and --output are required", call. = FALSE)
        }
        if (!file.exists(counts)) {
            stop("File not found: ", counts, call. = FALSE)
        }
        if (!file.exists(meta)) {
            stop("File not found: ", meta, call. = FALSE)
        }

        if (!dir.exists(output)) dir.create(output, recursive = TRUE)

        # Read inputs
        counts_df <- read_data_file(counts)
        meta_df <- read_data_file(meta)

        # Run analysis using package core functions
        se <- SummarizedExperiment(
            assays = list(counts = as.matrix(counts_df)),
            colData = meta_df
        )
        result <- run_pca(se, n_top = n_top, log_transform = log_transform)

        save_pca_results(result, output)

        if (color_by != "") {
            plot_file <- file.path(output, "pca_plot.png")
            p <- plot_pca(result, color_by = color_by)
            ggsave(plot_file, p, width = 8, height = 6, dpi = 150)
            message("Saved: ", plot_file)
        }

        message("Done.")
    },

    #| title: Validate input files
    #| description: Check that input files exist, parse correctly, and report dimensions.
    validate = {
        #| description: Path to counts matrix (TSV/CSV)
        #| short: c
        counts <- ""

        #| description: Path to sample metadata (TSV/CSV)
        #| short: m
        meta <- ""

        # Validation
        if (counts == "" || meta == "") {
            stop("--counts and --meta are required", call. = FALSE)
        }
        if (!file.exists(counts)) {
            stop("File not found: ", counts, call. = FALSE)
        }
        if (!file.exists(meta)) {
            stop("File not found: ", meta, call. = FALSE)
        }

        # Parse and report
        counts_df <- read_data_file(counts)
        meta_df <- read_data_file(meta)

        message("Counts dimensions: ", nrow(counts_df), " genes x ",
                ncol(counts_df), " samples")
        message("Metadata rows: ", nrow(meta_df))
        message("Metadata columns: ",
                paste(colnames(meta_df), collapse = ", "))

        if (!all(colnames(counts_df) %in% rownames(meta_df))) {
            stop("Sample IDs in counts do not match metadata row names",
                 call. = FALSE)
        }

        message("All sample IDs match. Inputs look valid.")
    }
)
