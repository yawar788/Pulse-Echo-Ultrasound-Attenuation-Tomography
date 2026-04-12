# attomo

A Python package for tissue attenuation imaging with Pulse-Echo Ultrasound Attenuation Tomography technique. The method and implementation details are carefully described in 

> [tba].

Please cite this article if you use codes in <i>attomo</i>.


### Installation

(1) If required, set up python by installing the latest <a href="https://docs.conda.io/en/latest/miniconda.html">Miniconda</a> distribution.

(2) All required packages can be installed by creating a new environment for <i>attomo</i> as

<code> conda env create -f environment_attomo_cpu(gpu).yml </code>

(3) Activate the environment:

<code> conda activate attomo </code>

(4) Set up <i>attomo</i> module (developer mode) by running:

<code> pip install -e . </code>

in this directory.

(5) You are now ready to run the self-explanatory jupyter notebooks! Just type

<code> jupyter-notebook </code>

and select the notebooks (e.g., <a href="Attenuation_tomography.ipynb">Attenuation_tomography.ipynb</a>).


### Data:

This public version of the code is written to use the ultrasound signals computed from the <a href="http://www.k-wave.org/">k-Wave</a> open-source wave propagation simulator. The Matlab script used to generate the necessary data can be found in <a href="data/Script_kWave_simulation.m">./data/Script_kWave_simulation.m </a>.


---

## Simulation Instructions (k-Wave)

### Requirements
- MATLAB with k-Wave toolbox (v1.4.1 tested)
- GPU with CUDA support recommended (CPU also supported)

### Step 1 — Generate acquisition data
Run in MATLAB:
```matlab
cd('./data')
run('Script_kWave_simulation.m')
```
Generates: `acquisition_1.mat` ... `acquisition_5.mat`

### Step 2 — Generate calibration data
Run in MATLAB:
```matlab
cd('./data')
run('Script_kWave_calibration.m')
```
Generates: `calibration_acquisition_1.mat` ... `calibration_acquisition_5.mat`

> **GPU users:** Set DATA_CAST = 'gpuArray-single' at top of both scripts.
> **CPU users:** Set DATA_CAST = 'single' (default in this repo).

## Running notebooks (in order)
1. Compute_calibration_data.ipynb
2. Attenuation_tomography.ipynb

