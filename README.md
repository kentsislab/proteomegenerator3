# kentsislab/proteomegenerator3

[![GitHub Actions CI Status](https://github.com/shahcompbio/proteomegenerator3/actions/workflows/ci.yml/badge.svg)](https://github.com/shahcompbio/proteomegenerator3/actions/workflows/ci.yml)
[![GitHub Actions Linting Status](https://github.com/shahcompbio/proteomegenerator3/actions/workflows/linting.yml/badge.svg)](https://github.com/shahcompbio/proteomegenerator3/actions/workflows/linting.yml)[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)
[![nf-test](https://img.shields.io/badge/unit_tests-nf--test-337ab7.svg)](https://www.nf-test.com)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A524.04.2-23aa62.svg)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

## Introduction

**kentsislab/proteomegenerator3** is a bioinformatics pipeline that can be used to create sample-specific, proteogenomics search databases from long-read RNAseq data. It takes in a samplesheet and aligned long-read RNAseq data as input, performs guided, de novo transcript assembly, ORF prediction, and then produces a protein fasta file suitable for use with computational proteomics search platforms (e.g, Fragpipe, DIA-NN).

<!-- TODO nf-core:
   Complete this sentence with a 2-3 sentence summary of what types of data the pipeline ingests, a brief overview of the
   major pipeline sections and the types of output it produces. You're giving an overview to someone new
   to nf-core here, in 15-20 seconds. For an example, see https://github.com/nf-core/rnaseq/blob/master/README.md#introduction
-->

<!-- TODO nf-core: Include a figure that guides the user through the major workflow steps. Many nf-core
     workflows use the "tube map" design for that. See https://nf-co.re/docs/contributing/design_guidelines#examples for examples.   -->
<!-- TODO nf-core: Fill in short bullet-pointed list of the default steps in the pipeline -->

1. Pre-processing of aligned reads to create transcript read classes with [bambu](https://github.com/GoekeLab/bambu) which can be re-used in future analyses. Optional filtering:
   1. Filtering on MAPQ and read length with [samtools](https://www.htslib.org/)
2. Transcript assembly, quantification, and filtering with [bambu](https://github.com/GoekeLab/bambu). Option to merge multiple samples into a unified transcriptome.
3. ORF prediction with [Transdecoder](https://github.com/TransDecoder/TransDecoder). Option to provide fusion contigs from [JAFFAL](https://github.com/Oshlack/JAFFA).
4. Formatting of ORFs into a fasta file which can be used for computational proteomics searchs with [Fragpipe](https://fragpipe.nesvilab.org/), [DIA-NN](https://github.com/vdemichev/DiaNN), [Spectronaut](https://biognosys.com/software/spectronaut/).
5. MultiQC to collate package versions used ([`MultiQC`](http://multiqc.info/))

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data. When using the profile, it will run on a minimal test dataset that can be run in 5-10 minutes on most modern laptops.

First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv
sample,bam,bai,rcFile,jaffal_fasta,jaffal_table
CONTROL_REP1,AEG588A1_S1_L002_R1_001.bam,AEG588A1_S1_L002_R1_001.bam.bai,,jaffal_results.fasta,jaffal_results.csv
```

Each row represents a long-read RNAseq sample. The columns are as follows:

1. `sample`: name of the sample
2. `bam`: aligned, sorted long-read RNAseq bam
3. `bai`: index file for bam
4. `rcFile`: read class file from Bambu if you've already done some pre-processing; you can provide this and then use the `--skip_preprocessing` flag to speed up run time and re-analyze previous samples
5. `jaffal_fasta`: Fusion contigs which are output from JAFFAL (see description [here](https://github.com/Oshlack/JAFFA/wiki/OutputDescription#jaffa_resultsfasta-file)).
6. `jaffal_table`: Fusion table which is output from JAFFAL (see description [here](https://github.com/Oshlack/JAFFA/wiki/OutputDescription#jaffa_resultscsv))

To produce the necessary files, we recommend using the [nf-core/nanoseq](https://nf-co.re/nanoseq/3.1.0/) pipeline, which will run both alignment and call fusions with JAFFAL.

Now, you can run the pipeline using:

<!-- TODO nf-core: update the following command to include all required parameters for a minimal example -->

```bash
nextflow run kentsislab/proteomegenerator3 \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --fasta <REF_GENOME> \
   --gtf <REF_GTF> \
   --outdir <OUTDIR>
```

Where `REF_GENOME` and `REF_GTF` are the reference genome and transcriptome respectively. These can be from GENCODE or Ensembl, but should match the reference used to align the data.

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_; see [docs](https://nf-co.re/docs/usage/getting_started/configuration#custom-configuration-files).

### Additional parameters

To see all optional parameters that could be used with the pipeline and their explanations, use the help menu:

```bash
nextflow run kentsislab/proteomegenerator3 --help
```

This options can be run using flags. For example:

```bash
nextflow run kentsislab/proteomegenerator3 \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --fasta <REF_GENOME> \
   --gtf <REF_GTF> \
   --outdir <OUTDIR> \
   --filter_reads
```

Will pre-filter the bam file before transcript assembly is performed on mapq and read length.

As another example, you can use the following flag to perform ORF calling on fusion contigs:

```bash
nextflow run kentsislab/proteomegenerator3 \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --fasta <REF_GENOME> \
   --gtf <REF_GTF> \
   --outdir <OUTDIR> \
   --fusions
```

I have highlighted the following options here:

1. `filter_reads`: use this flag to pre-filter reads using mapq and read length
2. `mapq`: min mapq for read filtering [default: 20]
3. `read_len`: min read length for read filtering [default: 500]
4. `filter_acc_reads`: filter reads on accessory chromosomes; sometimes causes issues for bambu
5. `skip_preprocessing`: use previously generated bambu read classes
6. `NDR`: modulate bambu's novel discovery rate [default: 0.1]
7. `recommended_NDR`: run bambu with recommended NDR (as determined by bambu's algorithm)
8. `single_sample`: Run bambu on samples individually, and skip merging of transcriptomes; if you provide a single sample or fusions, this will be automatically run.
9. `skip_multisample`: skip multisample transcript assembly (see #8).
10. `fusions`: Perform ORF predictions on fusions from JAFFAL [default: false]
11. `multiple_orfs`: Allow for multiple ORFs per transcript (this is in beta-testing)

## Credits

kentsislab/proteomegenerator3 was originally written by Asher Preska Steinberg.

We thank the following people for their extensive assistance in the development of this pipeline:

<!-- TODO nf-core: If applicable, make list of people who have also contributed -->

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use kentsislab/proteomegenerator3 for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->

If you use kentsislab/proteomegenerator3 for your analysis, please cite it our manuscript:

> **End-to-end proteogenomics for discovery of cryptic and non-canonical cancer proteoforms using long-read transcriptomics and multi-dimensional proteomics**
>
> Katarzyna Kulej, Asher Preska Steinberg, Jinxin Zhang, Gabriella Casalena, Eli Havasov, Sohrab P. Shah, Andrew McPherson, Alex Kentsis.
>
> _BioRXiv._ 2025 XX XX. doi: [XXXX](XXXX).

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/main/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
