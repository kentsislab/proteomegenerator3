#!/usr/bin/env python
import sys
import pandas as pd
from gtfparse import read_gtf
from Bio import SeqIO
import warnings
warnings.filterwarnings('ignore')
###
import logging
logger = logging.getLogger()
logger.setLevel(logging.CRITICAL)

"""
generate proteome from transdecoder results in UniProt format
"""
def make_seqdict(input_file):
    """
    make a dict of sequences from fasta file
    :param input_file: fasta file
    :return: dictionary of sequences with ORFs
    """
    seq_dict = {}
    with open(input_file, "r") as f:
        for record in SeqIO.parse(f, "fasta"):
            seq_dict[record.description] = str(record.seq)
    return seq_dict

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

def seqdict2df(sp_dict):
    sp_dat = pd.DataFrame.from_dict(sp_dict, orient="index")
    sp_dat = sp_dat.reset_index()
    sp_dat.columns = ["header", "seq"]
    return sp_dat

'''
inputs
'''
input_fasta = sys.argv[1] # transdecoder ORFs
gtfpath = sys.argv[2] # transcriptome gtf
sp_fasta = sys.argv[3] # swissprot fasta
'''
outputs
'''
output_file = sys.argv[4] # output fasta
protein_tsv = sys.argv[5] # output protein index table

### load in de novo transcript assembly
gtf = read_gtf(gtfpath)
txdb = gtf[gtf["feature"] == "transcript"]
## extract gene info
tx2gene = dict(zip(txdb["transcript_id"], txdb["gene_id"]))
# load in swissprot fasta as well so we can search this for exact matches
sp_dict = make_seqdict(sp_fasta)
sp_dat = seqdict2df(sp_dict)
# account for duplicate sequences in swissprot
sp_dat = sp_dat.drop_duplicates(keep="first", subset="seq")

# make sequence dictionary of complete ORFs from transdecoder
seqdict = extract_complete_orfs(input_fasta)
transdat = seqdict2df(seqdict)
# merge on sequence, keeping all of our detected sequences
mergedat = pd.merge(transdat, sp_dat, on=["seq"], suffixes=("_trans", "_sp"), how="left", indicator=True)
# load in swissprot fasta headers to give these proteoforms the exact swissprot headers
tx_ids = []
protein_ids = []
ORF_ids = []
gene_ids = []
og_headers = []
sp_status = []
### proteoform count for novel proteoforms (with PG accession numbers)
count = 1
with open(output_file, "w+") as outfile:
    for _, row in mergedat.iterrows():
        header = row["header_trans"]
        temp = header.split(" ")
        ORF_id = temp[0]
        tx_id = ORF_id.split(".p")[0]
        # fetch gene
        gene = tx2gene[tx_id]
        # if exact match to swissprot, give it a proper swissprot header
        if row["_merge"] == "both":
            sp_header = row["header_sp"]
            outfile.write(f">{sp_header}\n")
            # retain protein id
            temp = sp_header.split("|")
            protein_id = temp[1]
            protein_ids.append(protein_id)
            sp_status.append(True)
        # if it's a newly predicted ORF give it a trembl header (kind of)
        else:
            new_header = f">tr|PG{count}|{ORF_id} PG3 predicted ORF OS=Homo sapiens OX=9606 GN={gene} PE=2\n"
            # give unique protein id
            protein_id = f"PG{count}"
            protein_ids.append(protein_id)
            count = count + 1
            # determined not to have an exact match in swissprot
            sp_status.append(False)
            outfile.write(new_header)
        # write sequences
        outfile.write(f"{row['seq']}\n")
        # save to create index table
        tx_ids.append(tx_id)
        ORF_ids.append(ORF_id)
        gene_ids.append(gene)
        og_headers.append(header)

# write protein tsv file
descriptdat = pd.DataFrame(zip(protein_ids, tx_ids, ORF_ids, gene_ids, og_headers, sp_status),
                           columns=["Protein", "Transcript", "ORF", "Gene", "transdecoder_header", "SwissProt"])
descriptdat.to_csv(protein_tsv, sep="\t", index=None)
