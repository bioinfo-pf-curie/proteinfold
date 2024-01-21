# RNA-seq 

**Institut Curie - Nextflow rna-seq analysis pipeline**

[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A520.10.0-brightgreen.svg)](https://www.nextflow.io/)
[![MultiQC](https://img.shields.io/badge/MultiQC-1.11-blue.svg)](https://multiqc.info/)
[![Install with conda](https://img.shields.io/badge/install%20with-conda-brightgreen.svg)](https://conda.anaconda.org/anaconda)
[![Singularity Container available](https://img.shields.io/badge/singularity-available-7E4C74.svg)](https://singularity.lbl.gov/)
[![Docker Container available](https://img.shields.io/badge/docker-available-003399.svg)](https://www.docker.com/)


### Introduction

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. 
It comes with conda / singularity containers making installation easier and results highly reproducible.


### Pipeline summary

This pipeline allows the prediction of protein 3D structure using [AlphaFold](https://github.com/google-deepmind/alphafold/).

### Quick help

```bash
N E X T F L O W  ~  version 22.10.6
Launching `main.nf` [curious_perlman] DSL2 - revision: 986ad6e9f0
------------------------------------------------------------------------
      _   _   _   _   _   _   _     _   _   _   _  
     / \ / \ / \ / \ / \ / \ / \   / \ / \ / \ / \ 
    ( P | r | o | t | e | i | n ) ( F | o | l | d )
     \_/ \_/ \_/ \_/ \_/ \_/ \_/   \_/ \_/ \_/ \_/ 
    
------------------------------------------------------------------------

------------------------------------------------------------------------


    Usage:

    The typical command for running the pipeline is as follows:

    nextflow run main.nf --fastaPath PATH -profile PROFILES

MANDATORY ARGUMENTS:
    --fastaPath PATH   Path to the input directory which contains the fasta files

REFERENCES:
    --genomeAnnotationPath PATH   Path to genome annotations folder

OTHER OPTIONS:
    -params-file    
    --alphaFoldOptions PATH   Prediction model options passed to alphaFold. This parameter must be set in a JSON file (i.e. 'params.json') and passed
                              to nextflow with the option -params-file. For example, the JSON can contain: "alphaFoldOptions":
                              "--max_template=2024-01-01 --multimer". WARNING: passing the option '--alphaFoldOptions' in command line may result in
                              some errors when the option contains '-' or '--' characters which are not appreciated by nextflow.
    --outDir           PATH   The output directory where the results will be saved

=======================================================
Available Profiles
   -profile test                        Run the test dataset
   -profile singularity                 Use the Singularity images for each process. Use `--singularityPath` to define the insallation path
   -profile cluster                     Run the workflow on the cluster, instead of locally

```

### Quick run

The pipeline can be run on any infrastructure. The use of GPU is preferred to speed-up computation.

#### Run the pipeline on a test dataset

See the `conf/test.config` to set your test dataset.

```
nextflow run main.nf -profile test,singularity
```

#### Run the pipeline with custom option

Create a json file with your custom parameters, for example:

```json
{
  "alphaFoldOptions": "--max_template_date=2024-01-01 --random_seed=654321"
}
```

Launch nextflow with the `-params-file` options:
```
nextflow run main.nf --fastaPath="test/data" -params-file params.json --outDir MY_OUTPUT_DIR -profile singularity
```


#### Run the pipeline on a computing cluster

For example, to launch the pipeline on a computing cluster with SLURM:

```
echo "#! /bin/bash" > launcher.sh
echo "set -oue pipefail" >> launcher.sh
echo "nextflow run main.nf --fastaPath=\"test/data\" --alphaFoldOptions \"max_template_date=2024-01-01|random_seed=654321\" --outDir MY_OUTPUT_DIR -profile singularity,cluster" >> launcher.sh
sbatch launcher
```


### Full Documentation

1. [Installation](docs/installation.md)
2. [Reference genomes](docs/referenceGenomes.md)
3. [Running the pipeline](docs/usage.md)
4. [Output and how to interpret the results](docs/output.md)
5. [Troubleshooting](docs/troubleshooting.md)

#### Credits

This pipeline has been written by the bioinformatics platform of the Institut Curie (P. Hupé)

#### Citation

#### Contacts

For any question, bug or suggestion, please use the issues system or contact the bioinformatics core facility.
