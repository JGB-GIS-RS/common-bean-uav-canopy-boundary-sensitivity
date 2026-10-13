# =========================================================
# Figure 5. Geometric consequences of canopy-boundary perturbation
#
# Layout:
#   Top row:       V4 | R5
#   Bottom row: R6 | R7 | R8
#
# All five panels:
#   - identical physical width
#   - identical x-scale (-3 to +3 cm)
#   - identical y-scale (-100 to 150 %)
#
# Global elements:
#   - one common x-axis title
#   - one common y-axis title
#   - one common legend
#
# Secondary reference guides:
#   Y = -50, 50, 100, 150 %
#   X = -2, +2 cm
#
# Input:
#   boundary_geometry_qa.csv
#
# Output:
#   - Figure_5_geometric_consequences_boundary_perturbation.png
#   - Figure_5_geometric_consequences_boundary_perturbation.pdf
# =========================================================


rm(list = ls())


# -----------------------------
# Packages
# -----------------------------

library(readr)
library(dplyr)
library(ggplot2)
library(stringr)
library(patchwork)
library(grid)


# -----------------------------
# Paths
# -----------------------------

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

input_file <- file.path(
  project_root,
  "derived",
  "boundary_sensitivity",
  "boundary_geometry_qa.csv"
)

figure_root <- file.path(
  project_root,
  "figures"
)

if (!dir.exists(figure_root)) {
  dir.create(
    figure_root,
    recursive = TRUE
  )
}

output_png <- file.path(
  figure_root,
  "Figure_5_geometric_consequences_boundary_perturbation.png"
)

output_pdf <- file.path(
  figure_root,
  "Figure_5_geometric_consequences_boundary_perturbation.pdf"
)

if (!file.exists(input_file)) {
  stop(
    "Missing input file:\n",
    input_file
  )
}


# -----------------------------
# Helper to find candidate columns
# -----------------------------

pick_col <- function(df, candidates) {
  
  hit <- candidates[candidates %in% names(df)]
  
  if (length(hit) == 0) {
    return(NA_character_)
  }
  
  hit[1]
}


# -----------------------------
# Read data
# -----------------------------

geom_df <- read_csv(
  input_file,
  show_col_types = FALSE
)


# -----------------------------
# Detect column names robustly
# -----------------------------

stage_col <- pick_col(
  geom_df,
  c(
    "growth_stage",
    "stage",
    "uav_stage"
  )
)

plot_col <- pick_col(
  geom_df,
  c(
    "subplot",
    "plot",
    "spatial_unit"
  )
)

pert_col <- pick_col(
  geom_df,
  c(
    "perturb_cm",
    "boundary_shift_cm",
    "distance_cm"
  )
)

delta_col <- pick_col(
  geom_df,
  c(
    "area_change_pct",
    "delta_area_pct",
    "relative_area_change_pct"
  )
)


# -----------------------------
# Basic checks
# -----------------------------

required_cols <- c(
  stage_col,
  plot_col,
  pert_col,
  delta_col
)

if (any(is.na(required_cols))) {
  
  stop(
    "Missing one or more required columns.\n",
    "Detected:\n",
    "  growth stage = ", stage_col, "\n",
    "  plot         = ", plot_col, "\n",
    "  perturbation = ", pert_col, "\n",
    "  delta area   = ", delta_col, "\n"
  )
}


# -----------------------------
# Prepare data
# -----------------------------

plot_levels <- c(
  "P1",
  "P2",
  "P3",
  "P4",
  "P5"
)

stage_levels <- c(
  "V4",
  "R5",
  "R6",
  "R7",
  "R8"
)

pert_levels <- c(
  -3,
  -2,
  -1,
  0,
  1,
  2,
  3
)


fig5_df <- geom_df %>%
  
  transmute(
    
    growth_stage = .data[[stage_col]],
    
    plot = .data[[plot_col]],
    
    perturb_cm =
      as.numeric(.data[[pert_col]]),
    
    area_change_pct =
      as.numeric(.data[[delta_col]])
    
  ) %>%
  
  filter(
    !is.na(growth_stage),
    !is.na(plot),
    !is.na(perturb_cm),
    !is.na(area_change_pct)
  ) %>%
  
  mutate(
    
    growth_stage =
      factor(
        growth_stage,
        levels = stage_levels
      ),
    
    plot =
      factor(
        plot,
        levels = plot_levels
      )
    
  ) %>%
  
  filter(
    !is.na(growth_stage),
    !is.na(plot)
  ) %>%
  
  arrange(
    growth_stage,
    plot,
    perturb_cm
  )


# -----------------------------
# Sanity check
# -----------------------------

print(
  
  fig5_df %>%
    
    group_by(growth_stage) %>%
    
    summarise(
      
      n_obs = n(),
      
      min_delta =
        min(
          area_change_pct,
          na.rm = TRUE
        ),
      
      max_delta =
        max(
          area_change_pct,
          na.rm = TRUE
        ),
      
      .groups = "drop"
      
    )
  
)


# =========================================================
# Common plot function
# =========================================================

make_stage_plot <- function(stage_name) {
  
  stage_df <- fig5_df %>%
    filter(growth_stage == stage_name)
  
  ggplot(
    stage_df,
    aes(
      x = perturb_cm,
      y = area_change_pct,
      group = plot,
      color = plot,
      shape = plot
    )
  ) +
    
    # -----------------------------------------------------
  # Secondary horizontal reference guides
  # -----------------------------------------------------
  
  geom_hline(
    yintercept = c(
      -50,
      50,
      100,
      150
    ),
    linewidth = 0.22,
    colour = "grey92"
  ) +
    
    # -----------------------------------------------------
  # Secondary vertical reference guides
  # -----------------------------------------------------
  
  geom_vline(
    xintercept = c(
      -2,
      2
    ),
    linewidth = 0.22,
    colour = "grey92"
  ) +
    
    # -----------------------------------------------------
  # Principal zero-reference lines
  # -----------------------------------------------------
  
  geom_hline(
    yintercept = 0,
    linewidth = 0.40,
    colour = "grey55"
  ) +
    
    geom_vline(
      xintercept = 0,
      linewidth = 0.40,
      colour = "grey55"
    ) +
    
    # -----------------------------------------------------
  # Plot trajectories
  # -----------------------------------------------------
  
  geom_line(
    linewidth = 0.70,
    alpha = 0.90
  ) +
    
    geom_point(
      size = 2.6,
      stroke = 0.85
    ) +
    
    # -----------------------------------------------------
  # Stage strip
  # -----------------------------------------------------
  
  facet_wrap(
    ~ growth_stage,
    nrow = 1
  ) +
    
    # -----------------------------------------------------
  # X scale
  # -----------------------------------------------------
  
  scale_x_continuous(
    
    breaks = pert_levels,
    
    labels = c(
      "-3",
      "-2",
      "-1",
      "0",
      "+1",
      "+2",
      "+3"
    ),
    
    limits = c(
      -3,
      3
    ),
    
    expand =
      expansion(
        mult = c(
          0.03,
          0.03
        )
      )
    
  ) +
    
    # -----------------------------------------------------
  # Y scale
  # -----------------------------------------------------
  
  scale_y_continuous(
    
    breaks =
      seq(
        -100,
        150,
        by = 50
      ),
    
    limits = c(
      -100,
      150
    ),
    
    expand =
      expansion(
        mult = c(
          0.02,
          0.03
        )
      )
    
  ) +
    
    # -----------------------------------------------------
  # Same visual encoding used in Figure 4
  # -----------------------------------------------------
  
  scale_color_viridis_d(
    option = "D",
    end = 0.90,
    name = "Plot",
    drop = FALSE
  ) +
    
    scale_shape_manual(
      
      values = c(
        "P1" = 16,
        "P2" = 17,
        "P3" = 15,
        "P4" = 18,
        "P5" = 1
      ),
      
      name = "Plot",
      
      drop = FALSE
      
    ) +
    
    # -----------------------------------------------------
  # No individual axis titles
  # -----------------------------------------------------
  
  labs(
    x = NULL,
    y = NULL,
    color = "Plot",
    shape = "Plot"
  ) +
    
    # -----------------------------------------------------
  # Theme
  # -----------------------------------------------------
  
  theme_classic(
    base_size = 13
  ) +
    
    theme(
      
      axis.title.x = element_blank(),
      axis.title.y = element_blank(),
      
      axis.text =
        element_text(
          size = 11,
          colour = "black"
        ),
      
      axis.ticks =
        element_line(
          colour = "black",
          linewidth = 0.45
        ),
      
      # Stage strip:
      # light grey background without black border
      strip.background =
        element_rect(
          fill = "grey95",
          colour = NA
        ),
      
      strip.text =
        element_text(
          face = "bold",
          size = 12
        ),
      
      legend.position = "bottom",
      
      legend.title =
        element_text(
          face = "bold",
          size = 12
        ),
      
      legend.text =
        element_text(
          size = 11
        ),
      
      panel.spacing =
        grid::unit(
          1.0,
          "lines"
        ),
      
      plot.margin =
        margin(
          4,
          6,
          4,
          6
        )
      
    )
  
}


# =========================================================
# Generate individual panels
# =========================================================

p_V4 <- make_stage_plot("V4")
p_R5 <- make_stage_plot("R5")
p_R6 <- make_stage_plot("R6")
p_R7 <- make_stage_plot("R7")
p_R8 <- make_stage_plot("R8")


# =========================================================
# TOP ROW
#
# No legend is shown in V4 or R5.
#
# Total width:
#   0.5 spacer + 1 V4 + 1 R5 + 0.5 spacer = 3
# =========================================================

top_row <- (
  
  plot_spacer() +
    
    (p_V4 + theme(legend.position = "none")) +
    
    (p_R5 + theme(legend.position = "none")) +
    
    plot_spacer()
  
) +
  
  plot_layout(
    
    ncol = 4,
    
    widths = c(
      0.5,
      1,
      1,
      0.5
    )
    
  )


# =========================================================
# BOTTOM ROW
#
# R6, R7 and R8 share ONE common legend.
#
# Total width:
#   1 + 1 + 1 = 3
# =========================================================

bottom_row <- (
  
  p_R6 +
    p_R7 +
    p_R8
  
) +
  
  plot_layout(
    
    ncol = 3,
    
    widths = c(
      1,
      1,
      1
    ),
    
    guides = "collect"
    
  ) &
  
  theme(
    
    legend.position = "bottom",
    
    legend.box = "horizontal",
    
    legend.margin =
      margin(
        t = 3,
        r = 0,
        b = 2,
        l = 0
      )
    
  )


# =========================================================
# PANEL BLOCK
#
# Top and bottom rows retain the same total width.
# No additional guide collection is performed here.
# =========================================================

panel_block <- (
  
  top_row /
    bottom_row
  
) +
  
  plot_layout(
    
    heights = c(
      1,
      1
    )
    
  )


# =========================================================
# GLOBAL Y-AXIS TITLE
# =========================================================

y_label <- wrap_elements(
  
  full = textGrob(
    
    label =
      expression(
        "Relative mask-area change, " ~
          Delta * italic(A)[italic(d)] ~
          " (%)"
      ),
    
    rot = 90,
    
    gp = gpar(
      fontsize = 14,
      fontface = "bold"
    )
    
  )
  
)


# =========================================================
# GLOBAL X-AXIS TITLE
# =========================================================

x_label <- wrap_elements(
  
  full = textGrob(
    
    label =
      "Boundary perturbation (cm)",
    
    gp = gpar(
      fontsize = 13
    )
    
  )
  
)


# =========================================================
# MAIN BODY
#
# Single global Y-axis title on the left.
# =========================================================

main_body <- (
  
  y_label |
    panel_block
  
) +
  
  plot_layout(
    
    widths = c(
      0.075,
      1
    )
    
  )


# =========================================================
# FINAL FIGURE
#
# Single global X-axis title.
#
# The ONLY legend is the collected legend
# associated with the bottom row.
# =========================================================

fig5 <- (
  
  main_body /
    x_label
  
) +
  
  plot_layout(
    
    heights = c(
      1,
      0.055
    )
    
  )


# -----------------------------
# Display
# -----------------------------

print(fig5)


# -----------------------------
# Save PNG
# -----------------------------

ggsave(
  
  filename = output_png,
  
  plot = fig5,
  
  width = 9.0,
  
  height = 6.2,
  
  units = "in",
  
  dpi = 600,
  
  bg = "white"
  
)


# -----------------------------
# Save PDF
# -----------------------------

ggsave(
  
  filename = output_pdf,
  
  plot = fig5,
  
  width = 9.0,
  
  height = 6.2,
  
  units = "in",
  
  bg = "white"
)


# -----------------------------
# Final message
# -----------------------------

cat(
  "\nFigure 5 saved as:\n"
)

cat(
  " - ",
  output_png,
  "\n",
  sep = ""
)

cat(
  " - ",
  output_pdf,
  "\n",
  sep = ""
)