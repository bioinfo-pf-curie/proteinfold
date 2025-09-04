#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

/*
=============================================
   Set of functions to check the input file
   with protein (pdb) and ligand (sdf) required
   by DynamicBind
=============================================
*/

// Function to check if a file exists and has the extension ext
def checkFileExistWithExt(filePath, ext = null) {
  def file = new File(filePath)
  if (!file.exists() || !file.isFile()) {
    exit(1, "${filePath} does not exist or is not a regular file")
  }

  // Check if the file has the extension ext
  if (ext != null) {
    if (!filePath.endsWith(ext)) {
      exit(1, "${filePath} does not have the '${ext}' extension")
    }
  }

  return true
}

// Function to check if columns exist in a CSV file
def checkColumnsExist(filePath, columns) {
  checkFileExistWithExt(filePath)
  def file = new File(filePath)

  // Read the first line (header) from the file
  def headerLine = null
  file.withReader { reader ->
    headerLine = reader.readLine()
  }

  if (headerLine == null) {
    exit(1, "${filePath} is empty")
  }

  // Split the header line into columns
  def headerColumns = headerLine.split(',')

  // Check if all specified columns exist

  columns.each { column ->
    if (!headerColumns.contains(column.trim())) {
      exit(1, "Column '${column}' not found in the CSV file ${filePath}")
    }
  }

  return true
}

def checkBlankLines(filePath) {
  checkFileExistWithExt(filePath)
  def file = new File(filePath)

  // Use BufferedReader with FileReader to read the file
  def reader
  try {
    reader = new BufferedReader(new FileReader(file))
    def lineCounter = 0

    // Read each line from the file
    reader.eachLine { line ->
      lineCounter += 1

      // Check if the line contains a space
      if (line.contains(' ')) {
        exit(1, "Line ${lineCounter} contains a space in the CSV file ${filePath}")
      }
    }
  }
  if (reader != null) {
    reader.close()
  }


  return true
}

// Function to check that there are the pdb and sdf files exist
def checkProteinLigandFiles(filePath) {
  checkFileExistWithExt(filePath)
  def file = new File(filePath)

  // Use BufferedReader with FileReader to read the file
  def reader
  try {
    reader = new BufferedReader(new FileReader(file))
    // skip the first line with the header
    def header = reader.readLine().split(',')
    println(header)
    def lineCounter = 1

    // Read each line from the file
    reader.eachLine { line ->
      lineCounter += 1
      def fields = line.split(',')
      def value = [:]
      value[header[0]] = fields[0]
      value[header[1]] = fields[1]
      checkFileExistWithExt(value.protein, 'pdb')
      checkFileExistWithExt(value.ligand, 'sdf')
    }
  }
  if (reader != null) {
    reader.close()
  }


  return true
}

// Function to check that the input file with path 
// to protein pdb and ligand sdf files is correctly formatted
def checkInput4Docking(filePath) {
  checkBlankLines(filePath)
  checkColumnsExist(filePath, ['protein', 'ligand'])
  checkProteinLigandFiles(filePath)

  return true
}

def buildFastaPathCh(fastaPath) {

  def fastaPathCh = Channel.fromPath(fastaPath)
  fastaPathCh
    .collect()
    .map { fileList ->
      // Use regex to extract the file extension
      def List extensionList = []
      fileList.each {
        def matcher = it =~ /.*\.(\w+)$/
        def extension = matcher ? matcher[0][1] : null
        extensionList.add(extension)
      }

      if (extensionList.unique().size() > 1) {
        def msg = "In the path " + params.fastaPath + " multiple file extension have been found: " + extensionList.unique() + ". Only one extension type must be found: either 'fasta' or 'json' (for AlphaFold3)"
        NFTools.printRedText(msg)
        exit(1, msg)
      }
    }

  return fastaPathCh
}

// Function to chack that the multimer version is valid
def checkMultimerVersions(String version) {
  def allowedVersions = ['v1', 'v2', 'v3']

  if (!(version in allowedVersions)) {
    error("version " + version + " is not supported.")
  }
}


/*
=================================================
  Create channel with alphaFold models to run the
  predictions in parallel inseatd of sequential.
  This is used with afMassive
=================================================
*/

def createAfModelsCh(String alphaFoldOptions, int predictionsPerModel = 5, int numberOfModels = 5, String multimerVersions = "v1,v2,v3") {
  // Set variables
  def List afModels
  def Map afModelsInfo = [:]
  def int modelNumber = 0
  def String modelsToRelaxOptions = ""
  def List multimerVersionsList
  def int randomSeed

  // This variable will store the new parameters
  def String alphaFoldOptionsParallel = alphaFoldOptions.toString()

  // Multimer
  if (alphaFoldOptions.contains('model_preset=multimer')) {
    multimerVersionsList = multimerVersions.split(',').toList()
    multimerVersionsList.each { version ->
      checkMultimerVersions(version)
      afModels = (1..numberOfModels).collect { model ->
        "model_${model}_multimer_${version}"
      }
      modelNumber += numberOfModels
    }
  }

  // Monomer
  if (!alphaFoldOptions.contains('model_preset=monomer_ptm') && (alphaFoldOptions.contains('model_preset=monomer') || !alphaFoldOptions.contains('model_preset'))) {
    afModels = (1..numberOfModels).collect { model ->
      "model_${model}"
    }
    modelNumber += numberOfModels
  }

  // Monomer pTM
  if (alphaFoldOptions.contains('model_preset=monomer_ptm')) {
    afModels = (1..6).collect { model ->
      "model_${model}_ptm"
    }
    modelNumber += numberOfModels
  }

  // We can not keep the same random_seed for each prediction
  // otherwise results would be the same.
  if (alphaFoldOptions.contains('random_seed')) {
    def String randomSeedParams = (alphaFoldOptions =~ /--random_seed=\d+/)[0]
    alphaFoldOptionsParallel = alphaFoldOptions.replace(randomSeedParams, '')
    randomSeed = randomSeedParams
      .replaceAll('--random_seed=', '')
      .toInteger()
  }

  // Check what is the option for relaxation.
  // We do not want to relax all the models 
  // as we we have only one model each time
  // which will be obviously the best
  if (alphaFoldOptions.contains('models_to_relax')) {
    modelsToRelaxOptions = (alphaFoldOptions =~ /--models_to_relax=\w+/)[0]
    alphaFoldOptionsParallel = alphaFoldOptionsParallel.replaceAll(modelsToRelaxOptions, '')
    alphaFoldOptionsParallel = alphaFoldOptionsParallel + " --models_to_relax=none"
  }
  else {
    alphaFoldOptionsParallel = alphaFoldOptionsParallel + " --models_to_relax=none"
  }

  // This is necessary to have a deterministic combination of model/pred with the random seed
  def afModelsList = (1..predictionsPerModel).collect { pred_i ->
    afModels.each {
      randomSeed = randomSeed + 1
      tuple(pred_i, it, randomSeed)
    }
  }
  def afModelsCh = Channel.fromList(afModelsList)

  afModelsInfo['alphaFoldOptionsParallel'] = alphaFoldOptionsParallel
  afModelsInfo['channel'] = afModelsCh
  afModelsInfo['modelsToRelaxOptions'] = modelsToRelaxOptions

  return afModelsInfo
}

/*
=================================================
  Create channel for a list a protein directories
=================================================
*/
def createFromCh(fromParams, fastaFilesCh) {
  def File fromParamsFile = new File(params[fromParams])
  if (!fromParamsFile.exists()) {
    exit(1, "The path to the folder '" + params[fromParams] + "' does not exist.")
  }
  if (!fromParamsFile.isDirectory()) {
    exit(1, "The path to the folder '" + params[fromParams] + "' is not a directory.")
  }

  def fromCh
  def proteinInDir
  def proteinInFasta
  def proteinUnion

  fromCh = Channel.fromPath("${params[fromParams]}/*", type: 'dir')
    .map { dir ->
      def String protein = dir
        .toString()
        .replaceAll(".*/", "")
      def File proteinDir = new File("${params[fromParams]}/${protein}")
      def dirFileList = []
      proteinDir.eachFile { file -> dirFileList.add(file.getAbsolutePath()) }
      tuple(protein, dirFileList)
    }

  proteinInDir = fromCh.map { it[0] }.collect().map { tuple('list', it) }
  proteinInFasta = fastaFilesCh.map { it[0] }.collect().map { tuple('list', it) }
  proteinUnion = proteinInDir.join(proteinInFasta)

  // Print warning if the msas is present but not the fasta file  
  proteinUnion.map {
    elementsNotPresent(it[2].toList(), it[1].toList()).each { prot ->
      def String msg
      msg = "WARNING (option ${fromParams}) - folder is present but no FASTA file available for protein '"
      msg = msg + prot + "'. The protein will be ignored."
      NFTools.printOrangeText(msg)
    }
  }

  // Print warning if the fasta file is present but not the msas folder
  proteinUnion.map {
    elementsNotPresent(it[1].toList(), it[2].toList()).each { prot ->
      def String msg
      msg = "WARNING (option ${fromParams}) - FASTA file is present but no folder available for protein '"
      msg = msg + prot + "'. The protein will be ignored. "
      NFTools.printOrangeText(msg)
    }
  }

  return fromCh
}


/*
=============================================
  Set of utilities functions 
=============================================
*/

// Function which returns elements which are present in list2
// but not in list1
def elementsNotPresent(ArrayList list1, ArrayList list2) {

  def elementsNotInList1 = list2.findAll { !list1.contains(it) }

  return elementsNotInList1
}

// Function to print the help of the tools
def printFileContent(file) {
  def inputFile = new File(file)

  if (inputFile.exists()) {
    inputFile.eachLine { line ->
      println(line)
    }
  }
  else {
    System.out.println("File not found: ${file}")
  }
}
