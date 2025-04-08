# Installation of data required by NanoBERT

You may have to set the appropriate `git` setting to allow the `git clone` command:

```bash
git config --global http.sslVerify false
```

Once you have cloned the repository, do not forvert to revert the config:

```bash
git config --global http.sslVerify true
```

## human_heavy model
```bash
mkdir -p $HOME/tmp/nanobert
cd $HOME/tmp/nanobert
git lfs install
git clone https://huggingface.co/NaturalAntibody/human_heavy
```

## nanoBERT model
```bash
cd $HOME/tmp/nanobert
git lfs install
git clone https://huggingface.co/NaturalAntibody/nanoBERT
```


## Copy the data in the appropriate folder and modify the `conf/process.config` file

Assuming that the nextflow parameters `params.genomeAnnotationPath` is set to the path  `/data/annotations`, move the data in the following folder:

```
mkdir -p /data/annotations/proteinfold/nanobert/
mv $HOME/tmp/nanobert /data/annotations/proteinfold/nanobert/v1.0
```

Then, set the correct values the the parameter `params.genomes.nanobert.database` in the `conf/genomes.config` file accordingly, for example:

```
params {
  genomes {
    diffdock {
      database = "${params.genomeAnnotationPath}/proteinfold/nanobert/v1.0"
    }
  }
}
```
