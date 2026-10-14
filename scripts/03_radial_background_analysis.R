# ============================================================
# 10_radial_background_analysis.R
#
# Purpose
# -------
# Characterizes the spectral transition immediately outside the
# segmented canopy using four independent non-canopy rings:
#
#   0-5 cm
#   5-10 cm
#   10-15 cm
#   15-20 cm
#
# All segmented canopy from P1-P5 is removed from every ring.
# No reconstructed physical plot boundary is assumed.
#
# Inputs per flight
# -----------------
#   data/raw/<stage>/canopy_YYYYMMDD.gpkg
#   data/raw/<stage>/ndvi_YYYYMMDD.tif
#   data/raw/<stage>/msavi_YYYYMMDD.tif
#   data/raw/<stage>/wdrvi_YYYYMMDD.tif
#
# Outputs
# -------
#   derived/radial_background/
#     radial_ring_observations.csv
#     radial_ring_summary.csv
#     radial_gradient_by_plot.csv
#     radial_gradient_summary.csv
#
# Notes
# -----
# Rings are mechanistic/descriptive spatial diagnostics. They are
# not independent biological replicates.
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

    has_data <- dir.exists(
      file.path(
        current,
        "data",
        "raw"
      )
    )

    has_scripts <- dir.exists(
      file.path(
        current,
        "scripts"
      )
    )

    if (has_data && has_scripts) {
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
    "\nExpected a parent directory containing both data/raw and scripts."
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
  "raw"
)

derived_root <- file.path(
  project_root,
  "derived",
  "radial_background"
)

if (!dir.exists(spatial_root)) {
  stop(
    "Directory not found: ",
    spatial_root
  )
}

if (!dir.exists(derived_root)) {
  dir.create(
    derived_root,
    recursive = TRUE
  )
}

# ------------------------------------------------------------
# 2. METADATA
# ------------------------------------------------------------

flights <- data.frame(
  flight = 1:5,
  folder = c(
    "V4",
    "R5",
    "R6",
    "R7",
    "R8"
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

rings <- data.frame(
  ring_inner_cm = c(
    0,
    5,
    10,
    15
  ),
  ring_outer_cm = c(
    5,
    10,
    15,
    20
  ),
  ring_mid_cm = c(
    2.5,
    7.5,
    12.5,
    17.5
  ),
  stringsAsFactors = FALSE
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

  sum(
    terra::expanse(
      v,
      unit = "m",
      transform = FALSE
    ),
    na.rm = TRUE
  )
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

make_noncanopy_ring <- function(
  canopy_union,
  all_canopy_union,
  inner_cm,
  outer_cm
) {

  outer_buffer <- terra::buffer(
    canopy_union,
    width = outer_cm / 100
  )

  if (inner_cm == 0) {

    ring_geom <- terra::erase(
      outer_buffer,
      all_canopy_union
    )

  } else {

    inner_buffer <- terra::buffer(
      canopy_union,
      width = inner_cm / 100
    )

    annulus <- terra::erase(
      outer_buffer,
      inner_buffer
    )

    ring_geom <- terra::erase(
      annulus,
      all_canopy_union
    )
  }

  ring_geom
}

# ------------------------------------------------------------
# 4. EXTRACT RING VALUES
# ------------------------------------------------------------

observation_rows <- list()
counter <- 1

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

  if (any(!file.exists(raster_files))) {
    stop(
      "One or more rasters are missing for ",
      growth_stage
    )
  }

  cat("\n")
  cat("====================================================\n")
  cat(
    "RADIAL BACKGROUND | ",
    growth_stage,
    " | ",
    date_txt,
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
      "Missing subplot/plot field in:\n",
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

    canopy_union <- dissolve_vector(
      canopy_raw
    )

    for (j in seq_len(nrow(rings))) {

      inner_cm <- rings$ring_inner_cm[j]
      outer_cm <- rings$ring_outer_cm[j]
      midpoint_cm <- rings$ring_mid_cm[j]

      ring_geom <- make_noncanopy_ring(
        canopy_union = canopy_union,
        all_canopy_union = all_canopy_union,
        inner_cm = inner_cm,
        outer_cm = outer_cm
      )

      ring_area_m2 <- vector_area_m2(
        ring_geom
      )

      if (ring_area_m2 <= 0) {
        stop(
          "Empty radial ring for ",
          growth_stage,
          " ",
          subplot,
          " ",
          inner_cm,
          "-",
          outer_cm,
          " cm"
        )
      }

      for (idx in indices) {

        r <- rasters[[idx]]

        canopy_stats <- extract_mean(
          r,
          canopy_raw
        )

        ring_stats <- extract_mean(
          r,
          ring_geom
        )

        pixel_area_m2 <- prod(
          res(r)
        )

        expected_ring_pixels <-
          ring_area_m2 /
          pixel_area_m2

        ring_support_pct <- if (
          expected_ring_pixels > 0
        ) {
          100 *
            ring_stats$n_valid_pixels /
            expected_ring_pixels
        } else {
          NA_real_
        }

        relative_contrast_pct <- if (
          is.finite(canopy_stats$mean_index) &&
          abs(canopy_stats$mean_index) > 0
        ) {
          100 *
            (
              ring_stats$mean_index -
                canopy_stats$mean_index
            ) /
            abs(canopy_stats$mean_index)
        } else {
          NA_real_
        }

        observation_rows[[counter]] <- data.frame(
          flight = flight_id,
          date = date_txt,
          growth_stage = growth_stage,
          subplot = subplot,
          index = idx,
          ring_inner_cm = inner_cm,
          ring_outer_cm = outer_cm,
          ring_mid_cm = midpoint_cm,
          ring_area_m2 = ring_area_m2,
          canopy_mean = canopy_stats$mean_index,
          ring_mean = ring_stats$mean_index,
          ring_minus_canopy =
            ring_stats$mean_index -
            canopy_stats$mean_index,
          ring_relative_to_canopy_pct =
            relative_contrast_pct,
          ring_valid_pixels =
            ring_stats$n_valid_pixels,
          raster_pixel_area_m2 =
            pixel_area_m2,
          ring_support_pct_raw =
            ring_support_pct,
          stringsAsFactors = FALSE
        )

        counter <- counter + 1
      }
    }
  }
}

observations <- do.call(
  rbind,
  observation_rows
)

expected_rows <-
  5 *
  5 *
  3 *
  4

if (nrow(observations) != expected_rows) {
  stop(
    "Unexpected number of radial observations: ",
    nrow(observations),
    "; expected ",
    expected_rows
  )
}

# ------------------------------------------------------------
# 5. STAGE × INDEX × RING SUMMARY
# ------------------------------------------------------------

group_keys <- unique(
  observations[
    ,
    c(
      "growth_stage",
      "index",
      "ring_inner_cm",
      "ring_outer_cm",
      "ring_mid_cm"
    )
  ]
)

summary_rows <- list()

for (i in seq_len(nrow(group_keys))) {

  key <- group_keys[i, ]

  z <- observations[
    observations$growth_stage == key$growth_stage &
      observations$index == key$index &
      observations$ring_inner_cm == key$ring_inner_cm &
      observations$ring_outer_cm == key$ring_outer_cm,
  ]

  summary_rows[[i]] <- data.frame(
    growth_stage = key$growth_stage,
    index = key$index,
    ring_inner_cm = key$ring_inner_cm,
    ring_outer_cm = key$ring_outer_cm,
    ring_mid_cm = key$ring_mid_cm,
    n_subplots = length(
      unique(z$subplot)
    ),
    mean_ring_value = mean(
      z$ring_mean,
      na.rm = TRUE
    ),
    sd_ring_value = sd(
      z$ring_mean,
      na.rm = TRUE
    ),
    median_ring_value = median(
      z$ring_mean,
      na.rm = TRUE
    ),
    mean_canopy_value = mean(
      z$canopy_mean,
      na.rm = TRUE
    ),
    mean_relative_contrast_pct = mean(
      z$ring_relative_to_canopy_pct,
      na.rm = TRUE
    ),
    mean_ring_support_pct_raw = mean(
      z$ring_support_pct_raw,
      na.rm = TRUE
    ),
    min_ring_support_pct_raw = min(
      z$ring_support_pct_raw,
      na.rm = TRUE
    ),
    stringsAsFactors = FALSE
  )
}

ring_summary <- do.call(
  rbind,
  summary_rows
)

# ------------------------------------------------------------
# 6. RADIAL GRADIENT BY PLOT × STAGE × INDEX
# ------------------------------------------------------------

gradient_keys <- unique(
  observations[
    ,
    c(
      "flight",
      "growth_stage",
      "subplot",
      "index"
    )
  ]
)

gradient_rows <- list()

for (i in seq_len(nrow(gradient_keys))) {

  key <- gradient_keys[i, ]

  z <- observations[
    observations$flight == key$flight &
      observations$growth_stage == key$growth_stage &
      observations$subplot == key$subplot &
      observations$index == key$index,
  ]

  z <- z[
    order(
      z$ring_mid_cm
    ),
  ]

  fit <- lm(
    ring_mean ~ ring_mid_cm,
    data = z
  )

  fit_summary <- summary(
    fit
  )

  gradient_rows[[i]] <- data.frame(
    flight = key$flight,
    growth_stage = key$growth_stage,
    subplot = key$subplot,
    index = key$index,
    radial_slope_index_units_per_cm =
      unname(
        coef(fit)[
          "ring_mid_cm"
        ]
      ),
    radial_intercept =
      unname(
        coef(fit)[
          "(Intercept)"
        ]
      ),
    radial_r2 =
      fit_summary$r.squared,
    strictly_monotonic_decrease =
      all(
        diff(
          z$ring_mean
        ) <= 0
      ),
    inner_ring_0_5_mean =
      z$ring_mean[
        z$ring_inner_cm == 0
      ],
    outer_ring_15_20_mean =
      z$ring_mean[
        z$ring_inner_cm == 15
      ],
    outer_minus_inner =
      z$ring_mean[
        z$ring_inner_cm == 15
      ] -
      z$ring_mean[
        z$ring_inner_cm == 0
      ],
    stringsAsFactors = FALSE
  )
}

gradients <- do.call(
  rbind,
  gradient_rows
)

gradient_summary_keys <- unique(
  gradients[
    ,
    c(
      "growth_stage",
      "index"
    )
  ]
)

gradient_summary_rows <- list()

for (i in seq_len(nrow(gradient_summary_keys))) {

  key <- gradient_summary_keys[i, ]

  z <- gradients[
    gradients$growth_stage == key$growth_stage &
      gradients$index == key$index,
  ]

  gradient_summary_rows[[i]] <- data.frame(
    growth_stage = key$growth_stage,
    index = key$index,
    n_subplots = nrow(z),
    mean_radial_slope = mean(
      z$radial_slope_index_units_per_cm,
      na.rm = TRUE
    ),
    sd_radial_slope = sd(
      z$radial_slope_index_units_per_cm,
      na.rm = TRUE
    ),
    median_radial_slope = median(
      z$radial_slope_index_units_per_cm,
      na.rm = TRUE
    ),
    mean_radial_r2 = mean(
      z$radial_r2,
      na.rm = TRUE
    ),
    plots_strictly_monotonic =
      sum(
        z$strictly_monotonic_decrease,
        na.rm = TRUE
      ),
    plots_outer_lower_than_inner =
      sum(
        z$outer_minus_inner < 0,
        na.rm = TRUE
      ),
    stringsAsFactors = FALSE
  )
}

gradient_summary <- do.call(
  rbind,
  gradient_summary_rows
)

# ------------------------------------------------------------
# 7. EXPORT
# ------------------------------------------------------------

observations_file <- file.path(
  derived_root,
  "radial_ring_observations.csv"
)

summary_file <- file.path(
  derived_root,
  "radial_ring_summary.csv"
)

gradient_file <- file.path(
  derived_root,
  "radial_gradient_by_plot.csv"
)

gradient_summary_file <- file.path(
  derived_root,
  "radial_gradient_summary.csv"
)

write.csv(
  observations,
  observations_file,
  row.names = FALSE,
  quote = FALSE
)

write.csv(
  ring_summary,
  summary_file,
  row.names = FALSE,
  quote = FALSE
)

write.csv(
  gradients,
  gradient_file,
  row.names = FALSE,
  quote = FALSE
)

write.csv(
  gradient_summary,
  gradient_summary_file,
  row.names = FALSE,
  quote = FALSE
)

# ------------------------------------------------------------
# 8. QA REPORT
# ------------------------------------------------------------

cat("\n")
cat("====================================================\n")
cat("RADIAL BACKGROUND ANALYSIS COMPLETED\n")
cat("====================================================\n")
cat(
  "Observations: ",
  nrow(observations),
  "\n",
  sep = ""
)
cat(
  "Plot × stage × index gradients: ",
  nrow(gradients),
  "\n",
  sep = ""
)
cat(
  "Strictly monotonic profiles: ",
  sum(
    gradients$strictly_monotonic_decrease,
    na.rm = TRUE
  ),
  "/",
  nrow(gradients),
  "\n",
  sep = ""
)
cat(
  "Outer ring lower than inner ring: ",
  sum(
    gradients$outer_minus_inner < 0,
    na.rm = TRUE
  ),
  "/",
  nrow(gradients),
  "\n",
  sep = ""
)
cat("\nOutputs:\n")
cat(
  observations_file,
  "\n"
)
cat(
  summary_file,
  "\n"
)
cat(
  gradient_file,
  "\n"
)
cat(
  gradient_summary_file,
  "\n"
)

# ============================================================
# END
# ============================================================
