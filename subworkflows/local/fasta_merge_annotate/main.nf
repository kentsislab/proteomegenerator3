// make uniprot-style fasta for msfragger and create index tables
include { TRANSDECODER2FASTA } from '../../../modules/local/transdecoder2fasta/main.nf'

workflow FASTA_MERGE_ANNOTATE {
    take:
    ch_orfs // channel: [ val(meta), [ transdecoder_peps, gtf, swissprot_fasta ] ]

    main:

    ch_versions = Channel.empty()

    // uniprot-style fasta and index table for transdecoder orfs
    TRANSDECODER2FASTA(ch_orfs)
    ch_versions = ch_versions.mix(TRANSDECODER2FASTA.out.versions.first())

    emit:
    proteins    = TRANSDECODER2FASTA.out.fasta // channel: [ val(meta), [ fasta ] ]
    protein_tsv = TRANSDECODER2FASTA.out.tsv // channel: [ val(meta), [ tsv ] ]
    versions    = ch_versions // channel: [ versions.yml ]
}
