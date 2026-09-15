%% === RESONANCE OF THE WHOLE SYSTEM (T37) ===
clear; clc; close all;

%% 1. LOAD DATA
d1 = load('pos1_T37.mat');

S    = d1.data.measurement.s_mat;
freq = d1.data.info.freqVect;
nPorts = 8;
nFreq  = length(freq);

%% 2. AGGREGATE METRICS ACROSS FREQUENCY

% --- Method 1: Mean power of all Sij [dB] ---
S_mean_all = zeros(1, nFreq);
for fi = 1:nFreq
    slice = S(:,:,fi);
    S_mean_all(fi) = 20*log10(mean(abs(slice(:))));
end

% --- Method 2: Mean power of transmission terms Sij only (i~=j) ---
S_mean_off = zeros(1, nFreq);
mask = ~eye(nPorts, 'logical');
for fi = 1:nFreq
    slice = S(:,:,fi);
    off   = slice(mask);
    S_mean_off(fi) = 20*log10(mean(abs(off)));
end

% --- Method 3: SVD - first singular value ---
S_svd1 = zeros(1, nFreq);
for fi = 1:nFreq
    sv = svd(S(:,:,fi));
    S_svd1(fi) = 20*log10(sv(1));
end

%% 3. RESONANCE SEARCH
min_prominence = 3;
min_distance   = 5;

metrics = {S_mean_all, S_mean_off, S_svd1};
names   = {'Mean of all S_{ij}', 'Mean of transmission S_{ij} (i~=j)', 'SVD - 1st singular value'};
res_all = cell(1,3);

fprintf('=== RESONANCE OF THE WHOLE SYSTEM (T37) ===\n\n');

for m = 1:3
    signal = -metrics{m};   % invert for findpeaks
    [~, locs, ~, prom] = findpeaks(signal, ...
        'MinPeakProminence', min_prominence, ...
        'MinPeakDistance',   min_distance);

    res_all{m}.locs     = locs;
    res_all{m}.freq_GHz = freq(locs) / 1e9;
    res_all{m}.val_dB   = metrics{m}(locs);
    res_all{m}.prom     = prom;

    fprintf('Method: %s\n', names{m});
    if isempty(locs)
        fprintf('  No resonance found\n');
    else
        for k = 1:length(locs)
            fprintf('  Resonance %d: %.4f GHz  |  value = %.2f dB  |  prominence = %.2f dB\n', ...
                k, res_all{m}.freq_GHz(k), res_all{m}.val_dB(k), res_all{m}.prom(k));
        end
    end
    fprintf('\n');
end

%% 4. VISUALIZATION
figure('Name','T37 system resonance','Position',[100 100 1000 800]);
colors_m = [0.2 0.5 0.9; 0.1 0.75 0.3; 0.9 0.3 0.2];

for m = 1:3
    subplot(3,1,m);
    plot(freq/1e9, metrics{m}, 'Color', colors_m(m,:), 'LineWidth', 1.8);
    hold on;

    % Mark the resonances
    if ~isempty(res_all{m}.locs)
        plot(res_all{m}.freq_GHz, res_all{m}.val_dB, ...
            'v', 'MarkerSize', 10, 'MarkerFaceColor', 'r', 'Color', 'r');
        for k = 1:length(res_all{m}.freq_GHz)
            text(res_all{m}.freq_GHz(k), res_all{m}.val_dB(k) - 1.2, ...
                sprintf(' %.3f GHz', res_all{m}.freq_GHz(k)), ...
                'FontSize', 8, 'Color', 'r', 'HorizontalAlignment', 'center');
        end
    end

    xlabel('Frequency [GHz]');
    ylabel('[dB]');
    title(names{m});
    grid on;
    hold off;
end

sgtitle('Resonance of the whole system - T37 phantom', 'FontSize', 13);

%% 5. AGREEMENT OF RESONANCES BETWEEN METHODS
fprintf('=== AGREEMENT OF RESONANCES BETWEEN METHODS ===\n');
tol = 0.05;   % matching tolerance [GHz]

all_freqs = [];
for m = 1:3
    all_freqs = [all_freqs, res_all{m}.freq_GHz];
end
all_freqs = sort(unique(round(all_freqs / tol) * tol));

fprintf('\n%-15s  %-8s  %-8s  %-8s\n', 'Frequency [GHz]', 'Method 1', 'Method 2', 'Method 3');
fprintf('%s\n', repmat('-', 1, 50));
for f = all_freqs
    row = '';
    for m = 1:3
        match = any(abs(res_all{m}.freq_GHz - f) <= tol);
        if match, row = [row, sprintf('  %-10s', 'yes')];
        else,      row = [row, sprintf('  %-10s', '-')]; end
    end
    fprintf('%-15.4f %s\n', f, row);
end
