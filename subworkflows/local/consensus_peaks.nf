/*
 * Create group consensus peaks
 */

params.bedtools_merge_options = [:]
params.sort_options           = [:]
params.plot_peak_options      = [:]
params.awk_threshold_options  = [:]
params.run_peak_plotting      = true

include { SORT                 } from "../../modules/local/linux/sort"                    addParams( options: params.sort_options           )
include { BEDTOOLS_MERGE       } from "../../modules/nf-core/modules/bedtools/merge/main" addParams( options: params.bedtools_merge_options )
include { AWK                  } from "../../modules/local/linux/awk"                     addParams( options: params.awk_threshold_options  )
include { PLOT_CONSENSUS_PEAKS } from "../../modules/local/python/plot_consensus_peaks"   addParams( options: params.plot_peak_options      )

workflow CONSENSUS_PEAKS {

    take:
    bed //  channel: [ val(meta), [ bed ], count]

    main:

    // Sort bed files
    SORT ( bed )

    // Merge peaks
    BEDTOOLS_MERGE ( SORT.out.file )

    // Filter peaks on minimum replicate consensus
    AWK ( BEDTOOLS_MERGE.out.bed )

    // Plot consensus peak sets
    if(params.run_peak_plotting) {
        PLOT_CONSENSUS_PEAKS ( BEDTOOLS_MERGE.out.bed.collect{it[1]}.ifEmpty([]) )
    }

    emit:
    bed              = BEDTOOLS_MERGE.out.bed       // channel: [ val(meta), [ bed ] ]
    filtered_bed     = AWK.out.file                 // channel: [ val(meta), [ bed ] ]
    bedtools_version = BEDTOOLS_MERGE.out.version   // path: *.version.txt
}
