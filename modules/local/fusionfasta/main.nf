// write fusion fasta in single sample mode
process FUSIONFASTA {
    tag "${meta.id}"
    label 'process_single'
    publishDir "${params.outdir}/proteome", mode: 'copy'

    // TODO nf-core: See section in main README for further information regarding finding and adding container addresses to the section below.
    conda "${moduleDir}/environment.yml"
    container "quay.io/shahlab_singularity/biopython:v250501"

    input:
    tuple val(meta), path(lrfusion_tsv)

    output:
    // TODO nf-core: Named file extensions MUST be emitted for ALL output channels
    tuple val(meta), path("*.predicted_fusion_orf_info.tsv"), emit: tsv
    tuple val(meta), path("*.predicted_fusion_orfs.fasta"), emit: fasta
    // TODO nf-core: List additional required output channels/values here
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    fusion_fasta.py \\
        ${lrfusion_tsv} \\
        ${prefix}.predicted_fusion_orf_info.tsv \\
        ${prefix}.predicted_fusion_orfs.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        pandas: \$(python -c "import pandas; print(pandas.__version__)")
        numpy: \$(python -c "import numpy; print(numpy.__version__)")
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo ${args}
    touch ${prefix}.predicted_fusion_orf_info.tsv
    touch ${prefix}.predicted_fusion_orfs.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        pandas: \$(python -c "import pandas; print(pandas.__version__)")
        numpy: \$(python -c "import numpy; print(numpy.__version__)")
    END_VERSIONS
    """
}
