#!/usr/bin/env Rscript
library(bambu)
library(optparse)
## load in commandline args
option_list = list(
  make_option("--rds", type="character", default=NULL,
              help="bambu read classes", metavar="character"),
  make_option("--yieldsize", type="character", default=1e5,
              help="limits number of reads processed at once", metavar="character"),
  make_option("--NDR", type="numeric", default=NULL,
              help="bambu NDR; modulates FDR", metavar="character"),
  make_option("--quant", type="logical", default=TRUE,
              help="whether to run quantification", metavar="logical"),
  make_option("--discovery", type="logical", default=TRUE,
              help="whether to run quantification", metavar="logical"),
  make_option("--ncore", type="numeric", default=1,
              help="number of threads", metavar="numeric"),
  make_option("--ref_genome", type="character", default=NULL,
              help="reference genome", metavar="character"),
  make_option("--ref_gtf", type="character", default=NULL,
              help="reference gtf", metavar="character"),
  make_option("--lowMemory", type="logical", default=TRUE,
            help="low memory mode", metavar="logical")
);

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);
# This function creates a reference annotation object which is used for transcript discovery and quantification in Bambu.
annotations <- prepareAnnotations(opt$ref_gtf)
####################
# prepare a vector of read classes
rds <- strsplit(opt$rds, ",")[[1]]
sprintf("processing %s read classes", length(rds))
## run bambu
se <- bambu(reads = rds, annotations = annotations, ncore = opt$ncore,
            genome = opt$ref_genome, NDR = opt$NDR, verbose=TRUE,
            quant = opt$quant, discovery=opt$discovery,
            yieldSize = opt$yieldsize, lowMemory=opt$lowMemory)
## write outputs to gtf and expression level files
if (opt$quant){
  writeBambuOutput(se, path = "./")
} else {
  writeToGTF(se, file = "./extended_annotations.gtf")
}
#
## let's also save the summarized experiment object to play with later ...
save(se, file = "./se.RData")
