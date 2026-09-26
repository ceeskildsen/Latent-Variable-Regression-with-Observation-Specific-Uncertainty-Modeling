README - AqSolDB Source Data

The original AqSolDB dataset is third-party material and is not distributed
in this repository.

Download:

    curated-solubility-dataset.csv

from the Harvard Dataverse record:

    https://doi.org/10.7910/DVN/OVHAW8

Place the downloaded file in this folder so that its path is:

    data/AqSolDB/raw_data/curated-solubility-dataset.csv

Then run the following scripts from the project root:

    run('code/AqSolDB/load_AqSolDB.m')
    run('code/AqSolDB/split_AqSolDB_data.m')

The first script generates AqSolDB_raw.mat in this folder. The second script
recreates AqSolDB_data_split.mat and the reproducible split-assignment CSV
using the fixed random-number seed documented in data/AqSolDB/README.txt.

The downloaded CSV, locally generated AqSolDB_raw.mat, and complete MATLAB
split dataset are excluded from Git tracking. They remain subject to the
licence, attribution requirements, and terms associated with the original
AqSolDB record.
