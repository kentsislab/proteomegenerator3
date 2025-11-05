// predict ORFs with transdecoder & output fasta for msfragger
include { PHILOSOPHER_DATABASE } from '../../../modules/local/philosopher/database/main'
include { DIAMOND_MAKEDB       } from '../../../modules/nf-core/diamond/makedb/main'
include { DIAMOND_BLASTP       } from '../../../modules/nf-core/diamond/blastp/main'
include { TRANSDECODER_LONGORF } from '../../../modules/nf-core/transdecoder/longorf/main'
include { TRANSDECODER_PREDICT } from '../../../modules/local/transdecoder/predict/main'
include { WRITEFASTA           } from '../../../modules/local/writefasta/main'
workflow PREDICT_ORFS {
    take:
    orf_ch // channel: [ val(meta), fasta, fusion_table ]
    fusions // boolean: whether to predict ORFs for fusions
    blast_db // path to diamond blast database if it already exists

    main:

    ch_versions = Channel.empty()
    // prepare diamond database for diamond blast
    if (!blast_db) {
        PHILOSOPHER_DATABASE([id: params.uniprot_proteome], params.reviewed, params.isoforms)
        blast_fasta = PHILOSOPHER_DATABASE.out.fasta
        ch_versions = ch_versions.mix(PHILOSOPHER_DATABASE.out.versions)
    }
    else {
        blast_fasta = [[id: 'db_prep'], blast_db]
    }
    // make diamond database
    DIAMOND_MAKEDB(blast_fasta, [], [], [])
    ch_versions = ch_versions.mix(DIAMOND_MAKEDB.out.versions)
    // prepare input for transdecoder
    fasta_ch = orf_ch.map { meta, fasta, _fusion_table -> tuple(meta, fasta) }
    TRANSDECODER_LONGORF(fasta_ch)
    ch_versions = ch_versions.mix(TRANSDECODER_LONGORF.out.versions)
    // blast orfs against database
    DIAMOND_BLASTP(
        TRANSDECODER_LONGORF.out.pep,
        DIAMOND_MAKEDB.out.db,
        6,
        [],
    )
    ch_versions = ch_versions.mix(DIAMOND_BLASTP.out.versions)
    // join the fasta channel with blast results
    input_predict_ch = fasta_ch.join(DIAMOND_BLASTP.out.txt)
    input_predict_ch.view()
    TRANSDECODER_PREDICT(input_predict_ch, TRANSDECODER_LONGORF.out.folder)
    ch_versions = ch_versions.mix(TRANSDECODER_PREDICT.out.versions)
    fusion_ch = orf_ch.map { meta, fasta, fusion_table -> tuple(meta, fusion_table) }
    protein_ch = TRANSDECODER_PREDICT.out.pep.join(fusion_ch)
    protein_ch.view()
    WRITEFASTA(protein_ch)
    ch_versions = ch_versions.mix(WRITEFASTA.out.versions)

    emit:
    proteins = WRITEFASTA.out.fasta // channel: [ val(meta), fasta ]
    versions = ch_versions // channel: [ versions.yml ]
}
