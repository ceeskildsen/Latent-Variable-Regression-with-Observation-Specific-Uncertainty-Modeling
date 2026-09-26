% Table1_Type_I_II_errors.m
% Script to export Table 1 from saved analyte-detection results.

%
% USAGE: From the project root, run('tables/Table-1/code/Table1_Type_I_II_errors.m').

clear; clc;

scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(fileparts(scriptDir)));
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    projectRoot = pwd;
end
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    error('Project root could not be resolved. Set the MATLAB current folder to the project root and run the script again.');
end

load(fullfile(projectRoot, 'data', 'Raman', 'analysis_data', 'analyte_detection_results.mat'), 'type_error_table');

disp('--- Table 1: Type I and II Errors ---');
disp(type_error_table);

outpath = fullfile(projectRoot, 'tables', 'Table-1', 'Table1_Type_I_II_errors.txt');
if ~exist(fileparts(outpath), 'dir')
    mkdir(fileparts(outpath));
end
writetable(type_error_table, outpath, 'Delimiter', '\t');
