# Analytical validation and quality assurance

This document summarizes descriptive quality-control checks for the **24 analysis-ready CSV tables** supporting the UAV canopy-boundary sensitivity study. The published tables were checked for file integrity and agreement with the RStudio analysis outputs. Original UAV photographs and upstream photogrammetric processing inputs are not distributed in this repository.

## Data coverage and baseline reproduction

- Five stages: V4, R5, R6, R7, R8; P1–P5 in every stage; three vegetation indices NDVI, MSAVI, WDRVI.
- 25 plot-stage baseline records and 75 corresponding per-index baseline records.
- 525 perturbation-level spectral records, 175 mask-geometry records, 75 crossplot-overlap checks.
- Maximum absolute discrepancy between independently extracted and baseline vegetation-index means: **4.44089209850063×10⁻¹⁶**.

## Plot-level dilation and mask nesting

Outward dilation retains the entire baseline mask for each plot. Canopy assigned to other plots is excluded only from the newly added exterior area; any pre-existing overlap between baseline masks is retained. This definition yielded spatially nested dilation supports, with 525 spectral and 175 vector-geometry records. The final spatial correction affects 117 positive-distance spectral observations and 42 positive-distance vector geometry records; baseline and erosion records remain unchanged. The R6–P1 example at +1 cm contains 121,194 valid NDVI cells and 10.557251 m² of dilated vector support. Across 450 nonzero plot × acquisition × index observations, the median absolute difference between relative vector-area and valid-pixel-count changes is 0.09 percentage points (maximum 1.90 points).

## Mean baseline WDRVI by stage

| Stage | Mean across P1–P5 |
|---|---:|
| V4 | +0.01493319 |
| R5 | +0.10799302 |
| R6 | +0.50643067 |
| R7 | −0.07598148 |
| R8 | +0.23016291 |

Negative WDRVI values are valid for α = 0.1. In V4 some WDRVI baseline means are close to zero; normalized percentage changes may therefore be large.

## Direction-dependent spectral sensitivity

- **72/75** plot × acquisition × index combinations have both `beta_erosion` and `beta_dilation` negative.
- The three remaining combinations all occur in **P2–R7**, one each for NDVI, MSAVI and WDRVI; both slopes are positive.
- Median directional asymmetry across the 75 combinations: **34.406859%**; maximum **96.423244%**.
- Under the **relative normalized** sensitivity metric, the stage-by-index median magnitude order is WDRVI > MSAVI > NDVI for both erosion and dilation in all five stages. This does **not** establish an intrinsic ranking of absolute-index changes.

Median absolute direction-specific coefficients (selected examples):

| Stage | Index | Erosion | Dilation |
|---|---|---:|---:|
| V4 | NDVI | 0.032423 | 0.016203 |
| V4 | MSAVI | 0.082342 | 0.039178 |
| V4 | WDRVI | 1.527005 | 0.740340 |
| R8 | NDVI | 0.064036 | 0.097677 |
| R8 | MSAVI | 0.153153 | 0.219748 |
| R8 | WDRVI | 0.940978 | 1.276690 |

The stage-level median dilation/erosion ratio is the median **over the five plot-specific ratios**, not the ratio of the medians in this table.

## Robustness diagnostics

Comparison of coefficient magnitudes from 1–2 cm versus the complete 1–3 cm range:

| Statistic | Erosion | Dilation |
|---|---:|---:|
| Median absolute relative difference | **4.31%** | **2.76%** |
| Mean absolute relative difference | **6.15%** | **3.08%** |
| Maximum absolute relative difference | **22.37%** | **10.33%** |

For leave-one-plot-out influence on the mean `|β|`, the median (across the 15 stage–index combinations) of each combination's maximum absolute change is **13.01%** for erosion and **9.15%** for dilation. The maximum across all combinations is **21.20%** for erosion (R6 WDRVI) and **22.07%** for dilation (R7 WDRVI).

These descriptive checks are not statistical acceptance thresholds or evidence of population-level robustness. The LOPO diagnostic is calculated on mean absolute coefficients and does not, by itself, establish stability of the median summaries used in the primary figure.

## Non-canopy radial gradients

- 300 records = 5 stages × 5 plots × 3 indices × 4 rings.
- **75/75** outermost-ring values are lower than their respective innermost-ring values.
- **67/75** profiles decrease monotonically through the four external rings.

The ring analysis describes adjacent non-canopy spectral structure, not an independent sample of pure bare soil.

## Interpretive limitations

For `ΔVI (%) = 100 (VI_d−VI_0)/|VI_0|`, near-zero baselines increase coefficient magnitudes. Within the same plot–stage–index combination, this shared scaling cancels from the ratio of dilation to erosion and from directional asymmetry. The coefficient comparison across indices, however, remains dependent on index scale.

WDRVI with fixed α is a monotonic nonlinear transformation of NDVI at the pixel level and does not provide independent spectral corroboration. All calculations are descriptive and the controlled perturbations do not estimate actual segmentation error.
