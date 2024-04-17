#!/usr/bin/env python

"""generate header used as input yaml file for multiqc"""

import argparse

parser = argparse.ArgumentParser()
parser.add_argument("-i", "--input", help="version file", type=str, default='')
parser.add_argument("-s",
                    "--split",
                    help="string to split the line",
                    type=str,
                    default=' ')
parser.add_argument("-t",
                    "--id",
                    help="section id",
                    type=str,
                    default='software_versions')
parser.add_argument("-n",
                    "--name",
                    help="section name",
                    type=str,
                    default=' Versions')
parser.add_argument(
    "-d",
    "--description",
    help="section ",
    type=str,
    default='This information is collected at runtime from the software output.'
)
args = parser.parse_args()

versions = {}
with open(args.input, 'w',  encoding="utf-8") as f:
    for line in f:
        if line.strip():
            (key, val) = line.strip().split(args.split)
            if key in versions.keys():
                if val != versions[str(key)]:
                    versions[str(key)] = versions[str(key)] + " - " + val
            else:
                versions[str(key)] = val

# Dump to YAML
print(f"""
id: '{args.id}'
parent_id: software
parent_name: 'Software'
section_name: '{args.name}'
plot_type: 'html'
description: '{args.description}'
data: |
    <dl class="dl-horizontal">
""")
#.format(args.id, args.name, args.description)
for k, v in versions.items():
    print(f"        <dt>{k}</dt><dd><samp>{v}</samp></dd>")
print("    </dl>")
