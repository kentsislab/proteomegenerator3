# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**proteomegenerator3** is a Nextflow bioinformatics pipeline for creating sample-specific proteogenomics search databases from long-read RNA-seq data. The pipeline performs guided and de novo transcript assembly, ORF prediction, and produces protein FASTA files for use with proteomics search platforms (Fragpipe, DIA-NN, Spectronaut).

### Key Technologies

- **Nextflow DSL2** (version ≥24.04.2)
- **nf-schema plugin** (v2.2.0) for parameter validation
- **nf-test** for testing
- Primary tools: Bambu (transcript assembly), Transdecoder (ORF prediction), GFFREAD (cDNA extraction)

## Essential Commands

### Running the Pipeline

Basic execution:

```bash
nextflow run kentsislab/proteomegenerator3 -r 1.0.0 \
  -profile <docker/singularity/.../institute> \
  --input samplesheet.csv \
  --fasta <REF_GENOME> \
  --gtf <REF_GTF> \
  --outdir <OUTDIR>
```

Run with test data:

```bash
nextflow run . -profile test,docker
```

Run with latest development version:

```bash
nextflow run kentsislab/proteomegenerator3 -r main -latest --help
```

### Testing

Run nf-test suite:

```bash
nf-test test
```

Run specific test:

```bash
nf-test test tests/main.nf.test
```

### Development

Update cached pipeline:

```bash
nextflow pull kentsislab/proteomegenerator3
```

Run with resume (use cached results):

```bash
nextflow run . -profile docker -resume
```

## Architecture

### Pipeline Flow

1. **main.nf**: Entry point that orchestrates the workflow

   - Imports `PROTEOMEGENERATOR3` workflow from `workflows/proteomegenerator3.nf`
   - Handles pipeline initialization and completion via utility subworkflows
   - Manages genome parameter values from igenomes.config

2. **workflows/proteomegenerator3.nf**: Main workflow logic

   - **PREPROCESS_READS**: Filters BAM files by MAPQ/read length, removes accessory chromosome reads
   - **ASSEMBLY_QUANT**: Runs Bambu for transcript assembly and quantification
   - **GFFREAD**: Extracts cDNA sequences from assembled transcripts
   - **CAT_CAT**: Concatenates transcript and fusion FASTA files (when fusions enabled)
   - **PREDICT_ORFS**: Predicts ORFs using Transdecoder
   - **MULTIQC**: Generates quality control report

3. **Subworkflows** (in `subworkflows/local/`):

   - `preprocess_reads/`: Read filtering and quality control
   - `assembly_quant/`: Transcript assembly with Bambu
   - `predict_orfs/`: ORF prediction with Transdecoder and FASTA formatting

4. **Python Scripts** (in `bin/`):
   - `write_fasta.py`: Formats Transdecoder peptides into proteomics-ready FASTA
     - Distinguishes canonical (ENST), novel (Bambu), and fusion (GF) proteins
     - Filters for complete ORFs only
     - Assigns protein evidence levels (PE=1 for canonical, PE=2 for novel/fusion)

### Key Design Patterns

**Sample Mode Selection**: Pipeline automatically switches to single-sample mode when:

- Only one sample provided in samplesheet
- Fusion analysis enabled (`--fusions`)
- User explicitly sets `--single_sample`

**NDR (Novel Discovery Rate) Handling**:

- Can use fixed NDR value (`--NDR 0.1`)
- Can use Bambu's recommended NDR (`--recommended_NDR`)
- Can run both modes if both flags provided
- NDR value is added to sample metadata for tracking

**Channel Pattern for Fusions**:
When `--fusions` is enabled, the workflow:

1. Extracts fusion FASTA and table from samplesheet
2. Combines with NDR channel to create all NDR/fusion combinations
3. Joins fusion table with ORF predictions for downstream filtering
4. Concatenates transcript and fusion FASTAs before ORF prediction

**Read Class Caching**:

- Bambu generates "read classes" during preprocessing (expensive operation)
- Can be cached and reused via `rcFile` column in samplesheet
- Use `--skip_preprocessing` to skip read class generation and use cached files

## Configuration

### Profiles

- `test`: Runs on minimal test dataset (conf/test_single_sample.config)
- `test_full`: Full test dataset (conf/test_full.config)
- `docker`: Docker containerization with resource limits (28GB memory, 12h time)
- `singularity`, `podman`, `apptainer`: Alternative container engines
- `slurm`: SLURM cluster execution (queue: componc_cpu)
- `desperation`: Local execution with high resources (20 CPUs, 400GB memory)

### Important Parameters

**Read Filtering**:

- `--filter_reads`: Enable pre-filtering (default: false)
- `--mapq`: Minimum MAPQ score (default: 20)
- `--read_len`: Minimum read length (default: 500)
- `--filter_acc_reads`: Filter accessory chromosomes (default: false)

**Bambu Assembly**:

- `--NDR`: Novel discovery rate (default: 0.1)
- `--yieldsize`: Reads to process at once for memory management (default: 100000)
- `--skip_multisample`: Skip multi-sample transcript merging

**ORF Prediction**:

- `--fusions`: Include fusion contigs from JAFFAL (default: false)
- `--multiple_orfs`: Allow multiple ORFs per transcript (beta, default: false)

## Input Format

Samplesheet CSV with columns:

- `sample`: Sample name
- `bam`: Aligned, sorted long-read RNA-seq BAM
- `bai`: BAM index file
- `rcFile`: Optional pre-computed Bambu read class file
- `jaffal_fasta`: Optional fusion contigs from JAFFAL
- `jaffal_table`: Optional fusion metadata from JAFFAL

## Output Structure

Results in `<OUTDIR>/`:

- `bambu/`: Transcript assembly GTFs and quantification
- `transdecoder/`: ORF predictions
- `proteins.fasta`: Final proteomics search database
- `fusion_stats.csv`: Fusion ORF statistics (if `--fusions` enabled)
- `multiqc_report.html`: Quality control report
- `pipeline_info/`: Execution reports, timeline, trace, DAG

## Testing Strategy

- Tests located in `tests/` and `subworkflows/local/*/tests/`
- Uses nf-test framework with nft-utils plugin
- Test configuration: `tests/nextflow.config`
- Tests run with `test` profile by default
- Test data sourced from: `https://raw.githubusercontent.com/apsteinberg/test-datasets/`

## Citation

When working with this pipeline, note it should be cited as:

> Kulej et al. (2025) End-to-end proteogenomics for discovery of cryptic and non-canonical cancer proteoforms using long-read transcriptomics and multi-dimensional proteomics. BioRxiv. doi: 10.1101/2025.08.23.671943
