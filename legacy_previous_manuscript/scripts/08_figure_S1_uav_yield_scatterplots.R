# ============================================================
# 08_figure_S1_uav_yield_scatterplots.R
#
# Supplementary Figure S1
# Stage-specific UAV metric–yield scatterplots
#
# Columns: V4, R5, R6, R7, R8
# Rows:
#   1) Projected canopy area
#   2) NDVI
#   3) MSAVI
#   4) WDRVI
#
# Each panel contains exactly five independent field plots (P1–P5).
# Plot identity is encoded redundantly by color + shape.
# Pearson r and n = 5 are shown descriptively.
# A thin grey least-squares line is included only as a visual guide.
# No p-values or confidence intervals are shown.
#
# Output:
#   figures/Figure_S1_UAV_yield_scatterplots.png
#
# PNG output only.
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

missing_packages <- required_packages[
  !vapply(
    required_packages,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]

if (length(missing_packages) > 0) {
  stop(
    "Missing required package(s): ",
    paste(missing_packages, collapse = ", "),
    "\nInstall once with:\ninstall.packages(c(",
    paste(
      sprintf('"%s"', missing_packages),
      collapse = ", "
    ),
    "))"
  )
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
# 3. READ MASTER DATASET
# ------------------------------------------------------------

d <- read.csv(
  master_file,
  stringsAsFactors = FALSE,
  check.names = FALSE
)


# ------------------------------------------------------------
# 4. DATA-INTEGRITY CHECKS
# ------------------------------------------------------------

required_columns <- c(
  "growth_stage",
  "plot",
  "N_rate_kg_ha",
  "canopy_area_m2",
  "NDVI_mean",
  "MSAVI_mean",
  "WDRVI_mean",
  "grain_yield_t_ha"
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
    "Expected 25 plot × stage records; found ",
    nrow(d)
  )
}

stage_levels <- c(
  "V4",
  "R5",
  "R6",
  "R7",
  "R8"
)

plot_levels <- c(
  "P1",
  "P2",
  "P3",
  "P4",
  "P5"
)

if (!all(stage_levels %in% unique(d$growth_stage))) {
  stop(
    "Expected growth stages V4, R5, R6, R7, and R8."
  )
}

if (!all(plot_levels %in% unique(d$plot))) {
  stop(
    "Expected plots P1, P2, P3, P4, and P5."
  )
}

if (any(table(d$growth_stage)[stage_levels] != 5)) {
  stop(
    "Each growth stage must contain exactly five plot records."
  )
}

for (p in plot_levels) {

  z <- d[d$plot == p, ]

  if (length(unique(z$grain_yield_t_ha)) != 1) {
    stop(
      "Final grain yield is not constant across repeated observations for ",
      p
    )
  }
}

d$growth_stage <- factor(
  d$growth_stage,
  levels = stage_levels
)

d$plot <- factor(
  d$plot,
  levels = plot_levels
)


# ------------------------------------------------------------
# 5. COMMON Y-AXIS
# ------------------------------------------------------------

yield_range <- range(
  d$grain_yield_t_ha,
  na.rm = TRUE
)

yield_padding <- diff(yield_range) * 0.10

yield_limits <- c(
  yield_range[1] - yield_padding,
  yield_range[2] + yield_padding
)

yield_breaks <- seq(
  1.0,
  2.0,
  by = 0.25
)


# ------------------------------------------------------------
# 6. PLOT SHAPES AND COLORS
# ------------------------------------------------------------
# Plot identity is encoded by shape + categorical color.
# Colors are NOT intended to represent an ordinal nitrogen-rate scale.

plot_shapes <- c(
  P1 = 21,
  P2 = 22,
  P3 = 23,
  P4 = 24,
  P5 = 25
)

plot_colors <- c(
  P1 = "#0072B2",  # blue
  P2 = "#E69F00",  # orange
  P3 = "#009E73",  # bluish green
  P4 = "#D55E00",  # vermillion
  P5 = "#CC79A7"   # reddish purple
)


# ------------------------------------------------------------
# 7. HELPER FUNCTION
# ------------------------------------------------------------

build_metric_row <- function(
  data,
  variable,
  x_label,
  show_stage_headers = FALSE,
  show_legend = FALSE
) {

  z <- data[
    ,
    c(
      "growth_stage",
      "plot",
      "grain_yield_t_ha",
      variable
    )
  ]

  names(z)[4] <- "x_value"


  # ----------------------------------------------------------
  # Stage-specific descriptive Pearson correlations
  # ----------------------------------------------------------

  r_rows <- lapply(
    stage_levels,
    function(stage) {

      zz <- z[
        z$growth_stage == stage,
      ]

      if (nrow(zz) != 5) {
        stop(
          "Expected n = 5 for ",
          variable,
          " at ",
          stage
        )
      }

      r_value <- cor(
        zz$x_value,
        zz$grain_yield_t_ha,
        method = "pearson",
        use = "complete.obs"
      )

      data.frame(
        growth_stage = factor(
          stage,
          levels = stage_levels
        ),
        r_label = sprintf(
          'italic(r) == "%0.2f" * ";" ~~ italic(n) == 5',
          r_value
        ),
        stringsAsFactors = FALSE
      )
    }
  )

  r_data <- do.call(
    rbind,
    r_rows
  )


  # ----------------------------------------------------------
  # BUILD METRIC ROW
  # ----------------------------------------------------------

  p <- ggplot(
    z,
    aes(
      x = x_value,
      y = grain_yield_t_ha
    )
  ) +

    # Descriptive least-squares fit only.
    # It is intentionally subtle and has no confidence band.
    geom_smooth(
      method = "lm",
      formula = y ~ x,
      se = FALSE,
      linewidth = 0.35,
      color = "grey65",
      linetype = "solid"
    ) +

    # Five independent plot-level observations
    geom_point(
      aes(
        shape = plot,
        fill = plot
      ),
      size = 3.25,
      stroke = 0.70,
      color = "black"
    ) +

    # Stage-specific descriptive Pearson r and effective sample size
    geom_text(
      data = r_data,
      aes(
        x = -Inf,
        y = Inf,
        label = r_label
      ),
      inherit.aes = FALSE,
      parse = TRUE,
      hjust = -0.10,
      vjust = 1.20,
      size = 3.0,
      color = "black"
    ) +

    facet_wrap(
      ~ growth_stage,
      nrow = 1
    ) +

    scale_shape_manual(
      values = plot_shapes,
      breaks = plot_levels,
      name = "Plot"
    ) +

    scale_fill_manual(
      values = plot_colors,
      breaks = plot_levels,
      name = "Plot"
    ) +

    scale_y_continuous(
      limits = yield_limits,
      breaks = yield_breaks,
      expand = expansion(
        mult = c(
          0.02,
          0.04
        )
      )
    ) +

    scale_x_continuous(
      expand = expansion(
        mult = c(
          0.08,
          0.08
        )
      )
    ) +

    labs(
      x = x_label,
      y = NULL
    ) +

    # Single legend showing the exact color + shape combination
    # used for each plot in the panels.
    guides(
      shape = "none",
      fill = guide_legend(
        title = "Plot",
        order = 1,
        override.aes = list(
          shape = unname(plot_shapes[plot_levels]),
          color = "black",
          size = 3.5,
          stroke = 0.70
        )
      )
    ) +

    theme_classic(
      base_size = 10
    ) +

    theme(
      plot.background = element_rect(
        fill = "white",
        color = NA
      ),

      panel.background = element_rect(
        fill = "white",
        color = NA
      ),

      panel.grid = element_blank(),

      axis.line = element_line(
        linewidth = 0.35,
        color = "black"
      ),

      axis.ticks = element_line(
        linewidth = 0.30,
        color = "black"
      ),

      axis.text = element_text(
        color = "black",
        size = 8.5
      ),

      axis.title.x = element_text(
        color = "black",
        size = 10,
        face = "bold",
        margin = margin(
          t = 5
        )
      ),

      axis.title.y = element_blank(),

      strip.background = if (show_stage_headers) {
        element_rect(
          fill = "white",
          color = "black",
          linewidth = 0.35
        )
      } else {
        element_blank()
      },

      strip.text = if (show_stage_headers) {
        element_text(
          color = "black",
          size = 10,
          face = "bold"
        )
      } else {
        element_blank()
      },

      legend.position = if (show_legend) {
        "bottom"
      } else {
        "none"
      },

      legend.title = element_text(
        size = 9.5,
        face = "bold"
      ),

      legend.text = element_text(
        size = 9
      ),

      legend.key = element_blank(),

      panel.spacing.x = unit(
        0.55,
        "lines"
      ),

      plot.margin = margin(
        t = 2,
        r = 4,
        b = 3,
        l = 2
      )
    )

  return(p)
}


# ------------------------------------------------------------
# 8. BUILD THE FOUR METRIC ROWS
# ------------------------------------------------------------

p_canopy <- build_metric_row(
  data = d,
  variable = "canopy_area_m2",
  x_label = expression(
    "Projected canopy area (m"^2*")"
  ),
  show_stage_headers = TRUE,
  show_legend = FALSE
)

p_ndvi <- build_metric_row(
  data = d,
  variable = "NDVI_mean",
  x_label = "Mean NDVI",
  show_stage_headers = FALSE,
  show_legend = FALSE
)

p_msavi <- build_metric_row(
  data = d,
  variable = "MSAVI_mean",
  x_label = "Mean MSAVI",
  show_stage_headers = FALSE,
  show_legend = FALSE
)

p_wdrvi <- build_metric_row(
  data = d,
  variable = "WDRVI_mean",
  x_label = "Mean WDRVI",
  show_stage_headers = FALSE,
  show_legend = TRUE
)


# ------------------------------------------------------------
# 9. COMBINE THE FOUR METRIC ROWS
# ------------------------------------------------------------

main_panel <- (
  p_canopy /
  p_ndvi /
  p_msavi /
  p_wdrvi
) +
  plot_layout(
    heights = c(
      1,
      1,
      1,
      1.12
    ),
    guides = "collect"
  ) &
  theme(
    legend.position = "bottom"
  )


# ------------------------------------------------------------
# 10. SHARED Y-AXIS TITLE
# ------------------------------------------------------------

shared_y_title <- patchwork::wrap_elements(
  full = grid::textGrob(
    expression(
      "Final grain yield (t ha"^{-1}*")"
    ),
    rot = 90,
    gp = grid::gpar(
      fontsize = 10.5
    )
  )
)


# ------------------------------------------------------------
# 11. FINAL FIGURE
# ------------------------------------------------------------

fig_S1 <- (
  shared_y_title |
  main_panel
) +
  plot_layout(
    widths = c(
      0.025,
      1
    )
  )


# ------------------------------------------------------------
# 12. EXPORT PNG ONLY
# ------------------------------------------------------------

png_file <- file.path(
  figure_root,
  "Figure_S1_UAV_yield_scatterplots.png"
)

ggsave(
  filename = png_file,
  plot = fig_S1,
  width = 11.5,
  height = 9.5,
  units = "in",
  dpi = 600,
  bg = "white"
)


# ------------------------------------------------------------
# 13. QA REPORT
# ------------------------------------------------------------

cat("\n")
cat("====================================================\n")
cat("SUPPLEMENTARY FIGURE S1 COMPLETED\n")
cat("====================================================\n\n")

cat("Columns = V4, R5, R6, R7, R8\n")
cat("Rows = Projected canopy area, NDVI, MSAVI, WDRVI\n\n")

cat(
  "PNG: ",
  png_file,
  "\n\n",
  sep = ""
)

cat("Each panel contains n = 5 independent plots.\n")
cat("Plot identity is encoded by color + shape.\n")
cat("The legend reproduces the same color + shape combinations.\n")
cat("Colors are categorical and do not represent an ordinal N-rate scale.\n")
cat("Pearson r is descriptive and exploratory only.\n")
cat("Thin grey lines are descriptive least-squares fits only.\n")
cat("No p-values or confidence intervals are displayed.\n")


# ============================================================
# END
# ============================================================