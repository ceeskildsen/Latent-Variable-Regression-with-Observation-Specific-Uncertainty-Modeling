% FigureS5_predictions_from_individual_LV.m
% Script to generate Supplementary Information (SI) figure 5 for the manuscript

%
% USAGE: From the project root, run('figures/Figure-S5/code/FigureS5_predictions_from_individual_LV.m').

clear; clc;
scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(fileparts(scriptDir)));
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    projectRoot = pwd;
end
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    error('Project root could not be resolved. Set the MATLAB current folder to the project root and run the script again.');
end

% --------------------------
% Load required data
% --------------------------
load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'data_split.mat'),'Ycal');
load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'pls_model.mat'), 'Tcal','q','Iint','Iy');

% --------------------------
% SI Figure 5: projections from individual latent variables
% --------------------------
fig = figure('Color', 'w', 'Units', 'centimeters', ...
    'Position', [2, 2, 18.0, 6.3], ...
    'PaperUnits', 'centimeters', 'PaperSize', [18.0, 6.3], ...
    'PaperPosition', [0, 0, 18.0, 6.3], 'Renderer', 'painters');

addpath(fullfile(projectRoot, 'code', 'functions'));
yc = Ycal(:, Iy) - mean(Ycal(:, Iy));
interferent = Ycal(:, Iint);

ax1 = axes(fig, 'Units', 'centimeters', 'Position', [1.25, 1.25, 3.90, 3.90]);
mycolor_scatter(yc, Tcal(:, 1) * q(1), interferent);
hold(ax1, 'on');
plot(ax1, [-0.1, 0.1], [-0.1, 0.1], 'k', 'LineWidth', 1.0);
xlim(ax1, [-0.1, 0.1]);
ylim(ax1, [-0.1, 0.1]);
xticks(ax1, [-0.05, 0, 0.05]);
yticks(ax1, [-0.05, 0, 0.05]);
xtickformat(ax1, '%.2f');
ytickformat(ax1, '%.2f');

ax2 = axes(fig, 'Units', 'centimeters', 'Position', [6.45, 1.25, 3.90, 3.90]);
mycolor_scatter(yc, yc - Tcal(:, 1) * q(1), interferent);
xlim(ax2, [-0.1, 0.1]);
ylim(ax2, [-0.02, 0.02]);
xticks(ax2, [-0.05, 0, 0.05]);
yticks(ax2, [-0.02, -0.01, 0, 0.01, 0.02]);
xtickformat(ax2, '%.2f');
ytickformat(ax2, '%.2f');

ax3 = axes(fig, 'Units', 'centimeters', 'Position', [11.75, 1.25, 3.90, 3.90]);
mycolor_scatter(yc, Tcal(:, 2) * q(2), interferent, 'cbar', ...
    min(interferent), max(interferent));
xlim(ax3, [-0.1, 0.1]);
xticks(ax3, [-0.05, 0, 0.05]);
yticks(ax3, [-0.01, -0.005, 0, 0.005, 0.01]);
xtickformat(ax3, '%.2f');
ytickformat(ax3, '%.3f');
hcb = colorbar(ax3);
set(hcb, 'Ticks', [0, 0.055, 0.110, 0.165, 0.220]);
hcb.TickLabels = compose('%.3f', hcb.Ticks);

xLabel = '{\it y} - {\it ȳ} [w/w]';
xlabel(ax1, xLabel, 'FontName', 'Arial', 'FontSize', 9, ...
    'FontWeight', 'normal', 'Interpreter', 'tex');
xlabel(ax2, xLabel, 'FontName', 'Arial', 'FontSize', 9, ...
    'FontWeight', 'normal', 'Interpreter', 'tex');
xlabel(ax3, xLabel, 'FontName', 'Arial', 'FontSize', 9, ...
    'FontWeight', 'normal', 'Interpreter', 'tex');
ylabel(ax1, '{\it t}_{1}{\it q}_{1} [w/w]', ...
    'FontName', 'Arial', 'FontSize', 9, 'FontWeight', 'normal', 'Interpreter', 'tex');
ylabel(ax2, '({\it y} - {\it ȳ}) - {\it t}_{1}{\it q}_{1} [w/w]', ...
    'FontName', 'Arial', 'FontSize', 9, 'FontWeight', 'normal', 'Interpreter', 'tex');
ylabel(ax3, '{\it t}_{2}{\it q}_{2} [w/w]', ...
    'FontName', 'Arial', 'FontSize', 9, 'FontWeight', 'normal', 'Interpreter', 'tex');
ylabel(hcb, 'Interferent concentration [w/w]', ...
    'FontName', 'Arial', 'FontSize', 9, 'FontWeight', 'normal', 'Interpreter', 'none');

for ax = [ax1, ax2, ax3]
    axis(ax, 'square');
    set(ax, 'FontName', 'Arial', 'FontSize', 8, 'LineWidth', 0.75, ...
        'FontWeight', 'normal', 'Box', 'on', 'TickDir', 'out');
end
set(hcb, 'Units', 'centimeters', 'Position', [15.95, 1.25, 0.30, 3.90], ...
    'FontName', 'Arial', 'FontSize', 8, 'LineWidth', 0.75, 'TickDirection', 'out');

text(ax1, -0.20, 1.12, 'A', 'Units', 'normalized', 'Clipping', 'off', ...
    'FontName', 'Arial', 'FontSize', 18, 'FontWeight', 'bold');
text(ax2, -0.10, 1.12, 'B', 'Units', 'normalized', 'Clipping', 'off', ...
    'FontName', 'Arial', 'FontSize', 18, 'FontWeight', 'bold');
text(ax3, -0.02, 1.12, 'C', 'Units', 'normalized', 'Clipping', 'off', ...
    'FontName', 'Arial', 'FontSize', 18, 'FontWeight', 'bold');

outdir = fullfile(projectRoot, 'figures', 'Figure-S5', 'raw_figure');
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
svgFile = fullfile(outdir, 'FigureSI5_predictions_from_individual_LV_raw.svg');
print(fig, svgFile, '-dsvg', '-r1200');

set_svg_physical_size(svgFile, 18.0, 6.3);

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
