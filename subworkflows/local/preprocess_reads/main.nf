// preprocess reads via filtering and read class creation with bambu
include { SAMTOOLS_INDEX } from '../../../modules/nf-core/samtools/index/main' 
include { SAMTOOLS_VIEW ; SAMTOOLS_VIEW as FILTER_READS } from '../../../modules/nf-core/samtools/view/main'
include { BAMBU_READCLASSES             } from '../../../modules/local/bambu/readclasses/main'

workflow PREPROCESS_READS {
    take:
    input_bam_ch   // channel: [ val(meta), [ bam ] ]
    filter_reads     // boolean; filter reads on mapq and read length
    filter_acc_reads // boolean; filter reads on accessory chromosomes

    main:

    ch_versions = Channel.empty()
    if (filter_reads || filter_acc_reads) {
        SAMTOOLS_INDEX(input_bam_ch)
        ch_versions = ch_versions.mix(SAMTOOLS_INDEX.out.versions.first())
        bam_bai_ch = input_bam_ch.join(SAMTOOLS_INDEX.out.bai, by: 0)
    }
    if (filter_reads) {
        ch_filtered = FILTER_READS(
            bam_bai_ch ,
            [[], []],
            [],
            "bai",
        )
        ch_bam = ch_filtered.bam
        ch_versions = ch_versions.mix(FILTER_READS.out.versions.first())
    }
    else if (filter_acc_reads) {
        ch_filtered = SAMTOOLS_VIEW(
            bam_bai_ch ,
            [[], []],
            [],
            "bai",
        )
        ch_bam = ch_filtered.bam
        ch_versions = ch_versions.mix(SAMTOOLS_VIEW.out.versions.first())
    }
    else {
        ch_bam = input_bam_ch
    }
    // create read classes with bambu
    BAMBU_READCLASSES(
        ch_bam,
        params.yieldsize,
        params.fasta,
        params.gtf,
    )
    ch_versions = ch_versions.mix(BAMBU_READCLASSES.out.versions)

    emit:
    bam      = ch_bam // channel: [ val(meta), path(bam) ]
    reads    = BAMBU_READCLASSES.out.rds // channel: [ val(meta), [ rcFile ] ]
    versions = ch_versions // channel: [ versions.yml ]
}
