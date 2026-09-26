function not_so_tight(ax_tight)
% not_so_tight adds a small margin around the current axis limits.
% An optional input keeps either the x-axis or y-axis tight.
% With no input, both axes receive padding.
%
% Input:
%       ax_tight: X | Y

% Carl Emil Eskildsen

if nargin == 0;
    ax_tight = 'none';
end
ax_tight = upper(ax_tight);

axis tight              % set tight axes, in order to get the data limits
a = axis;

dx = a(2)-a(1);         % the range of x data
dy = a(4)-a(3);         % ditto y axis


w = 0.05;               % percentage of axis range to be added

% Adjust the ranges.
if ax_tight ~= 'Y'
    a(1) = a(1) - w*dx;
    a(2) = a(2) + w*dx;
end

if ax_tight ~= 'X'
    a(3) = a(3) - w*dy;
    a(4) = a(4) + w*dy;
end

axis(a);                % set the new ranges
end
