# Reproducibility

This document describes how to reproduce the computational results of the current canopy-boundary sensitivity manuscript.

## 1. Restore the R environment

From the repository root:

```r
install.packages("renv")
renv::restore()
```

The authoritative package record is `renv.lock`. The captured runtime is R 4.4.1 on Windows 11.

## 2. Repository-root detection

Current-manuscript scripts detect the repository root using the presence of both `renv.lock` and the `scripts/` directory. They do not depend on a machine-specific absolute path.

## 3. Reproduce Figure 4 from tracked baseline data

```r
source("scripts/05_figure_4_baseline_multitemporal_context.R")
```

Input:

`data/common_bean_uav_master_dataset.csv`

Output:

`figures/Figure_4_baseline_multitemporal_context.png`

## 4. Reproduce the analysis from tracked derived tables

The repository tracks the outputs of the spatial extraction/perturbation stages. Therefore Scripts 11–14 can be run without the large spatial rasters.

Recommended order:

```r
source("scripts/11_normalized_boundary_sensitivity.R")
source("scripts/12_robustness_analysis.R")
source("scripts/14_figure_5_geometric_consequences_boundary_perturbation.R")
source("scripts/13_boundary_sensitivity_figures.R")
```

This reproduces the normalized boundary-response tables, direction-specific beta estimates, robustness diagnostics, Figure 5, Figure 6, Figure 7, Figure S1, and Figure S2.

## 5. Full spatial regeneration

To rerun Scripts 09 and 10 from spatial inputs, create:

```text
data/spatial/
├── flight01/
├── flight02/
├── flight03/
├── flight04/
└── flight05/
```

Each flight directory must contain:

- `canopy_YYYYMMDD.gpkg`
- `ndvi_YYYYMMDD.tif`
- `msavi_YYYYMMDD.tif`
- `wdrvi_YYYYMMDD.tif`

Then run:

```r
source("scripts/09_boundary_perturbation.R")
source("scripts/10_radial_background_analysis.R")
source("scripts/11_normalized_boundary_sensitivity.R")
source("scripts/12_robustness_analysis.R")
source("scripts/14_figure_5_geometric_consequences_boundary_perturbation.R")
source("scripts/13_boundary_sensitivity_figures.R")
```

Script 09 performs a baseline-reproduction QA against `derived/canopy_summary_by_plot.csv`.

## 6. Analytical hierarchy

The primary manuscript metrics are the direction-specific normalized sensitivity coefficients:

- `|beta_erosion|`
- `|beta_dilation|`

The combined beta estimated jointly from erosion and dilation is retained as a supporting diagnostic.

Perturbation levels are deterministic transformations, not experimental replicates. P1–P5 are the five spatial observational units. No inferential p-values or confidence intervals are generated for these analyses.

## 7. Tracked derived products

### Boundary sensitivity
`derived/boundary_sensitivity/`

Contains the perturbation observations, geometry QA, baseline-reproduction QA, normalized responses, beta estimates, directional summaries, and robustness outputs.

### Radial background
`derived/radial_background/`

Contains ring-level observations and radial-gradient summaries for 0–5, 5–10, 10–15, and 15–20 cm external non-canopy rings.

## 8. Large-file policy

Raw UAV photographs, full orthomosaics, and the analysis GeoTIFF/GeoPackage spatial inputs are not tracked in GitHub. This avoids duplicating large spatial assets while preserving all compact analysis-ready data needed to reproduce the reported numerical findings.

## 9. Figures 1–3

Figures 1 and 2 are cartographic/schematic composites. Figure 3 is an illustrative R6 spatial composite. Their provenance is documented in `docs/figure_provenance.md`. The quantitative findings of the manuscript are reproduced from the tracked analytical tables and scripts.
