% GPmodel_AqSolDB.m
% Fit GP mean model (bias) and heteroscedastic variance model on AqSolDB
% Uses validation set for GP training, then evaluates on test set
%
% Follows the same workflow as GPmodel.m for spectroscopy data

%
% USAGE: From the project root, run('code/AqSolDB/GPmodel_AqSolDB.m').

clear; clc; close all;
scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(scriptDir));
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    projectRoot = pwd;
end
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    error('Project root could not be resolved. Set the MATLAB current folder to the project root and run the script again.');
end


% --------------------------
% Load PLS model and data
% --------------------------
load(fullfile(projectRoot, 'data', 'AqSolDB', 'analysis_data', 'pls_model_AqSolDB.mat'));
load(fullfile(projectRoot, 'data', 'AqSolDB', 'analysis_data', 'AqSolDB_data_split.mat'), 'yval', 'ytest', 'ycal');

% remove outliers from reference data
ycal = ycal(idx_cal);
yval = yval(idx_val);
ytest = ytest(idx_test);
%
addpath(fullfile(projectRoot, 'code', 'functions'));
% --------------------------
% Mean GP kernel (ARD RBF): theta = [ell_1..ell_d; sf; sn]
% --------------------------
kernel_mu = @(xi, xj, theta) ...
    theta(end-1)^2 .* exp( ...
        -0.5 .* pdist2( ...
            bsxfun(@rdivide, xi, theta(1:end-2)'), ...
            bsxfun(@rdivide, xj, theta(1:end-2)'), ...
            'euclidean' ...
        ).^2 ...
    );

% --------------------------
% GP options (reproducible)
% --------------------------
% Options for mean GP (bias model)
opts_mu = struct('ard', true, 'nStarts', 10, 'seed', 1, ...
                 'snMin', 0.1, ...
                 'ellMinAbs', 0.5, ...
                 'ellMinFactor', 1.5);

% Options for heteroscedastic variance model (Laplace)
opts_hvar = struct();
opts_hvar.ard        = true;
opts_hvar.nStarts    = 10;
opts_hvar.seed       = 1;
opts_hvar.display    = 'off';
opts_hvar.maxEvals   = 300;
opts_hvar.maxIterLap = 60;
opts_hvar.tolLap     = 1e-6;
opts_hvar.jitterK    = 1e-8;
opts_hvar.epsR2      = 1e-12;
opts_hvar.ellMin     = 0.2;
opts_hvar.sfMin      = 1e-3;
opts_hvar.sfMax      = 1e3;

% Estimate ellMax from data span
xs = (Tval - mean(Tval, 1)) ./ std(Tval, 0, 1);
span = max(xs, [], 1) - min(xs, [], 1);
opts_hvar.ellMax = 0.5 * max(span);

% ============================================================
% Fit the two-stage heteroscedastic GP model once
% ============================================================
fprintf('\n--- Fitting Heteroscedastic GP Model ---\n');
tic;
gp_model = GP_heteroscedasticity_fit( ...
    Tval, e_val, kernel_mu, opts_mu, opts_hvar);
t_gp = toc;
fprintf('Heteroscedastic GP model fitted in %.1f seconds\n', t_gp);

theta_mu = gp_model.meanGP.theta_hat;
fprintf('Hyperparameters (mean GP):\n');
for d = 1:LV
    fprintf('  ell_%d = %.3f\n', d, theta_mu(d));
end
fprintf('  sf = %.4f\n', theta_mu(end-1));
fprintf('  sn = %.4f\n', theta_mu(end));

% Predict bias and all variance components on the test set.
[E_e_test_hat, ~, Var_epi_test_hat, ...
    Var_ale_test_hat, Var_total_test_hat] = ...
    GP_heteroscedasticity_predict(gp_model, Ttest);

% Detach the saved anonymous kernel from any temporary Live Editor wrapper.
% This prevents path warnings when the saved model is loaded elsewhere.
gp_model.meanGP.kernel = str2func(func2str(gp_model.meanGP.kernel));

% --------------------------
% Save GP model results
% --------------------------
outdir = fullfile(projectRoot, 'data', 'AqSolDB', 'analysis_data');
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
save(fullfile(outdir, 'gp_model_AqSolDB.mat'), ...
    'gp_model', 'E_e_test_hat', ...
    'Var_epi_test_hat', 'Var_ale_test_hat', 'Var_total_test_hat');

fprintf('\nGP model saved to: %s\n', fullfile(outdir, 'gp_model_AqSolDB.mat'));
