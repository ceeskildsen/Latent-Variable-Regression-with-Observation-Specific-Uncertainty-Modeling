% Figure6_error_distributions.m
% Script to generate Figure 6: Uncertainty distributions for selected test samples

%
% USAGE: From the project root, run('figures/Figure-6/code/Figure6_error_distributions.m').

close all; clear; clc;
scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(fileparts(scriptDir)));
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    projectRoot = pwd;
end
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    error('Project root could not be resolved. Set the MATLAB current folder to the project root and run the script again.');
end


% Load required data
load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'data_split.mat'),'IDcal','IDtest','Ycal')
load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'pls_model.mat'),'uIDtest','Iint','e_test')
load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'gp_model_results.mat'), ...
    'E_e_test_hat', 'Var_ale_test_hat');

% Define sample layout.
IDorder = [1,3,5,7,9; 10:14; 15,16,30,18,19; 20:24; 25:29];

% Prepare the figure at its intended double-column publication size.
figureWidthMm = 180;
figureHeightMm = 103;
fig = figure('Color', 'w', ...
    'Units', 'inches', ...
    'Position', [0, 0, figureWidthMm/25.4, figureHeightMm/25.4]);

% --------------------------
% Setup colormap
% --------------------------
fullpink = flipud(colormap('pink'));
m = size(get(fig, 'colormap'), 1);

% Define the fraction of the pink colormap to retain.
cutFraction = 0.7;

% Determine the starting index to keep.
startIdx = round(cutFraction * m);

% Extract the selected portion of the pink colormap.
upperpink = fullpink(1:startIdx, :);

% Interpolate the extracted portion back to m colors.
xOriginal = linspace(0, 1, size(upperpink, 1));
xQuery    = linspace(0, 1, m);
newColormap = interp1(xOriginal, upperpink, xQuery);

% Convert the colormap to HSV so we can adjust brightness.
hsvMap = rgb2hsv(flipud(newColormap));

% Darken
hsvMap(1:end, 3) = hsvMap(1:end, 3) * 0.8;

% Convert back to RGB.
cmap = flipud(hsv2rgb(hsvMap));

maxCol = size(cmap,1)-1;
cnew = Ycal(:,Iint) - min(Ycal(:,Iint));
cnew = cnew / max(cnew);
cnew = round(cnew * maxCol) + 1;

% Setup axes and range
xx = linspace(-1E-2, 8E-3, 1000);
offset = 600;
count = 0;

% --------------------------
% Generate Figure 6
% --------------------------
layout = tiledlayout(fig, 1, 5, ...
    'TileSpacing', 'compact', ...
    'Padding', 'loose');
ax = gobjects(1, 5);

for j = 1:5
    count = count + 1;
    ax(j) = nexttile(layout, count);
    hold on;

    for i = 1:5
        baseline_y = (i-1)*offset * ones(size(xx));
        plot(xx, baseline_y, 'k', 'LineWidth', 1);  % baseline

        % Indexing
        idx  = ismember(uIDtest, IDorder(i, j));
        idx1 = ismember(IDcal, IDorder(i,j));
        idx2 = ismember(IDtest, IDorder(i, j));

        % Plot estimated GP distribution (black line)
        y1 = normpdf(xx, E_e_test_hat(idx), sqrt(Var_ale_test_hat(idx))) + (i-1)*offset;
        plot(xx, y1, 'LineWidth', 1.5, 'color', 'k');

        % Histogram of observed residuals
        [hist_values, hist_edges] = histcounts(e_test(idx2), 'Normalization', 'pdf', 'BinWidth', 0.001);
        for k = 1:length(hist_values)
            xLeft  = hist_edges(k);
            xRight = hist_edges(k+1);
            yBottom = (i-1)*offset;
            yTop    = yBottom + hist_values(k);
            xPoly = [xLeft, xRight, xRight, xLeft];
            yPoly = [yBottom, yBottom, yTop, yTop];
            patch('XData', xPoly, ...
                  'YData', yPoly, ...
                  'FaceVertexCData', cmap(mean(cnew(idx1)),:), ...
                  'FaceColor', 'flat', ...
                  'FaceAlpha', 0.5, ...
                  'EdgeColor', 'k', ...
                  'LineWidth', 1);
        end

    end

    % Plot the zero-error reference once per panel.
    plot([0, 0], [0, offset*5], 'k--', 'LineWidth', 1);

    axis tight;
    ylim([0 offset*5]);
    yticks(0:300:offset*5);
    grid on;
    box on;
    set(ax(j), ...
        'YTickLabel', [], ...
        'FontName', 'Arial', ...
        'FontSize', 8, ...
        'FontWeight', 'normal');
    xtickangle(ax(j), 0);

    % Panel label. Clipping is disabled so the label can sit just outside
    % the upper-left corner of the plotting area.
    text(ax(j), -0.12, 1.03, char('A' + j - 1), ...
        'Units', 'normalized', ...
        'FontName', 'Arial', ...
        'FontSize', 18, ...
        'FontWeight', 'bold', ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'bottom', ...
        'Clipping', 'off');
end

% Shared axis labels. Only the scalar prediction error, e, is italic.
xlabel(layout, '\ite\rm [w/w] (prediction error)', ...
    'Interpreter', 'tex', ...
    'FontName', 'Arial', ...
    'FontSize', 8, ...
    'FontWeight', 'normal');
ylabel(layout, 'Probability density', ...
    'FontName', 'Arial', ...
    'FontSize', 8, ...
    'FontWeight', 'normal');

% Export figure
set(fig, 'Renderer', 'painters');
set(fig, 'InvertHardcopy', 'off');
drawnow;

outdir = fullfile(projectRoot, 'figures', 'Figure-6', 'raw_figure');
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
svgFile = fullfile(outdir, 'Figure6_ErrorDistributions_raw.svg');
print(fig, svgFile, '-dsvg', '-r1200');

% MATLAB writes SVG dimensions as unitless values using 144 units per inch.
% Inkscape interprets unitless SVG dimensions at 96 pixels per inch, making
% the artwork 1.5 times too large. Add an explicit physical page size and a
% viewBox so that Inkscape and the submitted PDF preserve the intended
% 180 mm width while scaling all vector elements, fonts and line widths
% consistently.
svgText = fileread(svgFile);
rootPattern = ['<svg(?<before>[^>]*)width="(?<width>[0-9.]+)" ' ...
               'height="(?<height>[0-9.]+)"(?<after>[^>]*)>'];
rootMatch = regexp(svgText, rootPattern, 'names', 'once');
oldRoot = regexp(svgText, rootPattern, 'match', 'once');

if isempty(rootMatch) || isempty(oldRoot)
    error('Could not identify the SVG root dimensions in %s.', svgFile);
end

newRoot = sprintf(['<svg%swidth="%.6gmm" height="%.6gmm" ' ...
                   'viewBox="0 0 %s %s"%s>'], ...
    rootMatch.before, figureWidthMm, figureHeightMm, ...
    rootMatch.width, rootMatch.height, rootMatch.after);
svgText = strrep(svgText, oldRoot, newRoot);

fid = fopen(svgFile, 'w');
if fid == -1
    error('Could not reopen %s to set its physical dimensions.', svgFile);
end
fileCleanup = onCleanup(@() fclose(fid));
fwrite(fid, svgText, 'char');
clear fileCleanup;
