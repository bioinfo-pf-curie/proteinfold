# Installation

## Nextflow pipeline

The ProteinFold pipeline is implemented according to the [geniac](https://github.com/bioinfo-pf-curie/geniac) guidelines. Details are available at:

* The [geniac documentation](https://geniac.readthedocs.io) provides a set of best practises to implement *Nextflow* pipelines.
* The [geniac](https://github.com/bioinfo-pf-curie/geniac) source code provides the set of utilities.
* The [geniac demo](https://github.com/bioinfo-pf-curie/geniac-demo) provides a toy pipeline to test and practise *Geniac*.
* The [geniac template](https://github.com/bioinfo-pf-curie/geniac-template) provides a pipeline template to start a new pipeline.

The pipeline can be installed with the [geniac](https://github.com/bioinfo-pf-curie/geniac) toolbox as described in the next sections.

### Install conda

If conda is not available on your computer, proceed as follows:

```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
```

### Create the geniac conda environment
```bash
export GENIAC_CONDA="https://raw.githubusercontent.com/bioinfo-pf-curie/geniac/release/environment.yml"
wget ${GENIAC_CONDA}
conda env create -f environment.yml
conda activate geniac
pip install geniac
```

### Install the pipeline with Geniac

```bash
export WORK_DIR="${HOME}/tmp/myPipeline"
export INSTALL_DIR="${WORK_DIR}/install"
export GIT_URL="https://github.com/bioinfo-pf-curie/proteinfold.git"

# Initialization of a working directory
# with the src and build folders
geniac init -w ${WORK_DIR} ${GIT_URL}
cd ${WORK_DIR}

# As the building of apptainer/singularity requires more than 16GB of RAM memory,
# it is highly recommended to define a dedicated folder on your filesystem.
# This folder will be used instead of the RAM
export APPTAINER_TMPDIR=$HOME/tmp/apptainer_tmpdir
mkdir -p $APPTAINER_TMPDIR

# Install the pipeline with the singularity images
geniac install . ${INSTALL_DIR} -m singularity
sudo chown -R  $(id -gn):$(id -gn) build

# Test the pipeline with the singularity profile
geniac test singularity

# Test the pipeline with the singularity and cluster profiles
geniac test singularity --check-cluster
```


## Annotations

Protein annotations databases and other dependency files are required to run the pipeline.

Note that the paths to the annotations required by the different tools implemented in the pipeline are defined in the file `conf/genomes.config` using the scope `params` which is defined by `nextflow`. For each tool, the following patttern is used to defined the path to the required data: `params.genomes.toolName.database`. For example, ton run AlphaFold, you have to defined in which folder you have dowloaded all the protein data:


```
params {
  genomes {
    alphafold {
      database = "${params.genomeAnnotationPath}/proteinfold/alphafold/2023-12"
    }
}
```

We provide below the link to the detailed procedure to install the data required by each tool.

* [AlphaFill](annotations/alphafill.md)
* [AlphaFold](annotations/alphafold.md)
* [AlphaFold3](annotations/alphafold3.md)
* [ColabFold](annotations/colabfold.md)
* [DiffDock](annotations/diffdock.md)
* [DynamicBind](annotations/dynamicbind.md)
* [NanoBERT](annotations/nanobert.md)
