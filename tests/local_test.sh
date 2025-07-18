#!/bin/bash
env_nf=$HOME/miniforge3/envs/m1/env_nf
source $HOME/miniforge3/bin/activate ${env_nf}
## specify params
outdir=$HOME/Library/CloudStorage/OneDrive-MemorialSloanKetteringCancerCenter/A673/APS010.1_pg3_nf_test/results
pipelinedir=$HOME/VSCodeProjects/proteomegenerator3
samplesheet=${pipelinedir}/assets/local_samplesheet.csv
test_data=$HOME/Library/CloudStorage/OneDrive-MemorialSloanKetteringCancerCenter/A673/APS010.1_pg3_nf_test/test_data
ref_genome=${test_data}/Homo_sapiens.GRCh38.dna_sm.primary_assembly_chr9_1_1000000.fa
gtf=${test_data}/Homo_sapiens.GRCh38.91_chr9_1_1000000.gtf
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