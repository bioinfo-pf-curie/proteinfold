# Usage

[Quick help](#quick-help)

**Prediction of 3D structures:**

- [AFMassive](#admassive)
  * [monomer](#monomer)
  * [multimer](#multimer)
- [AlphaFold](#alphafold)
  * [monomer](#monomer-1)
  * [multimer](#multimer-1)
- [ColabFold](#colabfold)
  * [monomer](#monomer-2)
  * [multimer](#multimer-2)
- [Multiple sequence alignments (msas)](#multiple-sequence-alignments-msas)

**Molecular docking:**

- [AlphaFill](#alphafill)
- [DiffDock](#diffdock)
- [DynamicBind](#dynamicbind)

**Nanobody mutational space**
  
- [nanoBERT](#nanobert)

**MultiQC HTML report from existing results**

- [MultiQC](#multiqc)

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

    nextflow run main.nf -params-file params.json -profile STRING 

MANDATORY ARGUMENTS, NEXTFLOW:
    -profile  STRING [test, singularity, cluster]  Configuration profile to use. Can use multiple (comma separated).

OTHER OPTIONS, NEXTFLOW:
    -params-file  PATH   Set the parameters of the pipeline using a JSON file configuration filei (i.e. 'params.json'). All parameters defined as JSON 
                         type must be this way. For example, the JSON can contain: "alphaFoldOptions": "--max_template=2024-01-01 --multimer". WARNING: 
                         passing the option '--alphaFoldOptions' in command line will throw an error when the option contains '-' or '--' characters which 
                         are not appreciated by nextflow.

OTHER OPTIONS:
    --afMassiveDatabase   PATH      Path to the database required by AFMassive.
    --afMassiveHelp                 Display all the options available to run AFMassive. Use this option in combination with -profile singularity.
    afMassiveOptions      JSON      Specific options for AFMassive. As AFMassive is an AlphaFold-like tool, standard AlphaFold options are passed 
                                    using the --alphaFoldOptions option.
    --alphaFoldDatabase   PATH      Path to the database required by AlphaFold.
    --alphaFoldHelp                 Display all the options available to run AlphaFold. Use this option in combination with -profile singularity.
    alphaFoldOptions      JSON      Prediction model options passed to AlphaFold or AFMassive.
    --colabFoldDatabase   PATH      Path to the database required by ColabFold.
    --colabFoldHelp                 Display all the options available to run ColabFold. Use this option in combination with -profile singularity.
    colabFoldOptions      JSON      Prediction model options passed to ColabFold.
    --dynamicBindDatabase PATH      Path to the database required by DynamicBind.
    --dynamicBindHelp               Display all the options available to run DynamicBind. Use this option in combination with -profile 
                                    singularity.
    dynamicBindOptions    JSON      Prediction model options passed to DynamicBind.
    --fastaPath           PATH      Path to the input directory which contains the fasta files.
    --fromMsas            PATH      Path to existing multiple sequence alignments (msas) to use for the 3D protein strcuture prediction. 
                                    Typically the path could be the results of the pipeline launcded with the --onlyMsas option.
    --launchAfMassive               Launch AFMassive
    --launchAlphaFold               Launch AlphaFold.
    --launchColabFold               Launch ColabFold.
    --launchDynamicBind             Launch DynamicBind.
    --onlyMsas                      When true, the pipeline will only generate the multiple sequence alignments (msas).
    --outDir              PATH      The output directory where the results will be saved
    --proteinLigandFile   PATH      Path to the input file for molecular docking. The file must be in CSV format, without space. One column named 
                                    'protein' contains the path the the 'pdb' file and one column named 'ligand' must contain the path to the 
                                    'sdf' file.
    --useGpu                        Run the prediction model on GPU. AlphaFold and AFMassive can run either on CPU or GPU. ColabFold and 
                                    DynamicBind require GPU only.

REFERENCES:
    --genomeAnnotationPath PATH   Path to genome/proteome annotations folder used to predict the protein 3D structure.

=======================================================
Available Profiles
   -profile test                        Run the test dataset
   -profile singularity                 Use the Singularity images for each process. Use `--singularityPath` to define the insallation path
   -profile cluster                     Run the workflow on the cluster, instead of locally

```
## AlphaFill

Visit the [AlphaFill](https://github.com/PDB-REDO/alphafill) GitHub repository for more details about the prediction model.

AlphaFill is launched whenener the option `--launchAlphaFill` is set. It can predict the binding of missing compounds from *best* 3D predicted protein structure provided as PDB files. The PDB file used for the prediction must be always named `ranked_0.pdb`.

```bash
nextflow run main.nf -profile singularity --fromPredictions test/data/afmassive/monomer2/ --launchAlphaFill --alphaFillDatabase $PWD/test/data/alphafill/database/ --fastaPath test/data/fasta/monomer2
```

The option `--fromPredictions` takes as imput a directory in which tehre is on folder per protein, each folder container the `ranked_0.pdb` file, for example:

```bash
├── MISFA
│   ├── ranked_0.pdb
└── MRLN
    ├── ranked_0.pdb
```

AlphaFill be also launched in used in combination with the following options:

* `--launchAlphaFold`
* `--launchAfMassive`

In that case, the **best** 3D predicted protein structure obtained by either AlphaFold or AFMassive will be used.

## AFMassive

Visit the [AFMassive](https://github.com/GBLille/AFMassive) GitHub repository for more details about the prediction model.

List of AFMassive options:

```bash
nextflow run main.nf --afMassiveHelp -profile singularity
```

### Monomer

Launch the nextflow pipeline using GPU:

```bash
nextflow run main.nf -params-file test/params-file/afmassive-monomer.json -profile singularity --useGpu
```

Define the options in a JSON file, for example:

```json
{
    "launchAfMassive": "true",
    "afMassiveOptions": "--dropout --dropout_structure_module",
	"alphaFoldOptions": "--max_template_date=2024-01-01 --db_preset=full_dbs --random_seed=123456",
	"fastaPath": "test/data/fasta/monomer2"
}
```

### Multimer

Launch the nextflow pipeline using GPU:

```bash
nextflow run main.nf -params-file test/params-file/afmassive-multimer.json -profile singularity --useGpu
```

Define the options in a JSON file, for example:

```json
{
    "launchAfMassive": "true",
    "afMassiveOptions": "--dropout --dropout_structure_module",
	"alphaFoldOptions": "--max_template_date=2024-01-01 --db_preset=full_dbs --random_seed=123456 --model_preset=multimer",
	"fastaPath": "test/data/fasta/multimer/alphafold"
}
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
	"colabFoldOptions": "--random-seed 654321 --model-type=alphafold2 --amber --use-gpu-relax",
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
	"colabFoldOptions": "--random-seed 654321 --model-type=alphafold2_multimer_v3 --amber --use-gpu-relax",
	"fastaPath": "test/data/fasta/multimer/colabfold"
}
```

Note that ColabFold expects a particular format for the input fasta file. See [](../test/data/multimer/colabfold/rac1-SOS-complex.fasta)


## Multiple sequence alignments (msas)

If you want to perform only msas, launch the pipeline with the option `--onlyMsas`.

If you want to use existing msas, launch the pipeline with the option `--fromMsas`. For example, if you have to predict the structure for two fasta files `protein1.fasta` and `protein2.fasta`, you must have a tree folder such as:

```
msas/
  protein1/
  protein2/
```

Then, provide the option `--fromMsas`, for example:


```bash
nextflow run main.nf -params-file test/params-file/alphafold-multimer-frommsas.json -profile singularity --useGpu
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

The option `--fromMsas` can be used with:

- AFMassive
- AlphaFold
- ColabFold

## DiffDock

Visit the [DiffDock](https://github.com/gcorso/DiffDock) GitHub repository for more details about the prediction model.

Launch the nextflow pipeline using GPU:

```bash
nextflow run main.nf -profile singularity --useGpu --proteinLigandFile test/data/diffdock/protein-ligand.csv
```

The `protein-ligand.csv` is a CSV file which must contain at least the two following columns:
- `protein`: provides the path to the `pdb` 3D structure file
- `ligand`: provided the path to the `sdf` file

Therefore, each row in this file corresponds to a protein/ligand pair. This file must not contain any space.


The options to launch the pipeline can also be defined in a JSON file, for example:

```json
{
	"diffDockArgsYamlFile": "assets/diffdock_default_inference_args.yaml",
	"launchDiffDock": "true",
	"proteinLigandFile": "test/data/diffdock/protein-ligand.csv"
}
```

Launch the pipleine with the `-params-file` option to take into account the JSON file:

```bash
nextflow run main.nf -params-file test/params-file/diffdock.json -profile singularity --useGpu
```

The `assets/diffdock_default_inference_args.yaml` makes it possible to tune the DiffDock options.

## DynamicBind

Visit the [DynamicBind](https://github.com/luwei0917/DynamicBind/) GitHub repository for more details about the prediction model.

List of DynamicBind options:

```bash
nextflow run main.nf --dynamicBindHelp -profile singularity
```

Launch the nextflow pipeline using GPU:

```bash
nextflow run main.nf -profile singularity --useGpu --proteinLigandFile test/data/dynamicbind/protein-ligand.csv
```

The `protein-ligand.csv` is a CSV file which must contain at least the two following columns:
- `protein`: provides the path to the `pdb` 3D structure file
- `ligand`: provided the path to the `sdf` file

Therefore, each row in this file corresponds to a protein/ligand pair. This file must not contain any space.


## MultiQC


Two options are available

### ProteinStruct report

```bash
nextflow run main.nf -profile singularity --fromPredictions test/data/afmassive/multimer --htmlProteinStruct --fastaPath test/data/fasta/multimer/alphafold
```

### MetricsMultimer report

```bash
nextflow run main.nf -profile singularity --fromPredictions test/data/afmassive/multimer --htmlMetricsMultimer --fastaPath test/data/fasta/multimer/alphafold
```

