clear all; close all;

%% === AXIS AND REFERENCE LINE SETTINGS (adjust as needed) ===
x_axis_label = 'Frequency [GHz]';
y_axis_label = 'Reflection coefficient [dB]';

horizontal_line_y = -10;   % -10 dB threshold
vertical_line_x1 = 1;      % 1 GHz (in this data the X axis is already in GHz)
vertical_line_x2 = 3;      % 3 GHz
% =======================================================

%% 1. File selection
[files, path] = uigetfile('*.csv', 'Select CSV file (final antenna model)', 'MultiSelect', 'on');

if isequal(files, 0)
    disp('User cancelled the selection.');
    return;
end

if ischar(files)
    files = {files};
end

fprintf('\n--- LOADING DATA ---\n');

%% 2. Figure setup
figure('Color', 'w', 'Position', [200, 200, 800, 500]);
hold on; grid on;

% Blue color for the final model
curve_color = [0 0.4470 0.7410];

%% 3. Loading and plotting
for f_idx = 1:length(files)
    currentFile = files{f_idx};
    fullPath = fullfile(path, currentFile);

    try
        dataMatrix = readmatrix(fullPath);
        numCols = size(dataMatrix, 2);

        for c = 1:2:numCols
            if c+1 <= numCols
                freq = dataMatrix(:, c);
                val  = dataMatrix(:, c+1);

                mask = ~isnan(freq) & ~isnan(val);

                if any(mask)
                    freq_clean = freq(mask);
                    val_clean = val(mask);

                    % Convert to dB (only if linear data happens to appear)
                    if all(val_clean >= 0)
                        val_clean(val_clean == 0) = 1e-12;
                        val_clean = 20 * log10(val_clean);
                    end

                    % Plot the final model's curve
                    plot(freq_clean, val_clean, ...
                         'LineWidth', 2, ...
                         'Color', curve_color);
                end
            end
        end
        fprintf('File "%s" plotted successfully.\n', currentFile);

    catch ME
        fprintf('Error reading %s: %s\n', currentFile, ME.message);
    end
end

%% 4. Axis formatting and reference lines
xlabel(x_axis_label, 'Interpreter', 'none', 'FontWeight', 'bold');
ylabel(y_axis_label, 'Interpreter', 'none', 'FontWeight', 'bold');

% Horizontal line at -10 dB
yline(horizontal_line_y, 'k--', '-10 dB', ...
    'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left', 'FontWeight', 'bold');

% Vertical lines (1 GHz and 3 GHz)
xline(vertical_line_x1, 'r--', '1 GHz', ...
    'LineWidth', 1.5, 'LabelVerticalAlignment', 'bottom', 'FontWeight', 'bold');

xline(vertical_line_x2, 'r--', '3 GHz', ...
    'LineWidth', 1.5, 'LabelVerticalAlignment', 'bottom', 'FontWeight', 'bold');

% Set sensible X limits so the lines sit at the plot edges
xlim([min(freq_clean) max(freq_clean)]);

fprintf('\nDone.\n');
