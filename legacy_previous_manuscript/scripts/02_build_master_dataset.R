# ============================================================
# 02_build_master_dataset.R
#
# Purpose
# -------
# Builds the canonical 25-row analytical dataset by integrating
# plot-level UAV canopy metrics with final harvest measurements.
#
# Inputs
# ------
#   derived/canopy_summary_by_plot.csv
#   data/field/harvest_data.csv
#
# Output
# ------
#   data/common_bean_uav_master_dataset.csv
#
# Notes
# -----
# Final grain yield is measured once per plot and repeated across
# flight rows only to preserve the longitudinal data structure.
# Expected working directory: repository root.
# ============================================================

rm(list = ls())
gc()

project_root <- normalizePath(".", winslash = "/", mustWork = TRUE)

canopy_file <- file.path(
  project_root,
  "derived",
  "canopy_summary_by_plot.csv"
)

harvest_file <- file.path(
  project_root,
  "data",
  "field",
  "harvest_data.csv"
)

master_file <- file.path(
  project_root,
  "data",
  "common_bean_uav_master_dataset.csv"
)

if (!file.exists(canopy_file)) stop("Missing file: ", canopy_file)
if (!file.exists(harvest_file)) stop("Missing file: ", harvest_file)

canopy <- read.csv(
  canopy_file,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

harvest <- read.csv(
  harvest_file,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

required_canopy <- c(
  "flight","date","growth_stage","plot","N_rate_kg_ha",
  "canopy_area_m2","canopy_polygon_count",
  "NDVI_mean","MSAVI_mean","WDRVI_mean"
)

required_harvest <- c(
  "plot","N_rate_kg_ha",
  "harvest_area_m2","harvested_grain_kg"
)

if (!all(required_canopy %in% names(canopy))) {
  stop("The canopy summary is missing required columns.")
}
if (!all(required_harvest %in% names(harvest))) {
  stop("The harvest table is missing required columns.")
}

if (nrow(canopy) != 25) {
  stop("Expected 25 canopy rows; found ", nrow(canopy))
}
if (nrow(harvest) != 5) {
  stop("Expected 5 harvest rows; found ", nrow(harvest))
}
if (anyDuplicated(harvest$plot)) {
  stop("Duplicate plot IDs found in harvest_data.csv")
}

m <- match(canopy$plot, harvest$plot)

if (anyNA(m)) {
  stop("At least one canopy plot is missing from harvest_data.csv")
}

if (any(
  canopy$N_rate_kg_ha !=
  harvest$N_rate_kg_ha[m]
)) {
  stop("Nitrogen-rate mismatch between canopy and harvest data.")
}

harvest_area_m2 <- harvest$harvest_area_m2[m]
harvested_grain_kg <- harvest$harvested_grain_kg[m]

grain_yield_t_ha <-
  harvested_grain_kg /
  harvest_area_m2 *
  10

master <- data.frame(
  flight = canopy$flight,
  date = canopy$date,
  growth_stage = canopy$growth_stage,
  plot = canopy$plot,
  N_rate_kg_ha = canopy$N_rate_kg_ha,
  canopy_area_m2 = canopy$canopy_area_m2,
  canopy_polygon_count = canopy$canopy_polygon_count,
  NDVI_mean = canopy$NDVI_mean,
  MSAVI_mean = canopy$MSAVI_mean,
  WDRVI_mean = canopy$WDRVI_mean,
  harvest_area_m2 = harvest_area_m2,
  harvested_grain_kg = harvested_grain_kg,
  grain_yield_t_ha = grain_yield_t_ha,
  stringsAsFactors = FALSE
)

master <- master[
  order(
    master$flight,
    master$N_rate_kg_ha
  ),
]

stopifnot(nrow(master) == 25)

write.csv(
  master,
  master_file,
  row.names = FALSE,
  quote = FALSE
)

cat("\n====================================================\n")
cat("MASTER DATASET CREATED\n")
cat("====================================================\n")
cat("Rows: ", nrow(master), "\n", sep = "")
cat("Plots: ", length(unique(master$plot)), "\n", sep = "")
cat("Flights: ", length(unique(master$flight)), "\n", sep = "")
cat("Output: ", master_file, "\n", sep = "")
cat("\nImportant: grain yield is measured once per plot and is\n")
cat("repeated across flight rows only to maintain longitudinal structure.\n")