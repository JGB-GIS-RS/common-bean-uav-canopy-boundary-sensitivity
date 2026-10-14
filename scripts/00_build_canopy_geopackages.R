# ============================================================
# 00_build_canopy_geopackages.R
#
# Purpose
# -------
# Consolidates the P1-P5 segmented-canopy shapefiles into one
# GeoPackage for each UAV flight and validates the exported geometry.
#
# Inputs
# ------
#   data/spatial/flightXX/plantas_p*_YYYYMMDD.shp
#
# Outputs
# -------
#   data/spatial/flightXX/canopy_YYYYMMDD.gpkg
#   derived/qa_canopy_geopackages.csv
#
# Notes
# -----
# Source shapefiles are not modified or deleted.
# Expected working directory: repository root.
# ============================================================

rm(list = ls())
gc()

library(terra)

# ------------------------------------------------------------
# 1. PROJECT ROOT
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

spatial_root <- file.path(
  project_root,
  "data",
  "spatial"
)

derived_root <- file.path(
  project_root,
  "derived"
)

if (!dir.exists(spatial_root)) {
  stop(
    "Directory not found: ",
    spatial_root,
    "\n\nExpected local spatial inputs under data/spatial/."
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

N_rate <- c(
  P1 = 0,
  P2 = 100,
  P3 = 200,
  P4 = 300,
  P5 = 400
)

# ------------------------------------------------------------
# 3. QA CONTAINER
# ------------------------------------------------------------

validation_rows <- list()
counter <- 1

# ------------------------------------------------------------
# 4. PROCESS EACH FLIGHT
# ------------------------------------------------------------

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

  if (!dir.exists(flight_dir)) {
    stop(
      "Flight directory not found: ",
      flight_dir
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

  # ----------------------------------------------------------
  # 4.1 READ P1-P5
  # ----------------------------------------------------------

  plot_vectors <- list()
  reference_crs <- NULL

  for (p in 1:5) {

    plot <- paste0("P", p)

    shp <- file.path(
      flight_dir,
      paste0(
        "plantas_p",
        p,
        "_",
        file_date,
        ".shp"
      )
    )

    if (!file.exists(shp)) {
      stop(
        "Missing shapefile:\n",
        shp
      )
    }

    v <- vect(shp)

    if (nrow(v) == 0) {
      stop(
        "Empty shapefile:\n",
        shp
      )
    }

    # Use the CRS of the first plot as the reference CRS.
    if (is.null(reference_crs)) {
      reference_crs <- crs(v)
    } else if (!same.crs(v, reference_crs)) {
      v <- project(
        v,
        reference_crs
      )
    }

    n_objects <- nrow(v)

    # Replace source attributes with a clean publication-ready table.
    values(v) <- data.frame(
      flight = rep(
        flight_id,
        n_objects
      ),
      date = rep(
        date_txt,
        n_objects
      ),
      growth_stage = rep(
        growth_stage,
        n_objects
      ),
      plot = rep(
        plot,
        n_objects
      ),
      N_rate_kg_ha = rep(
        as.numeric(
          N_rate[plot]
        ),
        n_objects
      ),
      canopy_object_id = seq_len(
        n_objects
      ),
      stringsAsFactors = FALSE
    )

    plot_vectors[[plot]] <- v

    cat(
      plot,
      ": ",
      n_objects,
      " canopy object(s)\n",
      sep = ""
    )
  }

  # ----------------------------------------------------------
  # 4.2 COMBINE P1-P5
  # ----------------------------------------------------------
  #
  # Reduce() is used instead of do.call(rbind, ...)
  # because it dispatches terra's SpatVector rbind method
  # reliably in this context.
  # ----------------------------------------------------------

  canopy_all <- Reduce(
    function(x, y) {
      rbind(x, y)
    },
    plot_vectors
  )

  # ----------------------------------------------------------
  # 4.3 WRITE GEOPACKAGE
  # ----------------------------------------------------------

  gpkg_file <- file.path(
    flight_dir,
    paste0(
      "canopy_",
      file_date,
      ".gpkg"
    )
  )

  if (file.exists(gpkg_file)) {
    file.remove(gpkg_file)
  }

  writeVector(
    canopy_all,
    gpkg_file,
    filetype = "GPKG",
    layer = "canopy",
    overwrite = TRUE
  )

  # ----------------------------------------------------------
  # 4.4 READ BACK FOR VALIDATION
  # ----------------------------------------------------------

  canopy_check <- vect(
    gpkg_file,
    layer = "canopy"
  )

  if (nrow(canopy_check) != nrow(canopy_all)) {
    stop(
      "Feature count changed after GeoPackage export."
    )
  }

  if (!same.crs(canopy_check, canopy_all)) {
    stop(
      "CRS changed after GeoPackage export."
    )
  }

  # ----------------------------------------------------------
  # 4.5 VALIDATE EACH PLOT
  # ----------------------------------------------------------

  for (plot in names(plot_vectors)) {

    original <- plot_vectors[[plot]]

    exported <- canopy_check[
      canopy_check$plot == plot,
    ]

    original_area <- sum(
      expanse(
        original,
        unit = "m"
      ),
      na.rm = TRUE
    )

    exported_area <- sum(
      expanse(
        exported,
        unit = "m"
      ),
      na.rm = TRUE
    )

    area_difference <-
      exported_area -
      original_area

    validation_rows[[counter]] <- data.frame(
      flight = flight_id,
      date = date_txt,
      growth_stage = growth_stage,
      plot = plot,
      N_rate_kg_ha = as.numeric(
        N_rate[plot]
      ),
      source_polygon_count = nrow(
        original
      ),
      gpkg_polygon_count = nrow(
        exported
      ),
      source_area_m2 = original_area,
      gpkg_area_m2 = exported_area,
      area_difference_m2 = area_difference,
      stringsAsFactors = FALSE
    )

    counter <- counter + 1
  }

  cat(
    "\nCreated: ",
    basename(gpkg_file),
    "\n",
    sep = ""
  )

  cat(
    "Total polygons: ",
    nrow(canopy_check),
    "\n",
    sep = ""
  )
}

# ------------------------------------------------------------
# 5. CONSOLIDATE VALIDATION
# ------------------------------------------------------------

validation <- do.call(
  rbind,
  validation_rows
)

validation$polygon_count_ok <-
  validation$source_polygon_count ==
  validation$gpkg_polygon_count

# A micrometre-scale area tolerance is more than sufficient
# for checking geometry preservation in this dataset.
validation$area_ok <-
  abs(
    validation$area_difference_m2
  ) < 1e-6

# ------------------------------------------------------------
# 6. FINAL QA
# ------------------------------------------------------------

all_ok <- all(
  validation$polygon_count_ok &
  validation$area_ok
)

cat("\n")
cat("====================================================\n")
cat("GEOPACKAGE VALIDATION\n")
cat("====================================================\n\n")

print(
  validation,
  row.names = FALSE
)

cat("\n")

if (all_ok) {
  cat(
    "RESULT: ALL GEOPACKAGES PASSED VALIDATION\n"
  )
} else {
  cat(
    "RESULT: REVIEW REQUIRED\n"
  )
}

cat("\n")

# ------------------------------------------------------------
# 7. SAVE QA TABLE
# ------------------------------------------------------------

qa_file <- file.path(
  derived_root,
  "qa_canopy_geopackages.csv"
)

write.csv(
  validation,
  qa_file,
  row.names = FALSE
)

cat(
  "QA table written to:\n",
  qa_file,
  "\n",
  sep = ""
)

cat("\n")
cat(
  "Source shapefiles were NOT modified or deleted.\n"
)

# ============================================================
# END
# ============================================================