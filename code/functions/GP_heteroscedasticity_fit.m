function model = GP_heteroscedasticity_fit(x, y_raw, kernel_main, opts_mean, opts_variance)
% GP_HETEROSCEDASTICITY_FIT Fit a two-stage heteroscedastic GP model.
%
% The first GP estimates the conditional mean of y and its epistemic
% uncertainty. The second GP models the input-dependent residual variance
% using a GP prior on g(x) = log(sigma^2(x)) and a Laplace approximation.
%
% INPUTS
%   x             : n-by-d predictors. A vector is treated as n-by-1.
%   y_raw         : n-by-1 responses.
%   kernel_main   : mean-GP covariance function with signature
%                   K = kernel_main(x1, x2, theta), where theta ends in
%                   [signal standard deviation; noise standard deviation].
%                   Pass [] to use the internal RBF kernel.
%   opts_mean     : optional structure controlling the mean GP.
%   opts_variance : optional structure controlling the variance GP.
%
% OUTPUT
%   model : fitted model for use with GP_heteroscedasticity_predict.
%
% The implementation supports both univariate and multivariate predictors.

    if nargin < 4 || isempty(opts_mean), opts_mean = struct(); end
    if nargin < 5 || isempty(opts_variance), opts_variance = struct(); end

    [x, y_raw] = validate_training_data(x, y_raw);
    d = size(x, 2);

    if ~isfield(opts_mean, 'ard')
        opts_mean.ard = d > 1;
    end
    if ~isfield(opts_variance, 'ard')
        opts_variance.ard = d > 1;
    end

    if nargin < 3 || isempty(kernel_main)
        use_ard = opts_mean.ard;
        kernel_main = @(xa, xb, theta) rbf_kernel_mean(xa, xb, theta, use_ard);
    end

    mean_gp = fit_mean_gp(x, y_raw, kernel_main, opts_mean);
    variance_gp = fit_variance_gp(x, y_raw, mean_gp, opts_variance);

    model.meanGP = mean_gp;
    model.varianceGP = variance_gp;
    model.nPredictors = d;
    model.options.mean = opts_mean;
    model.options.variance = opts_variance;
end


function [x, y] = validate_training_data(x, y)
    x = double(x);
    y = double(y(:));

    if isempty(x) || isempty(y)
        error('Training predictors and responses must not be empty.');
    end

    if isvector(x)
        if numel(x) == numel(y)
            x = x(:);
        elseif numel(y) == 1
            x = reshape(x, 1, []);
        else
            error('A predictor vector must contain one value per response.');
        end
    end

    if size(x, 1) ~= numel(y)
        error('The number of predictor rows must equal the number of responses.');
    end
    if size(x, 1) < 2
        error('At least two training observations are required.');
    end
    if any(~isfinite(x), 'all') || any(~isfinite(y))
        error('Training predictors and responses must be finite.');
    end
end


function gp = fit_mean_gp(x, y_raw, kernel, opts)
    if ~isfield(opts, 'nStarts'),        opts.nStarts = 1;          end
    if ~isfield(opts, 'startLogSpread'), opts.startLogSpread = 0.7; end
    if ~isfield(opts, 'seed'),           opts.seed = [];            end
    if ~isfield(opts, 'display'),        opts.display = 'off';      end
    if ~isfield(opts, 'maxEvals'),       opts.maxEvals = 2000;      end
    if ~isfield(opts, 'ellMinAbs'),      opts.ellMinAbs = 0.05;     end
    if ~isfield(opts, 'ellMinFactor'),   opts.ellMinFactor = 0.5;   end
    if ~isfield(opts, 'snMin'),          opts.snMin = 1e-6;         end

    if ~isempty(opts.seed), rng(opts.seed); end

    n = size(x, 1);
    d = size(x, 2);

    gp.x_mean = mean(x, 1);
    gp.x_std = std(x, 0, 1);
    gp.x_std(gp.x_std <= 0) = 1;
    x_scaled = (x - gp.x_mean) ./ gp.x_std;

    gp.y_mean = mean(y_raw);
    y_centered = y_raw - gp.y_mean;
    gp.y_std = std(y_centered);
    if gp.y_std <= 0
        error('Responses have zero variance; the mean GP cannot be fitted.');
    end
    y_scaled = y_centered / gp.y_std;

    gp.x_train = x_scaled;
    gp.kernel = kernel;
    gp.ard = logical(opts.ard);

    if isfield(opts, 'theta0') && ~isempty(opts.theta0)
        theta0 = opts.theta0(:);
    else
        theta0 = default_mean_theta(x_scaled, opts.seed, opts.ard);
    end

    expected_theta_count = 3;
    if opts.ard
        expected_theta_count = d + 2;
    end
    if numel(theta0) ~= expected_theta_count
        error('The mean-GP initial parameter vector has the wrong length.');
    end

    lower_lim = 1e-6 * ones(expected_theta_count, 1);
    upper_lim = 1e6 * ones(expected_theta_count, 1);

    if opts.ard
        ell_min = mean_lengthscale_lower_bound(x_scaled, true, opts);
        lower_lim(1:d) = max(lower_lim(1:d), ell_min(:));
    else
        ell_min = mean_lengthscale_lower_bound(x_scaled, false, opts);
        lower_lim(1) = max(lower_lim(1), ell_min);
    end
    lower_lim(end) = max(lower_lim(end), opts.snMin);

    starts = zeros(expected_theta_count, opts.nStarts);
    starts(:, 1) = theta0;
    for k = 2:opts.nStarts
        starts(:, k) = theta0 .* exp(opts.startLogSpread * randn(expected_theta_count, 1));
    end
    starts = max(starts, lower_lim);
    starts = min(starts, upper_lim);

    fmin_opts = optimoptions('fmincon', 'Algorithm', 'sqp', ...
        'Display', opts.display, ...
        'MaxFunctionEvaluations', opts.maxEvals);

    objective = @(theta) mean_negative_log_likelihood( ...
        theta, x_scaled, y_scaled, kernel);

    best_value = inf;
    best_theta = theta0;
    for k = 1:opts.nStarts
        try
            theta_k = fmincon(objective, starts(:, k), [], [], [], [], ...
                lower_lim, upper_lim, [], fmin_opts);
            value_k = objective(theta_k);
            if value_k < best_value
                best_value = value_k;
                best_theta = theta_k;
            end
        catch
            % Ignore failed starts and retain the best successful result.
        end
    end

    if ~isfinite(best_value)
        best_value = objective(best_theta);
    end

    gp.theta_hat = best_theta;
    gp.nlml_best = best_value;

    K_signal = kernel(x_scaled, x_scaled, best_theta);
    K = K_signal + eye(n) * best_theta(end)^2;
    gp.L = chol(K + eye(n) * 1e-6, 'lower');
    gp.alpha = gp.L' \ (gp.L \ y_scaled);
end


function value = mean_negative_log_likelihood(theta, x, y, kernel)
    n = size(x, 1);
    K_signal = kernel(x, x, theta);
    K = K_signal + eye(n) * theta(end)^2;
    L = chol(K + eye(n) * 1e-6, 'lower');
    alpha = L' \ (L \ y);
    value = 0.5 * (y' * alpha) + sum(log(diag(L))) + 0.5 * n * log(2 * pi);
end


function theta0 = default_mean_theta(x_scaled, seed, ard)
    if ~isempty(seed), rng(seed); end

    xs = unique(x_scaled, 'rows', 'stable');
    n = size(xs, 1);
    if n > 2000
        xs = xs(randperm(n, 2000), :);
    end

    d = size(xs, 2);
    sf0 = 1;
    sn0 = 0.1;

    if ard
        ell0 = ones(d, 1);
        for j = 1:d
            differences = diff(sort(unique(xs(:, j))));
            differences = differences(differences > 1e-12);
            if ~isempty(differences)
                ell0(j) = median(differences);
            end
            if ~isfinite(ell0(j)) || ell0(j) <= 0
                ell0(j) = 1;
            end
        end
    else
        distances = pdist(xs, 'euclidean');
        distances = distances(distances > 1e-12);
        if isempty(distances)
            ell0 = 1;
        else
            ell0 = median(distances);
        end
        if ~isfinite(ell0) || ell0 <= 0
            ell0 = 1;
        end
    end

    theta0 = [ell0; sf0; sn0];
end


function ell_min = mean_lengthscale_lower_bound(x_scaled, ard, opts)
    xs = unique(x_scaled, 'rows', 'stable');
    d = size(xs, 2);

    if ard
        ell_min = zeros(d, 1);
        for j = 1:d
            differences = diff(sort(unique(xs(:, j))));
            differences = differences(differences > 1e-12);
            if isempty(differences)
                spacing = 1;
            else
                spacing = median(differences);
            end
            ell_min(j) = max(opts.ellMinAbs, opts.ellMinFactor * spacing);
        end
    else
        distances = pdist(xs, 'euclidean');
        distances = distances(distances > 1e-12);
        if isempty(distances)
            spacing = 1;
        else
            spacing = prctile(distances, 10);
        end
        ell_min = max(opts.ellMinAbs, opts.ellMinFactor * spacing);
    end
end


function vgp = fit_variance_gp(x, y_raw, mean_gp, opts)
    if ~isfield(opts, 'nStarts'),        opts.nStarts = 10;          end
    if ~isfield(opts, 'startLogSpread'), opts.startLogSpread = 0.7;  end
    if ~isfield(opts, 'seed'),           opts.seed = [];             end
    if ~isfield(opts, 'display'),        opts.display = 'off';       end
    if ~isfield(opts, 'maxEvals'),       opts.maxEvals = 200;        end
    if ~isfield(opts, 'maxIterLap'),     opts.maxIterLap = 50;       end
    if ~isfield(opts, 'tolLap'),         opts.tolLap = 1e-6;         end
    if ~isfield(opts, 'jitterK'),        opts.jitterK = 1e-8;        end
    if ~isfield(opts, 'epsR2'),          opts.epsR2 = 1e-12;         end
    if ~isfield(opts, 'gMin'),           opts.gMin = log(1e-12);     end
    if ~isfield(opts, 'gMax'),           opts.gMax = log(1e6);       end
    if ~isfield(opts, 'ellMin'),         opts.ellMin = 0.05;         end
    if ~isfield(opts, 'ellMax'),         opts.ellMax = 50;           end
    if ~isfield(opts, 'sfMin'),          opts.sfMin = 1e-3;          end
    if ~isfield(opts, 'sfMax'),          opts.sfMax = 1e3;           end

    if ~isempty(opts.seed), rng(opts.seed, 'twister'); end

    [~, d] = size(x);
    vgp.x_mean = mean(x, 1);
    vgp.x_std = std(x, 0, 1);
    vgp.x_std(vgp.x_std <= 0) = 1;
    x_scaled = (x - vgp.x_mean) ./ vgp.x_std;
    vgp.x_train = x_scaled;
    vgp.ard = logical(opts.ard);

    mean_hat = predict_mean_only(mean_gp, x);
    residuals = y_raw - mean_hat;
    vgp.r_train = residuals;

    residuals_squared = residuals.^2 + opts.epsR2;
    vgp.m0 = log(median(residuals_squared));

    if opts.ard
        theta0 = [ones(d, 1); 1];
        lower_lim = [expand_bound(opts.ellMin, d); opts.sfMin];
        upper_lim = [expand_bound(opts.ellMax, d); opts.sfMax];
    else
        theta0 = [1; 1];
        lower_lim = [opts.ellMin(1); opts.sfMin];
        upper_lim = [opts.ellMax(1); opts.sfMax];
    end

    n_parameters = numel(theta0);
    starts = zeros(n_parameters, opts.nStarts);
    starts(:, 1) = theta0;
    for k = 2:opts.nStarts
        starts(:, k) = theta0 .* exp(opts.startLogSpread * randn(n_parameters, 1));
    end
    starts = max(starts, lower_lim);
    starts = min(starts, upper_lim);

    fmin_opts = optimoptions('fmincon', 'Algorithm', 'sqp', ...
        'Display', opts.display, ...
        'MaxFunctionEvaluations', opts.maxEvals);

    objective = @(theta) variance_negative_log_evidence( ...
        theta, x_scaled, residuals, vgp.m0, opts.ard, opts);

    best_value = inf;
    best_theta = theta0;
    best_cache = [];
    for k = 1:opts.nStarts
        try
            theta_k = fmincon(objective, starts(:, k), [], [], [], [], ...
                lower_lim, upper_lim, [], fmin_opts);
            [value_k, cache_k] = objective(theta_k);
            if value_k < best_value
                best_value = value_k;
                best_theta = theta_k;
                best_cache = cache_k;
            end
        catch
            % Ignore failed starts and retain the best successful result.
        end
    end

    if isempty(best_cache)
        [best_value, best_cache] = objective(best_theta);
    end

    vgp.theta_hat = best_theta;
    vgp.nlZ_best = best_value;
    vgp.g_hat = best_cache.g_hat;
    vgp.sqrtW = best_cache.sqrtW;
    vgp.Lb = best_cache.Lb;
    vgp.alpha_g = best_cache.alpha_g;
    vgp.sf2 = best_cache.sf2;
end


function y_hat = predict_mean_only(gp, x_test)
    x_scaled = (x_test - gp.x_mean) ./ gp.x_std;
    K_star = gp.kernel(gp.x_train, x_scaled, gp.theta_hat);
    y_hat_scaled = K_star' * gp.alpha;
    y_hat = y_hat_scaled * gp.y_std + gp.y_mean;
end


function values = expand_bound(value, d)
    if isscalar(value)
        values = repmat(value, d, 1);
    elseif numel(value) == d
        values = value(:);
    else
        error('Lengthscale bounds must be scalar or contain one value per predictor.');
    end
end


function [nlZ, cache] = variance_negative_log_evidence(theta, x, residuals, m0, ard, opts)
    n = size(x, 1);
    K = rbf_kernel_variance(x, x, theta, ard) + opts.jitterK * eye(n);
    Lk = chol(K, 'lower');

    g = m0 * ones(n, 1);
    log_posterior = variance_log_posterior(g, residuals, m0, Lk);

    for iteration = 1:opts.maxIterLap
        alpha_g = Lk' \ (Lk \ (g - m0));
        exp_negative_g = exp(-g);
        likelihood_gradient = -0.5 * (1 - residuals.^2 .* exp_negative_g);
        W = 0.5 * residuals.^2 .* exp_negative_g;
        sqrtW = sqrt(max(W, 0));

        B = eye(n) + (sqrtW * sqrtW') .* K;
        Lb = chol(B, 'lower');

        gradient = -alpha_g + likelihood_gradient;
        K_gradient = K * gradient;
        scaled_gradient = sqrtW .* K_gradient;
        v = Lb \ scaled_gradient;
        w = Lb' \ v;
        delta = K_gradient - K * (sqrtW .* w);

        if max(abs(delta)) < opts.tolLap
            break;
        end

        step = 1;
        g_new = clamp_g(g + step * delta, opts);
        new_log_posterior = variance_log_posterior(g_new, residuals, m0, Lk);
        while ~isfinite(new_log_posterior) || new_log_posterior < log_posterior
            step = step / 2;
            if step < 1e-6
                break;
            end
            g_new = clamp_g(g + step * delta, opts);
            new_log_posterior = variance_log_posterior(g_new, residuals, m0, Lk);
        end

        g = g_new;
        log_posterior = new_log_posterior;
    end

    alpha_g = Lk' \ (Lk \ (g - m0));
    W = 0.5 * residuals.^2 .* exp(-g);
    sqrtW = sqrt(max(W, 0));
    B = eye(n) + (sqrtW * sqrtW') .* K;
    Lb = chol(B, 'lower');

    log_likelihood = sum(-0.5 * (g + residuals.^2 .* exp(-g)));
    quadratic_term = 0.5 * (g - m0)' * alpha_g;
    log_determinant_B = 2 * sum(log(diag(Lb)));
    nlZ = quadratic_term - log_likelihood + 0.5 * log_determinant_B;

    if ~isfinite(nlZ)
        nlZ = 1e12;
    end

    cache.g_hat = g;
    cache.sqrtW = sqrtW;
    cache.Lb = Lb;
    cache.alpha_g = alpha_g;
    cache.sf2 = theta(end)^2;
end


function value = variance_log_posterior(g, residuals, m0, Lk)
    alpha_g = Lk' \ (Lk \ (g - m0));
    prior = -0.5 * (g - m0)' * alpha_g;
    likelihood = sum(-0.5 * (g + residuals.^2 .* exp(-g)));
    value = prior + likelihood;
end


function g = clamp_g(g, opts)
    g = min(max(g, opts.gMin), opts.gMax);
end


function K = rbf_kernel_mean(xa, xb, theta, ard)
    if ard
        ell = theta(1:end-2)';
        xa_scaled = xa ./ ell;
        xb_scaled = xb ./ ell;
        squared_distance = pdist2(xa_scaled, xb_scaled, 'euclidean').^2;
    else
        ell = theta(1);
        squared_distance = pdist2(xa, xb, 'euclidean').^2 / ell^2;
    end
    K = theta(end-1)^2 .* exp(-0.5 .* squared_distance);
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
