version 1.0

workflow MultiScaleFootprintingWorkflow{
    meta{
        version: 'v0.1'
        author: 'Zhijian Li'
        affiliation: 'Broad Institute of MIT and Harvard'
        email: 'lizhijia@broadinstitute.org'
        description: 'Performing multi-scale footprinting using PRINT'
    }

    input {
        File fragment_file
        File bed_file
        String ref_genome = "hg38"
        Int fp_scale = 10

        # optional input
        File? barcode_groups
        String? project_name = "PROJECT" 
    
    }

    call MultiScaleFootprinting { 
        input: 
            fragment_file = fragment_file, 
            bed_file = bed_file,
            ref_genome = ref_genome,
            fp_scale = fp_scale
            barcode_groups = barcode_groups,
            project_name = project_name
    }

}

task MultiScaleFootprinting{
    input{
        File fragment_file
        File bed_file
        String ref_genome = "hg38"
        Int fp_scale = 10

        # optional input
        File? barcode_groups
        String? project_name = "PROJECT" 
    }

    command{
        set -e

        # Perform footprinting
        Rscript /home/shareseq/PRINT/code/run_PRINT.R \
        --project_name ${project_name} \
        --fragment_file ${fragment_file} \
        --regions ${bed_file} \
        --barcode_groups ${barcode_groups} \
        --ref_genome ${ref_genome} \
        --fp_scale ${fp_scale}

    }

    output{
        File footprint_file = "footprint.bed"
    }
    runtime {
        # Pull this docker image from the `quay.io` registry
        docker: "lzj1769/print"
        memory: mem_gb + "GB"
    }
}