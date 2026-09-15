%%
close all; clear all;

%% 1. File selection and loading
[file, path] = uigetfile('*.csv', 'Select the file with simulations');
if isequal(file, 0), return; end
fullPath = fullfile(path, file);

% Print the loaded file name
fprintf('Selected file: %s\n', file);

% Read headers as cells (text)
opts_h = detectImportOptions(fullPath);
opts_h.VariableNamingRule = 'preserve';
T_headers = readcell(fullPath, 'Range', '1:1');

% Read the data as a plain numeric matrix
dataMatrix = readmatrix(fullPath);

% Initialization
simData = struct();
count = 0;

%% 2. Parsing parameters and data
numCols = size(dataMatrix, 2);
for i = 1:2:numCols
    currentHeader = char(T_headers{i});

    % Instead of searching for plain numbers, extract everything between square brackets [...]
    % E.g. finds: "Iteration=5, Balun_offset=3.33, offset=0"
    tokens = regexp(currentHeader, '\[(.*?)\]', 'tokens');

    if ~isempty(tokens)
        count = count + 1;

        % Store the whole parameter text
        simData(count).ParamString = tokens{1}{1};

        f = dataMatrix(:, i);
        v = dataMatrix(:, i+1);
        mask = ~isnan(f) & ~isnan(v);
        simData(count).Freq = f(mask);
        simData(count).Value = v(mask);
    end
end
fprintf('Successfully loaded %d simulations.\n', count);

%% 3. Visualization - each simulation in a separate window
if count > 0
    % NOTE: this will open a large number of windows
    for k = 1:length(simData)

        % Create a new window - use our extracted text as the window name
        figure('Color', 'w', 'Name', simData(k).ParamString);
        hold on; grid on;

        % Plot the specific curve
        plot(simData(k).Freq, simData(k).Value, ...
            'LineWidth', 2, ...
            'Color', [0 0.4470 0.7410]); % Standard blue

        % Labels and formatting
        xlabel('Frequency [GHz]');
        ylabel('Abs Reflection Coefficient');

        % Use the text extracted from the CSV header as the plot title
        % 'Interpreter', 'none' prevents MATLAB from turning underscores into subscripts
        title(simData(k).ParamString, 'Interpreter', 'none');

    end
    fprintf('Displayed %d separate windows.\n', count);
else
    disp('No data found.');
end
