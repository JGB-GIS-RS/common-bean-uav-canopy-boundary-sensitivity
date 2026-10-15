# R2-02: Leave-one-plot-out (LOPO) sensitivity of median directional slopes
# Reconstructed reproducibility script; the original local RStudio script
# was not included in the archived R2-02 diagnostics.
# Requires base R only. Execute from project root:
#   Rscript scripts/10_lopo_median_sensitivity.R .
#
# Input: derived/boundary_sensitivity/directional_beta_by_plot.csv
# Outputs: derived/reviewer2_diagnostics/R2_02_MEDIAN_LOPO/
# Does not overwrite input tables, legacy robustness results, or figures.

args <- commandArgs(trailingOnly = TRUE)
project_root <- if (length(args)) args[[1]] else getwd()
project_root <- normalizePath(project_root, winslash = "/", mustWork = TRUE)
input_file <- file.path(project_root, "derived", "boundary_sensitivity",
                        "directional_beta_by_plot.csv")
output_dir <- file.path(project_root, "derived", "reviewer2_diagnostics",
                        "R2_02_MEDIAN_LOPO")
if (!file.exists(input_file)) stop("Missing baseline coefficients: ", input_file)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

dat <- read.csv(input_file, stringsAsFactors = FALSE, check.names = FALSE)
required <- c("growth_stage", "index", "subplot", "abs_beta_erosion",
              "abs_beta_dilation", "dilation_to_erosion_ratio",
              "directional_asymmetry_pct")
if (!all(required %in% names(dat))) {
  stop("Missing required columns: ",
       paste(setdiff(required, names(dat)), collapse = ", "))
}
stages <- c("V4", "R5", "R6", "R7", "R8")
indices <- c("NDVI", "MSAVI", "WDRVI")
plots <- paste0("P", seq_len(5))
num_vars <- required[4:7]
if (nrow(dat) != 75L ||
    anyNA(dat[, required]) ||
    !all(vapply(dat[, num_vars, drop = FALSE],
                function(v) is.numeric(v) && all(is.finite(v)), logical(1))) ||
    any(dat$abs_beta_erosion <= 0) ||
    any(dat$abs_beta_dilation <= 0) ||
    !all(dat$growth_stage %in% stages) ||
    !all(dat$index %in% indices) ||
    !all(dat$subplot %in% plots)) {
  stop("Invalid or incomplete finalized R2-01 coefficient table.")
}
if (any(abs(dat$dilation_to_erosion_ratio -
            dat$abs_beta_dilation / dat$abs_beta_erosion) > 1e-8)) {
  stop("Stored plot-specific ratios disagree with absolute slopes.")
}
for (stage in stages) for (idx in indices) {
  subgroup <- dat[dat$growth_stage == stage & dat$index == idx, ]
  if (nrow(subgroup) != 5L || !setequal(subgroup$subplot, plots)) {
    stop("Unexpected plot support in: ", stage, " / ", idx)
  }
}

dominance <- function(x) {
  if (x < 1) "erosion" else if (x > 1) "dilation" else "equal"
}
relative_change <- function(new, old) 100 * (new - old) / abs(old)

detail_rows <- list()
summary_rows <- list()
for (stage in stages) {
  for (idx in indices) {
    full <- dat[dat$growth_stage == stage & dat$index == idx, ]
    e0 <- median(full$abs_beta_erosion)
    d0 <- median(full$abs_beta_dilation)
    plot_ratio0 <- median(full$dilation_to_erosion_ratio)
    ratio_medians0 <- d0 / e0
    asym0 <- median(full$directional_asymmetry_pct)
    group_rows <- list()

    for (omitted in plots) {
      remaining <- full[full$subplot != omitted, ]
      e1 <- median(remaining$abs_beta_erosion)
      d1 <- median(remaining$abs_beta_dilation)
      plot_ratio1 <- median(remaining$dilation_to_erosion_ratio)
      ratio_medians1 <- d1 / e1
      plot_flip <- dominance(plot_ratio0) != dominance(plot_ratio1)
      median_flip <- dominance(ratio_medians0) != dominance(ratio_medians1)

      one <- data.frame(
        growth_stage = stage, index = idx, omitted_plot = omitted,
        n_full = nrow(full), n_lopo = nrow(remaining),
        erosion_median_full = e0, erosion_median_lopo = e1,
        erosion_relative_change_pct = relative_change(e1, e0),
        dilation_median_full = d0, dilation_median_lopo = d1,
        dilation_relative_change_pct = relative_change(d1, d0),
        median_plot_ratio_full = plot_ratio0,
        median_plot_ratio_lopo = plot_ratio1,
        median_plot_ratio_change_pct = relative_change(plot_ratio1, plot_ratio0),
        plot_ratio_dominance_full = dominance(plot_ratio0),
        plot_ratio_dominance_lopo = dominance(plot_ratio1),
        plot_ratio_dominance_flip = plot_flip,
        ratio_of_medians_full = ratio_medians0,
        ratio_of_medians_lopo = ratio_medians1,
        ratio_of_medians_dominance_full = dominance(ratio_medians0),
        ratio_of_medians_dominance_lopo = dominance(ratio_medians1),
        ratio_of_medians_dominance_flip = median_flip,
        asymmetry_median_full = asym0,
        asymmetry_median_lopo = median(remaining$directional_asymmetry_pct),
        stringsAsFactors = FALSE
      )
      group_rows[[length(group_rows) + 1L]] <- one
      detail_rows[[length(detail_rows) + 1L]] <- one
    }
    group <- do.call(rbind, group_rows)
    summary_rows[[length(summary_rows) + 1L]] <- data.frame(
      growth_stage = stage, index = idx,
      max_abs_erosion_median_change_pct =
        max(abs(group$erosion_relative_change_pct)),
      max_abs_dilation_median_change_pct =
        max(abs(group$dilation_relative_change_pct)),
      full_median_plot_ratio = plot_ratio0,
      lopo_plot_ratio_min = min(group$median_plot_ratio_lopo),
      lopo_plot_ratio_max = max(group$median_plot_ratio_lopo),
      n_plot_ratio_direction_flips = sum(group$plot_ratio_dominance_flip),
      full_ratio_of_medians = ratio_medians0,
      n_ratio_of_medians_direction_flips =
        sum(group$ratio_of_medians_dominance_flip),
      stringsAsFactors = FALSE
    )
  }
}
detail <- do.call(rbind, detail_rows)
summary <- do.call(rbind, summary_rows)
rownames(detail) <- NULL
rownames(summary) <- NULL

ranking_rows <- list()
for (stage in stages) for (omitted in plots) for (direction in c("erosion", "dilation")) {
  remaining <- dat[dat$growth_stage == stage & dat$subplot != omitted, ]
  col <- paste0("abs_beta_", direction)
  median_by_index <- vapply(indices, function(idx) {
    median(remaining[remaining$index == idx, col])
  }, numeric(1))
  ordered <- paste(indices[order(median_by_index, decreasing = TRUE)],
                   collapse = " > ")
  ranking_rows[[length(ranking_rows) + 1L]] <- data.frame(
    growth_stage = stage, omitted_plot = omitted,
    direction = direction, ranked_indices = ordered,
    same_order = (ordered == "WDRVI > MSAVI > NDVI"),
    stringsAsFactors = FALSE
  )
}
ranking <- do.call(rbind, ranking_rows)
rownames(ranking) <- NULL

# Numerical QA checks are descriptive consistency tests, NOT inference.
stopifnot(
  nrow(detail) == 75L, nrow(summary) == 15L, nrow(ranking) == 50L,
  sum(detail$plot_ratio_dominance_flip) == 0L,
  sum(detail$ratio_of_medians_dominance_flip) == 10L,
  all(ranking$same_order),
  abs(max(abs(detail$erosion_relative_change_pct)) -
      49.82925648466148) < 1e-7,
  abs(max(abs(detail$dilation_relative_change_pct)) -
      89.93187445587677) < 1e-7
)
write.csv(detail, file.path(output_dir, "R2_02_LOPO_MEDIAN_DETAIL.csv"),
          row.names = FALSE, na = "")
write.csv(summary, file.path(output_dir, "R2_02_LOPO_MEDIAN_SUMMARY.csv"),
          row.names = FALSE, na = "")
write.csv(ranking, file.path(output_dir, "R2_02_INDEX_RANKING_QA.csv"),
          row.names = FALSE, na = "")

cat("PASS: R2-02 median LOPO calculations\n",
    "Input MD5: ", unname(tools::md5sum(input_file)), "\n",
    "Omissions: ", nrow(detail), "\n",
    "Summaries: ", nrow(summary), "\n",
    "Rankings: ", nrow(ranking), "\n",
    "Maximum erosion median change (%): ",
    max(abs(detail$erosion_relative_change_pct)), "\n",
    "Maximum dilation median change (%): ",
    max(abs(detail$dilation_relative_change_pct)), "\n",
    "Median-of-ratios flips: ", sum(detail$plot_ratio_dominance_flip), "\n",
    "Ratio-of-medians flips: ",
    sum(detail$ratio_of_medians_dominance_flip), "\n",
    "Ranking changes: ", sum(!ranking$same_order), "\n",
    "Output: ", output_dir, "\n", sep = "")
