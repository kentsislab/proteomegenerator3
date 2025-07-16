#!/bin/bash
#SBATCH --partition=componc_cpu
#SBATCH --account=shahs3
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --time=12:00:00
#SBATCH --mem=8GB
#SBATCH --job-name=bambu
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=preskaa@mskcc.org
#SBATCH --output=slurm%j_3x3.out

## activate nf-core conda environment
source /home/preskaa/miniforge3/bin/activate nf-core

module load java/20.0.1
## specify params
outdir=/data1/shahs3/users/preskaa/SarcAtlas/data/APS033_ont_transcript_assembly/3x3_bambu_merge_test
results_dir=${outdir}/results
pipelinedir=$HOME/proteomegenerator3
samplesheet=${outdir}/3x3_samplesheet.csv
fasta=/data1/shahs3/isabl_data_lake/assemblies/GRCh38-P14/GRCh38.primary_assembly.genome.fa
gtf=/data1/shahs3/isabl_data_lake/assemblies/GRCh38-P14/gencode.v45.primary_assembly.annotation.gtf

mkdir -p ${results_dir}
cd ${outdir}

# export NXF_SINGULARITY_OPTS="--bind /data1/shahs3:/data1/shahs3"

nextflow run ${pipelinedir}/main.nf \
    -profile singularity,test \
    -work-dir ${outdir}/work \
    --outdir ${outdir} \
    --input ${samplesheet} \
    --fasta ${fasta} \
    --gtf ${gtf} \
    --NDR=0.1 \
    --multisample_quant \
    --skip_preprocessing \
    -resume
