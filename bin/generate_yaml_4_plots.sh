#! /bin/bash

set -euo pipefail
#!/bin/bash

# Check if an argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <folder>"
    exit 1
fi

folder="$1"
png_files=()

# Check if the folder exists
if [ ! -d "$folder" ]; then
    echo "Folder '$folder' does not exist."
    exit 1
fi

# Search for png files and populate the array
while IFS= read -r -d '' file; do
    # Use basename to extract the filename
    filename=$(basename "$file" | sed -e "s/\.png//g")
    png_files+=("$filename")
done < <(find "$folder" \( -type f -o -type l \) -name "*.png" -print0)

png_files=($(printf "%s\n" "${png_files[@]}" | sort -r))

###################
# utils functions #
###################
has_plddt=0
has_pae=0
has_iptm=0
has_colabfold=0
has_alphafold=0
has_afmassive=0
function section_info {
  if [[ "$1" =~ "coverage" ]]; then
	  echo "    section_name: \"Sequence coverage\""
	  echo "    description: \"Number of sequences found during the multiple aligments step.\""
	  exit 0
  fi
  if [[ "$1" =~ "models_scores_plddts" ]]; then
	  echo "    section_name: \"Model scores\""
	  echo "    description: \"Scores of the models based on the plDDTs.\""
	  has_plddt=1
	  exit 0
  fi
  if [[ "$1" =~ "models_scores_iptm+ptm" ]]; then
	  echo "    section_name: \"Model scores\""
	  echo "    description: \"Scores of the models based on the 0.80*ipTM + 0.2*pTM criteria.\""
      has_iptm=1
	  exit 0
  fi
  if [[ "$1" =~ "score_distribution_plddts" ]]; then
	  echo "    section_name: \"Score histogram\""
	  echo "    description: \"Scores of the models based on the plDDTs.\""
	  has_plddt=1
	  exit 0
  fi
  if [[ "$1" =~ "score_distribution_iptm+ptm" ]]; then
	  echo "    section_name: \"Score histogram\""
	  echo "    description: \"Scores of the models based on the 0.80*ipTM + 0.2*pTM criteria.\""
      has_iptm=1
	  exit 0
  fi
  if [[ "$1" =~ "plddt_PAE" ]]; then
	  rank=${1:5:1}
	  $((rank++))
	  echo "    section_name: \"plDDT/PAE: model number ${rank}\""
	  echo "    description: \"The predicted local Distance Difference Test and Predicted Aligned Error.\""
	  has_plddt=1
	  has_pae=1
	  exit 0
  fi
  if [[ "$1" =~ "top_5_plddt" || "$1" =~ "0_plddt" ]]; then
	  echo "    section_name: \"plDDT: top 5 models\""
	  echo "    description: \"The predicted local Distance Difference Test of the top 5 models.\""
	  has_plddt=1
	  exit 0
  fi
  if [[ "$1" =~ "top_5_PAE" || "$1" =~ "0_pae"  ]]; then
	  echo "    section_name: \"PAE: top 5 models\""
	  echo "    description: \"The Predicted Aligned Error of the top 5 models.\""
	  has_pae=1
	  exit 0
  fi
  if [[ "$1" =~ "versions_density" ]]; then
	  echo "    section_name: \"Score density by AlphaFold model\""
	  echo "    description: \"Different versions of AlphaFold multimer have been released (v1, v2, v3). This plots de density of the scores for each version. The scores of the models are based on the 0.80*ipTM + 0.2*pTM criteria.\""
      has_iptm=1
	  exit 0
  fi

  #echo "ERROR: the png file '$i' does no match any pattern"
}

########################
# detect software used #
########################

software_versions=$(tr -s '\n' ' ' < $2)
if [[ "${software_versions}" =~ "colabfold" ]]; then
	has_colabfold=1
fi
if [[ "${software_versions}" =~ "AFMassive" ]]; then
	has_afmassive=1
	has_alphafold=1
fi
if [[ "${software_versions}" =~ "AlphaFold" ]]; then
	has_alphafold=1
fi

##########################
# generate the yaml file #
##########################

echo "custom_data:"

cat << EOF
  ranking_debug_table:
    id: 'ranking_debug_table'
    parent_id: ranking_debug
    parent_name: 'Model ranking'
    section_name: 'Model ranking'
    description: 'Model ranking'
    plot_type: 'table'
    pconfig:
      id: 'ranking_debug_table'
      format: '{:,.3f}'
EOF

### definition_legend ###
cat << EOF
  definition_legend:
    id: 'definition_legend'
    parent_id: legend
    parent_name: 'Legend'
    section_name: 'Definitions'
    plot_type: 'html'
    data: |
        <dl class="dl-horizontal">
EOF

if [[ ${has_pae} ]]; then
cat << EOF
            <dt>PAE</dt><dd><samp>Predicted aligned error (PAE) is a measure of how confident AlphaFold2 is in the relative position of two residues within the predicted structure. PAE is defined as the expected positional error at residue X, measured in Ångströms (Å), if the predicted and actual structures were aligned on residue Y.</samp></dd>
EOF
fi

if [[ ${has_plddt} ]]; then
cat << EOF
            <dt>plDDT</dt><dd><samp>The predicted local distance difference test (pLDDT) is a per-residue measure of local confidence. It is scaled from 0 to 100, with higher scores indicating higher confidence and usually a more accurate prediction.<br><br>pLDDT measures confidence in the local structure, estimating how well the prediction would agree with an experimental structure. It is based on the local distance difference test Cα (lDDT-Cα), which is a score that does not rely on superposition but assesses the correctness of the local distances.<br><br> - Regions with pLDDT > 90 are expected to be modelled to high accuracy. These should be suitable for any application that benefits from high accuracy (e.g. characterising binding sites).<br><br> - Regions with pLDDT between 70 and 90 are expected to be modelled well (a generally good backbone prediction).<br><br> - Regions with pLDDT between 50 and 70 are low confidence and should be treated with caution. </samp></dd>
EOF
fi

if [[ ${has_iptm} ]]; then
cat << EOF
            <dt>ipTM</dt><dd><samp>This is interface predicted template modelling (ipTM) score. It measures the accuracy of the predicted relative positions of the subunits forming the protein-protein complex. Values higher than 0.8 represent confident high-quality predictions, while values below 0.6 suggest likely a failed prediction. ipTM values between 0.6 and 0.8 are a grey zone where predictions could be correct or wrong.</samp></dd>
            <dt>pTM</dt><dd><samp>This is the predicted template modelling (pTM) score. pTM is an integrated measure of how well AlphaFold-Multimer has predicted the overall structure of the complex. It is the predicted TM score for a superposition between the predicted structure and the hypothetical true structure.</samp></dd>
EOF
fi


cat << EOF
        </dl>
EOF

### reference_legend
cat << EOF
  reference_legend:
    id: 'reference_legend'
    parent_id: legend
    parent_name: 'Legend'
    section_name: 'References'
    description: 'List of publications'
    plot_type: 'html'
    data: |
            <ul>
EOF

if [[ ${has_colabfold} ]]; then
cat << EOF
              <li>Mirdita, M., Schütze, K., Moriwaki, Y. et al. ColabFold: making protein folding accessible to all. Nat Methods 19, 679–682 (2022). <a href="https://doi.org/10.1038/s41592-022-01488-1">https://doi.org/10.1038/s41592-022-01488-1</a></li>
EOF
fi

if [[ ${has_alphafold} || ${has_afmassive} ]]; then
cat << EOF
              <li>Jumper, J., Evans, R., Pritzel, A. et al. Highly accurate protein structure prediction with AlphaFold. Nature 596, 583–589 (2021). <a href="https://www.nature.com/articles/s41586-021-03819-2">https://doi.org/10.1038/s41586-021-03819-2</a></li>
              <li>AlphaFold Database FAQ: <a href="https://alphafold.ebi.ac.uk/faq>How confident should I be in a prediction?</a></li>
EOF
fi

if [[ ${has_afmassive} ]]; then
cat << EOF
              <li>Björn Wallner, AFsample: improving multimer prediction with AlphaFold using massive sampling, Bioinformatics, Volume 39, Issue 9, September 2023, btad573, <a href="https://doi.org/10.1093/bioinformatics/btad573">https://doi.org/10.1093/bioinformatics/btad573</a></li>
EOF
fi

if [[ ${has_pae} ]]; then
cat << EOF
              <li>EMBL-EBI Training: <a href="https://www.ebi.ac.uk/training/online/courses/alphafold/inputs-and-outputs/evaluating-alphafolds-predicted-structures-using-confidence-scores/pae-a-measure-of-global-confidence-in-alphafold-predictions/">PAE: A measure of global confidence in AlphaFold2 predictions</a></li>
EOF
fi

if [[ ${has_plddt} ]]; then
cat << EOF
              <li>EMBL-EBI Training: <a href=""https://www.ebi.ac.uk/training/online/courses/alphafold/inputs-and-outputs/evaluating-alphafolds-predicted-structures-using-confidence-scores/plddt-understanding-local-confidence/>pLDDT: Understanding local confidence</a></li>
EOF
fi

if [[ ${has_iptm} ]]; then
cat << EOF
              <li>EMBL-EBI Training: <a href="https://www.ebi.ac.uk/training/online/courses/alphafold/inputs-and-outputs/evaluating-alphafolds-predicted-structures-using-confidence-scores/confidence-scores-in-alphafold-multimer/">Confidence scores in AlphaFold-Multimer</a></li>
EOF
fi

cat << EOF
            </ul>
EOF

# Print the array elements
for file in "${png_files[@]}"; do
    echo ""
    echo "  $file:"
    echo "    id: \"$file\""
    echo "    parent_id: prediction_structure_plots"
    echo "    parent_name: \"Plots\""
cat << EOF
$(section_info $file)
EOF
done

echo ""
echo "sp:"

for file in "${png_files[@]}"; do
    echo ""
    echo "  $file:"
    echo "    fn: \"${file}.png\""
done


echo ""
echo "  ranking_debug_table:"
echo "    fn: ranking_debug.tsv"

echo ""
echo "ignore_images: false"
echo ""
echo "report_section_order:"
echo "  prediction_structure_plots:"
echo "    order: -1000"


counter=-1000
for file in "${png_files[@]}"; do
    counter=$((counter - 10))
    echo "  ${file}:"
    echo "    order: ${counter}"
done


echo "  ranking_debug:"
echo "    order: -1300"
echo "  ranking_debug_table:"
echo "    order: -1290"
echo "  legend:"
echo "    order: -1500"
echo "  definition_legend:"
echo "    order: -1450"
echo "  reference_legend:"
echo "    order: -1440"
echo "  software:"
echo "    order: -2000"
echo "  software_versions:"
echo "    order: -1990"
echo "  software_options:"
echo "    order: -1980"
echo "  summary:"
echo "    order: -2300"


