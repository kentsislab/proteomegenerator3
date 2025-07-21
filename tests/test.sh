#!/bin/bash
env_nf=$HOME/miniforge3/envs/m1/env_nf
source $HOME/miniforge3/bin/activate ${env_nf}
## specify params
outdir=$HOME/Library/CloudStorage/OneDrive-MemorialSloanKetteringCancerCenter/A673/APS010.1_pg3_nf_test/results
pipelinedir=$HOME/VSCodeProjects/proteomegenerator3
mkdir -p ${outdir}
cd ${outdir}

nextflow run ${pipelinedir}/main.nf \
    -profile arm,docker,test \
    -work-dir ${outdir}/work \
    --outdir ${outdir} \
    -resume