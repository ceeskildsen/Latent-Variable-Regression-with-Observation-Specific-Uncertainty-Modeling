% GPmodel.m
% Fit a GP mean model on residuals (bias) and a heteroscedastic variance
% model using a GP prior on g(x)=log(sigma^2(x)) with Laplace approximation.
%
% Saved variables used by downstream analysis and figure scripts:
%   E_e_*_hat       = predicted bias (mean residual)
%   Var_epi_*_hat   = epistemic variance
%   Var_ale_*_hat   = aleatoric variance
%   Var_total_*_hat = total prediction-error variance

%
% USAGE: From the project root, run('code/Raman/GPmodel.m').

clear; clc;
scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(scriptDir));
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    projectRoot = pwd;
end
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    error('Project root could not be resolved. Set the MATLAB current folder to the project root and run the script again.');
end


% --------------------------
% Load data
% --------------------------
load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'pls_model.mat'), ...
    'Tval','e_val','LV','Ttest','uTtest','uTval');
load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'data_split.mat'),'IDval');

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
% Grid for maps (Figure 4)
% --------------------------
axlim_T1 = [-600, 600];
axlim_T2 = axlim_T1;
T1_range  = linspace(axlim_T1(1), axlim_T1(2), 100);
T2_range  = linspace(axlim_T2(1), axlim_T2(2), 100);
[T1grid, T2grid] = meshgrid(T1_range, T2_range);
Tgrid    = [T1grid(:), T2grid(:)];

% --------------------------
% Options for error GP (mean model)
% --------------------------
opts_mu = struct();
opts_mu.ard            = true;
opts_mu.nStarts        = 10;
opts_mu.seed           = 1;
opts_mu.ellMinAbs      = 1.5;
opts_mu.ellMinFactor   = 2.0;
opts_mu.snMin = 0.2;

% --------------------------
% Options for heteroscedastic variance model (Laplace)
% --------------------------
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

xs = (Tval(:,1:LV) - mean(Tval(:,1:LV),1)) ./ std(Tval(:,1:LV),0,1);
span = max(xs,[],1) - min(xs,[],1);
opts_hvar.ellMax = 0.5 * max(span);

addpath(fullfile(projectRoot, 'code', 'functions'));

% ============================================================
% Fit the two-stage heteroscedastic GP model once
% ============================================================
gp_model = GP_heteroscedasticity_fit( ...
    Tval(:,1:LV), e_val, kernel_mu, opts_mu, opts_hvar);
theta_hat = gp_model.meanGP.theta_hat;

% Predict bias and all variance components on the plotting grid.
[E_e_hat, ~, Var_epi_grid_vec, Var_ale_grid_vec, Var_total_grid_vec] = ...
    GP_heteroscedasticity_predict(gp_model, Tgrid);
E_e_hat_grid = reshape(E_e_hat, size(T1grid));
Var_epi_grid = reshape(Var_epi_grid_vec, size(T1grid));
Var_ale_grid = reshape(Var_ale_grid_vec, size(T1grid));
Var_total_grid = reshape(Var_total_grid_vec, size(T1grid));

% Predict bias and all variance components for test and validation scores.
[E_e_test_hat_all, ~, Var_epi_test_hat_all, ...
    Var_ale_test_hat_all, Var_total_test_hat_all] = ...
    GP_heteroscedasticity_predict(gp_model, Ttest(:,1:LV));
[E_e_test_hat, ~, Var_epi_test_hat, ...
    Var_ale_test_hat, Var_total_test_hat] = ...
    GP_heteroscedasticity_predict(gp_model, uTtest(:,1:LV));
[E_e_val_hat, ~, Var_epi_val_hat, ...
    Var_ale_val_hat, Var_total_val_hat] = ...
    GP_heteroscedasticity_predict(gp_model, uTval(:,1:LV));


% --------------------------
% Save
% --------------------------
outdir = fullfile(projectRoot, 'data', 'Raman', 'analysis_data');
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
% Detach the saved anonymous kernel from any temporary Live Editor wrapper.
gp_model.meanGP.kernel = str2func(func2str(gp_model.meanGP.kernel));

save(fullfile(outdir, 'gp_model_results.mat'), ...
     'gp_model', 'theta_hat', ...
     'E_e_hat_grid', 'Var_epi_grid', 'Var_ale_grid', 'Var_total_grid', ...
     'E_e_test_hat', 'Var_epi_test_hat', 'Var_ale_test_hat', ...
     'Var_total_test_hat', ...
     'E_e_test_hat_all', 'Var_epi_test_hat_all', 'Var_ale_test_hat_all', ...
     'Var_total_test_hat_all', ...
     'E_e_val_hat', 'Var_epi_val_hat', 'Var_ale_val_hat', ...
     'Var_total_val_hat');
