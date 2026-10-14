# ============================================================
# 07_figure_6_final_grain_yield.R
#
# Manuscript Figure 6 — Final grain yield
#
# Purpose
# -------
# Generates the publication-ready point plot of final grain yield for
# the five plots distributed along the experimental N gradient.
#
# Input
# -----
#   data/common_bean_uav_master_dataset.csv
#
# Output
# ------
#   figures/Figure_6_final_grain_yield.png
#
# Notes
# -----
# Each point represents one plot associated with one N level.
# N levels were not independently replicated; no fitted model,
# interpolation, or dose-response relationship is implied.
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
# 3. READ DATA
# ------------------------------------------------------------

d <- read.csv(
  master_file,
  stringsAsFactors = FALSE,
  check.names = FALSE
)


# ------------------------------------------------------------
# 4. CHECK REQUIRED COLUMNS
# ------------------------------------------------------------

required_columns <- c(
  "plot",
  "N_rate_kg_ha",
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


# ------------------------------------------------------------
# 5. BUILD FINAL-YIELD TABLE
# ------------------------------------------------------------

harvest <- unique(
  d[
    ,
    c(
      "plot",
      "N_rate_kg_ha",
      "grain_yield_t_ha"
    )
  ]
)

harvest <- harvest[
  order(
    harvest$N_rate_kg_ha
  ),
]

if (nrow(harvest) != 5) {
  stop(
    "Expected 5 unique plot-level yield observations; found ",
    nrow(harvest)
  )
}


# ------------------------------------------------------------
# 6. X-AXIS LABELS
# ------------------------------------------------------------

harvest$plot_N <- paste0(
  harvest$plot,
  " / ",
  harvest$N_rate_kg_ha
)

harvest$plot_N <- factor(
  harvest$plot_N,
  levels = c(
    "P1 / 0",
    "P2 / 100",
    "P3 / 200",
    "P4 / 300",
    "P5 / 400"
  )
)


# ------------------------------------------------------------
# 7. VALUE LABELS
# ------------------------------------------------------------

harvest$yield_label <- sprintf(
  "%.2f",
  harvest$grain_yield_t_ha
)


# ------------------------------------------------------------
# 8. JOURNAL THEME
# ------------------------------------------------------------

theme_journal <- theme_classic(
  base_size = 11
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
    
    # Soft horizontal grid only
    panel.grid.major.y = element_line(
      color = "grey90",
      linewidth = 0.30
    ),
    
    panel.grid.major.x = element_blank(),
    
    panel.grid.minor = element_blank(),
    
    # Axis text
    axis.text = element_text(
      color = "black",
      size = 10.5
    ),
    
    axis.title = element_text(
      color = "black",
      size = 11.5
    ),
    
    axis.line = element_line(
      color = "black",
      linewidth = 0.50
    ),
    
    axis.ticks = element_line(
      color = "black",
      linewidth = 0.40
    ),
    
    axis.title.x = element_text(
      margin = margin(
        t = 8
      )
    ),
    
    axis.title.y = element_text(
      margin = margin(
        r = 8
      )
    ),
    
    plot.margin = margin(
      8,
      10,
      8,
      8
    )
  )


# ------------------------------------------------------------
# 9. BUILD FIGURE
# ------------------------------------------------------------

fig6 <- ggplot(
  harvest,
  aes(
    x = plot_N,
    y = grain_yield_t_ha
  )
) +
  
  # Observed values only
  geom_point(
    size = 2.8,
    color = "black"
  ) +
  
  # Observed yield values
  geom_text(
    aes(
      label = yield_label
    ),
    nudge_y = 0.055,
    size = 3.6,
    color = "black"
  ) +
  
  scale_y_continuous(
    limits = c(
      0.8,
      2.1
    ),
    breaks = c(
      0.9,
      1.2,
      1.5,
      1.8,
      2.1
    ),
    expand = expansion(
      mult = c(
        0,
        0
      )
    )
  ) +
  
  labs(
    x = expression(
      "Plot / N rate (kg N " * ha^-1 * ")"
    ),
    y = expression(
      "Final grain yield (t " * ha^-1 * ")"
    )
  ) +
  
  theme_journal


# ------------------------------------------------------------
# 10. EXPORT PNG ONLY
# ------------------------------------------------------------

png_file <- file.path(
  figure_root,
  "Figure_6_final_grain_yield.png"
)

ggsave(
  filename = png_file,
  plot = fig6,
  width = 7.2,
  height = 4.6,
  units = "in",
  dpi = 600,
  bg = "white"
)


# ------------------------------------------------------------
# 11. CONSOLE REPORT
# ------------------------------------------------------------

cat("\n")
cat("====================================================\n")
cat("FINAL GRAIN YIELD FIGURE COMPLETED\n")
cat("====================================================\n\n")

cat(
  "PNG: ",
  png_file,
  "\n",
  sep = ""
)

cat(
  "\nEach point represents one plot associated with one N level.\n"
)

cat(
  "No fitted model, interpolation, or dose-response relationship is shown.\n"
)


# ============================================================
# END
# ============================================================