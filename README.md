# ProteinFold

**Institut Curie - Nextflow ProteinFold analysis pipeline**

[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A522.10.6-brightgreen.svg)](https://www.nextflow.io/)
[![Singularity/Apptainer Container](https://img.shields.io/badge/singularity-available-7E4C74.svg)](https://apptainer.org/)


## Introduction

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. 
It comes with singularity/apptainer containers making installation easier and results highly reproducible.


## Pipeline summary

This pipeline allows:

* the prediction of protein 3D structure using various tools:
  - [AFMassive](https://github.com/GBLille/AFMassive).
  - [AlphaFold](https://github.com/google-deepmind/alphafold/),
  - [AlphaFold3](https://github.com/google-deepmind/alphafold3/),
  - [ColabFold](https://github.com/sokrypton/ColabFold),
* molecular docking of protein/ligand using:
  - [DiffDock](https://github.com/gcorso/DiffDock)
  - [DynamicBind](https://github.com/luwei0917/DynamicBind/)
  - [AlphaFill](https://github.com/PDB-REDO/alphafill)
* the navigation of the nanobody mutational space
  - [nanoBERT](https://huggingface.co/NaturalAntibody/)

## Quick help

```
nextflow run main.nf --help
```

```bash
 N E X T F L O W   ~  version 24.10.5

Launching `main.nf` [high_cori] DSL2 - revision: 5992df9705

------------------------------------------------------------------------
      _   _   _   _   _   _   _     _   _   _   _  
     / \ / \ / \ / \ / \ / \ / \   / \ / \ / \ / \ 
    ( P | r | o | t | e | i | n ) ( F | o | l | d )
     \_/ \_/ \_/ \_/ \_/ \_/ \_/   \_/ \_/ \_/ \_/ 
    
                   vtag:v1.6.2-commit:ca3bbb3aa05ccf1db6db208c8ce0d81ebb1dc3f0
------------------------------------------------------------------------


    Usage:

    The typical command for running the pipeline is as follows:

    nextflow run main.nf -params-file params.json -profile STRING 

MANDATORY ARGUMENTS, NEXTFLOW:
    -profile  STRING [test, singularity, cluster]  Configuration profile to use. Can use multiple (comma separated).

OTHER OPTIONS, NEXTFLOW:
    -params-file  JSON   Set the parameters of the pipeline using a JSON file configuration file (i.e. 'params.json'). All parameters defined as JSON type 
                         must be this way. For example, the JSON can contain: "alphaFoldOptions": "--max_template=2024-01-01 --multimer". WARNING: passing 
                         the option '--alphaFoldOptions' in command line will throw an error when the option contains '-' or '--' characters which are not 
                         appreciated by nextflow.

OTHER OPTIONS:
    --fastaPath PATH   Path to the input directory which contains the fasta files.
    --outDir    PATH   The output directory where the results will be saved

REFERENCES:
    --genomeAnnotationPath PATH   Path to genome/proteome annotations folder used to predict the protein 3D structure.

AFMASSIVE:
    --afMassiveDatabase   PATH     Path to the database required by AFMassive.
    --afMassiveHelp       BOOL     Display all the options available to run AFMassive. Use this option in combination with -profile singularity.
    --afMassiveOptions    STRING   Specific options for AFMassive. As AFMassive is an AlphaFold-like tool, standard AlphaFold options are passed using the 
                                   --alphaFoldOptions option.
    --frommsas            BOOL     When true, the pipeline will skip the multiple sequence alignments (msas).
    --launchAfMassive     BOOL     Launch AFMassive
    --multimerVersions    STRING   AlphaFold multimer model versions (v1, v2, v3) which will be evaluated by AFMassive. This parameter is taken into 
                                   account when --launchAfMassive is true. The list of the versions to be evaluated must be provided with a comma 
                                   separated string, e.g. 'v1,v2', Default is 'v1,v2,v3'.
    --numberOfModels      INT      Number of models that will be evaluated by AFMassive. This parameter is taken into account when --launchAfMassive is 
                                   true. (Default 5)
    --onlymsas            BOOL     When true, the pipeline will only generate the multiple sequence alignments (msas).
    --predictionsPerModel INT      Number of predictions per model which will be evaluated by AFMassive. This parameter is taken into account when 
                                   --launchAfMassive is true. (Default 5)
    --useGpu              BOOL     Run the prediction model on GPU. AFMassive can run either on CPU or GPU.

ALPHAFILL:
    --alphaFillHelp   BOOL   Display all the options available to run AlphaFill. Use this option in combination with -profile singularity.
    --launchAlphaFill BOOL   Launch AlphaFill.

ALPHAFOLD:
    --alphaFoldDatabase PATH     Path to the database required by AlphaFold.
    --alphaFoldHelp     BOOL     Display all the options available to run AlphaFold. Use this option in combination with -profile singularity.
    --alphaFoldOptions  STRING   Prediction model options passed to AlphaFold or AFMassive.
    --frommsas          BOOL     When true, the pipeline will skip the multiple sequence alignments (msas).
    --launchAlphaFold   BOOL     Launch AlphaFold.
    --onlymsas          BOOL     When true, the pipeline will only generate the multiple sequence alignments (msas).
    --useGpu            BOOL     Run the prediction model on GPU. AlphaFold can run either on CPU or GPU.

ALPHAFOLD3:
    --alphaFold3Database PATH     Path to the database required by AlphaFold3.
    --alphaFold3Help     BOOL     Display all the options available to run AlphaFold3. Use this option in combination with -profile singularity.
    --alphaFold3Options  STRING   Prediction model options passed to AlphaFold3.
    --frommsas           BOOL     When true, the pipeline will skip the multiple sequence alignments (msas).
    --launchAlphaFold3   BOOL     Launch AlphaFold3.
    --onlymsas           BOOL     When true, the pipeline will only generate the multiple sequence alignments (msas).
    --useGpu             BOOL     Mandatory -- Run the prediction model on GPU. AlphaFold3 run only on GPU.

COLABFOLD:
    --colabFoldDatabase PATH     Path to the database required by ColabFold.
    --colabFoldHelp     BOOL     Display all the options available to run ColabFold. Use this option in combination with -profile singularity.
    --colabFoldOptions  STRING   Prediction model options passed to ColabFold.
    --frommsas          BOOL     When true, the pipeline will skip the multiple sequence alignments (msas).
    --launchColabFold   BOOL     Launch ColabFold.
    --onlymsas          BOOL     When true, the pipeline will only generate the multiple sequence alignments (msas).
    --useGpu            BOOL     Mandatory -- Run the prediction model on GPU. ColabFold require GPU only.

DIFFDOCK:
    --diffDockArgsYamlFile YAML   Path to the YAML file with the DiffDock options. 
    --diffDockDatabase     PATH   Path to the database required by DiffDock.
    --launchDiffDock       BOOL   Launch DiffDock.
    --proteinLigandFile    PATH   Path to the input file for molecular docking. The file must be in CSV format, without space. One column named 'protein' 
                                  contains the path the the 'pdb' file and one column named 'ligand' must contain the path to the 'sdf' file.

DYNAMICBIND:
    --dynamicBindDatabase PATH     Path to the database required by DynamicBind.
    --dynamicBindHelp     BOOL     Display all the options available to run DynamicBind. Use this option in combination with -profile singularity.
    --dynamicBindOptions  STRING   Prediction model options passed to DynamicBind.
    --launchDynamicBind   BOOL     Launch DynamicBind.
    --proteinLigandFile   PATH     Path to the input file for molecular docking. The file must be in CSV format, without space. One column named 'protein' 
                                   contains the path the the 'pdb' file and one column named 'ligand' must contain the path to the 'sdf' file.
    --useGpu              BOOL     Mandatory -- Run the prediction model on GPU. DynamicBind require GPU only.

=======================================================
Available Profiles
   -profile test                        Run the test dataset
   -profile singularity                 Use the Singularity images for each process. Use `--singularityPath` to define the insallation path
   -profile cluster                     Run the workflow on the cluster, instead of locally


```

## Quick run

The pipeline can be run on any infrastructure. The use of GPU is preferred (and even required for some tools) to speed-up computation.

### Run the pipeline on a test dataset

See the `conf/test.config` to set your test dataset.

```
nextflow run main.nf -profile test,singularity
```

### Run the pipeline with custom option

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


### Run the pipeline on a computing cluster

For example, to launch the pipeline on a computing cluster with SLURM:

```bash
echo "#! /bin/bash" > launcher.sh
echo "set -oue pipefail" >> launcher.sh
echo nextflow run main.nf --fastaPath="test/data" -params-file params.json --outDir MY_OUTPUT_DIR -profile singularity,cluster >> launcher.sh
sbatch launcher.sh
```


## Full Documentation

1. [Installation](docs/installation.md)
2. [Running the pipeline](docs/usage.md)
3. [Output of the pipelines](docs/output.md)

## Credits

This pipeline has been written by the bioinformatics platform of the Institut Curie (P. Hupé).

This work was granted access to the HPC resources of IDRIS under the allocation 2024-AD010315541 made by GENCI.

## Citation

## Contacts

For any question, bug or suggestion, please use the issues system or contact the bioinformatics core facility.
