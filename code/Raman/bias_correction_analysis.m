% bias_correction_analysis.m
% Computes bias-correction performance metrics for Figure 8.

%
% USAGE: From the project root, run('code/Raman/bias_correction_analysis.m').

clear; clc;

scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(scriptDir));
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    projectRoot = pwd;
end
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    error('Project root could not be resolved. Set the MATLAB current folder to the project root and run the script again.');
end

load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'data_split.mat'), 'IDtest', 'IDcal');
load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'pls_model.mat'), 'e_test');
load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'gp_model_results.mat'), 'E_e_test_hat_all');

IDtest = IDtest(:);
e_test = e_test(:);
E_e_test_hat_all = E_e_test_hat_all(:);
assert(numel(IDtest) == numel(e_test) && numel(e_test) == numel(E_e_test_hat_all), ...
    'Test identifiers, errors, and GP corrections must have equal lengths.');
assert(all(isfinite([IDtest; e_test; E_e_test_hat_all])), ...
    'Test identifiers, errors, and GP corrections must be finite.');

IDtest_select = [31; 35; 36; 37; 39; 41; 42; 43; 44; 45; 46; 48];
idx_on_grid  = ismember(IDtest, unique(IDcal));
idx_off_grid = ismember(IDtest, IDtest_select);
assert(all(xor(idx_on_grid, idx_off_grid)), ...
    'Each test observation must belong to exactly one test group.');

e_test_corr = e_test - E_e_test_hat_all;

[mixtureIDs, ~, mixtureIndex] = unique(IDtest);
observationsPerMixture = accumarray(mixtureIndex, 1);
mseBefore = accumarray(mixtureIndex, e_test.^2, [], @mean);
mseAfter = accumarray(mixtureIndex, e_test_corr.^2, [], @mean);
mixtureOnGrid = ismember(mixtureIDs, unique(IDcal));
mixtureOffGrid = ismember(mixtureIDs, IDtest_select);
assert(nnz(mixtureOnGrid) == 25 && nnz(mixtureOffGrid) == 12, ...
    'Expected 25 on-grid and 12 off-grid test mixtures.');

mixtureGroup = repmat("Off-grid", numel(mixtureIDs), 1);
mixtureGroup(mixtureOnGrid) = "On-grid";
mixtureResults = table(mixtureIDs, mixtureGroup, observationsPerMixture, ...
    mseBefore, mseAfter, mseBefore - mseAfter, ...
    'VariableNames', {'MixtureID', 'Group', 'N_observations', ...
    'MSE_before', 'MSE_after', 'MSE_reduction'});

MSE_on_grid       = mean(e_test(idx_on_grid).^2);
MSE_off_grid      = mean(e_test(idx_off_grid).^2);
MSE_on_grid_corr  = mean(e_test_corr(idx_on_grid).^2);
MSE_off_grid_corr = mean(e_test_corr(idx_off_grid).^2);

MSE_all      = mean(e_test.^2);
MSE_all_corr = mean(e_test_corr.^2);

reduction_on_grid  = 100 * (MSE_on_grid - MSE_on_grid_corr) / MSE_on_grid;
reduction_off_grid = 100 * (MSE_off_grid - MSE_off_grid_corr) / MSE_off_grid;
reduction_all      = 100 * (MSE_all - MSE_all_corr) / MSE_all;

mse_on_grid      = mseBefore(mixtureOnGrid);
mse_on_grid_corr = mseAfter(mixtureOnGrid);
[~, p_t_on, ~, stats_t_on] = ttest(mse_on_grid, mse_on_grid_corr, 'Tail', 'both');
[p_w_on, ~, stats_w_on] = signrank(mse_on_grid, mse_on_grid_corr, 'Tail', 'both');

mse_off_grid      = mseBefore(mixtureOffGrid);
mse_off_grid_corr = mseAfter(mixtureOffGrid);
[~, p_t_off, ~, stats_t_off] = ttest(mse_off_grid, mse_off_grid_corr, 'Tail', 'both');
[p_w_off, ~, stats_w_off] = signrank(mse_off_grid, mse_off_grid_corr, 'Tail', 'both');

[~, p_t_all, ~, stats_t_all] = ttest(mseBefore, mseAfter, 'Tail', 'both');
[p_w_all, ~, stats_w_all] = signrank(mseBefore, mseAfter, 'Tail', 'both');

MSE_summary = table( ...
    ["On-grid"; "Off-grid"; "Combined"], ...
    [MSE_on_grid; MSE_off_grid; MSE_all], ...
    [MSE_on_grid_corr; MSE_off_grid_corr; MSE_all_corr], ...
    [reduction_on_grid; reduction_off_grid; reduction_all], ...
    'VariableNames', {'Group', 'MSE_before', 'MSE_after', 'Reduction_percent'});

Group = ["On-grid"; "On-grid"; "Off-grid"; "Off-grid"; "Combined"; "Combined"];
Test = ["Paired t-test"; "Wilcoxon signed-rank"; "Paired t-test"; ...
        "Wilcoxon signed-rank"; "Paired t-test"; "Wilcoxon signed-rank"];
Statistic = [stats_t_on.tstat; stats_w_on.signedrank; ...
             stats_t_off.tstat; stats_w_off.signedrank; ...
             stats_t_all.tstat; stats_w_all.signedrank];
N_mixtures = [nnz(mixtureOnGrid); nnz(mixtureOnGrid); ...
              nnz(mixtureOffGrid); nnz(mixtureOffGrid); ...
              numel(mixtureIDs); numel(mixtureIDs)];
DF_or_N = [stats_t_on.df; nnz(mixtureOnGrid); ...
           stats_t_off.df; nnz(mixtureOffGrid); ...
           stats_t_all.df; numel(mixtureIDs)];
pValue = [p_t_on; p_w_on; p_t_off; p_w_off; p_t_all; p_w_all];

resultsTable = table(Group, Test, N_mixtures, Statistic, DF_or_N, pValue);

outpath = fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'bias_correction_results.mat');
if ~exist(fileparts(outpath), 'dir')
    mkdir(fileparts(outpath));
end
save(outpath, ...
    'idx_on_grid', 'idx_off_grid', 'e_test_corr', ...
    'MSE_on_grid', 'MSE_off_grid', 'MSE_on_grid_corr', 'MSE_off_grid_corr', ...
    'MSE_all', 'MSE_all_corr', ...
    'reduction_on_grid', 'reduction_off_grid', 'reduction_all', ...
    'MSE_summary', 'resultsTable', 'mixtureResults');

disp('--- MSE summary (before/after bias correction) ---');
disp(MSE_summary);
disp('--- Two-sided paired tests on mixture-level MSEs ---');
disp(resultsTable);
fprintf('Exploratory tests: interpret p-values cautiously because of skewness and asymmetry in paired differences.\n');
