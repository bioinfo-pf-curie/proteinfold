#! /usr/bin/env python

from absl import flags
from absl import app
import csv
import os
import sys

from typing import Sequence, Tuple

from transformers import pipeline, RobertaTokenizer, AutoModel

FLAGS = flags.FLAGS

flags.DEFINE_string('fasta_file', None, 'FASTA input file.')
flags.DEFINE_string('output_dir', None,
                    'Output directory to write nanoBERT results.')
flags.DEFINE_string('model_dir', '/app/nanobert',
                    'Directory with nanoBERT model parameters.')
flags.DEFINE_integer('top_k', 5, 'Select the tok k scores.')


# Function from alphafold/data/parsers.py
def parse_fasta(fasta_string: str) -> Tuple[Sequence[str], Sequence[str]]:
    """
    Parses FASTA string and returns list of strings with amino-acid sequences.

    Arguments:
      fasta_string: The string contents of a FASTA file.
  
    Returns:
      A tuple of two lists:
      * A list of sequences.
      * A list of sequence descriptions taken from the comment lines. In the
        same order as the sequences.
    """
    sequences = []
    descriptions = []
    index = -1
    for line in fasta_string.splitlines():
        line = line.strip()
        if line.startswith('>'):
            index += 1
            descriptions.append(line[1:])  # Remove the '>' at the beginning.
            sequences.append('')
            continue
        elif not line:
            continue  # Skip blank lines.
        sequences[index] += line

    return sequences, descriptions


def nanobert_mask(sequence: str, residue: int):
    return sequence[:residue] + '<mask>' + sequence[residue + 1:]


def format_output(residue_probability: list, residue: int = None):

    if residue is None:
        print('ERROR in function format_output: residue is None.')
        sys.exit(1)

    rank = 0
    score_info = {}
    for hit in residue_probability:
        rank = rank + 1
        score_info['residue'] = residue
        score_info[f'score{rank}'] = hit['score']
        score_info[f'aa{rank}'] = hit['token_str']
        # Dict are store in memory, actions below will be 
        # seen outside the function
        hit.pop('sequence')
        hit.pop('token')
        hit['residue'] = residue
        # This below just helps to have the resideu / score / aa order in the dict
        hit['score1'] = hit.pop('score')
        hit['score'] = hit.pop('score1')
        hit['aa'] = hit.pop('token_str')

    return score_info
def interpolate_color(value):
    if value < 0:
        value = 0
    elif value > 1:
        value = 1

    # Define RGB values for red, orange, and green in hexadecimal format
    red = (255, 0, 0)
    orange = (255, 128, 0)
    green = (0, 255, 0)

    # Interpolate between the colors based on the value
    if value < 0.5:
        red_weight = (0.5 - value) / 0.5
        orange_weight = 1 - red_weight
        return '#{:02X}{:02X}{:02X}'.format(*[int(red_channel * red_weight + orange_channel * orange_weight) for red_channel, orange_channel in zip(red, orange)])
    else:
        green_weight = (value - 0.5) / 0.5
        orange_weight = 1 - green_weight
        return '#{:02X}{:02X}{:02X}'.format(*[int(orange_channel * orange_weight + green_channel * green_weight) for orange_channel, green_channel in zip(orange, green)])


def write_mqc_list_dict(filename:str, list_dict:list[dict]):
    """ 
    Write yaml formmated file for multiqc

    Arguments:
      filename: name of the file
      list_dict: input data
      dict are taken into account
    """

    with open(filename, 'w', newline='') as file:
        file.write('data:\n' )
        for row in list_dict:
            #file.write('  p' + str(row['residue']) + ':\n')
            file.write('  \'p' + str(row['residue']) + '->' +  str(row['aa'])+ '\':\n')
            file.write('    x: ' + str(row['residue']) + '\n')
            file.write('    y: ' + str(row['score']) + '\n')
            file.write('    color: \'' + str(interpolate_color(row['score'])) + '\'\n')
            #file.write('    name: \'' + str(row['aa']) + '\'\n')


def write_csv_list_dict(filename:str, list_dict:list[dict], fieldnames=None):
    """ 
    Write a csv file from a list of dict. Separator is '\t'

    Arguments:
      filename: name of the file
      list_dict: input data
      fieldnames: select the fields to filter from the dic. If 'None', all the keys in the
      dict are taken into account
    """

    if fieldnames is None:
        fieldnames = list(list_dict[0].keys())

    with open(filename, 'w', newline='') as csv_file:
        writer = csv.DictWriter(csv_file,
                                fieldnames=fieldnames,
                                delimiter='\t')
        writer.writeheader()

        for row in list_dict:
            filtered_row = {
                key: value
                for key, value in row.items() if key in fieldnames
            }
            writer.writerow(filtered_row)

def main(argv):

    if not os.path.exists(f'{FLAGS.fasta_file}'):
        print(
            f'ERROR: in option --fasta_file, the file \'{FLAGS.fasta_file}\' does not exist.'
        )
        sys.exit(1)

    if not os.path.isdir(f'{FLAGS.output_dir}'):
        print(f'{FLAGS.output_dir} is not a directory.')
        sys.exit(1)

    with open(f'{FLAGS.fasta_file}') as f:
        fasta_str = f.read()

    sequence, description = parse_fasta(fasta_str)

    if len(sequence) > 1:
        print(f'ERROR: the fasta file contains more than one sequence.')
        sys.exit(1)

    tokenizer = RobertaTokenizer.from_pretrained(f"{FLAGS.model_dir}",
                                                 return_tensors="pt")
    unmasker = pipeline('fill-mask',
                        model=f"{FLAGS.model_dir}",
                        tokenizer=tokenizer,
                        top_k=FLAGS.top_k)

    all_residue_probability = []
    all_score_info = []
    for residue_i in range(len(sequence[0])):
        seq_mask = nanobert_mask(sequence[0], residue_i)
        residue_probability = unmasker(seq_mask)
        score_info = format_output(residue_probability, residue = residue_i + 1)
        all_score_info = all_score_info + [score_info]
        all_residue_probability = all_residue_probability + residue_probability

    write_csv_list_dict(os.path.join(f'{FLAGS.output_dir}', 'nanobert_scores.tsv'), all_residue_probability)
    write_csv_list_dict(os.path.join(f'{FLAGS.output_dir}', 'nanobert_matrix_scores.tsv'), all_score_info)
    write_mqc_list_dict(os.path.join(f'{FLAGS.output_dir}', 'nanobert_scores.yaml'), all_residue_probability)


if __name__ == "__main__":
    """ 
    Compute nanoBERT scores
    https://huggingface.co/NaturalAntibody
    Hadsund JT, Satława T, Janusz B, Shan L, Zhou L, Röttger R, Krawczyk K. nanoBERT: a deep learning model for gene agnostic navigation of the nanobody mutational space. Bioinform Adv. 2024 Mar 6;4(1):vbae033. doi: 10.1093/bioadv/vbae033. PMID: 38560554; PMCID: PMC10978573.
    """
    flags.mark_flags_as_required([
        'fasta_file',
        'output_dir',
    ])

    app.run(main)
