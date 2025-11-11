#!/bin/bash
env_nf=$HOME/miniforge3/envs/m1/env_nf
source $HOME/miniforge3/bin/activate ${env_nf}
## specify params
outdir=/data1/shahs3/users/preskaa/A673/data/pg3_1.0.1dev_nf_test/results
pipelinedir=$HOME/proteomegenerator3
mkdir -p ${outdir}
cd ${outdir}

nextflow run ${pipelinedir}/main.nf \
    -profile test,singularity \
    -work-dir ${outdir}/work \
    --outdir ${outdir} \
    -resume