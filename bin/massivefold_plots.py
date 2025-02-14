#!/usr/bin/env python

import csv
import json
import os
import pickle
import shutil

import numpy as np
import pandas as pd
from absl import flags
from absl import app
from matplotlib import ticker
import matplotlib.pyplot as plt
import seaborn as sns

from colabfold_plots import plot_msa_v2, plot_plddts, plot_confidence, plot_paes, plot_pae
from ap_format_ranking_alphafold3 import order_ranking_scores_af3

FLAGS = flags.FLAGS

flags.DEFINE_string(
    'input_path', None,
    'Path to directory were the alphafold output to be plotted lies.')
flags.DEFINE_integer(
    'top_n_predictions', 10,
    'Specify the number of predictions taken into account for plotting, it will be the n best predictions.'
)
flags.DEFINE_list(
    'chosen_plots', [], 'Specify the plots you want to get.'
    'CF_plddt for plddt of each predictions, DM_plddt_PAE for plddt and PAE on the same plot for each prediction,'
    'CF_PAEs for PAEs of all predictions on the same plot and CF_plddts for plddt of all predictions on the same plot.'
)
flags.DEFINE_enum('action', "save", ["save", "show"],
                  "Choose to save the plot or show them.")
flags.DEFINE_string(
    'output_path', None,
    'Path to directory that will store the plots, same as the input dir by default.'
)
flags.DEFINE_list('runs_to_compare', [],
                  'Runs that you want to compare on a same distribution plot')

def test_alphafold_version():
    alphafold_version = "unknown"
    if os.path.isfile(f'{FLAGS.input_path}/ranking_debug.json'):
        alphafold_version = 'alphafold2'
    if os.path.isfile(f'{FLAGS.input_path}/ranking_scores.csv'):
        alphafold_version = 'alphafold3'
    
    print(f"af version is {alphafold_version}")

    return alphafold_version


def extract_top_predictions():
    if test_alphafold_version() == 'alphafold2':
        with open(f'{FLAGS.input_path}/ranking_debug.json', 'r') as json_file:
            scores = json.load(json_file)
        top_pred = scores['order'][:FLAGS.top_n_predictions]
    if test_alphafold_version() == 'alphafold3':
        sorted_rows = order_ranking_scores_af3(f'{FLAGS.input_path}/ranking_scores.csv')
        top_pred = [row['model'] for row in sorted_rows[:FLAGS.top_n_predictions]]

    return top_pred


def CF_PAEs():
    all_models_pae = []
    jobname = FLAGS.input_path
    preds_to_plot = extract_top_predictions()
    if test_alphafold_version() == 'alphafold2':
        pos_s = sequence_length(f'{jobname}/features.pkl')
    if test_alphafold_version() == 'alphafold3':
        pos_s = sequence_length_alphafold3(f'{jobname}/{os.path.basename(jobname).lower()}_data.json')
    for pred in preds_to_plot:
        if test_alphafold_version() == 'alphafold2':
            with open(f'{jobname}/result_{pred}.pkl', "rb") as pkl_file:
                data = pickle.load(pkl_file)
            if 'predicted_aligned_error' not in data:
                return False
            all_models_pae.append(np.asarray(data['predicted_aligned_error']))
        if test_alphafold_version() == 'alphafold3':
            with open(f'{jobname}/{pred}/confidences.json', "rb") as json_file:
                data = json.load(json_file)
            if 'pae' not in data:
                return False
            all_models_pae.append(np.asarray(data['pae']))
    plot_paes(all_models_pae, pos_s=pos_s)
    if FLAGS.action == "save":
        plt.savefig(
            f"{FLAGS.output_path}/top_{FLAGS.top_n_predictions}_PAE.png",
            dpi=200)
        print(f"Saved as top_{FLAGS.top_n_predictions}_PAE.png")
        plt.close()
    if FLAGS.action == "show":
        plt.show()


def CF_plddts():
    all_models_plddt = []
    jobname = FLAGS.input_path
    preds_to_plot = extract_top_predictions()
    if test_alphafold_version() == 'alphafold2':
        pos_s = sequence_length(f'{jobname}/features.pkl')
    if test_alphafold_version() == 'alphafold3':
        pos_s = sequence_length_alphafold3(f'{jobname}/{os.path.basename(jobname).lower()}_data.json')
    for pred in preds_to_plot:
        if test_alphafold_version() == 'alphafold2':
            with open(f'{jobname}/result_{pred}.pkl', "rb") as pkl_file:
                data = pickle.load(pkl_file)
            all_models_plddt.append(np.asarray(data['plddt']))
        if test_alphafold_version() == 'alphafold3':
            with open(f'{jobname}/{pred}/confidences.json', "rb") as json_file:
                data = json.load(json_file)
            all_models_plddt.append(np.asarray(data['atom_plddts']))
    plot_plddts(all_models_plddt, pos_s=pos_s)
    if FLAGS.action == "save":
        plt.savefig(
            f"{FLAGS.output_path}/top_{FLAGS.top_n_predictions}_plddt.png",
            dpi=200)
        print(f"Saved as top_{FLAGS.top_n_predictions}_plddt.png")
        plt.close()
    if FLAGS.action == "show":
        plt.show()


def MF_DM_dual_plddt_PAE(prediction, rank):
    jobname = FLAGS.input_path
    if test_alphafold_version() == 'alphafold2':
        with open(f'{jobname}/result_{prediction}.pkl', "rb") as pkl_file:
            results = pickle.load(pkl_file)
        if 'predicted_aligned_error' not in results:
            return False

        results_plddt = results['plddt']
        pae_outputs = {}
        pae_outputs["test"] = (results["predicted_aligned_error"],
                               results['max_predicted_aligned_error'])
    if test_alphafold_version() == 'alphafold3':
        with open(f'{jobname}/{prediction}/confidences.json', "rb") as json_file:
            results = json.load(json_file)
        if 'pae' not in results:
            return False

        results_plddt = results['atom_plddts']
        pae_outputs = {}
        pae_outputs["test"] = (np.asarray(results["pae"]),
                               np.max(np.asarray(results['pae'])))

    if test_alphafold_version() == 'alphafold2':
        pos_s = sequence_length(f'{jobname}/features.pkl')
    if test_alphafold_version() == 'alphafold3':
        pos_s = sequence_length_alphafold3(f'{jobname}/{os.path.basename(jobname).lower()}_data.json')


    pae, max_pae = list(pae_outputs.values())[0]
    plt.figure(figsize=[8 * 2, 6])

    plt.subplot(1, 2, 1)
    plt.plot(results_plddt)
    plt.title('Predicted LDDT')
    plt.suptitle(f'rank_{rank}_{prediction}')
    plt.ylim(0, 100)
    plt.axhline(y=100, color='grey', linestyle='-', linewidth=1)
    plt.axhline(y=90, color='#0d57d3', linestyle='--', linewidth=1)
    plt.axhline(y=70, color='#6acbf1', linestyle='--', linewidth=1)
    plt.axhline(y=50, color='#fed936', linestyle='--', linewidth=1)
    add_line_sequence(pos_s)
    plt.xlabel('Residue')
    plt.ylabel('pLDDT')

    axes = plt.subplot(1, 2, 2)
    plot_pae(pae,
             axes,
             pos_s=pos_s,
             caption='Predicted Aligned Error (Ångströms)')
    plt.xlabel('Scored residue')
    plt.ylabel('Aligned residue')

    if FLAGS.action == "save":
        plt.savefig(
            f"{FLAGS.output_path}/rank_{rank}_{prediction}_plddt_PAE.png",
            dpi=200)
        print(f"Saved as rank_{rank}_{prediction}_plddt_PAE.png")
        plt.close()
    if FLAGS.action == "show":
        plt.show()


def call_dual():
    preds_to_plot = extract_top_predictions()
    for i, pred in enumerate(preds_to_plot):
        MF_DM_dual_plddt_PAE(pred, i)


def MF_indiv_plddt():
    jobname = FLAGS.input_path
    preds_to_plot = extract_top_predictions()
    for i, pred in enumerate(preds_to_plot):
        with open(f'{jobname}/result_{pred}.pkl', "rb") as pkl_file:
            data = pickle.load(pkl_file)
        plot_confidence(data['plddt'])
        plt.title(f'rank_{i}_{pred} predicted lDDT')
        if FLAGS.action == "save":
            plt.savefig(f"{FLAGS.output_path}/rank_{i}_{pred}_plddt.png",
                        dpi=200)
            print(f"Saved as rank_{i}_{pred}_plddt.png")
            plt.close()
        if FLAGS.action == "show":
            plt.show()


def MF_coverage():
    jobname = FLAGS.input_path
    with open(f'{jobname}/features.pkl', 'rb') as f:
        data = pickle.load(f)
    plot_msa_v2(data)
    if FLAGS.action == "save":
        plt.savefig(f"{FLAGS.output_path}/alignment_coverage.png", dpi=200)
        print("Saved as alignment_coverage.png")
        plt.close()
    elif FLAGS.action == "show":
        plt.show()


def MF_score_histogram(scores: dict):
    try:
        scores = scores['iptm+ptm']
        s_type = 'iptm+ptm'
    except KeyError:
        scores = scores['plddts']
        s_type = 'plddts'

    # Global score distribution
    all_scores = [scores[model] for model in scores]
    histogram, ax1 = plt.subplots()
    ax1.hist(all_scores, bins=50)
    histogram.suptitle('Global score distribution')
    ax1.set(xlabel='Ranking confidence', ylabel='Number of predictions')

    if s_type == 'iptm+ptm':
        plt.xlim(0, 1)
        plt.axvline(x=0.8, color='green', linestyle='--', linewidth=1)
        plt.axvline(x=0.6, color='orange', linestyle='--', linewidth=1)
    elif s_type == 'plddts':
        plt.xlim(0, 100)
        plt.axvline(x=90, color='green', linestyle='--', linewidth=1)
        plt.axvline(x=70, color='orange', linestyle='--', linewidth=1)
        plt.axvline(x=50, color='red', linestyle='--', linewidth=1)
    if FLAGS.action == "save":
        histogram.savefig(
            f"{FLAGS.output_path}/score_distribution_{s_type}.png", dpi=200)
        print(f"Saved as score_distribution_{s_type}.png")
        plt.close(histogram)


def MF_versions_density(scores: dict):
    try:
        scores = scores['iptm+ptm']
    except KeyError:
        print('\nOnly one version of NN models, no versions density plot.\n')
        return None

    # Score distribution by NN model version
    versions = {
        prediction.split('multimer_')[1].split('_pred')[0]: []
        for prediction in scores
    }

    for model in scores:
        versions[model.split('multimer_')[1].split('_pred')[0]].append(
            scores[model])
    scores_per_version = pd.DataFrame(versions)
    scores_per_version = scores_per_version.sort_index(axis=1)
    kde_versions, ax2 = plt.subplots()

    kde_versions.suptitle('Score density')
    sns.kdeplot(scores_per_version, ax=ax2)
    #scores_per_version.plot(kind="kde", ax=ax2, bw_method=0.3)
    ax2.set(xlabel='Ranking confidence', ylabel="Density")

    plt.xlim(0, 1)
    plt.axvline(x=0.8, color='green', linestyle='--', linewidth=1)
    plt.axvline(x=0.6, color='orange', linestyle='--', linewidth=1)

    if FLAGS.action == "save":
        kde_versions.savefig(f"{FLAGS.output_path}/versions_density.png",
                             dpi=200)
        print("Saved as versions_density.png")
        plt.close(kde_versions)


def MF_models_scores(scores: dict):
    try:
        scores = scores['iptm+ptm']
        s_type = 'iptm+ptm'
    except KeyError:
        scores = scores['plddts']
        s_type = "plddts"
    # Score distribution by NN model
    NN_models = {prediction.split('_pred')[0]: [] for prediction in scores}
    for model in scores:
        NN_models[model.split('_pred')[0]].append(scores[model])

    scores_per_model = pd.DataFrame(NN_models)
    cols = scores_per_model.columns
    scores_per_model.columns = [
        col.replace('model_', '').replace('multimer_', '') for col in cols
    ]
    pastel_colors = [
        '#add8e6', '#87ceeb', '#b0c4de', '#b0e0e6', '#e0ffff', '#afeeee',
        '#90ee90', '#98fb98', '#fafad2', '#ffa07a', '#f08080', '#ffb6c1',
        '#e6a8d7', '#fff0f5', '#ffe4e1'
    ]
    colors = {
        'boxes': '#add8e6',
    }
    # Create a boxplot with inclined x-axis labels
    fig, ax = plt.subplots()
    ax = scores_per_model.boxplot(sym='g+',
                                  patch_artist=True,
                                  color=colors,
                                  flierprops=dict(markerfacecolor='red'))
    for box, color in zip(ax.artists, pastel_colors):
        box.set_facecolor(color)

    plt.grid(False)
    fig.suptitle("Score per AlpfaFold model")

    ax.set(xlabel="AlphaFold model version", ylabel="Ranking confidence")
    ax.set_xticklabels(scores_per_model.columns, rotation=45)
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    if s_type == 'iptm+ptm':
        ax.set_ylim(bottom=0, top=1.1)
        plt.axhline(y=1, color='grey', linestyle='-', linewidth=1)
        plt.axhline(y=0.8, color='green', linestyle='--', linewidth=1)
        plt.axhline(y=0.6, color='orange', linestyle='--', linewidth=1)
    elif s_type == 'plddts':
        plt.axhline(y=100, color='grey', linestyle='-', linewidth=1)
        plt.axhline(y=90, color='#0d57d3', linestyle='--', linewidth=1)
        plt.axhline(y=70, color='#6acbf1', linestyle='--', linewidth=1)
        plt.axhline(y=50, color='#fed936', linestyle='--', linewidth=1)
        ax.set_ylim(bottom=0, top=110)

    plt.tight_layout()

    if FLAGS.action == "save":
        plt.savefig(f"{FLAGS.output_path}/models_scores_{s_type}.png", dpi=200)
        print(f"Saved as models_scores_{s_type}.png")

    if FLAGS.action == "show":
        plt.show()
    plt.close()


def MF_score_distribution():
    distribution_types = ["scores", "versions_scores", "models_scores"]
    jobname = FLAGS.input_path
    with open(f'{jobname}/ranking_debug.json', 'r') as json_scores:
        scores = json.load(json_scores)

    DISTRIBUTION_MAP = {
        "scores": MF_score_histogram,
        "versions_scores": MF_versions_density,
        "models_scores": MF_models_scores
    }

    for distrib in distribution_types:
        DISTRIBUTION_MAP[distrib](scores)
        #try:
        #  DISTRIBUTION_MAP[distrib](scores)
        #except:
        #  print(f"Error while trying to plot {DISTRIBUTION_MAP[distrib].__name__}()")


def MF_distribution_comparison():
    sequence_path = FLAGS.input_path
    runs = FLAGS.runs_to_compare
    all_scores = {}
    for run in runs:
        run_basename = os.path.basename(run)
        scores = []
        with open(f"{sequence_path}/{run}/ranking_debug.json",
                  'r') as json_file:
            run = json.load(json_file)
            try:
                run_scores = run['iptm+ptm']
            except KeyError:
                run_scores = run['plddts']

        run_scores = [run_scores[score] for score in run_scores]
        if len(runs) <= 3:
            plt.hist(run_scores, bins=30, alpha=0.5, label=run_basename)
        else:
            all_scores[run_basename] = run_scores
    if len(runs) > 3:
        datas = pd.DataFrame(all_scores)
        datas.plot(kind='kde')
    plt.legend()
    plt.title(
        f'Distribution comparison between {os.path.basename(sequence_path)} runs'
    )
    plt.xlabel('Ranking confidence')
    plt.ylabel('Number of predictions')
    plt.savefig(f'{sequence_path}/distribution_compa.png', dpi=200)
    print('Saved as distribution_compa.png')


def MF_extract_pred_recycle(log, relative_position):
    with open(log, 'r') as log_file:
        lines = log_file.readlines()

    start_symbol = 'Starts recycling'
    end_symbol = 'Ends recycling'

    recycle_logs = []
    for line in lines:
        if line.startswith(start_symbol):
            pred = {'scores': [], 'distances': []}
        elif line.startswith(end_symbol):
            pred['distances'] = [
                distance for i, distance in enumerate(pred['distances'])
                if i != 1
            ]
            recycle_logs.append(pred)

        elif line.startswith('Distance for') or line.startswith(
                "Last step's distance"):
            distance = float(line.split(': ')[1])
            pred['distances'].append(distance)
        elif line.startswith('Score for') or line.startswith(
                "Last step's score"):
            score = float(line.split(': ')[1])
            pred['scores'].append(score)

    return recycle_logs[relative_position[0]]


def MF_recycles():
    all_models_pae = []
    jobname = FLAGS.input_path
    run = os.path.basename(jobname)
    seq = os.path.basename(os.path.dirname(jobname))
    print('Starting recycle logs retrieving')
    #logs_dir = os.path.join(jobname, '../../../log_parallel/', seq, run)
    logs_dir = os.path.join(jobname, '../../../log/', seq, run)
    batches_file = os.path.join(logs_dir, f'{seq}_{run}_batches.json')

    preds_to_plot = extract_top_predictions()

    recycle_dir = f'{FLAGS.output_path}/recycles/'
    if not shutil.os.path.exists(recycle_dir):
        shutil.os.makedirs(recycle_dir)

    with open(batches_file, 'r') as batches:
        batches_to_model = json.load(batches)

    model_to_batch = {}
    for batch in batches_to_model:
        start = int(batches_to_model[batch]['start'])
        end = int(batches_to_model[batch]['end'])
        model = batches_to_model[batch]['model']
        if not model in model_to_batch:
            model_to_batch[model] = {}
        pred_to_batch = {pred: batch for pred in range(start, end + 1)}
        model_to_batch[model].update(pred_to_batch)

    for pred in preds_to_plot:
        pred_model, pred_nb = pred.split('_pred_')

        model_preds = model_to_batch[pred_model]
        batch_number = model_preds[int(pred_nb)]
        log_file = os.path.join(logs_dir, f"jobarray_{batch_number}.log")
        all_preds_in_batch = sorted([
            pred for pred in model_preds if model_preds[pred] == batch_number
        ])
        position_in_batch = all_preds_in_batch.index(int(pred_nb))
        batch_size = len(all_preds_in_batch)

        relative_position = (position_in_batch, batch_size)

        pred_recycles = MF_extract_pred_recycle(log_file, relative_position)
        scores_elements = pred_recycles['scores']
        distances_elements = pred_recycles['distances']

        with open(log_file, 'r') as log:
            lines = log.readlines()
        early_stop_tolerance = float([
            line.split('=')[1].strip() for line in lines
            if 'early_stop_tolerance=' in line
        ][0])
        if pred_recycles:

            fig, ax1 = plt.subplots()

            x_vals = np.linspace(0,
                                 len(scores_elements) - 1,
                                 len(scores_elements))

            color = 'tab:grey'
            ax1.plot(x_vals, [early_stop_tolerance for val in x_vals],
                     color=color)
            ax1.set_xlabel('Recycling step')
            est_pos_increment = max(distances_elements) / 50
            plt.text(x_vals[0],
                     early_stop_tolerance + est_pos_increment,
                     'Early stop tolerance',
                     color=color)

            ax2 = ax1.twinx()
            color = 'tab:red'
            ax2.set_ylabel('Ranking confidence', color=color)
            ax2.set_ylim(bottom=0, top=1.1)
            ax2.plot(x_vals, scores_elements, color=color, alpha=0.8)
            ax2.tick_params(axis='y', labelcolor=color)

            color = 'tab:blue'
            ax1.set_ylabel('Distance with previous step structure',
                           color=color)
            ax1.plot(x_vals, distances_elements, color=color, alpha=0.8)
            ax1.tick_params(axis='y', labelcolor=color)

            locator = ticker.MaxNLocator(integer=True)
            ax1.xaxis.set_major_locator(locator)
            ax2.xaxis.set_major_locator(locator)

            fig.suptitle(f"{seq} - {run}")
            plt.title(f"{pred_model}_pred_{pred_nb}")
            fig.tight_layout()

            if FLAGS.action == "save":
                plt.savefig(f"{recycle_dir}/{pred_model}_pred_{pred_nb}.png",
                            dpi=200)
                print(f"Saved as recycles/{pred_model}_pred_{pred_nb}.png")
                plt.close()
            if FLAGS.action == "show":
                plt.show()
        else:
            print(f'Recycles are broken for {os.path.basename(log_file)}')


def sequence_length_alphafold3(data_json):
    with open(data_json, 'rb') as f:
        input_data = json.load(f)

    print('seq fir AF3')

    for seq in input_data['sequences']:
        print('loop seq fir AF3')
        pos_s = []
        if list(seq.keys())[0] == 'protein':
            pos_s.append(len(seq['protein']['sequence']))

    print(f"AF3: {pos_s}")

    return pos_s


def sequence_length(features_pkl):
    with open(features_pkl, 'rb') as f:
        feature_dict = pickle.load(f)

    seq = feature_dict["msa"][0]
    if "asym_id" in feature_dict:
        pos_s = [0]
        k = feature_dict["asym_id"][0]
        for i in feature_dict["asym_id"]:
            if i == k:
                pos_s[-1] += 1
            else: pos_s.append(1)
            k = i
    else:
        pos_s = [len(seq)]

    return pos_s


def add_line_sequence(pos_s, max_value=100, orientation='vertical'):
    pos_prev = 0
    for pos_i in pos_s[:-1]:
        pos = pos_prev + pos_i
        pos_prev += pos_i
        if orientation == 'vertical':
            plt.plot([pos, pos], [0, max_value],
                     color="black",
                     linestyle='--',
                     linewidth=1)
        if orientation == 'horizontal':
            plt.plot([0, max_value], [pos, pos],
                     color="black",
                     linestyle='--',
                     linewidth=1)


def main(argv):
    """ 
    These functions are a combination of MassiveFold's team work and the following scripts from ColabFold repository and DeepMind colab notebook:
    https://github.com/sokrypton/ColabFold/blob/main/colabfold/plot.py
    https://github.com/sokrypton/ColabFold/blob/main/colabfold/colabfold.py
    https://colab.research.google.com/github/deepmind/alphafold/blob/main/notebooks/AlphaFold.ipynb
    
    Here are some basic commands:
    python MF_plots.py --input_path ./jobname --chosen_plots coverage,CF_PAEs
      -> regardless of the plot type, plot alignment coverage and group PAE for top 10 predictions
    """
    FLAGS.input_path = os.path.realpath(FLAGS.input_path)

    MF_plots = {
        "DM_plddt_PAE": call_dual,
        "CF_plddt": MF_indiv_plddt,
        "CF_PAEs": CF_PAEs,
        "CF_plddts": CF_plddts,
        "coverage": MF_coverage,
        "score_distribution": MF_score_distribution,
        "distribution_comparison": MF_distribution_comparison,
        "recycles": MF_recycles
    }


    # Flags checking
    if not FLAGS.input_path or not FLAGS.chosen_plots:
        print('Required flags: --input_path and --chosen_plots')
    if not FLAGS.output_path:
        FLAGS.output_path = f"{FLAGS.input_path}/plots/"
    print(f"Plot are stored in {FLAGS.output_path}")
    if "distribution_comparison" in FLAGS.chosen_plots and not FLAGS.runs_to_compare:
        print(
            'Flag --runs_to_compare is required for --chosen_plots=distribution_comparison'
        )
        FLAGS.chosen_plots = [
            plot for plot in FLAGS.chosen_plots
            if plot != 'distribution_comparison'
        ]

    if not shutil.os.path.exists(FLAGS.output_path):
        shutil.os.makedirs(FLAGS.output_path)

    # TO REMOVE
    FLAGS.chosen_plots = ['CF_PAEs', 'CF_plddts', 'DM_plddt_PAE']

    for chosen_plot in FLAGS.chosen_plots:
        MF_plots[chosen_plot]()


if __name__ == "__main__":
    app.run(main)
