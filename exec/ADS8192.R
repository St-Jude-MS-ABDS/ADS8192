#!/usr/bin/env Rapp
#| name: ADS8192
#| title: ADS8192 PCA Tool & Toaster
#| description: PCA analysis for SummarizedExperiment data (ADS 8192 reference implementation).

suppressPackageStartupMessages(library(ADS8192))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(SummarizedExperiment))

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
            png(plot_file, width = 8, height = 6, units = "in", res = 300)
            print(p)
            dev.off()
            message("Saved: ", plot_file)
        }

        message("Done.")
    },

    #| title: Make toast
    #| description: Make a slice of toast from the bread of your choice.
    toast = {
        #| description: Type of bread to use
        #| short: b
        bread <- ""

        #| description: Butter the toast
        buttered <- FALSE

        if (bread == "") {
            stop("--bread is required", call. = FALSE)
        }

        message(make_toast(bread = bread, buttered = buttered))
    }
)
