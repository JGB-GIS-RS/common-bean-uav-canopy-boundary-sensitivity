# Baseline Canopy Data Dictionary

This document describes `derived/canopy_summary_by_plot.csv`, the 25-row baseline canopy table used by the current manuscript.

| Variable | Type | Unit / format | Description |
|---|---|---|---|
| `flight` | Integer | 1–5 | Sequential UAV acquisition number. |
| `date` | Date | YYYY-MM-DD | UAV acquisition date. |
| `growth_stage` | Categorical | V4, R5, R6, R7, R8 | Observed common-bean growth stage. |
| `plot` | Categorical | P1–P5 | Spatial observational unit. |
| `N_rate_kg_ha` | Numeric | kg N ha⁻¹ | Agronomic N-rate context; not used for causal treatment inference in the current manuscript. |
| `canopy_area_m2` | Numeric | m² | Total projected segmented-canopy area within the plot. |
| `canopy_polygon_count` | Integer | count | Number of segmented canopy objects; not a plant count. |
| `NDVI_mean`, `NDVI_median`, `NDVI_sd` | Numeric | dimensionless | Baseline NDVI summaries within the original canopy mask. |
| `MSAVI_mean`, `MSAVI_median`, `MSAVI_sd` | Numeric | dimensionless | Baseline MSAVI summaries within the original canopy mask. |
| `WDRVI_mean`, `WDRVI_median`, `WDRVI_sd` | Numeric | dimensionless | Baseline WDRVI summaries within the original canopy mask. |

The table has one row per `plot × UAV acquisition`: 5 plots × 5 acquisitions = 25 rows. These are longitudinal observations of the same five spatial units, not 25 independent experimental replicates.

The table supplies the baseline (`d = 0`) context shown in Figure 4 and the reference for baseline-reproduction QA in Script 09. See `docs/boundary_sensitivity_data_dictionary.md` for the perturbation, directional-sensitivity, robustness, and radial tables.
