# WDRVI alpha=0.1 repository synchronization (in progress)

This branch is a staging area for synchronizing the **corrected WDRVI (alpha = 0.1)** analyses with the corresponding RStudio project. It is **NOT READY FOR PUBLICATION** and must not be merged into `main` until all corrected tables, the complete validated nine-script workflow, and the documentation are uploaded and checked.

The current `main` branch still includes pre-correction WDRVI tables; do not use those values to reproduce the revised manuscript.

## Independently confirmed computational results (local RStudio execution)

- 5 acquisitions (V4, R5, R6, R7, R8), 5 spatial units (P1–P5), 3 vegetation indices.
- 75 plot-acquisition-index combinations; 72 have negative erosion and dilation coefficients.
- Radial profile: all 75 outer rings lower than corresponding inner rings; 67 monotonic non-increasing profiles.
- Directional asymmetry: median 35.01%; maximum 96.42%.
- Reference WDRVI means by acquisition: V4 0.01493319; R5 0.10799302; R6 0.50643067; R7 -0.07598148; R8 0.23016291.

## Required remaining material

- Corrected `derived/` CSV files from the final RStudio execution (not the old GitHub versions).
- Remaining four validated scripts: `01_extract_canopy_statistics.R`, `06_figure_3_boundary_perturbation.R`, `07_figure_4_baseline_context.R`, `08_figure_5_geometric_consequences.R`.
- Corresponding updates to `README.md`, `docs/reproducibility.md`, `docs/data_dictionary.md`, `docs/boundary_sensitivity_data_dictionary.md`, and `docs/figure_provenance.md`.
- Final consistency verification of the full nine-script workflow and outputs.

## Intended execution order

```text
01_extract_canopy_statistics.R
02_boundary_perturbation.R
03_radial_background_analysis.R
04_normalized_boundary_sensitivity.R
05_robustness_analysis.R
06_figure_3_boundary_perturbation.R
07_figure_4_baseline_context.R
08_figure_5_geometric_consequences.R
09_figures_6_7_and_supplement.R
```

Input rasters and canopy GeoPackages are read from `data/raw/<STAGE>/` and are not published to the repository. The corrected, exportable analysis tables are necessary for analytical reproduction without raw spatial rasters.
