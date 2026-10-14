# ============================================================
# 04_figure_baseline_mask_spectral_support_boundary_perturbation_v16.R
#
# New manuscript — methodological figure
#
# Layout
# ------
#   (a) Baseline canopy mask                [top, full width]
#   (b) Baseline spectral support           [bottom-left]
#   (c) Controlled boundary perturbation    [bottom-right]
#
# v16
# ---
# - Detail window label moved farther upward
# - Scale bar in panel (a) shifted farther right
# - Panel titles separated more from maps
# - Panel (c) legend block shifted farther right
# - Panels (b) and (c) retain identical map dimensions
# ============================================================

rm(list = ls())
gc()

# ------------------------------------------------------------
# 1. PACKAGES
# ------------------------------------------------------------

needed <- c(
  "sf",
  "terra",
  "dplyr",
  "ggplot2",
  "cowplot",
  "grid",
  "scales"
)

missing <- needed[
  !vapply(
    needed,
    requireNamespace,
    FUN.VALUE = logical(1),
    quietly = TRUE
  )
]

if (length(missing) > 0) {
  stop(
    "Missing package(s): ",
    paste(missing, collapse = ", "),
    "\nInstall once with:\ninstall.packages(c(",
    paste(paste0('"', missing, '"'), collapse = ", "),
    "))"
  )
}

library(sf)
library(terra)
library(dplyr)
library(ggplot2)
library(cowplot)
library(grid)
library(scales)

# ------------------------------------------------------------
# 2. PATHS
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

flight_dir <- file.path(
  project_root,
  "data",
  "raw",
  "R6"
)

canopy_file <- file.path(
  flight_dir,
  "canopy_20241002.gpkg"
)

ndvi_file <- file.path(
  flight_dir,
  "ndvi_20241002.tif"
)

fig_dir <- file.path(
  project_root,
  "figures"
)

dir.create(
  fig_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

out_png <- file.path(
  fig_dir,
  "Figure_baseline_mask_spectral_support_boundary_perturbation_R6_v16.png"
)

if (!file.exists(canopy_file)) {
  stop("Missing canopy file: ", canopy_file)
}

if (!file.exists(ndvi_file)) {
  stop("Missing NDVI file: ", ndvi_file)
}

# ------------------------------------------------------------
# 3. READ AND STANDARDIZE DATA
# ------------------------------------------------------------

canopy_sf <- st_read(
  canopy_file,
  layer = "canopy",
  quiet = TRUE
)

if (is.na(st_crs(canopy_sf))) {
  stop("The canopy layer has no CRS.")
}

canopy_sf <- canopy_sf |>
  st_make_valid() |>
  st_transform(32618)

if (!("subplot" %in% names(canopy_sf))) {
  stop("The canopy layer does not contain the field 'subplot'.")
}

canopy_sf$subplot <- factor(
  canopy_sf$subplot,
  levels = c("P1", "P2", "P3", "P4", "P5")
)

ndvi_r <- rast(ndvi_file)

if (!same.crs(ndvi_r, "EPSG:32618")) {
  ndvi_r <- project(
    ndvi_r,
    "EPSG:32618",
    method = "bilinear"
  )
}

# ------------------------------------------------------------
# 4. PLOT-LEVEL BASELINE MASKS (d = 0)
# ------------------------------------------------------------

plot_masks <- canopy_sf |>
  group_by(subplot) |>
  summarise(
    .groups = "drop",
    do_union = TRUE
  ) |>
  st_make_valid()

if (nrow(plot_masks) != 5) {
  stop(
    "Expected 5 plot-level masks after dissolve, but obtained ",
    nrow(plot_masks),
    "."
  )
}

if (any(st_is_empty(plot_masks))) {
  stop("At least one dissolved plot-level canopy mask is empty.")
}

# ------------------------------------------------------------
# 5. REPRESENTATIVE SPATIAL UNIT
# ------------------------------------------------------------

example_plot <- "P4"

example_mask <- plot_masks[
  as.character(plot_masks$subplot) == example_plot,
]

if (nrow(example_mask) != 1) {
  stop(
    "Could not uniquely identify the example plot: ",
    example_plot
  )
}

# ------------------------------------------------------------
# 6. LOCAL WINDOW FOR PANELS (b) AND (c)
# ------------------------------------------------------------

local_window_size_m <- 5.0

bb_ex <- st_bbox(example_mask)

center_x <- (
  as.numeric(bb_ex["xmin"]) +
    as.numeric(bb_ex["xmax"])
) / 2

center_y <- (
  as.numeric(bb_ex["ymin"]) +
    as.numeric(bb_ex["ymax"])
) / 2

half <- local_window_size_m / 2

local_window <- st_as_sfc(
  st_bbox(
    c(
      xmin = center_x - half,
      ymin = center_y - half,
      xmax = center_x + half,
      ymax = center_y + half
    ),
    crs = st_crs(32618)
  )
)

local_window_sf <- st_as_sf(local_window)

window_bb <- st_bbox(local_window_sf)

# ------------------------------------------------------------
# 7. SPECTRAL SUPPORT FOR BASELINE EXTRACTION
# ------------------------------------------------------------

ndvi_local <- crop(
  ndvi_r,
  ext(
    center_x - half,
    center_x + half,
    center_y - half,
    center_y + half
  )
)

example_mask_local <- suppressWarnings(
  st_intersection(
    example_mask,
    local_window_sf
  )
)

if (nrow(example_mask_local) == 0) {
  stop(
    "Local window does not intersect ",
    example_plot,
    " baseline mask."
  )
}

ndvi_support <- mask(
  ndvi_local,
  vect(example_mask_local)
)

ndvi_df <- as.data.frame(
  ndvi_support,
  xy = TRUE,
  na.rm = TRUE
)

if (ncol(ndvi_df) < 3 || nrow(ndvi_df) == 0) {
  stop("Could not construct NDVI spectral-support pixels.")
}

names(ndvi_df)[3] <- "NDVI"

ndvi_limits <- as.numeric(
  quantile(
    ndvi_df$NDVI,
    probs = c(0.02, 0.98),
    na.rm = TRUE
  )
)

if (
  !all(is.finite(ndvi_limits)) ||
  diff(ndvi_limits) <= 0
) {
  ndvi_limits <- range(
    ndvi_df$NDVI,
    na.rm = TRUE
  )
}

ndvi_breaks <- pretty(
  ndvi_limits,
  n = 4
)

ndvi_breaks <- ndvi_breaks[
  ndvi_breaks >= ndvi_limits[1] &
    ndvi_breaks <= ndvi_limits[2]
]

spectral_palette <- c(
  "#355C9A",
  "#6F8FB8",
  "#8FB8CA",
  "#B9D9D2",
  "#DDE8C4",
  "#F5E6A1",
  "#F6C777",
  "#F6B35F",
  "#E98A4A",
  "#D95D45",
  "#B83A3A"
)

# ------------------------------------------------------------
# 8. CONTROLLED BOUNDARY PERTURBATION
# ------------------------------------------------------------

perturb_m <- 0.03

# Erosion
eroded_3 <- suppressWarnings(
  st_buffer(
    example_mask,
    dist = -perturb_m
  )
)

eroded_3 <- eroded_3[
  !st_is_empty(eroded_3),
]

if (nrow(eroded_3) == 0) {
  stop("The -3 cm erosion produced an empty geometry.")
}

eroded_3 <- st_make_valid(eroded_3)

# Raw dilation
dilated_3_raw <- st_buffer(
  example_mask,
  dist = perturb_m
)

# Exclude canopy assigned to other plots
other_masks <- plot_masks[
  as.character(plot_masks$subplot) != example_plot,
]

other_union <- st_union(
  st_geometry(other_masks)
)

dilated_geom <- suppressWarnings(
  st_difference(
    st_geometry(dilated_3_raw),
    other_union
  )
)

dilated_3 <- st_sf(
  subplot = factor(
    example_plot,
    levels = levels(plot_masks$subplot)
  ),
  geometry = dilated_geom
)

dilated_3 <- st_make_valid(dilated_3)

# ------------------------------------------------------------
# 9. DERIVED PERTURBATION AREAS
# ------------------------------------------------------------

erosion_removed_geom <- suppressWarnings(
  st_difference(
    st_geometry(example_mask),
    st_geometry(eroded_3)
  )
)

erosion_removed <- st_sf(
  geometry = erosion_removed_geom
) |>
  st_make_valid()

dilation_added_geom <- suppressWarnings(
  st_difference(
    st_geometry(dilated_3),
    st_geometry(example_mask)
  )
)

dilation_added <- st_sf(
  geometry = dilation_added_geom
) |>
  st_make_valid()

# ------------------------------------------------------------
# 10. CLIP GEOMETRIES TO LOCAL WINDOW
# ------------------------------------------------------------

clip_local <- function(x) {
  
  out <- suppressWarnings(
    st_intersection(
      x,
      local_window_sf
    )
  )
  
  if (nrow(out) == 0) {
    return(out)
  }
  
  st_make_valid(out)
}

baseline_local <- clip_local(example_mask)
eroded_local   <- clip_local(eroded_3)
dilated_local  <- clip_local(dilated_3)
erem_local     <- clip_local(erosion_removed)
dadd_local     <- clip_local(dilation_added)

# ------------------------------------------------------------
# 11. COMMON CARTOGRAPHIC SETTINGS
# ------------------------------------------------------------

TXT_PANEL_TAG  <- 17
TXT_AXIS_TITLE <- 12.5
TXT_AXIS_TICK  <- 10.5

utm_labels <- label_number(
  accuracy = 1,
  big.mark = ",",
  decimal.mark = "."
)

subplot_cols <- c(
  "P1" = "#2C91D1",
  "P2" = "#E69F00",
  "P3" = "#00A087",
  "P4" = "#CC79A7",
  "P5" = "#D55E00"
)

theme_map_pub <- function() {
  
  theme_minimal(base_size = 12.5) +
    
    theme(
      
      panel.grid.major = element_line(
        color = "grey86",
        linewidth = 0.30
      ),
      
      panel.grid.minor = element_blank(),
      
      axis.title = element_text(
        size = TXT_AXIS_TITLE,
        color = "black"
      ),
      
      axis.text = element_text(
        size = TXT_AXIS_TICK,
        color = "black"
      ),
      
      axis.ticks = element_line(
        color = "black",
        linewidth = 0.35
      ),
      
      axis.line = element_line(
        color = "black",
        linewidth = 0.35
      ),
      
      panel.background = element_rect(
        fill = "white",
        color = NA
      ),
      
      plot.background = element_rect(
        fill = "white",
        color = NA
      ),
      
      plot.margin = margin(
        4, 5, 4, 5
      )
    )
}

# ------------------------------------------------------------
# 12. PANEL (a) — BASELINE CANOPY MASK
# ------------------------------------------------------------

bb_all <- st_bbox(canopy_sf)

xmin <- as.numeric(bb_all["xmin"])
xmax <- as.numeric(bb_all["xmax"])
ymin <- as.numeric(bb_all["ymin"])
ymax <- as.numeric(bb_all["ymax"])

dx <- xmax - xmin
dy <- ymax - ymin

xlim_all <- c(
  xmin - 0.055 * dx,
  xmax + 0.040 * dx
)

ylim_all <- c(
  ymin - 0.175 * dy,
  ymax + 0.075 * dy
)

x_breaks_a <- seq(
  floor(xlim_all[1] / 10) * 10,
  ceiling(xlim_all[2] / 10) * 10,
  by = 10
)

x_breaks_a <- x_breaks_a[
  x_breaks_a >= xlim_all[1] &
    x_breaks_a <= xlim_all[2]
]

y_breaks_a <- seq(
  floor(ylim_all[1] / 5) * 5,
  ceiling(ylim_all[2] / 5) * 5,
  by = 5
)

y_breaks_a <- y_breaks_a[
  y_breaks_a >= ylim_all[1] &
    y_breaks_a <= ylim_all[2]
]

# ------------------------------------------------------------
# 12.1 NORTH ARROW
# ------------------------------------------------------------

north_arrow_layers <- function(
    x,
    y,
    size = 1.0
) {
  
  list(
    
    annotate(
      "segment",
      x = x,
      xend = x,
      y = y - 1.15 * size,
      yend = y + 0.10 * size,
      linewidth = 0.60,
      color = "black"
    ),
    
    annotate(
      "polygon",
      x = c(
        x,
        x - 0.22 * size,
        x,
        x + 0.22 * size
      ),
      y = c(
        y + 0.55 * size,
        y + 0.05 * size,
        y + 0.20 * size,
        y + 0.05 * size
      ),
      fill = "black",
      color = "black",
      linewidth = 0.35
    ),
    
    annotate(
      "text",
      x = x,
      y = y + 1.05 * size,
      label = "N",
      size = 4.8,
      fontface = "bold"
    )
  )
}

# ------------------------------------------------------------
# 12.2 SCALE BAR
# ------------------------------------------------------------

line_scalebar_layers <- function(
    x_left,
    y,
    length_m = 6,
    text = "6 m"
) {
  
  list(
    
    annotate(
      "segment",
      x = x_left,
      xend = x_left + length_m,
      y = y,
      yend = y,
      linewidth = 0.55,
      color = "black"
    ),
    
    annotate(
      "segment",
      x = x_left,
      xend = x_left,
      y = y - 0.18,
      yend = y + 0.18,
      linewidth = 0.55,
      color = "black"
    ),
    
    annotate(
      "segment",
      x = x_left + length_m,
      xend = x_left + length_m,
      y = y - 0.18,
      yend = y + 0.18,
      linewidth = 0.55,
      color = "black"
    ),
    
    annotate(
      "text",
      x = x_left + length_m / 2,
      y = y + 0.60,
      label = text,
      size = 4.0
    )
  )
}

north_x <- xlim_all[1] + 0.045 * diff(xlim_all)
north_y <- ylim_all[2] - 0.095 * diff(ylim_all)

# Further right than v15
scale_x <- xmin + 1.85
scale_y <- ymin - 0.120 * dy

# ------------------------------------------------------------
# 12.3 EXTERNAL PLOT LABELS
# ------------------------------------------------------------

pa_box_df <- data.frame(
  
  subplot = factor(
    c("P1", "P2", "P3", "P4", "P5"),
    levels = levels(canopy_sf$subplot)
  ),
  
  x = c(
    412763.05,
    412766.15,
    412759.45,
    412753.85,
    412743.55
  ),
  
  y = c(
    501787.10,
    501778.72,
    501775.55,
    501772.35,
    501777.55
  ),
  
  label = c(
    "P1",
    "P2",
    "P3",
    "P4",
    "P5"
  )
)

# ------------------------------------------------------------
# 12.4 ELBOW LEADER LINES
# ------------------------------------------------------------

pa_leader_df <- data.frame(
  
  subplot = rep(
    c("P1", "P2", "P3", "P4", "P5"),
    each = 3
  ),
  
  order = rep(
    1:3,
    times = 5
  ),
  
  x = c(
    
    412764.15,
    412765.05,
    412766.40,
    
    412764.80,
    412763.90,
    412762.35,
    
    412758.45,
    412757.45,
    412756.20,
    
    412753.05,
    412752.15,
    412750.35,
    
    412742.95,
    412741.95,
    412741.45
  ),
  
  y = c(
    
    501786.90,
    501786.90,
    501784.75,
    
    501778.72,
    501778.72,
    501780.35,
    
    501775.55,
    501775.55,
    501778.00,
    
    501772.95,
    501772.95,
    501775.20,
    
    501777.55,
    501777.55,
    501774.10
  )
)

PA_BOX_TEXT_SIZE <- 4.9
PA_BOX_LABEL_PADDING <- unit(0.28, "lines")
PA_BOX_LABEL_R <- unit(0.24, "lines")
PA_LEADER_LWD <- 0.42

# ------------------------------------------------------------
# 12.5 DETAIL-WINDOW LABEL
# ------------------------------------------------------------

detail_label_x <- (
  as.numeric(window_bb["xmin"]) +
    as.numeric(window_bb["xmax"])
) / 2

# Moved farther upward
detail_label_y <- as.numeric(window_bb["ymax"]) + 3.00

detail_target_x <- (
  as.numeric(window_bb["xmin"]) +
    as.numeric(window_bb["xmax"])
) / 2

detail_target_y <- as.numeric(window_bb["ymax"]) + 0.03

pA <- ggplot() +
  
  geom_sf(
    data = canopy_sf,
    aes(fill = subplot),
    color = NA,
    linewidth = 0
  ) +
  
  scale_fill_manual(
    values = subplot_cols,
    guide = "none"
  ) +
  
  geom_path(
    data = pa_leader_df,
    aes(
      x = x,
      y = y,
      group = subplot
    ),
    inherit.aes = FALSE,
    linewidth = PA_LEADER_LWD,
    colour = "black",
    lineend = "round",
    linejoin = "round"
  ) +
  
  geom_sf(
    data = local_window_sf,
    fill = NA,
    color = "black",
    linewidth = 0.70,
    linetype = "22"
  ) +
  
  annotate(
    "label",
    x = detail_label_x,
    y = detail_label_y,
    label = "Detail window (b-c)",
    size = 3.4,
    fontface = "plain",
    hjust = 0.5,
    vjust = 0.5,
    label.size = 0.22,
    label.padding = unit(0.16, "lines"),
    label.r = unit(0.14, "lines"),
    fill = scales::alpha("white", 0.94),
    color = "black"
  ) +
  
  annotate(
    "segment",
    x = detail_label_x,
    xend = detail_target_x,
    y = detail_label_y - 0.28,
    yend = detail_target_y,
    linewidth = 0.30,
    color = "black"
  ) +
  
  geom_label(
    data = pa_box_df,
    aes(
      x = x,
      y = y,
      label = label,
      colour = subplot
    ),
    inherit.aes = FALSE,
    fill = "grey97",
    size = PA_BOX_TEXT_SIZE,
    fontface = "bold",
    label.size = 0.42,
    label.padding = PA_BOX_LABEL_PADDING,
    label.r = PA_BOX_LABEL_R,
    show.legend = FALSE
  ) +
  
  geom_text(
    data = pa_box_df,
    aes(
      x = x,
      y = y,
      label = label
    ),
    inherit.aes = FALSE,
    colour = "black",
    size = PA_BOX_TEXT_SIZE,
    fontface = "bold",
    show.legend = FALSE
  ) +
  
  scale_colour_manual(
    values = subplot_cols,
    guide = "none"
  ) +
  
  north_arrow_layers(
    x = north_x,
    y = north_y,
    size = 1.0
  ) +
  
  line_scalebar_layers(
    x_left = scale_x,
    y = scale_y,
    length_m = 6,
    text = "6 m"
  ) +
  
  coord_sf(
    crs = st_crs(32618),
    default_crs = st_crs(32618),
    datum = st_crs(32618),
    xlim = xlim_all,
    ylim = ylim_all,
    expand = FALSE,
    clip = "on"
  ) +
  
  scale_x_continuous(
    breaks = x_breaks_a,
    labels = utm_labels
  ) +
  
  scale_y_continuous(
    breaks = y_breaks_a,
    labels = utm_labels
  ) +
  
  labs(
    title = "Baseline canopy mask",
    x = "Easting (m)",
    y = "Northing (m)"
  ) +
  
  theme_map_pub() +
  
  theme(
    plot.title = element_text(
      face = "bold",
      size = 13.5,
      hjust = 0,
      margin = margin(
        b = 12
      )
    )
  )

# ------------------------------------------------------------
# 13. PANEL (b) — BASELINE SPECTRAL SUPPORT
# ------------------------------------------------------------

pB <- ggplot() +
  
  geom_raster(
    data = ndvi_df,
    aes(
      x = x,
      y = y,
      fill = NDVI
    )
  ) +
  
  geom_sf(
    data = baseline_local,
    fill = NA,
    color = "black",
    linewidth = 0.70
  ) +
  
  scale_fill_gradientn(
    colours = spectral_palette,
    limits = ndvi_limits,
    oob = squish,
    guide = "none"
  ) +
  
  coord_sf(
    crs = st_crs(32618),
    default_crs = st_crs(32618),
    datum = st_crs(32618),
    xlim = c(
      center_x - half,
      center_x + half
    ),
    ylim = c(
      center_y - half,
      center_y + half
    ),
    expand = FALSE
  ) +
  
  scale_x_continuous(
    labels = utm_labels
  ) +
  
  scale_y_continuous(
    labels = utm_labels
  ) +
  
  labs(
    title = "Baseline spectral support",
    x = "Easting (m)",
    y = "Northing (m)"
  ) +
  
  theme_map_pub() +
  
  theme(
    plot.title = element_text(
      face = "bold",
      size = 13.5,
      hjust = 0,
      margin = margin(
        b = 12
      )
    )
  )

# ------------------------------------------------------------
# 14. HORIZONTAL NDVI COLORBAR FOR PANEL (b)
# ------------------------------------------------------------

ndvi_legend_source <- ggplot(
  data.frame(
    x = 1,
    y = 1,
    z = mean(ndvi_limits)
  ),
  aes(
    x = x,
    y = y,
    fill = z
  )
) +
  
  geom_tile() +
  
  scale_fill_gradientn(
    colours = spectral_palette,
    limits = ndvi_limits,
    breaks = ndvi_breaks,
    labels = number_format(
      accuracy = 0.01
    ),
    oob = squish,
    name = "NDVI",
    guide = guide_colorbar(
      direction = "horizontal",
      title.position = "top",
      title.hjust = 0.5,
      label.position = "bottom",
      barwidth = unit(66, "mm"),
      barheight = unit(4.3, "mm"),
      ticks = TRUE,
      frame.colour = "grey45",
      frame.linewidth = 0.25
    )
  ) +
  
  theme_void() +
  
  theme(
    legend.position = "bottom",
    
    legend.title = element_text(
      size = 10.5,
      face = "bold",
      hjust = 0.5
    ),
    
    legend.text = element_text(
      size = 9.0
    ),
    
    legend.margin = margin(
      0, 0, 0, 0
    ),
    
    legend.box.margin = margin(
      0, 0, 0, 0
    )
  )

ndvi_legend <- cowplot::get_legend(
  ndvi_legend_source
)

ndvi_legend_plot <- cowplot::ggdraw() +
  
  cowplot::draw_grob(
    ndvi_legend,
    x = 0.50,
    y = 0.50,
    width = 0.88,
    height = 0.94,
    hjust = 0.5,
    vjust = 0.5
  )

# ------------------------------------------------------------
# 15. PANEL (c) — CONTROLLED BOUNDARY PERTURBATION
# ------------------------------------------------------------

pC <- ggplot() +
  
  geom_sf(
    data = baseline_local,
    fill = "grey88",
    color = NA
  ) +
  
  geom_sf(
    data = erem_local,
    fill = "#E69F00",
    color = NA,
    alpha = 0.90
  ) +
  
  geom_sf(
    data = dadd_local,
    fill = "#56B4E9",
    color = NA,
    alpha = 0.90
  ) +
  
  geom_sf(
    data = eroded_local,
    fill = NA,
    color = "#D55E00",
    linewidth = 0.68,
    linetype = "22"
  ) +
  
  geom_sf(
    data = baseline_local,
    fill = NA,
    color = "black",
    linewidth = 0.58,
    linetype = "solid"
  ) +
  
  geom_sf(
    data = dilated_local,
    fill = NA,
    color = "#0072B2",
    linewidth = 0.68,
    linetype = "42"
  ) +
  
  coord_sf(
    crs = st_crs(32618),
    default_crs = st_crs(32618),
    datum = st_crs(32618),
    xlim = c(
      center_x - half,
      center_x + half
    ),
    ylim = c(
      center_y - half,
      center_y + half
    ),
    expand = FALSE
  ) +
  
  scale_x_continuous(
    labels = utm_labels
  ) +
  
  scale_y_continuous(
    labels = utm_labels
  ) +
  
  labs(
    title = "Controlled boundary perturbation",
    x = "Easting (m)",
    y = "Northing (m)"
  ) +
  
  theme_map_pub() +
  
  theme(
    plot.title = element_text(
      face = "bold",
      size = 13.5,
      hjust = 0,
      margin = margin(
        b = 12
      )
    )
  )

# ------------------------------------------------------------
# 16. CUSTOM LEGEND FOR PANEL (c)
# ------------------------------------------------------------

legend_poly_shape <- data.frame(
  x = c(
    0.05,
    0.32,
    0.32,
    0.48,
    0.48,
    0.23,
    0.23,
    0.05
  ),
  y = c(
    0.05,
    0.05,
    0.20,
    0.20,
    0.43,
    0.43,
    0.28,
    0.28
  )
)

legend_plot_c <- ggplot() +
  
  # AREA
  annotate(
    "text",
    x = 0.05,
    y = 1.38,
    label = "Area",
    fontface = "bold",
    size = 3.7,
    hjust = 0
  ) +
  
  geom_polygon(
    data = legend_poly_shape,
    aes(
      x = x + 0.78,
      y = y + 1.12
    ),
    inherit.aes = FALSE,
    fill = "grey88",
    color = "grey35",
    linewidth = 0.30
  ) +
  
  annotate(
    "text",
    x = 1.38,
    y = 1.32,
    label = "Baseline mask",
    size = 3.8,
    hjust = 0
  ) +
  
  geom_polygon(
    data = legend_poly_shape,
    aes(
      x = x + 2.72,
      y = y + 1.12
    ),
    inherit.aes = FALSE,
    fill = "#56B4E9",
    color = "grey35",
    linewidth = 0.30
  ) +
  
  annotate(
    "text",
    x = 3.32,
    y = 1.32,
    label = "Added",
    size = 3.8,
    hjust = 0
  ) +
  
  geom_polygon(
    data = legend_poly_shape,
    aes(
      x = x + 4.10,
      y = y + 1.12
    ),
    inherit.aes = FALSE,
    fill = "#E69F00",
    color = "grey35",
    linewidth = 0.30
  ) +
  
  annotate(
    "text",
    x = 4.70,
    y = 1.32,
    label = "Removed",
    size = 3.8,
    hjust = 0
  ) +
  
  # BOUNDARY
  annotate(
    "text",
    x = 0.05,
    y = 0.48,
    label = "Boundary",
    fontface = "bold",
    size = 3.7,
    hjust = 0
  ) +
  
  annotate(
    "segment",
    x = 0.88,
    xend = 1.48,
    y = 0.48,
    yend = 0.48,
    linewidth = 0.65,
    color = "black",
    linetype = "solid"
  ) +
  
  annotate(
    "text",
    x = 1.60,
    y = 0.48,
    label = "Baseline",
    size = 3.8,
    hjust = 0,
    vjust = 0.5
  ) +
  
  annotate(
    "segment",
    x = 2.70,
    xend = 3.30,
    y = 0.48,
    yend = 0.48,
    linewidth = 0.72,
    color = "#0072B2",
    linetype = "42"
  ) +
  
  annotate(
    "text",
    x = 3.42,
    y = 0.48,
    label = "Dilation",
    size = 3.8,
    hjust = 0,
    vjust = 0.5
  ) +
  
  annotate(
    "segment",
    x = 4.30,
    xend = 4.90,
    y = 0.48,
    yend = 0.48,
    linewidth = 0.72,
    color = "#D55E00",
    linetype = "22"
  ) +
  
  annotate(
    "text",
    x = 5.02,
    y = 0.48,
    label = "Erosion",
    size = 3.8,
    hjust = 0,
    vjust = 0.5
  ) +
  
  coord_cartesian(
    xlim = c(
      0,
      5.90
    ),
    ylim = c(
      0,
      1.85
    ),
    clip = "off"
  ) +
  
  theme_void() +
  
  theme(
    plot.margin = margin(
      0, 0, 0, 0
    )
  )

# Further right than v15
legend_plot_c_centered <- cowplot::ggdraw() +
  
  cowplot::draw_plot(
    legend_plot_c,
    x = 0.58,
    y = 0.50,
    width = 0.94,
    height = 0.94,
    hjust = 0.5,
    vjust = 0.5
  )

# ------------------------------------------------------------
# 17. FINAL COMPOSITION
# ------------------------------------------------------------

top_row <- cowplot::plot_grid(
  
  pA,
  
  nrow = 1,
  
  labels = "(a)",
  
  label_size = TXT_PANEL_TAG,
  
  label_fontface = "bold",
  
  label_x = 0.012,
  
  label_y = 0.992,
  
  hjust = 0,
  
  vjust = 1
)

left_bottom <- cowplot::plot_grid(
  
  pB,
  ndvi_legend_plot,
  
  ncol = 1,
  
  rel_heights = c(
    1.00,
    0.23
  )
)

right_bottom <- cowplot::plot_grid(
  
  pC,
  legend_plot_c_centered,
  
  ncol = 1,
  
  rel_heights = c(
    1.00,
    0.23
  )
)

bottom_row <- cowplot::plot_grid(
  
  left_bottom,
  right_bottom,
  
  nrow = 1,
  
  rel_widths = c(
    1.00,
    1.00
  ),
  
  labels = c(
    "(b)",
    "(c)"
  ),
  
  label_size = TXT_PANEL_TAG,
  
  label_fontface = "bold",
  
  label_x = c(
    0.012,
    0.012
  ),
  
  label_y = c(
    0.992,
    0.992
  ),
  
  hjust = 0,
  
  vjust = 1,
  
  align = "hv",
  
  axis = "tblr"
)

# ------------------------------------------------------------
# FINAL FIGURE
# Additional vertical separation between panel (a)
# and the lower row (b-c)
# ------------------------------------------------------------

vertical_gap <- cowplot::ggdraw()

final_fig <- cowplot::plot_grid(
  
  top_row,
  vertical_gap,
  bottom_row,
  
  ncol = 1,
  
  rel_heights = c(
    0.92,
    0.055,
    1.30
  )
)

# ------------------------------------------------------------
# 18. EXPORT
# ------------------------------------------------------------

if (file.exists(out_png)) {
  
  ok <- file.remove(out_png)
  
  if (!ok) {
    stop(
      "Could not overwrite output PNG. ",
      "Close the file in other applications and rerun: ",
      out_png
    )
  }
}

ggsave(
  filename = out_png,
  plot = final_fig,
  device = "png",
  width = 12.5,
  height = 11.25,
  units = "in",
  dpi = 600,
  bg = "white"
)

if (!file.exists(out_png)) {
  stop(
    "PNG export failed: ",
    out_png
  )
}

cat("\n")
cat("====================================================\n")
cat("BOUNDARY-SENSITIVITY METHODS FIGURE EXPORTED\n")
cat("====================================================\n")
cat(out_png, "\n")
cat("Panel (a): scale bar shifted farther right\n")
cat("Panel (a): detail-window label moved farther upward\n")
cat("Panel titles: increased separation from maps\n")
cat("Panel (b): centered horizontal NDVI scale\n")
cat("Panel (c): legend block shifted farther right\n")
cat("CRS: EPSG:32618\n")