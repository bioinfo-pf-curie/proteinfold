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
include { diffDock } from '../process/diffDock'
include { getSoftwareOptions } from '../../common/process/utils/getSoftwareOptions'
include { getSoftwareVersions } from '../../common/process/utils/getSoftwareVersions'
include { mqcDiffDock } from '../process/mqcDiffDock'

/*
=====================================
            WORKFLOW 
=====================================
*/

workflow diffDockWkfl {

  take:

  proteinLigandCh
  diffDockDatabase
  diffDockArgsYamlFile

  main:

  ///////////////////
  // Init channels //
  ///////////////////
  optionsCh = Channel.empty()
  versionsCh = Channel.empty()
  
  diffDock(proteinLigandCh, diffDockDatabase, diffDockArgsYamlFile)

  versionsCh = versionsCh.mix(diffDock.out.versions)
  optionsCh = optionsCh.mix(diffDock.out.options)

  ////////////////////
  // Software infos //
  ////////////////////
  getSoftwareOptions(optionsCh.unique().collectFile(sort: true))
  getSoftwareVersions(versionsCh.unique().collectFile(sort: true))
  optionsYamlCh = getSoftwareOptions.out.optionsYaml.collect(sort: true).ifEmpty([])
  versionsYamlCh = getSoftwareVersions.out.versionsYaml.collect(sort: true).ifEmpty([])


  /////////////
  // multiqc //
  /////////////
  mqcDiffDock(
    diffDock.out.scores.collect(),
    "${projectDir}/assets/multiqcConfigDiffDock.yaml",
    optionsYamlCh,
    versionsYamlCh
  )

}
