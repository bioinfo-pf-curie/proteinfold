# Admin document for the development and test of the pipeline

## stub-run

The following stub-run works:

```bash
#! /bin/bash

set -oeu pipefail


# afMassive

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/afmassive-monomer.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/afmassive-monomer.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/afmassive-monomer-frommsas.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/afmassive-monomer-frommsas.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/afmassive-monomer-onlymsas.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/afmassive-monomer-onlymsas.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/afmassive-monomer-alphafill.json -profile singularity --alphaFillDatabase $PWD/test/data/alphafill/database/
nextflow run main.nf -resume -stub-run -params-file test/params-file/afmassive-monomer-alphafill.json -profile singularity --alphaFillDatabase $PWD/test/data/alphafill/database/

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/afmassive-multimer.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/afmassive-multimer.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/afmassive-multimer-frommsas.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/afmassive-multimer-frommsas.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/afmassive-multimer-onlymsas.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/afmassive-multimer-onlymsas.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/afmassive-multimer-alphafill.json -profile singularity --alphaFillDatabase $PWD/test/data/alphafill/database/
nextflow run main.nf -resume -stub-run -params-file test/params-file/afmassive-multimer-alphafill.json -profile singularity --alphaFillDatabase $PWD/test/data/alphafill/database/

# AlphaFill from predictions

rm -r work results/ .nextflow*
nextflow run main.nf -stub-run -resume -profile singularity --fromPredictions test/data/afmassive/monomer2/ --launchAlphaFill --alphaFillDatabase $PWD/test/data/alphafill/database/ --fastaPath test/data/fasta/monomer2
nextflow run main.nf -stub-run -resume -profile singularity --fromPredictions test/data/afmassive/monomer2/ --launchAlphaFill --alphaFillDatabase $PWD/test/data/alphafill/database/ --fastaPath test/data/fasta/monomer2


# alphaFold

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold-monomer.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold-monomer.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold-monomer-frommsas.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold-monomer-frommsas.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold-monomer-onlymsas.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold-monomer-onlymsas.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold-monomer-alphafill.json -profile singularity --alphaFillDatabase $PWD/test/data/alphafill/database/
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold-monomer-alphafill.json -profile singularity --alphaFillDatabase $PWD/test/data/alphafill/database/

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold-multimer.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold-multimer.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold-multimer-frommsas.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold-multimer-frommsas.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold-multimer-onlymsas.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold-multimer-onlymsas.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold-multimer-alphafill.json -profile singularity --alphaFillDatabase $PWD/test/data/alphafill/database/
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold-multimer-alphafill.json -profile singularity --alphaFillDatabase $PWD/test/data/alphafill/database/

# alphaFold3

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold3-monomer.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold3-monomer.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold3-monomer-frommsas.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold3-monomer-frommsas.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold3-monomer-onlymsas.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold3-monomer-onlymsas.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold3-monomer-alphafill.json -profile singularity --alphaFillDatabase $PWD/test/data/alphafill/database/
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold3-monomer-alphafill.json -profile singularity --alphaFillDatabase $PWD/test/data/alphafill/database/

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold3-multimer.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold3-multimer.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold3-multimer-frommsas.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold3-multimer-frommsas.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold3-multimer-onlymsas.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold3-multimer-onlymsas.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold3-multimer-alphafill.json -profile singularity --alphaFillDatabase $PWD/test/data/alphafill/database/
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold3-multimer-alphafill.json -profile singularity --alphaFillDatabase $PWD/test/data/alphafill/database/

# colbaFold

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/colabfold-monomer.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/colabfold-monomer.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/colabfold-monomer-frommsas.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/colabfold-monomer-frommsas.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/colabfold-monomer-onlymsas.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/colabfold-monomer-onlymsas.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/colabfold-multimer.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/colabfold-multimer.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/colabfold-multimer-frommsas.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/colabfold-multimer-frommsas.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/colabfold-multimer-onlymsas.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/colabfold-multimer-onlymsas.json -profile singularity


# DiffDock
rm -r work/ results .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/diffdock.json -profile singularity 
nextflow run main.nf -resume -stub-run -params-file test/params-file/diffdock.json -profile singularity

# DynamicBind
rm -r work/ results .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/dynamicbind.json -profile singularity 
nextflow run main.nf -resume -stub-run -params-file test/params-file/dynamicbind.json -profile singularity

# nanoBERT

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/nanobert.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/nanobert.json -profile singularity

# HTML report ProteinStruct

rm -r work results/ .nextflow*
nextflow run main.nf -stub-run -resume -profile singularity --fromPredictions test/data/afmassive/monomer2/ --htmlProteinStruct --fastaPath test/data/fasta/monomer2
nextflow run main.nf -stub-run -resume -profile singularity --fromPredictions test/data/afmassive/monomer2/ --htmlProteinStruct --fastaPath test/data/fasta/monomer2

rm -r work results/ .nextflow*
nextflow run main.nf -stub-run -resume -profile singularity --fromPredictions test/data/afmassive/multimer --htmlProteinStruct --fastaPath test/data/fasta/multimer/alphafold
nextflow run main.nf -stub-run -resume -profile singularity --fromPredictions test/data/afmassive/multimer --htmlProteinStruct --fastaPath test/data/fasta/multimer/alphafold


rm -r work results/ .nextflow*
nextflow run main.nf -stub-run -resume -profile singularity --fromPredictions test/data/alphafold3/monomer2/ --htmlProteinStruct --fastaPath test/data/fasta/monomer2
nextflow run main.nf -stub-run -resume -profile singularity --fromPredictions test/data/alphafold3/monomer2/ --htmlProteinStruct --fastaPath test/data/fasta/monomer2

rm -r work results/ .nextflow*
nextflow run main.nf -stub-run -resume -profile singularity --fromPredictions test/data/alphafold3/multimer/ --htmlProteinStruct --fastaPath test/data/fasta/multimer/alphafold
nextflow run main.nf -stub-run -resume -profile singularity --fromPredictions test/data/alphafold3/multimer/ --htmlProteinStruct --fastaPath test/data/fasta/multimer/alphafold

```
