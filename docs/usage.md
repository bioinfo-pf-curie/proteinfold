# Usage

## Quick help

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
