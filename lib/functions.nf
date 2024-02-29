// ProteinFold Pipeline : custom functions 

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

// Function to check for lines with spaces or blanks in a CSV file
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


