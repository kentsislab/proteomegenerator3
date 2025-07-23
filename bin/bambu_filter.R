#!/usr/bin/env Rscript
library(bambu)
library(optparse)
## load in commandline args
option_list = list(
  make_option("--se", type="character", default=NULL,
              help="bambu read classes", metavar="character"),
  make_option("--merge", type="logical", default=FALSE,
              help="if multisample merge was performed", metavar="logical")
);
opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);
# load summarized experiment object
load(opt$se)
# filter on full-length counts
if (opt$merge) {
  fullLengthCounts <- assays(se)$fullLengthCounts
  rows_satisfying_conditions <- apply(fullLengthCounts, 1, function(row) any(row > 1))
  # Subset the SummarizedExperiment object based on the condition
  se.detected <- se[rows_satisfying_conditions, ]
} else {
  se.detected <- se[assays(se)$fullLengthCounts > 1,]
}
detectgtf <- rowRanges(se.detected)
writeToGTF(detectgtf, "detected_transcripts.gtf")
