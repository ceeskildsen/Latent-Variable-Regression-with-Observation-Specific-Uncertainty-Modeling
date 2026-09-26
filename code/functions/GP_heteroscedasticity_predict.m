function [mean_hat, CI, var_epistemic, var_aleatoric, var_total] = ...
        GP_heteroscedasticity_predict(model, x_test, alpha_error)
% GP_HETEROSCEDASTICITY_PREDICT Predict with a fitted heteroscedastic GP.
%
% INPUTS
%   model       : structure returned by GP_heteroscedasticity_fit.
%   x_test      : m-by-d predictors. For a univariate model, a vector is
%                 treated as m-by-1. For a multivariate model, a vector is
%                 treated as one observation containing d predictors.
%   alpha_error : optional significance level; default 0.05.
%
% OUTPUTS
%   mean_hat       : posterior mean on the original response scale.
%   CI             : two-sided confidence-interval half-width.
%   var_epistemic  : uncertainty in the estimated mean function.
%   var_aleatoric  : estimated input-dependent residual variance.
%   var_total      : var_epistemic + var_aleatoric.

    if nargin < 3 || isempty(alpha_error)
        alpha_error = 0.05;
    end
    if ~isscalar(alpha_error) || alpha_error <= 0 || alpha_error >= 1
        error('alpha_error must be a scalar strictly between zero and one.');
    end

    required = {'meanGP', 'varianceGP', 'nPredictors'};
    for i = 1:numel(required)
        if ~isfield(model, required{i})
            error('The fitted model is missing the field "%s".', required{i});
        end
    end

    x_test = validate_prediction_data(x_test, model.nPredictors);

    mean_gp = model.meanGP;
    x_mean_scaled = (x_test - mean_gp.x_mean) ./ mean_gp.x_std;
    K_star_mean = mean_gp.kernel(mean_gp.x_train, x_mean_scaled, mean_gp.theta_hat);

    mean_scaled = K_star_mean' * mean_gp.alpha;
    mean_hat = mean_scaled * mean_gp.y_std + mean_gp.y_mean;

    v_mean = mean_gp.L \ K_star_mean;
    var_epistemic_scaled = max(0, ...
        mean_gp.theta_hat(end-1)^2 - sum(v_mean.^2, 1)');
    var_epistemic = var_epistemic_scaled * mean_gp.y_std^2;

    variance_gp = model.varianceGP;
    x_variance_scaled = (x_test - variance_gp.x_mean) ./ variance_gp.x_std;
    K_star_variance = rbf_kernel_variance( ...
        variance_gp.x_train, x_variance_scaled, ...
        variance_gp.theta_hat, variance_gp.ard);

    g_mean = variance_gp.m0 + K_star_variance' * variance_gp.alpha_g;
    scaled_cross_covariance = variance_gp.sqrtW .* K_star_variance;
    v_variance = variance_gp.Lb \ scaled_cross_covariance;
    g_variance = max(0, variance_gp.sf2 - sum(v_variance.^2, 1)');

    % The variance GP is fitted to residuals on the original response scale.
    var_aleatoric = exp(g_mean + 0.5 * g_variance);
    var_aleatoric = max(var_aleatoric, eps);

    var_total = var_epistemic + var_aleatoric;
    z_score = norminv(1 - alpha_error / 2);
    CI = z_score .* sqrt(var_total);
end


function x = validate_prediction_data(x, n_predictors)
    x = double(x);
    if isempty(x)
        error('Prediction inputs must not be empty.');
    end

    if n_predictors == 1
        if ~isvector(x) && size(x, 2) ~= 1
            error('A univariate model requires one predictor column.');
        end
        if isvector(x)
            x = x(:);
        end
    elseif isvector(x)
        if numel(x) ~= n_predictors
            error('A multivariate prediction vector must contain one value per predictor.');
        end
        x = reshape(x, 1, n_predictors);
    elseif size(x, 2) ~= n_predictors
        error('Prediction inputs must have the same number of columns as the training inputs.');
    end

    if any(~isfinite(x), 'all')
        error('Prediction inputs must be finite.');
    end
end


function K = rbf_kernel_variance(xa, xb, theta, ard)
    if ard
        ell = theta(1:end-1)';
        xa_scaled = xa ./ ell;
        xb_scaled = xb ./ ell;
        squared_distance = pdist2(xa_scaled, xb_scaled, 'euclidean').^2;
    else
        ell = theta(1);
        squared_distance = pdist2(xa, xb, 'euclidean').^2 / ell^2;
    end
    K = theta(end)^2 .* exp(-0.5 .* squared_distance);
end
