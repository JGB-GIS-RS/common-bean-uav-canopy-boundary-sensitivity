# Figure Provenance

| Figure | Role | Provenance |
|---|---|---|
| Figure 1 | Geographic location and spatial configuration | Cartographic composite plus RGB orthomosaic; P1–P5, experimental boundary, RP-1/RP-2, and GCP-1–GCP-4 in WGS 84 / UTM zone 18N (EPSG:32618). |
| Figure 2 | Methodological workflow | Author-prepared schematic summarizing chronology, UAV processing, baseline canopy support, perturbation analysis, radial analysis, and robustness diagnostics. |
| Figure 3 | Baseline mask, spectral support, and controlled perturbation | Illustrative R6 composite assembled from the baseline canopy mask, NDVI raster support, and ±3 cm perturbations. |
| Figure 4 | Baseline multitemporal context | `scripts/05_figure_4_baseline_multitemporal_context.R` using `derived/canopy_summary_by_plot.csv`. |
| Figure 5 | Geometric consequences of perturbation | `scripts/14_figure_5_geometric_consequences_boundary_perturbation.R` using `derived/boundary_sensitivity/boundary_geometry_qa.csv`. |
| Figure 6 | Direction-specific normalized sensitivity | `scripts/13_boundary_sensitivity_figures.R` using `derived/boundary_sensitivity/directional_beta_by_plot.csv`. |
| Figure 7 | Radial spectral structure | `scripts/13_boundary_sensitivity_figures.R` using `derived/radial_background/radial_ring_observations.csv`. |
| Figure S1 | Directional asymmetry | `scripts/13_boundary_sensitivity_figures.R` using `derived/boundary_sensitivity/directional_beta_by_plot.csv`. |
| Figure S2 | Direction-specific normalized response curves | `scripts/13_boundary_sensitivity_figures.R` using `derived/boundary_sensitivity/normalized_boundary_response_observations.csv`. |

Figures 1–3 are explanatory composites rather than the sole source of reported quantitative sensitivity statistics.
