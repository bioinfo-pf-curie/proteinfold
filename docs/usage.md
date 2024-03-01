# Usage

[Quick help](#quick-help)
Prediction of 3D structures:
- [AlphaFold](#alphafold)
  * [monomer](#monomer)
  * [multimer](#multimer)
- [ColabFold](#colabfold)
  * [monomer](#monomer-1)
  * [multimer](#multimer-1)
- [MassiveFold](#massivefold)
  * [monomer](#monomer-2)
  * [multimer](#multimer-2)
- [Multiple sequence alignments (msas)](#multiple-sequence-alignments-msas)
Molecular docking:
- [DynamicBind](#dynamicbind)


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
    --fromMsas            PATH      Path to existing multiple sequence alignments (msas) to use for the 3D protein strcuture prediction.
                                    Typically the path could be the results of the pipeline launcded with the --onlyMsas option.
    --launchAlphaFold               Launch AlphaFold.
    --launchColabFold               Launch ColabFold.
    --launchMassiveFold             Launch MassiveFold.
    --massiveFoldDatabase PATH      Path to the database required by MassiveFold.
    --massiveFoldHelp               Display all the options available to run MassiveFold. Use this option in combination with -profile
                                    singularity.
    massiveFoldOptions    JSON      Specific options for MassiveFold. As MassiveFold is an AlphaFold-like tool, standard AlphaFold options are
                                    passed using the --alphaFoldOptions option.
    --onlyMsas                      When true, the pipeline will only generate the multiple sequence alignments (msas).
    --outDir              PATH      The output directory where the results will be saved
    --useGpu                        Run the prediction model on GPU. While AlphaFold and MassiveFold can run on CPU, ColabFold requires GPU only.

=======================================================
Available Profiles
   -profile test                        Run the test dataset
   -profile singularity                 Use the Singularity images for each process. Use `--singularityPath` to define the insallation path
   -profile cluster                     Run the workflow on the cluster, instead of locally

```

## AlphaFold

Visit the [AlphaFold](https://github.com/google-deepmind/alphafold/) GitHub repository for more details about the prediction model.

List of AlphaFold options:

```bash
nextflow run main.nf --alphaFoldHelp -profile singularity
```

### Monomer

Launch the nextflow pipeline using GPU:

```bash
nextflow run main.nf -params-file test/params-file/alphafold-monomer.json -profile singularity --useGpu
```

Define the options in a JSON file, for example:

```json
{
	"launchAlphaFold": "true",
	"alphaFoldOptions": "--max_template_date=2024-01-01 --db_preset=full_dbs --random_seed=123456",
	"fastaPath": "test/data/fasta/monomer2"
}
```


### Multimer

Launch the nextflow pipeline using GPU:

```bash
nextflow run main.nf -params-file test/params-file/alphafold-multimer.json -profile singularity --useGpu
```

Define the options in a JSON file, for example:

```json
{
	"launchAlphaFold": "true",
	"alphaFoldOptions": "--max_template_date=2024-01-01 --db_preset=full_dbs --random_seed=123456 --model_preset=multimer",
	"fastaPath": "test/data/fasta/multimer/alphafold"
}
```

## ColabFold

Visit the [ColabFold](https://github.com/sokrypton/ColabFold), GitHub repository for more details about the prediction model.

List of ColabFold options:

```bash
nextflow run main.nf --colabFoldHelp -profile singularity
```

### Monomer

Launch the nextflow pipeline using GPU:

```bash
nextflow run main.nf -params-file test/params-file/colabfold-monomer.json -profile singularity --useGpu
```

Define the options in a JSON file, for example:

```json
{
	"launchColabFold": "true",
	"colabFoldOptions": "--random-seed 654321 --model-type=alphafold2",
	"fastaPath": "test/data/fasta/monomer2"
}
```


### Multimer

Launch the nextflow pipeline using GPU:

```bash
nextflow run main.nf -params-file test/params-file/colabfold-multimer.json -profile singularity --useGpu
```

Define the options in a JSON file, for example:

```json
{
	"launchColabFold": "true",
	"colabFoldOptions": "--random-seed 654321 --model-type=alphafold2_multimer_v3",
	"fastaPath": "test/data/fasta/multimer/colabfold"
}
```

Note that ColabFold expects a particular format for the input fasta file. See [](../test/data/multimer/colabfold/rac1-SOS-complex.fasta)

## MassiveFold

Visit the [MassiveFold](https://github.com/GBLille/MassiveFold) GitHub repository for more details about the prediction model.

List of MassiveFold options:

```bash
nextflow run main.nf --colabFoldHelp -profile singularity
```

### Monomer

Launch the nextflow pipeline using GPU:

```bash
nextflow run main.nf -params-file test/params-file/massivefold-monomer.json -profile singularity --useGpu
```

Define the options in a JSON file, for example:

```json
{
	"launchMassiveFold": "true",
	"alphaFoldOptions": "--max_template_date=2024-01-01 --db_preset=full_dbs --random_seed=123456",
	"fastaPath": "test/data/fasta/monomer2"
}
```


### Multimer

Launch the nextflow pipeline using GPU:

```bash
nextflow run main.nf -params-file test/params-file/massivefold-multimer.json -profile singularity --useGpu
```

Define the options in a JSON file, for example:

```json
{
	"launchMassiveFold": "true",
	"alphaFoldOptions": "--max_template_date=2024-01-01 --db_preset=full_dbs --random_seed=123456 --model_preset=multimer",
	"fastaPath": "test/data/fasta/multimer/alphafold"
}
```

## Multiple sequence alignments (msas)

If you want to perform only msas, launch the pipeline with the option `--onlyMsas`.

If you want to use existing msas, launch the pipeline with the option `--fromMsas`. For example, if you have to predict the structure for two fasta files `protein1.fasta` and `protein2.fasta`, you must have a tree folder such as:

```
msas/
  protein1/
  protein2/
```

Then, provide the option `--fromMsas msas`, for example:


```bash
nextflow run main.nf -params-file test/params-file/frommsas/alphafold-multimer.json -profile singularity --useGpu
```

Define the options in a JSON file, for example:

```json
{
	"launchAlphaFold": "true",
	"alphaFoldOptions": "--max_template_date=2024-01-01 --db_preset=full_dbs --random_seed=123456 --model_preset=multimer",
	"fastaPath": "test/data/fasta/multimer/alphafold",
	"fromMsas": "test/data/msas/multimer/alphafold"
}
```


## DynamicBind

Visit the [DynamicBind](https://github.com/luwei0917/DynamicBind/) GitHub repository for more details about the prediction model.

List of DynamicBind options:

```bash
nextflow run main.nf --dynamicBindHelp -profile singularity
```


Launch the nextflow pipeline using GPU:

```bash
nextflow run main.nf -profile singularity --useGpu --proteinLigandFile protein-ligand.csv
```

The `protein-ligand.csv` is a CSV file which must contain at least the two following columns:
- `protein`: provides the path to the `pdb` 3D structure file
- `ligand`: provided the path to the `sdf` file

Therefore, each row in this file corresponds to a pair protein/ligand to assess their affinity. This file must not contain any space.

