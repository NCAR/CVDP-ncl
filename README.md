# CVDP
The Climate Variability Diagnostics Package (CVDP) developed by NCAR's Climate Analysis Section is an analysis tool that documents the major modes of climate variability in models and observations, including ENSO, Pacific Decadal Oscillation, Atlantic Multi-decadal Oscillation, Northern and Southern Annular Modes, North Atlantic Oscillation, Pacific North and South American teleconnection patterns. Time series, spatial patterns and power spectra are displayed graphically via webpages and saved as NetCDF files for later use. The package also computes climatological fields, standard deviation and trend maps; documentation is provided for all calculations.  The package can be applied to individual model simulations ("style 1") or to “initial condition” Large Ensembles (“style 2”).  Both styles provide quantitative metrics comparing models and observations; style 2 also includes ensemble mean (i.e., forced response) and ensemble spread (i.e., internal variability) diagnostics.  Several detrending options are provided, including linear, quadratic, 30-year high-pass filter and removal of the ensemble mean (in the case of Large Ensembles). The CVDP can be run on any set of model simulations (as long as the files meet CMIP output metadata requirements), allowing inter-model comparisons. Observational data sets and analysis periods are specified by the user. The CVDP Data Repository contains CVDP output for many CESM and CMIP model simulations. Two examples are linked below; many more examples are present on the <a href="https://www.cesm.ucar.edu/working_groups/CVC/cvdp/data-repository.html">CVDP Data Repository</a>. 

<a href="https://webext.cgd.ucar.edu/Multi-Case/CVDP_repository/cmip6.hist_ssp585_quadquad_1900-2100/">CMIP6 Historical/SSP585 Run Intercomparison 1900-2100</a><br>
<a href="https://webext.cgd.ucar.edu/Multi-Case/CVDP_repository/cesm2-lens_quadquad_1850-2100/">CESM2 Large Ensemble Intercomparison 1850-2100</a>

CVDP v6.0.0 combines the capabilities of previous versions of the CVDP with those of the <a href="https://github.com/NCAR/CVDP-LE">CVDP-LE</a>. Due to the merging of the capabilites of these two packages, the CVDP-LE is now deprecated.  

# Getting Started
View the <a href="https://www.cesm.ucar.edu/projects/cvdp/documentation">CVDP documentation page</a> for details on how to run CVDP v6.0.0. 

# Input data
The CVDP can read in the following data types as input:
- CMIP6
- CMIP5
- CMIP3
- CSM, CCSM and CESM
- Observations with file names and data array names matching CMIP conventions.

# Getting help
If the <a href="https://www.cesm.ucar.edu/projects/cvdp/documentation">CVDP documentation page</a> and the <a href="https://www.cesm.ucar.edu/working_groups/CVC/cvdp/">CVDP Website</a> do not answer your query or if you have a bug report or suggestion, it is recommended that you <a href="https://github.com/NCAR/CVDP-ncl/issues">open an issue on Github</a>. 
