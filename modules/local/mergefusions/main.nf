// merge fusions from ctat-lr-fusion across multiple samples
process MERGEFUSIONS {
    tag '$samplesheet'
    label 'process_single'
    publishDir "${params.outdir}/proteome", mode: 'copy'

    conda "${moduleDir}/environment.yml"
    container "quay.io/shahlab_singularity/biopython:v250501"

    input:
    path samplesheet

    output:
    path "merge.predicted_fusion_orf_info.tsv", emit: tsv
    path "merge.predicted_fusion_orfs.fasta", emit: fasta
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    merge_fusions.py \\
        ${samplesheet} \\
        merge.predicted_fusion_orf_info.tsv\\
        merge.predicted_fusion_orfs.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        pandas: \$(python -c "import pandas; print(pandas.__version__)")
        numpy: \$(python -c "import numpy; print(numpy.__version__)")
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''

    // TODO nf-core: A stub section should mimic the execution of the original module as best as possible
    //               Have a look at the following examples:
    //               Simple example: https://github.com/nf-core/modules/blob/818474a292b4860ae8ff88e149fbcda68814114d/modules/nf-core/bcftools/annotate/main.nf#L47-L63
    //               Complex example: https://github.com/nf-core/modules/blob/818474a292b4860ae8ff88e149fbcda68814114d/modules/nf-core/bedtools/split/main.nf#L38-L54
    // TODO nf-core: If the module doesn't use arguments ($args), you SHOULD remove:
    //               - The definition of args `def args = task.ext.args ?: ''` above.
    //               - The use of the variable in the script `echo $args ` below.
    """
    echo ${args}
    
    touch fusion_summary.tsv
    touch fusion_proteins.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mergefusions: \$(mergefusions --version)
    END_VERSIONS
    """
}
