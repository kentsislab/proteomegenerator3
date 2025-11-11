#!/usr/bin/env python
import sys
import pandas as pd
import numpy as np
"""
Merge fusion calls across multiple samples based on gene symbols and breakpoints.
"""
samplesheet = sys.argv[1] # samplesheet for pipeline
fusion_info_path = sys.argv[2]
output_fasta = sys.argv[3]
# read in metadata
metadata = pd.read_csv(samplesheet)
# make a dataframe of fusions
fusion_df = pd.DataFrame()
for _, row in metadata.iterrows():
    lrfusiondat = pd.read_csv(row["fusion_tsv"], sep="\t")
    lrfusiondat["sample"] = row["sample"]
    fusion_df = pd.concat([fusion_df, lrfusiondat])

# group by fusion names and predicted ORFs and breakpoints
fusion_groups = fusion_df.groupby(by=["#FusionName",
                                        "FUSION_TRANSL",
                                        "CDS_LEFT_RANGE",
                                        "CDS_LEFT_ID",
                                        "CDS_RIGHT_ID",
                                        "LeftGene",
                                        "RightGene",
                                        "LeftBreakpoint",
                                        "RightBreakpoint"])
# make a dataframe that contains fusion info
data = []
i = 1
for (genes, ORF, cds_lr, leftcds, rightcds, leftgene, rightgene, lbrk, rbrk), group in fusion_groups:
    # get breakpoint in AA position; will be useful when we match to proteomics later
    if not cds_lr == ".":
        AA_brk = np.round(int(cds_lr.split("-")[1]) / 3)
    else:
        AA_brk = cds_lr
    # append to dataframe
    data.append({
        '#FusionName': genes,
        'LeftGene': leftgene,
        'RightGene': rightgene,
        'LeftBreakpoint': lbrk,
        'RightBreakpoint': rbrk,
        'CDS_LEFT_ID': leftcds,
        'CDS_RIGHT_ID': rightcds,
        'FUSION_TRANSL': ORF,
        'fusioninspector_brk (AA)': AA_brk,
        'samples': ",".join(list(group['sample'])),
        'FFPM': ",".join(f"{x:.6f}" for x in group['LR_FFPM']),
        'fusion_id': f"GF{i}"
    })
    i = i + 1
# make the fusion table
fusion_info_table = pd.DataFrame(data)
fusion_info_table.to_csv(fusion_info_path, sep="\t", index=None)
# now let's write the fasta file
# drop rows without CDS regions
fusion_info_table1 = fusion_info_table[fusion_info_table["fusioninspector_brk (AA)"] != "."]
# write output fasta
with open(output_fasta, "w+") as outfile:
    for _, row in fusion_info_table1.iterrows():
        protein_id = row["fusion_id"]
        gene = row["#FusionName"]
        ORF_id = row["CDS_LEFT_ID"] + "--" + row["CDS_RIGHT_ID"]
        AAseq = row["FUSION_TRANSL"]
        # write header and AA seq
        header = f">tr|{protein_id}|{ORF_id} PG3 predicted ORF OS=Homo sapiens OX=9606 GN={gene} PE=2\n"
        outfile.write(header)
        outfile.write(f"{AAseq}\n")