% split_AqSolDB_data.m
% Script to split AqSolDB data into calibration, validation, and test sets
% Mimics the data split structure used for the spectroscopy data
%
% Split ratios (approximately):
%   - Calibration (PLS training): ~25%
%   - Validation (GP training): ~25%
%   - Test (evaluation): ~50%

%
% USAGE: From the project root, run('code/AqSolDB/split_AqSolDB_data.m').

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
% Configuration
% --------------------------
seed = 1;  % For reproducibility
rng(seed, 'twister');

% Split ratios
ratio_cal = 0.25;   % Calibration set (PLS training)
ratio_val = 0.25;   % Validation set (GP training)
ratio_test = 0.50;  % Test set (evaluation)

% Load processed data
dataFile = fullfile(projectRoot, 'data', 'AqSolDB', 'raw_data', 'AqSolDB_raw.mat');
if ~exist(dataFile, 'file')
    error('Processed data not found. Run load_AqSolDB.m first.');
end
load(dataFile, 'X', 'y', 'varNames', 'SMILES', 'compoundNames', 'compoundIDs');

N = size(X, 1);

% --------------------------
% Option 1: Random split (simple)
% --------------------------
fprintf('\n--- Random Split ---\n');

% Random permutation of indices
idx_perm = randperm(N);

% Calculate split sizes
n_cal = round(N * ratio_cal);
n_val = round(N * ratio_val);
n_test = N - n_cal - n_val;

% Assign indices
idx_cal = idx_perm(1:n_cal);
idx_val = idx_perm(n_cal+1:n_cal+n_val);
idx_test = idx_perm(n_cal+n_val+1:end);

% Store source-row indices as column vectors. These names distinguish the
% original data split from the screening masks later created by the PLS model.
source_idx_cal = idx_cal(:);
source_idx_val = idx_val(:);
source_idx_test = idx_test(:);

fprintf('Calibration set: %d compounds (%.1f%%)\n', n_cal, 100*n_cal/N);
fprintf('Validation set: %d compounds (%.1f%%)\n', n_val, 100*n_val/N);
fprintf('Test set: %d compounds (%.1f%%)\n', n_test, 100*n_test/N);

% --------------------------
% Extract subsets
% --------------------------
% Calibration set (for PLS)
Xcal = X(idx_cal, :);
ycal = y(idx_cal);
SMILES_cal = SMILES(idx_cal);
IDs_cal = compoundIDs(idx_cal);

% Validation set (for GP)
Xval = X(idx_val, :);
yval = y(idx_val);
SMILES_val = SMILES(idx_val);
IDs_val = compoundIDs(idx_val);

% Test set (for evaluation)
Xtest = X(idx_test, :);
ytest = y(idx_test);
SMILES_test = SMILES(idx_test);
IDs_test = compoundIDs(idx_test);

% --------------------------
% Save split data
% --------------------------
outputFile = fullfile(projectRoot, 'data', 'AqSolDB', 'analysis_data', 'AqSolDB_data_split.mat');
outdir = fileparts(outputFile);
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
save(outputFile, ...
    'Xcal', 'ycal', 'IDs_cal', 'SMILES_cal', ...
    'Xval', 'yval', 'IDs_val', 'SMILES_val', ...
    'Xtest', 'ytest', 'IDs_test', 'SMILES_test', ...
    'varNames', ...
    'source_idx_cal', 'source_idx_val', 'source_idx_test');

% Export a human-readable mapping from every source row to its initial split.
source_row_index = (1:N)';
compound_ID = compoundIDs;
SMILES_source = SMILES;
initial_split = strings(N, 1);
initial_split(source_idx_cal) = "calibration";
initial_split(source_idx_val) = "validation";
initial_split(source_idx_test) = "test";

assert(all(strlength(initial_split) > 0), ...
    'At least one source row was not assigned to a data split.');

splitTable = table(source_row_index, compound_ID, SMILES_source, initial_split, ...
    'VariableNames', {'source_row_index', 'compound_ID', 'SMILES', 'initial_split'});
assignmentFile = fullfile(outdir, 'AqSolDB_split_assignments.csv');
writetable(splitTable, assignmentFile);

fprintf('\nData split saved to: %s\n', outputFile);
fprintf('Split assignments saved to: %s\n', assignmentFile);
