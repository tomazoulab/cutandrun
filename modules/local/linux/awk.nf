include { initOptions; saveFiles; getSoftwareName } from '../common/functions'

params.options   = [:]
options          = initOptions(params.options)
options.command  = params.options.command ?: ''
options.command2 = params.options.command2 ?: ''
options.ext      = params.options.ext ?: ''

process AWK {
    tag "$meta.id"
    label 'process_low'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:'') }

    conda (params.enable_conda ? "conda-forge::sed=4.7" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://containers.biocontainers.pro/s3/SingImgsRepo/biocontainers/v1.2.0_cv1/biocontainers_v1.2.0_cv1.img"
    } else {
        container "biocontainers/biocontainers:v1.2.0_cv1"
    }

    input:
    tuple val(meta), path(input)

    output:
    tuple val(meta), path("*.awk.*"), emit: file
    path "*.version.txt",             emit: version

    script:
    def software = getSoftwareName(task.process)
    def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    def ext   = options.ext ? "${options.ext}" : "txt"
    """
    awk $options.args $options.command $input $options.command2 > ${prefix}.awk.${ext}
    awk -W version | head -n 1 | egrep -o "([0-9]{1,}\\.)+[0-9]{1,}" > ${software}.version.txt
    """
}
