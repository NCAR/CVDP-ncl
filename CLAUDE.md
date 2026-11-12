# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

CVDP-ncl is a palaeoclimate fork of NCAR's Climate Variability Diagnostics Package (CVDP v6.1.0). It analyzes major modes of climate variability (ENSO, PDO, AMO, NAM, NAO, etc.) from CMIP-format model output and observations, producing graphics and NetCDF output organized into HTML webpages. The primary language is NCL (NCAR Command Language); Python is used only for the parallel task runner.

## Running the Package

```bash
# Standard run (foreground)
ncl driver.ncl

# Background run with log
ncl driver.ncl >&! out.log &

# Run only specific diagnostic scripts (set modular = "True" and modular_list in driver.ncl first)
ncl driver.ncl
```

There is no build/compile step. NCL scripts are interpreted directly.

### This deployment (UCL geography cluster)

- Activate the conda environment first: `conda activate cvdp` (provides NCL 6.6.2). The shell alias `run_cvdp` expands to `ncl -n driver.ncl 2>&1 | tee out.log`.
- **Detached / non-interactive runs must redirect stdin from `/dev/null`**, e.g. `setsid ncl -n driver.ncl </dev/null >out.log 2>&1 &`. On a fatal error inside a script block NCL drops to an interactive prompt and will otherwise hang a piped or backgrounded shell.
- `out.log` is block-buffered when not attached to a tty, so it can look empty mid-run even while the job progresses — gauge progress from the files appearing in `outdir`, not the log.
- Heavy runs are launched on compute nodes `n03`/`n04.geog.ucl.ac.uk` (32 cores, 187 GB each). `/data` is a shared mount, so `outdir` output can be inspected from any host without SSH.
- Runstyle-1 by-experiment runs live under `/data/oacd/CVDP/v6.1/by_expt_rs1/<experiment>/`, with `zp` pointing at `/data/oacd/CVDP/v6.1/CVDP-ncl` (a symlink to this repo). Per-experiment `namelist`s are sourced from `/data/oacd/CVDP/by_experiment/<experiment>/` (prefer `namelist_all` where present); `namelist_obs` is experiment-independent and reused across runs.

## Configuration

All user settings are at the top of `driver.ncl`:

| Setting | Purpose |
|---|---|
| `runstyle` | 1 = individual simulations, 2 = ensemble mode |
| `outdir` | Output directory (must end in `/`) |
| `zp` | Path to the NCL scripts directory (must end in `/`) |
| `opt_climo` | `"Full"` = use full simulation period; `"Custom"` = use `climo_syear`/`climo_eyear` |
| `modular` / `modular_list` | Run a subset of diagnostic scripts |
| `max_num_tasks` | Number of parallel NCL processes |
| `namelists_only` | Set `"True"` to only generate `namelist_byvar/` files for inspection |

## Namelist Format

**`namelist`** (model simulations, pipe-delimited):
- Style 1 (runstyle=1): `SimName | /path/to/files/*.nc | start_year | end_year`
- Style 2 (runstyle=2): `SimName | /path/to/files/*.nc | start_year | end_year | ensemble_group`

**`namelist_obs`** (observations, pipe-delimited):
`VARIABLE | DatasetName | /path/to/file.nc | start_year | end_year`

Valid variables: `TS`, `PSL`, `TREFHT`, `PRECT`, `aice_nh`, `aice_sh`, `MOC`, `SSH`

## Architecture and Execution Flow

1. **`driver.ncl`** sets all configuration, exports environment variables, and orchestrates execution
2. **`scripts/namelist.ncl`** reads `namelist` + `namelist_obs` and writes per-variable namelists to `namelist_byvar/`
3. **`scripts/runTasks.py`** launches diagnostic scripts in parallel (up to `max_num_tasks` at once), polling every 15 seconds
4. Each diagnostic script in `scripts/` reads its variable namelist from `namelist_byvar/`, computes indices/patterns, writes `.nc` and image files to `outdir`
5. **`scripts/metrics.ncl`** and **`scripts/ncfiles.append.ncl`** aggregate results
6. **`scripts/webpage1.ncl`** or `webpage2.ncl` generates the HTML output

All diagnostic scripts receive configuration via environment variables (`OUTDIR`, `OPT_CLIMO`, `CLIMO_SYEAR`, `CLIMO_EYEAR`, etc.) set by `driver.ncl`.

## Script Directory Structure

- **`scripts/`** — All NCL diagnostic scripts and the Python task runner. This is what `zp` should point to.
- **`ncl_scripts/`** — Modified/development versions of a subset of scripts (`amoc.ncl`, `functions.ncl`, `pr.mean_stddev.ncl`). These are custom edits not yet in `scripts/`.
- **`misc_scripts/`** — Bash/shell utilities for ESGF data management and auto-generating namelists from curated data replicas.

## Diagnostic Scripts in `scripts/`

**Mode scripts** (compute EOF/regression patterns and timeseries):
`amm`, `amv`, `atl3`, `iod`, `ipv`, `monsoon`, `nam`, `nao`, `pdv`, `pna_npo`, `sam_psa`, `soi`

**Variable scripts** (mean/stddev, trends, timeseries by variable):
`{var}.mean_stddev.ncl`, `{var}.trends_timeseries.ncl`, `{var}.indices.ncl`
where `{var}` ∈ `sst`, `tas`, `pr`, `psl`, `siconc`, `zos`

**Support scripts**: `functions.ncl` (shared utility functions), `namelist.ncl`, `data_check_regrid.ncl`, `ensemble_mean.calc.ncl`, `metrics.ncl`, `ncfiles.append.ncl`, `webpage1.ncl`, `webpage2.ncl`

## Key Functions in `functions.ncl`

- `data_read_in(path, varname, yearS, yearE)` — Reads CMIP-style files, handles multiple variable name aliases (e.g., `TS`/`ts`/`sst`/`tos`), combines `PRECC+PRECL` for precip
- `check_custom_climo(...)` — Validates and applies custom climatological period
- `create_empty_array(...)` — Creates a missing-value placeholder array when data is absent
- `data_read_in_ice(path, "aice_nh"|"aice_sh", yearS, yearE)` — Reads sea-ice concentration (`aice`/`sic`/`siconc`/… aliases), attaching 2-D `lat2d`/`lon2d` for curvilinear grids. Recognizes CESM `TLAT`/`TLON`, CMIP `lat`/`lon`/`latitude`/`longitude`, and NEMO `nav_lat`/`nav_lon` (IPSL-CM6A-LR and other NEMO/eORCA models). If a grid has neither a recognized 2-D coordinate nor a 1-D `j` coordinate it returns a missing array (drops that model, warn-and-continue) rather than fataling — a hard fatal here would abort the whole diagnostic and every model after it.

## Reruns and Data Reuse

CVDP is incremental. Each diagnostic script, per simulation, calls `read_cvdp_le_data(...)` and skips (`continue`) any simulation whose result already exists in that sim's summary NetCDF; only missing simulations are recomputed. **Figures are always regenerated** (the plotting section runs regardless), as are metrics, the consolidated files and the webpages. So rerunning into a populated `outdir` = reuse existing model data + recompute only what is missing + rebuild all figures.

- The reuse key is the **filename, which embeds the year range**: `<sim>.cvdp_data.<syear>-<eyear>.nc`. Changing a simulation's year range in `namelist` changes the expected filename, so only that simulation recomputes; delete the orphaned old-range file to keep `outdir` tidy.
- `ncfiles.append.ncl` consolidates each run's per-diagnostic files into the master `<sim>.cvdp_data.<years>.nc` (via `ncks -A`) and deletes the intermediates; that master is what later reuse reads.
- To force a full recompute for a simulation, remove its `*.cvdp_data*.nc` files (this is also why changing `amoc_30N` requires a fresh `outdir` or removal of the amoc output).

## image_finalize (incremental image processing)

`image_finalize` (in `functions.ncl`) trims/watermarks only images **newer than a marker** that `driver.ncl` drops (`outdir/.cvdp_finalize_marker`) before the run generates any images and removes at the end. This stops images left by an earlier run (e.g. a `modular` or reused run) from being re-trimmed/re-watermarked. Its signature takes a trailing `since` (marker path) argument that `driver.ncl` supplies. On a full run every image is regenerated and therefore finalized normally.

## Namelist Pitfalls and Benign Log Messages

Data/namelist issues to watch for (none abort the run except the first, which silently guts it):

- **Stray whitespace in a path field** (e.g. `.../midHolocene / |`) makes `data_read_in` return missing and hit a hard `fatal` (`functions.ncl` ~line 133) that **aborts each diagnostic before its plotting section** — the run still reaches "Finished" but produces almost no plots. Symptom: many `cannot open file <...:>` warnings. Fix the path in `namelist`.
- **Requested year range outside the file coverage** → that model/variable is set to all-missing (`Requested X-Y ... is outside the input file ... time span of A-B`). Clamp the `namelist` years into coverage.

Benign, expected log noise (present in every successful run): `mv: cannot stat '.../<diag>.000001.png'` (~36–38 per run; per-member intermediate plots that do not apply in runstyle 1), `warning:IrTransInitialize: ... spline ... defaulting to linear`, and `warning:ContourPlotInitialize: no valid values in scalar field`.

## AR6 Regional Indices and Index Timeseries Plotting

Three diagnostics produce per-region index timeseries over the IPCC AR6 reference regions (masks in `AR6_masks_1x1.nc`, region definitions from Iturbide et al. 2020):

- `pr.indices.ncl` / `tas.indices.ncl` — area-weighted averages of monthly precip / near-surface temperature anomalies over each of the 58 AR6 reference regions, plus global and six latitude bands, each split all/land/ocean. Extraction is done by `extract_all_AR6_regions.ncl` and is reuse-guarded per simulation. Output: `ipcc_<region>_<pr|tas>.timeseries.png` (~82 region tokens each). Filename tokens carry suffixes: `_lnd`/`_ocn` for the multiply-defined regions, `GLOBAL_all|lnd|ocn`, and latitude bands like `NH_tropics_all`.
- `monsoon.ncl` — global monsoon domain + the 8 AR6 regional monsoons (`NAmerM`, `EqAmer`, `SAmerM`, `WAfriM`, `SAfri`, `SAsiaM`, `EAsiaM`, `AusMCM`). Output: `global_monsoon_domain.png`, `global_monsoon_stddev.png` (interannual std. dev. of local-summer rainfall over the climatological period, within the climatological domain), `monsoon_area_<region>.timeseries.png`, `monsoon_rain_<region>.timeseries.png` (rain averaged over each year's domain) and `monsoon_rainfixed_<region>.timeseries.png` (rain averaged over the climatological domain, held fixed). The reuse check keys on `monsoon_rainfixed_global`, so outputs predating it are recomputed. Maps switch to `RasterFill` above 5e5 grid points.

These index scripts are the **dominant runtime cost** of a run — their plotting loops render many multi-panel figures (one panel per simulation, ~82 regions × 2 variables).

**`plot_index_timeseries` (functions.ncl)** downsamples/smooths before plotting, keyed on the `nsamp_yr` argument the caller passes:
- `nsamp_yr = 1` (annual data, `monsoon.ncl`) — unchanged: raw series for ≤150 yr, 30-yr running mean sampled 5-yearly for >150 yr.
- `nsamp_yr = 12` (monthly data, `pr.indices`/`tas.indices`) — annual running mean sampled yearly for 30–150 yr records, decadal (10-yr) running mean sampled 5-yearly for >150 yr, each with a ±1σ envelope; ≤30 yr drawn at full monthly resolution.

This cut `pr.indices`/`tas.indices` plotting from hours to minutes and makes the multi-panel figures far more legible. Any change here alters figure appearance, so re-plot and eyeball a couple of regions.

**`ar6_indices.html`** is generated by `webpage1.ncl` (and `webpage2.ncl`) whenever `ipcc_*`/`monsoon_*` figures exist in `outdir`. It shows the AR6 region map, a PR/TAS link table (region order/names read from `AR6_masks_1x1.nc`; rows built by globbing the figures that exist), then the monsoon-domain figure and area/rain links. Two reference images live in `scripts/` alongside `cas-cvdp.png` — `AR6_reference_regions.jpg` (Iturbide 2020 Fig 1) and `AR6_monsoon_domains.jpg` (IPCC AR6 WGI Fig AV.1) — and are copied to `outdir` at webpage time. The page is linked from the index nav (`IPCC AR6 Regional Indices`) and documented in `methodology.html`. Note the index's real nav is the Bootstrap inline list at `txt(46)`, not the earlier `txt(14)` "Go to:" block (which builds a discarded array).

Adding this page (or any webpage change) to an already-completed run is **cheap** — no re-plot needed. Run `webpage1.ncl` standalone from the run's `outdir` with the driver's env vars (`OUTDIR`, `VERSION`, `OBS`, `REMOVE_TREND_OBS`/`REMOVE_TREND_MODEL`, `AMOC_30N`, `CVDP_SCRIPTS`) and `'webtitle="..."'`.

## Runstyle 3 (multi-model ensemble): running and gotchas

Full design is in `docs/runstyle3-design.md`; this is the operational summary from deploying the all-experiments-vs-`piControl` configuration.

- **Namelist is 6-column**: `SimName | path | syear | eyear | <group#>-<GroupName> | <pairing-key>`. Groups are experiments; `control_group_name` (driver) names the control group (e.g. `piControl`); the pairing key is the bare model name, so each experiment simulation is differenced against its own control (unpaired sims are warn-and-dropped). Multiple experiment groups in one run are allowed → one `<group>_minus_<control>.cvdp_mmm.nc` per experiment group.
- **Reuse for speed**: diagnostics run in individual-simulation mode, so hard-link the pre-computed `<sim>.cvdp_data.<years>.nc` masters from the per-experiment runs into the new `outdir` (`cp -l`). They are read-only during reuse, and NCL/NCO writes go via temp-file+rename, so the linked originals are not modified (verified). `namelist.ncl` scans every raw file to build `namelist_byvar/`, so it is slow at large sim counts (~1 h for ~170 sims) and reuse of the masters does not accelerate it.
- **`reuse_namelists = "True"`** (driver option, exported as `REUSE_NAMELISTS`) skips that scan: `namelist.ncl` reuses the existing `namelist_byvar/` files when they were built from the current `namelist`/`namelist_obs`. Validity is a content fingerprint (`md5` of `namelist` [+ `namelist_obs`] plus runstyle/obs) written to `namelist_byvar/.namelist_fingerprint` at the end of a successful run; on rerun the fingerprint is recomputed and the scan is skipped only if it matches and the outputs are present (`namelist_aice_sh`, plus `namelist_pairing` for runstyle 3). Any edit to the namelist changes the fingerprint and triggers an automatic full regenerate, so it is safe to leave on across reruns. Every run (flag on or off) now writes the fingerprint, so the first flagged rerun after an ordinary run already benefits.
- **`multi_model_stats.ncl` regrids hundreds of fields × ~30 models per group to 1°×1°.** It deletes and rewrites any existing `_mmm.nc`, so it is **not** idempotent/skippable. Three speedups are in place:
  - **Each master file is opened once per group** (via `addfiles`, with per-pair slot maps `exp_slot`/`ctl_slot`), not reopened on every `mmm_read_field` call (~2·npair calls per variable ≈ thousands of reopens/group). Variables are classified for stack allocation from metadata only (`mmm_coarse_class`: dim names/rank, no data read) instead of reading a whole field per variable. `mmm_read_field` takes an open `file` handle. ~⅓ faster per group; output is bit-identical.
  - **Cached ESMF regridding for curvilinear fields**: rectilinear fields use `linint2` (cheap, ~7 ms); the curvilinear sea-ice/ocean fields (which dominated the old runtime) use ESMF **bilinear** with weights generated once per (group, model, exp/ctl role, source-grid shape) and cached in an `mmm_wgt_*.nc` file that all of that model's fields on that grid reuse — ~0.04 s/field applied vs ~8 s/field for the old `rcm2rgrid`. Weight files live in `outdir` during a group and are deleted at group end. The mask is baked from the first field on each grid; ESMF still propagates each field's own missing values on apply (verified: no fill-value contamination). Bilinear differs slightly from the old `rcm2rgrid` at ice-edge coastal cells (a few cells, ~0.1–0.2 mean diff on 0–99 concentration) — expected and benign.
  - **Groups run in parallel**: `driver.ncl` launches one `multi_model_stats.ncl` process per experiment group (via `xargs -P max_num_tasks`, passing `MMM_GROUP=<group>`), since groups are independent and each writes its own output + uniquely-named weight files. To run one group standalone, set `MMM_GROUP` yourself (unset/empty = all groups).
- **Graphics**: run `scripts/multi_model_graphics.ncl` standalone (needs `OUTDIR`, `OUTPUT_TYPE`, `PNG_SCALE`, `VERSION`, `CVDP_SCRIPTS`) to make the 4-panel `mmm.*` maps + per-experiment `.mmm.html` pages *without* re-running the stats. Do **not** use `mmm_webpages_only = "True"` for graphics-only — it re-runs `multi_model_stats` (the whole expensive step).
  - **Runs in parallel too**: `driver.ncl` launches one graphics process per `*.cvdp_mmm.nc` (`xargs -P max_num_tasks`, passing `MMM_ONEFILE=<file>`); each file's figures and `.mmm.html` carry that group's name so processes never collide. Set `MMM_ONEFILE` yourself to render one group standalone (unset/empty = all). This was the dominant cost of a full MMM webpage rebuild (single-process ~18 min for ~1500 figures across 6 groups → ~3 min parallel).
  - **Per-diagnostic map framing** is chosen by the `mmm_basin(base)` helper (top of `multi_model_graphics.ncl`), so figures aren't left on the default lon-0 global projection: sea ice (`siconc_nh`/`siconc_sh`) → NH/SH polar stereographic cropped at ±40° (mirrors `siconc.mean_stddev.ncl`); annular modes (`nam`/`nao`/`pna`/`npo` → NH, `sam`/`psa1`/`psa2` → SH) → polar cropped at ±20°; basin modes → WinkelTripel centred on their ocean basin — Pacific=210° (`nino*`/`pdv`/`ipv`/`so_`/`north_pacific*`/`south_pacific*`/`southern_ocean`), Atlantic=0° (`amv`/`amm`/`atl3`/`atlantic*`/`north_atlantic`/`*_tropical_atlantic`), Indian=80° (`iod`/`indian_ocean_dipole`/`tropical_indian_ocean`); everything else (climatologies, stddev, trends, monsoon domain) keeps the global projection. Basin centres mirror the `centerlon` table in `sst.indices.ncl`. Stippling overlays align on all projections. To change a mode's framing, edit the `prefixes`/`codes` arrays in `mmm_basin`.
- **Known runstyle-3 bugs still open**: `metrics.ncl` fatals on `resT` (undefined at ~line 995 — the pattern-correlation/RMS table block is entered under `RUNSTYLE.eq."2"` but its `delete`/cleanup is not similarly guarded), aborting the individual metrics table (the MMM is unaffected). `image_finalize` references the global `max_num_tasks` (functions.ncl ~line 2629) instead of its `max_nt` argument, so it only works when called from `driver.ncl` (define `max_num_tasks` as a top-level global if calling it standalone).

## Palaeoclimate-Specific Additions (vs. upstream NCAR CVDP)

- `opt_climo = "Custom"` with negative year offsets (e.g., `climo_syear = -30` means 30 years before simulation end)
- `scripts/amm.ncl` — Atlantic Meridional Mode
- `scripts/atl3.ncl` — Atlantic Niño (ATL3)
- `scripts/monsoon.ncl` — Global Monsoon Domain
- `scripts/extract_all_AR6_regions.ncl` — IPCC AR6 regional averages (uses `AR6_masks_1x1.nc`)
- Extended IOD diagnostics with additional regression patterns
- `misc_scripts/` — Scripts to curate ESGF replicas and generate namelists for palaeoclimate experiments
