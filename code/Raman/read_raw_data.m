% read_raw_data.m
%
% This script imports raw Raman spectroscopy data and reference concentrations
% for the sugar mixtures study.
%
% Output variables:
%   - X:    [samples x spectral variables] matrix of raw Raman intensities
%   - wn:   [spectral variables x 1] vector of wavenumbers (cm^-1)
%   - ID:   [samples x 1] vector of sample IDs (links to reference concentrations)
%   - ref_values: [samples x 2] matrix of reference concentrations (Sucrose, Fructose)
%   - ref_varID: cell array of reference variable names

%
% USAGE: From the project root, run('code/Raman/read_raw_data.m').

clear; close all; clc;
scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(scriptDir));
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    projectRoot = pwd;
end
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    error('Project root could not be resolved. Set the MATLAB current folder to the project root and run the script again.');
end


% --- Raw data folder ---
path_raw_data = fullfile(projectRoot, 'data', 'Raman', 'raw_data');

% --- Reference Concentrations ---
% Stock solution masses (grams)
mfru = 184;       % mass of fructose in fructose stock
msuc = 353;       % mass of sucrose in sucrose stock
mH2O = 500;       % mass of water in each stock

% Calculate stock solution concentrations (w/w)
conc_fru_stock = mfru/(mfru + mH2O);     % Fructose
conc_suc_stock = msuc/(msuc + mH2O);     % Sucrose

% Read design table (reference values for each sample)
NUM = readmatrix(fullfile(path_raw_data, 'refvalues.xlsx'));      % Columns: see metadata
% Calculate actual concentrations for each sample
ref_values = (NUM(:,3:4) .* [conc_suc_stock, conc_fru_stock]) ./ sum(NUM(:,3:5),2);
ID_ref = (1:size(ref_values,1))';        % Sample IDs (1...N)
ref_varID = {'Sucrose','Fructose'};      % Reference analytes

clear conc_fru_stock conc_suc_stock mfru mH2O msuc NUM

% --- Read Raman Spectral Data ---
fdir = dir(fullfile(path_raw_data, '*.csv'));         % List all .csv files (raw spectra)
numFiles = numel(fdir);      % Number of spectral files

% Preallocate arrays based on the instrument output structure
numWellsPerSample = 32;    % e.g., 32 wells per sample
numReplicates = 3;         % e.g., 3 replicates per well
spectralVars = 2000;       % Number of spectral variables (wavenumbers)
N = numWellsPerSample * numReplicates * numFiles;  % Total number of measurements

X = nan(N, spectralVars);   % Raw spectra
ID = nan(N,1);              % Sample ID for each measurement

k = 1;   % Row counter for X/ID
for i = 1:numFiles
    [NUM, ~] = xlsread(fullfile(fdir(i).folder, fdir(i).name));        % Read spectral .csv
    n = size(NUM,2) - 1;                     % Number of spectra in file (all but last column)
    if i == 1
        wn = NUM(:, end);                    % Wavenumber axis from last column
    end
    X(k : k+n-1, :) = NUM(:, 1:end-1)';      % Store spectra (transpose for [obs x vars])
    ID(k : k+n-1, 1) = ID_ref(i);            % Assign sample ID
    k = k + n;
end

% --- Save to .mat file for later scripts ---
save(fullfile(path_raw_data, 'raw_data_imported.mat'), 'X', 'wn', 'ID', 'ref_values', 'ref_varID')

% --- Script completed ---
disp('Raw data import completed.');
disp(['Imported ' num2str(size(X,1)) ' spectra across ' num2str(numFiles) ' samples.']);

% See data/Raman/raw_data/README.txt for further details and sample mapping.
