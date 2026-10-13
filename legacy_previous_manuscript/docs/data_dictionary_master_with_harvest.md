# Data Dictionary

This document describes the variables in `data/common_bean_uav_master_dataset.csv`.

| Variable | Type | Unit / format | Description |
|---|---|---|---|
| `flight` | Integer | 1–5 | Sequential UAV flight number. |
| `date` | Date | YYYY-MM-DD | UAV acquisition date. |
| `growth_stage` | Categorical | V4, R5, R6, R7, R8 | Common-bean growth stage associated with the UAV acquisition. |
| `plot` | Categorical | P1–P5 | Field plot identifier. |
| `N_rate_kg_ha` | Numeric | kg N ha⁻¹ | Nitrogen application rate associated with the plot. |
| `canopy_area_m2` | Numeric | m² | Total projected canopy area segmented within the plot at the corresponding UAV acquisition. |
| `canopy_polygon_count` | Integer | count | Number of segmented canopy objects within the plot. This is not equivalent to plant count because individual canopies can merge during crop development. |
| `NDVI_mean` | Numeric | dimensionless | Mean Normalized Difference Vegetation Index calculated over canopy pixels within the plot. |
| `MSAVI_mean` | Numeric | dimensionless | Mean Modified Soil-Adjusted Vegetation Index calculated over canopy pixels within the plot. |
| `WDRVI_mean` | Numeric | dimensionless | Mean Wide Dynamic Range Vegetation Index calculated over canopy pixels within the plot. |
| `harvest_area_m2` | Numeric | m² | Ground area effectively harvested for grain-yield determination. |
| `harvested_grain_kg` | Numeric | kg | Total harvested grain mass for the plot at final harvest. |
| `grain_yield_t_ha` | Numeric | t ha⁻¹ | Grain yield standardized by harvested ground area. |

## Row structure

The dataset has one row for each combination of:

`plot × flight`

Thus, 5 plots × 5 flights = 25 rows.

## Nitrogen-rate assignment

| Plot | N rate (kg N ha⁻¹) |
|---|---:|
| P1 | 0 |
| P2 | 100 |
| P3 | 200 |
| P4 | 300 |
| P5 | 400 |

Because there is one plot per nitrogen rate, the nitrogen gradient has no independent treatment replication.

## Final-harvest variables

`harvest_area_m2`, `harvested_grain_kg`, and `grain_yield_t_ha` describe the final harvest of each plot.

These values are repeated across the five UAV-flight records for the same plot to support longitudinal joins and analysis.

They must not be interpreted as five independent harvest measurements per plot.

The final values are:

| Plot | Harvest area (m²) | Harvested grain (kg) | Grain yield (t ha⁻¹) |
|---|---:|---:|---:|
| P1 | 40 | 3.722 | 0.9305 |
| P2 | 40 | 5.077 | 1.2693 |
| P3 | 40 | 4.696 | 1.1740 |
| P4 | 40 | 7.664 | 1.9160 |
| P5 | 40 | 5.282 | 1.3205 |

## Grain-yield formula

`grain yield (t ha⁻¹) = harvested grain (kg) / harvest area (m²) × 10`

The projected UAV canopy area is not used to calculate agronomic grain yield.

## Interpretation of canopy polygon count

`canopy_polygon_count` is a segmentation attribute. Early in the crop cycle, separate plants or small canopy clusters can appear as multiple polygons. During canopy closure, adjacent objects merge.

Accordingly, the variable should be interpreted as the number of segmented canopy objects, not as a census of individual plants.

## Statistical-use note

The 25 rows are longitudinal observations, not 25 independent experimental replicates.

For analyses involving final grain yield, the experimental information remains five plot-level harvest observations. Any model using the 25-row structure must explicitly account for repeated measurements and the non-independence of repeated final-yield values.