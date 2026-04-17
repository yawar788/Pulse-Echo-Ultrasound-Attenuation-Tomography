# Pulse-Echo Ultrasound Attenuation Tomography
### GPU Pipeline — Setup & Run Guide
**Paper:** Korta Martiartu et al., *Phys. Med. Biol.* 69 (2024) 115016  
**GitHub:** https://github.com/naiarako/attomo

---

## Overview

This pipeline reproduces the numerical results of the attomo paper using **k-Wave (MATLAB)** for acoustic simulation and **Python** for attenuation tomography reconstruction. The full workflow has three stages:

| Stage | Tool | What it does | Output |
|-------|------|--------------|--------|
| 1 | MATLAB + k-Wave | Simulates ultrasound wave propagation in phantom | `acquisition_1.mat` … `acquisition_5.mat` |
| 2 | MATLAB + k-Wave | Simulates homogeneous reference medium (calibration) | `calibration_acquisition_1.mat` … `calibration_acquisition_5.mat` |
| 3 | Python + attomo | Beamforming, cross-correlation, tomographic inversion | Figures (PNG) |

---

## Requirements

### Hardware
- NVIDIA GPU with CUDA support (required for fast k-Wave simulation)
- Minimum 16 GB RAM recommended

### Software
- MATLAB R2020a or later
- k-Wave Toolbox — free download at http://www.k-wave.org/download.php
- Miniconda or Anaconda — https://docs.conda.io/en/latest/miniconda.html
- Git (optional, to clone the repo)

---

## Step 1 — Install k-Wave in MATLAB

1. Download k-Wave from http://www.k-wave.org/download.php
2. Extract the zip, e.g. to `C:\kwave\`
3. In the MATLAB Command Window run:
```matlab
addpath('C:\kwave')
savepath
```
4. Verify installation:
```matlab
help kWaveGrid
```
✔ If help text appears, k-Wave is correctly installed and you can proceed.

---

## Step 2 — Set Up Python Environment

5. Open Anaconda Prompt (or terminal) and navigate to the project folder:
```bash
cd /d D:\attomo
```
6. Create the GPU conda environment:
```bash
conda env create -f environment_attomo_gpu.yml
```
7. Activate it:
```bash
conda activate attomo
```
8. Install the attomo package in developer mode:
```bash
pip install -e .
```
9. Verify the install:
```bash
python -c "from attomo import Bmode, ATTomo; print('OK')"
```
✔ You should see `OK` printed. The CuPy warning about GPU options is harmless if it also says `OK`.

---

## Step 3 — Run the MATLAB k-Wave Phantom Simulation

This is the most time-consuming step. It runs **5 realisations × 121 steering angles = 605 k-Wave simulations**.

10. Open MATLAB
11. Navigate to the data folder:
```matlab
cd('D:\attomo\data')
```
12. Open `Script_kWave_simulation.m`
13. On line 5, make sure the GPU option is set:
```matlab
DATA_CAST = 'gpuArray-single';
```
14. Press **Run (F5)** and let it complete

> ⚠ Do NOT close MATLAB or let the PC sleep during simulation. This can take **1–3 hours on GPU**.

When finished, these 5 files will appear in `D:\attomo\data\` (or your working directory):

```
acquisition_1.mat
acquisition_2.mat
acquisition_3.mat
acquisition_4.mat
acquisition_5.mat
```

---

## Step 4 — Run the MATLAB k-Wave Calibration Simulation

This step generates the homogeneous reference medium data used to calibrate the attenuation measurements. It uses the **identical simulation setup** as Step 3, but with the circular inclusion removed and a uniform attenuation background.

15. In MATLAB, make sure you are still in the data folder:
```matlab
cd('D:\attomo\data')
```
16. Open `Script_kWave_calibration.m`
17. On line 9, set the GPU option:
```matlab
DATA_CAST = 'gpuArray-single';   % change to 'single' for CPU
```
18. Press **Run (F5)** and let it complete

> ⚠ This step also runs 5 realisations × 121 angles and takes the same amount of time as Step 3. Do not skip it — the Python notebooks cannot produce calibrated results without these files.

When finished, these 5 files will appear in the same folder:

```
calibration_acquisition_1.mat
calibration_acquisition_2.mat
calibration_acquisition_3.mat
calibration_acquisition_4.mat
calibration_acquisition_5.mat
```

**What is different from Step 3:**

| | Phantom simulation (Step 3) | Calibration simulation (Step 4) |
|---|---|---|
| Circular inclusion | ✅ Enabled (`alpha0 = 1.0 dB/cm/MHz`) | ❌ Disabled (homogeneous) |
| Background attenuation | `0.5 dB/cm/MHz` | `0.5 dB/cm/MHz` |
| Output filename prefix | `acquisition_` | `calibration_acquisition_` |
| Everything else | identical | identical |

---

## Step 5 — Run the Python Notebooks

Run the two notebooks **in order**. Both must be run before figures are produced.

### Launch Jupyter
```bash
conda activate attomo
cd /d D:\attomo
jupyter notebook
```
Your browser will open automatically.

### Notebook 1: `Compute_calibration_data.ipynb`
- Open and run all cells (**Cell → Run All**)
- Reads `calibration_acquisition_1.mat` … `calibration_acquisition_5.mat`
- Ensemble-averages the 5 realisations to compute the calibration baseline
- Saves a `calibration.pkl` file used by Notebook 2

### Notebook 2: `Attenuation_tomography.ipynb`
- Open and run all cells **after Notebook 1 has finished**
- Reads `acquisition_1.mat` … `acquisition_5.mat` + `calibration.pkl`
- Runs beamforming → cross-correlation → tomographic inversion
- Produces and saves all paper figures

> ⚠ Always run **Notebook 1 before Notebook 2**. Notebook 2 depends on `calibration.pkl` produced by Notebook 1.

---

## Expected Output Figures

The following figures from the paper are reproduced by this pipeline:

| Figure | Description |
|--------|-------------|
| Fig 1, 2 | Probe geometry and B-mode images |
| Fig 3 | Main attenuation reconstruction — 1 cm circular inclusion |
| Fig 4c, 4d | Effect of regularisation parameter |
| Fig 9 | Speed-of-sound sensitivity |
| Fig 10 | Single realisation result |

> ⚠ Figures requiring additional MATLAB simulations (Fig 4a, 4b, 5–8) and all experimental figures are not included in this pipeline.

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `kWaveGrid` not found in MATLAB | k-Wave path not added. Re-run `addpath` and `savepath`. |
| Out of GPU memory in MATLAB | Change `DATA_CAST` to `'single'` to use CPU instead. |
| `from attomo import ...` fails | Run `pip install -e .` inside the activated attomo environment. |
| Notebook 2 errors on calibration file | Make sure Notebook 1 completed without errors and `calibration.pkl` exists. |
| `acquisition_*.mat` not found | Check MATLAB working directory matches the path used in the notebook (`folder_path`). |
| `calibration_acquisition_*.mat` not found | Step 4 was skipped. Run `Script_kWave_calibration.m` in MATLAB first. |

---

## Quick Reference — Full Command Sequence

```matlab
% ── MATLAB (run scripts manually in the MATLAB IDE) ──────────────────
% Step 3: cd('D:\attomo\data'), then run Script_kWave_simulation.m
% Step 4: cd('D:\attomo\data'), then run Script_kWave_calibration.m
```

```bash
# ── Anaconda Prompt ───────────────────────────────────────────────────
conda env create -f environment_attomo_gpu.yml
conda activate attomo
pip install -e .
cd /d D:\attomo
jupyter notebook
```

Then in the browser:
1. Run `Compute_calibration_data.ipynb`
2. Run `Attenuation_tomography.ipynb`

---

## File Structure

```
attomo/
├── data/
│   ├── Script_kWave_simulation.m        ← Step 3: phantom simulation
│   ├── Script_kWave_calibration.m       ← Step 4: calibration simulation
│   ├── acquisition_1.mat                ← generated by Step 3
│   ├── ...
│   ├── acquisition_5.mat
│   ├── calibration_acquisition_1.mat    ← generated by Step 4
│   ├── ...
│   └── calibration_acquisition_5.mat
├── Compute_calibration_data.ipynb       ← Step 5, Notebook 1
├── Attenuation_tomography.ipynb         ← Step 5, Notebook 2
├── environment_attomo_gpu.yml
├── environment_attomo_cpu.yml
└── attomo/                              ← Python package source
```