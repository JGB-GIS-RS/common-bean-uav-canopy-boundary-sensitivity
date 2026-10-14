# Direction-Dependent Sensitivity of UAV-Derived Vegetation Indices to Canopy Boundary Definition in Common Bean

Reproducible analysis-ready data and R scripts for the common-bean UAV canopy-boundary sensitivity manuscript. This repository concerns **spatial support and directional boundary perturbations**, not causal effects of nitrogen fertilization.

## Study and statistical scope

- Five fixed spatial observational units (P1–P5) in the 2024 common-bean crop cycle, Quindío, Colombia; five UAV acquisitions (V4, R5, R6, R7, R8).
- Each plot had one N-rate context (0, 100, 200, 300, 400 kg N ha⁻¹), without independently replicated N treatments. **Do not interpret these as treatment replicates or infer causal N effects.**
- Vegetation indices: NDVI, MSAVI, and WDRVI **with α = 0.1**.
- Controlled canopy-mask erosion and dilation at −3, −2, −1, 0, +1, +2, +3 cm; directional coefficients are fit separately.
- Primary normalized metric: `ΔA (%) = 100 (A_d − A_0)/A_0`; `ΔVI (%) = 100 (VI_d − VI_0)/|VI_0|`; slope `β` through the origin in each direction; reported magnitude `|β|`.
- Near-zero `VI_0` can amplify **relative** WDRVI coefficients. A large relative coefficient is not necessarily a large absolute-index change. Within one plot, flight and index, the common baseline normalization cancels in the ratio of erosion/dilation magnitudes and in directional asymmetry.
- Perturbations and radial rings are **dependent deterministic/spatial summaries**, not independent biological replicates. Analyses are descriptive; no inferential hypothesis testing is claimed.

## Corrected WDRVI dataset

This version contains the WDRVI = (α·NIR − Red)/(α·NIR + Red) products corresponding to **α = 0.1**, as verified in the local source-raster analysis and regenerated analysis tables. The previous WDRVI tables have been replaced.

| Stage | Date (2024) | Mean WDRVI over P1–P5 |
|---|---|---:|
| V4 | 07 Sep | 0.014933 |
| R5 | 14 Sep | 0.107993 |
| R6 | 02 Oct | 0.506431 |
| R7 | 09 Oct | −0.075981 |
| R8 | 16 Oct | 0.230163 |

Quality-assurance checks: 525 spectral observations; 175 mask-geometry observations; 75 directional plot–stage–index combinations, with both slopes negative in 72; 300 external-ring measurements; all 75 radial profiles lower in the outermost than innermost ring, 67 strictly monotonic. The median directional asymmetry is 35.01% (maximum 96.42%). Details: [validation report](docs/validation_alpha01.md).

## Project layout

```text
data/raw/                                  # local-only spatial inputs; not distributed
derived/
  canopy_statistics_by_subplot_index.csv
  canopy_summary_by_subplot.csv           # 25 plot × acquisition records
  qa_spatial_extraction.csv
  boundary_sensitivity/                   # 17 numerical and QA tables
  radial_background/                      # 4 ring/gradient tables
scripts/
  01_extract_canopy_statistics.R
  02_boundary_perturbation.R
  03_radial_background_analysis.R
  04_normalized_boundary_sensitivity.R
  05_robustness_analysis.R
  06_figure_3_boundary_perturbation.R
  07_figure_4_baseline_context.R
  08_figure_5_geometric_consequences.R
  09_figures_6_7_and_supplement.R
docs/
  data_dictionary.md
  boundary_sensitivity_data_dictionary.md
  reproducibility.md
  figure_provenance.md
  validation_alpha01.md
legacy_previous_manuscript/                # separate earlier N/yield work
renv.lock
sessionInfo.txt
```

## Reproduce the figures from the tracked analysis tables

Open the included RStudio project, or set your working directory to the repository root. The tracked `data/raw/.gitkeep` allows the project-root detector to find a clean clone without distributing original spatial data.

```r
install.packages("renv") # if needed
renv::restore()
source("scripts/04_normalized_boundary_sensitivity.R")
source("scripts/05_robustness_analysis.R")
source("scripts/07_figure_4_baseline_context.R")
source("scripts/08_figure_5_geometric_consequences.R")
source("scripts/09_figures_6_7_and_supplement.R")
```

Outputs include Figure 4, Figure 5, Figures 6–7, Figures S1–S2, and the vector `Supplementary_Materials.pdf`. Figures are written under `figures/` and `figures/boundary_sensitivity/`; generated graphics are ignored by Git.

## Regenerate the complete spatial extraction (local inputs required)

Add the following per-stage inputs to `data/raw/<STAGE>/`:

| Folder | Acquisition basename | Required files |
|---|---|---|
| `V4/` | `20240907` | `canopy_*.gpkg`, `ndvi_*.tif`, `msavi_*.tif`, `wdrvi_*.tif` |
| `R5/` | `20240914` | same four files |
| `R6/` | `20241002` | same four files |
| `R7/` | `20241009` | same four files |
| `R8/` | `20241016` | same four files |

Run scripts 01–09 in numerical order. Figure 3 (R6 baseline mask and spectral support) specifically requires R6 canopy polygons and NDVI raster. Full source rasters/GeoPackages are not publicly tracked due to size; the **24 analysis-ready CSVs are tracked** for numerical and most figure-level reproduction. See [reproducibility](docs/reproducibility.md) for details.

## Figure-to-code mapping

| Item | R source |
|---|---|
| Figure 1 | cartographic composite, see [provenance](docs/figure_provenance.md) |
| Figure 2 | methodological schematic, see [provenance](docs/figure_provenance.md) |
| Figure 3 | `scripts/06_figure_3_boundary_perturbation.R` (spatial input required) |
| Figure 4 | `scripts/07_figure_4_baseline_context.R` |
| Figure 5 | `scripts/08_figure_5_geometric_consequences.R` |
| Figures 6–7 and S1–S2 | `scripts/09_figures_6_7_and_supplement.R` |

## Reproducibility and provenance

The tracked `renv.lock` and `sessionInfo.txt` document the recorded R environment; local reproducibility was tested in RStudio, but full independent clean-clone execution is not certified here. The previous N/yield-oriented study is preserved separately under `legacy_previous_manuscript/` and does **not** provide the WDRVI observations used for the present manuscript.

R scripts: MIT License. Distributed data and documentation: CC BY 4.0 unless otherwise specified. Final manuscript citation/DOI to be added after publication.
