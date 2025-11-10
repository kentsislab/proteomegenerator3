// write fasta compatible with msfragger, diann, spectronaut
process TRANSDECODER2FASTA {
    tag "${meta.id}"
    label 'process_single'
    publishDir "${params.outdir}/proteome/${meta.id}", mode: 'copy', overwrite: true

    // TODO nf-core: See section in main README for further information regarding finding and adding container addresses to the section below.
    conda "${moduleDir}/environment.yml"
    container "quay.io/preskaa/biopython:v240911"

    input:
    tuple val(meta), path(peps), path(gtf), path(swissprot)

    output:
    // TODO nf-core: Named file extensions MUST be emitted for ALL output channels
    tuple val(meta), path("*proteins.fasta"), emit: fasta
    tuple val(meta), path("*protein_transcript_info.tsv"), optional: true, emit: fusion_stats
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    transdecoder2fasta.py \\
        ${peps} \\
        ${gtf} \\
        ${swissprot} \\
        ${prefix}.proteins.fasta \\
        ${prefix}.protein_transcript_info.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        pandas: \$(python -c "import pandas; print(pandas.__version__)")
        numpy: \$(python -c "import numpy; print(numpy.__version__)")
        biopython: \$(python -c "import Bio; print(Bio.__version__)")
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
        writefasta: \$(writefasta --version)
    END_VERSIONS
    """
}
