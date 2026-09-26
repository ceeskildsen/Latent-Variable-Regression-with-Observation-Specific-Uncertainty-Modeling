function X_cleaned = remove_spikes(X, ID)
%REMOVE_SPIKES Removes cosmic spikes from Raman spectra using PCA residuals
%
%   X_cleaned = REMOVE_SPIKES(X, ID) identifies and replaces cosmic spikes
%   (outliers) in Raman spectra. Spike detection is based on PCA residuals
%   computed within replicate groups (as defined by ID). Outliers are
%   replaced by local NaNs and imputed using the group’s PCA model.
%
%   Inputs:
%     X   - [N x M] matrix of Raman spectra (N samples, M variables)
%     ID  - [N x 1] vector of sample group labels (same group => replicates)
%
%   Output:
%     X_cleaned - [N x M] matrix, with spikes replaced by PCA-estimated values
%
%   Method:
%     - Performs PCA (LV = 1) on each sample group (same ID)
%     - Computes PCA residuals and flags outliers > 5×SD per variable
%     - Affected regions (±5 variables) are set to NaN
%     - Missing values are imputed using the group’s PCA model
%
%   Dependencies:
%     Requires a function 'nipals_pca' for single-component PCA
%
%   Author: Carl Emil Aae Eskildsen, 2025
%   License: MIT

% Parameters
LV = 1; % Number of latent variables for PCA
window_half = 5; % How many variables on either side to set as NaN

% Initialization
uID = unique(ID);                % Unique group labels (replicates)
num_samples = numel(uID);        % Number of groups
X_cleaned = X;                   % Output: cleaned spectra

for n = 1:num_samples
    Idx = ismember(ID, uID(n));      % Logical index for group n
    Xtemp = X_cleaned(Idx, :);       % Extract spectra for group
    [T, P, ~] = nipals_pca(Xtemp, LV); % PCA on group (1 LV)
    E = Xtemp - (T * P');            % PCA residuals

    % Outlier detection: threshold = 5×SD for each variable (column)
    threshold = 5 * std(E, 0, 1);
    [row_idx, col_idx] = find(abs(E) > threshold);

    % If no outliers, continue to next group
    if isempty(row_idx)
        continue;
    end

    % Replace spikes ±window_half with NaN for robust imputation
    for i = 1:length(row_idx)
        r = row_idx(i);
        c = col_idx(i);
        idx_c = max(1, c-window_half):min(size(X_cleaned, 2), c+window_half);
        Xtemp(r, idx_c) = NaN;
    end

    % Impute missing values (NaNs) using PCA model for group
    nan_idx = isnan(Xtemp);
    if any(nan_idx, 'all')
        [Ttemp, Ptemp, ~] = nipals_pca(Xtemp, LV);
        Xhat = Ttemp * Ptemp';
        Xtemp(nan_idx) = Xhat(nan_idx);
    end

    % Update cleaned spectra
    X_cleaned(Idx, :) = Xtemp;
end

end
