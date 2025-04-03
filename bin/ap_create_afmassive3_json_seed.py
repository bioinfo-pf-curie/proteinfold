#!/usr/bin/env python
"""
This script processes JSON files to create new JSON files based on seed and protein information.

It reads the input JSON file, extracts seed information,
validates the seeds, and generates new JSON files
with updated seed values and protein names.
The script supports both single and multiple seed configurations.

Usage:
    python ap_create_afmassive3_json_seed.py --json <path_to_json>
    --protein <protein_name> [--num_seeds <number_of_seeds>]

Flags:
    --json: Path to the input JSON file (required).
    --protein: Name of the protein (required).
    --num_seeds: Number of seeds to generate (optional).
"""

import json
import os
from absl import app, flags

FLAGS = flags.FLAGS

flags.DEFINE_string("json", None, "Path to the JSON file")
flags.DEFINE_string("protein", None, "Path to the protein file")
flags.DEFINE_integer("num_seeds", None, "Number of seeds")
flags.mark_flag_as_required("json")
flags.mark_flag_as_required("protein")


def open_json(file_path):
    """
    Opens a JSON file and returns its content.

    Args:
        file_path (str): Path to the JSON file.

    Returns:
        dict: Content of the JSON file.
    """
    with open(file_path, "r", encoding="utf-8") as file:
        return json.load(file)


def get_seed(data):
    """
    Extracts the seed information from the data.

    Args:
        data (dict): Data containing seed information.

    Returns:
        list: List of seeds.
    """
    return data["modelSeeds"]


def test_list_modelSeeds(seed):
    """
    Tests if the seed list contains only integers.

    Args:
        seed (list): List of seeds.

    Returns:
        bool: True if all elements are integers, raises ValueError otherwise.
    """
    try:
        if isinstance(seed, list):
            if all(isinstance(element, int) for element in seed):
                return True

            raise ValueError(
                "All elements inside your modelSeeds list are not integers"
            )

        raise ValueError("modelSeeds is not a list")
    except ValueError as error:
        print("Caught an error: " + repr(error))


def create_json(data, seed, num_seeds, protein):
    """
    Creates JSON files based on the seeds and protein information.

    Args:
        data (dict): Original data.
        seed (list): List of seeds.
        num_seeds (int): Number of seeds.
        protein (str): Protein information.

    Returns:
        None
    """
    os.makedirs("seeds_json", exist_ok=True)
    if len(seed) > 1 and num_seeds is None:
        for s in seed:
            if s > 2**32:
                print(
                    f"WARNING: your seed {s} has been ignored because it is greater than 2^32"
                )
                continue

            content = data.copy()
            content["modelSeeds"] = [s]
            content["name"] = f"{protein}_seed_{s}"
            filename = "seeds_json/" + content["name"] + ".json"
            with open(filename, "w", encoding="utf-8") as outfile:
                json.dump(content, outfile)
    elif len(seed) == 1 and num_seeds is not None:
        for n in range(num_seeds):
            new_seed = seed[0] + n
            if new_seed > 2**32:
                print(
                    f"""WARNING: your seed {new_seed} and the others have been ignored
                        because they are greater than 2^32"""
                )
                break

            content = data.copy()
            content["modelSeeds"] = [new_seed]
            content["name"] = f"{protein}_seed_{new_seed}"
            filename = "seeds_json/" + content["name"] + ".json"
            with open(filename, "w", encoding="utf-8") as outfile:
                json.dump(content, outfile)
    else:
        print(
            """ERROR: you can either specify several seeds in modelSeeds (num_seeds=None)
               or choose a number of seeds with num_seeds by having a single starting seed
               in modelSeeds."""
        )
        exit(1)


def main(argv):
    """
    Main function to execute the script.

    Args:
        argv (list): List of command-line arguments.

    Returns:
        None
    """
    del argv
    data = open_json(FLAGS.json)
    seed = get_seed(data)
    test_list_modelSeeds(seed)
    create_json(data, seed, FLAGS.num_seeds, FLAGS.protein)


if __name__ == "__main__":
    app.run(main)
