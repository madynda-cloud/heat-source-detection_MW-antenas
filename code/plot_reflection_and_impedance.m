clear all; close all;

%% 1. File selection
[files, path] = uigetfile('*.csv', 'Select CSV files (Reflection and Impedance)', 'MultiSelect', 'on');
if isequal(files, 0)
    disp('User cancelled the selection.');
    return;
end

if ischar(files)
    files = {files}; % Ensure a single file is also processed as a list
end

%% 2. Prepare TWO separate windows
% First window for the reflection coefficient
fig1 = figure('Color', 'w', 'Name', 'Reflection coefficient', 'Position', [100, 300, 700, 450]);
ax1 = axes(fig1);
hold(ax1, 'on'); grid(ax1, 'on');
xlabel(ax1, 'Frequency');
ylabel(ax1, 'Abs Reflection Coefficient');
title(ax1, 'Reflection Coefficient');

% Second window for impedance
fig2 = figure('Color', 'w', 'Name', 'Impedance', 'Position', [850, 300, 700, 450]);
ax2 = axes(fig2);
hold(ax2, 'on'); grid(ax2, 'on');
xlabel(ax2, 'Frequency');
ylabel(ax2, 'Abs Impedance [\Omega]');
title(ax2, 'Input Impedance');

colors = lines(20); % Color palette
count_ref = 0; % Counter for reflection curves
count_imp = 0; % Counter for impedance curves

fprintf('\n--- LOADING AND PLOTTING DATA ---\n');

%% 3. Loading and automatic sorting of data
for f_idx = 1:length(files)
    currentFile = files{f_idx};
    fullPath = fullfile(path, currentFile);
    [~, fileName, ~] = fileparts(currentFile);

    try
        T_headers = readcell(fullPath, 'Range', '1:1');
        dataMatrix = readmatrix(fullPath);
        numCols = size(dataMatrix, 2);

        for c = 1:2:numCols
            if c+1 <= numCols
                freq = dataMatrix(:, c);
                val  = dataMatrix(:, c+1);
                mask = ~isnan(freq) & ~isnan(val);

                if any(mask)
                    % Get the name from the header
                    if c <= length(T_headers) && (ischar(T_headers{c}) || isstring(T_headers{c}))
                        origName = char(T_headers{c});

                        % Extract the text inside brackets
                        tokens = regexp(origName, '\[(.*?)\]', 'tokens');
                        if ~isempty(tokens)
                            paramName = tokens{1}{1};
                        else
                            paramName = origName;
                        end
                    else
                        origName = '';
                        paramName = sprintf('Curve %d', (c+1)/2);
                    end

                    legendName = sprintf('[%s] %s', strrep(fileName, '_', ' '), paramName);

                    % SORT INTO SEPARATE WINDOWS
                    if contains(lower(origName), 'impedance')
                        count_imp = count_imp + 1;
                        plot(ax2, freq(mask), val(mask), ...
                             'LineWidth', 1.5, ...
                             'Color', colors(mod(count_imp-1, 20) + 1, :), ...
                             'DisplayName', legendName);
                    else
                        count_ref = count_ref + 1;
                        plot(ax1, freq(mask), val(mask), ...
                             'LineWidth', 1.5, ...
                             'Color', colors(mod(count_ref-1, 20) + 1, :), ...
                             'DisplayName', legendName);
                    end
                end
            end
        end
        fprintf('File %s loaded.\n', currentFile);
    catch ME
        fprintf('Error reading %s: %s\n', currentFile, ME.message);
    end
end

%% 4. Final formatting
% Add legend in the top-left corner ('northwest')
if count_ref > 0
    legend(ax1, 'Location', 'northwest', 'Interpreter', 'none', 'FontSize', 8);
else
    close(fig1); % Close the reflection window if only impedance files were loaded
end

if count_imp > 0
    legend(ax2, 'Location', 'northwest', 'Interpreter', 'none', 'FontSize', 8);
else
    close(fig2); % Close the impedance window if only reflection files were loaded
end

% Link the X axis between the two independent windows
if count_ref > 0 && count_imp > 0
    linkaxes([ax1, ax2], 'x');
end

fprintf('\nDone. Displayed %d reflection curves and %d impedance curves.\n', count_ref, count_imp);
