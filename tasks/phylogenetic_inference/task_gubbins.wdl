version 1.0

task gubbins {
  input {
    File alignment
    String cluster_name # For comparison to other tools use HKY for bactopia, GTR+F+I for grandeur, GTR+G4 for nullarbor, GTR+G for dryad
    String docker = "sangerpathogens/gubbins:v3.0.0"
    File? treefile
    Int threads = 8
  }
  command <<<
    # date and version control
    date | tee DATE
    ls
    echo ""
    ls /data
    #iqtree --version | grep version | sed 's/.*version/version/;s/ for Linux.*//' | tee VERSION

    numGenomes=`grep -o '>' ~{alignment} | wc -l`
    if [ $numGenomes -gt 3 ]
    then
      run_gubbins.py --prefix ~{cluster_name} --threads ~{threads} --verbose --tree-builder iqtree --model-fitter iqtree --bootstrap 1000 --sh-test ~{alignment}

      mv gubbins_output.aln ~{cluster_name}_gubbins_output.aln
    fi
    ls
  >>>
  output {
    String date = read_string("DATE")
    File base_reconstruct = "~{cluster_name}.branch_base_reconstruction.embl"
    File polymorph_site_fasta = "~{cluster_name}.filtered_polymorphic_sites.fasta"
    File polymorph_site_phylip = "~{cluster_name}.filtered_polymorphic_sites.phylip"
    File gubbins_tree = "~{cluster_name}.final_tree.tre"
    File gubbins_labelled_tree = "~{cluster_name}.node_labelled.final_tree.tre"
    File branch_stats = "~{cluster_name}.per_branch_statistics.csv"
    File recomb_embl = "~{cluster_name}.recombination_predictions.embl"
    File recomb_gff = "~{cluster_name}.recombination_predictions.gff"
    File gubbins_snps= "~{cluster_name}.summary_of_snp_distribution.vcf"



  }
  runtime {
    docker: "~{docker}"
    memory: "32 GB"
    cpu: 4
    disks: "local-disk 100 SSD"
    preemptible: 0
    maxRetries: 3
  }
}
