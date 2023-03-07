version 1.0

task gubbins {
  input {
    File alignment
    String cluster_name
    String docker = "sangerpathogens/gubbins:v3.0.0"
    File? treefile
    Int threads = 4
    Float filter_perc = 25.0
    #String backup_model = "GTR"
  }
  command <<<
    # date and version control
    date | tee DATE
    half=$((threads/2))
    numGenomes=`grep -o '>' ~{alignment} | wc -l`
    if [ $numGenomes -gt 3 ]
    then
        run_gubbins.py --prefix ~{cluster_name} --threads ~{threads} --filter-percentage ~{filter_perc} --verbose --tree-builder iqtree --model-fitter iqtree  ~{alignment}>gubbins_attempt_1.txt || \
        run_gubbins.py --prefix ~{cluster_name} --threads $half --verbose --filter-percentage ~{filter_perc} --tree-builder iqtree --model-fitter iqtree  ~{alignment}>gubbins_attempt_2.txt || \
        run_gubbins.py --prefix ~{cluster_name} --verbose --filter-percentage ~{filter_perc} --tree-builder iqtree --model-fitter iqtree  ~{alignment}>gubbins_attempt_3.txt
        #run_gubbins.py --prefix ~{cluster_name} --verbose --tree-builder iqtree --best-model ~{alignment}

    fi
    if [ -f "gubbins_attempt_3.txt" ]; then
        if grep -Fxq "RuntimeWarning: divide by zero encountered in log" gubbins_attempt_3.txt; then
            echo "Gubbins cannot test GTR substitution model, no attempt to determine recombinance can be made">GUBBINS_COMMENT
            echo "false">GUBBINS_BOOL
        fi

    elif [ -f "gubbins_attempt_2.txt" ]; then
        pass

    elif [ -f "gubbins_attempt_1.txt" ]; then
        pass
    else
        echo "Too few genomes, No attempt to determine recombinance can be made">GUBBINS_COMMENT
        echo "false">GUBBINS_BOOL
    fi
    if [ ! -f "GUBBINS_BOOL" ]; then
        echo "true">GUBBINS_BOOL
    ls


  >>>
  output {
    String date = read_string("DATE")
    String? gubbins_comment = read_string("GUBBINS_COMMENT")
    Boolean gubbins_mask = read_string("GUBBINS_BOOL")
    File base_reconstruct = "~{cluster_name}.branch_base_reconstruction.embl"
    File polymorph_site_fasta = "~{cluster_name}.filtered_polymorphic_sites.fasta"
    File polymorph_site_phylip = "~{cluster_name}.filtered_polymorphic_sites.phylip"
    File branch_stats = "~{cluster_name}.per_branch_statistics.csv"
    File recomb_gff = "~{cluster_name}.recombination_predictions.gff"
    File recomb_embl = "~{cluster_name}.recombination_predictions.embl"
    File gubbins_snps= "~{cluster_name}.summary_of_snp_distribution.vcf"
    File gubbins_final_tre = "~{cluster_name}.final_tree.tre"
    File gubbins_log = "~{cluster_name}.log"
    File gubbins_node_tre = "~{cluster_name}.node_labelled.final_tree.tre"



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
    File base_reconstruct
    File recomb_embl
    File polymorph_site_fasta
    File polymorph_site_phylip
    File branch_stats
    File gubbins_snps
    File gubbins_final_tre
    File gubbins_log
    File gubbins_node_tre
  }
  command <<<
    # date and version control
    date | tee DATE
    mv ~{recomb} .
    mv ~{recomb} .
    mv ~{base_reconstruct} .
    mv ~{recomb_embl} .
    mv ~{polymorph_site_fasta} .
    mv ~{polymorph_site_phylip} .
    mv ~{branch_stats} .
    mv ~{gubbins_snps} .
    mv ~{gubbins_final_tre} .
    mv ~{gubbins_log} .
    mv ~{gubbins_node_tre} .

    python3 /data/maskrc-svg.py --aln ~{alignment} --out ~{cluster_name}_masked.aln --gubbins ~{cluster_name} --svg ~{cluster_name}_masked.svg --consensus
    rm *fasta
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
