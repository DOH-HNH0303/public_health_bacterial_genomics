version 1.0

task gubbins {
  input {
    File alignment
    String cluster_name
    String docker = "sangerpathogens/gubbins:v3.0.0"
    File? treefile
    Int threads = 2
  }
  command <<<
    # date and version control
    date | tee DATE

    numGenomes=`grep -o '>' ~{alignment} | wc -l`
    if [ $numGenomes -gt 3 ]
    then
      run_gubbins.py --prefix ~{cluster_name} --threads ~{threads} --verbose --tree-builder iqtree --model-fitter iqtree  ~{alignment}
    fi
    ls
  >>>
  output {
    String date = read_string("DATE")
    File base_reconstruct = "~{cluster_name}.branch_base_reconstruction.embl"
    File polymorph_site_fasta = "~{cluster_name}.filtered_polymorphic_sites.fasta"
    File polymorph_site_phylip = "~{cluster_name}.filtered_polymorphic_sites.phylip"
    File branch_stats = "~{cluster_name}.per_branch_statistics.csv"
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

task mask_gubbins {
  input {
    File alignment
    File recomb
    String cluster_name
    String docker = "hnh0303/mask_gubbins_aln:3.3"
    Int threads = 6
  }
  command <<<
    # date and version control
    date | tee DATE
    python3 /data/mask_gubbins_aln.py --aln ~{alignment} --gff ~{recomb} --out ~{cluster_name}_masked.aln
    awk -F "|" '/^>/ {close(F); ID=$1; gsub("^>", "", ID); F=ID".fasta"} {print >> F}' ~{cluster_name}_masked.aln
    tar -czvf ~{cluster_name}_masked_fastas.tar.gz *.fasta
  >>>
  output {
    String date = read_string("DATE")
    File masked_aln = "~{cluster_name}_masked.aln"
    File masked_fastas = "~{cluster_name}_masked_fastas.tar.gz"
    Array[File] masked_fasta_list = glob("*.fasta")
  }
  runtime {
    docker: "~{docker}"
    memory: "16 GB"
    cpu: 4
    disks: "local-disk 100 SSD"
    preemptible: 0
    maxRetries: 3
  }
}

task maskrc_svg {
  input {
    File alignment
    File recomb
    String cluster_name
    String docker = "hnh0303/maskrc-svg:0.5"
    Int threads = 6
  }
  command <<<
    # date and version control
    date | tee DATE
    python3 /data/maskrc-svg.py --aln ~{alignment} --out ~{cluster_name}_masked.aln --gubbins {cluster_name} --svg {cluster_name}_masked.svg --consensus
    awk -F "|" '/^>/ {close(F); ID=$1; gsub("^>", "", ID); F=ID".fasta"} {print >> F}' ~{cluster_name}_masked.aln
    tar -czvf ~{cluster_name}_masked_fastas.tar.gz *.fasta
  >>>
  output {
    String date = read_string("DATE")
    File masked_aln = "~{cluster_name}_masked.aln"
    File masked_fastas = "~{cluster_name}_masked_fastas.tar.gz"
    Array[File] masked_fasta_list = glob("*.fasta")
  }
  runtime {
    docker: "~{docker}"
    memory: "16 GB"
    cpu: 4
    disks: "local-disk 100 SSD"
    preemptible: 0
    maxRetries: 3
  }
}
