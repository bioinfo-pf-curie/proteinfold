# Nextflow profiles


## Define where the tools are available

The pipeline only works with the singularity profile.

###  `singularity`

Use the Singularity images for each process. Use the option `--singularityImagePath` to specify where the images are available.
Assume that the pipeline has been installed in `${HOME}/tmp/myPipeline/install`, geniac creates `${HOME}/tmp/myPipeline/install/containers/singularity` folder. If you ask geniac to build the singularity images, they will be stored in this folder. If you do not defined the `--singularityImagePath` option, the `-profile singularity` option expects to find the singularity images the `${HOME}/tmp/myPipeline/install/containers/singularity` folder.

## Define where to launch the computation

By default, the pipline runs locally. If you want to run it on a computing cluster, use the profile below.

###  `cluster`

Run the workflow on the cluster, instead of locally.

## Test the pipeline

### `test`

Set up the test dataset
