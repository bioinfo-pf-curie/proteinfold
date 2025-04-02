#! /usr/bin/env python
import json
import os
from absl import app, flags

FLAGS = flags.FLAGS

flags.DEFINE_string('json', None, 'Path to the JSON file')

flags.DEFINE_string('protein', None, 'Path to the JSON file')

flags.DEFINE_integer('num_seeds', None, 'Number of seeds')

flags.mark_flag_as_required('json')

flags.mark_flag_as_required('protein')

def open_json(file_path):
    with open(file_path, 'r') as file:
        return json.load(file)

def get_seed(data):
    return data["modelSeeds"]

def test_list_modelSeeds(seed):
    try:
        if isinstance(seed, list):
            if all(isinstance(element, int) for element in seed):
                return True
            else:
                raise ValueError('all elements inside your modelSeeds list are not integers')
        else:
            raise ValueError('modelSeeds is not a list')

    except ValueError as error:
        print('Caught an error: ' + repr(error))   

def create_json(data, seed, num_seeds, protein):
    os.makedirs('seeds_json', exist_ok=True)
    if len(seed) > 1 and num_seeds is None :
        for s in seed:
            if s > 2 ** 32:
                print(f"WARNING: your seed {s}  has been ignored because it is greater than 2 exponent 32")
                continue
            # Modifiez le contenu
            content = data.copy()
            content['modelSeeds'] = [s]
            content['name'] = f'{protein}_seed_{s}'
            
            # Définissez le nom du fichier
            filename = 'seeds_json/' + content['name']+ '.json'
            
            # Écrivez le contenu dans le fichier
            with open(filename, 'w') as outfile:
                json.dump(content, outfile)
    elif len(seed) == 1 and num_seeds is not None :
        for n in range(num_seeds):
            new_seed = seed[0] + n
            if n > 2 ** 32:
                print(f"WARNING: your seed {new_seed} and the other have been ignored because there are greater than 2 exponent 32")
                break
            # Modifiez le contenu
            content = data.copy()
            content['modelSeeds'] = [new_seed]
            content['name'] = f'{protein}_seed_{new_seed}'

            # Définissez le nom du fichier
            filename = 'seeds_json/' + content['name']+ '.json'
            
            # Écrivez le contenu dans le fichier
            with open(filename, 'w') as outfile:
                json.dump(content, outfile)
    else:
        print("ERROR: you can either specify several seeds in modelSeeds (num_seeds=None) or choose a number of seeds with num_seeds by having a single starting seed in modelSeeds.")
        exit(1)

def main(argv):
    del argv
    data = open_json(FLAGS.json)
    seed = get_seed(data)
    test_list_modelSeeds(seed)
    create_json(data, seed, FLAGS.num_seeds, FLAGS.protein)

if __name__ == "__main__":
    app.run(main)