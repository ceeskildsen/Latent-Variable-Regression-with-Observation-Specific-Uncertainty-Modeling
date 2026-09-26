README – Code

Overview:
---------

This folder contains the MATLAB scripts and functions used to prepare the
data, fit the models, perform the analyses, and generate the results reported
in the manuscript.


Associated manuscript:
----------------------

Observation-Specific Uncertainty Modeling for Latent-Variable Regression in
High-Dimensional Analytical Data


Contents:
---------

Raman/
    Scripts for importing and preprocessing the Raman measurements, creating
    the data splits, fitting the partial least-squares and Gaussian-process
    models, and performing the bias-correction and analyte-detection analyses.

AqSolDB/
    Scripts for importing and preparing the AqSolDB data, creating the data
    splits, fitting the partial least-squares and Gaussian-process models, and
    evaluating bias correction and prediction-error uncertainty.

functions/
    Custom MATLAB functions used by the analysis, figure, and table scripts.

README.txt
    Description of the code structure, execution order, dependencies, and
    generated outputs.


Raman workflow:
---------------

Run the following scripts from the project root in the order shown.

1. run('code/Raman/read_raw_data.m')

    Imports the raw Raman spectra and formulation reference information from:

        data/Raman/raw_data/

    Generates:

        data/Raman/raw_data/raw_data_imported.mat


2. run('code/Raman/preprocess_data.m')

    Applies the spectral preprocessing workflow, including fluorescence-
    background correction, spike removal, spectral-region selection, and
    Savitzky–Golay second-derivative filtering.

    Generates:

        data/Raman/processed_data/processed_data.mat
        data/Raman/processed_data/processed_spectra.csv
        data/Raman/processed_data/processed_wavenumbers.csv
        data/Raman/processed_data/processed_ID.csv
        data/Raman/processed_data/processed_reference.csv


3. run('code/Raman/select_data_for_analysis.m')

    Creates reproducible calibration, validation, and test datasets while
    keeping the three repeat acquisitions from each well in the same data
    split.

    Generates:

        data/Raman/analysis_data/data_split.mat
        data/Raman/analysis_data/calibration_spectra.csv
        data/Raman/analysis_data/calibration_reference.csv
        data/Raman/analysis_data/calibration_ID.csv
        data/Raman/analysis_data/calibration_indices.csv
        data/Raman/analysis_data/validation_spectra.csv
        data/Raman/analysis_data/validation_reference.csv
        data/Raman/analysis_data/validation_ID.csv
        data/Raman/analysis_data/validation_indices.csv
        data/Raman/analysis_data/test_spectra.csv
        data/Raman/analysis_data/test_reference.csv
        data/Raman/analysis_data/test_ID.csv
        data/Raman/analysis_data/test_indices.csv
        data/Raman/analysis_data/wavenumbers.csv


4. run('code/Raman/PLSmodel.m')

    Fits the partial least-squares regression model and calculates the
    calibration, validation, and test predictions, prediction errors, latent
    scores, and model-performance measures.

    Generates:

        data/Raman/analysis_data/pls_model.mat


5. run('code/Raman/GPmodel.m')

    Fits a Gaussian-process model for the expected prediction error and a
    heteroscedastic Gaussian-process model for the prediction-error variance.
    It generates observation-specific estimates of prediction bias,
    aleatoric variance, epistemic variance, and total prediction-error
    variance.

    Generates:

        data/Raman/analysis_data/gp_model_results.mat


6. run('code/Raman/bias_correction_analysis.m')

    Evaluates prediction errors before and after bias correction and
    calculates the corresponding mean squared errors and statistical tests.

    Generates:

        data/Raman/analysis_data/bias_correction_results.mat


7. run('code/Raman/analyte_detection_analysis.m')

    Calculates null-space projections, decision limits, detection
    probabilities, and Type I and Type II error rates for the
    analyte-detection analysis.

    Generates:

        data/Raman/analysis_data/analyte_detection_results.mat


AqSolDB workflow:
-----------------

The original third-party AqSolDB dataset is not distributed in this
repository. Before running this workflow, download
curated-solubility-dataset.csv from:

    https://doi.org/10.7910/DVN/OVHAW8

and place it at:

    data/AqSolDB/raw_data/curated-solubility-dataset.csv

Run the following scripts from the project root in the order shown.

1. run('code/AqSolDB/load_AqSolDB.m')

    Imports the original AqSolDB CSV file, extracts the aqueous-solubility
    response, molecular descriptors, compound identifiers, names, and
    molecular representations, and checks the selected variables for missing
    or infinite values.

    Input:

        data/AqSolDB/raw_data/curated-solubility-dataset.csv

    Generates:

        data/AqSolDB/raw_data/AqSolDB_raw.mat


2. run('code/AqSolDB/split_AqSolDB_data.m')

    Creates a reproducible random division of the compounds into calibration,
    validation, and test sets. It also records the source-row index,
    compound identifier, SMILES representation, and initial data assignment
    for every compound.

    Generates:

        data/AqSolDB/analysis_data/AqSolDB_data_split.mat
        data/AqSolDB/analysis_data/AqSolDB_split_assignments.csv

    AqSolDB_data_split.mat is generated locally but excluded from Git because
    it contains the complete third-party predictor and response data. The CSV
    split-assignment file is included in the repository.


3. run('code/AqSolDB/PLSmodel_AqSolDB.m')

    Fits the partial least-squares regression model, performs calibration-set
    screening, applies the final Hotelling’s T² limit to the validation and
    test sets, and calculates model predictions and performance measures.

    Generates:

        data/AqSolDB/analysis_data/pls_model_AqSolDB.mat


4. run('code/AqSolDB/GPmodel_AqSolDB.m')

    Fits a Gaussian-process model for the expected prediction error and a
    heteroscedastic Gaussian-process model for the prediction-error variance
    using the retained validation observations. The fitted models are
    evaluated using the retained test observations.

    Generates:

        data/AqSolDB/analysis_data/gp_model_AqSolDB.mat


5. run('code/AqSolDB/bias_correction_analysis_AqSolDB.m')

    Evaluates compound-level squared prediction errors before and after
    Gaussian-process bias correction and performs the paired statistical
    comparisons reported for Supplementary Fig. 8.

    Generates:

        data/AqSolDB/analysis_data/bias_correction_results_AqSolDB.mat


6. run('code/AqSolDB/uncertainty_evaluation_AqSolDB.m')

    Calculates GP and OLS coverage, prediction-error variances, continuous
    ranked probability scores, and the summary measures reported for
    Supplementary Fig. 9 and Supplementary Table 2.

    Generates:

        data/AqSolDB/analysis_data/uncertainty_evaluation_results_AqSolDB.mat


Custom functions:
-----------------

asysm.m
    Estimates spectral backgrounds using asymmetric least-squares smoothing.

difsmw.m
    Performs weighted smoothing with a finite-difference penalty and is used
    by the asymmetric least-squares procedure.

remove_spikes.m
    Identifies and replaces spectral spikes using principal-component
    residuals calculated within replicate groups.

SavitzkyGolay.m
    Applies Savitzky–Golay smoothing or derivative filtering.

nipals_pls1.m
    Fits a single-response partial least-squares regression model using the
    nonlinear iterative partial least-squares algorithm.

nipals_pca.m
    Performs principal-component analysis using the nonlinear iterative
    partial least-squares algorithm and supports missing values.

GP_heteroscedasticity_fit.m
    Fits the Gaussian-process model for the expected prediction error and the
    Laplace-approximated heteroscedastic Gaussian-process model for the
    residual variance. The function accepts either one predictor or multiple
    predictor columns and returns a reusable fitted model.

GP_heteroscedasticity_predict.m
    Applies a fitted heteroscedastic Gaussian-process model to new predictors
    and returns the estimated expected error, confidence-interval half-width,
    epistemic variance, aleatoric variance, and total prediction-error
    variance. The total variance is the sum of the epistemic and aleatoric
    components.

oblique_project_nullspace.m
    Projects an observation in latent space onto the blank subspace along the
    estimated analyte direction.

mycolor.m
    Plots spectra or other curves coloured according to a supplied variable.

mycolor_scatter.m
    Creates scatter plots in which points are coloured according to a
    supplied variable.

not_so_tight.m
    Adds a small margin around the current plot limits.


Figure and table code:
----------------------

Figure-generating scripts are stored in the code/ subfolder of the
corresponding folder under:

    figures/

Table-generating scripts are stored in the code/ subfolder of the
corresponding folder under:

    tables/

These scripts should also be run from the project root. They use the analysis
files generated by the Raman and AqSolDB workflows. Further information is
provided in the README files within the figure and table folders.


Usage:
------

Set the MATLAB current folder to the project root before running the scripts.

Scripts can be run using their relative paths, for example:

    run('code/Raman/preprocess_data.m')

The scripts resolve their input and output paths relative to the project root.
Scripts that require custom functions add code/functions/ to the MATLAB path
when run.


System requirements:
--------------------

MATLAB R2022a or later

Required toolboxes:

    Statistics and Machine Learning Toolbox
    Optimization Toolbox

No separate installation or compilation of the custom functions is required.
Model-fitting time depends on the dataset size and computer hardware. In
particular, fitting the heteroscedastic Gaussian-process model for AqSolDB may
take substantially longer than the other analysis steps.


Related documentation:
----------------------

data/Raman/raw_data/README.txt
    Describes the raw Raman measurements and data-import procedure.

data/Raman/processed_data/README.txt
    Describes the Raman preprocessing workflow and processed files.

data/Raman/analysis_data/README.txt
    Describes the Raman data splits and model-result files.

data/AqSolDB/README.txt
    Describes the AqSolDB source data, preparation, splitting, and model-result
    files.

figures/README.txt
    Describes the figure folders and figure-generating scripts.

tables/README.txt
    Describes the table folders and table-generating scripts.


Licensing:
----------

The MATLAB source code is licensed under the MIT License. See LICENSE.txt in
the repository root. The third-party AqSolDB dataset is not covered by this
licence and remains subject to the terms of its original repository.


Contact:
--------

For questions concerning the code or reproduction of the analyses, contact:

Carl Emil Aae Eskildsen
