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


## Scripts developed for the pipelines

* [ap_alphafill_table.py_](ap_alphafill_table.py)
  - Create a tsv file with the scores provided by AlphaFill.

* [ap_mqc_header.py](ap_mqc_header.py)
  - Generate header information for multiqc report

