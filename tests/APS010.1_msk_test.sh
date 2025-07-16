#!/bin/bash
## activate nf-core conda environment
source $HOME/miniforge_x86_64/bin/activate nf-core
## specify params
outdir=$HOME/Library/CloudStorage/OneDrive-MemorialSloanKetteringCancerCenter/A673/APS010.1_pg3_nf_test/results
pipelinedir=$HOME/VSCodeProjects/proteomegenerator3
samplesheet=${pipelinedir}/assets/msk_samplesheet.csv
ref_genome=$HOME/Library/CloudStorage/OneDrive-MemorialSloanKetteringCancerCenter/code/ref_genomes/hg38p14/GRCh38.primary_assembly.genome.fa
gtf=$HOME/Library/CloudStorage/OneDrive-MemorialSloanKetteringCancerCenter/code/ref_genomes/hg38p14/gencode.v45.primary_assembly.annotation.gtf
mkdir -p ${outdir}
cd ${outdir}

nextflow run ${pipelinedir}/main.nf \
    -profile arm,docker \
    -work-dir ${outdir}/work \
    --outdir ${outdir} \
    --input ${samplesheet} \
    --gtf ${gtf} \
    --fasta ${ref_genome} \
    -resume