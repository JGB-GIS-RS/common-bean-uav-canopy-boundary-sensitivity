# ============================================================
# 04_figure_3_spatial_characterization_R6.R
#
# Manuscript Figure 3 — Spatial characterization at R6
#
# Purpose
# -------
# Generates the publication-ready four-panel spatial figure for the
# R6 acquisition, integrating segmented canopy geometry and the three
# UAV-derived spectral indices.
#
# Panels
# ------
#   (a) Canopy segmentation at R6
#   (b) NDVI at R6 with zoom windows
#   (c) MSAVI at R6
#   (d) WDRVI at R6
#
# Main inputs
# -----------
#   data/spatial/flight03/canopy_20241002.gpkg
#   data/spatial/flight03/ndvi_20241002.tif
#   data/spatial/flight03/msavi_20241002.tif
#   data/spatial/flight03/wdrvi_20241002.tif
#
# Notes
# -----
# Cartographic and spectral settings in the executable code are kept
# unchanged. Historical internal output filenames are retained to avoid
# altering functional code; this script corresponds to manuscript Figure 3.
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

project_root <- "C:/common-bean-uav-nitrogen-gradient"

flight_dir <- file.path(
  project_root,
  "data",
  "spatial",
  "flight03"
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
  "Figure1_AB_R6_v26_PANEL_A_FINE_TUNING.png"
)

if (!file.exists(canopy_file)) {
  stop("Missing file: ", canopy_file)
}

if (!file.exists(ndvi_file)) {
  stop("Missing file: ", ndvi_file)
}

# ------------------------------------------------------------
# 3. READ DATA
# ------------------------------------------------------------

canopy_sf <- st_read(
  canopy_file,
  layer = "canopy",
  quiet = TRUE
)

if (is.na(st_crs(canopy_sf))) {
  stop("The canopy layer has no CRS.")
}

canopy_sf <- st_make_valid(
  canopy_sf
)

canopy_sf <- st_transform(
  canopy_sf,
  32618
)

ndvi_r <- rast(
  ndvi_file
)

if (!same.crs(ndvi_r, "EPSG:32618")) {
  ndvi_r <- project(
    ndvi_r,
    "EPSG:32618",
    method = "bilinear"
  )
}

# ------------------------------------------------------------
# 4. BASIC CLEANING
# ------------------------------------------------------------

canopy_sf$plot <- factor(
  canopy_sf$plot,
  levels = c("P1", "P2", "P3", "P4", "P5")
)

plot_cols <- c(
  "P1" = "#2C91D1",
  "P2" = "#E69F00",
  "P3" = "#00A087",
  "P4" = "#CC79A7",
  "P5" = "#D55E00"
)

# ------------------------------------------------------------
# 5. EXTRACT MEAN NDVI BY SEGMENTED CANOPY OBJECT
# ------------------------------------------------------------

canopy_vect <- vect(
  canopy_sf
)

ext_df <- terra::extract(
  ndvi_r,
  canopy_vect,
  fun = mean,
  na.rm = TRUE
)

if (ncol(ext_df) < 2) {
  stop("Mean NDVI extraction failed.")
}

canopy_sf$ndvi_mean <- ext_df[[2]]

if (all(is.na(canopy_sf$ndvi_mean))) {
  stop("Mean NDVI extraction failed: all extracted values are NA.")
}

# ------------------------------------------------------------
# 6. COMMON TYPOGRAPHY
# ------------------------------------------------------------

TXT_PANEL_TAG     <- 17.5
TXT_AXIS_TITLE    <- 13.5
TXT_AXIS_TICK     <- 11.5
TXT_LEGEND_TITLE  <- 11.5
TXT_LEGEND_VALUE  <- 10.0

# annotate("text") sizes are not pt, so use proportional increase
TXT_SCALE <- 4.0
TXT_NORTH <- 4.8

# ------------------------------------------------------------
# 7. HELPER FUNCTIONS
# ------------------------------------------------------------

theme_map_pub <- function() {

  theme_minimal(
    base_size = 13.5
  ) +

    theme(
      panel.grid.major = element_line(
        color = "grey82",
        linewidth = 0.35
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

      legend.title = element_text(
        size = TXT_LEGEND_TITLE,
        face = "bold"
      ),

      legend.text = element_text(
        size = TXT_LEGEND_VALUE
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
        6,
        6,
        6,
        6
      )
    )
}

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
      size = TXT_NORTH,
      fontface = "bold"
    )
  )
}

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
      y = y + 0.48,
      label = text,
      size = TXT_SCALE
    )
  )
}

# ------------------------------------------------------------
# FIXED FUNCTION
# ------------------------------------------------------------
# Robust to any sf geometry-column name.
# It does not call sub$geometry.
# ------------------------------------------------------------

get_plot_center <- function(
  x_sf,
  plot_name
) {

  if (!("plot" %in% names(x_sf))) {
    stop("The canopy layer does not contain the field 'plot'.")
  }

  sub <- x_sf[
    as.character(x_sf$plot) == plot_name,
  ]

  if (nrow(sub) == 0) {
    stop(
      "Plot not found: ",
      plot_name
    )
  }

  bb_sub <- st_bbox(
    sub
  )

  center_x <- (
    as.numeric(bb_sub["xmin"]) +
      as.numeric(bb_sub["xmax"])
  ) / 2

  center_y <- (
    as.numeric(bb_sub["ymin"]) +
      as.numeric(bb_sub["ymax"])
  ) / 2

  c(
    x = center_x,
    y = center_y
  )
}

make_square_bbox <- function(
  center_x,
  center_y,
  size,
  crs_obj
) {

  center_x <- as.numeric(center_x)
  center_y <- as.numeric(center_y)
  size <- as.numeric(size)

  half <- size / 2

  poly <- st_polygon(
    list(
      matrix(
        c(
          center_x - half, center_y - half,
          center_x + half, center_y - half,
          center_x + half, center_y + half,
          center_x - half, center_y + half,
          center_x - half, center_y - half
        ),
        ncol = 2,
        byrow = TRUE
      )
    )
  )

  st_sfc(
    poly,
    crs = crs_obj
  )
}


# ------------------------------------------------------------
# DOTTED CONNECTOR HELPERS
# ------------------------------------------------------------
# These functions only define the geometry of the visual guide lines.
# They do not modify zoom windows, source boxes, map extent, CRS,
# legends, palettes, or any underlying spectral values.

bbox_center_xy <- function(bb) {
  c(
    x = (as.numeric(bb["xmin"]) + as.numeric(bb["xmax"])) / 2,
    y = (as.numeric(bb["ymin"]) + as.numeric(bb["ymax"])) / 2
  )
}

# Find the point where the line from the rectangle center toward a target
# reaches the rectangle boundary. This makes the connector start/end on
# the border rather than through the middle of either box.
rect_boundary_toward <- function(bb, target_xy) {

  cx <- (as.numeric(bb["xmin"]) + as.numeric(bb["xmax"])) / 2
  cy <- (as.numeric(bb["ymin"]) + as.numeric(bb["ymax"])) / 2

  dx <- as.numeric(target_xy["x"]) - cx
  dy <- as.numeric(target_xy["y"]) - cy

  if (abs(dx) < .Machine$double.eps && abs(dy) < .Machine$double.eps) {
    return(c(x = cx, y = cy))
  }

  tx <- Inf
  ty <- Inf

  if (abs(dx) >= .Machine$double.eps) {
    xedge <- if (dx > 0) as.numeric(bb["xmax"]) else as.numeric(bb["xmin"])
    tx <- (xedge - cx) / dx
  }

  if (abs(dy) >= .Machine$double.eps) {
    yedge <- if (dy > 0) as.numeric(bb["ymax"]) else as.numeric(bb["ymin"])
    ty <- (yedge - cy) / dy
  }

  candidates <- c(tx, ty)
  candidates <- candidates[is.finite(candidates) & candidates > 0]

  if (length(candidates) == 0) {
    return(c(x = cx, y = cy))
  }

  t <- min(candidates)

  c(
    x = cx + t * dx,
    y = cy + t * dy
  )
}

make_zoom_connector <- function(display_box, source_box_sfc, connector_id) {

  # display_box is a named numeric vector: xmin/xmax/ymin/ymax
  display_bb <- c(
    xmin = as.numeric(display_box["xmin"]),
    xmax = as.numeric(display_box["xmax"]),
    ymin = as.numeric(display_box["ymin"]),
    ymax = as.numeric(display_box["ymax"])
  )

  source_bb <- st_bbox(source_box_sfc)

  display_center <- bbox_center_xy(display_bb)
  source_center  <- bbox_center_xy(source_bb)

  p_display <- rect_boundary_toward(
    display_bb,
    source_center
  )

  p_source <- rect_boundary_toward(
    source_bb,
    display_center
  )

  data.frame(
    id = connector_id,
    x = as.numeric(p_display["x"]),
    y = as.numeric(p_display["y"]),
    xend = as.numeric(p_source["x"]),
    yend = as.numeric(p_source["y"])
  )
}

# Right connector fixed as a fully horizontal dotted guide.
# It starts at the LEFT edge of the displayed right inset and ends
# at the RIGHT edge of the source box in the crop. The y-position is
# taken from the vertical middle of the displayed inset, but clipped so
# that it always intersects the source box.
make_horizontal_right_connector <- function(display_box, source_box_sfc, connector_id) {

  display_bb <- c(
    xmin = as.numeric(display_box["xmin"]),
    xmax = as.numeric(display_box["xmax"]),
    ymin = as.numeric(display_box["ymin"]),
    ymax = as.numeric(display_box["ymax"])
  )

  source_bb <- st_bbox(source_box_sfc)

  y_display_mid <- (display_bb["ymin"] + display_bb["ymax"]) / 2

  y_line <- max(
    min(y_display_mid, as.numeric(source_bb["ymax"])),
    as.numeric(source_bb["ymin"])
  )

  data.frame(
    id   = connector_id,
    x    = as.numeric(display_bb["xmin"]),
    y    = as.numeric(y_line),
    xend = as.numeric(source_bb["xmax"]) - 2.32,
    yend = as.numeric(y_line)
  )
}

build_zoom_plot <- function(
  box_sfc,
  canopy_sf,
  raster_obj,
  pixel_limits,
  pixel_palette
) {

  box_sf <- st_as_sf(
    box_sfc
  )

  canopy_box <- suppressWarnings(
    st_intersection(
      canopy_sf,
      box_sf
    )
  )

  if (nrow(canopy_box) == 0) {
    stop("Zoom window does not intersect canopy polygons.")
  }

  bb_box <- st_bbox(
    box_sfc
  )

  r_crop <- crop(
    raster_obj,
    ext(
      as.numeric(bb_box["xmin"]),
      as.numeric(bb_box["xmax"]),
      as.numeric(bb_box["ymin"]),
      as.numeric(bb_box["ymax"])
    )
  )

  # soil excluded: mask only with canopy objects
  r_mask <- mask(
    r_crop,
    vect(canopy_box)
  )

  pix_df <- as.data.frame(
    r_mask,
    xy = TRUE,
    na.rm = TRUE
  )

  if (ncol(pix_df) < 3) {
    stop("Could not create pixel data for zoom.")
  }

  names(pix_df)[3] <- "ndvi"

  ggplot() +

    geom_raster(
      data = pix_df,
      aes(
        x = x,
        y = y,
        fill = ndvi
      )
    ) +

    geom_sf(
      data = canopy_box,
      fill = NA,
      color = "grey10",
      linewidth = 0.22,
      inherit.aes = FALSE
    ) +

    scale_fill_gradientn(
      colours = pixel_palette,
      limits = pixel_limits,
      oob = squish,
      guide = "none"
    ) +

    coord_sf(
      crs = st_crs(32618),
      default_crs = st_crs(32618),
      datum = st_crs(32618),
      xlim = c(
        as.numeric(bb_box["xmin"]),
        as.numeric(bb_box["xmax"])
      ),
      ylim = c(
        as.numeric(bb_box["ymin"]),
        as.numeric(bb_box["ymax"])
      ),
      expand = FALSE
    ) +

    theme_void() +

    theme(
      panel.border = element_rect(
        color = "#17365D",
        fill = NA,
        linewidth = 0.85
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
        0,
        0,
        0,
        0
      )
    )
}

# ------------------------------------------------------------
# 8. COMMON EXTENT + UTM BREAKS
# ------------------------------------------------------------

bb <- st_bbox(
  canopy_sf
)

xmin <- as.numeric(bb["xmin"])
xmax <- as.numeric(bb["xmax"])
ymin <- as.numeric(bb["ymin"])
ymax <- as.numeric(bb["ymax"])

dx <- xmax - xmin
dy <- ymax - ymin

xlim_common <- c(
  xmin - 0.055 * dx,
  xmax + 0.040 * dx
)

ylim_common <- c(
  ymin - 0.165 * dy,
  ymax + 0.075 * dy
)

x_breaks <- seq(
  floor(xlim_common[1] / 10) * 10,
  ceiling(xlim_common[2] / 10) * 10,
  by = 10
)

x_breaks <- x_breaks[
  x_breaks >= xlim_common[1] &
    x_breaks <= xlim_common[2]
]

y_breaks <- seq(
  floor(ylim_common[1] / 5) * 5,
  ceiling(ylim_common[2] / 5) * 5,
  by = 5
)

y_breaks <- y_breaks[
  y_breaks >= ylim_common[1] &
    y_breaks <= ylim_common[2]
]

utm_labels <- label_number(
  accuracy = 1,
  big.mark = ",",
  decimal.mark = "."
)

# ------------------------------------------------------------
# 9. COMMON NORTH + SCALE POSITIONS
# ------------------------------------------------------------

north_x <- xlim_common[1] + 0.045 * diff(xlim_common)
north_y <- ylim_common[2] - 0.095 * diff(ylim_common)

scale_x <- xmin + 0.20
scale_y <- ymin - 0.105 * dy

# ------------------------------------------------------------
# 10. PANEL (a)
# ------------------------------------------------------------
# Updated only to fine-tune plot callouts and N-treatment labels.
# All cartographic settings (extent, CRS, north arrow, scale, colours)
# remain unchanged.

pa_box_df <- data.frame(
  plot = factor(c("P1", "P2", "P3", "P4", "P5"),
                   levels = levels(canopy_sf$plot)),
  x = c(412763.05, 412766.15, 412759.45, 412753.55, 412743.55),
  y = c(501787.10, 501778.72, 501775.55, 501772.62, 501778.88),
  label = c("P1", "P2", "P3", "P4", "P5")
)

pa_treatment_df <- data.frame(
  x = c(412763.05, 412766.15, 412759.45, 412753.55, 412743.55),
  y = c(501785.90, 501777.18, 501774.02, 501771.05, 501777.22),
  label = c(
    "0~kg~N~ha^{-1}",
    "100~kg~N~ha^{-1}",
    "200~kg~N~ha^{-1}",
    "300~kg~N~ha^{-1}",
    "400~kg~N~ha^{-1}"
  )
)

pa_leader_df <- data.frame(
  x = c(
    412764.35,
    412764.05, 412764.05,
    412757.25, 412757.25,
    412751.45, 412751.45,
    412741.35, 412741.35
  ),
  y = c(
    501786.95,
    501778.72, 501778.72,
    501775.68, 501775.68,
    501772.76, 501772.76,
    501778.88, 501778.88
  ),
  xend = c(
    412766.42,
    412766.00, 412762.25,
    412758.95, 412755.72,
    412753.05, 412749.82,
    412742.95, 412741.05
  ),
  yend = c(
    501784.72,
    501778.72, 501780.42,
    501775.68, 501778.10,
    501772.76, 501775.42,
    501778.88, 501773.38
  )
)

PA_BOX_TEXT_SIZE <- 4.9
PA_TREAT_TEXT_SIZE <- 3.4
PA_BOX_LABEL_PADDING <- unit(0.28, "lines")
PA_TREAT_LABEL_PADDING <- unit(0.10, "lines")
PA_BOX_LABEL_R <- unit(0.24, "lines")
PA_TREAT_LABEL_R <- unit(0.05, "lines")
PA_LEADER_LWD <- 0.42

pA <- ggplot() +

  geom_sf(
    data = canopy_sf,
    aes(fill = plot),
    color = NA,
    linewidth = 0
  ) +

  scale_fill_manual(
    values = plot_cols,
    guide = "none"
  ) +

  geom_segment(
    data = pa_leader_df,
    aes(x = x, y = y, xend = xend, yend = yend),
    inherit.aes = FALSE,
    linewidth = PA_LEADER_LWD,
    colour = "black",
    lineend = "round"
  ) +

  # Coloured border for each P1-P5 label box.
  # A second black text layer is drawn on top so the text itself
  # remains black while the border preserves the plot colour.
  geom_label(
    data = pa_box_df,
    aes(x = x, y = y, label = label, colour = plot),
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
    aes(x = x, y = y, label = label),
    inherit.aes = FALSE,
    colour = "black",
    size = PA_BOX_TEXT_SIZE,
    fontface = "bold",
    show.legend = FALSE
  ) +

  geom_label(
    data = pa_treatment_df,
    aes(x = x, y = y, label = label),
    inherit.aes = FALSE,
    parse = TRUE,
    fill = "white",
    colour = "black",
    size = PA_TREAT_TEXT_SIZE,
    fontface = "plain",
    label.size = 0,
    label.padding = PA_TREAT_LABEL_PADDING,
    label.r = PA_TREAT_LABEL_R,
    show.legend = FALSE
  ) +

  scale_colour_manual(
    values = plot_cols,
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
    xlim = xlim_common,
    ylim = ylim_common,
    expand = FALSE,
    clip = "on"
  ) +

  scale_x_continuous(
    breaks = x_breaks,
    labels = utm_labels
  ) +

  scale_y_continuous(
    breaks = y_breaks,
    labels = utm_labels
  ) +

  labs(
    x = "Easting (m)",
    y = "Northing (m)"
  ) +

  theme_map_pub()

# ------------------------------------------------------------
# 11. PANEL (b): MEAN NDVI + PIXEL ZOOMS
# ------------------------------------------------------------

# Common spectral palette for NDVI, MSAVI and WDRVI.
# Same direction for all indices: relatively low = blue,
# relatively high = red. Saturation is intentionally moderated
# so small within-index differences are not visually overstated.
ndvi_palette <- c(
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

# robust mean-object display range
mean_limits <- as.numeric(
  quantile(
    canopy_sf$ndvi_mean,
    probs = c(0.05, 0.95),
    na.rm = TRUE
  )
)

if (!all(is.finite(mean_limits)) || diff(mean_limits) <= 0) {
  mean_limits <- range(
    canopy_sf$ndvi_mean,
    na.rm = TRUE
  )
}

# Uniform legend structure:
# mean-object scales always use 5 equally spaced ticks.
mean_breaks <- seq(
  mean_limits[1],
  mean_limits[2],
  length.out = 5
)

# zoom centers — corrected function used here
center_p4 <- get_plot_center(
  canopy_sf,
  "P4"
)

center_p1 <- get_plot_center(
  canopy_sf,
  "P1"
)

zoom_size_map <- 2.20

left_zoom_box <- make_square_bbox(
  center_x = as.numeric(center_p4["x"]) + 0.35,
  center_y = as.numeric(center_p4["y"]) + 0.20,
  size = zoom_size_map,
  crs_obj = st_crs(canopy_sf)
)

right_zoom_box <- make_square_bbox(
  center_x = as.numeric(center_p1["x"]) - 0.55,
  center_y = as.numeric(center_p1["y"]) - 0.35,
  size = zoom_size_map,
  crs_obj = st_crs(canopy_sf)
)

# pixel limits based only on both canopy-only zooms
get_zoom_values <- function(
  box_sfc,
  canopy_sf,
  raster_obj
) {

  box_sf <- st_as_sf(
    box_sfc
  )

  canopy_box <- suppressWarnings(
    st_intersection(
      canopy_sf,
      box_sf
    )
  )

  bb_box <- st_bbox(
    box_sfc
  )

  r_crop <- crop(
    raster_obj,
    ext(
      as.numeric(bb_box["xmin"]),
      as.numeric(bb_box["xmax"]),
      as.numeric(bb_box["ymin"]),
      as.numeric(bb_box["ymax"])
    )
  )

  r_mask <- mask(
    r_crop,
    vect(canopy_box)
  )

  values(
    r_mask,
    na.rm = TRUE
  )
}

pixel_values <- c(
  get_zoom_values(
    left_zoom_box,
    canopy_sf,
    ndvi_r
  ),
  get_zoom_values(
    right_zoom_box,
    canopy_sf,
    ndvi_r
  )
)

pixel_limits <- as.numeric(
  quantile(
    pixel_values,
    probs = c(0.02, 0.98),
    na.rm = TRUE
  )
)

if (!all(is.finite(pixel_limits)) || diff(pixel_limits) <= 0) {
  pixel_limits <- range(
    pixel_values,
    na.rm = TRUE
  )
}

# Pixel scales always use 4 equally spaced ticks.
pixel_breaks <- seq(
  pixel_limits[1],
  pixel_limits[2],
  length.out = 4
)

pB_zoom_left <- build_zoom_plot(
  box_sfc = left_zoom_box,
  canopy_sf = canopy_sf,
  raster_obj = ndvi_r,
  pixel_limits = pixel_limits,
  pixel_palette = ndvi_palette
)

pB_zoom_right <- build_zoom_plot(
  box_sfc = right_zoom_box,
  canopy_sf = canopy_sf,
  raster_obj = ndvi_r,
  pixel_limits = pixel_limits,
  pixel_palette = ndvi_palette
)

# ------------------------------------------------------------
# FIX: INSETS ARE NOW ANCHORED IN UTM MAP COORDINATES
# ------------------------------------------------------------
# Using annotation_custom() in projected map coordinates avoids
# the normalized ggdraw coordinates that caused the zoom windows
# to drift onto axes and labels after panel composition.
#
# Both displayed insets are exactly the same size in metres.
# Only these positions are adjusted; the scientific content,
# zoom source windows, scales, CRS and legends remain unchanged.

zoom_left_grob  <- ggplotGrob(pB_zoom_left)
zoom_right_grob <- ggplotGrob(pB_zoom_right)

inset_size_m <- 5.20

# Upper-left white space: moved clearly right of the Y axis / north arrow
inset_left <- c(
  xmin = xlim_common[1] + 3.40,
  xmax = xlim_common[1] + 3.40 + inset_size_m,
  ymin = ylim_common[2] - 6.10,
  ymax = ylim_common[2] - 6.10 + inset_size_m
)

# SECOND ZOOM: move ONLY this inset next to the approved upper inset.
# The upper inset (inset_left) is left completely unchanged.
# Both zoom windows keep exactly the same size and vertical alignment.
zoom_gap_m <- 0.85

# IMPORTANT FIX:
# inset_left["xmax"] and inset_left["ymin"] are named scalars.
# If they are inserted directly into c(xmin = ..., ...), R can create
# compound names such as "xmin.xmax". Later, inset_right["xmin"] then
# returns NA, which produces the non-finite viewport error in grid/cowplot.
# as.numeric() removes those inherited names and keeps clean xmin/xmax/ymin/ymax.
inset_right <- c(
  xmin = as.numeric(inset_left["xmax"]) + zoom_gap_m,
  xmax = as.numeric(inset_left["xmax"]) + zoom_gap_m + inset_size_m,
  ymin = as.numeric(inset_left["ymin"]),
  ymax = as.numeric(inset_left["ymax"])
)

# Defensive check: all display inset coordinates must be finite.
if (!all(is.finite(inset_right))) {
  stop("Non-finite coordinates detected in inset_right.")
}

# ------------------------------------------------------------
# DOTTED ZOOM CONNECTORS — PANELS (b), (c), (d)
# ------------------------------------------------------------
# The first displayed zoom is linked to left_zoom_box (P4 region).
# The second displayed zoom is linked to right_zoom_box (upper field).
# Endpoints are automatically anchored to the nearest rectangle borders.

zoom_connector_df <- rbind(
  make_zoom_connector(
    display_box = inset_left,
    source_box_sfc = left_zoom_box,
    connector_id = "zoom_left"
  ),
  make_horizontal_right_connector(
    display_box = inset_right,
    source_box_sfc = right_zoom_box,
    connector_id = "zoom_right"
  )
)

zoom_boxes_sf <- rbind(
  st_as_sf(left_zoom_box),
  st_as_sf(right_zoom_box)
)

pB_main <- ggplot() +

  geom_sf(
    data = canopy_sf,
    aes(fill = ndvi_mean),
    color = "grey25",
    linewidth = 0.16
  ) +

  geom_segment(
    data = zoom_connector_df,
    aes(
      x = x,
      y = y,
      xend = xend,
      yend = yend
    ),
    inherit.aes = FALSE,
    color = "grey40",
    linewidth = 0.38,
    linetype = "22",
    lineend = "round"
  ) +

  geom_sf(
    data = zoom_boxes_sf,
    fill = NA,
    color = "#17365D",
    linewidth = 0.65
  ) +

  # Enlarged views anchored inside the projected map area
  annotation_custom(
    grob = zoom_left_grob,
    xmin = inset_left["xmin"],
    xmax = inset_left["xmax"],
    ymin = inset_left["ymin"],
    ymax = inset_left["ymax"]
  ) +

  annotation_custom(
    grob = zoom_right_grob,
    xmin = inset_right["xmin"],
    xmax = inset_right["xmax"],
    ymin = inset_right["ymin"],
    ymax = inset_right["ymax"]
  ) +

  scale_fill_gradientn(
    colours = ndvi_palette,
    limits = mean_limits,
    breaks = mean_breaks,
    oob = squish,
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
    xlim = xlim_common,
    ylim = ylim_common,
    expand = FALSE,
    clip = "on"
  ) +

  scale_x_continuous(
    breaks = x_breaks,
    labels = utm_labels
  ) +

  scale_y_continuous(
    breaks = y_breaks,
    labels = utm_labels
  ) +

  labs(
    x = "Easting (m)",
    y = "Northing (m)"
  ) +

  theme_map_pub() +

  theme(
    legend.position = "none"
  )

# ------------------------------------------------------------
# 12. PANEL (b) LEGENDS
# ------------------------------------------------------------

mean_legend_plot <- ggplot(
  data.frame(
    x = 1,
    y = 1,
    z = mean(mean_limits)
  ),
  aes(
    x = x,
    y = y,
    fill = z
  )
) +

  geom_tile() +

  scale_fill_gradientn(
    colours = ndvi_palette,
    limits = mean_limits,
    breaks = mean_breaks,
    labels = scales::label_number(
      accuracy = 0.001,
      trim = TRUE
    ),
    oob = squish,
    name = "Mean NDVI",
    guide = guide_colorbar(
      title.position = "top",
      title.hjust = 0.5,
      barheight = unit(27, "mm"),
      barwidth = unit(4.8, "mm"),
      ticks = TRUE,
      frame.colour = "grey45",
      frame.linewidth = 0.25
    )
  ) +

  theme_void() +

  theme(
    legend.position = "right",

    legend.title = element_text(
      size = TXT_LEGEND_TITLE,
      face = "bold",
      hjust = 0.5
    ),

    legend.text = element_text(
      size = TXT_LEGEND_VALUE
    ),

    plot.margin = margin(
      0,
      2,
      0,
      0
    )
  )

pixel_legend_plot <- ggplot(
  data.frame(
    x = 1,
    y = 1,
    z = mean(pixel_limits)
  ),
  aes(
    x = x,
    y = y,
    fill = z
  )
) +

  geom_tile() +

  scale_fill_gradientn(
    colours = ndvi_palette,
    limits = pixel_limits,
    breaks = pixel_breaks,
    labels = scales::label_number(
      accuracy = 0.01,
      trim = TRUE
    ),
    oob = squish,
    name = "Pixel NDVI",
    guide = guide_colorbar(
      title.position = "top",
      title.hjust = 0.5,
      barheight = unit(27, "mm"),
      barwidth = unit(4.8, "mm"),
      ticks = TRUE,
      frame.colour = "grey45",
      frame.linewidth = 0.25
    )
  ) +

  theme_void() +

  theme(
    legend.position = "right",

    legend.title = element_text(
      size = TXT_LEGEND_TITLE,
      face = "bold",
      hjust = 0.5
    ),

    legend.text = element_text(
      size = TXT_LEGEND_VALUE
    ),

    plot.margin = margin(
      0,
      2,
      0,
      0
    )
  )

legend_mean <- cowplot::get_legend(
  mean_legend_plot
)

legend_pixel <- cowplot::get_legend(
  pixel_legend_plot
)

# ------------------------------------------------------------
# LEGEND COLUMN — FINAL INSET ADJUSTMENT
# ------------------------------------------------------------
# The legend grobs are deliberately shifted inward from the
# outer right edge. This preserves the two map panels at equal
# visual scale while preventing legend titles/numbers from being
# clipped by the figure boundary.

# ------------------------------------------------------------
# 13. COMPACT FINAL COMPOSITION
# ------------------------------------------------------------
# The large blank gap came from assigning the legends their own
# full third column. Here the two map panels retain equal width,
# and the legends are overlaid in a narrow strip immediately to
# the right of panel (b), without changing map scale.

maps_pair <- cowplot::plot_grid(
  pA,
  pB_main,
  nrow = 1,
  rel_widths = c(1.00, 1.00),
  align = "hv",
  axis = "tblr",
  labels = c("(a)", "(b)"),
  label_size = TXT_PANEL_TAG,
  label_fontface = "bold",
  label_x = c(0.015, 0.015),
  label_y = c(0.985, 0.985),
  hjust = 0,
  vjust = 1
)

# Final canvas:
# - maps use 92.5% of the width
# - legends use only the remaining 7.5%
# - legend strip begins almost immediately after panel (b)
final_fig <- cowplot::ggdraw() +

  cowplot::draw_plot(
    maps_pair,
    x = 0.000,
    y = 0.000,
    width = 0.925,
    height = 1.000
  ) +

  cowplot::draw_grob(
    legend_mean,
    x = 0.915,
    y = 0.585,
    width = 0.082,
    height = 0.285
  ) +

  cowplot::draw_grob(
    legend_pixel,
    x = 0.915,
    y = 0.145,
    width = 0.082,
    height = 0.285
  )

# ------------------------------------------------------------
# 14. SAVE
# ------------------------------------------------------------

# ------------------------------------------------------------
# SAFE EXPORT
# ------------------------------------------------------------
# Use a new filename for this version so Windows/PowerPoint/Photos
# cannot block overwriting a previously opened PNG.
#
# If the file already exists and is not locked, remove it first.
if (file.exists(out_png)) {
  removed_ok <- file.remove(out_png)

  if (!removed_ok) {
    stop(
      "Could not overwrite the output PNG. ",
      "Close the image in PowerPoint, Photos, Explorer preview, or any other app, ",
      "then run the script again. Locked file: ",
      out_png
    )
  }
}

# Explicit PNG device avoids ambiguity about the output format.
ggsave(
  filename = out_png,
  plot = final_fig,
  device = "png",
  width = 15.2,
  height = 6.2,
  units = "in",
  dpi = 600,
  bg = "white"
)

if (!file.exists(out_png)) {
  stop("The PNG export did not create the expected file: ", out_png)
}

cat("\n")
cat("====================================================\n")
cat("FIGURE A+B EXPORTED\n")
cat("====================================================\n")
cat(out_png, "\n")
cat("CRS: EPSG:32618\n")
cat("North arrow: unified in panels (a) and (b)\n")
cat("Scale line: 6 m, outside crop\n")
cat("Panel labels: closer to map frames\n")
cat("Panel gap: reduced\n")
cat("Zoom soil: excluded\n")
cat("Zoom insets: anchored in UTM map coordinates\n")
cat("Connector lines: subtle dotted guides drawn from each zoom to its source box\n")
cat("Legends: compact overlay strip immediately right of panel (b)\n")


# ============================================================
# 15. EXTENSION TO PANELS (c) AND (d)
#
# IMPORTANT:
# Everything above this line is the already-approved code for
# panels (a) and (b). It is intentionally left unchanged.
#
# New panels:
#   (c) MSAVI
#   (d) WDRVI
#
# Scientific/cartographic rules inherited EXACTLY from panel (b):
# - same EPSG:32618
# - same map extent
# - same north arrow
# - same 6 m scale bar
# - same typography
# - same P4 and upper-field zoom source windows
# - same displayed zoom positions and sizes
# - same canopy-only mask in zooms (soil excluded)
# - same object-level mean representation in the main map
# - same P5-P95 stretch for object means
# - same P2-P98 stretch for zoom pixels
# - same blue-to-red palette
# - same subtle dotted connector lines in panels (b), (c), and (d)
#
# Panels (a) and (b) are NOT rebuilt or modified here.
# ============================================================

msavi_file <- file.path(
  flight_dir,
  "msavi_20241002.tif"
)

wdrvi_file <- file.path(
  flight_dir,
  "wdrvi_20241002.tif"
)

if (!file.exists(msavi_file)) {
  stop("Missing MSAVI file: ", msavi_file)
}

if (!file.exists(wdrvi_file)) {
  stop("Missing WDRVI file: ", wdrvi_file)
}

msavi_r <- rast(
  msavi_file
)

wdrvi_r <- rast(
  wdrvi_file
)

if (!same.crs(msavi_r, "EPSG:32618")) {
  msavi_r <- project(
    msavi_r,
    "EPSG:32618",
    method = "bilinear"
  )
}

if (!same.crs(wdrvi_r, "EPSG:32618")) {
  wdrvi_r <- project(
    wdrvi_r,
    "EPSG:32618",
    method = "bilinear"
  )
}

# ------------------------------------------------------------
# 16. GENERIC BUILDER FOR NEW SPECTRAL PANELS
#
# This function reproduces the APPROVED logic of panel (b).
# It is used ONLY for (c) and (d), so the approved NDVI code
# above remains untouched.
# ------------------------------------------------------------

build_additional_spectral_panel <- function(
  raster_obj,
  index_name
) {

  canopy_idx <- canopy_sf

  # ----------------------------------------------------------
  # Mean index per segmented canopy object
  # ----------------------------------------------------------

  ext_idx <- terra::extract(
    raster_obj,
    vect(canopy_idx),
    fun = mean,
    na.rm = TRUE
  )

  if (ncol(ext_idx) < 2) {
    stop(
      "Mean ",
      index_name,
      " extraction failed."
    )
  }

  canopy_idx$index_mean <- ext_idx[[2]]

  if (all(is.na(canopy_idx$index_mean))) {
    stop(
      "Mean ",
      index_name,
      " extraction failed: all values are NA."
    )
  }

  # ----------------------------------------------------------
  # Robust display limits for object means: P5-P95
  # ----------------------------------------------------------

  mean_limits_idx <- as.numeric(
    quantile(
      canopy_idx$index_mean,
      probs = c(0.05, 0.95),
      na.rm = TRUE
    )
  )

  if (
    !all(is.finite(mean_limits_idx)) ||
      diff(mean_limits_idx) <= 0
  ) {
    mean_limits_idx <- range(
      canopy_idx$index_mean,
      na.rm = TRUE
    )
  }

  # Same legend structure used in NDVI:
  # 5 equally spaced ticks for object means.
  mean_breaks_idx <- seq(
    mean_limits_idx[1],
    mean_limits_idx[2],
    length.out = 5
  )

  # ----------------------------------------------------------
  # Pixel values from EXACTLY the same two canopy-only zooms
  # ----------------------------------------------------------

  pixel_values_idx <- c(
    get_zoom_values(
      left_zoom_box,
      canopy_idx,
      raster_obj
    ),
    get_zoom_values(
      right_zoom_box,
      canopy_idx,
      raster_obj
    )
  )

  pixel_limits_idx <- as.numeric(
    quantile(
      pixel_values_idx,
      probs = c(0.02, 0.98),
      na.rm = TRUE
    )
  )

  if (
    !all(is.finite(pixel_limits_idx)) ||
      diff(pixel_limits_idx) <= 0
  ) {
    pixel_limits_idx <- range(
      pixel_values_idx,
      na.rm = TRUE
    )
  }

  # 4 equally spaced ticks for pixel-level zooms.
  pixel_breaks_idx <- seq(
    pixel_limits_idx[1],
    pixel_limits_idx[2],
    length.out = 4
  )

  # ----------------------------------------------------------
  # Pixel-level zoom plots
  # ----------------------------------------------------------

  zoom_left_idx <- build_zoom_plot(
    box_sfc = left_zoom_box,
    canopy_sf = canopy_idx,
    raster_obj = raster_obj,
    pixel_limits = pixel_limits_idx,
    pixel_palette = ndvi_palette
  )

  zoom_right_idx <- build_zoom_plot(
    box_sfc = right_zoom_box,
    canopy_sf = canopy_idx,
    raster_obj = raster_obj,
    pixel_limits = pixel_limits_idx,
    pixel_palette = ndvi_palette
  )

  zoom_left_idx_grob <- ggplotGrob(
    zoom_left_idx
  )

  zoom_right_idx_grob <- ggplotGrob(
    zoom_right_idx
  )

  # ----------------------------------------------------------
  # Main map — identical geometry/layout to approved panel (b)
  # ----------------------------------------------------------

  p_main_idx <- ggplot() +

    geom_sf(
      data = canopy_idx,
      aes(fill = index_mean),
      color = "grey25",
      linewidth = 0.16
    ) +

    geom_segment(
      data = zoom_connector_df,
      aes(
        x = x,
        y = y,
        xend = xend,
        yend = yend
      ),
      inherit.aes = FALSE,
      color = "grey40",
      linewidth = 0.38,
      linetype = "22",
      lineend = "round"
    ) +

    geom_sf(
      data = zoom_boxes_sf,
      fill = NA,
      color = "#17365D",
      linewidth = 0.65
    ) +

    annotation_custom(
      grob = zoom_left_idx_grob,
      xmin = inset_left["xmin"],
      xmax = inset_left["xmax"],
      ymin = inset_left["ymin"],
      ymax = inset_left["ymax"]
    ) +

    annotation_custom(
      grob = zoom_right_idx_grob,
      xmin = inset_right["xmin"],
      xmax = inset_right["xmax"],
      ymin = inset_right["ymin"],
      ymax = inset_right["ymax"]
    ) +

    scale_fill_gradientn(
      colours = ndvi_palette,
      limits = mean_limits_idx,
      breaks = mean_breaks_idx,
      oob = squish,
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
      xlim = xlim_common,
      ylim = ylim_common,
      expand = FALSE,
      clip = "on"
    ) +

    scale_x_continuous(
      breaks = x_breaks,
      labels = utm_labels
    ) +

    scale_y_continuous(
      breaks = y_breaks,
      labels = utm_labels
    ) +

    labs(
      x = "Easting (m)",
      y = "Northing (m)"
    ) +

    theme_map_pub() +

    theme(
      legend.position = "none"
    )

  # ----------------------------------------------------------
  # Mean legend
  # ----------------------------------------------------------

  mean_legend_plot_idx <- ggplot(
    data.frame(
      x = 1,
      y = 1,
      z = mean(mean_limits_idx)
    ),
    aes(
      x = x,
      y = y,
      fill = z
    )
  ) +

    geom_tile() +

    scale_fill_gradientn(
      colours = ndvi_palette,
      limits = mean_limits_idx,
      breaks = mean_breaks_idx,
      labels = scales::label_number(
        accuracy = 0.001,
        trim = TRUE
      ),
      oob = squish,
      name = paste(
        "Mean",
        index_name
      ),
      guide = guide_colorbar(
        title.position = "top",
        title.hjust = 0.5,
        barheight = unit(
          27,
          "mm"
        ),
        barwidth = unit(
          4.8,
          "mm"
        ),
        ticks = TRUE,
        frame.colour = "grey45",
        frame.linewidth = 0.25
      )
    ) +

    theme_void() +

    theme(
      legend.position = "right",

      legend.title = element_text(
        size = TXT_LEGEND_TITLE,
        face = "bold",
        hjust = 0.5
      ),

      legend.text = element_text(
        size = TXT_LEGEND_VALUE
      ),

      plot.margin = margin(
        0,
        2,
        0,
        0
      )
    )

  # ----------------------------------------------------------
  # Pixel legend
  # ----------------------------------------------------------

  pixel_legend_plot_idx <- ggplot(
    data.frame(
      x = 1,
      y = 1,
      z = mean(pixel_limits_idx)
    ),
    aes(
      x = x,
      y = y,
      fill = z
    )
  ) +

    geom_tile() +

    scale_fill_gradientn(
      colours = ndvi_palette,
      limits = pixel_limits_idx,
      breaks = pixel_breaks_idx,
      labels = scales::label_number(
        accuracy = 0.01,
        trim = TRUE
      ),
      oob = squish,
      name = paste(
        "Pixel",
        index_name
      ),
      guide = guide_colorbar(
        title.position = "top",
        title.hjust = 0.5,
        barheight = unit(
          27,
          "mm"
        ),
        barwidth = unit(
          4.8,
          "mm"
        ),
        ticks = TRUE,
        frame.colour = "grey45",
        frame.linewidth = 0.25
      )
    ) +

    theme_void() +

    theme(
      legend.position = "right",

      legend.title = element_text(
        size = TXT_LEGEND_TITLE,
        face = "bold",
        hjust = 0.5
      ),

      legend.text = element_text(
        size = TXT_LEGEND_VALUE
      ),

      plot.margin = margin(
        0,
        2,
        0,
        0
      )
    )

  mean_legend_idx <- cowplot::get_legend(
    mean_legend_plot_idx
  )

  pixel_legend_idx <- cowplot::get_legend(
    pixel_legend_plot_idx
  )

  list(
    main_plot = p_main_idx,
    mean_legend = mean_legend_idx,
    pixel_legend = pixel_legend_idx,
    mean_limits = mean_limits_idx,
    pixel_limits = pixel_limits_idx
  )
}

# ------------------------------------------------------------
# 17. BUILD PANEL (c): MSAVI
# ------------------------------------------------------------

panel_c_obj <- build_additional_spectral_panel(
  raster_obj = msavi_r,
  index_name = "MSAVI"
)

pC_main <- panel_c_obj$main_plot
legend_mean_msavi <- panel_c_obj$mean_legend
legend_pixel_msavi <- panel_c_obj$pixel_legend

# ------------------------------------------------------------
# 18. BUILD PANEL (d): WDRVI
# ------------------------------------------------------------

panel_d_obj <- build_additional_spectral_panel(
  raster_obj = wdrvi_r,
  index_name = "WDRVI"
)

pD_main <- panel_d_obj$main_plot
legend_mean_wdrvi <- panel_d_obj$mean_legend
legend_pixel_wdrvi <- panel_d_obj$pixel_legend

# ------------------------------------------------------------
# 19. INTERNAL LEGENDS FOR SPECTRAL PANELS
#
# The map geometry is NOT reduced.
# The two legends are overlaid in the lower-right white space
# of each spectral panel. This is the space gained by shifting
# the lower zoom inset left.
# ------------------------------------------------------------

embed_internal_legends <- function(
    main_plot,
    mean_legend_grob,
    pixel_legend_grob
) {
  
  white_bg <- grid::rectGrob(
    gp = grid::gpar(
      fill = "white",
      col  = NA
    )
  )
  
  cowplot::ggdraw() +
    
    cowplot::draw_plot(
      main_plot,
      x = 0,
      y = 0,
      width = 1,
      height = 1,
      scale = 1
    ) +
    
    # Fondo blanco Mean
    cowplot::draw_grob(
      white_bg,
      x = 0.625,
      y = 0.230,
      width = 0.135,
      height = 0.285
    ) +
    
    # Fondo blanco Pixel
    cowplot::draw_grob(
      white_bg,
      x = 0.825,
      y = 0.230,
      width = 0.135,
      height = 0.285
    ) +
    
    # Mean legend
    cowplot::draw_grob(
      mean_legend_grob,
      x = 0.640,
      y = 0.240,
      width = 0.100,
      height = 0.255
    ) +
    
    # Pixel legend
    cowplot::draw_grob(
      pixel_legend_grob,
      x = 0.840,
      y = 0.240,
      width = 0.100,
      height = 0.255
    )
}

# ------------------------------------------------------------
# 20. FOUR-PANEL 2 x 2 COMPOSITION
#
# IMPORTANT FIX FOR EQUAL MAP SCALE:
# Panel (a) is also wrapped inside the same ggdraw/draw_plot canvas
# logic used for the spectral panels. This preserves everything that
# was already gained, while making the main map body visually equal
# across panels (a), (b), (c) and (d).
# ------------------------------------------------------------

# Panel (a) wrapped into the same type of canvas used by panels (b-d)
pA_final <- cowplot::ggdraw() +
  cowplot::draw_plot(
    pA,
    x = 0,
    y = 0,
    width = 1,
    height = 1,
    scale = 1
  )

# Approved NDVI map + its own internal legends
pB_final <- embed_internal_legends(
  main_plot = pB_main,
  mean_legend_grob = legend_mean,
  pixel_legend_grob = legend_pixel
)

# MSAVI
pC_final <- embed_internal_legends(
  main_plot = pC_main,
  mean_legend_grob = legend_mean_msavi,
  pixel_legend_grob = legend_pixel_msavi
)

# WDRVI
pD_final <- embed_internal_legends(
  main_plot = pD_main,
  mean_legend_grob = legend_mean_wdrvi,
  pixel_legend_grob = legend_pixel_wdrvi
)

final_figure_4panels <- cowplot::plot_grid(
  pA_final,
  pB_final,
  pC_final,
  pD_final,
  ncol = 2,
  rel_widths = c(
    1.00,
    1.00
  ),
  rel_heights = c(
    1.00,
    1.00
  ),
  align = "hv",
  axis = "tblr",
  labels = c(
    "(a)",
    "(b)",
    "(c)",
    "(d)"
  ),
  label_size = TXT_PANEL_TAG,
  label_fontface = "bold",
  label_x = c(
    0.015,
    0.015,
    0.015,
    0.015
  ),
  label_y = c(
    0.952,
    0.952,
    0.952,
    0.952
  ),
  hjust = 0,
  vjust = 1
)

# ------------------------------------------------------------
# 22. EXPORT FOUR-PANEL FIGURE
# ------------------------------------------------------------

out_png_4 <- file.path(
  fig_dir,
  "Figure1_ABCD_R6_v26_PANEL_A_FINE_TUNING.png"
)

if (file.exists(out_png_4)) {

  removed_ok_4 <- file.remove(
    out_png_4
  )

  if (!removed_ok_4) {
    stop(
      "Could not overwrite the four-panel output PNG. ",
      "Close it in PowerPoint, Photos, Explorer preview, or another app, ",
      "then run the script again. Locked file: ",
      out_png_4
    )
  }
}

ggsave(
  filename = out_png_4,
  plot = final_figure_4panels,
  device = "png",
  width = 15.6,
  height = 11.4,
  units = "in",
  dpi = 600,
  bg = "white"
)

if (!file.exists(out_png_4)) {
  stop(
    "The four-panel PNG export did not create the expected file: ",
    out_png_4
  )
}

cat("\n")
cat("====================================================\n")
cat("FOUR-PANEL FIGURE EXPORTED\n")
cat("====================================================\n")
cat(out_png_4, "\n")
cat("Panels (a)–(d): same EPSG:32618 extent and same visual map-body scale\n")
cat("Panel (a) wrapped into the same canvas logic as panels (b)–(d)\n")
cat("Mean + Pixel legends embedded inside panels (b), (c), and (d)\n")
cat("Second zoom moved beside upper zoom; upper zoom unchanged\n")
cat("Internal Mean + Pixel legends with white background boxes\n")
cat("Same zoom source windows and inset positions in (b), (c), (d)\n")
cat("Soil excluded from all zooms\n")
cat("Object means: P5-P95 display stretch\n")
cat("Zoom pixels: P2-P98 display stretch\n")
cat("Original raster values were NOT modified\n")
cat("Dotted zoom connectors: enabled in panels (b), (c), and (d)\n")