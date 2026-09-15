% Consultant: Visualization of dielectric data with external legend
% Goal: Clear comparison of tissue contrast for the thesis

clear; clc; close all;

%% 1. Interactive file selection
[files, path] = uigetfile('*.txt', 'Select tissue data files', 'MultiSelect', 'on');
if isequal(files, 0), return; end
if ischar(files), files = {files}; end

colors = lines(length(files));

%% 2. WINDOW 1: Relative permittivity (epsilon_r)
figure('Name', 'Permittivity analysis', 'NumberTitle', 'off', 'Position', [100, 200, 950, 500]);
hold on; grid on; box on;

for i = 1:length(files)
    data = readmatrix(fullfile(path, files{i}));
    f_ghz = data(:,1) / 1e9;
    eps_r = data(:,2);
    [~, name, ~] = fileparts(files{i});
    plot(f_ghz, eps_r, 'LineWidth', 2, 'Color', colors(i,:), 'DisplayName', name);
end

%title('Frequency dependence of relative permittivity \epsilon_r');
xlabel('Frequency [GHz]'); ylabel('Relative permittivity [-]');

% KEY CHANGE: Legend placed outside the plot, top right
legend('Location', 'northeastoutside');
set(gca, 'FontSize', 11);

%% 3. WINDOW 2: Electrical conductivity (sigma)
figure('Name', 'Conductivity analysis', 'NumberTitle', 'off', 'Position', [100, 300, 950, 500]);
hold on; grid on; box on;

for i = 1:length(files)
    data = readmatrix(fullfile(path, files{i}));
    f_ghz = data(:,1) / 1e9;
    sigma = data(:,3);
    [~, name, ~] = fileparts(files{i});
    plot(f_ghz, sigma, 'LineWidth', 2, 'Color', colors(i,:), 'DisplayName', name);
end

%title('Frequency dependence of electrical conductivity \sigma');
xlabel('Frequency [GHz]'); ylabel('Electrical conductivity [S/m]');

% KEY CHANGE: Legend placed outside the plot, top right
legend('Location', 'northeastoutside');
set(gca, 'FontSize', 11);
