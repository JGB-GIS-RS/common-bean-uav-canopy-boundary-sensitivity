# Direction-Dependent Sensitivity of UAV-Derived Vegetation Indices to Canopy Boundary Definition in Common Bean

This repository contains the analysis-ready data, R code, quality-assurance outputs, and reproducible computational environment supporting the manuscript:

**Direction-Dependent Sensitivity of UAV-Derived Vegetation Indices to Canopy Boundary Definition in Common Bean**

The study quantifies how controlled inward and outward modifications of segmented common-bean canopy boundaries affect UAV-derived NDVI, MSAVI, and WDRVI estimates across five UAV acquisitions from V4 to R8.

> **Repository-name note.** The repository name `common-bean-uav-nitrogen-gradient` is retained for continuity with the original 2024 field dataset. Nitrogen rate is retained as agronomic context only in the current manuscript. The current analysis does not estimate causal nitrogen effects, treatment effects, or a fertilizer dose-response relationship.

## Scientific scope

The current manuscript evaluates:

1. the geometric consequences of controlled canopy-boundary perturbations of −3 to +3 cm;
2. direction-specific normalized sensitivity of NDVI, MSAVI, and WDRVI to inward erosion and outward dilation;
3. acquisition- and index-dependent changes in sensitivity;
4. radial spectral structure in the adjacent non-canopy environment; and
5. internal robustness to perturbation-range choice and sequential omission of individual plots.

Boundary perturbations are deterministic transformations of the same baseline masks. They are not experimental replicates and are not interpreted as empirical estimates of segmentation error.

## Study design

Five adjacent 40 m² plots (P1–P5) were observed during the 2024 common-bean crop cycle. Each plot had a different N-rate context:

| Plot | N rate (kg N ha⁻¹) |
|---|---:|
| P1 | 0 |
| P2 | 100 |
| P3 | 200 |
| P4 | 300 |
| P5 | 400 |

Because there was one plot per N rate, P1–P5 are treated as **spatial observational units**, not as independently replicated N treatments.

### UAV acquisitions

| Flight | Date | Stage | Days after N application |
|---|---|---|---:|
| 1 | 2024-09-07 | V4 | 8 |
| 2 | 2024-09-14 | R5 | 15 |
| 3 | 2024-10-02 | R6 | 33 |
| 4 | 2024-10-09 | R7 | 40 |
| 5 | 2024-10-16 | R8 | 47 |

## Repository structure

```text
.
├── data/
│   └── common_bean_uav_master_dataset.csv
├── derived/
│   ├── canopy_statistics_by_plot_index.csv
│   ├── canopy_summary_by_plot.csv
│   ├── qa_canopy_geopackages.csv
│   ├── qa_spatial_extraction.csv
│   ├── boundary_sensitivity/
│   │   └── [17 tracked analysis/QA tables]
│   └── radial_background/
│       └── [4 tracked radial-analysis tables]
├── scripts/
│   ├── 00_build_canopy_geopackages.R
│   ├── 01_extract_canopy_statistics.R
│   ├── 02_build_master_dataset.R
│   ├── 05_figure_4_baseline_multitemporal_context.R
│   ├── 09_boundary_perturbation.R
│   ├── 10_radial_background_analysis.R
│   ├── 11_normalized_boundary_sensitivity.R
│   ├── 12_robustness_analysis.R
│   ├── 13_boundary_sensitivity_figures.R
│   └── 14_figure_5_geometric_consequences_boundary_perturbation.R
├── docs/
│   ├── data_dictionary.md
│   ├── boundary_sensitivity_data_dictionary.md
│   ├── figure_provenance.md
│   └── reproducibility.md
├── legacy_previous_manuscript/
│   ├── README.md
│   ├── scripts/
│   └── derived/
├── renv.lock
└── sessionInfo.txt
```

## Reproducible workflow

### Baseline canopy products

```text
segmented canopy polygons + VI rasters
        ↓
00_build_canopy_geopackages.R
        ↓
01_extract_canopy_statistics.R
        ↓
derived/canopy_summary_by_plot.csv
        ↓
02_build_master_dataset.R
        ↓
data/common_bean_uav_master_dataset.csv
```

### Current boundary-sensitivity analysis

```text
baseline canopy masks + NDVI/MSAVI/WDRVI rasters
        ↓
09_boundary_perturbation.R
        ├── boundary_perturbation_observations.csv
        ├── boundary_geometry_qa.csv
        ├── crossplot_overlap_qa.csv
        └── baseline_reproduction_check.csv
        ↓
11_normalized_boundary_sensitivity.R
        ├── normalized_boundary_response_observations.csv
        ├── normalized_boundary_sensitivity_by_plot.csv
        └── normalized_boundary_sensitivity_summary.csv
        ↓
12_robustness_analysis.R
        ├── direction-specific beta tables
        ├── perturbation-range robustness tables
        ├── leave-one-plot-out tables
        └── directional asymmetry
        ↓
13_boundary_sensitivity_figures.R
        ├── Figure 6
        ├── Figure 7
        ├── Figure S1
        └── Figure S2

09_boundary_perturbation.R
        ↓
14_figure_5_geometric_consequences_boundary_perturbation.R
        ↓
Figure 5

baseline canopy masks + VI rasters
        ↓
10_radial_background_analysis.R
        ├── radial_ring_observations.csv
        ├── radial_ring_summary.csv
        ├── radial_gradient_by_plot.csv
        └── radial_gradient_summary.csv
        ↓
13_boundary_sensitivity_figures.R
        ↓
Figure 7
```

Figure 4 is reproduced directly from the tracked baseline master dataset using `05_figure_4_baseline_multitemporal_context.R`.

## Figure-to-code provenance

| Manuscript item | Repository source |
|---|---|
| Figure 1 | Cartographic/orthomosaic composite; see `docs/figure_provenance.md` |
| Figure 2 | Methodological schematic; see `docs/figure_provenance.md` |
| Figure 3 | Illustrative spatial composite based on baseline R6 mask, NDVI support, and controlled ±3 cm perturbation; see `docs/figure_provenance.md` |
| Figure 4 | `scripts/05_figure_4_baseline_multitemporal_context.R` |
| Figure 5 | `scripts/14_figure_5_geometric_consequences_boundary_perturbation.R` |
| Figure 6 | `scripts/13_boundary_sensitivity_figures.R` |
| Figure 7 | `scripts/13_boundary_sensitivity_figures.R` |
| Figure S1 | `scripts/13_boundary_sensitivity_figures.R` |
| Figure S2 | `scripts/13_boundary_sensitivity_figures.R` |

## Analysis-ready data

The tracked derived tables are sufficient to reproduce the manuscript's numerical sensitivity, robustness, radial, and figure-level summaries without access to the raw UAV photographs.

Key tables include:

- `derived/boundary_sensitivity/boundary_perturbation_observations.csv`
- `derived/boundary_sensitivity/boundary_geometry_qa.csv`
- `derived/boundary_sensitivity/normalized_boundary_response_observations.csv`
- `derived/boundary_sensitivity/directional_beta_by_plot.csv`
- `derived/boundary_sensitivity/directional_robustness_range_summary.csv`
- `derived/boundary_sensitivity/directional_robustness_leave_one_subplot_out_summary.csv`
- `derived/radial_background/radial_ring_observations.csv`
- `derived/radial_background/radial_gradient_by_plot.csv`

See `docs/boundary_sensitivity_data_dictionary.md` for the analytical hierarchy and table definitions.

## Spatial inputs and reproducibility levels

Large spatial inputs are intentionally not tracked in GitHub. Scripts 09 and 10 require local files under `data/spatial/flight01` through `flight05`:

- consolidated canopy GeoPackages;
- NDVI GeoTIFFs;
- MSAVI GeoTIFFs;
- WDRVI GeoTIFFs.

Accordingly, the repository supports two reproducibility levels:

**Analytical reproduction from a clean clone.** The tracked CSV files and scripts reproduce the normalized sensitivity, robustness, radial summaries, and Figures 4–7/S1–S2.

**Full spatial regeneration.** Re-running the raster/vector extraction in Scripts 09 and 10 additionally requires the large spatial inputs, which can be archived separately if needed.

## Statistical scope

- P1–P5 are the five available spatial observational units.
- Boundary perturbations are deterministic transformations and are not independent replicates.
- UAV acquisitions are repeated observations of the same spatial units.
- N rate is agronomic context only.
- No p-values, confidence intervals, or treatment-level ANOVA are used for the boundary-sensitivity or radial analyses.
- Primary sensitivity metrics are direction-specific `|beta_erosion|` and `|beta_dilation|`.
- Plot-level values are summarized with medians and interquartile ranges.
- Internal robustness is assessed using the 1–2 versus 1–3 cm perturbation range and leave-one-plot-out diagnostics.

## Reproducible R environment

The repository includes `renv.lock` and `sessionInfo.txt`.

Recorded environment:

- R 4.4.1
- Windows 11
- terra 1.8-54
- sf 1.0-21
- dplyr 1.1.4
- ggplot2 3.5.2
- cowplot 1.2.0
- patchwork 1.3.1
- scales 1.3.0
- renv 1.2.4

Restore with:

```r
install.packages("renv")
renv::restore()
```

See `docs/reproducibility.md` for execution details.

## Legacy material

Files used only for the earlier exploratory N/yield manuscript are preserved under `legacy_previous_manuscript/` for provenance. They do **not** support the claims or figures of the current boundary-sensitivity manuscript.

## Licenses

R code is released under the MIT License. Data tables and documentation are released under CC BY 4.0 unless otherwise stated.

## Citation

Bibliographic details and DOI for the associated manuscript will be added after publication.
