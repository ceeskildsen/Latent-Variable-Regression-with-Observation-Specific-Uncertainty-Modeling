% TableS1_q_values.m
% Script to generate Table S1: q-values (i.e. latent space regression
% coefficients

%
% USAGE: From the project root, run('tables/Table-S1/code/TableS1_q_values.m').

clear; clc;
scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(fileparts(scriptDir)));
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    projectRoot = pwd;
end
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    error('Project root could not be resolved. Set the MATLAB current folder to the project root and run the script again.');
end

% --------------------------
% Load required data
% --------------------------
load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'pls_model.mat'), 'q');

% --------------------------
% Assemble Results and Export
% --------------------------
q_no = {'q_1'; 'q_2'};

T = table(q_no, q);

disp('--- Table S1: q-values ---');
disp(T);

% Save as .txt
outpath = fullfile(projectRoot, 'tables', 'Table-S1', 'TableS1_q_values.txt');
if ~exist(fileparts(outpath), 'dir')
    mkdir(fileparts(outpath));
end
writetable(T, outpath, 'Delimiter', '\t');

