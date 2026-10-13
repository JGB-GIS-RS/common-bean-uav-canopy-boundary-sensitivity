# ============================================================
# 05_figure_4_multitemporal_uav_metrics.R
#
# Manuscript Figure 4 — Multitemporal UAV-derived metrics
#
# Purpose
# -------
# Generates the publication-ready four-panel figure showing structural
# and spectral trajectories across common-bean growth stages V4-R8.
#
# Panels
# ------
#   (a) Projected canopy area
#   (b) Mean NDVI
#   (c) Mean MSAVI
#   (d) Mean WDRVI
#
# Input
# -----
#   data/common_bean_uav_master_dataset.csv
#
# Output
# ------
#   figures/Figure_4_multitemporal_UAV_response.png
#
# Notes
# -----
# Each trajectory represents one plot associated with one N level.
# Plot identifiers P1-P5 are shown directly in panel (a).
# The legend links each plot identifier to its associated N rate.
# The figure is descriptive and does not imply replicated
# treatment-level inference.
# ============================================================


rm(list = ls())
gc()


# ------------------------------------------------------------
# 1. REQUIRED PACKAGES
# ------------------------------------------------------------

required_packages <- c(
  "ggplot2",
  "patchwork"
)

for (pkg in required_packages) {
  
  if (!requireNamespace(pkg, quietly = TRUE)) {
    
    stop(
      "Package '", pkg, "' is required.\n",
      "Install it once with:\n",
      "install.packages('", pkg, "')"
    )
  }
}

library(ggplot2)
library(patchwork)


# ------------------------------------------------------------
# 2. PROJECT PATHS
# ------------------------------------------------------------

project_root <- "C:/common-bean-uav-nitrogen-gradient"

master_file <- file.path(
  project_root,
  "data",
  "common_bean_uav_master_dataset.csv"
)

figure_root <- file.path(
  project_root,
  "figures"
)

if (!file.exists(master_file)) {
  
  stop(
    "Missing master dataset:\n",
    master_file
  )
}

if (!dir.exists(figure_root)) {
  
  dir.create(
    figure_root,
    recursive = TRUE
  )
}


# ------------------------------------------------------------
# 3. READ AND CHECK DATA
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
  "NDVI_mean",
  "MSAVI_mean",
  "WDRVI_mean"
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

if (nrow(d) != 25) {
  
  stop(
    "Expected 25 rows; found ",
    nrow(d)
  )
}


# ------------------------------------------------------------
# 4. ORDERING AND LABELS
# ------------------------------------------------------------

stage_levels <- c(
  "V4",
  "R5",
  "R6",
  "R7",
  "R8"
)

stage_date_labels <- c(
  V4 = "V4\n7 Sep",
  R5 = "R5\n14 Sep",
  R6 = "R6\n2 Oct",
  R7 = "R7\n9 Oct",
  R8 = "R8\n16 Oct"
)

d$growth_stage <- factor(
  d$growth_stage,
  levels = stage_levels
)

# Legend entries explicitly link P1-P5
# with their associated N rates.
d$plot_N <- factor(
  paste0(
    d$plot,
    ": ",
    d$N_rate_kg_ha
  ),
  levels = c(
    "P1: 0",
    "P2: 100",
    "P3: 200",
    "P4: 300",
    "P5: 400"
  )
)


# ------------------------------------------------------------
# 5. LEGEND AND SYMBOLS
# ------------------------------------------------------------

legend_title <- expression(
  "N rate (kg N " * ha^-1 * ")"
)

# Second visual encoding in addition to color.
# P5 uses an open circle instead of a cross to avoid
# confusion with error bars or uncertainty symbols.
plot_shapes <- c(
  "P1: 0"   = 16,  # filled circle
  "P2: 100" = 17,  # filled triangle
  "P3: 200" = 15,  # filled square
  "P4: 300" = 18,  # filled diamond
  "P5: 400" = 1    # open circle
)


# ------------------------------------------------------------
# 6. COMMON JOURNAL THEME
# ------------------------------------------------------------

theme_journal <- theme_classic(
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
    
    # Soft horizontal grid only
    panel.grid.major.y = element_line(
      color = "grey88",
      linewidth = 0.35
    ),
    
    panel.grid.major.x = element_blank(),
    
    panel.grid.minor = element_blank(),
    
    # Axes
    axis.text = element_text(
      color = "black",
      size = 10
    ),
    
    axis.title = element_text(
      color = "black",
      size = 11
    ),
    
    axis.line = element_line(
      color = "black",
      linewidth = 0.50
    ),
    
    axis.ticks = element_line(
      color = "black",
      linewidth = 0.40
    ),
    
    # Panel identifiers
    plot.title = element_text(
      face = "bold",
      color = "black",
      size = 11.5,
      hjust = 0,
      margin = margin(
        b = 4
      )
    ),
    
    # Legend
    legend.background = element_rect(
      fill = "white",
      color = NA
    ),
    
    legend.key = element_rect(
      fill = "white",
      color = NA
    ),
    
    legend.title = element_text(
      face = "bold",
      color = "black",
      size = 10
    ),
    
    legend.text = element_text(
      color = "black",
      size = 9.5
    ),
    
    legend.spacing.x = unit(
      0.20,
      "cm"
    ),
    
    # Slightly wider right margin to accommodate
    # direct P1-P5 labels in panel (a)
    plot.margin = margin(
      5,
      16,
      5,
      5
    )
  )


# ------------------------------------------------------------
# 7. FUNCTION TO BUILD EACH PANEL
# ------------------------------------------------------------

make_panel <- function(
    data,
    y_variable,
    y_label,
    panel_label,
    add_plot_labels = FALSE
) {
  
  p <- ggplot(
    data,
    aes(
      x = growth_stage,
      y = .data[[y_variable]],
      group = plot,
      color = plot_N,
      shape = plot_N
    )
  ) +
    
    geom_line(
      linewidth = 0.80,
      alpha = 0.95
    ) +
    
    geom_point(
      size = 2.8,
      stroke = 0.9
    ) +
    
    # Sequential, perceptually ordered palette
    scale_color_viridis_d(
      option = "D",
      end = 0.90,
      name = legend_title
    ) +
    
    # Different point shape for each plot / N-rate combination
    scale_shape_manual(
      values = plot_shapes,
      name = legend_title
    ) +
    
    scale_x_discrete(
      labels = stage_date_labels,
      expand = expansion(
        add = c(
          0.20,
          0.80
        )
      )
    ) +
    
    scale_y_continuous(
      expand = expansion(
        mult = c(
          0.05,
          0.10
        )
      )
    ) +
    
    labs(
      title = panel_label,
      x = "Growth stage / UAV acquisition date",
      y = y_label
    ) +
    
    coord_cartesian(
      clip = "off"
    ) +
    
    theme_journal +
    
    guides(
      
      color = guide_legend(
        title.position = "top",
        title.hjust = 0.5,
        nrow = 1,
        byrow = TRUE
      ),
      
      shape = guide_legend(
        title.position = "top",
        title.hjust = 0.5,
        nrow = 1,
        byrow = TRUE
      )
    )
  
  
  # ----------------------------------------------------------
  # Direct P1-P5 labels for panel (a)
  # ----------------------------------------------------------
  
  if (add_plot_labels) {
    
    label_data <- data[
      data$growth_stage == "R8",
      ,
      drop = FALSE
    ]
    
    # Start from the observed R8 canopy-area value
    label_data$label_y <- label_data[[y_variable]]
    
    # Manual vertical offsets to avoid label overlap.
    #
    # P5 is moved upward and P3 downward.
    # P2 is moved upward and P1 downward.
    # P4 requires only a small upward adjustment.
    
    label_data$label_y[
      label_data$plot == "P1"
    ] <- label_data$label_y[
      label_data$plot == "P1"
    ] - 0.45
    
    label_data$label_y[
      label_data$plot == "P2"
    ] <- label_data$label_y[
      label_data$plot == "P2"
    ] + 0.40
    
    label_data$label_y[
      label_data$plot == "P3"
    ] <- label_data$label_y[
      label_data$plot == "P3"
    ] - 0.35
    
    label_data$label_y[
      label_data$plot == "P4"
    ] <- label_data$label_y[
      label_data$plot == "P4"
    ] + 0.10
    
    label_data$label_y[
      label_data$plot == "P5"
    ] <- label_data$label_y[
      label_data$plot == "P5"
    ] + 0.45
    
    
    p <- p +
      
      geom_text(
        data = label_data,
        aes(
          x = growth_stage,
          y = label_y,
          label = plot,
          color = plot_N
        ),
        inherit.aes = FALSE,
        nudge_x = 0.18,
        hjust = 0,
        size = 3.4,
        fontface = "bold",
        show.legend = FALSE
      )
  }
  
  
  p
}


# ------------------------------------------------------------
# 8. BUILD THE FOUR PANELS
# ------------------------------------------------------------

p_a <- make_panel(
  data = d,
  y_variable = "canopy_area_m2",
  y_label = expression(
    "Projected canopy area (" * m^2 * ")"
  ),
  panel_label = "(a)",
  add_plot_labels = TRUE
)


p_b <- make_panel(
  data = d,
  y_variable = "NDVI_mean",
  y_label = "Mean NDVI",
  panel_label = "(b)"
)


p_c <- make_panel(
  data = d,
  y_variable = "MSAVI_mean",
  y_label = "Mean MSAVI",
  panel_label = "(c)"
)


p_d <- make_panel(
  data = d,
  y_variable = "WDRVI_mean",
  y_label = "Mean WDRVI",
  panel_label = "(d)"
)


# ------------------------------------------------------------
# 9. COMBINE PANELS
# ------------------------------------------------------------

fig_multitemporal <- (
  p_a + p_b +
    p_c + p_d
) +
  
  plot_layout(
    ncol = 2,
    guides = "collect",
    axes = "collect_x",
    axis_titles = "collect_x"
  ) &
  
  theme(
    legend.position = "bottom"
  )


# ------------------------------------------------------------
# 10. EXPORT PNG ONLY
# ------------------------------------------------------------

png_file <- file.path(
  figure_root,
  "Figure_4_multitemporal_UAV_response.png"
)

ggsave(
  filename = png_file,
  plot = fig_multitemporal,
  width = 8.8,
  height = 6.5,
  units = "in",
  dpi = 600,
  bg = "white"
)


# ------------------------------------------------------------
# 11. CONSOLE REPORT
# ------------------------------------------------------------

cat("\n")
cat("====================================================\n")
cat("MULTITEMPORAL UAV FIGURE COMPLETED\n")
cat("====================================================\n\n")

cat(
  "PNG: ",
  png_file,
  "\n",
  sep = ""
)

cat(
  "\nEach line represents one plot / N-rate combination.\n"
)

cat(
  "P1-P5 are labeled directly in panel (a).\n"
)

cat(
  "The legend identifies the N rate associated with each plot.\n"
)

cat(
  "Color and point shape identify the same plot / N-rate combination across panels.\n"
)

cat(
  "No treatment-level inference is implied by the figure.\n"
)


# ============================================================
# END
# ============================================================