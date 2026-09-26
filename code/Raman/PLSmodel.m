% PLS_modeling.m
% Script for PLS modeling

%
% USAGE: From the project root, run('code/Raman/PLSmodel.m').

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
load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'data_split.mat'));

% Select analyte and interferent columns
Iy = 2;    % Index of analyte (e.g., fructose)
Iint = 1;  % Index of interferent (e.g., sucrose)

% --------------------------
% PLS model
% --------------------------
% Parameters
LVmax = 10;     % Max number of latent variables to evaluate in CV
LV = 2;         % Number of LVs to use in final model %2
uIDcal = unique(IDcal);

% Cross-validation prediction matrix
yhat_cv = nan(size(Ycal,1), LVmax);

addpath(fullfile(projectRoot, 'code', 'functions'));
% Leave-one-sample-out cross-validation
for i = 1:numel(uIDcal)%size(Xcal,1) %numel(uIDcal)
    idx_train = ~ismember(IDcal, uIDcal(i));  % Calibration samples excluding one sample
%     idx_train = true(size(Xcal,1),1); idx_train(i) = false;
    idx_val = ~idx_train;

    % Mean-center training data
    mnX = mean(Xcal(idx_train,:));
    mnY = mean(Ycal(idx_train,:));

    % Centered validation sample(s)
    X_val = Xcal(idx_val,:) - mnX;

    % Fit PLS on remaining samples
    [b, ~, ~, ~, ~, ~] = nipals_pls1(Xcal(idx_train,:) - mnX, ...
                                     Ycal(idx_train,Iy) - mnY(Iy), LVmax);

    % Predict held-out sample(s)
    yhat_cv(idx_val,:) = X_val * b + mnY(Iy);
end

% Cross-validated errors and MSE
e_cal_cv = Ycal(:,Iy) - yhat_cv;
MSE_cv = mean(e_cal_cv.^2);

% Final model on full calibration set
mnXcal = mean(Xcal);
mnYcal = mean(Ycal);
[b, P, q, Tcal, ~, W] = nipals_pls1(Xcal - mnXcal, Ycal(:,Iy) - mnYcal(Iy), LV);
yhat_cal = (Xcal - mnXcal) * b(:,LV) + mnYcal(Iy);
e_cal = Ycal(:,Iy) - yhat_cal;

% Predict on validation and test set
yhat_val = (Xval - mnXcal) * b(:, LV) + mnYcal(Iy);
e_val = Yval(:,Iy) - yhat_val;

yhat_test = (Xtest - mnXcal) * b(:, LV) + mnYcal(Iy);
e_test = Ytest(:,Iy) - yhat_test;

% --------------------------
% Project validation and test set into latent space to obtain test set scores
% --------------------------
Tval = nan(size(Yval,1), LV);
Xvalmn = Xval - mnXcal;

Ttest = nan(size(Ytest,1), LV);
Xtestmn = Xtest - mnXcal;

for i = 1:LV
    Tval(:,i) = Xvalmn * W(:,i);
    Xvalmn = Xvalmn - Tval(:,i) * P(:,i)';

    Ttest(:,i) = Xtestmn * W(:,i);
    Xtestmn = Xtestmn - Ttest(:,i) * P(:,i)';
end

% Flip signs of second LV for visual consistency
Tcal(:,2) = -Tcal(:,2);
Tval(:,2) = -Tval(:,2);
Ttest(:,2) = -Ttest(:,2);
P(:,2) = -P(:,2);
q(2) = -q(2);


% --------------------------
% Sample (empirical) error measures for validation and test samples
% --------------------------
uIDval = unique(IDval);
uTval = nan(size(uIDval,1),LV); % mean scores for each validation sample
E_e_val = nan(size(uIDval,1),1); % Expected error of validation samples
Var_e_val = nan(size(uIDval,1),1); % Prediction error variance of validation samples
for i = 1:size(uIDval,1)
    idx = ismember(IDval,uIDval(i));
    uTval(i,:) = mean(Tval(idx,1:LV));
    E_e_val(i) = mean(e_val(idx));
    Var_e_val(i) = var(e_val(idx));
end

uIDtest = unique(IDtest);
uTtest = nan(size(uIDtest,1),LV); % mean scores for each test sample
E_e_test = nan(size(uIDtest,1),1); % Expected error of test samples
Var_e_test = nan(size(uIDtest,1),1); % Prediction error variance of test samples
for i = 1:size(uIDtest,1)
    idx = ismember(IDtest,uIDtest(i));
    uTtest(i,:) = mean(Ttest(idx,1:LV));
    E_e_test(i) = mean(e_test(idx));
    Var_e_test(i) = var(e_test(idx));
end

outdir = fullfile(projectRoot, 'data', 'Raman', 'analysis_data');
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
save(fullfile(outdir, 'pls_model.mat'), 'e_cal', 'e_val', 'e_test', 'Iint', 'Iy', 'LV','mnXcal','mnYcal','MSE_cv','P','q','Tcal', 'Tval', 'yhat_val', 'yhat_test', 'uIDval', 'uIDtest', 'uTval','uTtest', 'E_e_val','E_e_test', 'Var_e_val','Var_e_test', 'Tval','Ttest','yhat_cal');
