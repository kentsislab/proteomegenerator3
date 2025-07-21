/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { PREPROCESS_READS                    } from '../subworkflows/local/preprocess_reads/main'
include { ASSEMBLY_QUANT                      } from '../subworkflows/local/assembly_quant/main'
include { BAMBU_ASSEMBLY as BAMBU             } from '../modules/local/bambu/assembly/main'
include { BAMBU_ASSEMBLY as BAMBU_MERGE       } from '../modules/local/bambu/assembly/main'
include { BAMBU_ASSEMBLY as BAMBU_MERGE_QUANT } from '../modules/local/bambu/assembly/main'
include { BAMBU_ASSEMBLY as BAMBU_QUANT       } from '../modules/local/bambu/assembly/main'
include { SEMERGE                             } from '../modules/local/semerge/main'
include { SEMERGE as SEQUANT_MERGE            } from '../modules/local/semerge/main'
include { BAMBU_FILTER                        } from '../modules/local/bambu/filter/main'
include { MULTIQC                             } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap                    } from 'plugin/nf-schema'
include { paramsSummaryMultiqc                } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML              } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText              } from '../subworkflows/local/utils_nfcore_proteomegenerator3_pipeline'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PROTEOMEGENERATOR3 {
    take:
    ch_samplesheet // channel: samplesheet read in from --input

    main:
    // begin workflow
    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()
    //
    // MODULE: Run samtools view to filter bam files for reads aligned to accessory chromosomes
    //
    if (!params.skip_preprocessing) {
        input_ch = ch_samplesheet.map { meta, bam, bai, rds -> tuple(meta, bam, bai) }
        PREPROCESS_READS(input_ch, params.filter_reads, params.filter_acc_reads)
        rc_ch = PREPROCESS_READS.out.reads
        bam_ch = PREPROCESS_READS.out.bam
        ch_versions = ch_versions.mix(PREPROCESS_READS.out.versions)
    }
    else {
        rc_ch = ch_samplesheet.map { meta, bam, bai, rds -> tuple(meta, rds) }
        bam_ch = ch_samplesheet.map { meta, bam, bai, rds -> tuple(meta, bam) }
    }
    // perform assembly & quantification with bambu
    // make an NDR channel
    if (params.recommended_NDR && params.NDR != null) {
        ch_NDR = channel.of("DEFAULT", params.NDR)
    }
    else if (params.recommended_NDR) {
        ch_NDR = channel.of("DEFAULT")
    }
    else {
        ch_NDR = channel.of(params.NDR)
    }
    // add NDR to metamap
    def NDRmetamap = { meta, rds, NDR ->
        def new_meta = meta.clone()
        new_meta.NDR = NDR
        return [new_meta, rds]
    }
    ref_gtf_ch = channel.of(params.gtf)
    // run sample assembly & quant with read classes
    // count samples to make sure multisample isn't run on single samples
    sample_count = countSamples(params.input)
    // run assembly and quant with bambu
    ASSEMBLY_QUANT(
        rc_ch,
        params.single_sample,
        sample_count,
        ch_NDR,
        ref_gtf_ch,
        bam_ch,
    )
    ch_versions = ch_versions.mix(ASSEMBLY_QUANT.out.versions)

    // collect versions
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'proteomegenerator3_software_' + 'mqc_' + 'versions.yml',
            sort: true,
            newLine: true,
        )
        .set { ch_collated_versions }


    //
    // MODULE: MultiQC
    //
    ch_multiqc_config = Channel.fromPath(
        "${projectDir}/assets/multiqc_config.yml",
        checkIfExists: true
    )
    ch_multiqc_custom_config = params.multiqc_config
        ? Channel.fromPath(params.multiqc_config, checkIfExists: true)
        : Channel.empty()
    ch_multiqc_logo = params.multiqc_logo
        ? Channel.fromPath(params.multiqc_logo, checkIfExists: true)
        : Channel.empty()

    summary_params = paramsSummaryMap(
        workflow,
        parameters_schema: "nextflow_schema.json"
    )
    ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml')
    )
    ch_multiqc_custom_methods_description = params.multiqc_methods_description
        ? file(params.multiqc_methods_description, checkIfExists: true)
        : file("${projectDir}/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description = Channel.value(
        methodsDescriptionText(ch_multiqc_custom_methods_description)
    )

    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_methods_description.collectFile(
            name: 'methods_description_mqc.yaml',
            sort: true,
        )
    )

    MULTIQC(
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        [],
        [],
    )

    emit:
    multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def countSamples(input) {
    def lines = file(input).readLines()
    def sample_count = lines.size() - 1
    println("1 sample detected; switching to single sample mode")
    return sample_count
}
