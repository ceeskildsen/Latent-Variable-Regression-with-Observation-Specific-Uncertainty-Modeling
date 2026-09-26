% load_AqSolDB.m
% Script to load and preprocess the AqSolDB aqueous solubility dataset
% for use with PLS regression and GP uncertainty modeling
%
% Dataset: AqSolDB - A curated aqueous solubility dataset
% Source: https://github.com/mcsorkun/AqSolDB
% Paper: Sorkun et al. (2019) Scientific Data, doi:10.1038/s41597-019-0151-1
%
% The dataset contains 9,982 unique compounds with:
%   - Experimental aqueous solubility (LogS) as response variable
%   - 17 molecular descriptors as predictor variables

%
% USAGE: From the project root, run('code/AqSolDB/load_AqSolDB.m').

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
dataFile = fullfile(projectRoot, 'data', 'AqSolDB', 'raw_data', 'curated-solubility-dataset.csv');

% Descriptor column names (17 descriptors)
descriptorNames = {'MolWt', 'MolLogP', 'MolMR', 'HeavyAtomCount', ...
    'NumHAcceptors', 'NumHDonors', 'NumHeteroatoms', 'NumRotatableBonds', ...
    'NumValenceElectrons', 'NumAromaticRings', 'NumSaturatedRings', ...
    'NumAliphaticRings', 'RingCount', 'TPSA', 'LabuteASA', 'BalabanJ', 'BertzCT'};

% Response variable column name
responseCol = 'Solubility';  % LogS (aqueous solubility)

% --------------------------
% Load data
% --------------------------
fprintf('Loading AqSolDB dataset from: %s\n', dataFile);

if ~exist(dataFile, 'file')
    error(['Data file not found: %s\n\n' ...
           'Please download the dataset from:\n' ...
           '  Harvard Dataverse: https://doi.org/10.7910/DVN/OVHAW8\n' ...
           '  GitHub: https://github.com/mcsorkun/AqSolDB\n' ...
           '  Kaggle: https://www.kaggle.com/datasets/sorkun/aqsoldb-a-curated-aqueous-solubility-dataset\n\n' ...
           'Save the CSV file to: %s'], dataFile, dataFile);
end

% Read CSV file
opts = detectImportOptions(dataFile);
opts = setvartype(opts, 'SMILES', 'string');
opts = setvartype(opts, 'Name', 'string');
opts = setvartype(opts, 'InChI', 'string');
opts = setvartype(opts, 'InChIKey', 'string');
data = readtable(dataFile, opts);

fprintf('Loaded %d compounds\n', height(data));

% --------------------------
% Extract response variable (y)
% --------------------------
% Note: Column might be named 'Solubility' or 'Y' depending on version
if ismember('Solubility', data.Properties.VariableNames)
    y = data.Solubility;
elseif ismember('Y', data.Properties.VariableNames)
    y = data.Y;
else
    error('Could not find solubility column. Available columns: %s', ...
        strjoin(data.Properties.VariableNames, ', '));
end

% --------------------------
% Extract molecular descriptors (X)
% --------------------------
% Check which descriptors are available
availableDescriptors = intersect(descriptorNames, data.Properties.VariableNames);
missingDescriptors = setdiff(descriptorNames, data.Properties.VariableNames);

if ~isempty(missingDescriptors)
    warning('Missing descriptors: %s', strjoin(missingDescriptors, ', '));
end

fprintf('Using %d molecular descriptors\n', numel(availableDescriptors));

% Extract descriptor matrix
X = zeros(height(data), numel(availableDescriptors));
for i = 1:numel(availableDescriptors)
    X(:, i) = data.(availableDescriptors{i});
end

% Store descriptor names
varNames = availableDescriptors;

% --------------------------
% Extract metadata
% --------------------------
if ismember('SMILES', data.Properties.VariableNames)
    SMILES = data.SMILES;
else
    SMILES = strings(height(data), 1);
end

if ismember('Name', data.Properties.VariableNames)
    compoundNames = data.Name;
else
    compoundNames = strings(height(data), 1);
end

if ismember('ID', data.Properties.VariableNames)
    compoundIDs = data.ID;
else
    compoundIDs = (1:height(data))';
end

% --------------------------
% Handle missing values
% --------------------------
% Check for NaN in X
nanRowsX = any(isnan(X), 2);
% Check for NaN in y
nanRowsY = isnan(y);
% Check for Inf values
infRowsX = any(isinf(X), 2);

validRows = ~nanRowsX & ~nanRowsY & ~infRowsX;

fprintf('Removing %d rows with missing/invalid values\n', sum(~validRows));
fprintf('  - NaN in descriptors: %d\n', sum(nanRowsX));
fprintf('  - NaN in response: %d\n', sum(nanRowsY));
fprintf('  - Inf in descriptors: %d\n', sum(infRowsX));

X = X(validRows, :);
y = y(validRows);
SMILES = SMILES(validRows);
compoundNames = compoundNames(validRows);
compoundIDs = compoundIDs(validRows);

fprintf('Final dataset: %d compounds, %d descriptors\n', size(X, 1), size(X, 2));

% --------------------------
% Save data
% --------------------------
outputFile = fullfile(projectRoot, 'data', 'AqSolDB', 'raw_data', 'AqSolDB_raw.mat');
outputDir = fileparts(outputFile);
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

save(outputFile, 'X', 'y', 'varNames', 'SMILES', ...
    'compoundNames', 'compoundIDs');

fprintf('\nData saved to: %s\n', outputFile);
