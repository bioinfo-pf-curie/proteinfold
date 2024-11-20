#!/usr/bin/env python3

import gzip
import itertools
import json
import os
import pickle
import subprocess
import sys

from absl import flags, app, logging
import mdtraj as md
import numpy as np
import pandas as pd

from calculate_mpdockq import calc_pdockq, read_pdb, get_best_plddt, read_plddt, score_complex, calculate_mpDockQ, read_pdb_pdockq

flags.DEFINE_string('output_dir', None,
                    'directory where predicted models are stored')
flags.DEFINE_float(
    'cutoff', 5.0, 'cutoff value of PAE. i.e. only pae<cutoff is counted good')
flags.DEFINE_integer('surface_thres', 2, 'surface threshold. must be integer')
flags.DEFINE_integer('rank', 0, 'rank of the model to be assessed. Nothe that the best model corresponds to rank 0.')
FLAGS = flags.FLAGS


def examine_inter_pae(pae_mtx, seqs, cutoff):
    """A function that checks inter-pae values in multimer prediction jobs"""
    lens = [len(seq) for seq in seqs]
    old_lenth = 0
    for length in lens:
        new_length = old_lenth + length
        pae_mtx[old_lenth:new_length, old_lenth:new_length] = 50
        old_lenth = new_length
    check = np.where(pae_mtx < cutoff)[0].size != 0

    return check


def obtain_mpdockq(work_dir):
    """Returns mpDockQ if more than two chains otherwise return pDockQ"""
    pdb_path = os.path.join(work_dir, f"ranked_{FLAGS.rank}.pdb")
    pdb_chains, chain_coords, chain_CA_inds, chain_CB_inds = read_pdb(pdb_path)
    best_plddt = get_best_plddt(work_dir)
    plddt_per_chain = read_plddt(best_plddt, chain_CA_inds)
    complex_score, num_chains = score_complex(chain_coords, chain_CB_inds,
                                              plddt_per_chain)
    if complex_score is not None and num_chains > 2:
        mpDockq_or_pdockq = calculate_mpDockQ(complex_score)
    elif complex_score is not None and num_chains == 2:
        chain_coords, plddt_per_chain = read_pdb_pdockq(pdb_path)
        mpDockq_or_pdockq = calc_pdockq(chain_coords, plddt_per_chain, t=8)
    else:
        mpDockq_or_pdockq = "None"
    return mpDockq_or_pdockq


def run_and_summarise_pi_score(workd_dir, jobs, surface_thres):
    """A function to calculate all predicted models' pi_scores and make a pandas df of the results"""
    try:
        os.remove(f"mkdir {workd_dir}/pi_score_outputs")
    except:
        pass
    subprocess.run(f"mkdir {workd_dir}/pi_score_outputs",
                   shell=True,
                   executable='/bin/bash')
    pi_score_outputs = os.path.join(workd_dir, "pi_score_outputs")
    for job in jobs:
        subdir = os.path.join(workd_dir, job)
        if not os.path.isfile(os.path.join(subdir, f"ranked_{FLAGS.rank}.pdb")):
            print(f"{job} failed. Cannot find ranked_{FLAGS.rank}.pdb in {subdir}")
            sys.exit()
        else:
            pdb_path = os.path.join(subdir, f"ranked_{FLAGS.rank}.pdb")
            output_dir = os.path.join(pi_score_outputs, f"{job}")
            logging.info(
                f"pi_score output for {job} will be stored at {output_dir}")
            subprocess.run(
                f"source activate pi_score && export PYTHONPATH=/software:$PYTHONPATH && python /software/pi_score/run_piscore_wc.py -p {pdb_path} -o {output_dir} -s {surface_thres} -ps 10",
                shell=True,
                executable='/bin/bash')

    output_df = pd.DataFrame()
    for job in jobs:
        subdir = os.path.join(pi_score_outputs, job)
        csv_files = [
            f for f in os.listdir(subdir) if 'filter_intf_features' in f
        ]
        pi_score_files = [f for f in os.listdir(subdir) if 'pi_score_' in f]
        filtered_df = pd.read_csv(os.path.join(subdir, csv_files[0]))

        if filtered_df.shape[0] == 0:
            for column in filtered_df.columns:
                filtered_df[column] = ["None"]
            filtered_df['jobs'] = str(job)
            filtered_df['pi_score'] = "No interface detected"
        else:
            with open(os.path.join(subdir, pi_score_files[0]), 'r') as f:
                lines = [l for l in f.readlines() if "#" not in l]
                if len(lines) > 0:
                    pi_score = pd.read_csv(
                        os.path.join(subdir, pi_score_files[0]))
                    pi_score['jobs'] = str(job)
                else:
                    pi_score = pd.DataFrame.from_dict(
                        {"pi_score": ['SC:  mds: too many atoms']})
                f.close()
            filtered_df['jobs'] = str(job)
            pi_score['interface'] = pi_score['chains']
            filtered_df = pd.merge(filtered_df,
                                   pi_score,
                                   on=['jobs', 'interface'])
            try:
                filtered_df = filtered_df.drop(columns=[
                    "#PDB", "pdb", " pvalue", "chains", "predicted_class"
                ])
            except:
                pass

        output_df = pd.concat([output_df, filtered_df])
    return output_df


# NB: adapted from https://www.embopress.org/doi/full/10.1038/s44320-023-00005-6
# https://github.com/KatjaLuckLab/AlphaFold_manuscript/blob/main/scripts/calculate_template_independent_metrics.py
def calculate_iPAE(multimer_model_pickle, model_path):
    """Calculate iPAE using code adapted from https://github.com/fteufel/alphafold-peptide-receptors/blob/main/qc_metrics.py. Following the publication, the distance threshold to define contact is set at 0.35nm (3.5A) between CA atoms. Lower score means better.

    Returns:
        iPAE (float): iPAE score of the predicted model
    """

    #model_path = os.path.join(self.path_to_model,f'{self.predicted_model}.pdb')

    df = pd.DataFrame({})

    prediction = pd.read_pickle(multimer_model_pickle)

    # Extract plddt and PAE average over binding interface
    model_mdtraj = md.load(model_path)
    table, _ = model_mdtraj.topology.to_dataframe()
    table = table[(table['name'] == 'CA')]
    table['residue'] = np.arange(0, len(table))

    # receptor (domain) as chainID 0 and ligand (motif) chain as chainID 1 because I always use two chains
    # for prediction and the calling of receptor and ligan is arbitrary
    receptor_res = table[table['chainID'] == 0]['residue']
    ligand_res = table[table['chainID'] == 1]['residue']

    input_to_calc_contacts = [
        list(product) for product in itertools.product(ligand_res.values,
                                                       receptor_res.values)
    ]

    contacts, input_to_calc_contacts = md.compute_contacts(
        model_mdtraj,
        contacts=input_to_calc_contacts,
        scheme='closest',
        periodic=False)
    ligand_res_in_contact = []
    receptor_res_in_contact = []

    for i in input_to_calc_contacts[np.where(
            contacts[0] < 0.35)]:  # threshold in nm
        ligand_res_in_contact.append(i[0])
        receptor_res_in_contact.append(i[1])
    receptor_res_in_contact, receptor_res_counts = np.unique(
        np.asarray(receptor_res_in_contact), return_counts=True)
    ligand_res_in_contact, ligand_res_counts = np.unique(
        np.asarray(ligand_res_in_contact), return_counts=True)

    if len(ligand_res_in_contact) > 0:
        ipae = np.median(prediction['predicted_aligned_error'][
            receptor_res_in_contact, :][:, ligand_res_in_contact])
    else:
        ipae = 50  # if no residue in contact, impute ipae with large value

    return ipae


def main(argv):
    jobs = os.listdir(FLAGS.output_dir)
    good_jobs = []
    iptm_ptm = []
    iptm = []
    mpDockq_scores = []
    ipae_scores = []
    count = 0
    for job in jobs:
        logging.info(f"now processing {job}")
        if os.path.isfile(
                os.path.join(FLAGS.output_dir, job, 'ranking_debug.json')):
            count = count + 1
            result_subdir = os.path.join(FLAGS.output_dir, job)
            json_path = os.path.join(result_subdir, "ranking_debug.json")
            with open(json_path, 'r', encoding="utf-8") as json_file:
                data = json.load(json_file)
                rank_model = data['order'][FLAGS.rank]
            if "iptm" in data.keys() or "iptm+ptm" in data.keys():
                iptm_ptm_score = data['iptm+ptm'][rank_model]
                try:
                    pickle_path = os.path.join(result_subdir, f"result_{rank_model}.pkl")
                    with open(pickle_path, 'rb') as pickle_file:
                        check_dict = pickle.load(pickle_file)
                except FileNotFoundError:
                    print(
                        os.path.join(result_subdir, f"result_{rank_model}.pkl")
                        + " does not exist. Will search for pkl.gz")
                    pickle_path = os.path.join(result_subdir, f"result_{rank_model}.pkl.gz")
                    check_dict = pickle.load(gzip.open(pickle_path))
                finally:
                    print(
                        "finished reading result pickle for the best model.")
                # NB: seqs not produced by standard AlphaFold (only available with AlphaPullDown)
                # this why the nest lines is commented
                #seqs = check_dict['seqs']
                iptm_score = check_dict['iptm']
                pae_mtx = check_dict['predicted_aligned_error']
                # NB: seqs not produced by standard AlphaFold (only available with AlphaPullDown)
                # this why the nest lines is commented
                #check = examine_inter_pae(pae_mtx,seqs,cutoff=FLAGS.cutoff)
                check = True
                mpDockq_score = obtain_mpdockq(
                    os.path.join(FLAGS.output_dir, job))
                ipae_score = calculate_iPAE(
                    os.path.join(result_subdir, f"result_{rank_model}.pkl"),
                    os.path.join(FLAGS.output_dir, job, f"ranked_{FLAGS.rank}.pdb"))
                if check:
                    good_jobs.append(str(job))
                    iptm_ptm.append(iptm_ptm_score)
                    iptm.append(iptm_score)
                    mpDockq_scores.append(mpDockq_score)
                    ipae_scores.append(ipae_score)
            logging.info(
                f"done for {job} {count} out of {len(jobs)} finished.")
    other_measurements_df = pd.DataFrame.from_dict({
        "jobs": good_jobs,
        "rank": FLAGS.rank,
        "model": rank_model,
        "iptm_ptm": iptm_ptm,
        "iptm": iptm,
        "mpDockQ/pDockQ": mpDockq_scores,
        "iPAE": ipae_scores
    })
    # NB: the computation requires a conda env set available from AlphaPullDown
    # I did not install the conda env pi_score, there, the following 2 lines have been commented
    #pi_score_df = run_and_summarise_pi_score(FLAGS.output_dir,good_jobs,FLAGS.surface_thres)
    #pi_score_df=pd.merge(pi_score_df,other_measurements_df,on="jobs")
    pi_score_df = other_measurements_df
    columns = list(pi_score_df.columns.values)
    columns.pop(columns.index('jobs'))
    pi_score_df = pi_score_df[['jobs'] + columns]
    pi_score_df = pi_score_df.sort_values(by='iptm', ascending=False)
    pi_score_df = pi_score_df.drop(columns=['jobs'])
    if pi_score_df.size == 0:
        logging.error("ERROR: No data available to compute the scores")
        sys.exit(1)

    pi_score_df.to_csv(os.path.join(FLAGS.output_dir,
                                    f"qc_metrics_multimer_rank{FLAGS.rank}.tsv"),
                       sep='\t',
                       index=False)


if __name__ == '__main__':
    app.run(main)
