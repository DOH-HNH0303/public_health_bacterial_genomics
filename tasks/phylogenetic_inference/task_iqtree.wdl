version 1.0

task iqtree {
  input {
    File alignment
    String cluster_name
    String iqtree_model = "GTR+I+G" # For comparison to other tools use HKY for bactopia, GTR+F+I for grandeur, GTR+G4 for nullarbor, GTR+G for dryad
    String iqtree_bootstraps = 1000 #  Ultrafast bootstrap replicates
    String alrt = 1000 # SH-like approximate likelihood ratio test (SH-aLRT) replicates
    String? iqtree_opts = ""
    String docker = "staphb/iqtree:1.6.7"
    Int disk_size = 100
  }
  command <<<
    # date and version control
    date | tee DATE
    iqtree --version | grep version | sed 's/.*version/version/;s/ for Linux.*//' | tee VERSION

    numGenomes=`grep -o '>' ~{alignment} | wc -l`
    if [ $numGenomes -gt 3 ]
    then
      cp ~{alignment} ./msa.fasta
      iqtree \
      -nt AUTO \
      -s msa.fasta \
      -m ~{iqtree_model} \
      -bb ~{iqtree_bootstraps} \
      -alrt ~{alrt} \
      ~{iqtree_opts}

      cp msa.fasta.contree ~{cluster_name}_msa.tree
      cp msa.fasta.iqtree ~{cluster_name}_msa.iqtree
    fi
    ls

    if grep -q "Model of substitution:" "~{cluster_name}_msa.iqtree"; then
      cat ~{cluster_name}_msa.iqtree | grep "Model of substitution" | sed s/"Model of substitution: "//>IQTREE_MODEL # SomeString was found
    elif grep -q "Best-fit model according to BIC" "core_iqtree_wa_cluster_msa.iqtree"; then
    cat core_iqtree_wa_cluster_msa.iqtree | grep "Best-fit model according to BIC" | sed s/"Best-fit model according to BIC"//>IQTREE_MODEL
    else
      echo ~{iqtree_model}>IQTREE_MODEL
    fi


  >>>
  output {
    String date = read_string("DATE")
    String version = read_string("VERSION")
    File ml_tree = "~{cluster_name}_msa.tree"
    File iqtree_report = "~{cluster_name}_msa.iqtree"
    File iqtree_model = read_string("IQTREE_MODEL")
  }
  runtime {
    docker: "~{docker}"
    memory: "32 GB"
    cpu: 4
    disks: "local-disk " + disk_size + " SSD"
    disk: disk_size + " GB"
    preemptible: 0
    maxRetries: 3
  }
}
