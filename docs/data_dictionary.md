# Baseline Canopy Data Dictionary (corrected WDRVI, α = 0.1)

The tracked table `derived/canopy_summary_by_subplot.csv` contains **25 rows** (five fixed plots × five UAV acquisitions), one row per `subplot × growth_stage`.

| Field | Units/type | Meaning |
|---|---|---|
| `flight` | integer 1–5 | Chronological acquisition number |
| `date` | YYYY-MM-DD | Acquisition date |
| `growth_stage` | V4, R5, R6, R7, R8 | Observed crop development stage (coincides with a single acquisition date) |
| `subplot` | P1–P5 | Fixed spatial observational unit, not an independent N-treatment replicate |
| `N_rate_kg_ha` | kg N ha⁻¹ | Agronomic context only (P1–P5: 0, 100, 200, 300, 400) |
| `canopy_area_m2` | m² | Projected area of the original segmented canopy mask |
| `canopy_polygon_count` | integer | Number of original canopy polygon objects; not a plant count |
| `NDVI_mean`, `NDVI_median`, `NDVI_sd` | dimensionless | NDVI summaries across raster cells selected by the original mask |
| `MSAVI_mean`, `MSAVI_median`, `MSAVI_sd` | dimensionless | MSAVI summaries across raster cells selected by the original mask |
| `WDRVI_mean`, `WDRVI_median`, `WDRVI_sd` | dimensionless | **Corrected WDRVI using α = 0.1** |

The underlying indices are pixel-level data. For a fixed α, pixel WDRVI is a nonlinear monotonic transform of pixel NDVI; their spatial means are not related by direct application of that nonlinear transform to the mean NDVI.

Additional tables:

- `derived/canopy_statistics_by_subplot_index.csv`: 75 plot × acquisition × index baseline summaries, including index-specific extraction diagnostics.
- `derived/qa_spatial_extraction.csv`: 25 spatial and raster-support QA records.
- `derived/boundary_sensitivity/`: 17 perturbation, sensitivity, directional robustness, and QA tables.
- `derived/radial_background/`: 4 radial-analysis tables.

`subplot` is the authoritative column name in these current CSV files; older documentation using `plot` describes superseded exports. The repeated UAV acquisitions and deterministic perturbations are not independent experimental replicates.

Refer to [boundary sensitivity dictionary](boundary_sensitivity_data_dictionary.md) for coefficient and perturbation definitions.
