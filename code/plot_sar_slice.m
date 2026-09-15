clear all; close all;
%% =========================================================================
% SCRIPT FOR DISPLAYING XZ SLICE - SAR DISTRIBUTION
% =========================================================================

% --- 1. FILE SELECTION AND LOADING ---
[file, path] = uigetfile('*.mat', 'Select exported .mat file with SAR from Sim4Life');
if isequal(file, 0)
    disp('File selection cancelled.');
    return;
else
    full_path = fullfile(path, file);
    disp(['Loading file: ', full_path]);
    data = load(full_path);
    disp('File loaded successfully!');
end

% --- 2. VARIABLE PREPARATION ---
x_axis = data.Axis0;
y_axis = data.Axis1;
z_axis = data.Axis2;
sar_data = data.Snapshot0;

disp('Processing SAR data...');

if size(sar_data, 2) > 1
    sar_1D = sqrt(sum(abs(sar_data).^2, 2));
else
    sar_1D = abs(sar_data);
end

Nx = length(x_axis); Ny = length(y_axis); Nz = length(z_axis);
num_elements = length(sar_1D);

if num_elements == Nx * Ny * Nz
    sar_3D = reshape(sar_1D, [Nx, Ny, Nz]);
    x_plot = x_axis; y_plot = y_axis; z_plot = z_axis;
elseif num_elements == (Nx-1) * (Ny-1) * (Nz-1)
    sar_3D = reshape(sar_1D, [Nx-1, Ny-1, Nz-1]);
    x_plot = x_axis(1:end-1) + diff(x_axis)/2;
    y_plot = y_axis(1:end-1) + diff(y_axis)/2;
    z_plot = z_axis(1:end-1) + diff(z_axis)/2;
else
    error('Number of field values does not match grid dimensions!');
end

% --- CONVERT AXES TO mm (axes are in meters) ---
x_plot_mm = x_plot * 1000;
y_plot_mm = y_plot * 1000;
z_plot_mm = z_plot * 1000;

% --- AUTOMATIC RANGE PRINTOUT for verification ---
fprintf('\n=== MODEL INFO ===\n');
fprintf('X range: %.4f to %.4f mm\n', min(x_plot_mm), max(x_plot_mm));
fprintf('Y range: %.4f to %.4f mm\n', min(y_plot_mm), max(y_plot_mm));
fprintf('Z range: %.4f to %.4f mm\n', min(z_plot_mm), max(z_plot_mm));

% --- 3. SLICE SELECTION ---
% Automatically take the Y-layer where the global SAR maximum is located
sar_3D(isnan(sar_3D)) = 0;
[~, idx_global] = max(sar_3D(:));
[ix_max, iy_max, iz_max] = ind2sub(size(sar_3D), idx_global);

fprintf('Global MAX SAR at point: X=%.4f mm, Y=%.4f mm, Z=%.4f mm\n', ...
    x_plot_mm(ix_max), y_plot_mm(iy_max), z_plot_mm(iz_max));
fprintf('Using Y-slice through the global maximum: Y = %.4f mm\n', y_plot_mm(iy_max));
fprintf('=====================\n\n');

% Slice through Y where the maximum is (most interesting view)
y_index = iy_max;
slice_XZ_sar = squeeze(sar_3D(:, y_index, :));

% --- 4. CONVERT TO dB ---
max_val_global = max(sar_3D(:));

if max_val_global > 0
    sar_norm = slice_XZ_sar / max_val_global;
    sar_norm(sar_norm < 1e-10) = 1e-10;  % air = -100 dB (below the displayed range)
    slice_dB = 10 * log10(sar_norm);
else
    error('SAR is zero everywhere - check the Sim4Life export.');
end

% --- 5. ZOOM - automatically based on actual model range ---
% Show the entire model (or adjust as needed)
% x_zoom = [min(x_plot_mm), max(x_plot_mm)];
% z_zoom = [min(z_plot_mm), max(z_plot_mm)];

x_zoom = [-50, 50];
z_zoom = [-50, 50];

% --- 6. PLOTTING ---
figure('Name', 'SAR Distribution', 'Position', [100 100 800 700]);

h = pcolor(x_plot_mm, z_plot_mm, slice_dB.');
set(h, 'EdgeColor', 'none');
shading interp;
set(gca, 'YDir', 'normal');

hold on;
% Isolines -3, -10, -20 dB
% contour(x_plot_mm, z_plot_mm, slice_dB.', [-3, -10, -20], ...
%     'LineColor', 'k', 'LineWidth', 1);

% Antenna/tissue interface - adjust the Z value according to your model (in mm)
% yline(0, 'w--', 'LineWidth', 1.5);
hold off;

colormap('jet');
caxis([-40 0]);  % Show top 40 dB dynamic range

cb = colorbar;
cb.Label.String = 'SAR [dB]';
cb.Label.FontWeight = 'bold';

xlabel('X axis (mm)', 'FontWeight', 'bold');
ylabel('Z axis (mm)', 'FontWeight', 'bold');
yline(5, 'w--', 'LineWidth', 1.5);
%title(sprintf('SAR Distribution - XZ slice (Y = %.4f mm)', y_plot_mm(y_index)),'FontWeight', 'bold');

xlim(x_zoom);
ylim(z_zoom);

disp('Done!');
