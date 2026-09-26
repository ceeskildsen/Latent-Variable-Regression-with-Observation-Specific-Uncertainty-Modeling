% FigureS7_PLS.m
% Script to generate Supplementary Figure 7: AqSolDB PLS model.
%
% USAGE: From the project root, run('figures/Figure-S7/code/FigureS7_PLS.m').

clear; close all; clc;

scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(fileparts(scriptDir)));
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    projectRoot = pwd;
end
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    error('Project root could not be resolved. Set the MATLAB current folder to the project root and run the script again.');
end

load(fullfile(projectRoot, 'data', 'AqSolDB', 'analysis_data', 'pls_model_AqSolDB.mat'));
load(fullfile(projectRoot, 'data', 'AqSolDB', 'analysis_data', 'AqSolDB_data_split.mat'), 'ycal');
ycal = ycal(idx_cal);

colCal = [0.2 0.7 0.3];
colOther = [0.75 0.85 0.77];

fig = figure('Color', 'w', 'Units', 'centimeters', ...
    'Position', [2, 2, 18.0, 9.0], ...
    'PaperUnits', 'centimeters', 'PaperSize', [18.0, 9.0], ...
    'PaperPosition', [0, 0, 18.0, 9.0], 'Renderer', 'painters');

ax1 = axes(fig, 'Units', 'centimeters', 'Position', [1.65, 1.45, 5.75, 5.75]);
hb = bar(ax1, 1:10, MSE_cv(1:10), 'FaceColor', 'flat', ...
    'EdgeColor', 'k', 'LineWidth', 0.75);
hb.CData = repmat(colOther, 10, 1);
hb.CData(LV, :) = colCal;
xticks(ax1, 1:10);
xtickangle(ax1, 0);
ytickformat(ax1, '%.1f');
xlabel(ax1, 'Number of latent variables', ...
    'FontName', 'Arial', 'FontSize', 9, 'Interpreter', 'none');
ylabel(ax1, 'Cross-validated mean squared error', ...
    'FontName', 'Arial', 'FontSize', 9, 'Interpreter', 'none');
grid(ax1, 'on');
axis(ax1, 'square');
box(ax1, 'on');

ax2 = axes(fig, 'Units', 'centimeters', 'Position', [10.40, 1.45, 5.75, 5.75]);
hold(ax2, 'on');
scatter(ax2, ycal, yhat_cv(:, LV), 9, colCal, 'filled', ...
    'MarkerFaceAlpha', 0.28, 'MarkerEdgeAlpha', 0.28);
allValues = [ycal; yhat_cv(:, LV)];
padding = 0.05 * range(allValues);
axmin = min(allValues) - padding;
axmax = max(allValues) + padding;
plot(ax2, [axmin, axmax], [axmin, axmax], 'k', 'LineWidth', 1.0);
xlim(ax2, [axmin, axmax]);
ylim(ax2, [axmin, axmax]);
xlabel(ax2, {'{\rm log}_{10}({\it y}) [mol L^{-1}]', '(Reference value)'}, ...
    'FontName', 'Arial', 'FontSize', 9, 'Interpreter', 'tex');
ylabel(ax2, {'{\rm log}_{10}({\it ŷ}) [mol L^{-1}]', ...
    '(Cross-validated prediction)'}, ...
    'FontName', 'Arial', 'FontSize', 9, 'Interpreter', 'tex');
grid(ax2, 'on');
axis(ax2, 'square');
box(ax2, 'on');
hold(ax2, 'off');

for ax = [ax1, ax2]
    set(ax, 'FontName', 'Arial', 'FontSize', 8, 'LineWidth', 0.75, ...
        'FontWeight', 'normal', 'TickDir', 'out', 'GridAlpha', 0.18);
end

text(ax1, -0.20, 1.12, 'A', 'Units', 'normalized', 'Clipping', 'off', ...
    'FontName', 'Arial', 'FontSize', 18, 'FontWeight', 'bold');
text(ax2, -0.20, 1.12, 'B', 'Units', 'normalized', 'Clipping', 'off', ...
    'FontName', 'Arial', 'FontSize', 18, 'FontWeight', 'bold');

outdir = fullfile(projectRoot, 'figures', 'Figure-S7', 'raw_figure');
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
svgFile = fullfile(outdir, 'FigureSI7_PLS.svg');
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
