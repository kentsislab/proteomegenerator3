// transcript assembly with bambu
// NOTE: be warying of errant spaces in the script section! optparse will be unhappy
process BAMBU_ASSEMBLY {
    tag "${meta.id}_NDR_${meta.NDR}"
    label 'process_high_memory'

    conda "${moduleDir}/environment.yml"
    container "quay.io/shahlab_singularity/bambu:3.10.0beta"

    input:
    tuple val(meta), path(rds, arity: '1..*'), path(ref_gtf, stageAs: 'reference.gtf')
    val yieldsize
    path ref_genome

    output:
    tuple val(meta), path("se.RData"), emit: se
    tuple val(meta), path("extended_annotations.gtf"), optional: true, emit: gtf
    tuple val(meta), path("counts_gene.txt"), optional: true, emit: gene_counts
    tuple val(meta), path("counts_transcript.txt"), optional: true, emit: transcript_counts
    tuple val(meta), path("CPM_transcript.txt"), optional: true, emit: transcript_cpms
    tuple val(meta), path("fullLengthCounts_transcript.txt"), optional: true, emit: full_len_counts
    tuple val(meta), path("uniqueCounts_transcript.txt"), optional: true, emit: unique_counts
    tuple val(meta), path("bambu_assembly.log"), emit: log
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def NDR_args = meta.NDR == "DEFAULT" ? "" : "--NDR=${meta.NDR}"
    def prefix = task.ext.prefix ?: "${meta.id}"
    def args = task.ext.args ?: ''
    def rds_list = rds.join(',')
    def yieldSize = task.ext.yieldsize ?: yieldsize
    """
    transcript_assembly.R \\
        --rds=${rds_list} \\
        --yieldsize=${yieldSize} \\
        --ref_genome=${ref_genome} \\
        --ref_gtf=reference.gtf \\
        --ncore=${task.cpus} \\
        ${NDR_args} \\
        ${args} 2>&1 | tee bambu_assembly.log
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(echo \$(R --version 2>&1) | sed 's/^.*R version //; s/ .*\$//')
        bambu: \$(Rscript -e "library(bambu); cat(as.character(packageVersion('bambu')))")
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // TODO nf-core: A stub section should mimic the execution of the original module as best as possible
    //               Have a look at the following examples:
    //               Simple example: https://github.com/nf-core/modules/blob/818474a292b4860ae8ff88e149fbcda68814114d/modules/nf-core/bcftools/annotate/main.nf#L47-L63
    //               Complex example: https://github.com/nf-core/modules/blob/818474a292b4860ae8ff88e149fbcda68814114d/modules/nf-core/bedtools/split/main.nf#L38-L54
    """
    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bambu: \$(samtools --version |& sed '1!d ; s/samtools //')
    END_VERSIONS
    """
}
