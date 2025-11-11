// make uniprot-style fasta for msfragger and create index tables
include { TRANSDECODER2FASTA } from '../../../modules/local/transdecoder2fasta/main.nf'
include { MERGEFUSIONS       } from '../../../modules/local/mergefusions/main.nf'
include { CAT_CAT            } from '../../../modules/nf-core/cat/cat/main.nf'
include { SEQKIT_RMDUP       } from '../../../modules/nf-core/seqkit/rmdup/main'
include { SEQKIT_STATS       } from '../../../modules/nf-core/seqkit/stats/main'

workflow FASTA_MERGE_ANNOTATE {
    take:
    ch_orfs // channel: [ val(meta), [ transdecoder_peps, gtf, swissprot_fasta ] ]
    samplesheet // samplesheet
    skip_multisample // boolean determining multi or single sample mode
    swissprot_fasta

    main:

    ch_versions = Channel.empty()

    // uniprot-style fasta and index table for transdecoder orfs
    TRANSDECODER2FASTA(ch_orfs)
    ch_versions = ch_versions.mix(TRANSDECODER2FASTA.out.versions.first())
    // multisample workflow with merging
    if (!skip_multisample) {
        // merge fusions if multisample mode has been enabled
        MERGEFUSIONS(samplesheet)
        ch_versions = ch_versions.mix(MERGEFUSIONS.out.versions)
        TRANSDECODER2FASTA.out.fasta.view()
        MERGEFUSIONS.out.fasta.view()
        // concatenate fusions, non-canonical proteins, and swissprot
        cat_ch = TRANSDECODER2FASTA.out.fasta
            .combine(MERGEFUSIONS.out.fasta)
            .combine(swissprot_fasta)
            .map { meta1, novel_proteins, fusions, _meta2, sp_fasta ->
                [meta1, [sp_fasta, novel_proteins, fusions]]
            }
        cat_ch.view()
        // concat fasta files
        CAT_CAT(cat_ch)
        ch_versions = ch_versions.mix(CAT_CAT.out.versions.first())
        // remove duplicates from fasta
        SEQKIT_RMDUP(CAT_CAT.out.file_out)
        ch_versions = ch_versions.mix(SEQKIT_RMDUP.out.versions.first())
        // compute some basic stats on the final proteome
        SEQKIT_STATS(SEQKIT_RMDUP.out.fastx)
        ch_versions = ch_versions.mix(SEQKIT_STATS.out.versions.first())
    }

    emit:
    predicted_orfs = TRANSDECODER2FASTA.out.fasta // channel: [ val(meta), [ fasta ] ]
    orf_tsv        = TRANSDECODER2FASTA.out.tsv // channel: [ val(meta), [ tsv ] ]
    proteome_fasta = SEQKIT_RMDUP.out.fastx // channel: [ val(meta), [fasta]]
    versions       = ch_versions // channel: [ versions.yml ]
}
