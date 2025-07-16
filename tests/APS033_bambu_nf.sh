#!/bin/bash
#SBATCH --partition=cpu_short
#SBATCH --account=shahs3
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --time=1:00:00
#SBATCH --mem=20GB
#SBATCH --job-name=bambu
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=preskaa@mskcc.org
#SBATCH --output=slurm%j_bambu.out

## activate nf-core conda environment
source /home/preskaa/miniforge3/bin/activate nf-core

module load java/20.0.1
## specify params
outdir=/data1/shahs3/users/preskaa/SarcAtlas/data/APS033_ont_transcript_assembly/bambu_nf_test/preprocess_multisample_test
pipelinedir=$HOME/proteomegenerator3
samplesheet=${pipelinedir}/assets/samplesheet.csv
fasta=/data1/shahs3/isabl_data_lake/assemblies/GRCh38-P14/GRCh38.primary_assembly.genome.fa
gtf=/data1/shahs3/isabl_data_lake/assemblies/GRCh38-P14/gencode.v45.primary_assembly.annotation.gtf

mkdir -p ${outdir}
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
    -resume
