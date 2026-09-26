% Figure3_PLS.m
% Fit a PLS model to the calibration data and generate Figure 3.
% Panel 1: Cross-validated MSE vs number of latent variables (LVs)
% Panel 2: Observed vs predicted calibration responses (color-coded by interferent)
% Panel 3: LV score plot (color-coded by interferent) with colorbar
%
% NOTE on panel sizing:
%   axis square can shrink axes differently depending on tick label extents.
%   A final equalization step enforces identical axes width/height for all panels.

%
% USAGE: From the project root, run('figures/Figure-3/code/Figure3_PLS.m').

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
% Load data
% --------------------------
load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'data_split.mat'),'Ycal');
load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'pls_model.mat'),'MSE_cv','yhat_cal','Iy','Iint','Tcal');

% --------------------------
% Figure 3
% --------------------------
% Prepare the figure at its intended double-column publication size.
figureWidthMm = 180;
figureHeightMm = 2.65 * 25.4;
fig = figure('Color','w', ...
    'Units','inches', ...
    'Position',[0, 0, figureWidthMm/25.4, figureHeightMm/25.4]);

% ==========================
% Panel 1: MSE vs number of LVs
% ==========================
ax1 = subplot(1,3,1);
bar(MSE_cv);
grid on;
axis square;
ylabel('Cross-validated MSE', ...
    'FontName','Arial','FontSize',8,'FontWeight','normal');
xlabel('Number of LVs', ...
    'FontName','Arial','FontSize',8,'FontWeight','normal');
xticks(ax1, 1:numel(MSE_cv));
xtickangle(ax1, 0);

% Adjust panel spacing.
pos = get(ax1,'Position'); pos(1) = pos(1) - 0.05;
set(ax1,'Position', pos);

% ==========================
% Panel 2: Observed vs predicted (calibration)
% ==========================
ax2 = subplot(1,3,2);
addpath(fullfile(projectRoot, 'code', 'functions'));
mycolor_scatter(Ycal(:,Iy), yhat_cal, Ycal(:,Iint));
axis square;
set(ax2,'XLim', [-0.01, 0.16], 'YLim', [-0.01, 0.16]);

hl = refline(ax2, 1, 0);
hl.Color = 'k';

xlabel('\ity\rm [w/w]', ...
    'Interpreter','tex','FontName','Arial','FontSize',8,'FontWeight','normal');
ylabel('\itŷ\rm [w/w]', ...
    'Interpreter','tex','FontName','Arial','FontSize',8,'FontWeight','normal');
xtickformat('%.2f'); ytickformat('%.2f');

% Adjust panel spacing.
pos = get(ax2,'Position'); pos(1) = pos(1) - 0.05;
set(ax2,'Position', pos);

% (Optional) hide axes toolbar overlay in exported SVGs
if isprop(ax2,'Toolbar')
    ax2.Toolbar.Visible = 'off';
end

% ==========================
% Panel 3: LV score plot with colorbar
% ==========================
axlim_T1 = [-600, 600];
axlim_T2 = axlim_T1;
ax3 = subplot(1,3,3);
pos = get(ax3,'Position'); % preserve panel position before plotting

mycolor_scatter(Tcal(:,1), Tcal(:,2), Ycal(:,Iint), 'cbar', ...
                min(Ycal(:,Iint)), max(Ycal(:,Iint)));

set(ax3,'Position', pos, 'XLim',axlim_T1,'YLim',axlim_T2, 'XTick',[-500,-250,0,250,500],'YTick',[-500,-250,0,250,500]);

axis square;
xlabel('LV1 score', ...
    'FontName','Arial','FontSize',8,'FontWeight','normal');
ylabel('LV2 score', ...
    'FontName','Arial','FontSize',8,'FontWeight','normal');
xtickangle(ax3, 0);

hcb = colorbar(ax3);
caxis(ax3, [min(Ycal(:,Iint)), max(Ycal(:,Iint))]);
set(ax3,'Position', pos);
hcb.TickLabels = compose('%.2f', hcb.Ticks);
ylabel(hcb, 'Interferent concentration [w/w]', ...
    'FontName','Arial','FontSize',8,'FontWeight','normal');

% Adjust panel spacing.
pos = get(ax3,'Position'); pos(1) = pos(1) - 0.05;
set(ax3,'Position', pos);

% --------------------------
% Equalize panel sizes (axis square can shrink panels differently)
% --------------------------
drawnow;

p1 = get(ax1,'Position');
p2 = get(ax2,'Position');
p3 = get(ax3,'Position');

w = min([p1(3) p2(3) p3(3)]);
h = min([p1(4) p2(4) p3(4)]);

p1(3:4) = [w h];
p2(3:4) = [w h];
p3(3:4) = [w h];

set(ax1,'Position',p1);
set(ax2,'Position',p2);
set(ax3,'Position',p3);

% Apply consistent publication typography to axes and colour bar.
set([ax1, ax2, ax3], ...
    'FontName','Arial', ...
    'FontSize',8, ...
    'FontWeight','normal');
set(hcb, ...
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
text(ax1, -0.12, 1.08, 'A', panelLabelArgs{:});
text(ax2, -0.12, 1.08, 'B', panelLabelArgs{:});
text(ax3, -0.12, 1.08, 'C', panelLabelArgs{:});

drawnow;

% --------------------------
% Export
% --------------------------
set(fig, 'Renderer', 'painters');
outdir = fullfile(projectRoot, 'figures', 'Figure-3', 'raw_figure');
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
svgFile = fullfile(outdir, 'Figure3_PLS_calibration_raw.svg');
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
