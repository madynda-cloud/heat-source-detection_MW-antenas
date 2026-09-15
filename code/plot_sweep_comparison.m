clear all; close all;

%% === AXIS AND REFERENCE LINE SETTINGS ===
x_axis_label = 'Frequency [GHz]';
y_axis_label = 'Magnitude [dB]';
horizontal_line_y = -10;
vertical_line_x1 = 1e9;
vertical_line_x2 = 3e9;

%% 1. File selection
[files, path] = uigetfile('*.csv', 'Select CSV files', 'MultiSelect', 'on');
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

% Color palette - each curve gets a different color
colors = [
    0.0000, 0.4470, 0.7410;   % blue
    0.8500, 0.3250, 0.0980;   % orange
    0.4660, 0.6740, 0.1880;   % green
    0.4940, 0.1840, 0.5560;   % purple
    0.9290, 0.6940, 0.1250;   % yellow
    0.3010, 0.7450, 0.9330;   % light blue
    0.6350, 0.0780, 0.1840;   % dark red
];

%% 3. Loading and plotting
legend_names = {};
color_index = 1;
freq_clean = [];

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
                    val_clean  = val(mask);

                    if all(val_clean >= 0)
                        val_clean(val_clean == 0) = 1e-12;
                        val_clean = 20 * log10(val_clean);
                    end

                    % Pick a color (cycles if there are more curves than colors)
                    current_color = colors(mod(color_index-1, size(colors,1))+1, :);

                    plot(freq_clean, val_clean, ...
                        'LineWidth', 2, ...
                        'Color', current_color);

                    % Legend name = file name without extension
                    [~, name, ~] = fileparts(currentFile);
                    legend_names{end+1} = strrep(name, '_', ' ');

                    color_index = color_index + 1;
                end
            end
        end

        fprintf('File "%s" plotted successfully.\n', currentFile);
    catch ME
        fprintf('Error reading %s: %s\n', currentFile, ME.message);
    end
end

%% 4. Reference lines
yline(horizontal_line_y, '--', '-10 dB', ...
    'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left', 'FontWeight', 'bold', ...
    'Color', [0 0 0]);  % black

xline(vertical_line_x1, '--', '1 GHz', ...
    'LineWidth', 1.5, 'LabelVerticalAlignment', 'bottom', 'FontWeight', 'bold', ...
    'Color', [1 0 0]);  % red

xline(vertical_line_x2, '--', '3 GHz', ...
    'LineWidth', 1.5, 'LabelVerticalAlignment', 'bottom', 'FontWeight', 'bold', ...
    'Color', [1 0 0]);  % red
%% 5. Formatting
xlabel(x_axis_label, 'Interpreter', 'none', 'FontWeight', 'bold');
ylabel(y_axis_label, 'Interpreter', 'none', 'FontWeight', 'bold');

if ~isempty(freq_clean)
    xlim([min(freq_clean), max(freq_clean)]);
end

% Legend for data curves only (without reference lines)
%legend(legend_names, 'Location', 'best', 'Interpreter', 'none');

fprintf('\nDone.\n');
