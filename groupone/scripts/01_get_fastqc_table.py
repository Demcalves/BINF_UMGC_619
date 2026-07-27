import pandas as pd
import json, sys
from pathlib import Path
proj_dir = Path.cwd()
output_dir = sys.argv[1]
# get raw data and duplicate comparison table for FASTQC
with open(f"{proj_dir}/results/multiqc/pretrim/multiqc_data/multiqc_data.json") as fastqc_f:
    fastqc_data = json.load(fastqc_f)

# aliases a dictionary with key-value pairs (SRR_#.fastq) and a list of metrics from fastqc_data
stats = fastqc_data['report_general_stats_data'][0] 

comp_records, sum_records = [], []
for sample, metrics in stats.items():
   
    comp_records.append({
        'Sample': sample[:len(sample)-2], # slice off the mate_pair tag so that the results can be aggregated later
        'total_sequences': metrics.get('total_sequences'),
        'percent_duplicates': metrics.get('percent_duplicates')
    })
    sum_records.append({
        'Sample': sample[:len(sample)-2],
        'total_sequences': metrics.get('total_sequences'),
        'percent_duplicates': metrics.get('percent_duplicates'),
        'percent_gc': metrics.get('percent_gc'),
        'read_quality': 100 - int(metrics.get('percent_fails'))
    })

df_comp = pd.DataFrame(comp_records)
df_sum = pd.DataFrame(sum_records)
print(df_sum)

grouped_comp = df_comp.groupby('Sample').agg(
    total_sequences=('total_sequences', 'sum'), # merging the paired reads (R1, R2) summing the reads together
    percent_duplicates=('percent_duplicates', 'mean') # averaging duplication percentage between mate pairs R1 / R2
).reset_index()

grouped_comp.to_csv(f"{output_dir}/total_seqs_duplicates_table.csv", index=False)
print(f"Dataframe saved to {output_dir}/total_seqs_duplicates_table.csv")
#print(grouped_comp)

grouped_sum = df_sum.groupby('Sample').agg(
    total_sequences=('total_sequences', 'sum'), # merging the paired reads (R1, R2) summing the reads together
    percent_duplicates=('percent_duplicates', 'mean'), # averaging duplication percentage between mate pairs R1 / R2
    percent_gc=('percent_gc', 'mean'),
    read_quality=('read_quality', 'mean')
).reset_index()

grouped_sum.to_csv(f"{output_dir}/total_seqs_qc_summary_table.csv", index=False)
print(f"Dataframe saved to {proj_dir}/{output_dir}/total_seqs_qc_summary_table.csv")
print(grouped_sum)


print(grouped_sum.to_markdown(index=False))