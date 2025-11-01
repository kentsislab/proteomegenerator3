# kentsislab/proteomegenerator3: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-01

First stable release of kentsislab/proteomegenerator3.

### Changed

- Updated README.md with version 1.0.0 and biorxiv citation.

## [1.0.0dev] - 2025-07-23

Initial release of kentsislab/proteomegenerator3, created with the [nf-core](https://nf-co.re/) template.

### `Added`

- Transcript assembly & quant with bambu
- Flags to pre-filter reads before assembly on read length & mapq (useful for samples with inadequate QC)
- Flags to pre-filter reads on accessory chromosomes (can sometimes cause issues for Bambu)
- Flag to adjust NDR in bambu
- ORF prediction for transcripts & fusions using TransDecoder
- reformatting of fasta for use with MSFragger, DIA-NN, and Spectronaut
- nf-test and test datasets
- updated README.md
