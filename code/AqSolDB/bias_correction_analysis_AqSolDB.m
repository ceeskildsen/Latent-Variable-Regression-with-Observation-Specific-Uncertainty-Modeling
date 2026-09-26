% bias_correction_analysis_AqSolDB.m
% Evaluate GP bias correction for the retained AqSolDB test compounds.

clear; clc;

scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(scriptDir));
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    projectRoot = pwd;
end
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    error('Project root could not be resolved. Set the MATLAB current folder to the project root and run the script again.');
end

load(fullfile(projectRoot, 'data', 'AqSolDB', 'analysis_data', 'AqSolDB_data_split.mat'), ...
    'ytest');
load(fullfile(projectRoot, 'data', 'AqSolDB', 'analysis_data', 'pls_model_AqSolDB.mat'), ...
    'yhat_test', 'idx_test');
load(fullfile(projectRoot, 'data', 'AqSolDB', 'analysis_data', 'gp_model_AqSolDB.mat'), ...
    'E_e_test_hat');

ytest = ytest(idx_test);
yhat_test_corr = yhat_test + E_e_test_hat;

e_test = ytest - yhat_test;
e_test_corr = ytest - yhat_test_corr;
sq_err = e_test.^2;
sq_err_corr = e_test_corr.^2;

MSE_pls = mean(sq_err);
MSE_corr = mean(sq_err_corr);
MSE_reduction_percent = 100 * (1 - MSE_corr / MSE_pls);
n_test = numel(ytest);

[~, p_t, ~, stats_t] = ttest(sq_err, sq_err_corr, 'Tail', 'both');
[p_w, ~, stats_w] = signrank(sq_err, sq_err_corr, 'Tail', 'both');
t_stat = stats_t.tstat;
t_df = stats_t.df;
W = stats_w.signedrank;

outdir = fullfile(projectRoot, 'data', 'AqSolDB', 'analysis_data');
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
outfile = fullfile(outdir, 'bias_correction_results_AqSolDB.mat');
save(outfile, 'ytest', 'yhat_test', 'yhat_test_corr', ...
    'e_test', 'e_test_corr', 'sq_err', 'sq_err_corr', ...
    'MSE_pls', 'MSE_corr', 'MSE_reduction_percent', 'n_test', ...
    't_stat', 't_df', 'p_t', 'W', 'p_w');

fprintf('\n--- AqSolDB bias-correction analysis ---\n');
fprintf('n = %d test compounds\n', n_test);
fprintf('MSE (PLS):       %.4f\n', MSE_pls);
fprintf('MSE (corrected): %.4f\n', MSE_corr);
fprintf('Reduction:       %.1f%%\n', MSE_reduction_percent);
fprintf('Paired t-test:   t = %.2f, df = %d, p = %.2e\n', t_stat, t_df, p_t);
fprintf('Wilcoxon:        W = %.1f, p = %.2e\n', W, p_w);
fprintf('Results saved to: %s\n', outfile);
