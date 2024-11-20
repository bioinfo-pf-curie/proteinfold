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
include { dynamicBind } from '../process/dynamicBind'
include { getSoftwareOptions } from '../../common/process/utils/getSoftwareOptions'
include { getSoftwareVersions } from '../../common/process/utils/getSoftwareVersions'
include { mqcDynamicBind } from '../process/mqcDynamicBind'

/*
=====================================
            WORKFLOW 
=====================================
*/

workflow dynamicBindWkfl {

  take:

  proteinLigandCh
  dynamicBindDatabase

  main:

  ///////////////////
  // Init channels //
  ///////////////////
  optionsCh = Channel.empty()
  versionsCh = Channel.empty()
  
  dynamicBind(proteinLigandCh, dynamicBindDatabase)

  versionsCh = versionsCh.mix(dynamicBind.out.versions)
  optionsCh = optionsCh.mix(dynamicBind.out.options)

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
  mqcDynamicBind(
    dynamicBind.out.scores.collect(),
    "${projectDir}/assets/mqcCfgDynamicBind.yaml",
    optionsYamlCh,
    versionsYamlCh
  )

}
