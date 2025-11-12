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
# drop all fusions with CDS
coding_fusions = fusion_df[fusion_df["FUSION_TRANSL"] != "."]
# group by fusion names and predicted ORFs and breakpoints
fusion_groups = coding_fusions.groupby(by=["#FusionName",
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
for (genes, ORF, cds_lr, leftcds, rightcds, leftgene, rightgene, lbrk, rbrk), group in fusion_groups:
    # append to dataframe
    data.append({
        '#FusionName': genes,
        'LeftGene': leftgene,
        'RightGene': rightgene,
        'LeftBreakpoint': lbrk,
        'RightBreakpoint': rbrk,
        'CDS_LEFT_ID': leftcds,
        "CDS_LEFT_RANGE": cds_lr,
        'CDS_RIGHT_ID': rightcds,
        'FUSION_TRANSL': ORF,
        'samples': ",".join(list(group['sample'])),
        'FFPM': ",".join(f"{x:.6f}" for x in group['LR_FFPM'])
    })
# make the fusion table
fusion_info_table = pd.DataFrame(data)
# give fusions unique IDs and note AA position of breakpoint
# (useful later to test if we find peptides spanning the junction)
fusion_info_table = fusion_info_table.assign(
    AA_brk_pos=lambda x: (x["CDS_LEFT_RANGE"].str.split("-").str[1].astype(int) / 3).round(0).astype(int)
)
fusion_info_table = fusion_info_table.assign(
    Protein=lambda x: ["GF" + str(i) for i in np.arange(1, len(x) + 1)]
)
fusion_info_table.to_csv(fusion_info_path, sep="\t", index=None)
# now let's write the fasta file
with open(output_fasta, "w+") as outfile:
    for _, row in fusion_info_table.iterrows():
        protein_id = row["Protein"]
        gene = row["#FusionName"]
        ORF_id = row["CDS_LEFT_ID"] + "--" + row["CDS_RIGHT_ID"]
        AAseq = row["FUSION_TRANSL"]
        # write header and AA seq
        header = f">tr|{protein_id}|{ORF_id} PG3 predicted ORF OS=Homo sapiens OX=9606 GN={gene} PE=2\n"
        outfile.write(header)
        outfile.write(f"{AAseq}\n")
