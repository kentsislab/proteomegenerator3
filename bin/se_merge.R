#!/usr/bin/env Rscript
library(bambu)
library(optparse)
## load in commandline args
option_list = list(
  make_option("--se", type="character", default=NULL,
              help="summarized experiments", metavar="character")
);
opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);
# create vector of summarized experiment objects
loadRData <- function(fileName){
    load(fileName)
    get(ls()[ls() != "fileName"])
}
rdata_paths <- strsplit(opt$se, ",")[[1]]
### combine objects
se <- loadRData(rdata_paths[1])
for (i in 2:length(rdata_paths)){
  se1 <- loadRData(rdata_paths[i])
  se <- cbind(se, se1)
}
# write bambu outputs
writeBambuOutput(se, path="./")
save(se, file = "merged_se.RData")
