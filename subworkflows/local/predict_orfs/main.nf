// predict ORFs with transdecoder & output fasta for msfragger
include { TRANSDECODER_LONGORF } from '../../../modules/nf-core/transdecoder/longorf/main'
include { TRANSDECODER_PREDICT } from '../../../modules/nf-core/transdecoder/predict/main'
workflow PREDICT_ORFS {
    take:
    orf_ch  // channel: [ val(meta), fasta, fusion_table ]
    fusions // boolean: whether to predict ORFs for fusions

    main:

    ch_versions = Channel.empty()

    // TODO nf-core: substitute modules here for the modules of your subworkflow
    fasta_ch = orf_ch.map { meta, fasta, fusion_table -> tuple(meta, fasta) }
    TRANSDECODER_LONGORF(fasta_ch)
    ch_versions = ch_versions.mix(TRANSDECODER_LONGORF.out.versions)
    TRANSDECODER_PREDICT(fasta_ch, TRANSDECODER_LONGORF.out.folder)
    ch_versions = ch_versions.mix(TRANSDECODER_PREDICT.out.versions)

    emit:
    pep      = TRANSDECODER_LONGORF.out.pep // channel: [ val(meta), fasta ]
    versions = ch_versions // channel: [ versions.yml ]
}
