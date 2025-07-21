#!/usr/bin/env python
import os
import argparse
import pandas as pd
from Bio import SeqIO
import numpy as np
"""
write protein fasta from transdecoder results
"""
def extract_complete_orfs(input_file):
    """
    filter fasta file based on fusion contig name ....
    :param input_file: Transcoder peptide sequences
    :return: dictionary of sequences with complete ORFs
    """
    seq_dict = {}
    with open(input_file, "r") as f:
        for record in SeqIO.parse(f, "fasta"):
            ## just take complete ORFs
            if "ORF type:complete" in record.description:
                ## remove asterisk at end of sequence if its there
                if record.seq.endswith("*"):
                    record.seq = record.seq[:-1]
                    seq_dict[record.description] = str(record.seq)
    return seq_dict

def write_fasta(seq_dict, output_file):
    """
    :param seq_dict: complete ORFs predicted by transdecoder
    :param output_file: output fasta in msfragger format
    :return: writes fasta file in msfragger format
    """
    ## for fusions; may not be necessary
    fusion_id = 1
    fusion_ids = []
    contigs = []
    fusion_genes = []
    with open(output_file, "w") as outfile:
        for header, seq in seq_dict.items():
            ## write out non-canonical protein sequences ...
            if header.startswith("Bambu"):
                protein = header.split(" ")[0]
                protein_id = protein.split(".p")[0]
                outfile.write(f'>%s PE=2\n' % protein_id)
                outfile.write(f'%s\n' %seq)
          ## write out canonical protein sequences ....
            elif header.startswith("ENST"):
                protein = header.split(" ")[0]
                protein_id = protein.split(".p")[0]
                outfile.write(f'>%s PE=1\n' % protein_id)
                outfile.write(f'%s\n' %seq)
            ## write out fusions from JAFFAL....
            elif "fastq" in header:
                protein = header.split(" ")[0]
                protein_id = protein.split(".p")[0]
                ## split futher to collect gene and contig id; then we output as a dataframe ....
                _, fusion_gene, contig = protein_id.split("|")
                outfile.write(f'>GF%d PE=2\n' % fusion_id)
                outfile.write(f'%s\n' %seq)
                ## append everything to fusion lists ....
                fusion_ids.append(fusion_id)
                contigs.append(contig)
                fusion_genes.append(fusion_gene)
                fusion_id = fusion_id + 1
            else:
                print("unclassified sequence")
                continue
    ## return a pandas dataframe with the fusion ids
    fusion_dat = pd.DataFrame(zip(fusion_ids, fusion_genes, contigs),
                              columns=["fusion id (GF##)", "fusion genes", "contig"])
    return fusion_dat


## format fasta for msfragger; if fusions are included collect and rename

## inputs
p = argparse.ArgumentParser()
p.add_argument("transdecoder_peps")
p.add_argument("jaffacsv", nargs='?', default=None)
p.add_argument("--fusions", action="store_true", help="whether fusion calling was enabled")
args = p.parse_args()
##filter for complete ORFs returned from transdecoder
seq_dict = extract_complete_orfs(args.transdecoder_peps)
## write the fasta and return a fusion dataframe
fusion_dat = write_fasta(seq_dict, 'proteins.fasta')
## if we called fusions
if args.fusions:
    jaffacsv = pd.read_csv(args.jaffacsv)
    ## return a csv file of fusions which have complete ORFs
    df = pd.merge(jaffacsv, fusion_dat, on=["fusion genes", "contig"])
    df.to_csv("fusion_stats.csv", index=None)