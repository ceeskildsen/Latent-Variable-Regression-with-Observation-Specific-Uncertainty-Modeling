function h = mycolor_scatter(x, y, c, varargin)
% mycolor_scatter(x,y,c)
% mycolor_scatter(x,y,c,cmax)                 % (legacy) scale using [min(c), min(c)+cmax]
% mycolor_scatter(x,y,c,cmin,cmax)            % explicit [cmin,cmax] for color coding
% mycolor_scatter(x,y,c,'cbar',...)           % optional: add colorbar for the SCATTER (will set colormap/caxis)
%
% NOTE (important): By default (no 'cbar'), this function does NOT touch the
% axes colormap or caxis (so it plays nicely on top of contourf, etc.).
%
% Carl Emil Eskildsen, 2011 (updated)

% --- ensure column vectors ---
x = x(:); y = y(:); c = c(:);

% --- dimension check ---
if numel(x) ~= numel(y) || numel(x) ~= numel(c)
    error('Dimensions of x, y and c do not match');
end

ax = gca;

% --- parse optional inputs ---
showCbar = false;
args = varargin;

if ~isempty(args) && (ischar(args{1}) || isstring(args{1}) || islogical(args{1}))
    showCbar = true;
    args = args(2:end);
end

cmin_data = min(c,[],'omitnan');
cmax_data = max(c,[],'omitnan');
if ~isfinite(cmin_data) || ~isfinite(cmax_data)
    cmin_data = 0; cmax_data = 1;
end

% Determine color limits used ONLY for the scatter coloring (clim)
if isempty(args)
    clim = [cmin_data, cmax_data];
elseif numel(args) == 1 && isnumeric(args{1}) && isscalar(args{1})
    % legacy: interpret scalar as "range width from min(c)"
    cmax = args{1};
    clim = [cmin_data, cmin_data + cmax];
elseif numel(args) == 2 && isnumeric(args{1}) && isnumeric(args{2}) && isscalar(args{1}) && isscalar(args{2})
    % NEW: explicit [cmin cmax]
    clim = [args{1}, args{2}];
else
    error('Invalid optional inputs. Use: (cmax), (cmin,cmax), or (''cbar'',...).');
end

if clim(2) <= clim(1)
    clim = [clim(1), clim(1) + eps];
end

% --- build custom pink colormap WITHOUT setting global colormap ---
m = size(colormap(ax), 1);
if isempty(m) || m < 2
    m = 64;
end

fullpink = flipud(pink(m));

cutFraction = 0.7;
startIdx = max(2, round(cutFraction * m));
upperpink = fullpink(1:startIdx, :);

xOriginal   = linspace(0, 1, size(upperpink, 1));
xQuery      = linspace(0, 1, m);
newColormap = interp1(xOriginal, upperpink, xQuery);

hsvMap = rgb2hsv(flipud(newColormap));
hsvMap(:,3) = hsvMap(:,3) * 0.8;          % darken
cmap = flipud(hsv2rgb(hsvMap));           % m-by-3
% cmap = colormap('jet');
% cmap = colormap('cool');
% cmap = colormap;
% cmap = colormap('gray');
% cmap = 1-cmap;
% cmap = flipud(colormap('summer'));
% cmap = flipud(colormap('copper'));
% cmap = flipud(colormap('spring'));


% --- map c -> RGB (truecolor), clamped to [cmin,cmax] ---
c_clamped = min(max(c, clim(1)), clim(2));
t = (c_clamped - clim(1)) ./ (clim(2) - clim(1) + eps);
idx = floor(t * (m-1)) + 1;
idx = min(max(idx,1),m);

rgb = cmap(idx, :);  % N-by-3 truecolor

% --- plot, preserving hold state ---
wasHold = ishold(ax);
hold(ax, 'on');

h = scatter(ax, x, y, 25, rgb, 'filled', ...
    'MarkerEdgeColor', 'k');

grid(ax, 'on');
box(ax, 'on');

if ~wasHold
    hold(ax, 'off');
end

% --- optional: add colorbar FOR THE SCATTER (will set axis colormap/caxis) ---
if showCbar
    colormap(ax, cmap);
    caxis(ax, clim);
    colorbar(ax);
end

shg
end
