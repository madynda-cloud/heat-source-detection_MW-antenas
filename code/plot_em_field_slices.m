clear all; close all;
%% =========================================================================
% SCRIPT FOR DISPLAYING XZ SLICE (Real, imaginary, and RMS field components)
% =========================================================================

% --- 1. FILE SELECTION AND LOADING ---
[file, path] = uigetfile('*.mat', 'Select exported .mat file from Sim4Life');
if isequal(file, 0)
    disp('File selection cancelled.');
    return;
else
    full_path = fullfile(path, file);
    disp(['Loading file: ', full_path]);
    data = load(full_path);
    disp('File loaded successfully!');
end

% --- 2. VARIABLE PREPARATION FROM THE FILE ---
x_axis = data.Axis0;
y_axis = data.Axis1;
z_axis = data.Axis2;
field_vectors = data.Snapshot0; % [N x 3] matrix of vectors

disp('Computing field magnitudes...');

if isreal(field_vectors)
    warning('Data does not contain an imaginary component!');
    E_real = field_vectors;
    E_imag = zeros(size(field_vectors));
else
    E_real = real(field_vectors);
    E_imag = imag(field_vectors);
end

% Magnitude calculation for the real and imaginary components
mag_real_1D = sqrt(sum(E_real.^2, 2));
mag_imag_1D = sqrt(sum(E_imag.^2, 2));

% --- RMS OF THE TOTAL FIELD ---
% Total amplitude of the complex vector divided by sqrt(2)
mag_rms_1D = sqrt(sum(abs(field_vectors).^2, 2)) / sqrt(2);

% Number of elements along each axis
Nx = length(x_axis); Ny = length(y_axis); Nz = length(z_axis);
num_elements = length(mag_real_1D);

% Smart reshape and axis recalculation
if num_elements == Nx * Ny * Nz
    field_3D_real = reshape(mag_real_1D, [Nx, Ny, Nz]);
    field_3D_imag = reshape(mag_imag_1D, [Nx, Ny, Nz]);
    field_3D_rms  = reshape(mag_rms_1D,  [Nx, Ny, Nz]); % RMS added

    x_plot = x_axis; y_plot = y_axis; z_plot = z_axis;
elseif num_elements == (Nx - 1) * (Ny - 1) * (Nz - 1)
    field_3D_real = reshape(mag_real_1D, [Nx-1, Ny-1, Nz-1]);
    field_3D_imag = reshape(mag_imag_1D, [Nx-1, Ny-1, Nz-1]);
    field_3D_rms  = reshape(mag_rms_1D,  [Nx-1, Ny-1, Nz-1]); % RMS added

    x_plot = x_axis(1:end-1) + diff(x_axis)/2;
    y_plot = y_axis(1:end-1) + diff(y_axis)/2;
    z_plot = z_axis(1:end-1) + diff(z_axis)/2;
else
    error('Number of field values does not match grid dimensions!');
end

% --- 3. SLICE SELECTION (Slicing in the XZ plane) ---
y_target = 0; % Where exactly should the slice be taken? (in meters)
[~, y_index] = min(abs(y_plot - y_target));

slice_XZ_real = squeeze(field_3D_real(:, y_index, :));
slice_XZ_imag = squeeze(field_3D_imag(:, y_index, :));
slice_XZ_rms  = squeeze(field_3D_rms(:, y_index, :)); % RMS added

% --- 4. CONVERT TO dB SCALE ---
% Use a shared maximum for the real and imaginary parts for visual comparison
max_val_ri = max(max(slice_XZ_real(:)), max(slice_XZ_imag(:)));
% Use its own maximum for RMS
max_val_rms = max(slice_XZ_rms(:));

if max_val_ri > 0
    slice_XZ_real_dB = 20 * log10((slice_XZ_real + eps) / max_val_ri);
    slice_XZ_imag_dB = 20 * log10((slice_XZ_imag + eps) / max_val_ri);
else
    slice_XZ_real_dB = slice_XZ_real;
    slice_XZ_imag_dB = slice_XZ_imag;
end

if max_val_rms > 0
    slice_XZ_rms_dB = 20 * log10((slice_XZ_rms + eps) / max_val_rms);
else
    slice_XZ_rms_dB = slice_XZ_rms;
end

% =========================================================================
% --- 5. PLOTTING IN SEPARATE WINDOWS ---
% =========================================================================

x_plot_mm = x_plot * 1000;
y_plot_mm = y_plot * 1000;
z_plot_mm = z_plot * 1000;

x_zoom_mm = [-50, 50];
z_zoom_mm = [-50, 50];

% ----------------- PLOT 1: REAL PART -----------------
figure('Name', 'Real part of the field');
h1 = pcolor(x_plot_mm, z_plot_mm, slice_XZ_real_dB.');
set(h1, 'EdgeColor', 'none'); shading interp; set(gca, 'YDir', 'normal');
axis image; hold on;
%contour(x_plot_mm, z_plot_mm, slice_XZ_real_dB.', [-35, -45], 'LineColor', 'k', 'LineWidth', 1);
yline(5, 'w--', 'LineWidth', 1.5);
hold off;
colormap('jet'); caxis([-70 0]);
cb1 = colorbar; cb1.Label.String = 'Electric field intensity [dB]'; cb1.Label.FontWeight = 'bold';
xlabel('X axis (mm)', 'FontWeight', 'bold'); ylabel('Z axis (mm)', 'FontWeight', 'bold');
%title('REAL part', 'FontWeight', 'bold');
xlim(x_zoom_mm); ylim(z_zoom_mm);

% ----------------- PLOT 2: IMAGINARY PART -----------------
figure('Name', 'Imaginary part of the field');
h2 = pcolor(x_plot_mm, z_plot_mm, slice_XZ_imag_dB.');
set(h2, 'EdgeColor', 'none'); shading interp; set(gca, 'YDir', 'normal');
axis image; hold on;
%contour(x_plot_mm, z_plot_mm, slice_XZ_imag_dB.', [-10, -20], 'LineColor', 'k', 'LineWidth', 1);
yline(5, 'w--', 'LineWidth', 1.5);
hold off;
colormap('jet'); caxis([-55 0]);
cb2 = colorbar; cb2.Label.String = 'Electric field intensity [dB]'; cb2.Label.FontWeight = 'bold';
xlabel('X axis (mm)', 'FontWeight', 'bold'); ylabel('Z axis (mm)', 'FontWeight', 'bold');
%title('IMAGINARY part', 'FontWeight', 'bold');
xlim(x_zoom_mm); ylim(z_zoom_mm);

% ----------------- PLOT 3: RMS OF THE TOTAL FIELD -----------------
figure('Name', 'Total RMS field');
h3 = pcolor(x_plot_mm, z_plot_mm, slice_XZ_rms_dB.');
set(h3, 'EdgeColor', 'none'); shading interp; set(gca, 'YDir', 'normal');
axis image; hold on;
%contour(x_plot_mm, z_plot_mm, slice_XZ_rms_dB.', [-10, -20], 'LineColor', 'k', 'LineWidth', 1);
yline(5, 'w--', 'LineWidth', 1.5);
hold off;
colormap('jet'); caxis([-70 0]);
cb3 = colorbar; cb3.Label.String = 'Electric field intensity [dB]'; cb3.Label.FontWeight = 'bold';
xlabel('X axis (mm)', 'FontWeight', 'bold'); ylabel('Z axis (mm)', 'FontWeight', 'bold');
%title('TOTAL MAGNITUDE (RMS)', 'FontWeight', 'bold');
xlim(x_zoom_mm); ylim(z_zoom_mm);

disp('Done! Three plots displayed: real part, imaginary part, and RMS.');
