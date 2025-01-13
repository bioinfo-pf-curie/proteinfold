# Installation of data required by AlphaFold3

## Annotations

Create the bash script `download-database.sh` and modify the different variables if needed:

```bash
#! /bin/bash

set -euo pipefail

readonly db_dir=$HOME/tmp/alphafold3

for cmd in wget tar zstd ; do
  if ! command -v "${cmd}" > /dev/null 2>&1; then
    echo "${cmd} is not installed. Please install it."
  fi
done

DATABASE_FILES="pdb_2022_09_28_mmcif_files.tar \
                mgy_clusters_2022_05.fa \
                bfd-first_non_consensus_sequences.fasta \
                uniref90_2022_05.fa uniprot_all_2021_04.fa \
                pdb_seqres_2022_09_28.fasta \
                rnacentral_active_seq_id_90_cov_80_linclust.fasta \
                nt_rna_2023_02_23_clust_seq_id_90_cov_80_rep_seq.fasta \
                rfam_14_9_clust_seq_id_90_cov_80_rep_seq.fasta"


echo "Fetching databases to ${db_dir}"
mkdir -p "${db_dir}"
GOOGLE_API="https://storage.googleapis.com/storage/v1"
AF3_BUCKET="alphafold-databases"
AF3_VERSION="v3.0"
readonly SOURCE=https://storage.googleapis.com/${AF3_BUCKET}/${AF3_VERSION}

if [[ -f md5.log ]]; then
        rm md5.log
fi

# Download
for NAME in ${DATABASE_FILES}; do
        echo "Download json for the file ${NAME}"
        curl ${GOOGLE_API}/b/${AF3_BUCKET}/o/${AF3_VERSION}%2F${NAME}.zst > ${NAME}.zst.json
        MD5SUM_BASE64_SRC=$(jq '.md5Hash' ${NAME}.zst.json | sed -e 's/\"//g')
        echo "Download file ${NAME}"
        wget -P ${db_dir} "${SOURCE}/${NAME}.zst"
        MD5SUM_BASE64_COPY=$(cat ${db_dir}/${NAME}.zst | openssl dgst -md5 -binary | openssl enc -base64)
        echo "MD5_SRC: ${MD5SUM_BASE64_SRC} - MD5_COPY: ${MD5SUM_BASE64_COPY}"
        echo "MD5_SRC: ${MD5SUM_BASE64_SRC} - MD5_COPY: ${MD5SUM_BASE64_COPY}" >> md5.log
        if [[ ${MD5SUM_BASE64_SRC} != ${MD5SUM_BASE64_COPY} ]]; then
                echo "ERROR: MD5 sum does not match"
                exit 1
        fi
done

# Decompress
for NAME in ${DATABASE_FILES}; do
        echo "Decompress the file ${NAME}.zst"
        if [[ -e "${db_dir}/${NAME}.zst" && "${NAME}" =~ '.tar' ]]; then
                echo "Decompress tar.zst: ${NAME}"
    tar --directory="${db_dir}" --use-compress-program=zstd -xf "${db_dir}/${NAME}.zst"
        else
                echo "Decompress zst: ${NAME}"
    zstd --decompress "${db_dir}/${NAME}.zst" > "${db_dir}/${NAME}" 
        fi
done

echo "Complete"

```

Launch `bash download-database.sh`

## Copy the data in the appropriate folder and modify the `conf/process.config` file

Assuming that the nextflow parameters `params.genomeAnnotationPath` is set to the path  `/data/annotations`, move the data in the following folder:

```
mkdir -p /data/annotations/proteinfold/
mv $HOME/tmp/alphafold3 /data/annotations/proteinfold/
```

Then, set the correct values the the parameter `params.genomes.alphafold3.database` in the `conf/genomes.config` file accordingly, for example:

```
params {
  genomes {
    alphafold3 {
      database = "${params.genomeAnnotationPath}/proteinfold/alphafold3"
    }
  }
}
```
