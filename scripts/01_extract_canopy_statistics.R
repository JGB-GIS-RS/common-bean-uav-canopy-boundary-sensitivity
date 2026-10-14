# ============================================================
# 01_extract_canopy_statistics.R
#
# Purpose
# -------
# Extracts canopy-level statistics from the final UAV spectral-index
# rasters using the consolidated canopy GeoPackage for each flight.
#
# Inputs per flight
# -----------------
#   data/raw/<stage>/ndvi_YYYYMMDD.tif
#   data/raw/<stage>/msavi_YYYYMMDD.tif
#   data/raw/<stage>/wdrvi_YYYYMMDD.tif
#   data/raw/<stage>/canopy_YYYYMMDD.gpkg
#
# Outputs
# -------
#   derived/canopy_statistics_by_subplot_index.csv
#   derived/canopy_summary_by_subplot.csv
#   derived/qa_spatial_extraction.csv
#
# Notes
# -----
# No input file is modified.
# Run from the project root or any subdirectory. Original inputs are never modified.
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

spatial_root <- file.path(
  project_root,
  "data",
  "raw"
)

derived_root <- file.path(
  project_root,
  "derived"
)

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

# ------------------------------------------------------------
# 3. EXTRACTION FUNCTION
# ------------------------------------------------------------

extract_stats <- function(r, v) {

  if (!same.crs(v, r)) {
    v <- project(
      v,
      crs(r)
    )
  }

  canopy_area_m2 <- sum(
    expanse(
      v,
      unit = "m"
    ),
    na.rm = TRUE
  )

  d <- terra::extract(
    r,
    v,
    ID = TRUE,
    cells = TRUE
  )

  value_col <- names(r)[1]

  d <- d[
    is.finite(
      d[[value_col]]
    ),
  ]

  n_duplicate_cells <- sum(
    duplicated(
      d$cell
    )
  )

  d <- d[
    !duplicated(
      d$cell
    ),
  ]

  x <- d[[value_col]]

  if (length(x) == 0) {
    stop(
      "No valid raster cells were extracted."
    )
  }

  pixel_area_m2 <- prod(
    res(r)
  )

  expected_pixels <-
    canopy_area_m2 /
    pixel_area_m2

  coverage_pct <-
    100 *
    length(x) /
    expected_pixels

  n_below_minus1 <- sum(
    x < -1,
    na.rm = TRUE
  )

  n_above_1 <- sum(
    x > 1,
    na.rm = TRUE
  )

  data.frame(
    canopy_area_m2 = canopy_area_m2,
    n_pixels = length(x),
    n_duplicate_cells_removed = n_duplicate_cells,
    coverage_pct = coverage_pct,
    mean = mean(
      x,
      na.rm = TRUE
    ),
    median = median(
      x,
      na.rm = TRUE
    ),
    sd = sd(
      x,
      na.rm = TRUE
    ),
    p05 = as.numeric(
      quantile(
        x,
        0.05,
        na.rm = TRUE
      )
    ),
    p25 = as.numeric(
      quantile(
        x,
        0.25,
        na.rm = TRUE
      )
    ),
    p75 = as.numeric(
      quantile(
        x,
        0.75,
        na.rm = TRUE
      )
    ),
    p95 = as.numeric(
      quantile(
        x,
        0.95,
        na.rm = TRUE
      )
    ),
    p99 = as.numeric(
      quantile(
        x,
        0.99,
        na.rm = TRUE
      )
    ),
    min = min(
      x,
      na.rm = TRUE
    ),
    max = max(
      x,
      na.rm = TRUE
    ),
    n_below_minus1 = n_below_minus1,
    n_above_1 = n_above_1,
    pct_outside_minus1_1 =
      100 *
      (n_below_minus1 + n_above_1) /
      length(x)
  )
}

# ------------------------------------------------------------
# 4. PROCESS ALL FLIGHTS
# ------------------------------------------------------------

results <- list()
qa_rows <- list()

k <- 1
q <- 1

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

  gpkg_file <- file.path(
    flight_dir,
    paste0(
      "canopy_",
      file_date,
      ".gpkg"
    )
  )

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

  if (!file.exists(gpkg_file)) {
    stop(
      "Missing GeoPackage:\n",
      gpkg_file
    )
  }

  rasters <- lapply(
    raster_files,
    rast
  )

  for (idx in names(rasters)) {
    names(
      rasters[[idx]]
    ) <- idx
  }

  canopy_all <- vect(
    gpkg_file,
    layer = "canopy"
  )

  required_fields <- c(
    "flight",
    "date",
    "growth_stage",
    "subplot",
    "N_rate_kg_ha",
    "canopy_object_id"
  )

  if (!all(
    required_fields %in%
      names(canopy_all)
  )) {
    stop(
      "GeoPackage is missing one or more required fields:\n",
      gpkg_file
    )
  }

  subplots <- c(
    "P1",
    "P2",
    "P3",
    "P4",
    "P5"
  )

  for (subplot in subplots) {

    canopy <- canopy_all[
      canopy_all$subplot == subplot,
    ]

    if (nrow(canopy) == 0) {
      stop(
        "No canopy polygons found for ",
        subplot,
        " in ",
        basename(
          gpkg_file
        )
      )
    }

    N_rate_value <- unique(
      canopy$N_rate_kg_ha
    )

    if (length(N_rate_value) != 1) {
      stop(
        "Multiple N rates detected for ",
        subplot,
        " in ",
        basename(
          gpkg_file
        )
      )
    }

    n_canopy_objects <- nrow(
      canopy
    )

    subplot_results <- list()

    for (idx in names(rasters)) {

      z <- extract_stats(
        rasters[[idx]],
        canopy
      )

      row <- cbind(
        data.frame(
          flight = flight_id,
          date = date_txt,
          growth_stage = growth_stage,
          subplot = subplot,
          N_rate_kg_ha = as.numeric(
            N_rate_value
          ),
          index = idx,
          canopy_polygon_count =
            n_canopy_objects,
          stringsAsFactors = FALSE
        ),
        z
      )

      results[[k]] <- row
      subplot_results[[idx]] <- row
      k <- k + 1
    }

    area_values <- sapply(
      subplot_results,
      function(z) {
        z$canopy_area_m2
      }
    )

    coverage_values <- sapply(
      subplot_results,
      function(z) {
        z$coverage_pct
      }
    )

    outside_values <- sapply(
      subplot_results,
      function(z) {
        z$pct_outside_minus1_1
      }
    )

    qa_rows[[q]] <- data.frame(
      flight = flight_id,
      date = date_txt,
      growth_stage = growth_stage,
      subplot = subplot,
      N_rate_kg_ha = as.numeric(
        N_rate_value
      ),
      canopy_polygon_count =
        n_canopy_objects,
      canopy_area_m2 = mean(
        area_values
      ),
      canopy_area_range_m2 =
        max(area_values) -
        min(area_values),
      minimum_coverage_pct = min(
        coverage_values
      ),
      maximum_coverage_pct = max(
        coverage_values
      ),
      maximum_pct_outside_minus1_1 = max(
        outside_values
      ),
      stringsAsFactors = FALSE
    )

    q <- q + 1
  }
}

# ------------------------------------------------------------
# 5. CONSOLIDATE LONG TABLE
# ------------------------------------------------------------

long_table <- do.call(
  rbind,
  results
)

qa_table <- do.call(
  rbind,
  qa_rows
)

# ------------------------------------------------------------
# 6. BUILD 25-ROW SUMMARY
# ------------------------------------------------------------

pick_index <- function(index_name) {

  z <- long_table[
    long_table$index == index_name,
  ]

  z[
    order(
      z$flight,
      z$N_rate_kg_ha
    ),
  ]
}

ndvi <- pick_index(
  "NDVI"
)

msavi <- pick_index(
  "MSAVI"
)

wdrvi <- pick_index(
  "WDRVI"
)

summary_25 <- data.frame(
  flight = ndvi$flight,
  date = ndvi$date,
  growth_stage = ndvi$growth_stage,
  subplot = ndvi$subplot,
  N_rate_kg_ha = ndvi$N_rate_kg_ha,
  canopy_area_m2 = ndvi$canopy_area_m2,
  canopy_polygon_count =
    ndvi$canopy_polygon_count,

  NDVI_mean = ndvi$mean,
  NDVI_median = ndvi$median,
  NDVI_sd = ndvi$sd,

  MSAVI_mean = msavi$mean,
  MSAVI_median = msavi$median,
  MSAVI_sd = msavi$sd,

  WDRVI_mean = wdrvi$mean,
  WDRVI_median = wdrvi$median,
  WDRVI_sd = wdrvi$sd,

  stringsAsFactors = FALSE
)

# ------------------------------------------------------------
# 7. AUTOMATIC QA
# ------------------------------------------------------------

if (nrow(long_table) != 75) {
  stop(
    "Expected 75 rows in long table; found ",
    nrow(long_table)
  )
}

if (nrow(summary_25) != 25) {
  stop(
    "Expected 25 rows in summary table; found ",
    nrow(summary_25)
  )
}

if (nrow(qa_table) != 25) {
  stop(
    "Expected 25 rows in QA table; found ",
    nrow(qa_table)
  )
}

if (
  any(!is.finite(
    summary_25$NDVI_mean
  )) ||
  any(!is.finite(
    summary_25$MSAVI_mean
  )) ||
  any(!is.finite(
    summary_25$WDRVI_mean
  ))
) {
  stop(
    "Non-finite spectral means detected."
  )
}

# ------------------------------------------------------------
# 8. SAVE OUTPUTS
# ------------------------------------------------------------

write.csv(
  long_table,
  file.path(
    derived_root,
    "canopy_statistics_by_subplot_index.csv"
  ),
  row.names = FALSE
)

write.csv(
  summary_25,
  file.path(
    derived_root,
    "canopy_summary_by_subplot.csv"
  ),
  row.names = FALSE
)

write.csv(
  qa_table,
  file.path(
    derived_root,
    "qa_spatial_extraction.csv"
  ),
  row.names = FALSE
)

# ------------------------------------------------------------
# 9. CONSOLE SUMMARY
# ------------------------------------------------------------

cat("\n")
cat("====================================================\n")
cat("CANOPY EXTRACTION COMPLETED\n")
cat("====================================================\n\n")

cat(
  "Long table rows: ",
  nrow(long_table),
  "\n",
  sep = ""
)

cat(
  "Summary rows:    ",
  nrow(summary_25),
  "\n",
  sep = ""
)

cat(
  "QA rows:         ",
  nrow(qa_table),
  "\n",
  sep = ""
)

cat("\nMinimum coverage by flight:\n")

print(
  aggregate(
    minimum_coverage_pct ~
      flight +
      date +
      growth_stage,
    data = qa_table,
    FUN = min
  ),
  row.names = FALSE
)

cat("\nMean values by flight:\n")

flight_means <- aggregate(
  cbind(
    NDVI_mean,
    MSAVI_mean,
    WDRVI_mean,
    canopy_area_m2
  ) ~
    flight +
    date +
    growth_stage,
  data = summary_25,
  FUN = mean
)

print(
  flight_means,
  row.names = FALSE
)

cat("\nOutputs written to:\n")
cat(
  derived_root,
  "\n\n"
)

cat(
  "No input raster or vector file was modified.\n"
)

# ============================================================
# END
# ============================================================
