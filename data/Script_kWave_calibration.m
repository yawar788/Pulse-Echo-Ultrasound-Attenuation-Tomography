% =========================================================
% GPU READY: DATA_CAST = 'gpuArray-single'
% To run on CPU: change DATA_CAST to 'single' (line below)
% Requires: k-Wave toolbox, MATLAB Parallel Computing Toolbox
% =========================================================

% Run this AFTER Script_kWave_simulation.m has finished.
% Output is read by Compute_calibration_data.ipynb
% GPU toggle (line 9):
%   'gpuArray-single'  ->  GPU
%   'single'           ->  CPU

clear all; clc; close all;

DATA_CAST = 'gpuArray-single';   % change to 'single' on CPU machine

%% CREATE MESHGRID

pml_x_size = 20;                    % [grid points]
pml_y_size = 20;                    % [grid points]

Nx = 2048 - 2*pml_x_size;          % [grid points]
Ny = 2200 - 2*pml_y_size;          % [grid points]
dx = 25e-6;                         % [m]
dy = 25e-6;                         % [m]

kgrid = kWaveGrid(Nx, dx, Ny, dy);

%% MEDIUM PROPERTIES

c0           = 1540;    % [m/s]
alpha_coeff0 = 0.2;    % [dB/(MHz cm)]
alpha_power0 = 1.0;
rho0         = 1000;    % [kg/m^3]

medium.alpha_mode = 'no_dispersion';

rng(20)

for ireal = 1:5

    % Random scatterer background - identical to simulation script
    background_map_mean = 1;
    background_map_std  = 0.008;
    scat_locs  = randn([Nx, Ny]);
    scat_locs2 = randn([Nx, Ny]);
    background_map = background_map_mean + background_map_std * scat_locs;

    % Homogeneous medium properties
    sound_speed_map  = c0           * ones(Nx, Ny);
    density_map      = rho0         * ones(Nx, Ny) .* background_map;
    alpha_coeff_map  = alpha_coeff0 * ones(Nx, Ny);

    % *** NO INCLUSION - this is the only difference from simulation script ***

    medium.sound_speed  = sound_speed_map;
    medium.density      = density_map;
    medium.alpha_coeff  = alpha_coeff_map;
    medium.alpha_power  = alpha_power0;

    x_axis = [0, Nx * dx * 1e3];
    y_axis = [0, Ny * dy * 1e3];

    % Time array
    t_end = (Nx * dx) * 2.2 / c0;
    kgrid.makeTime(c0, 0.6, t_end);

    %% Probe and input signal - identical to simulation script

    pts_pitch    = 8;
    num_elements = 256 * pts_pitch;
    x_offset     = 10;

    source.u_mask = zeros(Nx, Ny);
    start_index   = Ny/2 - round(num_elements/2) + 1;
    source.u_mask(x_offset, start_index:1:start_index + num_elements - 1) = 1;

    sampling_freq     = 1 / kgrid.dt;
    element_spacing   = dy;
    tone_burst_freq   = 5e6;
    tone_burst_cycles = 7;
    time_offset       = 920;

    element_index = -(num_elements/pts_pitch - 1)/2 : (num_elements/pts_pitch - 1)/2;

    sensor.record = {'p'};
    sensor.mask   = zeros(Nx, Ny);
    sensor.mask(x_offset, start_index:1:start_index + num_elements - 1) = 1;


    steering_angles = -27.5:0.5:27.5;

    nangles    = length(steering_angles);
    scan_lines = zeros(kgrid.Nt, num_elements/pts_pitch, nangles);

    input_args = {'DisplayMask', source.u_mask, 'PlotScale', [-5e4, 5e4], ...
                  'PMLInside',   false, ...
                  'PMLSize',     [pml_x_size, pml_y_size], ...
                  'PlotSim',     false, ...
                  'DataCast',    DATA_CAST, ...
                  'PMLAlpha',    4, ...
                  'ScaleSourceTerms', false};

    for itx = 1:nangles

        steering_angle = steering_angles(itx)

        tone_burst_offset = time_offset + element_spacing * pts_pitch * element_index * ...
            sin(steering_angle * pi/180) / (c0 * kgrid.dt);

        source.ux = repelem(toneBurst(sampling_freq, tone_burst_freq, tone_burst_cycles, ...
            'SignalOffset', tone_burst_offset, 'Envelope', 'Gaussian'), pts_pitch, 1);

        source.u_mode = 'additive-no-correction';

        sensor_data = kspaceFirstOrder2D(kgrid, medium, source, sensor, input_args{:});

        scan_lines(:,:,itx) = ...
            sensor_data.p(1:pts_pitch:end,:)' + sensor_data.p(2:pts_pitch:end,:)' + ...
            sensor_data.p(3:pts_pitch:end,:)' + sensor_data.p(4:pts_pitch:end,:)' + ...
            sensor_data.p(5:pts_pitch:end,:)' + sensor_data.p(6:pts_pitch:end,:)' + ...
            sensor_data.p(7:pts_pitch:end,:)' + sensor_data.p(8:pts_pitch:end,:)';

    end

    %% Save

    properties.freq         = tone_burst_freq;
    properties.pitch        = pts_pitch * element_spacing;
    properties.c0           = c0;
    properties.num_elements = num_elements / pts_pitch;
    properties.t0           = (time_offset - 1) * kgrid.dt;
    properties.dt           = kgrid.dt;
    properties.angles       = steering_angles;

    folder   = './';
    filename = [folder, 'calibration_acquisition_', num2str(ireal), '.mat']

    save(filename, 'scan_lines', 'properties');

end