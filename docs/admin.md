# Admin document for the developxement of the pipeline

## stub-run

The following stub-run works:

```bash
nextflow run main.nf -stub-run -params-file test/params-file/alphafold-monomer.json -profile singularity
```

```bash
nextflow run main.nf -stub-run -params-file test/params-file/alphafold-multimer.json -profile singularity
```

```bash
nextflow run main.nf -stub-run -params-file test/params-file/afmassive-monomer.json -profile singularity
```

```bash
nextflow run main.nf -stub-run -params-file test/params-file/colabfold-monomer.json -profile singularity --useGpu
```

```bash
nextflow run main.nf -stub-run -params-file test/params-file/colabfold-multimer.json -profile singularity --useGpu 
```

```bash
nextflow run main.nf -stub-run -params-file test/params-file/alphafold-multimer-alphafill.json -profile singularity
```

```bash
nextflow run main.nf -stub-run -params-file test/params-file/afmassive-multimer-alphafill.json -profile singularity
```
