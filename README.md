# ProteinFold

**Institut Curie - Nextflow ProteinFold analysis pipeline**

[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A522.10.6-brightgreen.svg)](https://www.nextflow.io/)
[![Singularity/Apptainer Container](https://img.shields.io/badge/singularity-available-7E4C74.svg)](https://apptainer.org/)


### Introduction

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. 
It comes with singularity/apptainer containers making installation easier and results highly reproducible.


### Pipeline summary

This pipeline allows the prediction of protein 3D structure using various tools:

* [AlphaFold](https://github.com/google-deepmind/alphafold/),
* [ColabFold](https://github.com/sokrypton/ColabFold),
* [MassiveFold](https://github.com/GBLille/MassiveFold).

### Quick help

```
nextflow run main.nf --help
```

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

    nextflow run main.nf -params-file params.json -profile STRING --fastaPath PATH 

MANDATORY ARGUMENTS, NEXTFLOW:
    -profile  STRING [test, singularity, cluster]  Configuration profile to use. Can use multiple (comma separated).

OTHER OPTIONS, NEXTFLOW:
    -params-file  PATH   Set the parameters of the pipeline using a JSON file configuration filei (i.e. 'params.json'). All parameters defined as JSON 
                         type must be this way. For example, the JSON can contain: "alphaFoldOptions": "--max_template=2024-01-01 --multimer". WARNING: 
                         passing the option '--alphaFoldOptions' in command line will throw an error when the option contains '-' or '--' characters which 
                         are not appreciated by nextflow.

MANDATORY ARGUMENTS:
    --fastaPath PATH   Path to the input directory which contains the fasta files.

REFERENCES:
    --genomeAnnotationPath PATH   Path to genome/proteome annotations folder used to predict the protein 3D structure.

OTHER OPTIONS:
    --alphaFoldDatabase   PATH      Path to the database required by AlphaFold.
    --alphaFoldHelp                 Display all the options available to run AlphaFold. Use this option in combination with -profile singularity.
    alphaFoldOptions      JSON      Prediction model options passed to AlphaFold or MassiveFold.
    --colabFoldDatabase   PATH      Path to the database required by ColabFold.
    --colabFoldHelp                 Display all the options available to run ColabFold. Use this option in combination with -profile singularity.
    colabFoldOptions      JSON      Prediction model options passed to ColabFold.
    --launchAlphaFold               Launch AlphaFold.
    --launchColabFold               Launch ColabFold.
    --launchMassiveFold             Launch MassiveFold.
    --massiveFoldDatabase PATH      Path to the database required by MassiveFold.
    --massiveFoldHelp               Display all the options available to run MassiveFold. Use this option in combination with -profile 
                                    singularity.
    massiveFoldOptions    JSON      Specific options for MassiveFold. As MassiveFold is an AlphaFold-like tool, standard AlphaFold options are 
                                    passed using the --alphaFoldOptions option.
    --outDir              PATH      The output directory where the results will be saved
    --useGpu                        Run the prediction model on GPU. While AlphaFold and MassiveFold can run on CPU, ColabFold requires GPU only.

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
2. [Reference annotations](docs/referenceGenomes.md)
3. [Running the pipeline](docs/usage.md)
4. [Output of the pipelines](docs/output.md)

#### Credits

This pipeline has been written by the bioinformatics platform of the Institut Curie (P. Hupé)

#### Citation

#### Contacts

For any question, bug or suggestion, please use the issues system or contact the bioinformatics core facility.
