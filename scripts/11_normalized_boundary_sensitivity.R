# ============================================================
# 11_normalized_boundary_sensitivity.R
#
# Purpose
# -------
# Converts centimetre-based canopy-boundary perturbations into a
# normalized sensitivity metric that accounts for the actual relative
# change in segmented-mask area.
#
# Definitions
# -----------
#   DeltaA(%) =
#     100 * (A_d - A_0) / A_0
#
#   DeltaVI(%) =
#     100 * (VI_d - VI_0) / |VI_0|
#
# For each subplot × growth stage × vegetation index:
#
#   DeltaVI = beta * DeltaA
#
# The regression is constrained through the origin because the
# unperturbed mask has DeltaA = DeltaVI = 0 by definition.
#
# Supporting combined sensitivity metric:
#   |beta| = % VI change per 1% mask-area change
#
# The primary manuscript metrics are the direction-specific
# |beta_erosion| and |beta_dilation| estimates generated in Script 12.
#
# Inputs
# ------
#   derived/boundary_sensitivity/
#     boundary_perturbation_observations.csv
#     boundary_geometry_qa.csv
#
# Outputs
# -------
#   derived/boundary_sensitivity/
#     normalized_boundary_sensitivity_by_plot.csv
#     normalized_boundary_sensitivity_summary.csv
#     normalized_boundary_response_observations.csv
#
# Notes
# -----
# Perturbation levels are not independent replicates.
# The five subplots are the independent spatial observational units.
# ============================================================

rm(list = ls())
gc()

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

derived_root <- file.path(
  project_root,
  "derived",
  "boundary_sensitivity"
)

spectral_file <- file.path(
  derived_root,
  "boundary_perturbation_observations.csv"
)

geometry_file <- file.path(
  derived_root,
  "boundary_geometry_qa.csv"
)

if (!file.exists(spectral_file)) {
  stop(
    "Missing file:\n",
    spectral_file,
    "\nRun scripts/09_boundary_perturbation.R first."
  )
}

if (!file.exists(geometry_file)) {
  stop(
    "Missing file:\n",
    geometry_file,
    "\nRun scripts/09_boundary_perturbation.R first."
  )
}

# ------------------------------------------------------------
# 2. READ AND MERGE
# ------------------------------------------------------------

spectral <- read.csv(
  spectral_file,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

geometry <- read.csv(
  geometry_file,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

required_spectral <- c(
  "flight",
  "growth_stage",
  "subplot",
  "index",
  "perturb_cm",
  "mean_index",
  "baseline_mean",
  "pct_change_from_baseline"
)

required_geometry <- c(
  "flight",
  "growth_stage",
  "subplot",
  "perturb_cm",
  "original_area_m2",
  "perturbed_area_m2",
  "area_change_pct"
)

if (!all(
  required_spectral %in%
    names(spectral)
)) {
  stop(
    "Spectral table is missing required columns."
  )
}

if (!all(
  required_geometry %in%
    names(geometry)
)) {
  stop(
    "Geometry table is missing required columns."
  )
}

d <- merge(
  spectral,
  geometry[
    ,
    required_geometry
  ],
  by = c(
    "flight",
    "growth_stage",
    "subplot",
    "perturb_cm"
  ),
  all.x = TRUE,
  sort = FALSE
)

d$delta_mask_area_pct <-
  d$area_change_pct

d$delta_index_pct <-
  d$pct_change_from_baseline

d <- d[
  order(
    d$flight,
    d$subplot,
    d$index,
    d$perturb_cm
  ),
]

# ------------------------------------------------------------
# 3. HELPER: THROUGH-ORIGIN SLOPE
# ------------------------------------------------------------

fit_origin <- function(x, y) {

  ok <-
    is.finite(x) &
    is.finite(y)

  x <- x[ok]
  y <- y[ok]

  if (
    length(x) < 2 ||
    sum(x^2) == 0
  ) {
    return(
      c(
        beta = NA_real_,
        r2_origin = NA_real_
      )
    )
  }

  beta <-
    sum(
      x * y
    ) /
    sum(
      x^2
    )

  predicted <-
    beta *
    x

  sse <- sum(
    (
      y -
        predicted
    )^2
  )

  sst_origin <- sum(
    y^2
  )

  r2_origin <- if (
    sst_origin > 0
  ) {
    1 -
      sse /
      sst_origin
  } else {
    NA_real_
  }

  c(
    beta = beta,
    r2_origin = r2_origin
  )
}

# ------------------------------------------------------------
# 4. ESTIMATE BETA BY SUBPLOT × STAGE × INDEX
# ------------------------------------------------------------

analysis_data <- d[
  d$perturb_cm != 0,
]

keys <- unique(
  analysis_data[
    ,
    c(
      "flight",
      "growth_stage",
      "subplot",
      "index"
    )
  ]
)

beta_rows <- list()

for (i in seq_len(nrow(keys))) {

  key <- keys[i, ]

  z <- analysis_data[
    analysis_data$flight == key$flight &
      analysis_data$growth_stage == key$growth_stage &
      analysis_data$subplot == key$subplot &
      analysis_data$index == key$index,
  ]

  fit_all <- fit_origin(
    x = z$delta_mask_area_pct,
    y = z$delta_index_pct
  )

  z12 <- z[
    abs(
      z$perturb_cm
    ) <= 2,
  ]

  fit_12 <- fit_origin(
    x = z12$delta_mask_area_pct,
    y = z12$delta_index_pct
  )

  beta_rows[[i]] <- data.frame(
    flight = key$flight,
    growth_stage = key$growth_stage,
    subplot = key$subplot,
    index = key$index,
    beta_pctVI_per_pctMaskArea =
      unname(
        fit_all["beta"]
      ),
    absolute_beta =
      abs(
        unname(
          fit_all["beta"]
        )
      ),
    r2_origin_all_1to3cm =
      unname(
        fit_all["r2_origin"]
      ),
    beta_using_1to2cm =
      unname(
        fit_12["beta"]
      ),
    absolute_beta_using_1to2cm =
      abs(
        unname(
          fit_12["beta"]
        )
      ),
    r2_origin_1to2cm =
      unname(
        fit_12["r2_origin"]
      ),
    stringsAsFactors = FALSE
  )
}

betas <- do.call(
  rbind,
  beta_rows
)

if (nrow(betas) != 75) {
  stop(
    "Expected 75 subplot × stage × index beta estimates; found ",
    nrow(betas)
  )
}

# ------------------------------------------------------------
# 5. STAGE × INDEX DESCRIPTIVE SUMMARY
# ------------------------------------------------------------

summary_keys <- unique(
  betas[
    ,
    c(
      "growth_stage",
      "index"
    )
  ]
)

summary_rows <- list()

for (i in seq_len(nrow(summary_keys))) {

  key <- summary_keys[i, ]

  z <- betas[
    betas$growth_stage == key$growth_stage &
      betas$index == key$index,
  ]

  summary_rows[[i]] <- data.frame(
    growth_stage = key$growth_stage,
    index = key$index,
    n_subplots = nrow(z),
    mean_abs_beta = mean(
      z$absolute_beta,
      na.rm = TRUE
    ),
    sd_abs_beta = sd(
      z$absolute_beta,
      na.rm = TRUE
    ),
    median_abs_beta = median(
      z$absolute_beta,
      na.rm = TRUE
    ),
    q25_abs_beta = as.numeric(
      quantile(
        z$absolute_beta,
        0.25,
        na.rm = TRUE
      )
    ),
    q75_abs_beta = as.numeric(
      quantile(
        z$absolute_beta,
        0.75,
        na.rm = TRUE
      )
    ),
    min_abs_beta = min(
      z$absolute_beta,
      na.rm = TRUE
    ),
    max_abs_beta = max(
      z$absolute_beta,
      na.rm = TRUE
    ),
    mean_r2_origin = mean(
      z$r2_origin_all_1to3cm,
      na.rm = TRUE
    ),
    mean_abs_beta_1to2cm = mean(
      z$absolute_beta_using_1to2cm,
      na.rm = TRUE
    ),
    stringsAsFactors = FALSE
  )
}

beta_summary <- do.call(
  rbind,
  summary_rows
)

# ------------------------------------------------------------
# 6. EXPORT
# ------------------------------------------------------------

response_file <- file.path(
  derived_root,
  "normalized_boundary_response_observations.csv"
)

beta_file <- file.path(
  derived_root,
  "normalized_boundary_sensitivity_by_plot.csv"
)

summary_file <- file.path(
  derived_root,
  "normalized_boundary_sensitivity_summary.csv"
)

write.csv(
  d,
  response_file,
  row.names = FALSE,
  quote = FALSE
)

write.csv(
  betas,
  beta_file,
  row.names = FALSE,
  quote = FALSE
)

write.csv(
  beta_summary,
  summary_file,
  row.names = FALSE,
  quote = FALSE
)

# ------------------------------------------------------------
# 7. REPORT
# ------------------------------------------------------------

cat("\n")
cat("====================================================\n")
cat("NORMALIZED BOUNDARY SENSITIVITY COMPLETED\n")
cat("====================================================\n")
cat(
  "Normalized response rows: ",
  nrow(d),
  "\n",
  sep = ""
)
cat(
  "Beta estimates: ",
  nrow(betas),
  "\n",
  sep = ""
)
cat(
  "Stage × index summaries: ",
  nrow(beta_summary),
  "\n",
  sep = ""
)
cat("\n")
cat("Primary metric: |beta| = % VI change per 1% mask-area change.\n")
cat("No p-values are calculated because perturbation levels are\n")
cat("deterministic transformations rather than independent replicates.\n")
cat("\nOutputs:\n")
cat(
  response_file,
  "\n"
)
cat(
  beta_file,
  "\n"
)
cat(
  summary_file,
  "\n"
)

# ============================================================
# END
# ============================================================