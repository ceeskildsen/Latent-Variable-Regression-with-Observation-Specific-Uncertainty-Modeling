% Figure9_analyte_detection.m
% Script to generate Figure 9 from saved analyte-detection results.

%
% USAGE: From the project root, run('figures/Figure-9/code/Figure9_analyte_detection.m').

close all; clear; clc;

scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(fileparts(scriptDir)));
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    projectRoot = pwd;
end
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    error('Project root could not be resolved. Set the MATLAB current folder to the project root and run the script again.');
end

load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'analyte_detection_results.mat'), ...
    'LV', 'Tcal2', 'Ycal', 'Iint', 'uTtest_null', ...
    'mnTblank', 'Q_blank', 'u_y', ...
    'analyteT', 'nullT', 'yhat_A', 'yhat_blank', ...
    'e_hat_detect', 'Var_total_null', 'var_null_ols', ...
    'DL_gp', 'DL_ols', 'p_tail');

if LV ~= 2
    warning('This script is written for LV=2. Current LV=%d.', LV);
end

% Nature Communications maximum double-column width. The fixed physical
% dimensions are also written into the SVG after export below.
figureWidthMm = 180;
figureHeightMm = 120;
fig = figure('Color', 'w', ...
    'Units', 'inches', ...
    'Position', [0, 0, figureWidthMm/25.4, figureHeightMm/25.4]);

fontName = 'Arial';
axisFontSize = 8;
panelLabelFontSize = 18;
nullSpaceColor = [0, 0.4470, 0.7410];
olsColor = [0.6350, 0.8500, 0.8800];

axlim_T1 = [-600, 600];
axlim_T2 = axlim_T1;

addpath(fullfile(projectRoot, 'code', 'functions'));
% Fixed positions avoid the automatic subplot layout shrinking panel B to
% accommodate its legend. The arrangement follows the previous final
% Figure 9: panel A on the left, with two aligned distribution panels on
% the right.
% With the 180 mm-wide by 120 mm-high canvas, a normalized width of 0.36
% and height of 0.54 give a square 64.8 mm panel. Its vertical limits are
% deliberately identical to the outer vertical limits of the two B panels.
axA = axes('Parent', fig, 'Position', [0.08, 0.15, 0.36, 0.54]);
hCalibration = mycolor_scatter(Tcal2(:,1), Tcal2(:,2), Ycal(:,Iint)); hold on;

hBlankOnGrid = plot(uTtest_null(1:min(5,size(uTtest_null,1)),1), ...
     uTtest_null(1:min(5,size(uTtest_null,1)),2), ...
    'o', 'MarkerSize', 6, 'LineWidth', 1.5, 'Color', [0.8500 0.3250 0.0980]);
if size(uTtest_null,1) > 5
    hBlankOffGrid = plot(uTtest_null(6:end,1), uTtest_null(6:end,2), ...
        'p', 'MarkerSize', 7, 'LineWidth', 1.0, ...
        'MarkerEdgeColor', [0.4660 0.6740 0.1880], ...
        'MarkerFaceColor', [0.4660 0.6740 0.1880]);
else
    hBlankOffGrid = gobjects(1);
end

alpha_plot = max(abs(axlim_T1)) * 1.5;
pt1 = mnTblank - alpha_plot * Q_blank';
pt2 = mnTblank + alpha_plot * Q_blank';
hNullSpace = plot([pt1(1), pt2(1)], [pt1(2), pt2(2)], '-', ...
    'LineWidth', 2.5, 'Color', nullSpaceColor);

col = [0.9290 0.6940 0.1250; 0.6350 0.0780 0.1840];
hAnalyte = gobjects(2,1);
hNull = gobjects(2,1);
for i = 1:2
    hAnalyte(i) = plot(analyteT(i,1), analyteT(i,2), '+', ...
        'MarkerSize', 10, 'LineWidth', 2.5, 'Color', col(i,:));
    hNull(i) = plot(nullT(i,1), nullT(i,2), 'x', ...
        'MarkerSize', 10, 'LineWidth', 2.0, 'Color', col(i,:));
    line([nullT(i,1), analyteT(i,1)], [nullT(i,2), analyteT(i,2)], ...
        'LineStyle', ':', 'Color', [0.5, 0.5, 0.5], 'LineWidth', 1);
end

set(axA, 'XLim', axlim_T1, 'YLim', axlim_T2, ...
    'XTick', [-500, -250, 0, 250, 500], ...
    'YTick', [-500, -250, 0, 250, 500]);
axis(axA, 'square'); grid(axA, 'on'); box(axA, 'on');
xlabel(axA, 'LV1 score', 'FontName', fontName, 'FontSize', axisFontSize, ...
    'FontWeight', 'normal');
ylabel(axA, 'LV2 score', 'FontName', fontName, 'FontSize', axisFontSize, ...
    'FontWeight', 'normal');
% The ordering in the results file is sample 6 then sample 5. The legend
% therefore lists the handles in the intuitive sample-number order.
lgdA = legend(axA, [hBlankOnGrid, hBlankOffGrid, hNullSpace, ...
    hAnalyte(2), hAnalyte(1)], ...
    {'Blank test samples (on-grid)', 'Blank test samples (off-grid)', ...
    'Estimated null-space', 'Sample 5', 'Sample 6'}, ...
    'Location', 'northoutside', 'NumColumns', 2, 'FontName', fontName, ...
    'FontSize', axisFontSize, 'FontWeight', 'normal', 'Box', 'on');
set(lgdA, 'Units', 'normalized', 'Position', [0.06, 0.75, 0.43, 0.13]);

% Both panels retain the same outer top and bottom limits as panel A. They
% are deliberately taller and closer together than a default subplot pair.
panelBPositions = [0.58, 0.15, 0.35, 0.23; ... % Sample 6 (bottom)
                   0.58, 0.46, 0.35, 0.23];    % Sample 5 (top)
h_sub = gobjects(2,1);
hGp = gobjects(2,1);
hOls = gobjects(2,1);
hDLgp = gobjects(2,1);
hDLols = gobjects(2,1);
hPrediction = gobjects(2,1);
for i = 1:2
    h_sub(i) = axes('Parent', fig, 'Position', panelBPositions(i,:)); hold on;

    [hist_values, hist_edges] = histcounts(yhat_blank{i}, ...
        'Normalization', 'pdf', 'BinWidth', 0.001);

    for k = 1:length(hist_values)
        xPoly = [hist_edges(k), hist_edges(k+1), hist_edges(k+1), hist_edges(k)];
        yPoly = [0, 0, hist_values(k), hist_values(k)];
        if i == 1
            patch('XData', xPoly, 'YData', yPoly, ...
                'FaceVertexCData', [0.4660 0.6740 0.1880], ...
                'FaceColor', 'flat', 'FaceAlpha', 0.5, 'EdgeColor', 'k', 'LineWidth', 1);
        else
            patch('XData', xPoly, 'YData', yPoly, ...
                'FaceVertexCData', [0.8500 0.3250 0.0980], ...
                'FaceColor', 'flat', 'FaceAlpha', 0.5, 'EdgeColor', 'k', 'LineWidth', 1);
        end
    end

    xx = linspace(-0.01, 0.02, 1000);

    hOls(i) = plot(xx, normpdf(xx, 0, sqrt(var_null_ols(i))), ...
        'LineWidth', 1.5, 'Color', olsColor);
    hGp(i) = plot(xx, normpdf(xx, -e_hat_detect(i), sqrt(Var_total_null(i))), ...
        'k', 'LineWidth', 1.5);

    hDLgp(i) = plot([DL_gp(i) DL_gp(i)], [0, 500], 'k:', 'LineWidth', 1.5);
    hDLols(i) = plot([DL_ols(i) DL_ols(i)], [0, 500], ':', ...
        'LineWidth', 1.5, 'Color', olsColor);
    hPrediction(i) = plot([yhat_A(i) yhat_A(i)], [0, 600], '-', ...
        'LineWidth', 1.5, 'Color', col(i,:));
    % A downward triangle produces a robust arrowhead in SVG export. A
    % quiver arrowhead scales poorly because the horizontal and vertical
    % axes use different units.
    plot(h_sub(i), yhat_A(i), 25, 'v', 'MarkerSize', 7, ...
        'MarkerFaceColor', col(i,:), 'MarkerEdgeColor', col(i,:));

    axis tight;
    ylim([0, 600]); yticks(0:200:600); set(gca, 'YTickLabel', []);
    grid on; box on;

    if i == 1
        % MATLAB's TeX interpreter does not reliably export \hat to SVG.
        % The precomposed glyph preserves the intended y-hat label in
        % Inkscape; italics identify it as a scalar variable.
        xlabel(h_sub(i), char(375), 'Interpreter', 'none', ...
            'FontName', fontName, 'FontSize', axisFontSize, ...
            'FontWeight', 'normal', 'FontAngle', 'italic');
        set(gca,'XTick',[0,0.01,0.02], 'XTickLabel',[0,0.01,0.02]);
    else
        set(gca,'XTick',[0,0.01,0.02], 'XTickLabel',[]);
    end
    set(h_sub(i), 'FontName', fontName, 'FontSize', axisFontSize, ...
        'FontWeight', 'normal', 'LineWidth', 0.75);
end

title(h_sub(2), 'Analyte detection sample 5', ...
    'FontName', fontName, 'FontSize', axisFontSize, 'FontWeight', 'normal');
title(h_sub(1), 'Analyte detection sample 6', ...
    'FontName', fontName, 'FontSize', axisFontSize, 'FontWeight', 'normal');

% Direct labels keep the B legend compact while identifying the empirical
% histograms and the coloured prediction arrows.
for i = 1:2
    text(h_sub(i), 0.18, 0.76, {'Empirical blank', 'data'}, ...
        'Units', 'normalized', ...
        'FontName', fontName, 'FontSize', axisFontSize, 'FontWeight', 'normal', ...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');
    text(h_sub(i), 0.94, 0.86, {'Analyte', 'prediction'}, ...
        'Units', 'normalized', ...
        'FontName', fontName, 'FontSize', axisFontSize, 'FontWeight', 'normal', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
end

lgdB = legend(h_sub(2), [hGp(2), hDLgp(2), hOls(2), hDLols(2)], ...
    {'Null distribution (GP-derived)', '95% detection limit (GP-derived)', ...
    'Null distribution (OLS-derived)', '95% detection limit (OLS-derived)'}, ...
    'Location', 'northoutside', 'NumColumns', 1, 'FontName', fontName, ...
    'FontSize', axisFontSize, 'FontWeight', 'normal', 'Box', 'on');
set(lgdB, 'Units', 'normalized', 'Position', [0.58, 0.76, 0.36, 0.17]);

% One shared y-axis label makes the paired distributions read as a single
% panel while leaving both plot interiors uncluttered.
sharedLabelAxes = axes('Parent', fig, 'Position', [0, 0, 1, 1], ...
    'Visible', 'off', 'HitTest', 'off', 'HandleVisibility', 'off');
text(sharedLabelAxes, 0.555, 0.42, 'Probability density', ...
    'Units', 'normalized', 'Rotation', 90, ...
    'FontName', fontName, 'FontSize', axisFontSize, 'FontWeight', 'normal', ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');

% Place panel labels in figure coordinates so they remain above, rather
% than underneath, their legends when MATLAB exports the SVG.
annotation(fig, 'textbox', [0.055, 0.890, 0.05, 0.045], 'String', 'A', ...
    'FontName', fontName, 'FontSize', panelLabelFontSize, ...
    'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'middle', 'EdgeColor', 'none', 'FitBoxToText', 'off');
annotation(fig, 'textbox', [0.535, 0.940, 0.05, 0.045], 'String', 'B', ...
    'FontName', fontName, 'FontSize', panelLabelFontSize, ...
    'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'middle', 'EdgeColor', 'none', 'FitBoxToText', 'off');

set(axA, 'FontName', fontName, 'FontSize', axisFontSize, ...
    'FontWeight', 'normal', 'LineWidth', 0.75);

disp(p_tail);

set(fig, 'Renderer', 'painters', 'InvertHardcopy', 'off');
drawnow;

outdir = fullfile(projectRoot, 'figures', 'Figure-9', 'raw_figure');
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
svgFile = fullfile(outdir, 'Figure9_AnalyteDetection_raw.svg');
print(fig, svgFile, '-dsvg', '-painters');

% MATLAB uses unitless dimensions in exported SVGs. Assign an explicit
% physical page size and preserve the internal drawing dimensions in the
% viewBox so Inkscape retains the intended 180 mm-wide artwork.
svgText = fileread(svgFile);
rootPattern = ['<svg(?<before>[^>]*)width="(?<width>[0-9.]+)" ' ...
               'height="(?<height>[0-9.]+)"(?<after>[^>]*)>'];
rootMatch = regexp(svgText, rootPattern, 'names', 'once');
oldRoot = regexp(svgText, rootPattern, 'match', 'once');
if isempty(rootMatch) || isempty(oldRoot)
    error('Could not identify the SVG root dimensions in %s.', svgFile)
end
newRoot = sprintf(['<svg%swidth="%.6gmm" height="%.6gmm" ' ...
                   'viewBox="0 0 %s %s"%s>'], ...
    rootMatch.before, figureWidthMm, figureHeightMm, ...
    rootMatch.width, rootMatch.height, rootMatch.after);
svgText = strrep(svgText, oldRoot, newRoot);

fid = fopen(svgFile, 'w');
if fid == -1
    error('Could not reopen %s to set its physical dimensions.', svgFile)
end
fileCleanup = onCleanup(@() fclose(fid));
fwrite(fid, svgText, 'char');
clear fileCleanup;
