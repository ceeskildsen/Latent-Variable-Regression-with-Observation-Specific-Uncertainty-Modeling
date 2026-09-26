% Figure4_BiasVarianceMap.m
% Plot GP bias and total variance maps on precomputed grids and overlay
% validation scores. Point colors are independent of the contour colormaps.

%
% USAGE: From the project root, run('figures/Figure-4/code/Figure4_BiasVarianceMap.m').

close all; clear; clc;
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
load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'data_split.mat'),'Yval');
load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'pls_model.mat'),'Tval','Iint');
load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'gp_model_results.mat'), ...
    'E_e_hat_grid', 'Var_total_grid');

assert(size(Tval,1) == size(Yval,1), 'Tval and Yval must have the same number of rows.');

% --------------------------
% Axes limits matching the grid generated in code/Raman/GPmodel.m.
% --------------------------
axlim_T1 = [-600, 600];
axlim_T2 = axlim_T1;

% Small axis padding for nicer layout
padFrac = 0;
dx = diff(axlim_T1); dy = diff(axlim_T2);
axlim_T1_plot = axlim_T1 + [-padFrac*dx, +padFrac*dx];
axlim_T2_plot = axlim_T2 + [-padFrac*dy, +padFrac*dy];

% Grid axes that MATCH the stored grid size
nx = size(E_e_hat_grid, 2);
ny = size(E_e_hat_grid, 1);
T1_range = linspace(axlim_T1(1), axlim_T1(2), nx);
T2_range = linspace(axlim_T2(1), axlim_T2(2), ny);
[T1g, T2g] = meshgrid(T1_range, T2_range);


m = 256; % colormap resolution (fixed)

% --------------------------
% Point color scale
% --------------------------
c = Yval(:,Iint);
cmin = min(c); cmax = max(c);
if cmax == cmin
    t = 0.5 * ones(size(c));
else
    t = (c - cmin) ./ (cmax - cmin);
end
idx = max(1, min(m, round(t*(m-1)) + 1));

cmapPts = flipud(pink(m));
rgbPts  = cmapPts(idx,:);

% --------------------------
% Convex hull used for color-axis scaling
% --------------------------
k = convhull(Tval(:,1), Tval(:,2));
xh = Tval(k,1);
yh = Tval(k,2);

% Expanded hull coordinates are retained for optional display masking.
hullExpandFactor = 1.40;
ctrx = mean(xh(1:end-1));  % last point repeats first
ctry = mean(yh(1:end-1));

xh_exp = ctrx + hullExpandFactor * (xh - ctrx);
yh_exp = ctry + hullExpandFactor * (yh - ctry);

inHullCore = inpolygon(T1g, T2g, xh,     yh);      % for caxis stats
inHullExp  = inpolygon(T1g, T2g, xh_exp, yh_exp);

% --------------------------
% Figure
% --------------------------
% Prepare the figure at its intended double-column publication size.
figureWidthMm = 180;
figureHeightMm = 105;
fig = figure('Color','w', ...
    'Units','inches', ...
    'Position',[0, 0, figureWidthMm/25.4, figureHeightMm/25.4]);

% ==========================
% Panel 1: Bias map
% ==========================
h1 = subplot(1,2,1);

Zb = E_e_hat_grid;

% Plot
if any(isfinite(Zb(:)))
    [~, hf] = contourf(T1_range, T2_range, Zb, 50);
    hf.LineColor = 'none';
else
    imagesc(T1_range, T2_range, zeros(size(Zb)));
    set(gca,'YDir','normal');
end
axis square; hold on;

colormap(h1, jet(m));

addpath(fullfile(projectRoot, 'code', 'functions'));
mycolor_scatter(Tval(:,1), Tval(:,2), Yval(:,Iint), ...
                min(Yval(:,Iint)), max(Yval(:,Iint)));

set(h1, 'XLim', axlim_T1_plot, 'YLim', axlim_T2_plot, ...
    'XTick',[-500, -250, 0, 250, 500], ...
    'YTick',[-500, -250, 0, 250, 500]);
xlabel(h1, 'LV1 score', ...
    'FontName','Arial','FontSize',8,'FontWeight','normal');
ylabel(h1, 'LV2 score', ...
    'FontName','Arial','FontSize',8,'FontWeight','normal');
xtickangle(h1, 0);
grid on; box on;

% Symmetric caxis around 0 using ORIGINAL hull values only
Zb_core = E_e_hat_grid;
coreVals = Zb_core(inHullCore & isfinite(Zb_core));
if ~isempty(coreVals)
    maxAbs = max(abs(coreVals));
    if maxAbs <= 0, maxAbs = 1; end
    caxis(h1, [-maxAbs, +maxAbs]);
end

hcb1 = colorbar('southoutside');
xlabel(hcb1, 'Expected prediction error [w/w]', ...
    'FontName','Arial','FontSize',8,'FontWeight','normal');
ticks = [-0.003, 0, 0.003];
set(hcb1,'Ticks', ticks);
% ==========================
% Panel 2: Variance map
% ==========================
h2 = subplot(1,2,2);

Zv = Var_total_grid;

if any(isfinite(Zv(:)))
    [~, hf] = contourf(T1_range, T2_range, Zv, 50);
    hf.LineColor = 'none';
else
    imagesc(T1_range, T2_range, zeros(size(Zv)));
    set(gca,'YDir','normal');
end
axis square; hold on;

% Custom colormap for variance
fullMap = cool(m);
cutFraction = 0.2;
startIdx = max(1, round(cutFraction * m));
upperMap = fullMap(startIdx:end, :);

xOrig = linspace(0, 1, size(upperMap,1));
xQ    = linspace(0, 1, m);
interpMap = interp1(xOrig, upperMap, xQ);

hsvMap = rgb2hsv(interpMap);
nDark = max(1, round(0.1 * m));
scaleVals = flipud(linspace(0.9, 1, nDark)');
scaleVals = [scaleVals; repmat(scaleVals(end), m - nDark, 1)];
hsvMap(:,3) = hsvMap(:,3) .* scaleVals;

customMap = hsv2rgb(hsvMap);
colormap(h2, customMap);

addpath(fullfile(projectRoot, 'code', 'functions'));
mycolor_scatter(Tval(:,1), Tval(:,2), Yval(:,Iint), ...
                min(Yval(:,Iint)), max(Yval(:,Iint)));


set(h2, 'XLim', axlim_T1_plot, 'YLim', axlim_T2_plot, ...
    'XTick',[-500, -250, 0, 250, 500], ...
    'YTick',[-500, -250, 0, 250, 500]);
xlabel(h2, 'LV1 score', ...
    'FontName','Arial','FontSize',8,'FontWeight','normal');
ylabel(h2, 'LV2 score', ...
    'FontName','Arial','FontSize',8,'FontWeight','normal');
xtickangle(h2, 0);
grid on; box on;

% caxis for variance based on ORIGINAL hull values only (non-symmetric)
Zv_core = Var_total_grid;
coreV = Zv_core(inHullCore & isfinite(Zv_core));
if ~isempty(coreV)
    vmin = min(coreV); vmax = max(coreV);
    if vmax <= vmin, vmax = vmin + eps; end
    caxis(h2, [vmin vmax]);
end

hcb2 = colorbar('southoutside');
xlabel(hcb2, 'Total prediction-error variance [(w/w)^2]', ...
    'Interpreter','tex', ...
    'FontName','Arial','FontSize',8,'FontWeight','normal');
ticks = [0.000002, 0.000003, 0.000004];
set(hcb2,'Ticks', ticks);

% Apply consistent publication typography to axes and colour bars.
set([h1, h2], ...
    'FontName','Arial', ...
    'FontSize',8, ...
    'FontWeight','normal');
set([hcb1, hcb2], ...
    'FontName','Arial', ...
    'FontSize',8, ...
    'FontWeight','normal');

% Panel labels. Clipping is disabled so the labels can sit just outside the
% upper-left corner of each plotting area.
panelLabelArgs = {'Units','normalized', ...
    'FontName','Arial', ...
    'FontSize',18, ...
    'FontWeight','bold', ...
    'HorizontalAlignment','left', ...
    'VerticalAlignment','bottom', ...
    'Clipping','off'};
text(h1, -0.12, 1.06, 'A', panelLabelArgs{:});
text(h2, -0.12, 1.06, 'B', panelLabelArgs{:});

% --------------------------
% Export (R2022a-safe)
% --------------------------
set(fig, 'Renderer', 'painters');
set(fig, 'InvertHardcopy', 'off');
drawnow;

outdir = fullfile(projectRoot, 'figures', 'Figure-4', 'raw_figure');
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
svgFile = fullfile(outdir, 'Figure4_BiasVarianceMap_raw.svg');
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
