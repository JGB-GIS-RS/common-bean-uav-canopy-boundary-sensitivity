# Directional Boundary-Sensitivity and Radial Data Dictionary

All tracked CSVs in this version were regenerated with **WDRVI α = 0.1**. Acquisition stage and plot refer to five repeated surveys of P1–P5. The `subplot` field identifies a spatial unit, not an N-treatment replicate.

## Variables and estimands

- `A_0`, `A_d`: projected segmented-mask area before and after a prescribed perturbation (m²).
- `ΔA_d (%) = 100(A_d − A_0)/A_0`: proportional change in effective vector area (negative erosion; positive dilation).
- `VI_0`, `VI_d`: mean vegetation index over baseline and perturbed masks.
- `ΔVI_d (%) = 100(VI_d − VI_0)/|VI_0|`: **relative** spectral response. A baseline index close to zero can amplify this percentage.
- Direction-specific `β_erosion` and `β_dilation`: separately fitted through-origin slopes of `ΔVI` versus `ΔA`, using the three −1,−2,−3 cm or +1,+2,+3 cm perturbations, respectively.
- `abs_beta_erosion` and `abs_beta_dilation`: the primary magnitude summaries; units are % VI change per percentage-point mask-area change.
- `dilation_to_erosion_ratio`: within-plot `|β_dilation|/|β_erosion|`, summarized as the **median of plot-specific ratios**, not the ratio of stage-level medians.
- `directional_asymmetry_pct`: `200*abs(|β_dilation|−|β_erosion|)/(|β_dilation|+|β_erosion|)`. It measures the asymmetry between directions, not an inferential test or segmentation accuracy.

Because both directional slopes for a given `subplot × stage × index` share the same denominator `|VI_0|`, that factor cancels in the within-observation ratio and directional asymmetry.

## Boundary-perturbation products (17 files)

Under `derived/boundary_sensitivity/`:

| CSV | Rows | Description |
|---|---:|---|
| `baseline_reproduction_check.csv` | 75 | Comparison of independently reconstructed baseline index means; maximum absolute difference 4.44×10⁻¹⁶ |
| `boundary_geometry_qa.csv` | 175 | 5 stages × 5 plots × 7 perturbations, effective vector area and geometry diagnostics |
| `boundary_perturbation_observations.csv` | 525 | 5 stages × 5 plots × 3 indices × 7 perturbations, corresponding raster-index summaries |
| `crossplot_overlap_qa.csv` | 75 | Excluded overlap from outward dilation where neighboring plotted canopy would be incorporated |
| `normalized_boundary_response_observations.csv` | 525 | Joined normalized geometric/spectral changes; Figure S2 |
| `normalized_boundary_sensitivity_by_plot.csv` | 75 | Supporting **combined-direction**, through-origin β for all nonzero perturbations |
| `normalized_boundary_sensitivity_summary.csv` | 15 | Stage × index summaries of combined-direction β |
| `directional_beta_by_plot.csv` | 75 | **Primary** plot-specific erosion and dilation slopes and asymmetry |
| `directional_beta_summary.csv` | 15 | Stage × index medians/IQR-related summaries and ratios |
| `directional_robustness_range_by_plot.csv` | 150 | 1–2 cm versus 1–3 cm comparison separately for both directions |
| `directional_robustness_range_summary.csv` | 30 | Stage × index × direction stability summaries |
| `directional_robustness_leave_one_subplot_out.csv` | 150 | Five leave-one-plot-out calculations for each stage × index × direction |
| `directional_robustness_leave_one_subplot_out_summary.csv` | 30 | Maximum influence on direction-specific mean `|β|` |
| `robustness_range_by_plot.csv` | 75 | Supporting combined-direction stability calculations |
| `robustness_range_summary.csv` | 15 | Supporting combined-direction stage-index summaries |
| `robustness_leave_one_subplot_out.csv` | 75 | Supporting combined-direction plot-omission calculations |
| `robustness_leave_one_subplot_out_summary.csv` | 15 | Supporting combined-direction plot-omission summaries |

The **combined-direction β is not the primary manuscript result**; directional erosion and dilation coefficients are reported separately.

## Radial environment products (4 files)

Under `derived/radial_background/`:

| CSV | Rows | Description |
|---|---:|---|
| `radial_ring_observations.csv` | 300 | 5 stages × 5 plots × 3 indices × 4 mutually exclusive outer rings (0–5, 5–10, 10–15, 15–20 cm) |
| `radial_ring_summary.csv` | 60 | Stage × index × ring mean/median and variability |
| `radial_gradient_by_plot.csv` | 75 | Plot-stage-index radial slope, monotonicity and outer-minus-inner difference |
| `radial_gradient_summary.csv` | 15 | Stage × index radial-slope summaries |

Non-canopy rings exclude all segmented common-bean canopy from the five plots. They are a spatial transition environment and are **not necessarily pure bare soil**. All rings are nested spatial summaries, not independent biological replicates.

## Scope

Descriptive within-dataset analysis only: no p-values, confidence intervals, or causal nitrogen-response inference. The 1–3 cm perturbations are controlled alternatives to an adopted mask and **do not quantify measured segmentation error**.
