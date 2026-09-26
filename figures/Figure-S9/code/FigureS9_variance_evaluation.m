% FigureS9_variance_evaluation.m
% Supplementary Figure 9: Evaluation of GP vs OLS variance estimates
%   A) Calibration plot (reliability diagram)
%   B) Variance estimate distributions (GP top, OLS bottom — stacked)
%
%
% USAGE: From the project root, run('figures/Figure-S9/code/FigureS9_variance_evaluation.m').

clear; close all; clc;
scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(fileparts(scriptDir)));
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    projectRoot = pwd;
end
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    error('Project root could not be resolved. Set the MATLAB current folder to the project root and run the script again.');
end

load(fullfile(projectRoot, 'data', 'AqSolDB', 'analysis_data', ...
    'uncertainty_evaluation_results_AqSolDB.mat'), ...
    'nominal_levels', 'empirical_GP', 'empirical_OLS', ...
    'Var_total_test_hat', 'Var_e_test_OLS');

% --------------------------
% Colors (consistent with S Fig 8)
% --------------------------
col_gp  = [0.9 0.1 0.9];   % GP (magenta)
col_ols = [0.2 0.4 0.8];   % OLS (blue)

% ================================================================
% Figure layout
% ================================================================
fig = figure('Color', 'w', 'Units', 'centimeters', ...
    'Position', [2, 2, 18.0, 9.0], ...
    'PaperUnits', 'centimeters', 'PaperSize', [18.0, 9.0], ...
    'PaperPosition', [0, 0, 18.0, 9.0], 'Renderer', 'painters');

% ================================================================
% Panel A: Calibration plot
% ================================================================
ax1 = axes(fig, 'Units', 'centimeters', 'Position', [1.65, 1.45, 5.75, 5.75]);
hold(ax1, 'on');

hGP = plot(ax1, nominal_levels, empirical_GP, 'o-', 'Color', col_gp, ...
    'MarkerFaceColor', col_gp, 'LineWidth', 1.5, ...
    'MarkerSize', 5, 'DisplayName', 'GP');
hOLS = plot(ax1, nominal_levels, empirical_OLS, 's-', 'Color', col_ols, ...
    'MarkerFaceColor', col_ols, 'LineWidth', 1.5, ...
    'MarkerSize', 5, 'DisplayName', 'OLS');
hPerfect = plot(ax1, [0, 1], [0, 1], 'k--', 'LineWidth', 1.0, ...
    'DisplayName', 'Perfect calibration');
hold(ax1, 'off');

xlabel(ax1, 'Nominal coverage', ...
    'FontName', 'Arial', 'FontSize', 9, 'Interpreter', 'none');
ylabel(ax1, 'Empirical coverage', ...
    'FontName', 'Arial', 'FontSize', 9, 'Interpreter', 'none');
axis(ax1, 'square');
grid(ax1, 'on');
box(ax1, 'on');
xlim(ax1, [0, 1]);
ylim(ax1, [0, 1]);
set(ax1, 'XTick', 0:0.2:1, 'YTick', 0:0.2:1);
xtickformat(ax1, '%.1f');
ytickformat(ax1, '%.1f');

ax1Position = get(ax1, 'Position');
legend(ax1, [hGP, hOLS, hPerfect], ...
    {'GP', 'OLS', 'Nominal = Empirical'}, ...
    'Location', 'southeast', 'FontName', 'Arial', 'FontSize', 8, ...
    'FontWeight', 'normal', 'Interpreter', 'none', 'Box', 'on');
set(ax1, 'Position', ax1Position);
% ================================================================
% Panel B (top): GP variance distribution — own x-axis
% ================================================================
ax_top = axes(fig, 'Units', 'centimeters', 'Position', [10.40, 4.70, 5.75, 2.50]);

histogram(ax_top, Var_total_test_hat, 50, ...
    'FaceColor', col_gp, 'FaceAlpha', 0.8, 'EdgeColor', 'none');
grid(ax_top, 'on');
box(ax_top, 'on');

text(ax_top, 0.95, 0.82, 'GP', 'Units', 'normalized', ...
    'HorizontalAlignment', 'right', 'FontWeight', 'bold', ...
    'Color', col_gp, 'FontName', 'Arial', 'FontSize', 9);

% ================================================================
% Panel B (bottom): OLS variance distribution — own x-axis
% ================================================================
ax_bot = axes(fig, 'Units', 'centimeters', 'Position', [10.40, 1.45, 5.75, 2.50]);

histogram(ax_bot, Var_e_test_OLS, 50, ...
    'FaceColor', col_ols, 'FaceAlpha', 0.8, 'EdgeColor', 'none');
grid(ax_bot, 'on');
box(ax_bot, 'on');
xlabel(ax_bot, 'Prediction-error variance', ...
    'FontName', 'Arial', 'FontSize', 9, 'Interpreter', 'none');

text(ax_bot, 0.95, 0.82, 'OLS', 'Units', 'normalized', ...
    'HorizontalAlignment', 'right', 'FontWeight', 'bold', ...
    'Color', col_ols, 'FontName', 'Arial', 'FontSize', 9);

set(ax_bot, 'XLim', [1.95, 2.00], 'YTick', [0, 200, 400]);
xtickformat(ax_bot, '%.2f');

for ax = [ax1, ax_top, ax_bot]
    set(ax, 'FontName', 'Arial', 'FontSize', 8, 'LineWidth', 0.75, ...
        'FontWeight', 'normal', 'TickDir', 'in', 'GridAlpha', 0.18);
end

drawnow;
figPosition = get(fig, 'Position');
topPosition = get(ax_top, 'Position');
botPosition = get(ax_bot, 'Position');
topLimits = xlim(ax_top);
botLimits = xlim(ax_bot);

xTopLeft = (topPosition(1) + ...
    (botLimits(1) - topLimits(1)) / diff(topLimits) * topPosition(3)) / figPosition(3);
xTopRight = (topPosition(1) + ...
    (botLimits(2) - topLimits(1)) / diff(topLimits) * topPosition(3)) / figPosition(3);
xBotLeft = botPosition(1) / figPosition(3);
xBotRight = (botPosition(1) + botPosition(3)) / figPosition(3);
yTop = topPosition(2) / figPosition(4);
yBot = (botPosition(2) + botPosition(4)) / figPosition(4);

annotation(fig, 'line', [xTopLeft, xBotLeft], [yTop, yBot], ...
    'LineStyle', '--', 'LineWidth', 0.75, 'Color', [0.45, 0.45, 0.45]);
annotation(fig, 'line', [xTopRight, xBotRight], [yTop, yBot], ...
    'LineStyle', '--', 'LineWidth', 0.75, 'Color', [0.45, 0.45, 0.45]);

text(ax_top, -0.16, -0.15, 'Count', 'Units', 'normalized', ...
    'Rotation', 90, 'Clipping', 'off', ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
    'FontName', 'Arial', 'FontSize', 9, 'FontWeight', 'normal');

text(ax1, -0.20, 1.12, 'A', 'Units', 'normalized', 'Clipping', 'off', ...
    'FontName', 'Arial', 'FontSize', 18, 'FontWeight', 'bold');
text(ax_top, -0.20, 1.28, 'B', 'Units', 'normalized', 'Clipping', 'off', ...
    'FontName', 'Arial', 'FontSize', 18, 'FontWeight', 'bold');
% ================================================================
% Save figure
% ================================================================
%%
outdir = fullfile(projectRoot, 'figures', 'Figure-S9', 'raw_figure');
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
svgFile = fullfile(outdir, 'FigureSI9_variance_evaluation.svg');
print(fig, svgFile, '-dsvg', '-r1200');

set_svg_physical_size(svgFile, 18.0, 9.0);

function set_svg_physical_size(svgFile, widthCm, heightCm)
svgText = fileread(svgFile);
tokens = regexp(svgText, 'width="([0-9.]+)" height="([0-9.]+)"', 'tokens', 'once');
if isempty(tokens)
    error('Could not identify the SVG canvas dimensions in %s.', svgFile);
end
replacement = sprintf('width="%gcm" height="%gcm" viewBox="0 0 %s %s"', ...
    widthCm, heightCm, tokens{1}, tokens{2});
svgText = regexprep(svgText, 'width="[0-9.]+" height="[0-9.]+"', replacement, 'once');
fileID = fopen(svgFile, 'w');
if fileID == -1
    error('Could not open %s for writing.', svgFile);
end
cleanup = onCleanup(@() fclose(fileID));
fwrite(fileID, svgText, 'char');
end

