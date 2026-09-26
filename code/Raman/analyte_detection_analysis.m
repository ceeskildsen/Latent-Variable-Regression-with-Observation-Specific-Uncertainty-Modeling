% analyte_detection_analysis.m
% Computes null-space projections, detection limits, and Type I/II errors.

%
% USAGE: From the project root, run('code/Raman/analyte_detection_analysis.m').

clear; clc;

scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(scriptDir));
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    projectRoot = pwd;
end
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    error('Project root could not be resolved. Set the MATLAB current folder to the project root and run the script again.');
end

addpath(fullfile(projectRoot, 'code', 'functions'));

load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'data_split.mat'), ...
    'Ycal', 'Ytest', 'IDtest');
load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'pls_model.mat'), ...
    'Tcal', 'Ttest', 'LV', 'Iint', 'Iy', ...
    'uIDtest', 'uTtest', 'yhat_test', 'MSE_cv');
load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'gp_model_results.mat'), 'gp_model');

gp_model.meanGP.kernel = @(xi, xj, theta) ...
    theta(end-1)^2 .* exp( ...
    -0.5 .* pdist2( ...
    bsxfun(@rdivide, xi, theta(1:end-2)'), ...
    bsxfun(@rdivide, xj, theta(1:end-2)'), ...
    'euclidean').^2);

if LV ~= 2
    warning('This analysis is written for LV=2. Current LV=%d.', LV);
end

Tcal2 = Tcal(:, 1:LV);
Ttest2 = Ttest(:, 1:LV);

idx_null_test = ismember(uIDtest, unique(IDtest(Ytest(:, Iy) == 0)));
uTtest_null = uTtest(idx_null_test, 1:LV);

idx_cal_blank = (Ycal(:, Iy) == 0);
T_blank = Tcal2(idx_cal_blank, :);

mnTblank = mean(T_blank, 1);
T_blank_centered = T_blank - mnTblank;
[~, ~, V] = svd(T_blank_centered, 'econ');
Q_blank = V(:, 1);

Ical = Ycal(:, Iint);
ycal = Ycal(:, Iy);
Z = [ones(size(Tcal2, 1), 1), Ical, ycal];
C = Z \ Tcal2;
cy = C(3, :).';
u_y = cy / norm(cy);

ID_A_detect = [41; 48];
ID_null_detect = [45; 25];

idxA_u = zeros(numel(ID_A_detect), 1);
for i = 1:numel(ID_A_detect)
    k = find(uIDtest == ID_A_detect(i), 1, 'first');
    if isempty(k)
        error('Could not find analyte ID %d in uIDtest.', ID_A_detect(i));
    end
    idxA_u(i) = k;
end
analyteT = uTtest(idxA_u, 1:LV);

yhat_A = nan(numel(ID_A_detect), 1);
for i = 1:numel(ID_A_detect)
    k = find(IDtest == ID_A_detect(i), 1, 'first');
    if isempty(k)
        error('Could not find analyte ID %d in IDtest.', ID_A_detect(i));
    end
    yhat_A(i) = yhat_test(k);
end

nullT = zeros(numel(ID_A_detect), LV);
xi_coef = nan(numel(ID_A_detect), 1);
for i = 1:numel(ID_A_detect)
    B = [Q_blank, u_y];
    rhs = (analyteT(i, :) - mnTblank)';
    coef = B \ rhs;
    xi_coef(i) = coef(1);
    nullT(i, :) = mnTblank + (Q_blank * xi_coef(i))';
end

[e_hat_detect, ~, Var_epi_null, Var_ale_null, Var_total_null] = ...
    GP_heteroscedasticity_predict(gp_model, nullT(:, 1:LV));

alpha_level = 0.05;
z = norminv(1 - alpha_level);

Ncal = size(Tcal2, 1);
G = Tcal2' * Tcal2;

var_null_ols = zeros(numel(ID_A_detect), 1);
DL_gp = zeros(numel(ID_A_detect), 1);
DL_ols = zeros(numel(ID_A_detect), 1);
p_tail = zeros(numel(ID_A_detect), 1);
yhat_blank = cell(numel(ID_A_detect), 1);

for i = 1:numel(ID_A_detect)
    var_null_ols(i) = (1 + 1/Ncal + nullT(i, :) / G * nullT(i, :)') * MSE_cv(LV);
    var_null_ols(i) = max(var_null_ols(i), eps);
    DL_gp(i) = -e_hat_detect(i) + z * sqrt(Var_total_null(i));
    DL_ols(i) = z * sqrt(var_null_ols(i));
    p_tail(i) = normcdf(yhat_A(i), -e_hat_detect(i), sqrt(Var_total_null(i)), 'upper');

    idx_blank = ismember(IDtest, ID_null_detect(i));
    yhat_blank{i} = yhat_test(idx_blank);
end

type1_gp  = zeros(2, 1);
type2_gp  = zeros(2, 1);
type1_ols = zeros(2, 1);
type2_ols = zeros(2, 1);

for i = 1:2
    idx_blank = ismember(IDtest, ID_null_detect(i));
    Tblank_test = Ttest2(idx_blank, :);
    yhat_blank_i = yhat_test(idx_blank);

    falsePositive_gp = false(size(Tblank_test, 1), 1);
    falsePositive_ols = false(size(Tblank_test, 1), 1);

    for j = 1:size(Tblank_test, 1)
        nullT_temp = oblique_project_nullspace(Tblank_test(j, :), Q_blank, u_y, mnTblank);

        [e_hat_temp, ~, ~, ~, Vtot_temp] = ...
            GP_heteroscedasticity_predict(gp_model, nullT_temp);
        DL_temp = -e_hat_temp + z * sqrt(Vtot_temp);
        falsePositive_gp(j) = (yhat_blank_i(j) > DL_temp);

        var_null = (1 + 1/Ncal + nullT_temp / G * nullT_temp') * MSE_cv(LV);
        var_null = max(var_null, eps);
        falsePositive_ols(j) = (yhat_blank_i(j) > z * sqrt(var_null));
    end

    type1_gp(i) = mean(falsePositive_gp);
    type1_ols(i) = mean(falsePositive_ols);
end

for i = 1:2
    idx_analyte = ismember(IDtest, ID_A_detect(i));
    Tanalyte_test = Ttest2(idx_analyte, :);
    yhat_analyte = yhat_test(idx_analyte);

    detected_gp = false(size(Tanalyte_test, 1), 1);
    detected_ols = false(size(Tanalyte_test, 1), 1);

    for j = 1:size(Tanalyte_test, 1)
        nullT_temp = oblique_project_nullspace(Tanalyte_test(j, :), Q_blank, u_y, mnTblank);

        [e_hat_temp, ~, ~, ~, Vtot_temp] = ...
            GP_heteroscedasticity_predict(gp_model, nullT_temp);
        DL_temp = -e_hat_temp + z * sqrt(Vtot_temp);
        detected_gp(j) = (yhat_analyte(j) > DL_temp);

        var_null = (1 + 1/Ncal + nullT_temp / G * nullT_temp') * MSE_cv(LV);
        var_null = max(var_null, eps);
        detected_ols(j) = (yhat_analyte(j) > z * sqrt(var_null));
    end

    type2_gp(i) = 1 - mean(detected_gp);
    type2_ols(i) = 1 - mean(detected_ols);
end

samples = {'Sample 5 (low analyte level)'; 'Sample 6 (high analyte level)'};
T1_GP  = flipud(type1_gp);
T2_GP  = flipud(type2_gp);
T1_OLS = flipud(type1_ols);
T2_OLS = flipud(type2_ols);

type_error_table = table(samples, T1_GP, T2_GP, T1_OLS, T2_OLS, ...
    'VariableNames', {'Sample', 'GP_Type_I', 'GP_Type_II', 'OLS_Type_I', 'OLS_Type_II'});

outpath = fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'analyte_detection_results.mat');
if ~exist(fileparts(outpath), 'dir')
    mkdir(fileparts(outpath));
end
save(outpath, ...
    'LV', 'Tcal2', 'Ycal', 'Iint', 'uTtest_null', ...
    'mnTblank', 'Q_blank', 'u_y', 'ID_A_detect', 'ID_null_detect', ...
    'analyteT', 'nullT', 'xi_coef', 'yhat_A', 'yhat_blank', ...
    'e_hat_detect', 'Var_epi_null', 'Var_ale_null', 'Var_total_null', ...
    'var_null_ols', 'DL_gp', 'DL_ols', 'p_tail', ...
    'alpha_level', 'z', 'type1_gp', 'type2_gp', 'type1_ols', 'type2_ols', ...
    'type_error_table');

disp('--- Table 1: Type I and II Errors ---');
disp(type_error_table);
