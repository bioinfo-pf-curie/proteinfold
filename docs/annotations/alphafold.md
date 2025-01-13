# Installation of data required by AlphaFold

Install the following software:

- `aria2c`: [https://aria2.github.io/](https://aria2.github.io/)

Make sure it is in your PATH.

## Annotations

Create the bash script `download-database.sh` and modify the different variables if needed:

```bash
#! /bin/bash

set -oue pipefail

DOWNLOAD_DIR=$HOME/tmp/alphafold

ALPHAFOLD_SCRIPT="https://raw.githubusercontent.com/google-deepmind/alphafold/refs/tags/v2.3.2/scripts"

for script in download_alphafold_params.sh \
              download_small_bfd.sh \
              download_bfd.sh \
              download_mgnify.sh \
              download_pdb70.sh \
              download_pdb_mmcif.sh \
              download_uniref30.sh \
              download_uniref90.sh \
              download_uniprot.sh \
              download_pdb_seqres.sh; do 

  wget $ALPHAFOLD_SCRIPT/$script
  bash $script $DOWNLOAD_DIR
done
```

Launch `bash download-database.sh`

## Copy the data in the appropriate folder and modify the `conf/process.config` file

Assuming that the nextflow parameters `params.genomeAnnotationPath` is set to the path  `/data/annotations`, move the data in the following folder:

```
mkdir -p /data/annotations/proteinfold/
mv $DOWNLOAD_DIR/alphafold /data/annotations/proteinfold/
```

Then, set the correct values the the parameter `params.genomes.alphafold.database` in the `conf/genomes.config` file accordingly, for example:

```
params {
  genomes {
    alphafold {
      database = "${params.genomeAnnotationPath}/proteinfold/alphafold"
    }
  }
}
```
