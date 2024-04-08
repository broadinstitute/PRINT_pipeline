suppressMessages(source("/data/pinello/PROJECTS/2024_04_ZL_PRINT/PRINT/code/utils.R"))
suppressMessages(source("/data/pinello/PROJECTS/2024_04_ZL_PRINT/PRINT/code/getCounts.R"))
suppressMessages(source("/data/pinello/PROJECTS/2024_04_ZL_PRINT/PRINT/code/getBias.R"))
suppressMessages(source("/data/pinello/PROJECTS/2024_04_ZL_PRINT/PRINT/code/getFootprints.R"))
suppressMessages(source("/data/pinello/PROJECTS/2024_04_ZL_PRINT/PRINT/code/getSubstructures.R"))
suppressMessages(source("/data/pinello/PROJECTS/2024_04_ZL_PRINT/PRINT/code/visualization.R"))
suppressMessages(source("/data/pinello/PROJECTS/2024_04_ZL_PRINT/PRINT/code/getGroupData.R"))
suppressMessages(source("/data/pinello/PROJECTS/2024_04_ZL_PRINT/PRINT/code/footprintTracking.R"))
suppressMessages(source("/data/pinello/PROJECTS/2024_04_ZL_PRINT/PRINT/code/getTFBS.R"))

suppressMessages(library(optparse))

option_list = list(
    make_option(c("--project_name"), type="character", default="PROJECT", 
                help="Project name. Default: PROJECT", metavar="character"),
    
    make_option(c("--fragment_file"), type="character", default=NULL, 
                help="Input fragment file. Default: NULL", metavar="character"),
    
    make_option(c("--barcode_groups"), type="character", default=NULL, 
                help="Input file containing group information of barcodes. 
                      First column is barcodes and second is groupID. Default: NULL", 
                metavar="character"),    
    
    make_option(c("--regions"), type="character", default=NULL, 
                help="Input bed file containing regions for performing footprinting. Default: NULL", metavar="character"),
    
    make_option(c("--ref_genome"), type="character", default="hg38", 
                help="Reference genome. Available options: hg38, mm10. Default: hg38", 
                metavar="character"),
    
    make_option(c("--disp_model_dir"), type="character", default="NULL", 
                help="Directory of dispersion models. Default: NULL", 
                metavar="character"),    
    
    make_option(c("--tf_model"), type="character", default="NULL", 
                help="Path of TFBS prediction models. Default: NULL", 
                metavar="character"), 
    
    make_option(c("--tn5_bias_dir"), type="character", default="NULL", 
                help="Directory of Tn5 bias model. Can be downloaded from https://zenodo.org/record/7121027#.ZCbw4uzMI8N
Default: NULL", 
                metavar="character"), 
    
    make_option(c("--fp_scale"), type="integer", default=10, 
                help="Length of footprint", metavar="int"),

    make_option(c("--n_cores"), type="integer", default=4, 
                help="Number of cores", metavar="int"),
    
    make_option(c("--out_dir"), type="character", default="./", 
                help="Output directory", metavar="character")
)

opt_parser <- OptionParser(option_list=option_list)
opt <- parse_args(opt_parser)

# create object of the project
cat("Creating project...\n")
if(!dir.exists(opt$out_dir)){
    dir.create(opt$out_dir, recursive = TRUE)
}
project <- footprintingProject(projectName = opt$project_name, 
                               refGenome = opt$ref_genome,
                               outDir = opt$out_dir,
                               fragFile = opt$fragment_file)

# Read regions
cat("Reading genomic regions...\n")
df <- read.table(opt$regions, header = T)
regionRanges(project) <- GRanges(seqnames = df$chr, 
                                 ranges = IRanges(start = df$start, 
                                                  end = df$end))
cat(glue::glue("Number of regions: {nrow(df)}\n"))

# read barcode group
cat("Reading barcodes group...\n")
df <- read.table(opt$barcode_groups, header = T)
barcodeGrouping(project) <- read.table(opt$barcode_groups, header = T)
groups(project) <- mixedsort(unique(df$group))

# loading dispersion model
cat("Loading dispersion models...\n")
for(kernelSize in 2:100){
    filename <- glue::glue("{opt$disp_model_dir}/dispersionModel{kernelSize}bp.rds")
    dispModel(project, as.character(kernelSize)) <- readRDS(filename)
}

# Reading bias prediction
cat("Reading Tn5 bias...\n")
project <- getPrecomputedBias(project, 
                              Tn5BiasDir=opt$tn5_bias_dir, 
                              nCores = opt$n_cores)


# Load TFBS prediction model
cat("Loading TFBS prediction model...\n")
TFBindingModel(project) <- loadTFBSModel(opt$tf_model)


# convert fragment to tensor
cat("Converting fragments to count tensor...\n")
project <- getCountTensor(project, 
                          nCores = opt$n_cores,
                          returnCombined = F)

# get footprints
project <- getFootprints(
  project,
  mode = as.character(opt$fp_scale),
  nCores = opt$n_cores,
  footprintRadius = opt$fp_scale,
  flankRadius = opt$fp_scale)
