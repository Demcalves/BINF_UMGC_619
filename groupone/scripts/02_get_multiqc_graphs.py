# this script takes the json values stored from the multiqc operations
# pre-trim and post-trim and creates a simple bar-plot showing the 
# the comparison of import values
import json, sys
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

# this script is excuted from groupone project directory
proj_dir = Path.cwd()
# sra.txt containing a txt file of all SRAs processed
sra_arg_file = sys.argv[1]
with open(sra_arg_file, 'r') as sra_f:
    sra_list = sra_f.read().splitlines()

records = []

for sra in sra_list:
    with open(f"{proj_dir}/results/trimmed/{sra}_fastp_report.json") as data_f:
        fastp_data = json.load(data_f)

    # generate a table 
    before = fastp_data['summary']['before_filtering']
    after = fastp_data['summary']['after_filtering']

    records.append({
        'sample': sra,
        'total_reads_before': before['total_reads'],
        'total_reads_after': after['total_reads'],
        'q20_rate_before': before['q20_rate'],
        'q20_rate_after': after['q20_rate'],
        'q30_rate_before': before['q30_rate'],
        'q30_rate_after': after['q30_rate'],
        'gc_content_before': before['gc_content'],
        'gc_content_after': after['gc_content'],
    })

# data frame for generating figure for comparing reads pre and post trim
df = pd.DataFrame(records)

# x axis set
x = range(len(df))
width = 0.35

fig, ax = plt.subplots()
ax.bar([i - width/2 for i in x], df['total_reads_before'], width, label='Before filtering')
ax.bar([i + width/2 for i in x], df['total_reads_after'], width, label='After filtering')

ax.set_xticks(x)
ax.set_xticklabels(df['sample'], rotation=45)
ax.set_ylabel('Total Reads')
ax.set_title('Read Counts Before vs After FastP trimming')
ax.legend()
plt.tight_layout()
plt.savefig(f"{proj_dir}/figures/reads_before_after.png", dpi=300)

# generate a figure for q30 rates
fig, ax = plt.subplots()
ax.bar([i - width/2 for i in x], df['q30_rate_before']*100, width, label='Before filtering')
ax.bar([i + width/2 for i in x], df['q30_rate_after']*100, width, label='After filtering')
ax.set_xticks(x)
ax.set_xticklabels(df['sample'], rotation=45)
ax.set_ylabel('Q30 Rate (%)')
ax.set_title('Q30 Quality Rate Before vs After Trimming')
ax.legend()
plt.tight_layout()
plt.savefig(f"{proj_dir}/figures/q30_before_after.png", dpi=300)

# save the data 
df.to_csv(f"{proj_dir}/fastqc_fastp_comparison.csv", index=False)
print(df.to_markdown(index=False))