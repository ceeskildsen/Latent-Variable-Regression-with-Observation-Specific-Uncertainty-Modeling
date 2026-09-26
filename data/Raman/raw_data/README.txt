README – Raw Raman Data

Overview:
---------

This folder contains the raw Raman spectra, acquisition metadata, and
formulation reference information for the fructose–sucrose model system.

The dataset comprises 51 mixture formulations. Each formulation was measured
in 32 wells, with three repeat spectral acquisitions from each well. Each
repeat acquisition is stored as a separate spectrum.

The complete dataset contains 4,896 spectra:

51 formulations × 32 wells × 3 repeat acquisitions = 4,896 spectra


Associated manuscript:
----------------------

Observation-Specific Uncertainty Modeling for Latent-Variable Regression in
High-Dimensional Analytical Data


Contents:
---------

TRUST-MDX_240302_MIX-##_spectra.csv
    Raw Raman spectra exported in CSV format. Each file corresponds to one
    mixture formulation and contains 96 spectra and the Raman-shift axis.

TRUST-MDX_240302_MIX-##_spectra.txt
    Raw Raman spectra exported in TXT format.

meta_data/
    Acquisition and instrument metadata associated with the raw spectra.

refvalues.txt
refvalues.xlsx
    Formulation-design information for the sucrose, fructose, and water
    components. These values are used to calculate the sucrose and fructose
    mass fractions associated with each mixture formulation.

raw_data_imported.mat
    MATLAB representation of the imported raw spectra and reference
    information, generated using code/Raman/read_raw_data.m.

README.txt
    Description of the raw dataset and its organisation.


Data structure:
---------------

Each spectral file corresponds to one mixture formulation and contains:

    32 wells
    3 repeat acquisitions per well
    96 spectra in total

In the CSV files, each spectrum occupies one column. The final column contains
the Raman-shift axis in cm⁻¹.

Spectrum identifiers encode the plate, well, sample, aliquot, measurement
point, measurement round, and repeat number. For example:

TRUST-MDX_2024-03-02_PLT-01_WELL-A01_SAMP-001_ALQ-A_PNT-1_RND-1_REP-1

Mixture numbers in the spectral filenames link the spectra to the formulation
information in refvalues.txt and refvalues.xlsx.

Calibration, validation, and test assignments are defined during the
subsequent data-selection stage.


Acquisition details:
--------------------

Instrument:
    B-Raman

Acquisition dates:
    March 2024

Operators:
    Carl Emil Aae Eskildsen
    Alvaro Galiana

Spectral values:
    Raman intensity in arbitrary units

Spectral axis:
    Raman shift in cm⁻¹

Further acquisition and instrument settings are provided in the corresponding
files in meta_data/.


Imported MATLAB variables:
--------------------------

raw_data_imported.mat contains:

X
    A 4,896 × 2,000 matrix of raw Raman intensities. Rows represent spectral
    acquisitions and columns represent spectral variables.

wn
    Raman-shift values corresponding to the columns of X.

ID
    Mixture-formulation identifier for each spectral acquisition.

ref_values
    Calculated sucrose and fructose mass fractions for each mixture
    formulation.

ref_varID
    Names of the reference variables.


Usage:
------

From the project root, run:

    run('code/Raman/read_raw_data.m')

The script reads the raw CSV files and formulation information and generates
raw_data_imported.mat.


Related files:
--------------

code/Raman/read_raw_data.m
    Imports the raw spectra and calculates the reference mass fractions.

code/Raman/preprocess_data.m
    Applies the spectral preprocessing workflow.

data/Raman/processed_data/README.txt
    Describes the processed Raman dataset.

data/Raman/analysis_data/README.txt
    Describes the analysis-ready data and model outputs.


Licence:
--------

Creative Commons Attribution 4.0 International (CC BY 4.0).

See LICENSE.txt in the repository root.


Contact:
--------

For questions concerning the raw data or acquisition protocol, contact:

Carl Emil Aae Eskildsen
