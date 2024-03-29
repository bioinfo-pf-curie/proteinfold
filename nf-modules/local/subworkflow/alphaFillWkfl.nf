/*
Copyright Institut Curie 2024

This software is a computer program whose purpose is to
predict 3D structure of proteins.
You can use, modify and/ or redistribute the software under the terms
of license (see the LICENSE file for more details).
The software is distributed in the hope that it will be useful,
but "AS IS" WITHOUT ANY WARRANTY OF ANY KIND.
Users are therefore encouraged to test the software's suitability as regards
their requirements in conditions enabling the security of their systems and/or data.
The fact that you are presently reading this means that you have had knowledge
of the license and that you accept its terms.

*/

/*
==================================
           INCLUDE
==================================
*/ 

// Processes
include { alphaFill } from '../process/alphaFill'
include { generateAlphaFillTsv } from '../process/generateAlphaFillTsv'
include { multiqcScoresAlphaFill } from '../process/multiqcScoresAlphaFill'

/*
=====================================
            WORKFLOW 
=====================================
*/

workflow alphaFillWkfl {

  take:

  predictionsCh

  main:

  // step - launch AlphaFill
  alphaFill(
    predictionsCh,
    params.alphaFillDatabase
  )

  // step - generate tsv from the json
  generateAlphaFillTsv(
    alphaFill.out.predictions,
    params.alphaFillDatabase
  )

  // step - generate multiqc for AlphaFill
  multiqcScoresAlphaFill(
    generateAlphaFillTsv.out.tsv,
    Channel.fromPath("${projectDir}/assets/multiqcConfigScoresAlphaFill.yaml") 
  )

}
