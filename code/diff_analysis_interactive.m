%% === DIFFERENTIAL ANALYSIS OF S-PARAMETERS - interactive frequency ===
clear; clc; close all;

%% 1. LOAD DATA
d1 = load('pos4_T37_v2.mat');
d2 = load('pos4_T44_v2.mat');

% Access the data (according to your structure)
S1 = d1.data.measurement.s_mat;
S2 = d2.data.measurement.s_mat;
freq = d1.data.info.freqVect;

nPorts = 8;
nFreq  = length(freq);

%% 2. DIFFERENCE CALCULATION
% Compute the difference in dB
diff_data = 20*log10(abs(S2 - S1));

% Remove the diagonal (S11, S22...) so only transmission terms are shown
for fi = 1:nFreq
    for i = 1:nPorts
        diff_data(i, i, fi) = NaN;
    end
end

%% 3. FIGURE AND PLOT SETUP
fig = figure('Name', 'Interactive difference analysis', 'Color', 'w', 'Position', [100 100 800 600]);

% Create axes for the plot (leave room at the bottom for the slider)
ax = axes('Units', 'pixels', 'Position', [100 100 600 450]);

% Default view (index 1)
i_init = 1;
img = imagesc(diff_data(:,:,i_init));
colormap(jet);
cb = colorbar;
cb.Label.String   = 'S-parameter difference [dB]';
cb.Label.FontSize = 10;
cb.Label.FontWeight = 'bold';
caxis([-100 -20]); % Set the dB range as needed (min max)
title_handle = title(sprintf('S-parameter difference at %.4f GHz', freq(i_init)/1e9));
xlabel('Excitation antenna');
ylabel('Receiving antenna');

%% 4. SLIDER AND CONTROLS
uicontrol('Style', 'text', ...
    'Position', [50 20 120 20], ...
    'String', 'Frequency [GHz]:', 'BackgroundColor', 'w');

freq_label = uicontrol('Style', 'text', ...
    'Position', [530 20 150 20], ...
    'String', sprintf('%.4f GHz', freq(i_init)/1e9), 'BackgroundColor', 'w');

% Slider definition
slider = uicontrol('Style', 'slider', ...
    'Min', 1, 'Max', nFreq, ...
    'Value', i_init, ...
    'SliderStep', [1/(nFreq-1), 10/(nFreq-1)], ...
    'Position', [180 20 340 20]);

% Set the callback (what happens when the slider moves)
slider.Callback = @(src, event) updatePlot(src, freq, diff_data, img, freq_label, title_handle);

%% 5. HELPER FUNCTION (Callback)
function updatePlot(src, freq, diff_data, img_handle, label_handle, title_handle)
    % Get the index from the slider
    idx = round(src.Value);

    % Update the image data
    set(img_handle, 'CData', diff_data(:,:,idx));

    % Update the labels
    current_f = freq(idx) / 1e9;
    set(label_handle, 'String', sprintf('%.4f GHz', current_f));
    set(title_handle, 'String', sprintf('S-parameter difference at %.4f GHz', current_f));
end
