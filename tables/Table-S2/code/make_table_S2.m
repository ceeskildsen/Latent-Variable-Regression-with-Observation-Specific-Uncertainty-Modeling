% make_table_S2.m
% Supplementary Table 2: summary of uncertainty evaluation
%   prints summary metrics to console and saves a summary table.
%
% USAGE: From the project root, run('tables/Table-S2/code/make_table_S2.m').

clear; close all; clc;
scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(fileparts(scriptDir)));
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    projectRoot = pwd;
end
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    error('Project root could not be resolved. Set the MATLAB current folder to the project root and run the script again.');
end

load(fullfile(projectRoot, 'data', 'AqSolDB', 'analysis_data', ...
    'uncertainty_evaluation_results_AqSolDB.mat'), ...
    'mean_CRPS_GP', 'mean_CRPS_OLS', ...
    'mean_variance_GP', 'mean_variance_OLS', ...
    'median_variance_GP', 'median_variance_OLS', ...
    'std_variance_GP', 'std_variance_OLS');


% ================================================================
% Summary table
% ================================================================
Metric = ["Mean CRPS"; ...
          "Mean variance"; ...
          "Median variance"; ...
          "Std variance"];

GP  = [mean_CRPS_GP; ...
       mean_variance_GP; ...
       median_variance_GP; ...
       std_variance_GP];

OLS = [mean_CRPS_OLS; ...
       mean_variance_OLS; ...
       median_variance_OLS; ...
       std_variance_OLS];

summaryTable = table(Metric, GP, OLS);

fprintf('\n--- Supplementary Table S2: Uncertainty summary ---\n');
disp(summaryTable);

% Save as .txt
outpath = fullfile(projectRoot, 'tables', 'Table-S2', 'TableS2_uncertainty_summary.txt');
if ~exist(fileparts(outpath), 'dir')
    mkdir(fileparts(outpath));
end
% writetable(summaryTable, outpath, 'Delimiter', '\t');

