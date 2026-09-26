% FigureS1_data_loadings.m
% Script to generate Supplementary Information (SI) figure 1 for the manuscript

%
% USAGE: From the project root, run('figures/Figure-S1/code/FigureS1_data_loadings.m').

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
load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'data_split.mat'), 'IDcal','Xcal', 'wn','Ycal');
load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'pls_model.mat'),'P','Iy');


% --------------------------
% SI Figure 1: Raw data and PLS loadings
% --------------------------
idx_a   = ismember(IDcal, 9);
idx_int = ismember(IDcal, 25);

% Final display size: double-column width (180 mm).
fig = figure('Color', 'w', 'Units', 'centimeters', ...
    'Position', [2, 2, 18, 10.3], ...
    'PaperUnits', 'centimeters', 'PaperSize', [18, 10.3], ...
    'PaperPosition', [0, 0, 18, 10.3], 'Renderer', 'painters');

ax1 = subplot(3, 1, 1);
addpath(fullfile(projectRoot, 'code', 'functions'));
mycolor(wn, Xcal - mean(Xcal), Ycal(:,Iy)); grid on;
set(ax1, 'XDir', 'reverse', 'XTickLabels', [])
hcb = colorbar(ax1);
caxis([min(Ycal(:,Iy)) max(Ycal(:,Iy))]);
% set(hcb, 'Ticks', [0, 0.035, 0.070, 0.105, 0.140]);
hcb.TickLabels = compose('%.2f', hcb.Ticks);
ylabel(hcb, 'Analyte concentration [w/w]', 'FontName', 'Arial', ...
    'FontSize', 9, 'Interpreter', 'none');
formatAxes(ax1);
set(hcb, 'FontName', 'Arial', 'FontSize', 8);
ylabel(ax1, 'Intensity', 'FontName', 'Arial', 'FontSize', 9, ...
    'Interpreter', 'none');
pos1 = get(ax1, 'Position');
addPanelLabel(ax1, 'A');

ax2 = subplot(3, 1, 2);
plot(wn, mean(Xcal(idx_a,:)), 'LineWidth', 2); hold on;
plot(wn, mean(Xcal(idx_int,:)), 'LineWidth', 2); hold off;
addpath(fullfile(projectRoot, 'code', 'functions'));
not_so_tight('Y'); grid on;
set(ax2, 'XDir', 'reverse', 'XTickLabels', []);
formatAxes(ax2);
legend(ax2, 'Analyte', 'Interferent', 'Location', 'northwest', ...
    'FontName', 'Arial', 'FontSize', 8);
ylabel(ax2, 'Intensity', 'FontName', 'Arial', 'FontSize', 9, ...
    'Interpreter', 'none');
pos = get(ax2, 'Position');
pos(3) = pos1(3);
set(ax2, 'Position', pos);
addPanelLabel(ax2, 'B');

ax3 = subplot(3, 1, 3);
plot(wn, P(:,1), 'LineWidth', 2, 'Color', [0.9290 0.6940 0.1250]); hold on;
plot(wn, P(:,2), 'LineWidth', 2, 'Color', [0.4940 0.1840 0.5560]); hold off;
not_so_tight('Y'); grid on;
set(ax3, 'XDir', 'reverse', 'YLim', [-0.2, 0.2]);
formatAxes(ax3);
xlabel(ax3, 'Wavenumber [cm^{-1}]', 'FontName', 'Arial', 'FontSize', 9, ...
    'Interpreter', 'tex');
ylabel(ax3, 'Intensity', 'FontName', 'Arial', 'FontSize', 9, ...
    'Interpreter', 'none');
legend(ax3, 'Loadings LV1', 'Loadings LV2', 'Location', 'southwest', ...
    'FontName', 'Arial', 'FontSize', 8);
pos = get(ax3, 'Position');
pos(3) = pos1(3);
set(ax3, 'Position', pos);
addPanelLabel(ax3, 'C');

outdir = fullfile(projectRoot, 'figures', 'Figure-S1', 'raw_figure');
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
% print(fig, fullfile(outdir, 'FigureSI1_data_loadings_raw.svg'), '-dsvg', '-r1200');

function formatAxes(ax)
set(ax, 'FontName', 'Arial', 'FontSize', 8, 'LineWidth', 0.75, ...
    'Box', 'on', 'TickDir', 'out');
end

function addPanelLabel(ax, label)
text(ax, 0, 1.04, label, 'Units', 'normalized', ...
    'FontName', 'Arial', 'FontSize', 18, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
    'Interpreter', 'none');
end
