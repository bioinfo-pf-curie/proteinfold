# Installation of data required by DynamicBind

To install some dependencies, it is needed to build the apptainer `dynamicbind.sif` image using geniac from the ProteinFold pipeline.

## Precompute series for SO(3) groups

```bash
mkdir -p $HOME/tmp/dynamicbind/
apptainer exec dynamicbind.sif /bin/bash -c "cp -r /app/dynamicbind $HOME/tmp/dynamicbind/src"
cd $HOME/tmp/dynamicbind
```

Launch a `python` console, then type:
```python
import os
import sys

sys.path.append(os.getenv('HOME') + '/tmp/dynamicbind/src')
from datasets.pdbbind import PDBBind
```

Quit the python console

This command may take several minutes. It will generate in the folder `$HOME/tmp/dynamicbind/src` the following hidden files:
```bash
.so3_score_norms2.npy
.so3_omegas_array2.npy
.so3_exp_score_norms2.npy
.so3_cdf_vals2.npy
.p.npy
.score.npy
```

Copy the files in a dedicated folder:

```bash
mkdir $HOME/tmp/dynamicbind/pdbbind
cd $HOME/tmp/dynamicbind/src
cp .so3_score_norms2.npy $HOME/tmp/dynamicbind/pdbbind
cp .so3_omegas_array2.npy $HOME/tmp/dynamicbind/pdbbind
cp .so3_exp_score_norms2.npy $HOME/tmp/dynamicbind/pdbbind
cp .so3_cdf_vals2.npy $HOME/tmp/dynamicbind/pdbbind
cp .p.npy $HOME/tmp/dynamicbind/pdbbind
cp .score.npy $HOME/tmp/dynamicbind/pdbbind
```

## Checkpoints from Zenodo

They are available from https://zenodo.org/records/10137507


```bash
cd $HOME/tmp/dynamicbind/
wget https://zenodo.org/records/10137507/files/workdir.zip
unzip workdir.zip
rm -r __MACOSX
rm workdir/.DS_Store
rm workdir.zip
```

## ESM checkpoints

The script `./esm/esm/pretrained.py` downloads some data:

```bash
cd $HOME/tmp/dynamicbind/
mkdir -p esm_models/checkpoints
cd esm_models/checkpoints
wget https://dl.fbaipublicfiles.com/fair-esm/models/esm2_t33_650M_UR50D.pt
wget https://dl.fbaipublicfiles.com/fair-esm/regression/esm2_t33_650M_UR50D-contact-regression.pt
```

## Copy the data in the appropriate folder and modify the `conf/process.config` file

Assuming that the nextflow parameters `params.genomeAnnotationPath` is set to the path  `/data/annotations`, move the data in the following folder:

```
mkdir -p /data/annotations/proteinfold/dynamicbind/
mv $HOME/tmp/dynamicbind /data/annotations/proteinfold/dynamicbind/v1.0
```

Then, set the correct values the the parameter `params.genomes.dynamicbind.database` in the `conf/genomes.config` file accordingly, for example:

```
params {
  genomes {
    diffdock {
      database = "${params.genomeAnnotationPath}/proteinfold/dynamicbind/v1.0"
    }
  }
}
```
