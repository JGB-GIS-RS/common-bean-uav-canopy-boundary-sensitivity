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

Input: `derived/canopy_summary_by_plot.csv`

Output: `figures/Figure_4_baseline_multitemporal_context.png`

## 4. Reproduce the analysis from tracked derived tables

```r
source("scripts/11_normalized_boundary_sensitivity.R")
source("scripts/12_robustness_analysis.R")
source("scripts/14_figure_5_geometric_consequences_boundary_perturbation.R")
source("scripts/13_boundary_sensitivity_figures.R")
```

This reproduces the normalized response tables, direction-specific beta estimates, robustness diagnostics, Figure 5, Figure 6, Figure 7, Figure S1, and Figure S2. Figure 7 uses the tracked `derived/radial_background/radial_ring_observations.csv`.

## 5. Full spatial regeneration

Create local `data/spatial/flight01` through `flight05` directories and supply the vector/raster inputs documented in Scripts 00, 01, 09, and 10.

Then run:

```r
source("scripts/00_build_canopy_geopackages.R")
source("scripts/01_extract_canopy_statistics.R")
source("scripts/09_boundary_perturbation.R")
source("scripts/10_radial_background_analysis.R")
source("scripts/11_normalized_boundary_sensitivity.R")
source("scripts/12_robustness_analysis.R")
source("scripts/14_figure_5_geometric_consequences_boundary_perturbation.R")
source("scripts/13_boundary_sensitivity_figures.R")
```

Script 09 performs a baseline-reproduction QA against `derived/canopy_summary_by_plot.csv`.

## 6. Analytical hierarchy

Primary manuscript metrics:
- `|beta_erosion|`
- `|beta_dilation|`

The combined beta estimated jointly from erosion and dilation is a supporting diagnostic. Perturbation levels are deterministic transformations, not experimental replicates. P1–P5 are the five spatial observational units. No inferential p-values or confidence intervals are generated.

## 7. Tracked products

- `derived/canopy_summary_by_plot.csv`: 25 baseline plot × acquisition records.
- `derived/boundary_sensitivity/`: perturbation observations, geometry QA, normalized responses, direction-specific sensitivity, and robustness outputs.
- `derived/radial_background/`: ring observations and radial-gradient summaries for 0–5, 5–10, 10–15, and 15–20 cm.

## 8. Large-file policy

Raw UAV photographs, full orthomosaics, and analysis GeoTIFF/GeoPackage inputs are not tracked in GitHub. The compact analysis-ready tables needed to reproduce the reported numerical findings are tracked.

## 9. Figures 1–3

Figures 1 and 2 are cartographic/schematic composites. Figure 3 is an illustrative R6 spatial composite. Their provenance is documented in `docs/figure_provenance.md`.
