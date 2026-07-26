# this is a simple processing script taking the Salmon Quant results from each SRA in sra.txt 
# this python script will get the top genes for each SRA file in results/counts
# Then aggregate all of the values into one library that gets the top 20 
# total and top 10 total as a tsv and txt file respectively for reporting
# finally it makes a plot
import sys
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
#from scipy.stats import zscore
from pathlib import Path

proj_dir = Path.cwd()
# this script only takes one argument
sra_list = str(sys.argv[1]) # should be a string

with open(sra_list, 'r') as sra_f:
    sra_args_list = sra_f.read().splitlines()

# this dictionary will hold gene name and a list of tuples (SRR number, expression level)
amal_dict = {}
amal_top_genes = [] 
for sra_arg in sra_args_list:
    # use the bsub_lib to replace gene-BSU_[0-9]+ annotation id with the gene_name
    with open(proj_dir/'results'/'counts'/sra_arg/f"{sra_arg}_cds_quant.txt", "r") as cq_file:
        # output file that we want
        cds_output_10 = open(proj_dir/'results'/'counts'/sra_arg/f"{sra_arg}_top10.txt", 'w')
        cds_output_20 = open(proj_dir/'results'/'counts'/sra_arg/f"{sra_arg}_top20.txt", 'w')
        # write a header for cds_output
        cds_output_10.writelines("Gene-ID\tSRA\tTPM\n")
        cds_output_20.writelines("Gene-ID\tSRA\tTPM\n")
        cds_quant = cq_file.readlines()
        cds_dict = {}
        # create a list of all cds (BSU-[0-9]+) into the 
        for cq_line in cds_quant:
            cq_no_newline = cq_line.split("\n")[0]
            cq_values = cq_no_newline.split(" ")
            # contains bsu and TPM values
            bsu, tpm = cq_values[0][cq_values[0].index("-")+1:len(cq_values[0])], float(cq_values[1])
            cds_dict[bsu] = tpm
            if bsu not in amal_dict:
                amal_dict[bsu] = []
            amal_dict[bsu].append((sra_arg, tpm))

        # use the sorted function to iterate through the entire dictionary created above and sort the top 10 genes
        # the lambda function is getting the second value in cds_dict.items which is the TPM that we are sorting 
        # by using that value as the sorting key.
        toptwenty_pairs_local = sorted(cds_dict.items(), key=lambda kv: kv[1], reverse=True)[:20]
        topten_pairs_local = toptwenty_pairs_local[:10]
        #print(topten_pairs_local)
        for gene,tpm in toptwenty_pairs_local:
            # append to amal_top_genes list for comparison
            # boolean checker for passing a boolean
            is_not_in_top_genes = True
            for i in range(len(amal_top_genes)):
                entry = amal_top_genes[i]
                #print(entry)
                if entry[0] == gene:
                    is_not_in_top_genes = False
            if (is_not_in_top_genes):
                amal_top_genes.append((gene, sra_arg, tpm))
            cds_output_20.writelines(f"{gene}\t{sra_arg}\t{tpm}\n")

        for gene,tpm in topten_pairs_local:
            cds_output_10.writelines(f"{gene}\t{sra_arg}\t{tpm}\n")
    cds_output_10.close()
    cds_output_20.close()
# now that we have done the local files, sort the almagamated


topten_global = open(proj_dir/'results'/'topgenes_aggregate_10.txt', 'w')
topten_global.writelines("Gene\tSRA\tTMP\n")
toptwenty_pairs_global = sorted(amal_top_genes, key=lambda kv: kv[2], reverse=True)[:20]
#print(toptwenty_pairs_global)
# extract the top ten expressed genes across all of the samples
topten_pairs_global = toptwenty_pairs_global[:10]
for gene, srr, tpm_val in topten_pairs_global:
    topten_global.writelines(f"{gene}\t{srr}\t{tpm_val:.2f}\n")
topten_global.close()
# create pivot table for graphs
columns_list = ['Gene-ID'] # append these on with pandas
row_values = []
#print(columns_list)
#top_genes_set = set(gene for gene, srr, tpm_val in toptwenty_pairs_global)
#print(top_genes_set)
# extract every three values? 
top_genes_list = []
for i in range(0, len(toptwenty_pairs_global)):
    top_gene = toptwenty_pairs_global[i][0]
    top_genes_list.append(top_gene)
for gene in top_genes_list:
    #print(amal_dict[gene])
    for srr, tpm in amal_dict[gene]:
        row_values.append((gene, srr, round(tpm, 2)))
# create the data frame
df = pd.DataFrame(row_values, columns=['Gene-ID', 'SRR-ID', 'TPM'])
wide_df = df.pivot(index='Gene-ID', columns='SRR-ID', values='TPM')
gene_order = wide_df.max(axis=1).sort_values(ascending=False).index
widedf_sorted = wide_df.reindex(gene_order)
widedf_sorted.to_csv(proj_dir/'results'/'topgenes_aggregate_20.txt', sep='\t')
#scaled_df = widedf_sorted.apply(zscore, axis=1)
# take the csv and plot it
sns.heatmap(widedf_sorted, cmap='viridis', annot=True, fmt='.0f')
plt.tight_layout()
plt.savefig(proj_dir/'results'/'top20genes_heatmap.png', dpi=300)