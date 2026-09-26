% uncertainty_evaluation_AqSolDB.m
% Evaluate GP and OLS prediction-error variance estimates for AqSolDB.

clear; clc;

scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(scriptDir));
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    projectRoot = pwd;
end
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    error('Project root could not be resolved. Set the MATLAB current folder to the project root and run the script again.');
end

load(fullfile(projectRoot, 'data', 'AqSolDB', 'analysis_data', 'pls_model_AqSolDB.mat'), ...
    'e_test', 'yhat_cal', 'Tcal', 'Ttest', 'MSE_cv', 'LV');
load(fullfile(projectRoot, 'data', 'AqSolDB', 'analysis_data', 'gp_model_AqSolDB.mat'), ...
    'E_e_test_hat', 'Var_total_test_hat');

N_cal = size(yhat_cal, 1);
G = Tcal' * Tcal;
Var_e_test_OLS = ((1 + 1/N_cal) + diag(Ttest / G * Ttest')) * MSE_cv(LV);

Var_total_test_hat = max(Var_total_test_hat, eps);
Var_e_test_OLS = max(Var_e_test_OLS, eps);

sigma_GP = sqrt(Var_total_test_hat);
sigma_OLS = sqrt(Var_e_test_OLS);
z_GP = (e_test - E_e_test_hat) ./ sigma_GP;
z_OLS = e_test ./ sigma_OLS;

nominal_levels = [0.10, 0.20, 0.30, 0.40, 0.50, ...
    0.60, 0.70, 0.80, 0.90, 0.95, 0.99];
empirical_GP = nan(size(nominal_levels));
empirical_OLS = nan(size(nominal_levels));

for k = 1:numel(nominal_levels)
    z_crit = norminv(0.5 + nominal_levels(k)/2);
    empirical_GP(k) = mean(abs(z_GP) <= z_crit);
    empirical_OLS(k) = mean(abs(z_OLS) <= z_crit);
end

CRPS_GP = crps_gaussian(e_test, E_e_test_hat, sigma_GP);
CRPS_OLS = crps_gaussian(e_test, zeros(size(e_test)), sigma_OLS);

mean_CRPS_GP = mean(CRPS_GP);
mean_CRPS_OLS = mean(CRPS_OLS);
mean_variance_GP = mean(Var_total_test_hat);
mean_variance_OLS = mean(Var_e_test_OLS);
median_variance_GP = median(Var_total_test_hat);
median_variance_OLS = median(Var_e_test_OLS);
std_variance_GP = std(Var_total_test_hat);
std_variance_OLS = std(Var_e_test_OLS);

outdir = fullfile(projectRoot, 'data', 'AqSolDB', 'analysis_data');
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
outfile = fullfile(outdir, 'uncertainty_evaluation_results_AqSolDB.mat');
save(outfile, 'Var_total_test_hat', 'Var_e_test_OLS', ...
    'sigma_GP', 'sigma_OLS', 'z_GP', 'z_OLS', ...
    'nominal_levels', 'empirical_GP', 'empirical_OLS', ...
    'CRPS_GP', 'CRPS_OLS', ...
    'mean_CRPS_GP', 'mean_CRPS_OLS', ...
    'mean_variance_GP', 'mean_variance_OLS', ...
    'median_variance_GP', 'median_variance_OLS', ...
    'std_variance_GP', 'std_variance_OLS');

fprintf('\n--- AqSolDB uncertainty evaluation ---\n');
fprintf('Mean CRPS (GP):  %.4f\n', mean_CRPS_GP);
fprintf('Mean CRPS (OLS): %.4f\n', mean_CRPS_OLS);
fprintf('Results saved to: %s\n', outfile);

function C = crps_gaussian(y, mu, sigma)
z = (y - mu) ./ sigma;
C = sigma .* (z .* (2*normcdf(z) - 1) + 2*normpdf(z) - 1/sqrt(pi));
end
