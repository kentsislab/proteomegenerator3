#!/usr/bin/env python
import sys
import pandas as pd
import numpy as np
# inputs
fusion_tsv = sys.argv[1]
# outputs
fusion_table = sys.argv[2] # table of fusions with cds regions
output_file = sys.argv[3] # fusion fasta

####
fusion_dat = pd.read_csv(fusion_tsv, sep="\t")
# drop fusions without cds regions for this
coding_fusions = fusion_dat[fusion_dat["FUSION_CDS"] != "."]
# give fusions unique IDs and note AA position of breakpoint
# (useful later to test if we find peptides spanning the junction)
coding_fusions = coding_fusions.assign(
    AA_brk_pos=lambda x: (x["CDS_LEFT_RANGE"].str.split("-").str[1].astype(int) / 3).round(0).astype(int)
)
coding_fusions = coding_fusions.assign(
    Protein=lambda x: ["GF" + str(i) for i in np.arange(1, len(x) + 1)]
)
# write output fasta
with open(output_file, "w+") as outfile:
    for _, row in coding_fusions.iterrows():
        protein_id = row["Protein"]
        gene = row["#FusionName"]
        ORF_id = row["CDS_LEFT_ID"]+"--"+row["CDS_RIGHT_ID"]
        AAseq = row["FUSION_TRANSL"]
        # write header and AA seq
        header = f">tr|{protein_id}|{ORF_id} PG3 predicted ORF OS=Homo sapiens OX=9606 GN={gene} PE=2\n"
        outfile.write(header)
        outfile.write(f"{AAseq}\n")
# write tsv file describing fusions
coding_fusions.to_csv(fusion_table, sep="\t", index=False)
