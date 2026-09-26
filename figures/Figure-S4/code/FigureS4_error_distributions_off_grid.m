% FigureS4_error_distributions_off_grid.m
% Script to generate panel B of Supplementary Figure 4 for the manuscript.
% Panel A, the experimental design, is maintained separately in Inkscape.

% USAGE: From the project root, run('figures/Figure-S4/code/FigureS4_error_distributions_off_grid.m').

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
load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'data_split.mat'), 'IDtest');
load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'pls_model.mat'), 'e_test', 'uIDtest');
load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'gp_model_results.mat'), ...
    'E_e_test_hat', 'Var_ale_test_hat');

% --------------------------
% SI Figure 4B: Error distributions for off-grid samples
% --------------------------
% Final display size of the MATLAB panel within the composite figure.
fig = figure('Color', 'w', 'Units', 'centimeters', ...
    'Position', [2, 2, 8.5, 7.2], ...
    'PaperUnits', 'centimeters', 'PaperSize', [8.5, 7.2], ...
    'PaperPosition', [0, 0, 8.5, 7.2], 'Renderer', 'painters');

IDorder = [46, 48, 42; 45, 41, 39; 36, 37, 44; 31, 43, 35];
offGridGreen = [0.4660, 0.6740, 0.1880];
xx = linspace(-1e-2, 8e-3, 1000);

t = tiledlayout(fig, 4, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

for i = 1:4
    for j = 1:3
        sampleNumber = i + (j - 1) * 4;
        ax = nexttile(t, (i - 1) * 3 + j);
        hold(ax, 'on');

        idx = ismember(uIDtest, IDorder(i, j));
        gpDensity = normpdf(xx, E_e_test_hat(idx), sqrt(Var_ale_test_hat(idx)));

        idx2 = ismember(IDtest, IDorder(i, j));
        [histValues, histEdges] = histcounts(e_test(idx2), ...
            'Normalization', 'pdf', 'BinWidth', 1e-3);

        for k = 1:numel(histValues)
            xPoly = [histEdges(k), histEdges(k + 1), histEdges(k + 1), histEdges(k)];
            yPoly = [0, 0, histValues(k), histValues(k)];
            patch(ax, 'XData', xPoly, 'YData', yPoly, ...
                'FaceColor', offGridGreen, 'FaceAlpha', 0.5, ...
                'EdgeColor', 'k', 'LineWidth', 0.75);
        end

        plot(ax, xx, gpDensity, 'k', 'LineWidth', 1.25);
        xline(ax, 0, 'k--', 'LineWidth', 1);

        xlim(ax, [-1e-2, 8e-3]);
        ylim(ax, [0, 600]);
        xticks(ax, [-1e-2, -5e-3, 0, 5e-3]);
        ax.XAxis.Exponent = -3;
        yticks(ax, [0, 300, 600]);
        yticklabels(ax, []);
        grid(ax, 'on');
        box(ax, 'on');
        set(ax, 'FontName', 'Arial', 'FontSize', 6, 'LineWidth', 0.5, ...
            'TickDir', 'out', 'GridAlpha', 0.18);

        if i < 4
            xticklabels(ax, []);
        end

        text(ax, 0.06, 0.82, num2str(sampleNumber), 'Units', 'normalized', ...
            'FontName', 'Arial', 'FontSize', 7, 'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'top');
    end
end

xlabel(t, {'{\it e} [w/w]', 'Prediction error'}, ...
    'FontName', 'Arial', 'FontSize', 9, 'Interpreter', 'tex');
ylabel(t, 'Probability density', 'FontName', 'Arial', 'FontSize', 9, ...
    'Interpreter', 'none');

outdir = fullfile(projectRoot, 'figures', 'Figure-S4', 'raw_figure');
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
svgFile = fullfile(outdir, 'FigureSI4_error_distributions_off_grid_raw.svg');
print(fig, svgFile, '-dsvg', '-r1200');

% MATLAB writes SVG dimensions as unitless pixels at 144 dpi.  Inkscape
% interprets unitless SVG pixels at 96 dpi, which otherwise enlarges the
% artwork after import.  Set the intended panel size and retain the
% original coordinate system so it fits panel B of the 180-mm composite.
set_svg_physical_size(svgFile, 8.5, 7.2);

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
