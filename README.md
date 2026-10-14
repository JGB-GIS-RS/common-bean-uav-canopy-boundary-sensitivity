# Direction-Dependent Sensitivity of UAV-Derived Vegetation Indices to Canopy Boundary Definition in Common Bean

This repository contains the analysis-ready data, R code, quality-assurance outputs, and reproducible computational environment supporting the manuscript:

**Direction-Dependent Sensitivity of UAV-Derived Vegetation Indices to Canopy Boundary Definition in Common Bean**

The study quantifies how controlled inward and outward modifications of segmented common-bean canopy boundaries affect UAV-derived NDVI, MSAVI, and WDRVI estimates across five UAV acquisitions from V4 to R8.

> **Repository-name note.** The repository name `common-bean-uav-nitrogen-gradient` is retained for continuity with the original 2024 field dataset. Nitrogen rate is retained as agronomic context only. The current manuscript does not estimate causal nitrogen effects, treatment effects, or a fertilizer dose-response relationship.

## Scientific scope

The current manuscript evaluates:

1. geometric consequences of controlled canopy-boundary perturbations from −3 to +3 cm;
2. direction-specific normalized sensitivity of NDVI, MSAVI, and WDRVI to inward erosion and outward dilation;
3. acquisition- and index-dependent changes in sensitivity;
4. radial spectral structure in the adjacent non-canopy environment; and
5. internal robustness to perturbation-range choice and sequential omission of individual plots.

Boundary perturbations are deterministic transformations of the same baseline masks. They are not experimental replicates and are not interpreted as empirical estimates of segmentation error.

## Study design

Five adjacent 40 m² plots (P1–P5) were observed during the 2024 common-bean crop cycle. The plots had N-rate contexts of 0, 100, 200, 300, and 400 kg N ha⁻¹ for P1–P5, respectively. Because there was one plot per N rate, P1–P5 are treated as **spatial observational units**, not as independently replicated N treatments.

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
│   ├── data/
│   ├── derived/
│   └── docs/
├── renv.lock
└── sessionInfo.txt
```

Large local spatial inputs are intentionally excluded from version control under `data/spatial/`.

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
05_figure_4_baseline_multitemporal_context.R
        ↓
Figure 4
```

### Boundary-sensitivity analysis

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
        ↓
12_robustness_analysis.R
        ↓
13_boundary_sensitivity_figures.R
        ├── Figure 6
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
        ↓
13_boundary_sensitivity_figures.R
        ↓
Figure 7
```

## Figure-to-code provenance

| Manuscript item | Repository source |
|---|---|
| Figure 1 | Cartographic/orthomosaic composite; see `docs/figure_provenance.md` |
| Figure 2 | Methodological schematic; see `docs/figure_provenance.md` |
| Figure 3 | Illustrative R6 spatial composite; see `docs/figure_provenance.md` |
| Figure 4 | `scripts/05_figure_4_baseline_multitemporal_context.R` |
| Figure 5 | `scripts/14_figure_5_geometric_consequences_boundary_perturbation.R` |
| Figure 6 | `scripts/13_boundary_sensitivity_figures.R` |
| Figure 7 | `scripts/13_boundary_sensitivity_figures.R` |
| Figure S1 | `scripts/13_boundary_sensitivity_figures.R` |
| Figure S2 | `scripts/13_boundary_sensitivity_figures.R` |

## Analysis-ready data

The tracked tables are sufficient to reproduce the manuscript's numerical sensitivity, robustness, radial, and figure-level summaries without the raw UAV photographs.

Current baseline:
- `derived/canopy_summary_by_plot.csv` — 25 plot × acquisition records used for Figure 4 and baseline QA.

Key sensitivity products:
- `derived/boundary_sensitivity/boundary_perturbation_observations.csv`
- `derived/boundary_sensitivity/boundary_geometry_qa.csv`
- `derived/boundary_sensitivity/normalized_boundary_response_observations.csv`
- `derived/boundary_sensitivity/directional_beta_by_plot.csv`
- `derived/boundary_sensitivity/directional_robustness_range_summary.csv`
- `derived/boundary_sensitivity/directional_robustness_leave_one_subplot_out_summary.csv`
- `derived/radial_background/radial_ring_observations.csv`
- `derived/radial_background/radial_gradient_by_plot.csv`

See `docs/data_dictionary.md` and `docs/boundary_sensitivity_data_dictionary.md`.

## Reproducibility levels

**Analytical reproduction from a clean clone.** Tracked CSV files reproduce the numerical sensitivity, robustness, radial summaries, and Figures 4–7/S1–S2 using Scripts 05 and 11–14.

**Full spatial regeneration.** Scripts 00, 01, 09, and 10 additionally require local vector/raster inputs under `data/spatial/flight01` through `flight05`. These large inputs are not tracked in GitHub.

## Statistical scope

- P1–P5 are the five available spatial observational units.
- Boundary perturbations are deterministic transformations and are not independent replicates.
- UAV acquisitions are repeated observations of the same spatial units.
- N rate is agronomic context only.
- No p-values, confidence intervals, or analysis-of-variance comparisons are used for the boundary-sensitivity or radial analyses.
- Primary sensitivity metrics are direction-specific `|beta_erosion|` and `|beta_dilation|`.
- Plot-level values are summarized with medians and interquartile ranges.
- Internal robustness is assessed using the 1–2 versus 1–3 cm perturbation range and leave-one-plot-out diagnostics.

## Reproducible R environment

The repository includes `renv.lock` and `sessionInfo.txt`. The recorded environment is R 4.4.1 on Windows 11, including `terra` 1.8-54, `sf` 1.0-21, `dplyr` 1.1.4, `ggplot2` 3.5.2, `patchwork` 1.3.1, and `renv` 1.2.4.

Restore with:

```r
install.packages("renv")
renv::restore()
```

See `docs/reproducibility.md` for execution details.

## Legacy material

The earlier harvest/yield-oriented master dataset, field-harvest table, data dictionary, scripts, and exploratory outputs are preserved under `legacy_previous_manuscript/` for provenance. They do **not** support the claims or figures of the current boundary-sensitivity manuscript.

## Licenses

R code is released under the MIT License. Data tables and documentation are released under CC BY 4.0 unless otherwise stated.

## Citation

Bibliographic details and DOI for the associated manuscript will be added after publication.
