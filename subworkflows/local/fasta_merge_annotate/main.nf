// make uniprot-style fasta for msfragger and create index tables
include { TRANSDECODER2FASTA } from '../../../modules/local/transdecoder2fasta/main.nf'
include { MERGEFUSIONS       } from '../../../modules/local/mergefusions/main.nf'

workflow FASTA_MERGE_ANNOTATE {
    take:
    ch_orfs // channel: [ val(meta), [ transdecoder_peps, gtf, swissprot_fasta ] ]
    samplesheet // samplesheet
    skip_multisample // boolean determining multi or single sample mode

    main:

    ch_versions = Channel.empty()

    // uniprot-style fasta and index table for transdecoder orfs
    TRANSDECODER2FASTA(ch_orfs)
    ch_versions = ch_versions.mix(TRANSDECODER2FASTA.out.versions.first())
    // merge fusions if multisample mode has been enabled
    if (!skip_multisample) {
        MERGEFUSIONS(samplesheet)
        ch_versions = ch_versions.mix(MERGEFUSIONS.out.versions)
    }

    emit:
    proteins    = TRANSDECODER2FASTA.out.fasta // channel: [ val(meta), [ fasta ] ]
    protein_tsv = TRANSDECODER2FASTA.out.tsv // channel: [ val(meta), [ tsv ] ]
    versions    = ch_versions // channel: [ versions.yml ]
}
