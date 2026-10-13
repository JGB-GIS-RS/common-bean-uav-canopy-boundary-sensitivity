# Direction-Dependent Sensitivity of UAV-Derived Vegetation Indices to Canopy Boundary Definition in Common Bean

This repository supports the manuscript:

**Direction-Dependent Sensitivity of UAV-Derived Vegetation Indices to Canopy Boundary Definition in Common Bean**

The study evaluates how controlled inward and outward modifications of segmented common-bean canopy boundaries affect UAV-derived NDVI, MSAVI, and WDRVI estimates across five UAV acquisitions from V4 to R8.

> **Repository-name note.** The repository name `common-bean-uav-nitrogen-gradient` is retained for continuity with the original 2024 field dataset. Nitrogen application rate is reported as agronomic context only in the current manuscript; the present analysis does **not** estimate causal nitrogen effects or a fertilizer dose–response relationship.

## Current scientific scope

The current manuscript addresses four linked questions:

1. How strongly do UAV-derived vegetation-index means change when the adopted canopy boundary is moved inward or outward by 1–3 cm?
2. Is boundary sensitivity direction dependent?
3. Does sensitivity vary among NDVI, MSAVI, WDRVI, and UAV acquisitions?
4. Does the adjacent non-canopy environment show a structured radial spectral transition away from the adopted canopy edge?

Boundary perturbations are treated as controlled sensitivity transformations around the adopted baseline masks. They are **not** interpreted as empirical estimates of segmentation error.

## Study design

The field study used common bean (*Phaseolus vulgaris* L.) cv. Calima during the 2024 crop cycle. The experimental area comprised five adjacent 40 m² plots (P1–P5).

| Plot | N rate (kg N ha⁻¹) |
|---|---:|
| P1 | 0 |
| P2 | 100 |
| P3 | 200 |
| P4 | 300 |
| P5 | 400 |

Each N rate was associated with one fixed spatial plot. Accordingly, the five plots are treated in the current manuscript as **spatial observational units with differing agronomic contexts**, not as independently replicated N treatments.

## UAV acquisition sequence

| Flight | Date | Observed stage | Days after N application |
|---|---|---|---:|
| 1 | 2024-09-07 | V4 | 8 |
| 2 | 2024-09-14 | R5 | 15 |
| 3 | 2024-10-02 | R6 | 33 |
| 4 | 2024-10-09 | R7 | 40 |
| 5 | 2024-10-16 | R8 | 47 |

Multispectral imagery was acquired with a DJI Phantom 3 Professional equipped with a MAPIR Survey2 Red/NIR camera. The current analysis uses projected canopy area and canopy-level NDVI, MSAVI, and WDRVI values derived from the final segmented masks.

## Repository status

The repository already contains the validated baseline canopy dataset, spatial-extraction code, quality-assurance outputs, reproducible R environment, and the multitemporal baseline figure workflow used by the current manuscript.

The **boundary-perturbation, radial-profile, and robustness analysis files for the current manuscript are being consolidated into this repository before submission**. Until that consolidation is complete, the repository should not be interpreted as a complete end-to-end reproduction package for the current manuscript.

Some scripts and derived tables remain from an earlier exploratory manuscript focused on nitrogen-gradient and UAV–yield relationships. Those legacy analyses are **not part of the inferential or analytical workflow of the current boundary-sensitivity manuscript** and will be separated from the current workflow before submission.

## Baseline data currently available

- [Analysis-ready 25-row baseline dataset](data/common_bean_uav_master_dataset.csv)
- [Canopy summary by plot and UAV acquisition](derived/canopy_summary_by_plot.csv)
- [Canopy statistics by plot and vegetation index](derived/canopy_statistics_by_plot_index.csv)
- [Spatial extraction QA](derived/qa_spatial_extraction.csv)
- [Canopy GeoPackage QA](derived/qa_canopy_geopackages.csv)
- [Data dictionary](docs/data_dictionary.md)
- [Reproducibility instructions](docs/reproducibility.md)

The baseline dataset contains one record for each `plot × UAV acquisition` combination (5 plots × 5 acquisitions = 25 records). These observations are longitudinal measurements, not 25 independent experimental replicates.

## Baseline spatial-processing workflow

The currently tracked spatial-processing scripts establish the baseline canopy dataset used by the current manuscript:

```text
Original segmented-canopy polygons
                ↓
00_build_canopy_geopackages.R
                ↓
Consolidated canopy GeoPackages
                +
NDVI / MSAVI / WDRVI rasters
                ↓
01_extract_canopy_statistics.R
                ↓
derived/canopy_statistics_by_plot_index.csv
derived/canopy_summary_by_plot.csv
derived/qa_spatial_extraction.csv
                ↓
02_build_master_dataset.R
                ↓
data/common_bean_uav_master_dataset.csv
```

### Baseline scripts relevant to the current manuscript

| Script | Role in the current manuscript |
|---|---|
| `00_build_canopy_geopackages.R` | Consolidates plot-level segmented-canopy shapefiles into one GeoPackage per UAV acquisition and validates geometry/area preservation. |
| `01_extract_canopy_statistics.R` | Extracts baseline projected canopy area and NDVI/MSAVI/WDRVI statistics using the final canopy geometries. |
| `02_build_master_dataset.R` | Builds the 25-row longitudinal baseline dataset used for multitemporal context. |
| `05_figure_4_multitemporal_uav_metrics.R` | Reproduces the baseline multitemporal canopy-area and vegetation-index trajectories corresponding to Figure 4 of the current manuscript. |

The raster extraction implemented in `01_extract_canopy_statistics.R` uses `terra::extract(..., ID = TRUE, cells = TRUE)`; duplicate raster cells associated with more than one canopy object are removed before plot-level aggregation.

## Boundary-sensitivity analysis package to be added before submission

The completed repository for the current manuscript will include analysis-ready tables and R code sufficient to reproduce the direction-specific sensitivity, radial, and robustness analyses without requiring the raw UAV photographs.

The core analytical data products will include:

### 1. Baseline canopy metrics

One record per `plot × UAV acquisition`, containing at least:

- baseline canopy area;
- mean NDVI;
- mean MSAVI;
- mean WDRVI.

These values are already represented in the current baseline dataset.

### 2. Boundary-perturbation dataset

One record per:

`plot × UAV acquisition × vegetation index × perturbation distance`

for perturbations of −3, −2, −1, 0, +1, +2, and +3 cm.

The table will contain the quantities needed to reproduce:

- effective mask area after perturbation;
- proportional mask-area change (ΔA);
- perturbed vegetation-index mean;
- relative vegetation-index response (ΔVI);
- direction-specific origin-constrained sensitivity coefficients;
- median and interquartile-range summaries;
- perturbation-range robustness diagnostics;
- leave-one-plot-out diagnostics;
- erosion–dilation asymmetry.

### 3. Radial-profile dataset

One record per:

`plot × UAV acquisition × vegetation index × radial interval`

for the non-overlapping external intervals:

- 0–5 cm;
- 5–10 cm;
- 10–15 cm;
- 15–20 cm.

This dataset will support the radial slopes, monotonicity diagnostics, inner-versus-outer comparisons, and the manuscript radial-profile figure.

## Spatial inputs

The spatial-processing scripts expect local inputs under `data/spatial/flight01` through `data/spatial/flight05`, including:

- final segmented-canopy polygons or consolidated canopy GeoPackages;
- NDVI GeoTIFF;
- MSAVI GeoTIFF;
- WDRVI GeoTIFF.

These spatial files are not currently tracked in GitHub because of their size. The current manuscript can be reproduced analytically from the compact derived datasets once the boundary-sensitivity tables and scripts are added. A permanent external archive for larger spatial products can be linked separately if required.

## Statistical scope

The statistical framework of the current manuscript is descriptive and sensitivity-oriented.

- P1–P5 are the five available spatial observational units.
- Boundary perturbations are deterministic transformations of the same baseline masks and are not independent replicates.
- UAV acquisitions are repeated observations of the same spatial units through time.
- Nitrogen rate is retained as agronomic context and is not used for causal treatment inference.
- Differences among V4–R8 are interpreted as multitemporal observational patterns rather than isolated causal phenological effects.
- Direction-specific sensitivity is summarized primarily with plot-level `|β|` values, medians, and interquartile ranges.
- Robustness is evaluated by perturbation-range reduction and leave-one-plot-out influence diagnostics rather than by p-values or treatment-level ANOVA.

## Legacy exploratory analyses

The following currently tracked files originate from the earlier exploratory nitrogen/yield manuscript and are **not used to support the conclusions of the current boundary-sensitivity manuscript**:

- `scripts/03_descriptive_analysis.R` where it produces N/yield association outputs;
- `scripts/06_figure_5_uav_yield_correlations.R`;
- `scripts/07_figure_6_final_grain_yield.R`;
- `scripts/08_figure_S1_uav_yield_scatterplots.R`;
- derived files whose names contain `yield_associations`, `N_associations`, or `final_harvest`.

These files are retained temporarily for provenance and will be moved to a clearly separated legacy location before manuscript submission.

## Reproducible R environment

The computational environment is captured with `renv`.

- R version: 4.4.1
- Operating system used for the recorded environment: Windows 11
- `terra`: 1.8-54
- `sf`: 1.0-21
- `dplyr`: 1.1.4
- `ggplot2`: 3.5.2
- `cowplot`: 1.2.0
- `patchwork`: 1.3.1
- `scales`: 1.3.0
- `renv`: 1.2.4

A third party can restore the recorded package environment with:

```r
install.packages("renv")
renv::restore()
```

See [docs/reproducibility.md](docs/reproducibility.md) and `renv.lock` for the complete dependency record.

## License

R source code in `scripts/` is licensed under the MIT License; see [LICENSE](LICENSE).

Data tables, derived analytical outputs, and documentation are licensed under the Creative Commons Attribution 4.0 International License (CC BY 4.0), unless otherwise stated; see [LICENSE-DATA.md](LICENSE-DATA.md).

## Citation

Bibliographic details and DOI for the associated manuscript will be added after publication.

Until then, please cite the repository together with the manuscript title given above when using these data or scripts.
