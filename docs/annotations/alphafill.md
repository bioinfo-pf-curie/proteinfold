# Installation or data required by DiffDock

The details can be found at [https://alphafill.eu/man/alphafill/](https://alphafill.eu/man/alphafill/)

Create the bash script `download-database.sh` and modify the different variables if needed:

```bash
#! /bin/bash

set -euo pipefail
DOWNLOAD_DIR="$HOME/tmp/pdb-redo/"
rsync -avP --exclude=attic rsync://rsync.pdb-redo.eu/pdb-redo/ $DOWNLOAD_DIR
```

## Copy the data in the appropriate folder and modify the `conf/process.config` file

Assuming that the nextflow parameters `params.genomeAnnotationPath` is set to the path  `/data/annotations`, move the data in the following folder:

```
mkdir -p /data/annotations/proteinfold/
mv $HOME/tmp/pdb-redo /data/annotations/proteinfold/
```

Then, set the correct values the the parameter `params.genomes.alphafill.database` in the `conf/genomes.config` file accordingly, for example:

```
params {
  genomes {
    alphafill {
      database = "${params.genomeAnnotationPath}/proteinfold/pdb-redo"
    }
  }
}
```
