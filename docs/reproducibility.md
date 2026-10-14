# Reproducibility guide — corrected WDRVI α = 0.1

This document distinguishes **analytical reproduction from the 24 tracked CSVs** from **full spatial regeneration**, which requires large GeoTIFF and GeoPackage inputs not hosted in this repository.

## 1. Working environment

The original recorded R environment is described by `renv.lock` and `sessionInfo.txt`. Open the repository's `common-bean-uav-canopy-boundary-sensitivity.Rproj` in RStudio. Alternatively, set the R working directory to the repository root.

```r
install.packages("renv") # only if needed
renv::restore()
```

Scripts search upward for a directory containing `scripts/` and `data/raw/`. The otherwise empty `data/raw/` directory is retained in a Git clone through `data/raw/.gitkeep`. All script paths are relative, not machine-specific.

## 2. Analytical reproduction from the tracked CSVs (no original rasters)

The published CSVs already contain the pixel-extraction and perturbation-level observations for WDRVI α = 0.1. Execute:

```r
source("scripts/04_normalized_boundary_sensitivity.R")
source("scripts/05_robustness_analysis.R")
source("scripts/07_figure_4_baseline_context.R")
source("scripts/08_figure_5_geometric_consequences.R")
source("scripts/09_figures_6_7_and_supplement.R")
```

Scripts 04 and 05 recalculate the normalized and directional sensitivity summaries and robustness diagnostics from previously derived observations. Scripts 07–09 produce Figure 4, Figure 5, Figure 6, Figure 7, Figure S1, Figure S2, and a two-page vector `Supplementary_Materials.pdf`.

Generated graphics are written under `figures/` and `figures/boundary_sensitivity/`, which are intentionally untracked. They may be regenerated from the released tables without original UAV photographs.

The Figure 3 R6 spatial-composite script (`scripts/06_figure_3_boundary_perturbation.R`) requires the corresponding original NDVI raster and segmented-canopy GeoPackage.

## 3. Full spatial regeneration from original inputs

Populate these local-only directories with the canopy polygon masks and NDVI, MSAVI and **corrected α = 0.1 WDRVI** rasters:

```text
data/raw/V4/    canopy_20240907.gpkg ndvi_20240907.tif msavi_20240907.tif wdrvi_20240907.tif
data/raw/R5/    canopy_20240914.gpkg ndvi_20240914.tif msavi_20240914.tif wdrvi_20240914.tif
data/raw/R6/    canopy_20241002.gpkg ndvi_20241002.tif msavi_20241002.tif wdrvi_20241002.tif
data/raw/R7/    canopy_20241009.gpkg ndvi_20241009.tif msavi_20241009.tif wdrvi_20241009.tif
data/raw/R8/    canopy_20241016.gpkg ndvi_20241016.tif msavi_20241016.tif wdrvi_20241016.tif
```

Then run all nine scripts in the specified order:

```r
source("scripts/01_extract_canopy_statistics.R")
source("scripts/02_boundary_perturbation.R")
source("scripts/03_radial_background_analysis.R")
source("scripts/04_normalized_boundary_sensitivity.R")
source("scripts/05_robustness_analysis.R")
source("scripts/06_figure_3_boundary_perturbation.R")
source("scripts/07_figure_4_baseline_context.R")
source("scripts/08_figure_5_geometric_consequences.R")
source("scripts/09_figures_6_7_and_supplement.R")
```

The first three scripts read the local spatial input and overwrite corresponding derived CSVs. Do not run them without the correct raster/mask inputs. The baseline reproduction check must give an absolute difference close to floating-point precision.

## 4. Published analysis targets

| Check | Value |
|---|---:|
| Baseline plot-stage rows | 25 |
| Plot-stage-index baseline rows | 75 |
| Perturbed spectral rows | 525 |
| Geometry QA rows | 175 |
| Directional beta combinations | 75 |
| Both erosion and dilation coefficients negative | 72 of 75 |
| Ring observations | 300 |
| Radial profiles with outer ring lower than inner | 75 of 75 |
| Monotonic decreasing radial profiles | 67 of 75 |
| Median directional asymmetry | 35.01% |
| Maximum directional asymmetry | 96.42% |
| Maximum baseline mean reproduction error | 4.44×10⁻¹⁶ |

See [validation](validation_alpha01.md) for stage-specific WDRVI and robustness results.

## 5. Interpretation and scope

The primary coefficients are fitted **separately for erosion and dilation** as through-origin regressions of relative vegetation-index change against effective mask-area change. The combined-direction β files are supporting diagnostics only. Relative spectral changes are normalized by `|VI_0|`; results can be amplified for a near-zero baseline index.

Five plots at distinct N rates are not replicated N treatments. The five flights are repeated observations, and perturbations/radial rings do not increase the biological sample size. No causal fertilizer-response or inferential significance claims are warranted.

## 6. Provenance and licensing

The original 2024 spatial inputs and original UAV photography are excluded from Git because of their size. Therefore, a clean clone does not reproduce the **upstream radiometric calibration, image mosaicking, or pixel extraction** unless those inputs are separately supplied. It does support analytical reproduction from the released numerical tables.

Figure 1 is a cartographic composite; Figure 2 a methodological schematic. Figure 3 requires original R6 spatial data. See [figure provenance](figure_provenance.md). Earlier nitrogen/yield work is archived under `legacy_previous_manuscript/` and is separate from the present sensitivity analysis.
