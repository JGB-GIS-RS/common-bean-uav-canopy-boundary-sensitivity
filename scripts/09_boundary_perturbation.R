# ============================================================
# 09_boundary_perturbation.R
#
# Purpose
# -------
# Quantifies the sensitivity of UAV vegetation-index means to
# controlled perturbations of the segmented canopy boundary.
#
# Perturbations
# -------------
#   -3, -2, -1, 0, +1, +2, +3 cm
#
# Negative values erode the segmented canopy.
# Positive values dilate the segmented canopy.
# Canopy assigned to another subplot is removed from dilated masks.
#
# Inputs per flight
# -----------------
#   data/spatial/flightXX/canopy_YYYYMMDD.gpkg
#   data/spatial/flightXX/ndvi_YYYYMMDD.tif
#   data/spatial/flightXX/msavi_YYYYMMDD.tif
#   data/spatial/flightXX/wdrvi_YYYYMMDD.tif
#
# Reference input for QA
# ----------------------
#   derived/canopy_summary_by_plot.csv
#
# Outputs
# -------
#   derived/boundary_sensitivity/
#     boundary_perturbation_observations.csv
#     boundary_geometry_qa.csv
#     crossplot_overlap_qa.csv
#     baseline_reproduction_check.csv
#
# Notes
# -----
# The perturbations are deterministic transformations of the same
# segmented canopy and MUST NOT be interpreted as independent
# experimental replicates.
#
# The repository root is detected automatically from the current working directory or its parent directories.
# ============================================================

rm(list = ls())
gc()

library(terra)

# ------------------------------------------------------------
# 1. PROJECT PATHS
# ------------------------------------------------------------

find_project_root <- function(start = getwd()) {

  current <- normalizePath(
    start,
    winslash = "/",
    mustWork = TRUE
  )

  repeat {

    has_lockfile <- file.exists(
      file.path(
        current,
        "renv.lock"
      )
    )

    has_scripts <- dir.exists(
      file.path(
        current,
        "scripts"
      )
    )

    if (has_lockfile && has_scripts) {
      return(current)
    }

    parent <- dirname(current)

    if (identical(parent, current)) {
      break
    }

    current <- parent
  }

  stop(
    "Repository root could not be detected from working directory: ",
    normalizePath(start, winslash = "/", mustWork = TRUE),
    "\nExpected a parent directory containing renv.lock and scripts/."
  )
}

project_root <- find_project_root()

cat(
  "Repository root detected: ",
  project_root,
  "\n",
  sep = ""
)

spatial_root <- file.path(
  project_root,
  "data",
  "spatial"
)

derived_root <- file.path(
  project_root,
  "derived",
  "boundary_sensitivity"
)

reference_candidates <- c(
  file.path(
    project_root,
    "derived",
    "canopy_summary_by_plot.csv"
  ),
  file.path(
    project_root,
    "derived",
    "canopy_summary_by_subplot.csv"
  )
)

existing_reference_files <- reference_candidates[
  file.exists(reference_candidates)
]

reference_file <- if (length(existing_reference_files) > 0) {
  existing_reference_files[1]
} else {
  reference_candidates[1]
}

if (!dir.exists(spatial_root)) {
  stop(
    "Directory not found: ",
    spatial_root,
    "\n\nOpen the RStudio project at the repository root."
  )
}

if (!dir.exists(derived_root)) {
  dir.create(
    derived_root,
    recursive = TRUE
  )
}

# ------------------------------------------------------------
# 2. FLIGHT METADATA
# ------------------------------------------------------------

flights <- data.frame(
  flight = 1:5,
  folder = c(
    "flight01",
    "flight02",
    "flight03",
    "flight04",
    "flight05"
  ),
  date = c(
    "2024-09-07",
    "2024-09-14",
    "2024-10-02",
    "2024-10-09",
    "2024-10-16"
  ),
  file_date = c(
    "20240907",
    "20240914",
    "20241002",
    "20241009",
    "20241016"
  ),
  growth_stage = c(
    "V4",
    "R5",
    "R6",
    "R7",
    "R8"
  ),
  stringsAsFactors = FALSE
)

subplots <- paste0(
  "P",
  1:5
)

indices <- c(
  "NDVI",
  "MSAVI",
  "WDRVI"
)

perturb_cm <- c(
  -3,
  -2,
  -1,
  0,
  1,
  2,
  3
)

# ------------------------------------------------------------
# 3. HELPER FUNCTIONS
# ------------------------------------------------------------

dissolve_vector <- function(v) {

  if (is.null(v) || nrow(v) == 0) {
    return(v)
  }

  if (nrow(v) == 1) {
    return(v)
  }

  terra::aggregate(
    v,
    dissolve = TRUE
  )
}

vector_area_m2 <- function(v) {

  if (is.null(v) || nrow(v) == 0) {
    return(0)
  }

  a <- terra::expanse(
    v,
    unit = "m",
    transform = FALSE
  )

  sum(
    a,
    na.rm = TRUE
  )
}

safe_intersection_area <- function(x, y) {

  if (
    is.null(x) ||
    is.null(y) ||
    nrow(x) == 0 ||
    nrow(y) == 0
  ) {
    return(0)
  }

  # A missing intersection is an expected geometric outcome for many
  # subplot × dilation combinations. terra emits a warning in that case;
  # suppress it here because the function explicitly converts the
  # no-intersection case to an overlap area of zero.
  z <- suppressWarnings(
    try(
      terra::intersect(
        x,
        y
      ),
      silent = TRUE
    )
  )

  if (
    inherits(z, "try-error") ||
    is.null(z) ||
    nrow(z) == 0
  ) {
    return(0)
  }

  vector_area_m2(z)
}

extract_mean <- function(r, v) {

  if (
    is.null(v) ||
    nrow(v) == 0
  ) {
    return(
      data.frame(
        mean_index = NA_real_,
        n_valid_pixels = 0L,
        stringsAsFactors = FALSE
      )
    )
  }

  if (!same.crs(v, r)) {
    v <- project(
      v,
      crs(r)
    )
  }

  z <- terra::extract(
    r,
    v,
    ID = TRUE,
    cells = TRUE
  )

  value_col <- names(r)[1]

  z <- z[
    is.finite(
      z[[value_col]]
    ),
  ]

  if (nrow(z) == 0) {
    return(
      data.frame(
        mean_index = NA_real_,
        n_valid_pixels = 0L,
        stringsAsFactors = FALSE
      )
    )
  }

  z <- z[
    !duplicated(
      z$cell
    ),
  ]

  data.frame(
    mean_index = mean(
      z[[value_col]],
      na.rm = TRUE
    ),
    n_valid_pixels = nrow(z),
    stringsAsFactors = FALSE
  )
}

# ------------------------------------------------------------
# 4. PROCESS ALL FLIGHTS
# ------------------------------------------------------------

spectral_rows <- list()
geometry_rows <- list()
crossplot_rows <- list()

spectral_counter <- 1
geometry_counter <- 1
crossplot_counter <- 1

for (i in seq_len(nrow(flights))) {

  flight_id <- flights$flight[i]
  folder_name <- flights$folder[i]
  date_txt <- flights$date[i]
  file_date <- flights$file_date[i]
  growth_stage <- flights$growth_stage[i]

  flight_dir <- file.path(
    spatial_root,
    folder_name
  )

  gpkg_file <- file.path(
    flight_dir,
    paste0(
      "canopy_",
      file_date,
      ".gpkg"
    )
  )

  raster_files <- c(
    NDVI = file.path(
      flight_dir,
      paste0(
        "ndvi_",
        file_date,
        ".tif"
      )
    ),
    MSAVI = file.path(
      flight_dir,
      paste0(
        "msavi_",
        file_date,
        ".tif"
      )
    ),
    WDRVI = file.path(
      flight_dir,
      paste0(
        "wdrvi_",
        file_date,
        ".tif"
      )
    )
  )

  if (!file.exists(gpkg_file)) {
    stop(
      "Missing GeoPackage:\n",
      gpkg_file
    )
  }

  missing_rasters <- raster_files[
    !file.exists(
      raster_files
    )
  ]

  if (length(missing_rasters) > 0) {
    stop(
      "Missing raster(s):\n",
      paste(
        missing_rasters,
        collapse = "\n"
      )
    )
  }

  cat("\n")
  cat("====================================================\n")
  cat(
    "FLIGHT ",
    flight_id,
    " | ",
    date_txt,
    " | ",
    growth_stage,
    "\n",
    sep = ""
  )
  cat("====================================================\n")

  canopy_all <- vect(
    gpkg_file,
    layer = "canopy"
  )

  subplot_field <- if (
    "subplot" %in% names(canopy_all)
  ) {
    "subplot"
  } else if (
    "plot" %in% names(canopy_all)
  ) {
    "plot"
  } else {
    stop(
      "The canopy GeoPackage must contain a 'subplot' or 'plot' field:\n",
      gpkg_file
    )
  }

  # Read canopy IDs explicitly from the SpatVector attribute table.
  # This avoids relying on [[ ]] dispatch for SpatVector objects.
  subplot_ids_raw <- terra::values(
    canopy_all
  )[[subplot_field]]

  subplot_ids <- toupper(
    trimws(
      as.character(
        subplot_ids_raw
      )
    )
  )

  # Harmonize common ID representations without modifying source files.
  subplot_ids <- gsub("^SUBPLOT[ _-]*", "P", subplot_ids)
  subplot_ids <- gsub("^PLOT[ _-]*", "P", subplot_ids)
  subplot_ids <- gsub("^P[ _-]*", "P", subplot_ids)

  numeric_ids <- grepl("^[1-5]$", subplot_ids)

  subplot_ids[numeric_ids] <- paste0(
    "P",
    subplot_ids[numeric_ids]
  )

  canopy_all$subplot_work <- subplot_ids

  detected_subplots <- sort(
    unique(
      subplot_ids[
        !is.na(subplot_ids) &
          nzchar(subplot_ids)
      ]
    )
  )

  cat(
    "Canopy ID field: ",
    subplot_field,
    "\n",
    sep = ""
  )

  cat(
    "Canopy IDs detected: ",
    paste(
      detected_subplots,
      collapse = ", "
    ),
    "\n",
    sep = ""
  )

  if (!all(
    subplots %in%
      detected_subplots
  )) {
    stop(
      "Expected P1-P5 in:\n",
      gpkg_file,
      "\nDetected values: ",
      paste(
        detected_subplots,
        collapse = ", "
      )
    )
  }

  all_canopy_union <- dissolve_vector(
    canopy_all
  )

  rasters <- lapply(
    raster_files,
    rast
  )

  for (idx in names(rasters)) {
    names(
      rasters[[idx]]
    ) <- idx
  }

  for (subplot in subplots) {

    canopy_raw <- canopy_all[
      canopy_all$subplot_work == subplot,
    ]

    if (nrow(canopy_raw) == 0) {
      stop(
        "No canopy geometry found for ",
        subplot,
        " at ",
        growth_stage
      )
    }

    canopy_union <- dissolve_vector(
      canopy_raw
    )

    original_area_m2 <- vector_area_m2(
      canopy_union
    )

    other_canopy_raw <- canopy_all[
      canopy_all$subplot_work != subplot,
    ]

    other_canopy_union <- dissolve_vector(
      other_canopy_raw
    )

    for (d_cm in perturb_cm) {

      d_m <- d_cm / 100

      if (d_cm < 0) {

        perturbed_geom <- terra::buffer(
          canopy_union,
          width = d_m
        )

        raw_expanded_area_m2 <- NA_real_
        overlap_other_area_m2 <- 0

      } else if (d_cm == 0) {

        # Use the original, non-dissolved geometry for extraction.
        # This reproduces the extraction logic used by Script 01,
        # while geometry areas are measured on the dissolved canopy.
        perturbed_geom <- canopy_union

        raw_expanded_area_m2 <- original_area_m2
        overlap_other_area_m2 <- 0

      } else {

        raw_geom <- terra::buffer(
          canopy_union,
          width = d_m
        )

        raw_expanded_area_m2 <- vector_area_m2(
          raw_geom
        )

        overlap_other_area_m2 <- safe_intersection_area(
          raw_geom,
          other_canopy_union
        )

        perturbed_geom <- terra::erase(
          raw_geom,
          other_canopy_union
        )
      }

      perturbed_area_m2 <- vector_area_m2(
        perturbed_geom
      )

      area_change_pct <- if (
        original_area_m2 > 0
      ) {
        100 *
          (
            perturbed_area_m2 -
              original_area_m2
          ) /
          original_area_m2
      } else {
        NA_real_
      }

      geometry_rows[[geometry_counter]] <- data.frame(
        flight = flight_id,
        date = date_txt,
        growth_stage = growth_stage,
        subplot = subplot,
        perturb_cm = d_cm,
        original_area_m2 = original_area_m2,
        perturbed_area_m2 = perturbed_area_m2,
        area_ratio_to_original =
          perturbed_area_m2 /
          original_area_m2,
        area_change_pct = area_change_pct,
        geometry_empty =
          perturbed_area_m2 <= 0,
        stringsAsFactors = FALSE
      )

      geometry_counter <- geometry_counter + 1

      if (d_cm > 0) {

        overlap_pct_raw <- if (
          is.finite(raw_expanded_area_m2) &&
          raw_expanded_area_m2 > 0
        ) {
          100 *
            overlap_other_area_m2 /
            raw_expanded_area_m2
        } else {
          NA_real_
        }

        crossplot_rows[[crossplot_counter]] <- data.frame(
          flight = flight_id,
          date = date_txt,
          growth_stage = growth_stage,
          subplot = subplot,
          perturb_cm = d_cm,
          raw_expanded_area_m2 =
            raw_expanded_area_m2,
          overlap_with_other_subplot_canopy_m2 =
            overlap_other_area_m2,
          overlap_pct_of_raw_expansion =
            overlap_pct_raw,
          stringsAsFactors = FALSE
        )

        crossplot_counter <- crossplot_counter + 1
      }

      for (idx in indices) {

        r <- rasters[[idx]]

        # For the unperturbed baseline, use the original canopy objects
        # to match Script 01 exactly; duplicate raster cells are removed.
        extraction_geom <- if (
          d_cm == 0
        ) {
          canopy_raw
        } else {
          perturbed_geom
        }

        z <- extract_mean(
          r,
          extraction_geom
        )
        spectral_rows[[spectral_counter]] <- data.frame(
          flight = flight_id,
          date = date_txt,
          growth_stage = growth_stage,
          subplot = subplot,
          index = idx,
          perturb_cm = d_cm,
          mean_index = z$mean_index,
          n_valid_pixels = z$n_valid_pixels,
          raster_res_x_m = res(r)[1],
          raster_res_y_m = res(r)[2],
          stringsAsFactors = FALSE
        )

        spectral_counter <- spectral_counter + 1
      }
    }
  }
}

spectral <- do.call(
  rbind,
  spectral_rows
)

geometry_qa <- do.call(
  rbind,
  geometry_rows
)

crossplot_qa <- do.call(
  rbind,
  crossplot_rows
)

# ------------------------------------------------------------
# 5. CALCULATE CHANGE FROM THE ORIGINAL MASK
# ------------------------------------------------------------

baseline <- spectral[
  spectral$perturb_cm == 0,
  c(
    "flight",
    "growth_stage",
    "subplot",
    "index",
    "mean_index"
  )
]

names(baseline)[5] <- "baseline_mean"

spectral <- merge(
  spectral,
  baseline,
  by = c(
    "flight",
    "growth_stage",
    "subplot",
    "index"
  ),
  all.x = TRUE,
  sort = FALSE
)

spectral$delta_from_baseline <-
  spectral$mean_index -
  spectral$baseline_mean

spectral$pct_change_from_baseline <-
  ifelse(
    abs(spectral$baseline_mean) > 0,
    100 *
      spectral$delta_from_baseline /
      abs(spectral$baseline_mean),
    NA_real_
  )

spectral$abs_pct_change <-
  abs(
    spectral$pct_change_from_baseline
  )

spectral <- spectral[
  order(
    spectral$flight,
    spectral$subplot,
    spectral$index,
    spectral$perturb_cm
  ),
]

# ------------------------------------------------------------
# 6. BASELINE REPRODUCTION QA
# ------------------------------------------------------------

baseline_check <- data.frame()

if (file.exists(reference_file)) {

  reference <- read.csv(
    reference_file,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  reference_subplot_field <- if (
    "subplot" %in% names(reference)
  ) {
    "subplot"
  } else if (
    "plot" %in% names(reference)
  ) {
    "plot"
  } else {
    stop(
      "Reference canopy summary has no subplot/plot field:\n",
      reference_file
    )
  }

  baseline_rows <- spectral[
    spectral$perturb_cm == 0,
  ]

  check_rows <- list()
  check_counter <- 1

  for (idx in indices) {

    reference_column <- paste0(
      idx,
      "_mean"
    )

    if (!reference_column %in% names(reference)) {
      stop(
        "Missing reference column: ",
        reference_column
      )
    }

    ref_idx <- data.frame(
      flight = reference$flight,
      growth_stage = reference$growth_stage,
      subplot = reference[[reference_subplot_field]],
      index = idx,
      reference_mean = reference[[reference_column]],
      stringsAsFactors = FALSE
    )

    obs_idx <- baseline_rows[
      baseline_rows$index == idx,
      c(
        "flight",
        "growth_stage",
        "subplot",
        "index",
        "mean_index"
      )
    ]

    z <- merge(
      obs_idx,
      ref_idx,
      by = c(
        "flight",
        "growth_stage",
        "subplot",
        "index"
      ),
      all.x = TRUE,
      sort = FALSE
    )

    z$difference <-
      z$mean_index -
      z$reference_mean

    z$abs_difference <-
      abs(
        z$difference
      )

    check_rows[[check_counter]] <- z
    check_counter <- check_counter + 1
  }

  baseline_check <- do.call(
    rbind,
    check_rows
  )

  max_difference <- max(
    baseline_check$abs_difference,
    na.rm = TRUE
  )

  if (!is.finite(max_difference)) {
    stop(
      "Baseline reproduction QA could not be evaluated."
    )
  }

  # Internal reproducibility tolerance. This is a pipeline QA rule,
  # not an inferential/statistical threshold.
  baseline_tolerance <- 1e-5

  if (max_difference > baseline_tolerance) {
    stop(
      "Baseline extraction does not reproduce Script 01 within tolerance.\n",
      "Maximum absolute difference = ",
      format(
        max_difference,
        scientific = TRUE
      ),
      "\nTolerance = ",
      baseline_tolerance
    )
  }

} else {

  warning(
    "Reference file not found; baseline reproduction QA was skipped:\n",
    reference_file
  )
}

# ------------------------------------------------------------
# 7. INTEGRITY CHECKS
# ------------------------------------------------------------

expected_spectral_rows <-
  5 *
  5 *
  3 *
  length(perturb_cm)

expected_geometry_rows <-
  5 *
  5 *
  length(perturb_cm)

if (nrow(spectral) != expected_spectral_rows) {
  stop(
    "Unexpected number of spectral rows: ",
    nrow(spectral),
    "; expected ",
    expected_spectral_rows
  )
}

if (nrow(geometry_qa) != expected_geometry_rows) {
  stop(
    "Unexpected number of geometry rows: ",
    nrow(geometry_qa),
    "; expected ",
    expected_geometry_rows
  )
}

if (any(
  geometry_qa$geometry_empty,
  na.rm = TRUE
)) {
  warning(
    "At least one eroded geometry became empty. Inspect boundary_geometry_qa.csv."
  )
}

# ------------------------------------------------------------
# 8. EXPORT
# ------------------------------------------------------------

spectral_file <- file.path(
  derived_root,
  "boundary_perturbation_observations.csv"
)

geometry_file <- file.path(
  derived_root,
  "boundary_geometry_qa.csv"
)

crossplot_file <- file.path(
  derived_root,
  "crossplot_overlap_qa.csv"
)

baseline_file <- file.path(
  derived_root,
  "baseline_reproduction_check.csv"
)

write.csv(
  spectral,
  spectral_file,
  row.names = FALSE,
  quote = FALSE
)

write.csv(
  geometry_qa,
  geometry_file,
  row.names = FALSE,
  quote = FALSE
)

write.csv(
  crossplot_qa,
  crossplot_file,
  row.names = FALSE,
  quote = FALSE
)

if (nrow(baseline_check) > 0) {
  write.csv(
    baseline_check,
    baseline_file,
    row.names = FALSE,
    quote = FALSE
  )
}

# ------------------------------------------------------------
# 9. QA REPORT
# ------------------------------------------------------------

cat("\n")
cat("====================================================\n")
cat("BOUNDARY PERTURBATION COMPLETED\n")
cat("====================================================\n")
cat(
  "Spectral rows: ",
  nrow(spectral),
  "\n",
  sep = ""
)
cat(
  "Geometry QA rows: ",
  nrow(geometry_qa),
  "\n",
  sep = ""
)
cat(
  "Positive-buffer overlap QA rows: ",
  nrow(crossplot_qa),
  "\n",
  sep = ""
)

if (nrow(baseline_check) > 0) {
  cat(
    "Maximum baseline reproduction difference: ",
    format(
      max(
        baseline_check$abs_difference,
        na.rm = TRUE
      ),
      scientific = TRUE
    ),
    "\n",
    sep = ""
  )
}

cat("\nOutputs:\n")
cat(
  spectral_file,
  "\n"
)
cat(
  geometry_file,
  "\n"
)
cat(
  crossplot_file,
  "\n"
)

if (nrow(baseline_check) > 0) {
  cat(
    baseline_file,
    "\n"
  )
}

cat("\n")
cat("Important: perturbations are deterministic mask transformations,\n")
cat("not independent experimental replicates.\n")

# ============================================================
# END
# ============================================================