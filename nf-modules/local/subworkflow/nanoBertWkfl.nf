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
include { fastaChecker } from '../process/fastaChecker'
include { nanoBert } from '../process/nanoBert'
include { mqcNanoBert } from '../process/mqcNanoBert'
include { getSoftwareOptions } from '../../common/process/utils/getSoftwareOptions'
include { getSoftwareVersions } from '../../common/process/utils/getSoftwareVersions'

/*
=====================================
            WORKFLOW 
=====================================
*/

workflow nanoBertWkfl {

  take:

  fastaFilesCh
  fastaPathCh

  main:
  
  ///////////////////
  // Init channels //
  ///////////////////

  optionsCh = Channel.empty()
  versionsCh = Channel.empty()

  /////////////////////////////////////////////////////////
  // Check that the fasta files are correctly formatted  //
  /////////////////////////////////////////////////////////
  fastaChecker(fastaPathCh)
  nanoBert(fastaFilesCh, params.nanoBertDatabase)

  // step - generate multiqc for nanoBERT
  mqcNanoBert(
    nanoBert.out.scores
      .combine(Channel.fromPath("${projectDir}/assets/mqcCfgNanoBert.yaml"))
  )

}
