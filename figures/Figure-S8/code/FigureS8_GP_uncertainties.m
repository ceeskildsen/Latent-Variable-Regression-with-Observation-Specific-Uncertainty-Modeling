% FigureS8_GP_uncertainties.m
% Supplementary Figure 8: Bias correction results (QSAR)
%   A) Test set predictions (PLS vs bias-corrected)
%   B) MSE comparison
%
% USAGE: From the project root, run('figures/Figure-S8/code/FigureS8_GP_uncertainties.m').

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
    'bias_correction_results_AqSolDB.mat'), ...
    'ytest', 'yhat_test', 'yhat_test_corr', 'MSE_pls', 'MSE_corr');

% -------------------------
% Colors
% -------------------------
col_pls  = [0.2 0.4 0.8];   % PLS / OLS
col_corr = [0.9 0.1 0.9];   % GP bias-corrected
alphaVal = 0.28;

% -------------------------
% Layout
% -------------------------
fig = figure('Color', 'w', 'Units', 'centimeters', ...
    'Position', [2, 2, 18.0, 9.0], ...
    'PaperUnits', 'centimeters', 'PaperSize', [18.0, 9.0], ...
    'PaperPosition', [0, 0, 18.0, 9.0], 'Renderer', 'painters');

% -------------------------
% Panel A: scatter
% -------------------------
ax1 = axes(fig, 'Units', 'centimeters', 'Position', [1.65, 1.45, 5.75, 5.75]);
hold(ax1, 'on');

hPls = scatter(ax1, ytest, yhat_test, 9, col_pls, ...
    'filled', 'MarkerFaceAlpha', alphaVal, 'MarkerEdgeAlpha', alphaVal, ...
    'DisplayName', 'PLS predictions');
hCorr = scatter(ax1, ytest, yhat_test_corr, 9, col_corr, ...
    'filled', 'MarkerFaceAlpha', alphaVal, 'MarkerEdgeAlpha', alphaVal, ...
    'DisplayName', 'Bias-corrected predictions');

allValues = [ytest; yhat_test; yhat_test_corr];
padding = 0.05 * range(allValues);
axmin = min(allValues) - padding;
axmax = max(allValues) + padding;
plot(ax1, [axmin, axmax], [axmin, axmax], 'k', 'LineWidth', 1.0);
xlim(ax1, [axmin, axmax]);
ylim(ax1, [axmin, axmax]);
axis(ax1, 'square');
xlabel(ax1, {'{\rm log}_{10}({\it y}) [mol L^{-1}]', '(Reference value)'}, ...
    'FontName', 'Arial', 'FontSize', 9, 'Interpreter', 'tex');
ylabel(ax1, {'{\rm log}_{10}({\it ŷ}) [mol L^{-1}]', '(Prediction)'}, ...
    'FontName', 'Arial', 'FontSize', 9, 'Interpreter', 'tex');
ax1Position = get(ax1, 'Position');
legend(ax1, [hPls, hCorr], 'Location', 'southeast', ...
    'FontName', 'Arial', 'FontSize', 8, 'FontWeight', 'normal', ...
    'Interpreter', 'none', 'Box', 'on');
set(ax1, 'Position', ax1Position);
grid(ax1, 'on');
box(ax1, 'on');
hold(ax1, 'off');

% -------------------------
% Panel B: MSE bar chart
% -------------------------
ax2 = axes(fig, 'Units', 'centimeters', 'Position', [10.40, 1.45, 5.75, 5.75]);

b_h = bar(ax2, [MSE_pls, MSE_corr]);
b_h.FaceColor = 'flat';
b_h.CData     = [col_pls; col_corr];
b_h.FaceAlpha = 0.8;
b_h.EdgeColor = 'none';

axis(ax2, 'square');
grid(ax2, 'on');
box(ax2, 'on');
ylabel(ax2, 'Mean squared error (test set)', ...
    'FontName', 'Arial', 'FontSize', 9, 'Interpreter', 'none');
set(ax2, 'XLim', [0.5, 2.5], 'YLim', [0, 2.3], ...
    'XTick', [1, 2], ...
    'XTickLabel', {'PLS', 'GP-corrected PLS'}, ...
    'XTickLabelRotation', 0);
ytickformat(ax2, '%.1f');

for ax = [ax1, ax2]
    set(ax, 'FontName', 'Arial', 'FontSize', 8, 'LineWidth', 0.75, ...
        'FontWeight', 'normal', 'TickDir', 'in', 'GridAlpha', 0.18);
end

text(ax1, -0.20, 1.12, 'A', 'Units', 'normalized', 'Clipping', 'off', ...
    'FontName', 'Arial', 'FontSize', 18, 'FontWeight', 'bold');
text(ax2, -0.20, 1.12, 'B', 'Units', 'normalized', 'Clipping', 'off', ...
    'FontName', 'Arial', 'FontSize', 18, 'FontWeight', 'bold');
%%
% -------------------------
% Save
% -------------------------
outdir = fullfile(projectRoot, 'figures', 'Figure-S8', 'raw_figure');
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
svgFile = fullfile(outdir, 'FigureSI8_GPuncertainties.svg');
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
