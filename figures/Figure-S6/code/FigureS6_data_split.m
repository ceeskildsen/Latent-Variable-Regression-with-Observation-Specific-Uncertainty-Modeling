% FigureS6_data_split.m
% Script to generate Supplementary Figure 6: AqSolDB data split.
%
% USAGE: From the project root, run('figures/Figure-S6/code/FigureS6_data_split.m').

clear; close all; clc;

scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(fileparts(scriptDir)));
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    projectRoot = pwd;
end
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    error('Project root could not be resolved. Set the MATLAB current folder to the project root and run the script again.');
end

load(fullfile(projectRoot, 'data', 'AqSolDB', 'analysis_data', 'AqSolDB_data_split.mat'), ...
    'Xcal', 'Xval', 'Xtest', 'ycal', 'yval', 'ytest');
load(fullfile(projectRoot, 'data', 'AqSolDB', 'analysis_data', 'pls_model_AqSolDB.mat'), ...
    'idx_cal', 'idx_val', 'idx_test');

Xcal = Xcal(idx_cal, :);
Xval = Xval(idx_val, :);
Xtest = Xtest(idx_test, :);

ycal = ycal(idx_cal);
yval = yval(idx_val);
ytest = ytest(idx_test);

addpath(fullfile(projectRoot, 'code', 'functions'));

mnX = mean(Xcal);
stdX = std(Xcal);

LV = 2;
[Tcal, P, expVar] = nipals_pca((Xcal - mnX) ./ stdX, LV);
Tval = ((Xval - mnX) ./ stdX) * P;
Ttest = ((Xtest - mnX) ./ stdX) * P;

colTest = [0.2 0.4 0.8];
colCal = [0.2 0.7 0.3];
colVal = [0.8 0.4 0.2];

fig = figure('Color', 'w', 'Units', 'centimeters', ...
    'Position', [2, 2, 18.0, 9.0], ...
    'PaperUnits', 'centimeters', 'PaperSize', [18.0, 9.0], ...
    'PaperPosition', [0, 0, 18.0, 9.0], 'Renderer', 'painters');

ax1 = axes(fig, 'Units', 'centimeters', 'Position', [1.65, 1.35, 5.75, 5.75]);
hold(ax1, 'on');
scatter(ax1, Ttest(:, 1), Ttest(:, 2), 9, colTest, 'filled', ...
    'MarkerFaceAlpha', 0.28, 'MarkerEdgeAlpha', 0.28, 'HandleVisibility', 'off');
scatter(ax1, Tcal(:, 1), Tcal(:, 2), 9, colCal, 'filled', ...
    'MarkerFaceAlpha', 0.28, 'MarkerEdgeAlpha', 0.28, 'HandleVisibility', 'off');
scatter(ax1, Tval(:, 1), Tval(:, 2), 9, colVal, 'filled', ...
    'MarkerFaceAlpha', 0.28, 'MarkerEdgeAlpha', 0.28, 'HandleVisibility', 'off');
hCal = scatter(ax1, nan, nan, 18, colCal, 'filled');
hVal = scatter(ax1, nan, nan, 18, colVal, 'filled');
hTest = scatter(ax1, nan, nan, 18, colTest, 'filled');
xlabel(ax1, sprintf('PC1 score (%.2f%%)', expVar(1, 2)), ...
    'FontName', 'Arial', 'FontSize', 9, 'Interpreter', 'none');
ylabel(ax1, sprintf('PC2 score (%.2f%%)', expVar(2, 2)), ...
    'FontName', 'Arial', 'FontSize', 9, 'Interpreter', 'none');
grid(ax1, 'on');
axis(ax1, 'square');
box(ax1, 'on');
hold(ax1, 'off');

lg1 = legend(ax1, [hCal, hVal, hTest], ...
    {'Calibration', 'Validation', 'Test'}, 'Location', 'none');
set(lg1, 'Units', 'centimeters', 'Position', [3.60, 7.20, 3.60, 1.50], ...
    'FontName', 'Arial', 'FontSize', 9, 'Box', 'on');

ax2 = axes(fig, 'Units', 'centimeters', 'Position', [10.40, 1.35, 5.75, 5.75]);
hold(ax2, 'on');
yAll = [ycal; yval; ytest];
binEdges = linspace(min(yAll), max(yAll), 31);
hTestHist = histogram(ax2, ytest, binEdges, 'Normalization', 'probability', ...
    'FaceColor', colTest, 'FaceAlpha', 0.45, 'EdgeColor', 'k', ...
    'LineWidth', 0.5);
hCalHist = histogram(ax2, ycal, binEdges, 'Normalization', 'probability', ...
    'FaceColor', colCal, 'FaceAlpha', 0.45, 'EdgeColor', 'k', ...
    'LineWidth', 0.5);
hValHist = histogram(ax2, yval, binEdges, 'Normalization', 'probability', ...
    'FaceColor', colVal, 'FaceAlpha', 0.45, 'EdgeColor', 'k', ...
    'LineWidth', 0.5);
xlabel(ax2, '{\rm log}_{10}({\it y}) [mol L^{-1}]', ...
    'FontName', 'Arial', 'FontSize', 9, 'Interpreter', 'tex');
ylabel(ax2, 'Probability', 'FontName', 'Arial', 'FontSize', 9, ...
    'Interpreter', 'none');
grid(ax2, 'on');
axis(ax2, 'square');
box(ax2, 'on');
hold(ax2, 'off');

lg2 = legend(ax2, [hCalHist, hValHist, hTestHist], ...
    {'Calibration', 'Validation', 'Test'}, 'Location', 'none');
set(lg2, 'Units', 'centimeters', 'Position', [12.35, 7.20, 3.60, 1.50], ...
    'FontName', 'Arial', 'FontSize', 9, 'Box', 'on');

for ax = [ax1, ax2]
    set(ax, 'FontName', 'Arial', 'FontSize', 8, 'LineWidth', 0.75, ...
        'FontWeight', 'normal', 'TickDir', 'out', 'GridAlpha', 0.18);
end

text(ax1, -0.20, 1.22, 'A', 'Units', 'normalized', 'Clipping', 'off', ...
    'FontName', 'Arial', 'FontSize', 18, 'FontWeight', 'bold');
text(ax2, -0.20, 1.22, 'B', 'Units', 'normalized', 'Clipping', 'off', ...
    'FontName', 'Arial', 'FontSize', 18, 'FontWeight', 'bold');

outdir = fullfile(projectRoot, 'figures', 'Figure-S6', 'raw_figure');
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
svgFile = fullfile(outdir, 'FigureSI6_data_split.svg');
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
