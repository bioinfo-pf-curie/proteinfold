# Installation or data required by DiffDock

To install some dependencies, it is needed to build the apptainer `diffdock.sif` image using geniac from the ProteinFold pipeline.

## Precompute series for SO(2) and SO(3) groups

```bash
apptainer shell diffdock.sif
mkdir -p $HOME/tmp/diffdock
cd $HOME/tmp/diffdock
python /app/diffdock/utils/precompute_series.py
```

This will generate the following files:

```bash
├── .p.npy
├── .score.npy
├── .so3_cdf_vals4.npy
├── .so3_exp_score_norms4.npy
├── .so3_omegas_array4.npy
└── .so3_score_norms4.npy
```

## ESM checkpoints


```bash
apptainer shell diffdock.sif
cd $HOME/tmp/diffdock
export TORCH_HOME=torch_home
```

Inside the python console:
```python
from esm import pretrained
model_location = "esm2_t33_650M_UR50D"
model, alphabet = pretrained.load_model_and_alphabet(model_location)
```

It will download these two files:

```
Downloading: "https://dl.fbaipublicfiles.com/fair-esm/models/esm2_t33_650M_UR50D.pt" to torch_home/hub/checkpoints/esm2_t33_650M_UR50D.pt
Downloading: "https://dl.fbaipublicfiles.com/fair-esm/regression/esm2_t33_650M_UR50D-contact-regression.pt" to torch_home/hub/checkpoints/esm2_t33_650M_UR50D-contact-regression.pt
```

## Download the DiffDock models

```
cd $HOME/tmp/diffdock
curl -L -o diffdock_models_v1.1.zip "https://github.com/gcorso/DiffDock/releases/download/v1.1/diffdock_models.zip" \
  && mkdir -p workdir \
  && unzip diffdock_models_v1.1.zip -d workdir \
  && rm diffdock_models_v1.1.zip
```

## Copy the data in the appropiate folder and modify the `conf/process.config` file

Assuming that the nextflow parameters `params.genomeAnnotationPath` is set to the path  `/data/annotations`, move the data in the following folder:

```
mkdir -p /data/annotations/proteinfold/diffdock/
mv $HOME/tmp/diffdock /data/annotations/proteinfold/diffdock/v1.1.2
```

Then, set the correct values the the parameter `params.genones.diffdock.database` in the `conf/process.config` file accordingly, for example:

```
params {

  genomes {

    diffdock {
      database = "${params.genomeAnnotationPath}/proteinfold/diffdock/v1.1.2"
    }
  }

}
```
