/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   ProteinFold Pipeline : custom functions 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


/*
=============================================
  Set of utilities functions 
=============================================
*/

// Function which returns elements which are present in list2
// but not in list1
def elementsNotPresent (ArrayList list1, ArrayList list2){

  def elementsNotInList1 = list2.findAll { !list1.contains(it) }

  return elementsNotInList1

}

// Function to print the help of the tools
def printFileContent(file) {
    def inputFile = new File(file)
    
    if (inputFile.exists()) {
        inputFile.eachLine { line ->
            println line
        }
    } else {
        System.out.println("File not found: $file")
    }
}
/*
=================================================
  Create channel with alphaFold models to run the
  predictions in parallel inseatd of sequential.
  This is used with afMassive
=================================================
*/

def createAfModelsCh(String alphaFoldOptions) {

  // Set variables
  List afModels
  int modelNumber = 0
  String modelsToRelaxOptions = ""
  int predNumber = 5
  int randomSeed
  Map afModelsInfo = [:]

  // This variable will store the new parameters
  String alphaFoldOptionsParallel = alphaFoldOptions

  // Multimer
  if(alphaFoldOptions.contains('model_preset=multimer')){
    afModels = []
    for (int version = 1; version < 4; version++) {
      for (int model = 1; model < 6; model++) {
        modelNumber++
        afModels.add("model_" + model + "_multimer_v" + version)
      }
    }
  }

  // Monomer
  if(!alphaFoldOptions.contains('model_preset=monomer_ptm') 
     && (alphaFoldOptions.contains('model_preset=monomer') || !alphaFoldOptions.contains('model_preset'))) {
    afModels = []
    for (int model = 1; model < 6; model++) {
      modelNumber++
      afModels.add("model_" + model)
    }
  }

  // Monomer pTM
  if(alphaFoldOptions.contains('model_preset=monomer_ptm')){
    afModels = []
    for (int model = 1; model < 6; model++) {
      modelNumber++
      afModels.add("model_" + model + "_ptm")
    }
  }

  // We can not keep the same random_seed for each prediction
  // otherwise results would be the same.
  if(alphaFoldOptions.contains('random_seed')){
    String randomSeedParams = (alphaFoldOptions =~ /--random_seed=\d+/)[0]
    alphaFoldOptionsParallel = alphaFoldOptions
                                 .replace(randomSeedParams, '')
    randomSeed = randomSeedParams
                   .replaceAll('--random_seed=', '')
                   .toInteger()
  }

  // Check what is the option for relaxation.
  // We do not want to relax all the models 
  // as we we have only one model each time
  // which will be obviously the best
  if(alphaFoldOptions.contains('models_to_relax')){
    modelsToRelaxOptions = (alphaFoldOptions =~ /--models_to_relax=\w+/)[0]
    alphaFoldOptionsParallel = alphaFoldOptionsParallel
                                 .replaceAll(modelsToRelaxOptions, '')
    alphaFoldOptionsParallel = alphaFoldOptionsParallel + "--models_to_relax=none"
  } else {
    alphaFoldOptionsParallel = alphaFoldOptionsParallel + "--models_to_relax=none"
  }
   
  // This is necessary to have a deterministic combination of model/pred with the random seed
  def afModelsList = [] 
  for (int pred_i = 1; pred_i <= predNumber; pred_i++) {
    afModels.each { 
      randomSeed = randomSeed + 1
      afModelsList.add(tuple(pred_i, it, randomSeed))
    }

  afModelsCh = Channel.fromList(afModelsList)
  
  }

  //afModelsCh = Channel.of(1..predNumber)
  //               .combine(Channel.fromList(afModels))
  //               .merge(Channel.of(1..(modelNumber*predNumber))
  //                        .map { it + randomSeed }
  //                      )

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
def createFromCh(def fromParams, fastaFilesCh) {
  File fromParamsFile = new File(params[fromParams])
  if (!fromParamsFile.exists()){
    exit 1, "The path to the folder '" + params[fromParams] + "' does not exist."
  }
  if (!fromParamsFile.isDirectory()){
    exit 1, "The path to the folder '" + params[fromParams] + "' is not a directory."
  }

  def fromCh
  def proteinInDir
  def proteinInFasta
  def proteinUnion

  fromCh = Channel.fromPath("${params[fromParams]}/*", type: 'dir')
             .map { def dir -> 
                String protein = dir.toString()
                                   .replaceAll(".*/", "")
                File proteinDir = new File("${params[fromParams]}/${protein}")
                def dirFileList = [] 
                proteinDir.eachFile {def file -> dirFileList.add(file.getAbsolutePath())}
                tuple(protein, dirFileList)
             }
 
  proteinInDir = fromCh.map { it[0]}.collect().map { tuple ('list', it) }
  proteinInFasta = fastaFilesCh.map { it[0]}.collect().map { tuple ('list', it) }
  proteinUnion = proteinInDir.join(proteinInFasta)

  // Print warning if the msas is present but not the fasta file  
  proteinUnion
    .map{
      elementsNotPresent(it[2].toList(), it[1].toList())
        .each{ def prot ->
                 String msg
                 msg = "WARNING (option ${fromParams}) - folder is present but no FASTA file available for protein '" 
                 msg = msg + prot + "'. The protein will be ignored."
                 NFTools.printOrangeText(msg)
        }
    }
    
  // Print warning if the fasta file is present but not the msas folder
  proteinUnion
    .map{
      elementsNotPresent(it[1].toList(), it[2].toList())
        .each{ def prot ->
          String msg
          msg = "WARNING (option ${fromParams}) - FASTA file is present but no folder available for protein '"
          msg = msg + prot + "'. The protein will be ignored. "
          NFTools.printOrangeText(msg)
        }
    }

    return fromCh
}

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
        exit 1, "${filePath} does not exist or is not a regular file"
    }

    // Check if the file has the extension ext
    if (ext != null) 
        if (!filePath.endsWith(ext)) {
            exit 1, "${filePath} does not have the '${ext}' extension"
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
        exit 1, "${filePath} is empty"
    }

    // Split the header line into columns
    def headerColumns = headerLine.split(',')

    // Check if all specified columns exist
    for (column in columns) {
        if (!headerColumns.contains(column.trim())) {
            exit 1, "Column '$column' not found in the CSV file ${filePath}"
        }
    }

    return true
}

// Function to check for lines with spaces or blanks in a CSV file
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
            lineCounter++
            
            // Check if the line contains a space
            if (line.contains(' ')) {
                exit 1, "Line $lineCounter contains a space in the CSV file ${filePath}"
            }
        }
    } finally {
        if (reader != null) {
            reader.close()
        }
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
        header = reader.readLine().split(',')
        println header 
        def lineCounter = 1

        // Read each line from the file
        reader.eachLine { line ->
            lineCounter++
            fields = line.split(',')
            value = [:]
            value[header[0]] = fields[0]
            value[header[1]] = fields[1]
            checkFileExistWithExt(value.protein, 'pdb')
            checkFileExistWithExt(value.ligand, 'sdf')
            
        }
    } finally {
        if (reader != null) {
            reader.close()
        }
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
