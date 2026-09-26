% Figure8_bias_correction.m
% Script to generate Figure 8 from saved bias-correction results.

%
% USAGE: From the project root, run('figures/Figure-8/code/Figure8_bias_correction.m').

close all; clear; clc;

scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(fileparts(scriptDir)));
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    projectRoot = pwd;
end
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    error('Project root could not be resolved. Set the MATLAB current folder to the project root and run the script again.');
end

% --------------------------
% Load data
% --------------------------
load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'data_split.mat'), 'Ytest');
load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'pls_model.mat'), 'Iy', 'yhat_test');
load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'gp_model_results.mat'), 'E_e_test_hat_all');
load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'bias_correction_results.mat'), ...
    'idx_on_grid', 'idx_off_grid', ...
    'MSE_on_grid', 'MSE_off_grid', 'MSE_on_grid_corr', 'MSE_off_grid_corr', ...
    'MSE_summary', 'resultsTable');

% --------------------------
% Generate Figure 8
% --------------------------
figureWidthMm = 180;
figureHeightMm = 145;
fig = figure('Color', 'w', ...
    'Units', 'inches', ...
    'Position', [0 0 figureWidthMm/25.4 figureHeightMm/25.4]);

orange = [0.8500 0.3250 0.0980];
green = [0.4660 0.6740 0.1880];
predictionLimits = [-0.01 0.16];

% Panel A: original predictions.
ax1 = subplot(2, 2, 1);
plot(ax1, Ytest(idx_on_grid, Iy), yhat_test(idx_on_grid), 'o', ...
    'LineStyle', 'none', 'MarkerSize', 5, ...
    'Color', orange, 'LineWidth', 1.2);
hold(ax1, 'on')
plot(ax1, Ytest(idx_off_grid, Iy), yhat_test(idx_off_grid), 'p', ...
    'LineStyle', 'none', 'MarkerSize', 7, ...
    'MarkerEdgeColor', green, 'MarkerFaceColor', green, 'LineWidth', 1.0);
set(ax1, 'XLim', predictionLimits, 'YLim', predictionLimits)
axis(ax1, 'square')
grid(ax1, 'on')
xtickformat(ax1, '%.2f')
ytickformat(ax1, '%.2f')
xlabel(ax1, {'{\ity} [w/w]', '(Reference analyte concentration)'}, ...
    'Interpreter', 'tex', 'FontName', 'Arial', 'FontSize', 8, ...
    'FontWeight', 'normal')
ylabel(ax1, 'PLS prediction [w/w]', ...
    'Interpreter', 'none', 'FontName', 'Arial', 'FontSize', 8, ...
    'FontWeight', 'normal')
hEquality1 = refline(ax1, 1, 0);
set(hEquality1, 'Color', 'k', 'LineWidth', 1)
text(ax1, -0.16, 1.08, 'A', 'Units', 'normalized', ...
    'FontName', 'Arial', 'FontSize', 18, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom')

% Panel B: Gaussian-process-corrected predictions.
ax2 = subplot(2, 2, 2);
hOn = plot(ax2, Ytest(idx_on_grid, Iy), ...
    yhat_test(idx_on_grid) + E_e_test_hat_all(idx_on_grid), 'o', ...
    'LineStyle', 'none', 'MarkerSize', 5, ...
    'Color', orange, 'LineWidth', 1.2);
hold(ax2, 'on')
hOff = plot(ax2, Ytest(idx_off_grid, Iy), ...
    yhat_test(idx_off_grid) + E_e_test_hat_all(idx_off_grid), 'p', ...
    'LineStyle', 'none', 'MarkerSize', 7, ...
    'MarkerEdgeColor', green, 'MarkerFaceColor', green, 'LineWidth', 1.0);
set(ax2, 'XLim', predictionLimits, 'YLim', predictionLimits)
axis(ax2, 'square')
grid(ax2, 'on')
xtickformat(ax2, '%.2f')
ytickformat(ax2, '%.2f')
xlabel(ax2, {'{\ity} [w/w]', '(Reference analyte concentration)'}, ...
    'Interpreter', 'tex', 'FontName', 'Arial', 'FontSize', 8, ...
    'FontWeight', 'normal')
ylabel(ax2, 'GP-corrected prediction [w/w]', ...
    'Interpreter', 'none', 'FontName', 'Arial', 'FontSize', 8, ...
    'FontWeight', 'normal')
hEquality2 = refline(ax2, 1, 0);
set(hEquality2, 'Color', 'k', 'LineWidth', 1)
text(ax2, -0.16, 1.08, 'B', 'Units', 'normalized', ...
    'FontName', 'Arial', 'FontSize', 18, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom')

ax2Position = get(ax2, 'Position');
legend(ax2, [hOn hOff], ...
    {'On-the-grid test observations', 'Off-the-grid test observations'}, ...
    'Location', 'northoutside', 'FontName', 'Arial', 'FontSize', 8, ...
    'FontWeight', 'normal', 'Box', 'off');
set(ax2, 'Position', ax2Position)

% Panel 3+4: MSE before and after correction (single subplot with 4 bars)
ax3 = subplot(2, 2, [3 4]);
hold(ax3, 'on')

% Bar values: [on-grid PLS, on-grid corrected, off-grid PLS, off-grid corrected]
mseVec = [MSE_on_grid, MSE_on_grid_corr, MSE_off_grid, MSE_off_grid_corr];
b = bar(ax3, 1:4, mseVec, ...
    'FaceColor', 'flat', 'EdgeColor', 'k', 'LineWidth', 0.75);

% Color bars: first two orange, last two green.
for i = 1:4
    if i <= 2
        b.CData(i,:) = orange;
    else
        b.CData(i,:) = green;
    end
end

% Get the true bar centres.
xtPos = b.XEndPoints;

% Remove the default x-ticks so only custom labels appear.
ax3.XTick = [];

% Prepare the stacked labels for each bar.
labels = { ...
    {'PLS'}, ...
    {'PLS with', 'GP correction'}, ...
    {'PLS'}, ...
    {'PLS with', 'GP correction'} ...
};

ylim(ax3, [0 max(mseVec)*1.2])
yl = ax3.YLim;
yPos = yl(1) - 0.08*diff(yl);

% Draw each label centred under its bar.
for k = 1:numel(xtPos)
    text(ax3, xtPos(k), yPos, labels{k}, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'top', ...
        'Rotation', 45, ...
        'Interpreter', 'none', ...
        'FontName', 'Arial', ...
        'FontSize', 8, ...
        'FontWeight', 'normal', ...
        'Clipping', 'off');
end

ylabel(ax3, 'Mean squared error [(w/w)^2]', ...
    'FontName', 'Arial', 'FontSize', 8, 'FontWeight', 'normal')
grid(ax3, 'on')
box(ax3, 'on')
text(ax3, -0.08, 1.08, 'C', 'Units', 'normalized', ...
    'FontName', 'Arial', 'FontSize', 18, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom')

% Legend.
p1 = patch(ax3, nan, nan, orange, 'EdgeColor', 'none');
p2 = patch(ax3, nan, nan, green, 'EdgeColor', 'none');
legend(ax3, [p1 p2], {'On-the-grid', 'Off-the-grid'}, ...
    'Location', 'northeast', 'FontName', 'Arial', 'FontSize', 8, ...
    'FontWeight', 'normal', 'Box', 'off');

% Adjust the lower panel position to accommodate the rotated labels.
pos = ax3.Position;
ax3.Position = [pos(1), pos(2)+0.05, pos(3), pos(4)-0.05];

set([ax1 ax2 ax3], ...
    'FontName', 'Arial', ...
    'FontSize', 8, ...
    'FontWeight', 'normal', ...
    'LineWidth', 0.75, ...
    'Box', 'on')

drawnow
set(fig, 'PaperPositionMode', 'auto')

% Export figure.
outdir = fullfile(projectRoot, 'figures', 'Figure-8', 'raw_figure');
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
outputFile = fullfile(outdir, 'Figure8_BiasCorrection_raw.svg');
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

disp('--- MSE summary (before/after bias correction) ---');
disp(MSE_summary);
disp('--- Statistical tests on squared errors ---');
disp(resultsTable);
