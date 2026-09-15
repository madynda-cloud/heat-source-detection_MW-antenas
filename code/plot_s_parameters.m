close all; clear all;

%% --- Data preparation ---
%load("pos1_T37.mat")
load("pos1_T44.mat")
f     = data.info.freqVect;
S     = data.measurement.s_mat;
f_ghz = f / 1e9;

% Frequency range diagnostics
fprintf('Frequency range: %.4f GHz - %.4f GHz\n', min(f_ghz), max(f_ghz));

num_antennas = 8;
colors       = lines(num_antennas);

% Reference line values - adjust if frequencies are in different units
ref_yline  = -10;    % [dB]
ref_xline1 =  1;     % [GHz]
ref_xline2 =  3;     % [GHz]

%% --- PLOT 1: Reflection coefficients (S11 to S88) ---
figure('Name', 'Reflections_S11_to_S88', 'Color', 'w');
hold on; grid on;

for i = 1:num_antennas
    s_ii = squeeze(S(i, i, :));
    plot(f_ghz, 20*log10(abs(s_ii)), ...
        'LineWidth', 1.5, ...
        'Color',       colors(i, :), ...
        'DisplayName', ['S', num2str(i), num2str(i)]);
end

% Reference lines
yline(ref_yline,  '--k', 'LineWidth', 1.5, 'HandleVisibility', 'off');
%xline(ref_xline1, '--r', 'LineWidth', 1.5, 'HandleVisibility', 'off', 'Label', '');
%xline(ref_xline2, '--r', 'LineWidth', 1.5, 'HandleVisibility', 'off', 'Label', '');

xlabel('Frequency [GHz]');
ylabel('Magnitude [dB]');
legend('show', 'Location', 'northeastoutside');
ylim([-50 5]);

%% --- PLOT 2: MAIN FIGURE: Sij transmission terms ---
fig = figure('Name', 'Transmissions_Sij', 'Color', 'w');
set(fig, 'Units', 'normalized', 'OuterPosition', [0 0 0.55 1]);

top_margin    = 0.03;
bottom_margin = 0.06;
left_margin   = 0.12;
right_margin  = 0.18;
gap           = 0.045;   % larger gap - room for the X axis labels
plot_width    = 1 - left_margin - right_margin;
plot_height   = (1 - top_margin - bottom_margin - gap * (num_antennas - 1)) / num_antennas;

ax_all = gobjects(num_antennas, 1);

for j = 1:num_antennas
    bottom = bottom_margin + (num_antennas - j) * (plot_height + gap);
    ax = axes('Position', [left_margin, bottom, plot_width, plot_height]); %#ok<LAXES>
    ax_all(j) = ax;
    hold(ax, 'on');
    box(ax, 'on');
    grid(ax, 'on');
    ax.FontSize = 7;

    for i = 1:num_antennas
        if i ~= j
            s_ij = squeeze(S(i, j, :));
            plot(ax, f_ghz, 20*log10(abs(s_ij)), ...
                'LineWidth', 1.0, ...
                'Color',     colors(i, :));
        end
    end

    % Reference lines - same values as in plot 1
    yline(ax, ref_yline,  '--k', 'LineWidth', 1.2, 'HandleVisibility', 'off');
    %xline(ax, ref_xline1, '--r', 'LineWidth', 1.2, 'HandleVisibility', 'off', 'Label', '');
    %xline(ax, ref_xline2, '--r', 'LineWidth', 1.2, 'HandleVisibility', 'off', 'Label', '');

    ylabel(ax, ['|S_{i', num2str(j), '}| [dB]'], ...
        'FontSize',            7, ...
        'Rotation',            90, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment',   'bottom');

    ylim(ax, [-100 0]);

     % Numeric X-axis tick labels on all subplots
    set(ax, 'XTickMode', 'auto');
    ax.XTickLabelRotation = 0;

    % Text X-axis label only on the last subplot
    if j == num_antennas
        xlabel(ax, 'Frequency [GHz]', 'FontSize', 8);
    end
end

linkaxes(ax_all, 'x');

% --- Legend on the right ---
legend_handles = gobjects(num_antennas, 1);
legend_labels  = cell(num_antennas, 1);

for i = 1:num_antennas
    legend_handles(i) = plot(ax_all(1), NaN, NaN, ...
        'Color',            colors(i, :), ...
        'LineWidth',        1.5, ...
        'HandleVisibility', 'on');
    legend_labels{i} = ['S_{', num2str(i), 'j}'];
end

lgd = legend(ax_all(1), legend_handles, legend_labels, ...
    'Orientation', 'vertical', ...
    'Units',       'normalized', ...
    'FontSize',    8, ...
    'Box',         'on');

lgd.Position = [1 - right_margin + 0.01, bottom_margin, right_margin - 0.02, 0.4];
