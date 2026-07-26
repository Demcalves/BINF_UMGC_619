# this is a simple txt getter and setter script taking the gff file for the
# the reference genome and corresponding compressed gff file
# containing only coding sequences and the gene names for reference


from pathlib import Path

proj_dir = Path.cwd()
annotations = Path(proj_dir/'data'/'annotations')
gff_output = open(annotations / 'bsub_gff_cds.txt', "w")
gff_input_target = "bsub_gff_compressed.txt"


with open(annotations / gff_input_target, "r") as f:
    gff_input = f.readlines()
    for line in gff_input:
    #print(line)
    # should only return a list of two strings split by \t
        values = line.split(";")
        #print(values)
        # genetype_id gives something like "CDS\tID=..." and will be split into gene_type and gene_id off of "\t"
        # gene_anot should be the second entry (gene-name) in the annotation, which is the target i.e Parent=gene-BSU_00240
        # gene_name should return "product=..." with the actual gene name
        genetype_id, gene_anot, gene_name = values[0], values[1], values[-3]  
        genetype_idsplit=genetype_id.split("\t")
        # 
        # gene_id should be the first entry (ID) in the annotation, i.e ID=cds-NP_387905.1
        gene_id = genetype_idsplit[1]
        # check to make sure that value1 is CDS, the annotation file includes non coding sequences such as rRNA, tRNA, etc
        # trim the gene_anot and gene_name using slicing to make substrings
        gene_id= gene_id[7:len(gene_id)]
        gene_anot = gene_anot[7:len(gene_anot)] 
        gene_name = gene_name[8:len(gene_name)] # substringing to only be something like BSU_00240
        # not including genetype in the final output. only coding sequences are included
        gff_output.writelines(f"{gene_id}\t{gene_anot}\t{gene_name}\n")
gff_output.close()