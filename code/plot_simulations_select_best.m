clear all; close all;

%% 1. File selection and initialization
[files, path] = uigetfile('*.csv', 'Select one or more CSV files', 'MultiSelect', 'on');
if isequal(files, 0)
    disp('User cancelled the selection.');
    return;
end

if ischar(files)
    files = {files}; % Ensure a single file is also processed as a list
end

simData = struct();
count = 0;
fprintf('\n--- LOADING DATA ---\n');

%% 2. Universal loop over all selected files
for f_idx = 1:length(files)
    currentFile = files{f_idx};
    fullPath = fullfile(path, currentFile);

    try
        % 1. Read the first row of the file as text (headers)
        T_headers = readcell(fullPath, 'Range', '1:1');

        % 2. Load the numeric data
        dataMatrix = readmatrix(fullPath);
        numCols = size(dataMatrix, 2);

        % Iterate through the file in column pairs (X and Y)
        for c = 1:2:numCols
            if c+1 <= numCols
                freq = dataMatrix(:, c);
                val  = dataMatrix(:, c+1);

                % Remove empty values (NaN)
                mask = ~isnan(freq) & ~isnan(val);

                if any(mask)
                    count = count + 1;
                    simData(count).Freq = freq(mask);
                    simData(count).Value = val(mask);

                    % Extract the original name
                    if c <= length(T_headers) && (ischar(T_headers{c}) || isstring(T_headers{c}))
                        origName = char(T_headers{c});
                        if length(files) > 1
                            [~, fileName, ~] = fileparts(currentFile);
                            simData(count).Name = sprintf('[%s] %s', strrep(fileName, '_', ' '), origName);
                        else
                            simData(count).Name = origName;
                        end
                    else
                        simData(count).Name = sprintf('Curve %d', count);
                    end
                end
            end
        end
        fprintf('File %s loaded successfully.\n', currentFile);
    catch ME
        fprintf('Error reading %s: %s\n', currentFile, ME.message);
    end
end

if count == 0
    error('No valid data was loaded.');
end
fprintf('Total curves loaded for analysis: %d\n', count);

%% 3. Plot ALL loaded curves
figure('Color', 'w', 'Name', 'All curves');
hold on; grid on;
colors = lines(min(count, 20));

for k = 1:count
    plot(simData(k).Freq, simData(k).Value, ...
         'LineWidth', 1.5, ...
         'Color', colors(mod(k-1, size(colors, 1)) + 1, :), ...
         'DisplayName', simData(k).Name);
end

xlabel('Frequency [GHz]');
ylabel('Abs Reflection Coefficient');
title('Comparison of all loaded simulations');

if count <= 25
    legend('Location', 'eastoutside', 'Interpreter', 'none', 'FontSize', 8);
else
    disp('Legend for the first plot hidden (too many curves).');
end

%% 4. Analysis and selection of the "best" curve (smoothest with the lowest values below the threshold)
fprintf('\n--- CURVE QUALITY ANALYSIS ---\n');

optimal_antenna_threshold = -10; % <--- SET YOUR THRESHOLD HERE

for k = 1:count
    % 1. Info about the absolute minimum (for display)
    [minVal, minIdx] = min(simData(k).Value);
    simData(k).MinRefl = minVal;
    simData(k).ResFreq = simData(k).Freq(minIdx);

    % 2. "Lowest values" criterion: average of the whole curve
    avg_value = mean(simData(k).Value);
    simData(k).MeanValue = avg_value;

    % 3. "Smoothest curve" criterion
    roughness = sum(abs(diff(simData(k).Value)));
    simData(k).Roughness = roughness;

    % 4. Overall score calculation with a CONDITION
    roughness_weight = 2; % <--- Tune the ratio between smoothness and average here

    if minVal > optimal_antenna_threshold
        % If the curve never drops below the threshold at any point,
        % it gets the worst possible score (-Inf) and is discarded.
        simData(k).Score = -Inf;
    else
        % If it met the threshold, compute its smoothness/average score
        simData(k).Score = - (avg_value + (roughness_weight * roughness));
    end
end

%% 5. Display the winner
all_scores = [simData.Score];
[best_score, winner_idx] = max(all_scores);

winner = simData(winner_idx);

fprintf('Best curve found!\n');
fprintf('  - Name: %s\n', winner.Name);
fprintf('  - Resonant frequency (local dip): %.3f GHz\n', winner.ResFreq);
fprintf('  - Minimum (dip depth): %.2f\n', winner.MinRefl);
fprintf('  - Average value of the whole curve: %.2f\n', winner.MeanValue);
fprintf('  - Roughness index (lower = smoother): %.2f\n', winner.Roughness);

% Plot the winner separately
figure('Color', 'w', 'Name', 'WINNING CURVE');
hold on; grid on;

plot(winner.Freq, winner.Value, 'g-', 'LineWidth', 3, ...
    'DisplayName', winner.Name);

% Show the average value for reference
yline(winner.MeanValue, 'r--', 'Average value', 'LineWidth', 1.5, 'HandleVisibility','off');

xlabel('Frequency [GHz]');
ylabel('Abs Reflection Coefficient');
title('Best curve found (smoothest and lowest)');
legend('Location', 'best', 'Interpreter', 'none');
