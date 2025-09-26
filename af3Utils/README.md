# af3Utils

**af3Utils** is a command-line tool to automatically generate input JSON files for AlphaFold3 from FASTA sequences and sample plans.

It also creates configuration files for execution via Nextflow and can generate SLURM launcher scripts.

---

## Features

- 🔍 List all available JSON files in a directory
- 🧪 Merge multiple protein sequences into a single AlphaFold3-compatible JSON
- ⚙️ Generate `params-file` configuration files for Nextflow execution
- 📤 Create SLURM job launcher scripts

---

## Usage

### List available JSON files

```bash
python -m af3Utils list ./fasta
```

### Merge proteins using a CSV sample plan

```bash
python -m af3Utils merge samplePlan.csv --seeds 1 2 3 --serverPath /work/data
```

### Generate SLURM launcher scripts

```bash
python -m af3Utils launcher --input ./inputFile --output ./slurm --serverPath /work/data
```

---

## Project Structure

```bash
af3Utils/
├── cli.py               # Argument parsing for CLI
├── createLauncher.py    # SLURM script generation
├── list.py              # Lists available JSON files
├── merge.py             # Merges and builds JSON files for AlphaFold3
├── __main__.py          # Entry point for CLI
└── __init__.py          # Package interface
```

---

## Example `samplePlan.csv` file

```csv
P53,BRCA1
TP53
```

Each line represents a group of proteins to be merged into one input file.

---

## Example output structure

```bash
inputFile/
├── P53-BRCA1/
│   ├── fasta/
│   │   └── P53-BRCA1.json
│   └── params-file/
│       └── P53-BRCA1.json
├── TP53/
│   └── ...
```

---

