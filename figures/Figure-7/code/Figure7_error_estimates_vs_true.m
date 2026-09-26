% Figure7_error_estimates_vs_true.m
% Script to compare Gaussian-process estimates with empirical prediction-error statistics
% Generates Figure 7 for the manuscript:
% "Latent Variable Regression with Observation-Specific Uncertainty Modeling"

%
% USAGE: From the project root, run('figures/Figure-7/code/Figure7_error_estimates_vs_true.m').

close all; clear; clc;
scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(fileparts(scriptDir)));
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    projectRoot = pwd;
end
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    error('Project root could not be resolved. Set the MATLAB current folder to the project root and run the script again.');
end


% Load necessary data
load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'data_split.mat'), 'IDcal');
load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'pls_model.mat'), ...
    'E_e_test', 'Var_e_test', 'uIDtest');
load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'gp_model_results.mat'), ...
    'E_e_test_hat', 'Var_ale_test_hat');

% Separate test formulations that are on and off the calibration grid.
Idx_IDcal = ismember(uIDtest, IDcal);
Idx_IDtest = ~Idx_IDcal;

% --------------------------
% Generate Figure 7
% --------------------------
figureWidthMm = 180;
figureHeightMm = 97;
fig = figure('Color', 'w', ...
    'Units', 'inches', ...
    'Position', [0 0 figureWidthMm/25.4 figureHeightMm/25.4]);

orange = [0.8500 0.3250 0.0980];
green = [0.4660 0.6740 0.1880];

% Panel A: expected prediction error.
ax1 = subplot(1, 2, 1);
plot(ax1, E_e_test(Idx_IDcal), E_e_test_hat(Idx_IDcal), 'o', ...
    'LineStyle', 'none', 'MarkerSize', 6, 'Color', orange, 'LineWidth', 1.2);
hold(ax1, 'on')
plot(ax1, E_e_test(Idx_IDtest), E_e_test_hat(Idx_IDtest), 'p', ...
    'LineStyle', 'none', 'MarkerSize', 9, ...
    'MarkerEdgeColor', green, 'MarkerFaceColor', green, 'LineWidth', 1.0);

biasValues = [E_e_test(:); E_e_test_hat(:)];
biasValues = biasValues(isfinite(biasValues));
biasRange = max(biasValues) - min(biasValues);
if biasRange == 0
    biasRange = max(abs(biasValues));
end
if biasRange == 0
    biasRange = 1;
end
biasLimits = [min(biasValues), max(biasValues)] + 0.05*biasRange*[-1 1];
set(ax1, 'XLim', biasLimits, 'YLim', biasLimits)
axis(ax1, 'square')
grid(ax1, 'on')
hEquality1 = refline(ax1, 1, 0);
set(hEquality1, 'Color', 'k', 'LineWidth', 1)
xlabel(ax1, {'Empirical estimate of', 'expected prediction error [w/w]'}, ...
    'FontName', 'Arial', 'FontSize', 8, 'FontWeight', 'normal')
ylabel(ax1, {'Gaussian-process estimate of', 'expected prediction error [w/w]'}, ...
    'FontName', 'Arial', 'FontSize', 8, 'FontWeight', 'normal')
text(ax1, -0.12, 1.06, 'A', 'Units', 'normalized', ...
    'FontName', 'Arial', 'FontSize', 18, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom')

% Panel B: aleatoric prediction-error variance.
ax2 = subplot(1, 2, 2);
hOn = plot(ax2, Var_e_test(Idx_IDcal), Var_ale_test_hat(Idx_IDcal), 'o', ...
    'LineStyle', 'none', 'MarkerSize', 6, 'Color', orange, 'LineWidth', 1.2);
hold(ax2, 'on')
hOff = plot(ax2, Var_e_test(Idx_IDtest), Var_ale_test_hat(Idx_IDtest), 'p', ...
    'LineStyle', 'none', 'MarkerSize', 9, ...
    'MarkerEdgeColor', green, 'MarkerFaceColor', green, 'LineWidth', 1.0);

varianceValues = [Var_e_test(:); Var_ale_test_hat(:)];
varianceValues = varianceValues(isfinite(varianceValues));
varianceRange = max(varianceValues) - min(varianceValues);
if varianceRange == 0
    varianceRange = max(abs(varianceValues));
end
if varianceRange == 0
    varianceRange = 1;
end
varianceLimits = [min(varianceValues), max(varianceValues)] + 0.05*varianceRange*[-1 1];
set(ax2, 'XLim', varianceLimits, 'YLim', varianceLimits)
axis(ax2, 'square')
grid(ax2, 'on')
hEquality2 = refline(ax2, 1, 0);
set(hEquality2, 'Color', 'k', 'LineWidth', 1)
xtickformat(ax2, '%.1f')
ytickformat(ax2, '%.1f')
xlabel(ax2, {'Empirical estimate of', 'prediction-error variance [(w/w)^2]'}, ...
    'FontName', 'Arial', 'FontSize', 8, 'FontWeight', 'normal')
ylabel(ax2, {'Gaussian-process estimate of', 'aleatoric variance [(w/w)^2]'}, ...
    'FontName', 'Arial', 'FontSize', 8, 'FontWeight', 'normal')
text(ax2, -0.12, 1.06, 'B', 'Units', 'normalized', ...
    'FontName', 'Arial', 'FontSize', 18, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom')

set([ax1 ax2], 'FontName', 'Arial', 'FontSize', 8, 'FontWeight', 'normal', ...
    'LineWidth', 0.75, 'Box', 'on')

ax2Position = get(ax2, 'Position');
legend(ax2, [hOn hOff], ...
    {'On-the-grid test samples', 'Off-the-grid test samples'}, ...
    'Location', 'northoutside', 'FontName', 'Arial', 'FontSize', 8, ...
    'FontWeight', 'normal', 'Box', 'off');
set(ax2, 'Position', ax2Position)

drawnow
set(fig, 'PaperPositionMode', 'auto')

% Export figure.
outdir = fullfile(projectRoot, 'figures', 'Figure-7', 'raw_figure');
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
outputFile = fullfile(outdir, 'Figure7_Estimated_vs_True_Uncertainty_raw.svg');
print(fig, outputFile, '-dsvg', '-painters');

% MATLAB writes SVG dimensions as unitless pixel values. Preserve those
% internal dimensions in a viewBox while assigning the intended physical
% dimensions, so that Inkscape scales the complete drawing onto the page.
svgText = fileread(outputFile);
svgDimensions = regexp(svgText, ...
    '<svg([^>]*)width="([0-9.]+)"([^>]*)height="([0-9.]+)"', ...
    'tokens', 'once');
if isempty(svgDimensions)
    error('Could not identify the SVG canvas dimensions in %s.', outputFile)
end
svgWidthUnits = str2double(svgDimensions{2});
svgHeightUnits = str2double(svgDimensions{4});
svgText = regexprep(svgText, ...
    '<svg([^>]*)width="[^"]+"([^>]*)height="[^"]+"', ...
    sprintf(['<svg$1width="%.3fmm"$2height="%.3fmm" ' ...
    'viewBox="0 0 %.15g %.15g"'], ...
    figureWidthMm, figureHeightMm, svgWidthUnits, svgHeightUnits), 'once');
fid = fopen(outputFile, 'w');
fwrite(fid, svgText, 'char');
fclose(fid);
