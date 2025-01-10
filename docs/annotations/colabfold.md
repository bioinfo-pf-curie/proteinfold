# Installation of data required by ColabFold

To install some dependencies, it is needed to build the apptainer `colabfold.sif` image using geniac from the ProteinFold pipeline. Copy the `colabfold.sif` image in your `$TMPDIR` folder.

Install the following software:

- `aria2c`: [https://aria2.github.io/](https://aria2.github.io/)
- `mmseqs`: [https://github.com/soedinglab/mmseqs2](https://github.com/soedinglab/mmseqs2)

Make sure their are in your PATH.


## Annotations


Create the bash script `download-database.sh` and modify the different variables if needed:


```bash
#! /bin/bash

set -oue pipefail

# set variables
TMPDIR="$HOME/tmp/"
DOWNLOAD_DIR="$TMPDIR/colabfold"
mkdir -p $TMPDIR
mkdir -p $DOWNLOAD_DIR

# ColabFold script to download the database
wget https://raw.githubusercontent.com/sokrypton/ColabFold/refs/tags/v1.5.5/setup_databases.sh -P $TMPDIR

MMSEQS_NO_INDEX=1 $TMPDIR/setup_databases.sh $DOWNLOAD_DIR

```

Launch `bash download-database.sh`


## Download model parameters

Build the colabfold sif image by launching the CI/CD pipeline: set `BUILD_SIF=true` as described in [README.md](../README.md).

Launch `bash download-alphafold2-weights.sh`

Create the bash script `download-params.sh` and modify the different variables if needed:


```bash

set -oue pipefail

# set variables
TMPDIR="$HOME/tmp/"
DOWNLOAD_DIR="$TMPDIR/colabfold/params"
mkdir -p $DOWNLOAD_DIR

COLABFOLD_SIF="$TMPDIR/colabfold.sif"
apptainer run -B $DOWNLOAD_DIR:/cache $COLABFOLD_SIF python -m colabfold.download alphafold2_multimer_v3
apptainer run -B $DOWNLOAD_DIR:/cache $COLABFOLD_SIF python -m colabfold.download alphafold2_multimer_v2
apptainer run -B $DOWNLOAD_DIR:/cache $COLABFOLD_SIF python -m colabfold.download alphafold2_multimer_v1
apptainer run -B $DOWNLOAD_DIR:/cache $COLABFOLD_SIF python -m colabfold.download AlphaFold2-ptm
apptainer run -B $DOWNLOAD_DIR:/cache $COLABFOLD_SIF python -m colabfold.download deepfold_v1

```

Launch `bash download-params.sh`


## Copy the data in the appropriate folder and modify the `conf/process.config` file

Assuming that the nextflow parameters `params.genomeAnnotationPath` is set to the path  `/data/annotations`, move the data in the following folder:

```
mkdir -p /data/annotations/proteinfold/
mv $TMPDIR/colabfold /data/annotations/proteinfold/
```

Then, set the correct values the the parameter `params.genomes.colabfold.database` in the `conf/genomes.config` file accordingly, for example:

```
params {
  genomes {
    colabfold {
      database = "${params.genomeAnnotationPath}/proteinfold/colabfold"
    }
  }
}
```
