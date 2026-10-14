# Validation of the WDRVI α = 0.1 analytical regeneration

This document reports **descriptive checks performed on the corrected CSV exports** from the final local RStudio workflow. The 24 CSV files were uploaded to this repository after checking Git blob SHA-1 digests against the extracted `derived.rar` source; all matched exactly. The full upstream processing of raw UAV photographs is not included in the repository.

## Data coverage and baseline reproduction

- Five stages: V4, R5, R6, R7, R8; P1–P5 in every stage; three vegetation indices NDVI, MSAVI, WDRVI.
- 25 plot-stage baseline records and 75 corresponding per-index baseline records.
- 525 perturbation-level spectral records, 175 mask-geometry records, 75 crossplot-overlap checks.
- Maximum absolute discrepancy between independently extracted and baseline vegetation-index means: **4.44089209850063×10⁻¹⁶**.

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
- Median directional asymmetry across the 75 combinations: **35.012651%**; maximum **96.423244%**.
- Under the **relative normalized** sensitivity metric, the stage-by-index median magnitude order is WDRVI > MSAVI > NDVI for both erosion and dilation in all five stages. This does **not** establish an intrinsic ranking of absolute-index changes.

Median absolute direction-specific coefficients (selected examples):

| Stage | Index | Erosion | Dilation |
|---|---|---:|---:|
| V4 | NDVI | 0.032423 | 0.016203 |
| V4 | MSAVI | 0.082342 | 0.039178 |
| V4 | WDRVI | 1.527005 | 0.740340 |
| R8 | NDVI | 0.064036 | 0.111892 |
| R8 | MSAVI | 0.153153 | 0.244313 |
| R8 | WDRVI | 0.940978 | 1.292310 |

The stage-level median dilation/erosion ratio is the median **over the five plot-specific ratios**, not the ratio of the medians in this table.

## Robustness diagnostics

Comparison of coefficient magnitudes from 1–2 cm versus the complete 1–3 cm range:

| Statistic | Erosion | Dilation |
|---|---:|---:|
| Median absolute relative difference | **4.31%** | **3.17%** |
| Mean absolute relative difference | **6.15%** | **3.23%** |
| Maximum absolute relative difference | **22.37%** | **7.84%** |

For leave-one-plot-out influence on the mean `|β|`, the median (across the 15 stage–index combinations) of each combination's maximum absolute change is **13.01%** for erosion and **9.09%** for dilation. The maximum across all combinations is **21.20%** for erosion (R6 WDRVI) and **24.68%** for dilation (R7 WDRVI).

The original manuscript's previous erosion range-maximum value 19.54% was superseded by **22.37%**. This is not a statistical acceptance threshold or a population-level robustness statement.

## Non-canopy radial gradients

- 300 records = 5 stages × 5 plots × 3 indices × 4 rings.
- **75/75** outermost-ring values are lower than their respective innermost-ring values.
- **67/75** profiles decrease monotonically through the four external rings.

The ring analysis describes adjacent non-canopy spectral structure, not an independent sample of pure bare soil.

## Interpretive limitations

For `ΔVI (%) = 100 (VI_d−VI_0)/|VI_0|`, near-zero baselines increase coefficient magnitudes. Within the same plot–stage–index combination, this shared scaling cancels from the ratio of dilation to erosion and from directional asymmetry. The coefficient comparison across indices, however, remains dependent on index scale.

WDRVI with fixed α is a monotonic nonlinear transformation of NDVI at the pixel level and does not provide independent spectral corroboration. All calculations are descriptive and the controlled perturbations do not estimate actual segmentation error.
