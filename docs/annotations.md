# Annotations

Protein annotations databases  and other dependency files are required to run the pipeline.

The installation of these databases can be found the these webpages:

* [AlphaFold](https://github.com/google-deepmind/alphafold/),
* [ColabFold](https://github.com/sokrypton/ColabFold),
* [AFMassive](https://github.com/GBLille/AFMassive).

Note that the paths to the annotations required by the different tools implemented in the pipelines are defined in the file `conf/genomes.config` using the scope `params` which is defined by `nextflow`. For each tool, the following patttern is used to defined the path to the required data: `params.genomes.toolName.database`. For example, ton run AlphaFold, you have to defined in which folder you have dowloaded all the protein data:



```
params {

  genomes {

    alphafold {
      database = "${params.genomeAnnotationPath}/proteinfold/alphafold/2023-12"
    }
}
```

We provide below the details to install the data required by each tool.

* [DiffDock](annotations/diffdock.md)
