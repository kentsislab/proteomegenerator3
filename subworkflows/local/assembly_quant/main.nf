// transcript assembly and quantification with bambu

include { BAMBU_ASSEMBLY as BAMBU             } from '../../../modules/local/bambu/assembly/main'
include { BAMBU_ASSEMBLY as BAMBU_MERGE       } from '../../../modules/local/bambu/assembly/main'
include { BAMBU_ASSEMBLY as BAMBU_MERGE_QUANT } from '../../../modules/local/bambu/assembly/main'
include { BAMBU_ASSEMBLY as BAMBU_QUANT       } from '../../../modules/local/bambu/assembly/main'
include { SEMERGE                             } from '../../../modules/local/semerge/main'
include { SEMERGE as SEQUANT_MERGE            } from '../../../modules/local/semerge/main'
include { BAMBU_FILTER                        } from '../../../modules/local/bambu/filter/main'

workflow ASSEMBLY_QUANT {
    take:
    rc_ch         // channel: [val(meta), reads]
    single_sample // val
    sample_count  // val
    ch_NDR        // channel []
    ref_gtf_ch
    bam_ch        // channel: [ val(meta), [ bam ] ]

    main:

    ch_versions = Channel.empty()
    single_se_ch = Channel.empty()
    merge_se_ch = Channel.empty()


    // add NDR to metamap
    def NDRmetamap = { meta, rds, NDR ->
        def new_meta = meta.clone()
        new_meta.NDR = NDR
        return [new_meta, rds]
    }

    if (single_sample || sample_count == 1) {
        // combine read classes and NDR channels
        bambu_input_ch = rc_ch
            .combine(ch_NDR)
            .map(NDRmetamap)
            .combine(ref_gtf_ch)
        BAMBU(bambu_input_ch, params.yieldsize, params.fasta)
        single_se_ch = BAMBU.out.se
        ch_versions = ch_versions.mix(BAMBU.out.versions)
    }
    else {
        // run multisample mode; assembly then quant
        merge_ch = rc_ch
            .collect { meta, rds -> rds }
            .map { rds -> [["id": "merge"], rds] }
        merge_input_ch = merge_ch
            .combine(ch_NDR)
            .map(NDRmetamap)
            .combine(ref_gtf_ch)
        // merge_input_ch.view()
        BAMBU_MERGE(merge_input_ch, params.yieldsize, params.fasta)
        ch_versions = ch_versions.mix(BAMBU_MERGE.out.versions)
        // run bambu in quantification mode with merged gtf
        merge_quant_ch = bam_ch
            .combine(BAMBU_MERGE.out.gtf)
            .map { meta1, bam, meta2, ext_gtf ->
                def meta = meta1.clone()
                meta.NDR = meta2.NDR
                return [meta, bam, ext_gtf]
            }
        // merge_quant_ch.view()
        BAMBU_MERGE_QUANT(merge_quant_ch, params.yieldsize, params.fasta)
        ch_versions = ch_versions.mix(BAMBU_MERGE_QUANT.out.versions)
        // collect all summarized experiments for each NDR
        se_ch = BAMBU_MERGE_QUANT.out.se
            .map { meta, se ->
                def fmeta = meta.clone()
                fmeta.id = "merge"
                return [fmeta, se]
            }
            .groupTuple(by: 0)
        SEMERGE(se_ch)
        merge_se_ch = SEMERGE.out.se
        ch_versions = ch_versions.mix(SEMERGE.out.versions)
    }
    // filter for detected transcripts
    all_se_ch = merge_se_ch.mix(single_se_ch)
    BAMBU_FILTER(all_se_ch)
    ch_versions = ch_versions.mix(BAMBU_FILTER.out.versions)

    emit:
    gtf      = BAMBU_FILTER.out.gtf // channel: [ val(meta), [ gtf ] ]
    versions = ch_versions // channel: [ versions.yml ]
}
