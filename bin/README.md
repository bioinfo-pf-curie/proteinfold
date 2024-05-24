Put here the tools that are avalaible as binary or executable script.

## Scripts adapted from other public repositories

* [alphafold_options.py](alphafold_options.py)
  - set the options required by AlphaFold such as the paths to the database
  - source: adapted from [https://github.com/prehensilecode/alphafold_singularity](https://github.com/prehensilecode/alphafold_singularity)

* [amber_relax.py](amber_relax.py)
  - compute amber relaxation from a PDB file
  - code inspired from: https://github.com/google-deepmind/alphafold/issues/721

* [calculate_mpdockq.py](calculate_mpdockq.py)
  - it is required by the script [qc_metrics_multimer.py](qc_metrics_multimer.py)
  - source: [https://github.com/KosinskiLab/AlphaPulldown/blob/main/alphapulldown/analysis_pipeline/calculate_mpdockq.py](https://github.com/KosinskiLab/AlphaPulldown/blob/main/alphapulldown/analysis_pipeline/calculate_mpdockq.py)

* [massivefold_plots.py](massivefold_plots.py) and [colabfold_plots.py](colabfold_plots.py)
  - plots the results obtained with AlphaFold or AFSample
  - source: adapted from [https://github.com/GBLille/MassiveFold](https://github.com/GBLille/MassiveFold)

* [qc_metrics_multimer.py](qc_metrics_multimer.py)
  - computes pDockQ, iPAE
  source: adapted from [https://github.com/KosinskiLab/AlphaPulldown/blob/main/alphapulldown/analysis_pipeline/get_good_inter_pae.py](https://github.com/KosinskiLab/AlphaPulldown/blob/main/alphapulldown/analysis_pipeline/get_good_inter_pae.py) and [https://github.com/KatjaLuckLab/AlphaFold_manuscript/blob/main/scripts/calculate_template_independent_metrics.py](https://github.com/KatjaLuckLab/AlphaFold_manuscript/blob/main/scripts/calculate_template_independent_metrics.py)


## Scripts developed for the pipeline

* [ap_alphafill_table.py_](ap_alphafill_table.py)
  - Create a tsv file with the scores provided by AlphaFill

* [ap_mqc_header.py](ap_mqc_header.py)
  - Generate header information for multiqc report

* [ap_fasta_checker.sh](ap_fasta_checker.sh)
  - Check the fasta format

* [ap_format_diffdock_scores.sh](ap_format_diffdock_scores.sh)
  - Format the scores predicted by DiffDock in CSV format

* [ap_gather_predictions.py](ap_gather_predictions.py)
  - Gather the ranking_debug.json file into a single one when the model are assessed in parallel with AFMassive

* [ap_generate_yaml_4_plots.sh](ap_generate_yaml_4_plots.sh)
  - Generate yaml file to organize plots and legend in multiqc reports

* [ap_nanobert.py](ap_nanobert.py)
  - Generate the masks for NanoBERT prediction

* [ap_ranking_debug_tsv.py](ap_ranking_debug_tsv.py)
  - Convert the ranking_debug.json file into TSV format to display the values in multiqc reports.

* [ap_rename_json_by_model.sh](ap_rename_json_by_model.sh)
  - Rename the file with its expected name when the computation is parallelized with AFMassive
