function mycolor(Xax,X,c,cbar,cmax)
%
% function mycolor(Xax,X,c,cbar,cmax)
%
% Input:
%   X           =   data matrix - rows colored by c
%   c           =   column vector (color scale)
%   Xax         =   scale for x-axis
%   cbar        =   optional colorbar flag or numeric color-scale range
%   cmax        =   optional numeric color-scale range
%
%
% Output:
%   color coded plot

% Carl Emil Eskildsen, 2011

% Make sure dimensions of the data match
if size(X,1) ~= size(c,1);
    error ('dimentions of X and Y do not match')
end

if size(c,2) ~= 1
    error('Y has to be a vector');
end

% Remove rows with NaN color values.

a = find(isnan(c));

if ~isempty(a)
    idx = true(size(c,1),1);
    idx(a) = false;

    X = X(idx,:);
    c = c(idx);
    %X = delsamps(X,a);
    %c = delsamps(c,a);
end
% Perform color coding.
cmap = colormap('jet');
% cmap = colormap('summer');
colormap(cmap);
maxCol = size(cmap,1)-1;


if nargin == 4 && isnumeric(cbar)
    cnew = c-min(c);        % Shift color values to start at zero
    cnew = cnew/cbar;       % Scale color values
    cnew = round(cnew*maxCol)+1;   % Convert color values to colormap indices
elseif (nargin == 5 && isnumeric(cmax))
    cnew = c-min(c);        % Shift color values to start at zero
    cnew = cnew/cmax;       % Scale color values
    cnew = round(cnew*maxCol)+1;   % Convert color values to colormap indices
else
    cnew = c-min(c);        % Shift color values to start at zero
    cnew = cnew/max(cnew);  % Scale color values to the observed range
    cnew = round(cnew*maxCol)+1;   % Convert color values to colormap indices
    
end



% Plot the spectra.
for i = 1:size(X,1);
    hold on;
    %     plot(Xax(i,:),X(i,:),'color',cnew(y(i),:));
    plot(Xax,X(i,:),'color',cmap(cnew(i),:),'linewidth',1);
end
not_so_tight('Y')


% colorbar
if nargin == 4 && ~isnumeric(cbar)
    colorbar
    caxis([min(c) max(c)]);
end

box on
hold off;
shg
