# Admin document for the developxement of the pipeline

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
nextflow run main.nf -resume -stub-run -params-file test/params-file/frommsas/afmassive-monomer.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/frommsas/afmassive-monomer.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/afmassive-monomer-alphafill.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/afmassive-monomer-alphafill.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/afmassive-multimer.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/afmassive-multimer.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/frommsas/afmassive-multimer.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/frommsas/afmassive-multimer.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/afmassive-multimer-alphafill.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/afmassive-multimer-alphafill.json -profile singularity

# AlphaFill from predictions

rm -r work results/ .nextflow*
nextflow run main.nf -stub-run -resume -profile singularity --fromPredictions test/data/afmassive/monomer2/ --launchAlphaFill --alphaFillDatabase $PWD/test/data/alphafill/database/ --fastaPath test/data/fasta/monomer2
nextflow run main.nf -stub-run -resume -profile singularity --fromPredictions test/data/afmassive/monomer2/ --launchAlphaFill --alphaFillDatabase $PWD/test/data/alphafill/database/ --fastaPath test/data/fasta/monomer2


# alphaFold

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold-monomer.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold-monomer.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/frommsas/alphafold-monomer.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/frommsas/alphafold-monomer.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold-monomer-alphafill.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold-monomer-alphafill.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold-multimer.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold-multimer.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/frommsas/alphafold-multimer.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/frommsas/alphafold-multimer.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold-multimer-alphafill.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/alphafold-multimer-alphafill.json -profile singularity

# colbaFold

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/colabfold-monomer.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/colabfold-monomer.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/frommsas/colabfold-multimer.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/frommsas/colabfold-multimer.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/colabfold-monomer.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/colabfold-monomer.json -profile singularity

rm -r work results/ .nextflow*
nextflow run main.nf -resume -stub-run -params-file test/params-file/frommsas/colabfold-multimer.json -profile singularity
nextflow run main.nf -resume -stub-run -params-file test/params-file/frommsas/colabfold-multimer.json -profile singularity


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


```
