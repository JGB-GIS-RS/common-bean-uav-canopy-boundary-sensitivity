# ============================================================
# 13_boundary_sensitivity_figures.R
#
# Final publication-oriented figures for the canopy-boundary
# sensitivity study.
#
# MAIN
#   Figure 6. Direction-specific normalized boundary sensitivity
#   Figure 7. Radial spectral transition outside the canopy
#
# SUPPLEMENTARY
#   Figure S1. Directional erosion-dilation asymmetry
#   Figure S2. Directional normalized response curves
#
# No titles/subtitles are embedded in the exported images.
# ============================================================


rm(list = ls())
gc()


# ------------------------------------------------------------
# 1. PACKAGE
# ------------------------------------------------------------

if (!requireNamespace(
  "ggplot2",
  quietly = TRUE
)) {
  stop(
    "Package 'ggplot2' is required.\n",
    "Install it once with: install.packages('ggplot2')"
  )
}

library(ggplot2)


# ------------------------------------------------------------
# 2. PROJECT ROOT
# ------------------------------------------------------------

find_project_root <- function(
    start = getwd()
) {
  
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
    
    if (identical(
      parent,
      current
    )) {
      break
    }
    
    current <- parent
  }
  
  stop(
    "Repository root could not be detected from: ",
    start
  )
}


project_root <- find_project_root()


cat(
  "Repository root detected: ",
  project_root,
  "\n",
  sep = ""
)


# ------------------------------------------------------------
# 3. PATHS
# ------------------------------------------------------------

boundary_root <- file.path(
  project_root,
  "derived",
  "boundary_sensitivity"
)

radial_root <- file.path(
  project_root,
  "derived",
  "radial_background"
)

figure_root <- file.path(
  project_root,
  "figures",
  "boundary_sensitivity"
)


dir.create(
  figure_root,
  recursive = TRUE,
  showWarnings = FALSE
)


direction_file <- file.path(
  boundary_root,
  "directional_beta_by_plot.csv"
)

response_file <- file.path(
  boundary_root,
  "normalized_boundary_response_observations.csv"
)

radial_file <- file.path(
  radial_root,
  "radial_ring_observations.csv"
)


required_files <- c(
  direction_file,
  response_file,
  radial_file
)


missing_files <- required_files[
  !file.exists(
    required_files
  )
]


if (length(
  missing_files
) > 0) {
  
  stop(
    "Missing required derived file(s):\n",
    paste(
      missing_files,
      collapse = "\n"
    ),
    "\n\nRun Scripts 02-05 to regenerate the required derived tables."
  )
}


# ------------------------------------------------------------
# Clean matching output files before figure export
# ------------------------------------------------------------

obsolete_files <- c(
  "Figure_S1_combined_boundary_sensitivity.png",
  "Figure_S2_directional_asymmetry.png",
  "Figure_S3_directional_boundary_response_curves.png"
)


unlink(
  file.path(
    figure_root,
    obsolete_files
  ),
  force = TRUE
)


# ------------------------------------------------------------
# 4. READ DATA
# ------------------------------------------------------------

direction <- read.csv(
  direction_file,
  stringsAsFactors = FALSE,
  check.names = FALSE
)


response <- read.csv(
  response_file,
  stringsAsFactors = FALSE,
  check.names = FALSE
)


radial <- read.csv(
  radial_file,
  stringsAsFactors = FALSE,
  check.names = FALSE
)


# ------------------------------------------------------------
# 5. EXPECTED LEVELS
# ------------------------------------------------------------

stage_levels <- c(
  "V4",
  "R5",
  "R6",
  "R7",
  "R8"
)


index_levels <- c(
  "NDVI",
  "MSAVI",
  "WDRVI"
)


subplot_levels <- c(
  "P1",
  "P2",
  "P3",
  "P4",
  "P5"
)


direction_levels <- c(
  "Erosion",
  "Dilation"
)


# ------------------------------------------------------------
# 6. REQUIRED COLUMNS
# ------------------------------------------------------------

required_direction <- c(
  "growth_stage",
  "subplot",
  "index",
  "abs_beta_erosion",
  "abs_beta_dilation",
  "directional_asymmetry_pct"
)


required_response <- c(
  "growth_stage",
  "subplot",
  "index",
  "perturb_cm",
  "delta_mask_area_pct",
  "delta_index_pct"
)


required_radial <- c(
  "growth_stage",
  "subplot",
  "index",
  "ring_mid_cm",
  "ring_mean"
)


if (!all(
  required_direction %in%
  names(direction)
)) {
  
  stop(
    "directional_beta_by_plot.csv is missing required columns."
  )
}


if (!all(
  required_response %in%
  names(response)
)) {
  
  stop(
    "normalized_boundary_response_observations.csv is missing required columns."
  )
}


if (!all(
  required_radial %in%
  names(radial)
)) {
  
  stop(
    "radial_ring_observations.csv is missing required columns."
  )
}


if (nrow(direction) != 75) {
  
  stop(
    "Expected 75 directional beta records; found ",
    nrow(direction)
  )
}


if (anyNA(
  direction$abs_beta_erosion
)) {
  
  stop(
    "NA values detected in abs_beta_erosion."
  )
}


if (anyNA(
  direction$abs_beta_dilation
)) {
  
  stop(
    "NA values detected in abs_beta_dilation."
  )
}


# ------------------------------------------------------------
# 7. FACTOR ORDER
# ------------------------------------------------------------

apply_factor_order <- function(
    d
) {
  
  d$growth_stage <- factor(
    d$growth_stage,
    levels = stage_levels
  )
  
  d$index <- factor(
    d$index,
    levels = index_levels
  )
  
  d$subplot <- factor(
    d$subplot,
    levels = subplot_levels
  )
  
  d
}


direction <- apply_factor_order(
  direction
)

response <- apply_factor_order(
  response
)

radial <- apply_factor_order(
  radial
)


# ------------------------------------------------------------
# 8. SUMMARY FUNCTION
#    MEDIAN + IQR
# ------------------------------------------------------------

summarize_median_iqr <- function(
    data,
    value_col,
    group_cols
) {
  
  required_cols <- c(
    value_col,
    group_cols
  )
  
  missing_cols <- setdiff(
    required_cols,
    names(data)
  )
  
  
  if (length(
    missing_cols
  ) > 0) {
    
    stop(
      "Missing column(s) in summary function: ",
      paste(
        missing_cols,
        collapse = ", "
      )
    )
  }
  
  
  split_args <- lapply(
    data[
      ,
      group_cols,
      drop = FALSE
    ],
    function(x) {
      
      if (is.factor(x)) {
        x
      } else {
        factor(x)
      }
    }
  )
  
  
  split_factor <- do.call(
    interaction,
    c(
      split_args,
      list(
        drop = TRUE,
        lex.order = TRUE
      )
    )
  )
  
  
  groups <- split(
    data,
    split_factor
  )
  
  
  rows <- lapply(
    groups,
    function(z) {
      
      x <- z[[value_col]]
      
      group_values <- z[
        1,
        group_cols,
        drop = FALSE
      ]
      
      
      cbind(
        group_values,
        
        data.frame(
          n = sum(
            is.finite(x)
          ),
          
          median = median(
            x,
            na.rm = TRUE
          ),
          
          q25 = as.numeric(
            quantile(
              x,
              0.25,
              na.rm = TRUE
            )
          ),
          
          q75 = as.numeric(
            quantile(
              x,
              0.75,
              na.rm = TRUE
            )
          ),
          
          mean = mean(
            x,
            na.rm = TRUE
          ),
          
          sd = sd(
            x,
            na.rm = TRUE
          ),
          
          stringsAsFactors = FALSE
        )
      )
    }
  )
  
  
  out <- do.call(
    rbind,
    rows
  )
  
  
  rownames(out) <- NULL
  
  
  out
}


# ------------------------------------------------------------
# 9. COMMON GRAPHICAL SETTINGS
# ------------------------------------------------------------

subplot_shapes <- c(
  P1 = 21,
  P2 = 22,
  P3 = 23,
  P4 = 24,
  P5 = 25
)


theme_publication <- theme_classic(
  base_size = 11
) +
  theme(
    strip.background = element_rect(
      fill = "grey95",
      colour = "black",
      linewidth = 0.8
    ),
    
    strip.text = element_text(
      face = "bold",
      size = 10.5
    ),
    
    axis.title.y = element_text(
      face = "bold",
      size = 11.5
    ),
    
    axis.title.x = element_text(
      face = "plain",
      size = 11.5
    ),
    
    axis.text = element_text(
      size = 9.5,
      colour = "black"
    ),
    
    legend.title = element_text(
      face = "bold",
      size = 10.5
    ),
    
    legend.text = element_text(
      size = 9.5
    ),
    
    legend.position = "bottom",
    
    panel.spacing = grid::unit(
      0.8,
      "lines"
    ),
    
    plot.margin = margin(
      t = 5,
      r = 7,
      b = 5,
      l = 7
    )
  )


# ============================================================
# FIGURE 6 — MAIN
# DIRECTION-SPECIFIC NORMALIZED SENSITIVITY
# ============================================================

direction_long <- rbind(
  
  data.frame(
    growth_stage =
      direction$growth_stage,
    
    subplot =
      direction$subplot,
    
    index =
      direction$index,
    
    boundary_direction =
      "Erosion",
    
    absolute_beta =
      direction$abs_beta_erosion,
    
    stringsAsFactors = FALSE
  ),
  
  
  data.frame(
    growth_stage =
      direction$growth_stage,
    
    subplot =
      direction$subplot,
    
    index =
      direction$index,
    
    boundary_direction =
      "Dilation",
    
    absolute_beta =
      direction$abs_beta_dilation,
    
    stringsAsFactors = FALSE
  )
)


direction_long$growth_stage <- factor(
  direction_long$growth_stage,
  levels = stage_levels
)


direction_long$index <- factor(
  direction_long$index,
  levels = index_levels
)


direction_long$subplot <- factor(
  direction_long$subplot,
  levels = subplot_levels
)


direction_long$boundary_direction <- factor(
  direction_long$boundary_direction,
  levels = direction_levels
)


direction_summary <- summarize_median_iqr(
  data = direction_long,
  
  value_col =
    "absolute_beta",
  
  group_cols = c(
    "growth_stage",
    "index",
    "boundary_direction"
  )
)


direction_summary$growth_stage <- factor(
  direction_summary$growth_stage,
  levels = stage_levels
)


direction_summary$index <- factor(
  direction_summary$index,
  levels = index_levels
)


direction_summary$boundary_direction <- factor(
  direction_summary$boundary_direction,
  levels = direction_levels
)


position_direction <- position_dodge(
  width = 0.58
)


p1 <- ggplot(
  direction_long,
  
  aes(
    x = growth_stage,
    y = absolute_beta,
    fill = boundary_direction,
    group = boundary_direction
  )
) +
  
  geom_point(
    aes(
      shape = subplot
    ),
    
    position = position_jitterdodge(
      jitter.width = 0.04,
      jitter.height = 0,
      dodge.width = 0.58
    ),
    
    size = 2.35,
    stroke = 0.60,
    alpha = 0.82
  ) +
  
  geom_linerange(
    data = direction_summary,
    
    aes(
      x = growth_stage,
      ymin = q25,
      ymax = q75,
      group = boundary_direction
    ),
    
    inherit.aes = FALSE,
    position = position_direction,
    linewidth = 0.75
  ) +
  
  geom_point(
    data = direction_summary,
    
    aes(
      x = growth_stage,
      y = median,
      fill = boundary_direction,
      group = boundary_direction
    ),
    
    inherit.aes = FALSE,
    position = position_direction,
    shape = 21,
    size = 3.4,
    stroke = 0.90
  ) +
  
  facet_wrap(
    ~ index,
    nrow = 1,
    scales = "free_y"
  ) +
  
  scale_shape_manual(
    values = subplot_shapes,
    breaks = subplot_levels,
    name = "Plot"
  ) +
  scale_fill_manual(
    values = c(
      Erosion = "#F8766D",
      Dilation = "#00BFC4"
    ),
    breaks = direction_levels,
    name = "Boundary direction"
  ) +
  
  labs(
    x =
      "UAV acquisition stage",
    
    y = expression(
      "|" * beta * "|" ~ "(% VI change per 1% mask-area change)"
    ),
    
    fill =
      "Boundary direction"
  ) +
  
  guides(
    fill = guide_legend(
      order = 1,
      
      override.aes = list(
        shape = 21,
        size = 3.2
      )
    ),
    
    shape = guide_legend(
      order = 2,
      
      override.aes = list(
        fill = "white"
      )
    )
  ) +
  
  theme_publication


figure6_file <- file.path(
  figure_root,
  "Figure_6_directional_boundary_sensitivity.png"
)


ggsave(
  filename = figure6_file,
  plot = p1,
  width = 10.8,
  height = 4.4,
  units = "in",
  dpi = 600,
  bg = "white"
)


# ============================================================
# FIGURE 7 — MAIN
# RADIAL SPECTRAL TRANSITION
# ============================================================

radial_summary <- summarize_median_iqr(
  data = radial,
  
  value_col =
    "ring_mean",
  
  group_cols = c(
    "growth_stage",
    "index",
    "ring_mid_cm"
  )
)


radial_summary$growth_stage <- factor(
  radial_summary$growth_stage,
  levels = stage_levels
)


radial_summary$index <- factor(
  radial_summary$index,
  levels = index_levels
)


p2 <- ggplot(
  radial,
  
  aes(
    x = ring_mid_cm,
    y = ring_mean,
    group = subplot
  )
) +
  
  geom_line(
    linewidth = 0.30,
    alpha = 0.38
  ) +
  
  geom_point(
    aes(
      shape = subplot
    ),
    
    size = 1.55,
    alpha = 0.62
  ) +
  
  geom_linerange(
    data = radial_summary,
    
    aes(
      x = ring_mid_cm,
      ymin = q25,
      ymax = q75
    ),
    
    inherit.aes = FALSE,
    linewidth = 0.65
  ) +
  
  geom_line(
    data = radial_summary,
    
    aes(
      x = ring_mid_cm,
      y = median,
      group = 1
    ),
    
    inherit.aes = FALSE,
    linewidth = 0.90
  ) +
  
  geom_point(
    data = radial_summary,
    
    aes(
      x = ring_mid_cm,
      y = median
    ),
    
    inherit.aes = FALSE,
    shape = 21,
    size = 2.6,
    stroke = 0.80
  ) +
  
  facet_grid(
    index ~ growth_stage,
    scales = "free_y"
  ) +
  
  scale_x_continuous(
    breaks = c(
      2.5,
      7.5,
      12.5,
      17.5
    ),
    
    labels = c(
      "0-5",
      "5-10",
      "10-15",
      "15-20"
    )
  ) +
  
  scale_shape_manual(
    values = subplot_shapes,
    breaks = subplot_levels,
    name = "Plot"
  ) +
  
  labs(
    x =
      "External non-canopy ring (cm from segmented canopy boundary)",
    
    y =
      "Vegetation-index value"
  ) +
  
  theme_publication


figure7_file <- file.path(
  figure_root,
  "Figure_7_radial_background_profiles.png"
)


ggsave(
  filename = figure7_file,
  plot = p2,
  width = 11.8,
  height = 7.3,
  units = "in",
  dpi = 600,
  bg = "white"
)


# ============================================================
# FIGURE S1 — SUPPLEMENTARY
# DIRECTIONAL ASYMMETRY
# ============================================================

asym_summary <- summarize_median_iqr(
  data = direction,
  
  value_col =
    "directional_asymmetry_pct",
  
  group_cols = c(
    "growth_stage",
    "index"
  )
)


asym_summary$growth_stage <- factor(
  asym_summary$growth_stage,
  levels = stage_levels
)


asym_summary$index <- factor(
  asym_summary$index,
  levels = index_levels
)


pS1 <- ggplot(
  direction,
  
  aes(
    x = growth_stage,
    y = directional_asymmetry_pct
  )
) +
  
  geom_point(
    aes(
      shape = subplot
    ),
    
    position = position_jitter(
      width = 0.06,
      height = 0
    ),
    
    size = 2.2,
    alpha = 0.75
  ) +
  
  geom_linerange(
    data = asym_summary,
    
    aes(
      x = growth_stage,
      ymin = q25,
      ymax = q75
    ),
    
    inherit.aes = FALSE,
    linewidth = 0.75
  ) +
  
  geom_point(
    data = asym_summary,
    
    aes(
      x = growth_stage,
      y = median
    ),
    
    inherit.aes = FALSE,
    shape = 21,
    size = 3.2,
    stroke = 0.85
  ) +
  
  facet_wrap(
    ~ index,
    nrow = 1
  ) +
  
  scale_shape_manual(
    values = subplot_shapes,
    breaks = subplot_levels,
    name = "Plot"
  ) +
  
  labs(
    x =
      "UAV acquisition stage",
    
    y =
      "Directional asymmetry (%)"
  ) +
  
  theme_publication


figureS1_file <- file.path(
  figure_root,
  "Figure_S1_directional_asymmetry.png"
)


ggsave(
  filename = figureS1_file,
  plot = pS1,
  width = 10.6,
  height = 4.3,
  units = "in",
  dpi = 600,
  bg = "white"
)


# ============================================================
# FIGURE S2 — SUPPLEMENTARY
# DIRECTIONAL NORMALIZED RESPONSE CURVES
# ============================================================

response_nonzero <- response[
  response$perturb_cm != 0,
  ,
  drop = FALSE
]


response_nonzero$boundary_direction <- ifelse(
  response_nonzero$perturb_cm < 0,
  "Erosion",
  "Dilation"
)


response_zero <- response[
  response$perturb_cm == 0,
  ,
  drop = FALSE
]


response_zero_erosion <- response_zero

response_zero_erosion$boundary_direction <-
  "Erosion"


response_zero_dilation <- response_zero

response_zero_dilation$boundary_direction <-
  "Dilation"


response_curve <- rbind(
  response_nonzero,
  response_zero_erosion,
  response_zero_dilation
)


response_curve$boundary_direction <- factor(
  response_curve$boundary_direction,
  levels = direction_levels
)


response_curve <- response_curve[
  order(
    response_curve$growth_stage,
    response_curve$index,
    response_curve$subplot,
    response_curve$boundary_direction,
    response_curve$delta_mask_area_pct
  ),
]


pS2 <- ggplot(
  response_curve,
  
  aes(
    x =
      delta_mask_area_pct,
    
    y =
      delta_index_pct,
    
    group =
      interaction(
        subplot,
        boundary_direction
      ),
    
    linetype =
      boundary_direction,
    
    shape =
      subplot
  )
) +
  
  geom_hline(
    yintercept = 0,
    linewidth = 0.25
  ) +
  
  geom_vline(
    xintercept = 0,
    linewidth = 0.25
  ) +
  
  geom_line(
    linewidth = 0.38,
    alpha = 0.60
  ) +
  
  geom_point(
    size = 1.45,
    alpha = 0.78
  ) +
  
  facet_grid(
    index ~ growth_stage,
    scales = "free"
  ) +
  
  scale_shape_manual(
    values = subplot_shapes,
    breaks = subplot_levels,
    name = "Plot"
  ) +
  
  labs(
    x =
      "Relative change in segmented-mask area (%)",
    
    y =
      "Relative change in vegetation index (%)",
    
    linetype =
      "Boundary direction"
  ) +
  
  theme_publication


figureS2_file <- file.path(
  figure_root,
  "Figure_S2_directional_boundary_response_curves.png"
)


ggsave(
  filename = figureS2_file,
  plot = pS2,
  width = 11.8,
  height = 7.3,
  units = "in",
  dpi = 600,
  bg = "white"
)


# ------------------------------------------------------------
# 10. FINAL QA REPORT
# ------------------------------------------------------------

median_asymmetry <- median(
  direction$directional_asymmetry_pct,
  na.rm = TRUE
)


max_asymmetry <- max(
  direction$directional_asymmetry_pct,
  na.rm = TRUE
)


cat("\n")
cat("====================================================\n")
cat("FINAL BOUNDARY-SENSITIVITY FIGURES COMPLETED\n")
cat("====================================================\n")


cat(
  "Main figures: 2\n"
)


cat(
  "Supplementary figures: 2\n"
)


cat(
  "Combined-beta figure: intentionally not exported.\n"
)


cat(
  "Median directional asymmetry: ",
  sprintf(
    "%.2f%%",
    median_asymmetry
  ),
  "\n",
  sep = ""
)


cat(
  "Maximum directional asymmetry: ",
  sprintf(
    "%.2f%%",
    max_asymmetry
  ),
  "\n",
  sep = ""
)


cat("\nOutputs:\n")


output_files <- c(
  figure6_file,
  figure7_file,
  figureS1_file,
  figureS2_file
)


for (f in output_files) {
  
  cat(
    f,
    "\n"
  )
}


cat("\n")


cat(
  "No titles/subtitles are embedded in the image files.\n"
)


cat(
  "No inferential significance tests are displayed.\n"
)


cat(
  "P1-P5 remain visible as the five spatial observational units.\n"
)


# ============================================================
# END
# ============================================================


# ============================================================
# SUPPLEMENTARY MATERIALS: FIGURES + CAPTIONS IN ONE PDF
# ============================================================
# S1 and S2 remain separate 600-dpi PNG files above.
# The PDF is generated directly from pS1 and pS2 as vector
# graphics; captions are separate text below the figures.
# No new package dependency is introduced (grid is a base R package).

supplement_pdf_file <- file.path(
  figure_root,
  "Supplementary_Materials.pdf"
)

caption_S1 <- paste0(
  "Figure S1. Directional asymmetry in normalized canopy-boundary ",
  "sensitivity across UAV acquisitions and vegetation indices. ",
  "Directional asymmetry quantifies the relative difference between ",
  "the absolute erosion and dilation sensitivity coefficients for ",
  "each spatial observational unit (P1–P5). Large symbols represent ",
  "the median across plots and vertical bars indicate the ",
  "interquartile range. The metric is descriptive and is not ",
  "interpreted as an inferential or pass/fail robustness criterion."
)

caption_S2 <- paste0(
  "Figure S2. Direction-specific normalized spectral response to ",
  "controlled canopy-boundary perturbation across UAV acquisitions ",
  "and vegetation indices. Relative changes in vegetation-index ",
  "value are plotted against the corresponding relative changes in ",
  "segmented-mask area for inward erosion and outward dilation. ",
  "Each trajectory represents one spatial observational unit ",
  "(P1–P5), and the unperturbed condition is located at the origin ",
  "(ΔA = 0), (ΔVI = 0). Negative mask-area changes correspond to ",
  "erosion and positive changes to dilation. The trajectories ",
  "provide the underlying normalized responses from which the ",
  "direction-specific sensitivity coefficients were estimated. ",
  "Horizontal axis scales vary across acquisition stages, and ",
  "vertical axis scales vary across vegetation indices."
)

# Pages are landscape and large enough for the multi-panel S2.
# Cairo preserves Greek symbols and provides a vector PDF.
if (!capabilities("cairo")) {
  stop("Cairo PDF support is required for Unicode captions.")
}

grDevices::cairo_pdf(
  filename = supplement_pdf_file,
  width = 13.2,
  height = 9.8,
  onefile = TRUE,
  family = "sans",
  bg = "white"
)

# A caption uses typeset text outside the ggplot image.
draw_supplement_page <- function(plot, caption, kind) {

  grid::grid.newpage()

  # Preserve each figure's original plotting aspect ratio.
  plot_width_in <- 12.15
  plot_height_in <- if (kind == "S1") {
    plot_width_in * 4.3 / 10.6
  } else {
    plot_width_in * 7.3 / 11.8
  }

  # Allow S1 slightly more space above to balance the page.
  top_in <- if (kind == "S1") 8.65 else 9.43
  plot_center_y_in <- top_in - plot_height_in / 2

  grid::pushViewport(grid::viewport(
    x = grid::unit(6.6, "in"),
    y = grid::unit(plot_center_y_in, "in"),
    width = grid::unit(plot_width_in, "in"),
    height = grid::unit(plot_height_in, "in")
  ))
  grid::grid.draw(ggplot2::ggplotGrob(plot))
  grid::popViewport()

  caption_lines <- strwrap(caption, width = 142)
  caption_y_in <- top_in - plot_height_in - 0.22

  grid::grid.text(
    paste(caption_lines, collapse = "\n"),
    x = grid::unit(0.54, "in"),
    y = grid::unit(caption_y_in, "in"),
    just = c("left", "top"),
    gp = grid::gpar(
      fontsize = 10,
      fontfamily = "sans",
      lineheight = 1.28,
      col = "black"
    )
  )
}

tryCatch({
  draw_supplement_page(pS1, caption_S1, "S1")
  draw_supplement_page(pS2, caption_S2, "S2")
}, finally = {
  grDevices::dev.off()
})

if (!file.exists(supplement_pdf_file)) {
  stop("The Supplementary Materials PDF was not generated.")
}

cat("Supplementary PDF with captions: ", supplement_pdf_file, "\n", sep = "")
