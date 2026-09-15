clear; clc; close all;

%% 1. LOAD DATA
d1 = load('pos4_T37_v2.mat');   % change to the correct file
d2 = load('pos4_T44_v2.mat');

S1   = d1.data.measurement.s_mat;
S2   = d2.data.measurement.s_mat;
freq = d1.data.info.freqVect;
f_ghz = freq / 1e9;
nPorts = 8;
nFreq  = length(freq);

%% 2. ANTENNA POSITIONS
r_antenna  = 55;
angles_deg = 270 + (0:nPorts-1) * 45;
angles_rad = deg2rad(angles_deg);
ant_x = r_antenna * cos(angles_rad);
ant_y = r_antenna * sin(angles_rad);

fprintf('=== DATA DIAGNOSTICS ===\n');
fprintf('Frequency range: %.3f - %.3f GHz\n', min(f_ghz), max(f_ghz));
fprintf('Expected delta eps_r = 1.1\n');
fprintf('Heated region: 2 cm diameter, 30 ml volume\n\n');

%% 3. AMPLITUDE AND PHASE ANALYSIS
% Compute the amplitude and phase differences separately
diff_amp   = abs(S2)   - abs(S1);           % amplitude difference
diff_phase = angle(S2) - angle(S1);         % phase difference [rad]
diff_phase = atan2(sin(diff_phase), ...
                   cos(diff_phase));         % normalize to [-pi, pi]

% Average over all pairs and frequencies
mean_amp_freq   = zeros(1, nFreq);
mean_phase_freq = zeros(1, nFreq);

for fi = 1:nFreq
    a = diff_amp(:,:,fi);   a(1:nPorts+1:end) = NaN;
    p = diff_phase(:,:,fi); p(1:nPorts+1:end) = NaN;
    mean_amp_freq(fi)   = mean(abs(a(:)),   'omitnan');
    mean_phase_freq(fi) = mean(abs(p(:)),   'omitnan');
end

figure('Name', 'Diagnostics: amplitude and phase', 'Color', 'w', ...
    'Units', 'normalized', 'OuterPosition', [0 0 0.8 0.5]);

subplot(1,2,1);
plot(f_ghz, mean_amp_freq, 'LineWidth', 1.5, 'Color', [0 0.45 0.74]);
grid on; xlabel('Frequency [GHz]'); ylabel('Mean |\Delta S| [-]');
title('Mean amplitude difference');
[~, fi_amp] = max(mean_amp_freq);
xline(f_ghz(fi_amp), '--r', sprintf('%.2f GHz', f_ghz(fi_amp)), ...
    'LineWidth', 1.5, 'LabelVerticalAlignment', 'bottom');

subplot(1,2,2);
plot(f_ghz, mean_phase_freq * (180/pi), 'LineWidth', 1.5, 'Color', [0.85 0.33 0.1]);
grid on; xlabel('Frequency [GHz]'); ylabel('Mean |\Delta\phi| [\circ]');
title('Mean phase difference');
[~, fi_phase] = max(mean_phase_freq);
xline(f_ghz(fi_phase), '--r', sprintf('%.2f GHz', f_ghz(fi_phase)), ...
    'LineWidth', 1.5, 'LabelVerticalAlignment', 'bottom');

fprintf('Best frequency (amplitude): %.3f GHz\n', f_ghz(fi_amp));
fprintf('Best frequency (phase):     %.3f GHz\n', f_ghz(fi_phase));

%% 4. PAIR SENSITIVITY HEATMAP
% Which antenna pair is the most sensitive
sens_amp   = zeros(nPorts, nPorts);
sens_phase = zeros(nPorts, nPorts);

for tx = 1:nPorts
    for rx = 1:nPorts
        if tx == rx; continue; end
        sens_amp(tx,rx)   = mean(abs(squeeze(diff_amp(tx,rx,:))));
        sens_phase(tx,rx) = mean(abs(squeeze(diff_phase(tx,rx,:)))) * (180/pi);
    end
end

figure('Name', 'Antenna pair sensitivity', 'Color', 'w', ...
    'Units', 'normalized', 'OuterPosition', [0 0 0.7 0.5]);

subplot(1,2,1);
imagesc(sens_amp); colormap('jet'); colorbar; axis square;
set(gca, 'XTick', 1:8, 'YTick', 1:8);
xlabel('RX'); ylabel('TX');
title('Amplitude sensitivity |\Delta S| per pair');

subplot(1,2,2);
imagesc(sens_phase); colormap('jet'); colorbar; axis square;
set(gca, 'XTick', 1:8, 'YTick', 1:8);
xlabel('RX'); ylabel('TX');
title('Phase sensitivity |\Delta\phi| [\circ] per pair');

%% 5. PHASE-BASED DAS RECONSTRUCTION
% For a small eps_r change, phase shift is more sensitive than amplitude
fprintf('\nRunning phase-based DAS reconstruction...\n');

c0       = 3e8;
eps_r    = 54.48;
v_medium = c0 / sqrt(eps_r);

res   = 1;
r_max = 55;
x_vec = -r_max : res : r_max;
y_vec = -r_max : res : r_max;
[X, Y] = meshgrid(x_vec, y_vec);
mask   = sqrt(X.^2 + Y.^2) <= r_max;
nx = length(x_vec);
ny = length(y_vec);

% Frequency band
f_min     = 1.0e9;
f_max     = 3.0e9;
freq_mask = (freq >= f_min) & (freq <= f_max);
nFFT      = 2048;   % larger FFT for better resolution
dt        = 1 / (nFFT * mean(diff(freq)));
t_axis    = (0 : nFFT-1) * dt;

% Weight pairs by sensitivity - more sensitive pairs get a higher weight
weight_matrix = sens_phase / max(sens_phase(:));

% DAS with the phase signal
image_amp   = zeros(ny, nx);
image_phase = zeros(ny, nx);

for tx = 1:nPorts
    for rx = 1:nPorts
        if tx == rx; continue; end

        w = weight_matrix(tx, rx);   % pair weight

        % --- Amplitude DAS ---
        sig_amp_fd = squeeze(diff_amp(tx, rx, :));
        sig_amp_fd_masked           = zeros(nFreq, 1);
        sig_amp_fd_masked(freq_mask) = sig_amp_fd(freq_mask) .* ...
                                       hann(sum(freq_mask));
        sig_amp_padded              = zeros(nFFT, 1);
        sig_amp_padded(1:nFreq)     = sig_amp_fd_masked;
        sig_amp_td                  = real(ifft(sig_amp_padded));

        % --- Phase DAS ---
        sig_ph_fd = squeeze(diff_phase(tx, rx, :));
        sig_ph_fd_masked           = zeros(nFreq, 1);
        sig_ph_fd_masked(freq_mask) = sig_ph_fd(freq_mask) .* ...
                                      hann(sum(freq_mask));
        sig_ph_padded               = zeros(nFFT, 1);
        sig_ph_padded(1:nFreq)      = sig_ph_fd_masked;
        sig_ph_td                   = real(ifft(sig_ph_padded));

        % Delay
        d_tx  = sqrt((X - ant_x(tx)).^2 + (Y - ant_y(tx)).^2) * 1e-3;
        d_rx  = sqrt((X - ant_x(rx)).^2 + (Y - ant_y(rx)).^2) * 1e-3;
        delay = (d_tx + d_rx) / v_medium;
        valid = delay < t_axis(end) & delay > 0;

        si_amp   = zeros(ny, nx);
        si_phase = zeros(ny, nx);

        si_amp(valid)   = interp1(t_axis, sig_amp_td,  delay(valid), 'linear', 0);
        si_phase(valid) = interp1(t_axis, sig_ph_td,   delay(valid), 'linear', 0);

        image_amp   = image_amp   + w * si_amp.^2;
        image_phase = image_phase + w * si_phase.^2;
    end
end

image_amp(~mask)   = NaN;
image_phase(~mask) = NaN;

% Robust normalization helper (replaces the previous line 171)
norm_img = @(I) (I - min(I(:),[],'all','omitnan')) ./ ...
                max(eps, (max(I(:),[],'all','omitnan') - min(I(:),[],'all','omitnan')));

img_amp_n   = norm_img(image_amp);
img_phase_n = norm_img(image_phase);

% Combined image
img_combined = norm_img(img_amp_n + img_phase_n);

%% 6. PLOT RESULTS
theta_c = linspace(0, 2*pi, 200);

titles = {'DAS - amplitude', 'DAS - phase', 'DAS - combined'};
imgs   = {img_amp_n, img_phase_n, img_combined};

figure('Name', 'DAS Reconstruction', 'Color', 'w', ...
    'Units', 'normalized', 'OuterPosition', [0 0 1 0.7]);

for k = 1:3
    subplot(1, 3, k);
    imagesc(x_vec, y_vec, imrotate(imgs{k}, 90)); % 180 for position 1
    set(gca, 'YDir', 'normal'); axis image;
    axis equal;
    xlim([-55 55]); % changed
    ylim([-55 55]);
    colormap('jet'); clim([0 1]);
    cb = colorbar;
    cb.Label.String = 'Norm. intensity [-]';
    hold on;

    % Antenna positions
    plot(ant_x, ant_y, 'ws', 'MarkerSize', 9, 'MarkerFaceColor', 'w');
    for i = 1:nPorts
        text(ant_x(i)*1.18, ant_y(i)*1.18, num2str(i), ...
            'Color', 'w', 'FontSize', 8, 'FontWeight', 'bold', ...
            'HorizontalAlignment', 'center');
    end

    % Outline of the measured area
    plot(r_max*cos(theta_c), r_max*sin(theta_c), '--w', 'LineWidth', 1.2);

    % Expected location of the heated region (antenna 1 = bottom)
    % Antenna 1 is at (ant_x(1), ant_y(1)), heated region ~2 cm from it
    dir_x1 = -ant_x(4) / r_antenna;
    dir_y1 = -ant_y(4) / r_antenna;
    cx1 = ant_x(4) + 20 * dir_x1;   % 2 cm inward
    cy1 = ant_y(4) + 20 * dir_y1;
    theta_o = linspace(0, 2*pi, 110);
    plot(cx1 + 10*cos(theta_o), cy1 + 10*sin(theta_o), ...
        '--k', 'LineWidth', 1.5);
    text(cx1, cy1, 'position 2', 'Color', 'k', 'FontSize', 7, ...
        'HorizontalAlignment', 'center');

    xlabel('X [mm]', 'FontWeight', 'bold');
    ylabel('Y [mm]', 'FontWeight', 'bold');
    title(titles{k}, 'FontWeight', 'bold');
end
sgtitle(sprintf('DAS reconstruction  |  \\epsilon_r = %.0f  |  f = %.1f-%.1f GHz  |  \\Delta\\epsilon_r = 1.1', ...
    eps_r, f_min/1e9, f_max/1e9), 'FontWeight', 'bold');

fprintf('Done.\n');
