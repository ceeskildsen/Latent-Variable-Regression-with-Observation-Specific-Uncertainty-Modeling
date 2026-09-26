% FigureS3_scores_col_by_analyte.m
% Script to generate Supplementary Information (SI) figure 3 for the manuscript

%
% USAGE: From the project root, run('figures/Figure-S3/code/FigureS3_scores_col_by_analyte.m').

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
load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'pls_model.mat'), 'Tcal','Iy');

% --------------------------
% SI Figure 3: latent space coloured by analyte
% --------------------------
fig = figure('Color', 'w', 'Units', 'centimeters', ...
    'Position', [2, 2, 8.9, 7.0], ...
    'PaperUnits', 'centimeters', 'PaperSize', [8.9, 7.0], ...
    'PaperPosition', [0, 0, 8.9, 7.0], 'Renderer', 'painters');

addpath(fullfile(projectRoot, 'code', 'functions'));
mycolor_scatter(Tcal(:,1), Tcal(:,2), Ycal(:,Iy));
ax = gca;
axis(ax, 'square');
xlabel(ax, 'LV1 score', 'FontName', 'Arial', 'FontSize', 9, 'Interpreter', 'none');
ylabel(ax, 'LV2 score', 'FontName', 'Arial', 'FontSize', 9, 'Interpreter', 'none');
hcb = colorbar(gca);
caxis([min(Ycal(:,Iy)) max(Ycal(:,Iy))]);
set(hcb, 'Ticks', [0, 0.035, 0.070, 0.105, 0.140]);
hcb.TickLabels = compose('%.3f', hcb.Ticks);
ylabel(hcb, 'Analyte concentration [w/w]', 'FontName', 'Arial', ...
    'FontSize', 9, 'Interpreter', 'none');

set(ax, 'XLim', [-600, 600], 'YLim', [-600, 600], ...
    'XTick', [-500, -250, 0, 250, 500], 'YTick', [-500, -250, 0, 250, 500], ...
    'FontName', 'Arial', 'FontSize', 8, 'LineWidth', 0.75, 'TickDir', 'out');
set(hcb, 'FontName', 'Arial', 'FontSize', 8, 'LineWidth', 0.75, 'TickDirection', 'out');

outdir = fullfile(projectRoot, 'figures', 'Figure-S3', 'raw_figure');
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
svgFile = fullfile(outdir, 'FigureSI3_scores_col_by_analyte_raw.svg');
% print(fig, svgFile, '-dsvg', '-r1200');

% MATLAB writes SVG dimensions as unitless pixels at 144 dpi.  Inkscape
% interprets unitless SVG pixels at 96 dpi, which otherwise enlarges the
% artwork after import.  Set the intended physical size and retain the
% original coordinate system so the figure imports at 89 mm wide.

% set_svg_physical_size(svgFile, 8.9, 7.0);

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
