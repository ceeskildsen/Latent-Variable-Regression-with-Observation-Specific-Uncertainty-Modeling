README – AqSolDB Data

Overview:
---------

This folder documents the third-party AqSolDB aqueous-solubility dataset and
contains the reproducible split assignments and derived model and analysis
results used in the manuscript:

Observation-Specific Uncertainty Modeling for Latent-Variable Regression in
High-Dimensional Analytical Data

AqSolDB is a curated dataset containing experimental aqueous-solubility
values, validated molecular representations, and two-dimensional molecular
descriptors for 9,982 unique compounds.

The original AqSolDB CSV and its locally generated raw MATLAB representation
are not distributed in this repository. They must be obtained and generated
locally as described below.


Original dataset:
-----------------

Dataset:

    AqSolDB: A curated reference set of aqueous solubility and 2D descriptors
    for a diverse set of compounds

Authors:

    Murat Cihan Sorkun
    Abhishek Khetan
    Süleyman Er

Dataset repository:

    Harvard Dataverse
    https://doi.org/10.7910/DVN/OVHAW8

Associated publication:

    Sorkun, M. C., Khetan, A. & Er, S. AqSolDB, a curated reference set of
    aqueous solubility and 2D descriptors for a diverse set of compounds.
    Scientific Data 6, 143 (2019).
    https://doi.org/10.1038/s41597-019-0151-1

Source-code repository:

    https://github.com/mcsorkun/AqSolDB


Folder structure:
-----------------

raw_data/
    Contains download instructions. After the source dataset is downloaded,
    this folder is also the local location of the original AqSolDB CSV and
    the MATLAB representation generated for the present analysis. Those two
    files are excluded from Git tracking.

analysis_data/
    Contains the reproducible split-assignment CSV and the fitted partial
    least-squares and Gaussian-process model and evaluation results. The
    complete MATLAB split dataset is generated locally and excluded from Git.

README.txt
    Description of the AqSolDB source data, data preparation, data splitting,
    and analysis files.


Raw data:
---------

raw_data/curated-solubility-dataset.csv
    Original curated AqSolDB dataset containing 9,982 compounds. This file is
    not included in the repository. Download it from:

        https://doi.org/10.7910/DVN/OVHAW8

    and save it at:

        data/AqSolDB/raw_data/curated-solubility-dataset.csv

    The file includes compound identifiers, names, InChI representations,
    InChIKeys, SMILES representations, experimental aqueous solubility in
    LogS units, reliability information, and 17 molecular descriptors.

raw_data/AqSolDB_raw.mat
    MATLAB representation of the variables extracted from
    curated-solubility-dataset.csv using:

        code/AqSolDB/load_AqSolDB.m

    This generated file is also excluded from Git tracking. Despite its
    filename, AqSolDB_raw.mat is not an unmodified copy of the source data. It
    contains the response, selected molecular descriptors, and compound
    metadata prepared for the subsequent analysis.


AqSolDB_raw.mat variables:
--------------------------

X
    A 9,982 × 17 matrix containing the molecular descriptors used as
    predictors.

y
    A 9,982 × 1 vector containing the experimental aqueous-solubility values
    in LogS units.

varNames
    A 1 × 17 cell array containing the descriptor names in the same order as
    the columns of X.

SMILES
    A 9,982 × 1 string vector containing the SMILES representation of each
    compound.

compoundNames
    A 9,982 × 1 string vector containing the compound names.

compoundIDs
    A 9,982 × 1 vector containing the unique AqSolDB compound identifiers.

No rows were removed when the current AqSolDB_raw.mat file was generated,
because the selected descriptor and response variables contained no missing
or infinite values.


Molecular descriptors:
----------------------

The 17 columns of X are stored in the following order:

1.  BalabanJ
2.  BertzCT
3.  HeavyAtomCount
4.  LabuteASA
5.  MolLogP
6.  MolMR
7.  MolWt
8.  NumAliphaticRings
9.  NumAromaticRings
10. NumHAcceptors
11. NumHDonors
12. NumHeteroatoms
13. NumRotatableBonds
14. NumSaturatedRings
15. NumValenceElectrons
16. RingCount
17. TPSA

This order is also stored in the varNames variable in AqSolDB_raw.mat.


Data splitting:
---------------

The compounds were randomly divided into calibration, validation, and test
sets using:

    code/AqSolDB/split_AqSolDB_data.m

The MATLAB random-number seed was set to 1 using the twister generator.

The initial split contains:

Calibration:
    2,496 compounds
    Approximately 25% of the complete dataset
    Used to fit the partial least-squares regression model

Validation:
    2,496 compounds
    Approximately 25% of the complete dataset
    Used to fit the Gaussian-process bias and variance models

Test:
    4,990 compounds
    Approximately 50% of the complete dataset
    Used for final model evaluation

The three sets do not overlap. Their membership is recorded in the included
AqSolDB_split_assignments.csv file using the source-row index, compound
identifier, SMILES representation, and initial split assignment.


Analysis data:
--------------

analysis_data/AqSolDB_data_split.mat
    Generated by:

        code/AqSolDB/split_AqSolDB_data.m

    Contains the initial calibration, validation, and test datasets. This
    file is generated locally but excluded from Git because it contains the
    complete third-party predictor and response data.

    Variables:

    Xcal
        A 2,496 × 17 matrix of calibration-set molecular descriptors.

    ycal
        A 2,496 × 1 vector of calibration-set LogS values.

    IDs_cal
        Compound identifiers for the calibration set.

    SMILES_cal
        SMILES representations for the calibration set.

    Xval
        A 2,496 × 17 matrix of validation-set molecular descriptors.

    yval
        A 2,496 × 1 vector of validation-set LogS values.

    IDs_val
        Compound identifiers for the validation set.

    SMILES_val
        SMILES representations for the validation set.

    Xtest
        A 4,990 × 17 matrix of test-set molecular descriptors.

    ytest
        A 4,990 × 1 vector of test-set LogS values.

    IDs_test
        Compound identifiers for the test set.

    SMILES_test
        SMILES representations for the test set.

    varNames
        Descriptor names corresponding to the columns of Xcal, Xval, and
        Xtest.

analysis_data/AqSolDB_split_assignments.csv
    Included in the repository. Contains one row per AqSolDB compound and the
    following columns:

    source_row_index
        One-based row index in curated-solubility-dataset.csv.

    compound_ID
        AqSolDB compound identifier.

    SMILES
        Molecular SMILES representation.

    initial_split
        Initial calibration, validation, or test assignment generated using
        the fixed random-number seed above.


Partial least-squares model:
----------------------------

analysis_data/pls_model_AqSolDB.mat
    Generated by:

        code/AqSolDB/PLSmodel_AqSolDB.m

    An initial partial least-squares model with four latent variables was used
    to identify calibration observations with large cross-validated residuals
    or Hotelling’s T² values.

    A final partial least-squares model with six latent variables was fitted
    after calibration-set screening. Validation and test observations were
    subsequently screened using the final Hotelling’s T² limit.

    Numbers of retained compounds:

    Calibration:
        2,345 of 2,496 compounds retained
        151 compounds excluded during calibration screening

    Validation:
        2,181 of 2,496 compounds retained
        315 compounds excluded using the final Hotelling’s T² limit

    Test:
        4,397 of 4,990 compounds retained
        593 compounds excluded using the final Hotelling’s T² limit

    The file contains the partial least-squares model parameters, latent
    scores, predictions, residuals, cross-validation results, performance
    metrics, screening limits, and logical retention indices.

    The variables idx_cal, idx_val, and idx_test in this file are logical
    indicators of observations retained during model screening. They are not
    the indices used to create the original random data split.


Gaussian-process models:
------------------------

analysis_data/gp_model_AqSolDB.mat
    Generated by:

        code/AqSolDB/GPmodel_AqSolDB.m

    Contains the Gaussian-process models trained using the retained validation
    observations and evaluated using the retained test observations.

    Variables include:

    gp_model
        Fitted two-stage heteroscedastic Gaussian-process model containing
        the mean and variance components.

    E_e_test_hat
        A 4,397 × 1 vector containing the estimated expected prediction error
        for each retained test compound.

    Var_epi_test_hat
        A 4,397 × 1 vector containing the epistemic variance for each
        retained test compound.

    Var_ale_test_hat
        A 4,397 × 1 vector containing the aleatoric variance for each
        retained test compound.

    Var_total_test_hat
        A 4,397 × 1 vector containing the estimated total prediction-error
        variance for each retained test compound.

    All stored test-set bias estimates and total variance estimates are
    finite, and all total variance estimates are positive.


Evaluation results:
-------------------

analysis_data/bias_correction_results_AqSolDB.mat
    Generated by code/AqSolDB/bias_correction_analysis_AqSolDB.m. Contains
    the corrected predictions, squared prediction errors, mean squared errors,
    percentage reduction, and paired-test results used for Supplementary
    Fig. 8.

analysis_data/uncertainty_evaluation_results_AqSolDB.mat
    Generated by code/AqSolDB/uncertainty_evaluation_AqSolDB.m. Contains the
    GP and OLS coverage results, prediction-error variances, continuous ranked
    probability scores, and summary measures used for Supplementary Fig. 9
    and Supplementary Table 2.


Data relationships:
-------------------

- Rows of X, y, SMILES, compoundNames, and compoundIDs in AqSolDB_raw.mat
  refer to the same compounds.

- Rows within each split in AqSolDB_data_split.mat refer to the same compounds
  across the predictor, response, identifier, and SMILES variables.

- Columns of the predictor matrices correspond to the descriptor order stored
  in varNames.

- The retention indices in pls_model_AqSolDB.mat are applied to the
  corresponding initial calibration, validation, and test variables in
  AqSolDB_data_split.mat.

- The rows of E_e_test_hat, Var_epi_test_hat, Var_ale_test_hat, and
  Var_total_test_hat correspond to the retained test observations after
  application of idx_test.


Reproducing the analysis:
-------------------------

First download curated-solubility-dataset.csv from:

    https://doi.org/10.7910/DVN/OVHAW8

and place it at:

    data/AqSolDB/raw_data/curated-solubility-dataset.csv

Then set the MATLAB current folder to the project root and run:

    run('code/AqSolDB/load_AqSolDB.m')
    run('code/AqSolDB/split_AqSolDB_data.m')
    run('code/AqSolDB/PLSmodel_AqSolDB.m')
    run('code/AqSolDB/GPmodel_AqSolDB.m')
    run('code/AqSolDB/bias_correction_analysis_AqSolDB.m')
    run('code/AqSolDB/uncertainty_evaluation_AqSolDB.m')

The scripts must be run in this order because each script uses files generated
by the preceding step.


Loading the data:
-----------------

Load the prepared AqSolDB variables in MATLAB using:

    load(fullfile('data', 'AqSolDB', 'raw_data', 'AqSolDB_raw.mat'))

Load the initial data split using:

    load(fullfile('data', 'AqSolDB', 'analysis_data', ...
        'AqSolDB_data_split.mat'))

Load a fitted model using, for example:

    load(fullfile('data', 'AqSolDB', 'analysis_data', ...
        'pls_model_AqSolDB.mat'))


Related code:
-------------

code/AqSolDB/load_AqSolDB.m
    Imports the original AqSolDB CSV file, extracts the response and
    descriptors, checks for invalid values, and generates AqSolDB_raw.mat.

code/AqSolDB/split_AqSolDB_data.m
    Generates the reproducible calibration, validation, and test split.

code/AqSolDB/PLSmodel_AqSolDB.m
    Fits and evaluates the partial least-squares regression model and applies
    the model-screening procedure.

code/AqSolDB/GPmodel_AqSolDB.m
    Fits the Gaussian-process bias and variance models and evaluates them on
    the retained test set.

code/AqSolDB/bias_correction_analysis_AqSolDB.m
    Evaluates the effect of Gaussian-process bias correction on the retained
    test compounds.

code/AqSolDB/uncertainty_evaluation_AqSolDB.m
    Evaluates GP and OLS prediction-error uncertainty on the retained test
    compounds.


Licence and attribution:
------------------------

AqSolDB is a third-party dataset. Use and redistribution of the original data
are governed by the terms supplied with the original AqSolDB repository and
dataset record.

Users of this dataset should cite both the AqSolDB dataset and its associated
Scientific Data publication listed above. The licence applied to the present
project does not replace the original AqSolDB attribution and licensing
requirements.

The original AqSolDB CSV and its locally generated raw MATLAB representation
are excluded from this repository. See LICENSE.txt in the repository root for
the licensing terms applying to the project software and other original
material.


Contact:
--------

For questions concerning the use of AqSolDB in the present analysis, contact:

Carl Emil Aae Eskildsen
