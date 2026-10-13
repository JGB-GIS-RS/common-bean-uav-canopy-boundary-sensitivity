# ============================================================
# 06_figure_5_uav_yield_correlations.R
#
# Manuscript Figure 5 — Stage-specific UAV-yield correlations
#
# Purpose
# -------
# Generates the publication-ready heatmap of exploratory Pearson
# correlations between UAV-derived metrics and final grain yield.
#
# Rows, top to bottom
# -------------------
#   Projected canopy area
#   NDVI
#   MSAVI
#   WDRVI
#
# Columns
# -------
#   V4, R5, R6, R7, R8
#
# Input
# -----
#   derived/exploratory_yield_associations_by_flight.csv
#
# Output
# ------
#   figures/Figure_5_UAV_yield_associations.png
#
# Notes
# -----
# Correlations are stage-specific, descriptive, and exploratory.
# Each coefficient is based on the five plots (n = 5 per stage).
# ============================================================


rm(list = ls())
gc()


# ------------------------------------------------------------
# 1. REQUIRED PACKAGE
# ------------------------------------------------------------

if (!requireNamespace("ggplot2", quietly = TRUE)) {
  stop(
    "Package 'ggplot2' is required.\n",
    "Install it once with:\n",
    "install.packages('ggplot2')"
  )
}

library(ggplot2)


# ------------------------------------------------------------
# 2. PROJECT PATHS
# ------------------------------------------------------------

project_root <- "C:/common-bean-uav-nitrogen-gradient"

yield_assoc_file <- file.path(
  project_root,
  "derived",
  "exploratory_yield_associations_by_flight.csv"
)

figure_root <- file.path(
  project_root,
  "figures"
)

if (!file.exists(yield_assoc_file)) {
  stop(
    "Missing yield-association table:\n",
    yield_assoc_file
  )
}

if (!dir.exists(figure_root)) {
  dir.create(
    figure_root,
    recursive = TRUE
  )
}


# ------------------------------------------------------------
# 3. READ DATA
# ------------------------------------------------------------

yield_assoc <- read.csv(
  yield_assoc_file,
  stringsAsFactors = FALSE,
  check.names = FALSE
)


# ------------------------------------------------------------
# 4. CHECK REQUIRED COLUMNS
# ------------------------------------------------------------

required_columns <- c(
  "growth_stage",
  "UAV_variable",
  "pearson_r"
)

missing_columns <- setdiff(
  required_columns,
  names(yield_assoc)
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
# 5. ORDER GROWTH STAGES
# ------------------------------------------------------------

stage_levels <- c(
  "V4",
  "R5",
  "R6",
  "R7",
  "R8"
)

yield_assoc$growth_stage <- factor(
  yield_assoc$growth_stage,
  levels = stage_levels
)


# ------------------------------------------------------------
# 6. VARIABLE LABELS
# ------------------------------------------------------------

variable_labels <- c(
  canopy_area_m2 = "Projected canopy area",
  NDVI_mean      = "NDVI",
  MSAVI_mean     = "MSAVI",
  WDRVI_mean     = "WDRVI"
)

yield_assoc$variable_label <- unname(
  variable_labels[
    yield_assoc$UAV_variable
  ]
)

if (any(is.na(yield_assoc$variable_label))) {
  stop(
    "One or more UAV_variable values do not match the expected variables:\n",
    paste(
      unique(
        yield_assoc$UAV_variable[
          is.na(yield_assoc$variable_label)
        ]
      ),
      collapse = ", "
    )
  )
}


# ------------------------------------------------------------
# 7. ROW ORDER
# ------------------------------------------------------------
#
# ggplot draws the first factor level at the bottom.
# Therefore, levels are intentionally reversed so the displayed
# order from TOP to BOTTOM is:
#
# Projected canopy area
# NDVI
# MSAVI
# WDRVI
# ------------------------------------------------------------

yield_assoc$variable_label <- factor(
  yield_assoc$variable_label,
  levels = c(
    "WDRVI",
    "MSAVI",
    "NDVI",
    "Projected canopy area"
  )
)


# ------------------------------------------------------------
# 8. CORRELATION LABELS
# ------------------------------------------------------------

yield_assoc$r_label <- sprintf(
  "%.2f",
  yield_assoc$pearson_r
)


# ------------------------------------------------------------
# 9. JOURNAL THEME
# ------------------------------------------------------------

theme_heatmap <- theme_classic(
  base_size = 11
) +
  theme(
    
    # Background
    plot.background = element_rect(
      fill = "white",
      color = NA
    ),
    
    panel.background = element_rect(
      fill = "white",
      color = NA
    ),
    
    # Heatmap does not require conventional axis lines/ticks
    axis.line = element_blank(),
    axis.ticks = element_blank(),
    panel.grid = element_blank(),
    
    # X axis
    axis.text.x = element_text(
      color = "black",
      size = 11
    ),
    
    axis.title.x = element_text(
      color = "black",
      size = 12,
      margin = margin(
        t = 7
      )
    ),
    
    # Y axis
    axis.text.y = element_text(
      color = "black",
      size = 11,
      face = "bold",
      margin = margin(
        r = 5
      )
    ),
    
    axis.title.y = element_blank(),
    
    # Legend
    legend.position = "right",
    
    legend.title = element_text(
      color = "black",
      size = 11,
      face = "bold"
    ),
    
    legend.text = element_text(
      color = "black",
      size = 10
    ),
    
    legend.background = element_rect(
      fill = "white",
      color = NA
    ),
    
    legend.key = element_rect(
      fill = "white",
      color = NA
    ),
    
    # Reduce distance between heatmap and legend
    legend.box.spacing = unit(
      0.05,
      "cm"
    ),
    
    legend.margin = margin(
      t = 0,
      r = 0,
      b = 0,
      l = 0
    ),
    
    # Compact outer margins
    plot.margin = margin(
      t = 6,
      r = 2,
      b = 6,
      l = 6
    )
  )


# ------------------------------------------------------------
# 10. BUILD HEATMAP
# ------------------------------------------------------------

fig_heatmap <- ggplot(
  yield_assoc,
  aes(
    x = growth_stage,
    y = variable_label,
    fill = pearson_r
  )
) +
  
  # White separators between cells
  geom_tile(
    color = "white",
    linewidth = 0.8
  ) +
  
  # Pearson correlation coefficient inside each cell
  geom_text(
    aes(
      label = r_label
    ),
    color = "black",
    size = 4.4,
    fontface = "bold"
  ) +
  
  # Diverging correlation scale centered at zero
  scale_fill_gradient2(
    low = "#3B4CC0",
    mid = "white",
    high = "#B40426",
    midpoint = 0,
    limits = c(
      -1,
      1
    ),
    breaks = c(
      -1,
      -0.5,
      0,
      0.5,
      1
    ),
    name = expression(
      "Pearson " * italic(r)
    )
  ) +
  
  labs(
    x = "Growth stage",
    y = NULL
  ) +
  
  theme_heatmap +
  
  guides(
    fill = guide_colorbar(
      title.position = "top",
      title.hjust = 0.5,
      
      # Compact but fully legible color bar
      barheight = unit(
        40,
        "mm"
      ),
      
      barwidth = unit(
        5.5,
        "mm"
      ),
      
      ticks = TRUE,
      
      frame.colour = "grey60",
      frame.linewidth = 0.25
    )
  )


# ------------------------------------------------------------
# 11. EXPORT PNG ONLY
# ------------------------------------------------------------

png_file <- file.path(
  figure_root,
  "Figure_5_UAV_yield_associations.png"
)

ggsave(
  filename = png_file,
  plot = fig_heatmap,
  width = 7.4,
  height = 4.6,
  units = "in",
  dpi = 600,
  bg = "white"
)


# ------------------------------------------------------------
# 12. CONSOLE REPORT
# ------------------------------------------------------------

cat("\n")
cat("====================================================\n")
cat("UAV-YIELD ASSOCIATION HEATMAP COMPLETED\n")
cat("====================================================\n\n")

cat(
  "PNG: ",
  png_file,
  "\n",
  sep = ""
)

cat(
  "\nDisplayed row order:\n",
  "Projected canopy area -> NDVI -> MSAVI -> WDRVI\n"
)

cat(
  "\nCorrelations are descriptive and exploratory.\n"
)

cat(
  "Each stage-specific correlation is based on n = 5 plots.\n"
)

# ============================================================
# END
# ============================================================