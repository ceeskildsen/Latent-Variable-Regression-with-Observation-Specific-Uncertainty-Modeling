% FigureS2_e_against_y.m
% Script to generate Supplementary Information (SI) figure 2 for the manuscript

%
% USAGE: From the project root, run('figures/Figure-S2/code/FigureS2_e_against_y.m').

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
load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'pls_model.mat'),'e_cal','Iint','Iy');

% --------------------------
% SI Figure 2: Calibration residuals versus analyte reference concentrations
% --------------------------
% Final display size: single-column width (89 mm).
fig = figure('Color', 'w', 'Units', 'centimeters', ...
    'Position', [2, 2, 8.9, 7], ...
    'PaperUnits', 'centimeters', 'PaperSize', [8.9, 7], ...
    'PaperPosition', [0, 0, 8.9, 7], 'Renderer', 'painters');
addpath(fullfile(projectRoot, 'code', 'functions'));
mycolor_scatter(Ycal(:,Iy), e_cal, Ycal(:,Iint),'cbar',min(Ycal(:,Iint)), max(Ycal(:,Iint)));
not_so_tight; axis square;
xlabel({'{\it y} [w/w]', '(Analyte reference concentration)'}, ...
    'FontName', 'Arial', 'FontSize', 9, 'Interpreter', 'tex');
ylabel('{\it e} = {\it y} − {\it ŷ} [w/w]', ...
    'FontName', 'Arial', 'FontSize', 9, 'Interpreter', 'tex');
hcb = colorbar(gca);
% caxis([min(Ycal(:,Iint)) max(Ycal(:,Iint))]);
set(hcb, 'Ticks', [0, 0.055, 0.110, 0.165, 0.22]);
hcb.TickLabels = compose('%.3f', hcb.Ticks);
line(xlim, [0 0], 'color','k', 'linestyle','--','linewidth', 2)
ylabel(hcb, 'Interferent concentration [w/w]', 'FontName', 'Arial', ...
    'FontSize', 9, 'Interpreter', 'none');

ax = gca;
set(ax, 'FontName', 'Arial', 'FontSize', 8, 'LineWidth', 0.75, ...
    'Box', 'on', 'TickDir', 'out');
set(hcb, 'FontName', 'Arial', 'FontSize', 8);


outdir = fullfile(projectRoot, 'figures', 'Figure-S2', 'raw_figure');
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
svgFile = fullfile(outdir, 'FigureSI2_e_vs_y_raw.svg');
print(fig, svgFile, '-dsvg', '-r1200');

% MATLAB writes SVG dimensions as unitless pixels at 144 dpi.  Inkscape
% interprets unitless SVG pixels at 96 dpi, which otherwise enlarges the
% artwork after import.  Set the intended physical size and retain the
% original coordinate system so the figure imports at 89 mm wide.
set_svg_physical_size(svgFile, 8.9, 7.0);

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
