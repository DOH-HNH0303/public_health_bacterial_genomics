# **Pipeline dev notes**
python3 generate_ska_alignment.py --reference cdip_reference.fna --fasta kingc_isolates.list --out cdip_kingc.aln

##### Generate input file for ska
```
for f in *fasta; do echo "${f%.fasta}
    ${f}"; done > kingc_isolates.list
python3 generate_ska_alignment.py --reference cdip_reference.fna --fasta kingc_isolates.list --out cdip_kingc08102022.aln
```
##### Run Gubbins with built in Gubbins script
```
run_gubbins.py --prefix test_1  kingc_08102022.aln
```

##### Masks recombinants from alignment
mask_gubbins_aln.py --aln out.aln --gff out.recombination_predictions.gff --out out.masked.aln

##### Run Theiagen's kSNP3 pipeline to get core aln

##### run iqtree to generate tree using best fit model
```
iqtree -s {input} -pre iqtree -m TESTNEW -bb 1000 -alrt 1000 -nt AUTO
```


##### Treefile is "all organism" level tree for all seqs looked at
```
python /data/holly/gisaid/gisaid_script/gisaid_script.py HNH0303
```

## **Continue to by clade/cluster analysis**

##### Split seqs into clade (or cluster depending on organism) based on snp on output from kSNP3 pipeline
##### run contents of clade_by_snp.py in-line in command section of task
##### Continue with the following for each list of seqs that form a cluster/clade:

##### run Theiagen's pangenome/pirate pipeline+pirate_to_roary conversion

##### Run run_gubbins and mask_gubbins commands listed above (repeat tasks) for each cluster/clade

# Run iqtree as listen above for each cluster/clade

# run roary_plot_waphl.py on gene_presence_absence.csv+gubbins+iqtree output
