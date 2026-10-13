# ============================================================
# 03_descriptive_analysis.R
#
# Purpose
# -------
# Performs the descriptive and exploratory analyses used in the
# common-bean UAV nitrogen-gradient manuscript.
#
# Design constraints
# ------------------
# - Five plots were observed repeatedly across five UAV flights.
# - Each nitrogen rate is represented by one plot only.
# - Nitrogen treatments are not independently replicated.
# - Grain yield was measured once per plot at final harvest.
# - The 25 longitudinal rows must not be treated as 25 independent
#   yield observations.
# - No treatment-level hypothesis tests, ANOVA, inferential p-values,
#   or pooled yield regressions with n = 25 are performed.
#
# Input
# -----
#   data/common_bean_uav_master_dataset.csv
#
# Outputs
# -------
#   derived/descriptive_summary_by_flight.csv
#   derived/exploratory_N_associations_by_flight.csv
#   derived/exploratory_yield_associations_by_flight.csv
#   derived/final_harvest_by_plot.csv
#   derived/exploratory_N_yield_association.csv
#   derived/descriptive_analysis_notes.txt
#
# Expected working directory: repository root.
# ============================================================

rm(list = ls())
gc()

# ------------------------------------------------------------
# 1. PROJECT PATHS
# ------------------------------------------------------------

project_root <- normalizePath(
  ".",
  winslash = "/",
  mustWork = TRUE
)

master_file <- file.path(
  project_root,
  "data",
  "common_bean_uav_master_dataset.csv"
)

derived_root <- file.path(
  project_root,
  "derived"
)

if (!file.exists(master_file)) {
  stop(
    "Missing master dataset:\n",
    master_file
  )
}

if (!dir.exists(derived_root)) {
  dir.create(
    derived_root,
    recursive = TRUE
  )
}

# ------------------------------------------------------------
# 2. READ DATA
# ------------------------------------------------------------

d <- read.csv(
  master_file,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

required_columns <- c(
  "flight",
  "date",
  "growth_stage",
  "plot",
  "N_rate_kg_ha",
  "canopy_area_m2",
  "canopy_polygon_count",
  "NDVI_mean",
  "MSAVI_mean",
  "WDRVI_mean",
  "harvest_area_m2",
  "harvested_grain_kg",
  "grain_yield_t_ha"
)

missing_columns <- setdiff(
  required_columns,
  names(d)
)

if (length(missing_columns) > 0) {
  stop(
    "Missing required column(s): ",
    paste(
      missing_columns,
      collapse = ", "
    )
  )
}

# ------------------------------------------------------------
# 3. STRUCTURAL QA
# ------------------------------------------------------------

if (nrow(d) != 25) {
  stop(
    "Expected 25 rows; found ",
    nrow(d)
  )
}

if (length(unique(d$flight)) != 5) {
  stop("Expected 5 flights.")
}

if (length(unique(d$plot)) != 5) {
  stop("Expected 5 plots.")
}

rows_per_flight <- table(d$flight)

if (any(rows_per_flight != 5)) {
  stop(
    "Each flight must contain exactly 5 plot records."
  )
}

rows_per_plot <- table(d$plot)

if (any(rows_per_plot != 5)) {
  stop(
    "Each plot must contain exactly 5 repeated UAV observations."
  )
}

# Check that treatment assignment is constant within plot
for (s in unique(d$plot)) {

  z <- d[
    d$plot == s,
  ]

  if (length(unique(z$N_rate_kg_ha)) != 1) {
    stop(
      "Nitrogen rate is not constant for plot ",
      s
    )
  }
}

# Check that harvest variables are constant across repeated flights
harvest_fields <- c(
  "harvest_area_m2",
  "harvested_grain_kg",
  "grain_yield_t_ha"
)

for (s in unique(d$plot)) {

  z <- d[
    d$plot == s,
  ]

  for (v in harvest_fields) {

    if (length(unique(z[[v]])) != 1) {
      stop(
        "Harvest variable ",
        v,
        " is not constant across flights for plot ",
        s
      )
    }
  }
}

# ------------------------------------------------------------
# 4. ORDER DATA
# ------------------------------------------------------------

d <- d[
  order(
    d$flight,
    d$N_rate_kg_ha
  ),
]

# ------------------------------------------------------------
# 5. DESCRIPTIVE SUMMARY BY FLIGHT
# ------------------------------------------------------------

uav_variables <- c(
  "canopy_area_m2",
  "NDVI_mean",
  "MSAVI_mean",
  "WDRVI_mean"
)

summary_rows <- list()
k <- 1

for (f in sort(unique(d$flight))) {

  z <- d[
    d$flight == f,
  ]

  for (v in uav_variables) {

    x <- z[[v]]

    summary_rows[[k]] <- data.frame(
      flight = f,
      date = z$date[1],
      growth_stage = z$growth_stage[1],
      variable = v,
      n_plots = length(x),
      mean = mean(
        x,
        na.rm = TRUE
      ),
      sd = sd(
        x,
        na.rm = TRUE
      ),
      median = median(
        x,
        na.rm = TRUE
      ),
      min = min(
        x,
        na.rm = TRUE
      ),
      max = max(
        x,
        na.rm = TRUE
      ),
      range = diff(
        range(
          x,
          na.rm = TRUE
        )
      ),
      stringsAsFactors = FALSE
    )

    k <- k + 1
  }
}

descriptive_summary <- do.call(
  rbind,
  summary_rows
)

# ------------------------------------------------------------
# 6. EXPLORATORY ASSOCIATIONS WITH N RATE
# ------------------------------------------------------------
#
# These are descriptive effect-pattern summaries only.
# No p-values are produced because each flight has n = 5 and
# nitrogen rates are not independently replicated treatments.
# ------------------------------------------------------------

N_assoc_rows <- list()
k <- 1

for (f in sort(unique(d$flight))) {

  z <- d[
    d$flight == f,
  ]

  xN <- z$N_rate_kg_ha

  for (v in uav_variables) {

    y <- z[[v]]

    N_assoc_rows[[k]] <- data.frame(
      flight = f,
      date = z$date[1],
      growth_stage = z$growth_stage[1],
      variable = v,
      n = nrow(z),
      pearson_r = cor(
        xN,
        y,
        method = "pearson",
        use = "complete.obs"
      ),
      spearman_rho = cor(
        xN,
        y,
        method = "spearman",
        use = "complete.obs"
      ),
      stringsAsFactors = FALSE
    )

    k <- k + 1
  }
}

N_associations <- do.call(
  rbind,
  N_assoc_rows
)

# ------------------------------------------------------------
# 7. FINAL HARVEST TABLE
# ------------------------------------------------------------

harvest_table <- unique(
  d[
    ,
    c(
      "plot",
      "N_rate_kg_ha",
      "harvest_area_m2",
      "harvested_grain_kg",
      "grain_yield_t_ha"
    )
  ]
)

harvest_table <- harvest_table[
  order(
    harvest_table$N_rate_kg_ha
  ),
]

if (nrow(harvest_table) != 5) {
  stop(
    "Expected exactly 5 independent final-harvest records."
  )
}

# ------------------------------------------------------------
# 8. EXPLORATORY N-RATE / YIELD ASSOCIATION
# ------------------------------------------------------------

N_yield_association <- data.frame(
  variable_x = "N_rate_kg_ha",
  variable_y = "grain_yield_t_ha",
  n = nrow(harvest_table),
  pearson_r = cor(
    harvest_table$N_rate_kg_ha,
    harvest_table$grain_yield_t_ha,
    method = "pearson"
  ),
  spearman_rho = cor(
    harvest_table$N_rate_kg_ha,
    harvest_table$grain_yield_t_ha,
    method = "spearman"
  ),
  interpretation =
    "Exploratory descriptive association only; one plot per N rate.",
  stringsAsFactors = FALSE
)

# ------------------------------------------------------------
# 9. UAV METRIC / FINAL YIELD ASSOCIATIONS BY FLIGHT
# ------------------------------------------------------------
#
# Yield is evaluated separately within each flight.
# Each correlation therefore uses the five independent plot-level
# harvest observations once, never the pooled 25-row structure.
# ------------------------------------------------------------

yield_assoc_rows <- list()
k <- 1

for (f in sort(unique(d$flight))) {

  z <- d[
    d$flight == f,
  ]

  y <- z$grain_yield_t_ha

  for (v in uav_variables) {

    x <- z[[v]]

    yield_assoc_rows[[k]] <- data.frame(
      flight = f,
      date = z$date[1],
      growth_stage = z$growth_stage[1],
      UAV_variable = v,
      n = nrow(z),
      pearson_r = cor(
        x,
        y,
        method = "pearson",
        use = "complete.obs"
      ),
      spearman_rho = cor(
        x,
        y,
        method = "spearman",
        use = "complete.obs"
      ),
      stringsAsFactors = FALSE
    )

    k <- k + 1
  }
}

yield_associations <- do.call(
  rbind,
  yield_assoc_rows
)

# ------------------------------------------------------------
# 10. WRITE OUTPUTS
# ------------------------------------------------------------

write.csv(
  descriptive_summary,
  file.path(
    derived_root,
    "descriptive_summary_by_flight.csv"
  ),
  row.names = FALSE
)

write.csv(
  N_associations,
  file.path(
    derived_root,
    "exploratory_N_associations_by_flight.csv"
  ),
  row.names = FALSE
)

write.csv(
  yield_associations,
  file.path(
    derived_root,
    "exploratory_yield_associations_by_flight.csv"
  ),
  row.names = FALSE
)

write.csv(
  harvest_table,
  file.path(
    derived_root,
    "final_harvest_by_plot.csv"
  ),
  row.names = FALSE
)

write.csv(
  N_yield_association,
  file.path(
    derived_root,
    "exploratory_N_yield_association.csv"
  ),
  row.names = FALSE
)

# ------------------------------------------------------------
# 11. ANALYSIS NOTES
# ------------------------------------------------------------

notes <- c(
  "DESCRIPTIVE ANALYSIS NOTES",
  "==========================",
  "",
  "Experimental structure:",
  "- 5 field plots observed repeatedly across 5 UAV flights.",
  "- One nitrogen rate per plot; nitrogen treatments are not independently replicated.",
  "- 25 spectral/structural rows, but only 5 independent final-harvest observations.",
  "",
  "Analytical rules used in 03_descriptive_analysis.R:",
  "- No ANOVA or replicated-treatment hypothesis testing.",
  "- No inferential p-values for nitrogen-rate associations.",
  "- No pooled n=25 regression against final grain yield.",
  "- N-rate correlations are descriptive summaries within each flight (n=5).",
  "- UAV/yield correlations are calculated separately by flight (n=5).",
  "- Pearson r and Spearman rho are reported as exploratory association measures.",
  "",
  "Interpretation:",
  "- Results can describe temporal patterns and within-date gradients.",
  "- Results cannot establish causal fertilizer effects or a generalizable optimum N rate."
)

writeLines(
  notes,
  file.path(
    derived_root,
    "descriptive_analysis_notes.txt"
  )
)

# ------------------------------------------------------------
# 12. CONSOLE REPORT
# ------------------------------------------------------------

cat("\n")
cat("====================================================\n")
cat("DESCRIPTIVE ANALYSIS COMPLETED\n")
cat("====================================================\n\n")

cat("Rows in master dataset: ", nrow(d), "\n", sep = "")
cat("Flights: ", length(unique(d$flight)), "\n", sep = "")
cat("Plots: ", length(unique(d$plot)), "\n", sep = "")
cat("Independent harvest records: ", nrow(harvest_table), "\n", sep = "")

cat("\nMean UAV metrics by flight:\n")

wide_summary <- reshape(
  descriptive_summary[
    ,
    c(
      "flight",
      "date",
      "growth_stage",
      "variable",
      "mean"
    )
  ],
  idvar = c(
    "flight",
    "date",
    "growth_stage"
  ),
  timevar = "variable",
  direction = "wide"
)

print(
  wide_summary,
  row.names = FALSE
)

cat("\nExploratory N-rate associations by flight:\n")

print(
  N_associations,
  row.names = FALSE
)

cat("\nExploratory UAV / final-yield associations by flight:\n")

print(
  yield_associations,
  row.names = FALSE
)

cat("\nOutputs written to:\n")
cat(
  derived_root,
  "\n"
)

# ============================================================
# END
# ============================================================