% PLSmodel_AqSolDB.m
% Fit PLS regression model on AqSolDB calibration data
%
% Workflow:
%   1) Initial PLS/CV on calibration set
%   2) Use initial 4-LV model to detect/remove CALIBRATION outliers
%   3) Refit PLS on cleaned calibration set
%   4) Select final model (6 LVs) by CV on cleaned calibration set
%   5) Define final Hotelling T^2 threshold from cleaned calibration model
%   6) Apply final T^2 threshold to VALIDATION and TEST sets
%
% Notes:
%   - Calibration outlier screening uses residuals + T^2
%   - Validation/test screening uses T^2 only

%
% USAGE: From the project root, run('code/AqSolDB/PLSmodel_AqSolDB.m').

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
% Load split data
% --------------------------
load(fullfile(projectRoot, 'data', 'AqSolDB', 'analysis_data', 'AqSolDB_data_split.mat'), ...
    'Xcal', 'Xval', 'Xtest', 'ycal', 'yval', 'ytest');

Xcal_orig = Xcal;
ycal_orig = ycal;
Xval_orig = Xval;
yval_orig = yval;
Xtest_orig = Xtest;
ytest_orig = ytest;
%
% --------------------------
% PLS parameters
% --------------------------
LVmax   = 15;
nFolds  = 20;
seed    = 1;

% User-defined LV choices from CV
LV_init = 4;   % optimal before calibration outlier removal
LV      = 6;   % optimal after calibration outlier removal (final model)

addpath(fullfile(projectRoot, 'code', 'functions'));

% ============================================================
% 1) Initial CV on calibration set
% ============================================================
fprintf('\n--- Initial %d-fold CV on calibration set ---\n', nFolds);
[yhat_cv_init, T_cv_init, MSE_cv_init] = run_pls_cv(Xcal_orig, ycal_orig, LVmax, nFolds, seed);

e_cal_cv_init = ycal_orig - yhat_cv_init;

fprintf('Initial LV used for calibration outlier screening: %d\n', LV_init);

% --------------------------
% Initial calibration outlier screening (4-LV model)
% --------------------------
res_threshold_init = 3 * std(e_cal_cv_init(:, LV_init), 0, 1);
outlier_e_cal = abs(e_cal_cv_init(:, LV_init) - median(e_cal_cv_init(:, LV_init))) > res_threshold_init;

T_cv_scale = std(T_cv_init(:, 1:LV_init), 0, 1);
T_cv_scale(T_cv_scale == 0) = 1;
T2_cv_init = sum((T_cv_init(:, 1:LV_init) ./ T_cv_scale).^2, 2);
T2_crit_init = chi2inv(0.99, LV_init);
outlier_T2_cal = T2_cv_init > T2_crit_init;

idx_cal = ~(outlier_e_cal | outlier_T2_cal);

fprintf('Calibration outliers removed: %d\n', sum(~idx_cal));
fprintf('  - Residual outliers: %d\n', sum(outlier_e_cal));
fprintf('  - T^2 outliers:      %d\n', sum(outlier_T2_cal));

% Clean calibration set
Xcal = Xcal_orig(idx_cal, :);
ycal = ycal_orig(idx_cal, :);

% ============================================================
% 2) CV on cleaned calibration set
% ============================================================
fprintf('\n--- %d-fold CV on cleaned calibration set ---\n', nFolds);
[yhat_cv, ~, MSE_cv] = run_pls_cv(Xcal, ycal, LVmax, nFolds, seed);

fprintf('Final LV after calibration outlier removal: %d\n', LV);

% ============================================================
% 3) Fit final PLS model on cleaned calibration set
% ============================================================
fprintf('\n--- Fitting final PLS model ---\n');

mnX_cal = mean(Xcal, 1);
stdX_cal = std(Xcal, 0, 1);
stdX_cal(stdX_cal == 0) = 1;
mnY_cal = mean(ycal);

Xcal_auto = (Xcal - mnX_cal) ./ stdX_cal;
ycal_mc   = ycal - mnY_cal;

[b, P, q, Tcal, ~, W] = nipals_pls1(Xcal_auto, ycal_mc, LV);

% Calibration predictions
yhat_cal = Xcal_auto * b(:, LV) + mnY_cal;
e_cal    = ycal - yhat_cal;

% Final Hotelling T^2 threshold from cleaned calibration model
Tcal_scale = std(Tcal, 0, 1);
Tcal_scale(Tcal_scale == 0) = 1;
T2_crit_final = chi2inv(0.99, LV);

% ============================================================
% 4) Project validation and test sets using final model
% ============================================================
Xval_auto  = (Xval_orig  - mnX_cal) ./ stdX_cal;
Xtest_auto = (Xtest_orig - mnX_cal) ./ stdX_cal;

[Tval_all, ~] = project_pls_scores(Xval_auto,  W, P, LV);
[Ttest_all, ~] = project_pls_scores(Xtest_auto, W, P, LV);

yhat_val_all  = Xval_auto  * b(:, LV) + mnY_cal;
yhat_test_all = Xtest_auto * b(:, LV) + mnY_cal;

e_val_all  = yval_orig  - yhat_val_all;
e_test_all = ytest_orig - yhat_test_all;

% ============================================================
% 5) Validation and test screening using final T^2 only
% ============================================================
T2_val  = sum((Tval_all  ./ Tcal_scale).^2, 2);
T2_test = sum((Ttest_all ./ Tcal_scale).^2, 2);

idx_val  = T2_val  <= T2_crit_final;
idx_test = T2_test <= T2_crit_final;

fprintf('\nValidation outliers removed (T^2 only): %d\n', sum(~idx_val));
fprintf('Test outliers removed (T^2 only): %d\n', sum(~idx_test));

% Keep filtered validation/test sets
Tval     = Tval_all(idx_val, :);
Ttest    = Ttest_all(idx_test, :);

e_val    = e_val_all(idx_val);
e_test   = e_test_all(idx_test);

yhat_val = yhat_val_all(idx_val);
yhat_test = yhat_test_all(idx_test);

% ============================================================
% 6) Performance metrics
% ============================================================
MSE_cal  = mean(e_cal.^2);
MSE_val  = mean(e_val.^2);
MSE_test = mean(e_test.^2);

fprintf('\nSet sizes after screening:\n');
fprintf('  Calibration: %d\n', numel(ycal));
fprintf('  Validation:  %d\n', numel(e_val));
fprintf('  Test:        %d\n', numel(e_test));

% ============================================================
% Save model
% ============================================================
outdir = fullfile(projectRoot, 'data', 'AqSolDB', 'analysis_data');
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
save(fullfile(outdir, 'pls_model_AqSolDB.mat'), ...
    'LV_init', 'LV', 'P', 'q', 'b', 'W', ...
    'mnX_cal', 'stdX_cal', 'mnY_cal', ...
    'Tcal', 'e_cal', 'yhat_cal', ...
    'Tval', 'e_val', 'yhat_val', ...
    'Ttest', 'e_test', 'yhat_test', ...
    'yhat_cv_init', 'yhat_cv', ...
    'MSE_cv_init', 'MSE_cv', 'MSE_cal', 'MSE_val', 'MSE_test', ...
    'res_threshold_init', ...
    'T2_crit_init', 'T2_crit_final', ...
    'idx_cal', 'idx_val', 'idx_test');

fprintf('\nPLS model saved to: %s\n', fullfile(outdir, 'pls_model_AqSolDB.mat'));


% ============================================================
% Local functions
% ============================================================
function [yhat_cv, T_cv, MSE_cv] = run_pls_cv(X, y, LVmax, nFolds, seed)
    rng(seed, 'twister');

    N = size(X, 1);
    fold_id = make_fold_ids(N, nFolds);

    yhat_cv = nan(N, LVmax);
    T_cv    = nan(N, LVmax);

    for fold = 1:nFolds
        idx_test_cv  = (fold_id == fold);
        idx_train_cv = ~idx_test_cv;

        mnX = mean(X(idx_train_cv, :), 1);
        stdX = std(X(idx_train_cv, :), 0, 1);
        stdX(stdX == 0) = 1;
        mnY = mean(y(idx_train_cv));

        X_train_cv = (X(idx_train_cv, :) - mnX) ./ stdX;
        y_train_cv = y(idx_train_cv) - mnY;
        X_test_cv  = (X(idx_test_cv, :)  - mnX) ./ stdX;

        [b, P, ~, ~, ~, W] = nipals_pls1(X_train_cv, y_train_cv, LVmax);

        % Predictions for all LVs
        yhat_cv(idx_test_cv, :) = X_test_cv * b + mnY;

        % Scores by iterative deflation
        X_test_tmp = X_test_cv;
        for a = 1:LVmax
            T_cv(idx_test_cv, a) = X_test_tmp * W(:, a);
            X_test_tmp = X_test_tmp - T_cv(idx_test_cv, a) * P(:, a)';
        end
    end

    e_cv = y - yhat_cv;
    MSE_cv = mean(e_cv.^2, 1);
end

function fold_id = make_fold_ids(N, nFolds)
    idx_perm = randperm(N);

    fold_sizes = floor(N / nFolds) * ones(nFolds, 1);
    fold_sizes(1:mod(N, nFolds)) = fold_sizes(1:mod(N, nFolds)) + 1;

    fold_id = zeros(N, 1);
    start_idx = 1;
    for f = 1:nFolds
        stop_idx = start_idx + fold_sizes(f) - 1;
        fold_id(idx_perm(start_idx:stop_idx)) = f;
        start_idx = stop_idx + 1;
    end
end

function [T, Xres] = project_pls_scores(X, W, P, LV)
    T = nan(size(X, 1), LV);
    Xres = X;
    for a = 1:LV
        T(:, a) = Xres * W(:, a);
        Xres = Xres - T(:, a) * P(:, a)';
    end
end
