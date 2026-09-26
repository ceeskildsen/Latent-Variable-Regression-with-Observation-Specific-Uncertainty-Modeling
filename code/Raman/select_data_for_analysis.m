% select_data_for_analysis.m
%
% PURPOSE
%   Create reproducible calibration / validation / test splits from preprocessed spectra
%   (X_proc) while ensuring that the 3 repeat scans from the same well are kept
%   together in the same split.
%
% DATA ORDER ASSUMPTION
%   Within each sample ID:
%     rows 1:3   = well 1, repeats 1–3
%     rows 4:6   = well 2, repeats 1–3
%     ...
%   i.e. 3 consecutive rows = 1 well (3 repeats).
%
% SPLIT DESIGN (per sample ID)
%   - Calibration (PLS): 2 wells  (=> 2*3 = 6 spectra), ONLY for cal_IDs
%   - Validation (GP):   5 wells  (=> 5*3 = 15 spectra), ONLY for cal_IDs
%   - Test:             20 wells  (=> 20*3 = 60 spectra), for ALL allowed IDs
%   - Off-grid IDs (not in cal_IDs): TEST ONLY
%
% INPUTS (from processed_data.mat)
%   X_proc, Y_proc, ID_proc, wn_proc
%
% OUTPUTS (to data/Raman/analysis_data/data_split.mat)
%   Xcal,Ycal,IDcal, Xval,Yval,IDval, Xtest,Ytest,IDtest, wn
%   idx_cal, idx_val, idx_test

%
% USAGE: From the project root, run('code/Raman/select_data_for_analysis.m').

close all; clear; clc;
scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(scriptDir));
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    projectRoot = pwd;
end
if ~exist(fullfile(projectRoot, 'code'), 'dir') || ~exist(fullfile(projectRoot, 'data'), 'dir')
    error('Project root could not be resolved. Set the MATLAB current folder to the project root and run the script again.');
end


% --------------------------
% Load processed data
% --------------------------
load(fullfile(projectRoot, 'data', 'Raman', 'processed_data', 'processed_data.mat'), 'X_proc', 'Y_proc', 'ID_proc', 'wn_proc');

% --------------------------
% Define study-relevant IDs
% --------------------------
cal_IDs = [ ...
     1; 3; 5; 7; 9; ...
    10; 11; 12; 13; 14; 15; 16; ...
    18; 19; 20; 21; 22; 23; 24; 25; 26; 27; 28; 29; 30];

allowed_IDs = [cal_IDs; 31; 35; 36; 37; 39; 41; 42; 43; 44; 45; 46; 48];

in_study = ismember(ID_proc, allowed_IDs);

% --------------------------
% No additional outlier exclusion is applied at this stage.
% --------------------------
N = size(X_proc,1);
is_outlier = false(N,1);
keep_qc    = in_study & ~is_outlier;

% --------------------------
% Reproducibility
% --------------------------
seed = 1;
rng(seed,'twister');

% --------------------------
% Desired WELL counts (per ID)
% --------------------------
n_rep_per_well = 3;   % fixed by the measurement design

n_wells_cal  = 2;     % ONLY for cal_IDs
n_wells_val  = 5;     % ONLY for cal_IDs
n_wells_test = 25;    % for ALL allowed IDs

% Derived replicate counts
n_rep_cal  = n_wells_cal  * n_rep_per_well;
n_rep_val  = n_wells_val  * n_rep_per_well;
n_rep_test = n_wells_test * n_rep_per_well;

% --------------------------
% Build split indices (store indices for reproducibility)
% --------------------------
idx_cal  = [];
idx_val  = [];
idx_test = [];

for k = 1:numel(allowed_IDs)
    thisID = allowed_IDs(k);

    % All rows for this ID (kept after QC), in their original order
    idx_id = find(keep_qc & ID_proc == thisID);
    idx_id = sort(idx_id);

    nRows = numel(idx_id);

    % Sanity: must be divisible by 3 if we are to keep "3 repeats per well" intact
    if mod(nRows, n_rep_per_well) ~= 0
        error('ID %d: number of rows (%d) is not divisible by %d (repeats per well).', ...
              thisID, nRows, n_rep_per_well);
    end

    nWells = nRows / n_rep_per_well;

    % Determine how many wells are needed for this ID
    if ismember(thisID, cal_IDs)
        nWellsNeeded = n_wells_cal + n_wells_val + n_wells_test;
    else
        nWellsNeeded = n_wells_test; % off-grid IDs: TEST ONLY
    end

    if nWells < nWellsNeeded
        error(['Not enough wells for ID %d. Need %d wells, have %d.\n' ...
               'Reduce well counts or include more data for this ID.'], ...
               thisID, nWellsNeeded, nWells);
    end

    % Group indices into wells: each row = one well, cols = repeats 1..3
    % Relies on the data ordering described above.
    idx_well = reshape(idx_id, n_rep_per_well, nWells).';  % nWells-by-3

    % Deterministic random selection of wells (reproducible due to rng(seed,'twister'))
    permW = randperm(nWells);

    if ismember(thisID, cal_IDs)
        wells_cal  = permW(1:n_wells_cal);
        wells_val  = permW(n_wells_cal+1 : n_wells_cal+n_wells_val);
        wells_test = permW(n_wells_cal+n_wells_val+1 : nWellsNeeded);

        idx_cal  = [idx_cal;  reshape(idx_well(wells_cal , :).', [], 1)];
        idx_val  = [idx_val;  reshape(idx_well(wells_val , :).', [], 1)];
        idx_test = [idx_test; reshape(idx_well(wells_test, :).', [], 1)];
    else
        wells_test = permW(1:nWellsNeeded);
        idx_test = [idx_test; reshape(idx_well(wells_test, :).', [], 1)];
    end
end

% --------------------------
% Materialize datasets
% --------------------------
Xcal  = X_proc(idx_cal, :);
Ycal  = Y_proc(idx_cal, :);
IDcal = ID_proc(idx_cal);

Xval  = X_proc(idx_val, :);
Yval  = Y_proc(idx_val, :);
IDval = ID_proc(idx_val);

Xtest  = X_proc(idx_test, :);
Ytest  = Y_proc(idx_test, :);
IDtest = ID_proc(idx_test);

wn = wn_proc;

% --------------------------
% Save split + indices
% --------------------------
outdir = fullfile(projectRoot, 'data', 'Raman', 'analysis_data');
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
save(fullfile(outdir, 'data_split.mat'), ...
     'Xcal','Ycal','IDcal', ...
     'Xval','Yval','IDval', ...
     'Xtest','Ytest','IDtest', ...
     'wn', ...
     'idx_cal','idx_val','idx_test');

% --------------------------
% Export CSV copies
% --------------------------

% Calibration set
writematrix(Xcal, fullfile(outdir, 'calibration_spectra.csv'));
writematrix(Ycal, fullfile(outdir, 'calibration_reference.csv'));
writematrix(IDcal, fullfile(outdir, 'calibration_ID.csv'));
writematrix(idx_cal, fullfile(outdir, 'calibration_indices.csv'));

% Validation set
writematrix(Xval, fullfile(outdir, 'validation_spectra.csv'));
writematrix(Yval, fullfile(outdir, 'validation_reference.csv'));
writematrix(IDval, fullfile(outdir, 'validation_ID.csv'));
writematrix(idx_val, fullfile(outdir, 'validation_indices.csv'));

% Test set
writematrix(Xtest, fullfile(outdir, 'test_spectra.csv'));
writematrix(Ytest, fullfile(outdir, 'test_reference.csv'));
writematrix(IDtest, fullfile(outdir, 'test_ID.csv'));
writematrix(idx_test, fullfile(outdir, 'test_indices.csv'));

% Shared Raman-shift axis
writematrix(wn, fullfile(outdir, 'wavenumbers.csv'));

fprintf('CSV copies saved to %s\n', outdir);
fprintf('Calibration: %d spectra\n', size(Xcal, 1));
fprintf('Validation:  %d spectra\n', size(Xval, 1));
fprintf('Test:        %d spectra\n', size(Xtest, 1));