# ============================================================
# 12_robustness_analysis.R
#
# Purpose
# -------
# Audits robustness of the canopy-boundary sensitivity analysis.
#
# The final analytical hierarchy distinguishes:
#
# PRIMARY
#   Direction-specific normalized sensitivity:
#     |beta_erosion|
#     |beta_dilation|
#
# SUPPORTING
#   Combined |beta| estimated jointly from erosion and dilation.
#
# Robustness diagnostics
# ----------------------
# A. Combined beta (supporting metric)
#   1) ±1-2 cm versus ±1-3 cm
#   2) leave-one-subplot-out
#
# B. Direction-specific beta (PRIMARY metric)
#   3) erosion: ±1-2 cm versus ±1-3 cm
#   4) dilation: ±1-2 cm versus ±1-3 cm
#   5) directional leave-one-subplot-out
#   6) erosion-versus-dilation asymmetry
#
# Inputs
# ------
# derived/boundary_sensitivity/
#   normalized_boundary_response_observations.csv
#   normalized_boundary_sensitivity_by_plot.csv
#
# Outputs
# -------
# derived/boundary_sensitivity/
#   robustness_range_by_plot.csv
#   robustness_range_summary.csv
#   robustness_leave_one_subplot_out.csv
#   robustness_leave_one_subplot_out_summary.csv
#
#   directional_beta_by_plot.csv
#   directional_beta_summary.csv
#   directional_robustness_range_by_plot.csv
#   directional_robustness_range_summary.csv
#   directional_robustness_leave_one_subplot_out.csv
#   directional_robustness_leave_one_subplot_out_summary.csv
#
# Notes
# -----
# - Perturbation levels are deterministic transformations and are
#   not treated as independent experimental replicates.
# - P1-P5 are the independent spatial observational units.
# - No p-values are calculated.
# - No arbitrary pass/fail robustness threshold is imposed.
# ============================================================


rm(list = ls())
gc()


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
    normalizePath(
      start,
      winslash = "/",
      mustWork = TRUE
    ),
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


derived_root <- file.path(
  project_root,
  "derived",
  "boundary_sensitivity"
)


response_file <- file.path(
  derived_root,
  "normalized_boundary_response_observations.csv"
)

beta_file <- file.path(
  derived_root,
  "normalized_boundary_sensitivity_by_plot.csv"
)


if (!file.exists(response_file)) {
  stop(
    "Missing file:\n",
    response_file,
    "\nRun scripts/04_normalized_boundary_sensitivity.R first."
  )
}

if (!file.exists(beta_file)) {
  stop(
    "Missing file:\n",
    beta_file,
    "\nRun scripts/04_normalized_boundary_sensitivity.R first."
  )
}


# ------------------------------------------------------------
# 2. READ DATA
# ------------------------------------------------------------

responses <- read.csv(
  response_file,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

betas <- read.csv(
  beta_file,
  stringsAsFactors = FALSE,
  check.names = FALSE
)


required_response <- c(
  "flight",
  "growth_stage",
  "subplot",
  "index",
  "perturb_cm",
  "delta_mask_area_pct",
  "delta_index_pct"
)

required_beta <- c(
  "flight",
  "growth_stage",
  "subplot",
  "index",
  "absolute_beta",
  "absolute_beta_using_1to2cm",
  "r2_origin_all_1to3cm",
  "r2_origin_1to2cm"
)


if (!all(
  required_response %in%
  names(responses)
)) {
  stop(
    "normalized_boundary_response_observations.csv is missing required columns."
  )
}

if (!all(
  required_beta %in%
  names(betas)
)) {
  stop(
    "normalized_boundary_sensitivity_by_plot.csv is missing required columns."
  )
}

if (nrow(betas) != 75) {
  stop(
    "Expected 75 plot × stage × index beta estimates; found ",
    nrow(betas)
  )
}


# ------------------------------------------------------------
# 3. HELPER FUNCTIONS
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


safe_relative_difference_pct <- function(
    reference,
    comparison
) {
  
  ifelse(
    is.finite(reference) &
      is.finite(comparison) &
      abs(reference) > 0,
    100 *
      (
        comparison -
          reference
      ) /
      abs(reference),
    NA_real_
  )
}


summarize_by_keys <- function(
    data,
    keys,
    builder
) {
  
  unique_keys <- unique(
    data[
      ,
      keys,
      drop = FALSE
    ]
  )
  
  rows <- vector(
    "list",
    nrow(unique_keys)
  )
  
  for (i in seq_len(nrow(unique_keys))) {
    
    key <- unique_keys[i, , drop = FALSE]
    
    z <- data
    
    for (k in keys) {
      z <- z[
        z[[k]] == key[[k]],
        ,
        drop = FALSE
      ]
    }
    
    rows[[i]] <- cbind(
      key,
      builder(z)
    )
  }
  
  out <- do.call(
    rbind,
    rows
  )
  
  rownames(out) <- NULL
  
  out
}


# ============================================================
# PART A — COMBINED BETA ROBUSTNESS
# ============================================================


# ------------------------------------------------------------
# 4. COMBINED PERTURBATION-RANGE ROBUSTNESS
# ------------------------------------------------------------

range_robustness <- betas


range_robustness$signed_relative_difference_pct <-
  safe_relative_difference_pct(
    reference =
      range_robustness$absolute_beta,
    
    comparison =
      range_robustness$absolute_beta_using_1to2cm
  )


range_robustness$absolute_relative_difference_pct <-
  abs(
    range_robustness$signed_relative_difference_pct
  )


range_summary <- summarize_by_keys(
  data = range_robustness,
  
  keys = c(
    "growth_stage",
    "index"
  ),
  
  builder = function(z) {
    
    data.frame(
      n_subplots = nrow(z),
      
      mean_beta_1to3 =
        mean(
          z$absolute_beta,
          na.rm = TRUE
        ),
      
      mean_beta_1to2 =
        mean(
          z$absolute_beta_using_1to2cm,
          na.rm = TRUE
        ),
      
      mean_abs_relative_difference_pct =
        mean(
          z$absolute_relative_difference_pct,
          na.rm = TRUE
        ),
      
      median_abs_relative_difference_pct =
        median(
          z$absolute_relative_difference_pct,
          na.rm = TRUE
        ),
      
      max_abs_relative_difference_pct =
        max(
          z$absolute_relative_difference_pct,
          na.rm = TRUE
        ),
      
      mean_r2_1to3 =
        mean(
          z$r2_origin_all_1to3cm,
          na.rm = TRUE
        ),
      
      mean_r2_1to2 =
        mean(
          z$r2_origin_1to2cm,
          na.rm = TRUE
        ),
      
      stringsAsFactors = FALSE
    )
  }
)


# ------------------------------------------------------------
# 5. COMBINED LEAVE-ONE-SUBPLOT-OUT
# ------------------------------------------------------------

combined_lopo_rows <- list()
combined_lopo_counter <- 1


combined_lopo_keys <- unique(
  betas[
    ,
    c(
      "growth_stage",
      "index"
    )
  ]
)


for (i in seq_len(nrow(combined_lopo_keys))) {
  
  key <- combined_lopo_keys[
    i,
    ,
    drop = FALSE
  ]
  
  z <- betas[
    betas$growth_stage == key$growth_stage &
      betas$index == key$index,
    ,
    drop = FALSE
  ]
  
  full_mean <- mean(
    z$absolute_beta,
    na.rm = TRUE
  )
  
  for (subplot in sort(
    unique(
      z$subplot
    )
  )) {
    
    reduced <- z[
      z$subplot != subplot,
      ,
      drop = FALSE
    ]
    
    lopo_mean <- mean(
      reduced$absolute_beta,
      na.rm = TRUE
    )
    
    relative_change_pct <-
      safe_relative_difference_pct(
        reference = full_mean,
        comparison = lopo_mean
      )
    
    combined_lopo_rows[[combined_lopo_counter]] <- data.frame(
      
      growth_stage =
        key$growth_stage,
      
      index =
        key$index,
      
      left_out_subplot =
        subplot,
      
      full_mean_abs_beta =
        full_mean,
      
      lopo_mean_abs_beta =
        lopo_mean,
      
      relative_change_pct =
        relative_change_pct,
      
      abs_relative_change_pct =
        abs(
          relative_change_pct
        ),
      
      stringsAsFactors = FALSE
    )
    
    combined_lopo_counter <-
      combined_lopo_counter + 1
  }
}


combined_lopo <- do.call(
  rbind,
  combined_lopo_rows
)

rownames(combined_lopo) <- NULL


combined_lopo_summary <- summarize_by_keys(
  data = combined_lopo,
  
  keys = c(
    "growth_stage",
    "index"
  ),
  
  builder = function(z) {
    
    data.frame(
      full_mean_abs_beta =
        unique(
          z$full_mean_abs_beta
        )[1],
      
      mean_abs_lopo_change_pct =
        mean(
          z$abs_relative_change_pct,
          na.rm = TRUE
        ),
      
      max_abs_lopo_change_pct =
        max(
          z$abs_relative_change_pct,
          na.rm = TRUE
        ),
      
      min_lopo_mean_abs_beta =
        min(
          z$lopo_mean_abs_beta,
          na.rm = TRUE
        ),
      
      max_lopo_mean_abs_beta =
        max(
          z$lopo_mean_abs_beta,
          na.rm = TRUE
        ),
      
      stringsAsFactors = FALSE
    )
  }
)


# ============================================================
# PART B — DIRECTION-SPECIFIC ROBUSTNESS
# ============================================================


# ------------------------------------------------------------
# 6. PREPARE NON-ZERO RESPONSE DATA
# ------------------------------------------------------------

analysis_data <- responses[
  responses$perturb_cm != 0,
  ,
  drop = FALSE
]


analysis_data$boundary_direction <- ifelse(
  analysis_data$perturb_cm < 0,
  "Erosion",
  "Dilation"
)


direction_keys <- unique(
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


# ------------------------------------------------------------
# 7. DIRECTIONAL BETA:
#    ±1-3 cm AND ±1-2 cm
# ------------------------------------------------------------

directional_rows <- list()
directional_long_rows <- list()

directional_counter <- 1
directional_long_counter <- 1


for (i in seq_len(nrow(direction_keys))) {
  
  key <- direction_keys[
    i,
    ,
    drop = FALSE
  ]
  
  z <- analysis_data[
    analysis_data$flight == key$flight &
      analysis_data$growth_stage == key$growth_stage &
      analysis_data$subplot == key$subplot &
      analysis_data$index == key$index,
    ,
    drop = FALSE
  ]
  
  
  erosion <- z[
    z$perturb_cm < 0,
    ,
    drop = FALSE
  ]
  
  dilation <- z[
    z$perturb_cm > 0,
    ,
    drop = FALSE
  ]
  
  
  erosion_12 <- erosion[
    abs(
      erosion$perturb_cm
    ) <= 2,
    ,
    drop = FALSE
  ]
  
  dilation_12 <- dilation[
    abs(
      dilation$perturb_cm
    ) <= 2,
    ,
    drop = FALSE
  ]
  
  
  fit_erosion_13 <- fit_origin(
    x =
      erosion$delta_mask_area_pct,
    
    y =
      erosion$delta_index_pct
  )
  
  fit_erosion_12 <- fit_origin(
    x =
      erosion_12$delta_mask_area_pct,
    
    y =
      erosion_12$delta_index_pct
  )
  
  
  fit_dilation_13 <- fit_origin(
    x =
      dilation$delta_mask_area_pct,
    
    y =
      dilation$delta_index_pct
  )
  
  fit_dilation_12 <- fit_origin(
    x =
      dilation_12$delta_mask_area_pct,
    
    y =
      dilation_12$delta_index_pct
  )
  
  
  beta_erosion_13 <-
    unname(
      fit_erosion_13["beta"]
    )
  
  beta_erosion_12 <-
    unname(
      fit_erosion_12["beta"]
    )
  
  beta_dilation_13 <-
    unname(
      fit_dilation_13["beta"]
    )
  
  beta_dilation_12 <-
    unname(
      fit_dilation_12["beta"]
    )
  
  
  abs_erosion_13 <-
    abs(
      beta_erosion_13
    )
  
  abs_erosion_12 <-
    abs(
      beta_erosion_12
    )
  
  abs_dilation_13 <-
    abs(
      beta_dilation_13
    )
  
  abs_dilation_12 <-
    abs(
      beta_dilation_12
    )
  
  
  erosion_range_change <-
    safe_relative_difference_pct(
      reference =
        abs_erosion_13,
      
      comparison =
        abs_erosion_12
    )
  
  dilation_range_change <-
    safe_relative_difference_pct(
      reference =
        abs_dilation_13,
      
      comparison =
        abs_dilation_12
    )
  
  
  asymmetry_absolute <-
    abs(
      abs_dilation_13 -
        abs_erosion_13
    )
  
  asymmetry_relative_pct <- if (
    is.finite(abs_erosion_13) &&
    is.finite(abs_dilation_13) &&
    (
      abs_erosion_13 +
      abs_dilation_13
    ) > 0
  ) {
    
    200 *
      asymmetry_absolute /
      (
        abs_erosion_13 +
          abs_dilation_13
      )
    
  } else {
    
    NA_real_
  }
  
  
  dilation_to_erosion_ratio <- if (
    is.finite(abs_erosion_13) &&
    abs_erosion_13 > 0
  ) {
    
    abs_dilation_13 /
      abs_erosion_13
    
  } else {
    
    NA_real_
  }
  
  
  # Wide table retained for figures and manuscript summaries.
  directional_rows[[directional_counter]] <- data.frame(
    
    flight =
      key$flight,
    
    growth_stage =
      key$growth_stage,
    
    subplot =
      key$subplot,
    
    index =
      key$index,
    
    beta_erosion =
      beta_erosion_13,
    
    abs_beta_erosion =
      abs_erosion_13,
    
    r2_origin_erosion =
      unname(
        fit_erosion_13[
          "r2_origin"
        ]
      ),
    
    beta_erosion_1to2cm =
      beta_erosion_12,
    
    abs_beta_erosion_1to2cm =
      abs_erosion_12,
    
    r2_origin_erosion_1to2cm =
      unname(
        fit_erosion_12[
          "r2_origin"
        ]
      ),
    
    erosion_range_relative_change_pct =
      erosion_range_change,
    
    erosion_range_abs_relative_change_pct =
      abs(
        erosion_range_change
      ),
    
    beta_dilation =
      beta_dilation_13,
    
    abs_beta_dilation =
      abs_dilation_13,
    
    r2_origin_dilation =
      unname(
        fit_dilation_13[
          "r2_origin"
        ]
      ),
    
    beta_dilation_1to2cm =
      beta_dilation_12,
    
    abs_beta_dilation_1to2cm =
      abs_dilation_12,
    
    r2_origin_dilation_1to2cm =
      unname(
        fit_dilation_12[
          "r2_origin"
        ]
      ),
    
    dilation_range_relative_change_pct =
      dilation_range_change,
    
    dilation_range_abs_relative_change_pct =
      abs(
        dilation_range_change
      ),
    
    abs_directional_difference_beta =
      asymmetry_absolute,
    
    directional_asymmetry_pct =
      asymmetry_relative_pct,
    
    dilation_to_erosion_ratio =
      dilation_to_erosion_ratio,
    
    stringsAsFactors = FALSE
  )
  
  directional_counter <-
    directional_counter + 1
  
  
  # Long table for robustness summaries.
  directional_long_rows[[directional_long_counter]] <- data.frame(
    
    flight =
      key$flight,
    
    growth_stage =
      key$growth_stage,
    
    subplot =
      key$subplot,
    
    index =
      key$index,
    
    boundary_direction =
      "Erosion",
    
    beta_1to3 =
      beta_erosion_13,
    
    abs_beta_1to3 =
      abs_erosion_13,
    
    r2_1to3 =
      unname(
        fit_erosion_13[
          "r2_origin"
        ]
      ),
    
    beta_1to2 =
      beta_erosion_12,
    
    abs_beta_1to2 =
      abs_erosion_12,
    
    r2_1to2 =
      unname(
        fit_erosion_12[
          "r2_origin"
        ]
      ),
    
    relative_difference_pct =
      erosion_range_change,
    
    abs_relative_difference_pct =
      abs(
        erosion_range_change
      ),
    
    stringsAsFactors = FALSE
  )
  
  directional_long_counter <-
    directional_long_counter + 1
  
  
  directional_long_rows[[directional_long_counter]] <- data.frame(
    
    flight =
      key$flight,
    
    growth_stage =
      key$growth_stage,
    
    subplot =
      key$subplot,
    
    index =
      key$index,
    
    boundary_direction =
      "Dilation",
    
    beta_1to3 =
      beta_dilation_13,
    
    abs_beta_1to3 =
      abs_dilation_13,
    
    r2_1to3 =
      unname(
        fit_dilation_13[
          "r2_origin"
        ]
      ),
    
    beta_1to2 =
      beta_dilation_12,
    
    abs_beta_1to2 =
      abs_dilation_12,
    
    r2_1to2 =
      unname(
        fit_dilation_12[
          "r2_origin"
        ]
      ),
    
    relative_difference_pct =
      dilation_range_change,
    
    abs_relative_difference_pct =
      abs(
        dilation_range_change
      ),
    
    stringsAsFactors = FALSE
  )
  
  directional_long_counter <-
    directional_long_counter + 1
}


directional <- do.call(
  rbind,
  directional_rows
)

rownames(directional) <- NULL


directional_range <- do.call(
  rbind,
  directional_long_rows
)

rownames(directional_range) <- NULL


if (nrow(directional) != 75) {
  stop(
    "Expected 75 directional wide records; found ",
    nrow(directional)
  )
}

if (nrow(directional_range) != 150) {
  stop(
    "Expected 150 directional robustness records; found ",
    nrow(directional_range)
  )
}


# ------------------------------------------------------------
# 8. DIRECTIONAL RANGE SUMMARY
# ------------------------------------------------------------

directional_range_summary <- summarize_by_keys(
  data = directional_range,
  
  keys = c(
    "growth_stage",
    "index",
    "boundary_direction"
  ),
  
  builder = function(z) {
    
    data.frame(
      n_subplots =
        nrow(z),
      
      mean_abs_beta_1to3 =
        mean(
          z$abs_beta_1to3,
          na.rm = TRUE
        ),
      
      mean_abs_beta_1to2 =
        mean(
          z$abs_beta_1to2,
          na.rm = TRUE
        ),
      
      mean_abs_relative_difference_pct =
        mean(
          z$abs_relative_difference_pct,
          na.rm = TRUE
        ),
      
      median_abs_relative_difference_pct =
        median(
          z$abs_relative_difference_pct,
          na.rm = TRUE
        ),
      
      max_abs_relative_difference_pct =
        max(
          z$abs_relative_difference_pct,
          na.rm = TRUE
        ),
      
      mean_r2_1to3 =
        mean(
          z$r2_1to3,
          na.rm = TRUE
        ),
      
      mean_r2_1to2 =
        mean(
          z$r2_1to2,
          na.rm = TRUE
        ),
      
      stringsAsFactors = FALSE
    )
  }
)


# ------------------------------------------------------------
# 9. DIRECTIONAL BETA SUMMARY
# ------------------------------------------------------------

direction_summary <- summarize_by_keys(
  data = directional,
  
  keys = c(
    "growth_stage",
    "index"
  ),
  
  builder = function(z) {
    
    data.frame(
      n_subplots =
        nrow(z),
      
      mean_abs_beta_erosion =
        mean(
          z$abs_beta_erosion,
          na.rm = TRUE
        ),
      
      median_abs_beta_erosion =
        median(
          z$abs_beta_erosion,
          na.rm = TRUE
        ),
      
      mean_abs_beta_dilation =
        mean(
          z$abs_beta_dilation,
          na.rm = TRUE
        ),
      
      median_abs_beta_dilation =
        median(
          z$abs_beta_dilation,
          na.rm = TRUE
        ),
      
      median_dilation_to_erosion_ratio =
        median(
          z$dilation_to_erosion_ratio,
          na.rm = TRUE
        ),
      
      mean_directional_asymmetry_pct =
        mean(
          z$directional_asymmetry_pct,
          na.rm = TRUE
        ),
      
      median_directional_asymmetry_pct =
        median(
          z$directional_asymmetry_pct,
          na.rm = TRUE
        ),
      
      max_directional_asymmetry_pct =
        max(
          z$directional_asymmetry_pct,
          na.rm = TRUE
        ),
      
      mean_r2_erosion =
        mean(
          z$r2_origin_erosion,
          na.rm = TRUE
        ),
      
      mean_r2_dilation =
        mean(
          z$r2_origin_dilation,
          na.rm = TRUE
        ),
      
      stringsAsFactors = FALSE
    )
  }
)


# ------------------------------------------------------------
# 10. DIRECTIONAL LEAVE-ONE-SUBPLOT-OUT
# ------------------------------------------------------------

directional_lopo_rows <- list()
directional_lopo_counter <- 1


directional_lopo_keys <- unique(
  directional_range[
    ,
    c(
      "growth_stage",
      "index",
      "boundary_direction"
    )
  ]
)


for (i in seq_len(nrow(directional_lopo_keys))) {
  
  key <- directional_lopo_keys[
    i,
    ,
    drop = FALSE
  ]
  
  z <- directional_range[
    directional_range$growth_stage ==
      key$growth_stage &
      directional_range$index ==
      key$index &
      directional_range$boundary_direction ==
      key$boundary_direction,
    ,
    drop = FALSE
  ]
  
  full_mean <- mean(
    z$abs_beta_1to3,
    na.rm = TRUE
  )
  
  
  for (subplot in sort(
    unique(
      z$subplot
    )
  )) {
    
    reduced <- z[
      z$subplot != subplot,
      ,
      drop = FALSE
    ]
    
    lopo_mean <- mean(
      reduced$abs_beta_1to3,
      na.rm = TRUE
    )
    
    relative_change_pct <-
      safe_relative_difference_pct(
        reference =
          full_mean,
        
        comparison =
          lopo_mean
      )
    
    
    directional_lopo_rows[[directional_lopo_counter]] <- data.frame(
      
      growth_stage =
        key$growth_stage,
      
      index =
        key$index,
      
      boundary_direction =
        key$boundary_direction,
      
      left_out_subplot =
        subplot,
      
      full_mean_abs_beta =
        full_mean,
      
      lopo_mean_abs_beta =
        lopo_mean,
      
      relative_change_pct =
        relative_change_pct,
      
      abs_relative_change_pct =
        abs(
          relative_change_pct
        ),
      
      stringsAsFactors = FALSE
    )
    
    directional_lopo_counter <-
      directional_lopo_counter + 1
  }
}


directional_lopo <- do.call(
  rbind,
  directional_lopo_rows
)

rownames(directional_lopo) <- NULL


if (nrow(directional_lopo) != 150) {
  stop(
    "Expected 150 directional LOPO records; found ",
    nrow(directional_lopo)
  )
}


directional_lopo_summary <- summarize_by_keys(
  data = directional_lopo,
  
  keys = c(
    "growth_stage",
    "index",
    "boundary_direction"
  ),
  
  builder = function(z) {
    
    data.frame(
      full_mean_abs_beta =
        unique(
          z$full_mean_abs_beta
        )[1],
      
      mean_abs_lopo_change_pct =
        mean(
          z$abs_relative_change_pct,
          na.rm = TRUE
        ),
      
      median_abs_lopo_change_pct =
        median(
          z$abs_relative_change_pct,
          na.rm = TRUE
        ),
      
      max_abs_lopo_change_pct =
        max(
          z$abs_relative_change_pct,
          na.rm = TRUE
        ),
      
      min_lopo_mean_abs_beta =
        min(
          z$lopo_mean_abs_beta,
          na.rm = TRUE
        ),
      
      max_lopo_mean_abs_beta =
        max(
          z$lopo_mean_abs_beta,
          na.rm = TRUE
        ),
      
      stringsAsFactors = FALSE
    )
  }
)


# ------------------------------------------------------------
# 11. EXPORT
# ------------------------------------------------------------

range_file <- file.path(
  derived_root,
  "robustness_range_by_plot.csv"
)

range_summary_file <- file.path(
  derived_root,
  "robustness_range_summary.csv"
)

combined_lopo_file <- file.path(
  derived_root,
  "robustness_leave_one_subplot_out.csv"
)

combined_lopo_summary_file <- file.path(
  derived_root,
  "robustness_leave_one_subplot_out_summary.csv"
)


direction_file <- file.path(
  derived_root,
  "directional_beta_by_plot.csv"
)

direction_summary_file <- file.path(
  derived_root,
  "directional_beta_summary.csv"
)

directional_range_file <- file.path(
  derived_root,
  "directional_robustness_range_by_plot.csv"
)

directional_range_summary_file <- file.path(
  derived_root,
  "directional_robustness_range_summary.csv"
)

directional_lopo_file <- file.path(
  derived_root,
  "directional_robustness_leave_one_subplot_out.csv"
)

directional_lopo_summary_file <- file.path(
  derived_root,
  "directional_robustness_leave_one_subplot_out_summary.csv"
)


write.csv(
  range_robustness,
  range_file,
  row.names = FALSE,
  quote = FALSE
)

write.csv(
  range_summary,
  range_summary_file,
  row.names = FALSE,
  quote = FALSE
)

write.csv(
  combined_lopo,
  combined_lopo_file,
  row.names = FALSE,
  quote = FALSE
)

write.csv(
  combined_lopo_summary,
  combined_lopo_summary_file,
  row.names = FALSE,
  quote = FALSE
)


write.csv(
  directional,
  direction_file,
  row.names = FALSE,
  quote = FALSE
)

write.csv(
  direction_summary,
  direction_summary_file,
  row.names = FALSE,
  quote = FALSE
)

write.csv(
  directional_range,
  directional_range_file,
  row.names = FALSE,
  quote = FALSE
)

write.csv(
  directional_range_summary,
  directional_range_summary_file,
  row.names = FALSE,
  quote = FALSE
)

write.csv(
  directional_lopo,
  directional_lopo_file,
  row.names = FALSE,
  quote = FALSE
)

write.csv(
  directional_lopo_summary,
  directional_lopo_summary_file,
  row.names = FALSE,
  quote = FALSE
)


# ------------------------------------------------------------
# 12. REPORT
# ------------------------------------------------------------

erosion_range <- directional_range[
  directional_range$boundary_direction ==
    "Erosion",
  ,
  drop = FALSE
]

dilation_range <- directional_range[
  directional_range$boundary_direction ==
    "Dilation",
  ,
  drop = FALSE
]


erosion_lopo_summary <- directional_lopo_summary[
  directional_lopo_summary$boundary_direction ==
    "Erosion",
  ,
  drop = FALSE
]

dilation_lopo_summary <- directional_lopo_summary[
  directional_lopo_summary$boundary_direction ==
    "Dilation",
  ,
  drop = FALSE
]


cat("\n")
cat("====================================================\n")
cat("ROBUSTNESS ANALYSIS COMPLETED\n")
cat("====================================================\n")


cat("\nSUPPORTING COMBINED BETA\n")
cat("------------------------\n")

cat(
  "Mean absolute relative beta difference (±1-2 vs ±1-3 cm): ",
  sprintf(
    "%.2f%%",
    mean(
      range_robustness$absolute_relative_difference_pct,
      na.rm = TRUE
    )
  ),
  "\n",
  sep = ""
)

cat(
  "Median of stage × index maximum LOPO changes: ",
  sprintf(
    "%.2f%%",
    median(
      combined_lopo_summary$max_abs_lopo_change_pct,
      na.rm = TRUE
    )
  ),
  "\n",
  sep = ""
)


cat("\nPRIMARY DIRECTION-SPECIFIC BETA\n")
cat("-------------------------------\n")

cat(
  "Erosion — mean absolute range difference (±1-2 vs ±1-3 cm): ",
  sprintf(
    "%.2f%%",
    mean(
      erosion_range$abs_relative_difference_pct,
      na.rm = TRUE
    )
  ),
  "\n",
  sep = ""
)

cat(
  "Erosion — median absolute range difference: ",
  sprintf(
    "%.2f%%",
    median(
      erosion_range$abs_relative_difference_pct,
      na.rm = TRUE
    )
  ),
  "\n",
  sep = ""
)

cat(
  "Dilation — mean absolute range difference (±1-2 vs ±1-3 cm): ",
  sprintf(
    "%.2f%%",
    mean(
      dilation_range$abs_relative_difference_pct,
      na.rm = TRUE
    )
  ),
  "\n",
  sep = ""
)

cat(
  "Dilation — median absolute range difference: ",
  sprintf(
    "%.2f%%",
    median(
      dilation_range$abs_relative_difference_pct,
      na.rm = TRUE
    )
  ),
  "\n",
  sep = ""
)


cat("\nDirectional leave-one-subplot-out:\n")

cat(
  "Erosion — median of stage × index maximum changes: ",
  sprintf(
    "%.2f%%",
    median(
      erosion_lopo_summary$max_abs_lopo_change_pct,
      na.rm = TRUE
    )
  ),
  "\n",
  sep = ""
)

cat(
  "Erosion — largest stage × index maximum change: ",
  sprintf(
    "%.2f%%",
    max(
      erosion_lopo_summary$max_abs_lopo_change_pct,
      na.rm = TRUE
    )
  ),
  "\n",
  sep = ""
)

cat(
  "Dilation — median of stage × index maximum changes: ",
  sprintf(
    "%.2f%%",
    median(
      dilation_lopo_summary$max_abs_lopo_change_pct,
      na.rm = TRUE
    )
  ),
  "\n",
  sep = ""
)

cat(
  "Dilation — largest stage × index maximum change: ",
  sprintf(
    "%.2f%%",
    max(
      dilation_lopo_summary$max_abs_lopo_change_pct,
      na.rm = TRUE
    )
  ),
  "\n",
  sep = ""
)


cat("\nDirectional asymmetry:\n")

cat(
  "Median directional asymmetry across plot × stage × index: ",
  sprintf(
    "%.2f%%",
    median(
      directional$directional_asymmetry_pct,
      na.rm = TRUE
    )
  ),
  "\n",
  sep = ""
)

cat(
  "Maximum directional asymmetry: ",
  sprintf(
    "%.2f%%",
    max(
      directional$directional_asymmetry_pct,
      na.rm = TRUE
    )
  ),
  "\n",
  sep = ""
)


cat("\n")
cat(
  "Important: directional robustness is now evaluated on the same\n"
)
cat(
  "erosion and dilation beta metrics used as the primary results.\n"
)
cat(
  "No inferential significance tests or arbitrary pass/fail thresholds\n"
)
cat(
  "are applied to these diagnostics.\n"
)


cat("\nOutputs:\n")

output_files <- c(
  range_file,
  range_summary_file,
  combined_lopo_file,
  combined_lopo_summary_file,
  direction_file,
  direction_summary_file,
  directional_range_file,
  directional_range_summary_file,
  directional_lopo_file,
  directional_lopo_summary_file
)

for (f in output_files) {
  cat(
    f,
    "\n"
  )
}


# ============================================================
# END
# ============================================================