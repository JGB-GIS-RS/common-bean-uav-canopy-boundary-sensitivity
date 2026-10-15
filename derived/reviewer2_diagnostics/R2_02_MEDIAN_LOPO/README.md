# R2-02 — Median-based leave-one-plot-out audit

This diagnostic addresses the difference between the **mean-based** LOPO procedure in the original robustness workflow and the **median-based** summaries shown in Figure 6. It supplements, rather than replaces, the existing mean-based analysis. It does not change the final R2-01 canopy masks, directional coefficients, or figures.

## Input and files

- **Fixed input:** [directional_beta_by_plot.csv](../../boundary_sensitivity/directional_beta_by_plot.csv), the 75 plot × acquisition × index records released after the R2-01 correction.
- **Reproduction script:** [10_lopo_median_sensitivity.R](../../../scripts/10_lopo_median_sensitivity.R), base R only.
- **Outputs in this folder:**
  - [R2_02_LOPO_MEDIAN_DETAIL.csv](R2_02_LOPO_MEDIAN_DETAIL.csv): 75 individual plot-omission records.
  - [R2_02_LOPO_MEDIAN_SUMMARY.csv](R2_02_LOPO_MEDIAN_SUMMARY.csv): 15 stage × index summaries.
  - [R2_02_INDEX_RANKING_QA.csv](R2_02_INDEX_RANKING_QA.csv): 50 stage × omitted plot × direction ranking checks.

From the repository root, run:

```bash
Rscript scripts/10_lopo_median_sensitivity.R .
```

The script reads only the fixed input above, performs numeric QA checks and writes the three CSVs to this directory. It does not require UAV imagery, canopy polygons, or resegmentation, and does not overwrite production CSVs.

## Statistical definitions

For each acquisition and index, the five plots are the spatial observational units. One plot is omitted at a time, leaving four plots; the median of four values is the average of their two central ordered values.

- **Magnitude stability:** percent change in the median absolute erosion and dilation coefficients relative to the five-plot median.
- **Plot-specific directional ratio:** median over plots of `abs_beta_dilation / abs_beta_erosion`. This is the statistic used for directional predominance in the manuscript.
- **Ratio of marginal medians:** median `abs_beta_dilation` divided by median `abs_beta_erosion`. It is **not** algebraically equivalent to the median of plot-specific ratios.
- **Dominance:** whether the pertinent ratio is above or below 1; equality is recorded separately.
- **Index ordering:** medians compared independently within each acquisition × omitted plot × direction.

## Verified findings

| Diagnostic | Finding |
|---|---:|
| Individual plot omissions | 75 |
| Acquisition × index summaries | 15 |
| Largest absolute change in erosion median | 49.829256% (R7, WDRVI) |
| Largest absolute change in dilation median | 89.931874% (R7, WDRVI) |
| Directional flips, median of individual ratios | 0/75 |
| Directional flips, ratio of marginal medians | 10/75 |
| Changes in WDRVI > MSAVI > NDVI ranking | 0/50 |

The large median changes prohibit a blanket claim that **magnitudes** are robust to plot omission. Stability of the *median of plot-specific ratios* is a distinct, conditional descriptive finding. Ranking stability concerns the adopted **relative** sensitivity metric; it does not establish greater spectral sensitivity in native index units.

## Provenance and validation status

These three CSVs are the audited numerical outputs supplied from the R2-02 RStudio analysis. Their 75, 15 and 50 rows were checked independently against the final R2-01 coefficients; **all numeric and categorical fields matched** within floating-point precision. The original RStudio source script was **not included** in the archived results, so the R file here is an **independent reconstruction** of the documented computation, not a representation of that missing original source. The reconstructed logic was cross-checked independently against all archived output fields. A fresh execution using an installed R runtime remains advisable to certify end-to-end clean-clone reproducibility.

Archived report reference: `R2_02_MEDIAN_LOPO_20261015_060743`, input MD5 reported by original local analysis `e8546fae34c918dd6fc50a4d45dbbfa2`. MD5 should be compared with the current downloaded input when reproducing.

No p-values, confidence intervals, acceptance thresholds for scientific robustness, or population-level conclusions are implied by these descriptive checks.
