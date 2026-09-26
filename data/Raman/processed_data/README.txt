README – Processed Raman Data

Overview:
---------

This folder contains the processed Raman spectra and associated reference
information for the fructose–sucrose model system.

Each row represents one spectral acquisition. The three repeat acquisitions
from each well are retained as separate observations and are not averaged.

The complete processed dataset contains 4,896 spectra:

51 mixture formulations × 32 wells × 3 repeat acquisitions = 4,896 spectra


Associated manuscript:
----------------------

Observation-Specific Uncertainty Modeling for Latent-Variable Regression in
High-Dimensional Analytical Data


Contents:
---------

processed_data.mat
    MATLAB file containing the complete processed dataset.

processed_spectra.csv
    A 4,896 × 380 matrix containing the processed Raman spectra. Rows
    represent spectral acquisitions and columns represent spectral variables.

processed_wavenumbers.csv
    A 380 × 1 vector containing the Raman-shift values in cm⁻¹ corresponding
    to the columns of processed_spectra.csv.

processed_ID.csv
    A 4,896 × 1 vector containing the mixture identifier associated with each
    spectral acquisition. The identifiers correspond to the mixture numbers
    in data/Raman/raw_data/refvalues.txt and refvalues.xlsx.

processed_reference.csv
    A 4,896 × 2 matrix containing the reference mass fractions associated
    with each spectral acquisition. Column 1 contains the sucrose mass
    fraction and column 2 contains the fructose mass fraction.

README.txt
    Description of the processed dataset and preprocessing workflow.


MATLAB variables:
-----------------

processed_data.mat contains:

X_proc
    A 4,896 × 380 matrix of processed Raman spectra. Rows represent spectral
    acquisitions and columns represent spectral variables.

wn_proc
    A 380 × 1 vector of Raman-shift values in cm⁻¹ corresponding to the
    columns of X_proc.

ID_proc
    A 4,896 × 1 vector of mixture identifiers corresponding to the rows of
    X_proc.

Y_proc
    A 4,896 × 2 matrix of reference mass fractions corresponding to the rows
    of X_proc. Column 1 contains sucrose and column 2 contains fructose.

Ylab
    A 1 × 2 cell array containing the reference-variable labels:
    Sucrose and Fructose.

The CSV files contain the same numerical values and preserve the same row and
column order as the corresponding variables in processed_data.mat.


Preprocessing:
--------------

The processed dataset was generated from
data/Raman/raw_data/raw_data_imported.mat using:

    code/Raman/preprocess_data.m

The following steps were applied:

1. Spectra were restricted to the Raman-shift region nearest to
   400–1,500 cm⁻¹.

2. Fluorescence backgrounds were estimated and removed using asymmetric
   least-squares smoothing with a smoothing parameter of 1 × 10⁶, an
   asymmetry parameter of 0.001, and a third-order difference penalty.

3. Spectral spikes were removed.

4. Individual repeat acquisitions were retained as separate observations.

5. Sucrose and fructose reference mass fractions were assigned according to
   the mixture identifier.

6. A Savitzky–Golay second-derivative filter was applied using a second-order
   polynomial and a window length of seven spectral variables.

7. Three variables were removed from each end of the selected spectral region
   after derivative filtering.

The final spectral matrix contains 380 variables spanning approximately
409.98–1,492.25 cm⁻¹.


Data structure:
---------------

The files are linked by row and column position:

- Row n of processed_spectra.csv corresponds to row n of processed_ID.csv
  and row n of processed_reference.csv.
- Column m of processed_spectra.csv corresponds to row m of
  processed_wavenumbers.csv.
- Each mixture identifier links to the corresponding formulation in
  data/Raman/raw_data/refvalues.txt and refvalues.xlsx.

Calibration, validation, test, and not-used assignments are defined during
the subsequent data-selection stage and are therefore not included in these
processed-data files.


Usage:
------

From the project root, load the complete dataset in MATLAB using:

    load(fullfile('data', 'Raman', 'processed_data', ...
        'processed_data.mat'))

The CSV files can be imported into MATLAB, Python, R, Excel, or other
data-analysis software. They do not contain header rows; variable identities
and dimensions are documented above.


Related files:
--------------

code/Raman/preprocess_data.m
    Generates the processed dataset from the imported raw data.

code/Raman/select_data_for_analysis.m
    Assigns processed acquisitions to the calibration, validation, and test
    sets.

data/Raman/raw_data/README.txt
    Describes the raw Raman spectra and formulation information.

data/Raman/analysis_data/README.txt
    Describes the analysis-ready datasets and model outputs.

data/Raman/analysis_data/calibration_indices.csv
data/Raman/analysis_data/validation_indices.csv
data/Raman/analysis_data/test_indices.csv
    Row indices linking the selected observations to the processed dataset.


Licence:
--------

Creative Commons Attribution 4.0 International (CC BY 4.0).

See LICENSE.txt in the repository root.


Contact:
--------

For questions concerning the processed dataset or preprocessing workflow,
contact:

Carl Emil Aae Eskildsen
