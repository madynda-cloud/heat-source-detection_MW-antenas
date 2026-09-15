% Analysis of MUS_T44 phantom measurements directly from Excel
clear all; clc; close all;

% --- CONFIGURATION ---
filename = 'Dynda_mereni_vodivost_a_permi_fantom_MUS_T44_12_5_2026.xlsx';
num_buffers = 10;
% Data starts at row 10 (skipping the header with probe parameters)
data_range = 'A10';

% Initialize arrays to collect data
all_eps = [];
all_sigma = [];
freq = [];

% --- 1. LOAD DATA FROM SHEETS ---
fprintf('Loading data from Excel file: %s\n', filename);

for i = 1:num_buffers
    sheet_name = sprintf('Buffer %d', i);

    % Load the specific sheet
    % Columns: A=Freq, B=Eps', C=Eps'', D=Sigma
    opts = detectImportOptions(filename, 'Sheet', sheet_name);
    opts.DataLines = 10;
    opts.VariableNamingRule = 'preserve';

    data = readtable(filename, opts, 'Sheet', sheet_name);

    % Store the frequency axis (only need it from the first run, assuming the same grid)
    if i == 1
        freq = data{:, 1};
    end

    % Extract column B (2) for permittivity and D (4) for conductivity
    all_eps(:, i) = data{:, 2};
    all_sigma(:, i) = data{:, 4};
end

% --- 2. UNCERTAINTY CALCULATION (Type A, B, C) ---

% Type A: Statistical uncertainty from the measurements (standard deviation of the mean)
mean_eps = mean(all_eps, 2);
u_A_eps = std(all_eps, 0, 2);

mean_sigma = mean(all_sigma, 2);
u_A_sigma = std(all_sigma, 0, 2);

% Type B: Systematic uncertainty of the DAK-3.5 probe (per datasheet, k=2 -> divided by 2)
% Permittivity: 2.3% up to 3 GHz, 3.5% above 3 GHz
u_B_eps = zeros(size(freq));
mask_low = freq <= 3000;
mask_high = freq > 3000;
u_B_eps(mask_low) = (0.023 / 2) * mean_eps(mask_low);
u_B_eps(mask_high) = (0.035 / 2) * mean_eps(mask_high);

% Conductivity: 2.4% (k=2) -> 1.2% (k=1)
u_B_sigma = (0.024 / 2) * mean_sigma;

% Type C: Combined uncertainty (k=2 for the final plot)
u_C_eps = sqrt(u_A_eps.^2 + u_B_eps.^2);
u_C_sigma = sqrt(u_A_sigma.^2 + u_B_sigma.^2);

% --- 3. PLOTTING ---
figure('Color', 'w', 'Name', 'MUS_T44 Phantom Analysis', 'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.4]);

% Permittivity plot
subplot(1, 2, 1);
hold on; grid on;
% Gray lines for all measured buffers
plot(freq, all_eps, 'Color', [0.85 0.85 0.85], 'HandleVisibility', 'off');
% Type C uncertainty band (k=2)
fill([freq; flipud(freq)], [mean_eps - 2*u_C_eps; flipud(mean_eps + 2*u_C_eps)], ...
     'b', 'FaceAlpha', 0.15, 'EdgeColor', 'none', 'DisplayName', 'Type C uncertainty (k=2)');
% Mean curve
plot(freq, mean_eps, 'b', 'LineWidth', 2, 'DisplayName', 'Mean \epsilon''');
title('Real part of permittivity \epsilon''');
xlabel('f [MHz]'); ylabel('\epsilon'' [-]');
legend('Location', 'northeast');

% Conductivity plot
subplot(1, 2, 2);
hold on; grid on;
% Gray lines for all measured buffers
plot(freq, all_sigma, 'Color', [0.85 0.85 0.85], 'HandleVisibility', 'off');
% Type C uncertainty band (k=2)
fill([freq; flipud(freq)], [mean_sigma - 2*u_C_sigma; flipud(mean_sigma + 2*u_C_sigma)], ...
     'r', 'FaceAlpha', 0.15, 'EdgeColor', 'none', 'DisplayName', 'Type C uncertainty (k=2)');
% Mean curve
plot(freq, mean_sigma, 'r', 'LineWidth', 2, 'DisplayName', 'Mean \sigma');
title('Electrical conductivity \sigma');
xlabel('f [MHz]'); ylabel('\sigma [S/m]');
legend('Location', 'northwest');

fprintf('Processing complete. Plotted %d buffers.\n', num_buffers);
