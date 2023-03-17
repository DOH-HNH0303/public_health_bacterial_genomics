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
      ~{iqtree_opts}>> terminal_output.txt 2>&1|| \
      iqtree \
      -nt AUTO \
      -s msa.fasta \
      -m "GTR+I+G" \
      -bb ~{iqtree_bootstraps} \
      -alrt ~{alrt} \
      ~{iqtree_opts} >> terminal_output.txt 2>&1 || \
      iqtree \
      -s msa.fasta \
      -m "GTR+I+G" \
      ~{iqtree_opts} >> terminal_output.txt 2>&1

      cp msa.fasta.contree ~{cluster_name}_msa.tree || touch none_tree.txt
      cp msa.fasta.iqtree ~{cluster_name}_msa.iqtree || touch none_iqtree.txt
    fi
    ls

    if [ -f "~{cluster_name}_msa.iqtree" ]; then
    if grep -q "Model of substitution:" "~{cluster_name}_msa.iqtree"; then
      cat ~{cluster_name}_msa.iqtree | grep "Model of substitution" | sed s/"Model of substitution: "//>IQTREE_MODEL # SomeString was found
    elif grep -q "Best-fit model according to BIC" "core_iqtree_wa_cluster_msa.iqtree"; then
      cat core_iqtree_wa_cluster_msa.iqtree | grep "Best-fit model according to BIC" | sed s/"Best-fit model according to BIC"//>IQTREE_MODEL
    else
      echo ~{iqtree_model}>IQTREE_MODEL
    fi
    fi

    if [ -f "terminal_output.txt" ]; then

      if grep -q "WARNING: Your alignment contains too many identical sequences!" terminal_output.txt; then
        echo "Too few unique sequences to generate tree">IQTREE_COMMENT #
      elif grep -q "ERROR: It makes no sense to perform bootstrap with less than 4 sequences" terminal_output.txt; then
        echo "Too few unique sequences to perform bootstrapping">IQTREE_COMMENT
      else
        echo "">IQTREE_COMMENT#
      fi
    #elif [ -f "terminal_output.txt" ]; then
    #    if grep -q "ERROR: It makes no sense to perform bootstrap with less than 4 sequences" terminal_output2.txt; then
    #        echo "Too few unique sequences to perform bootstrapping">IQTREE_COMMENT #
    #    fi
    elif [ $numGenomes -le 3 ]; then
      echo "Too few unique sequences to generate tree">IQTREE_COMMENT
    else
      echo "">IQTREE_COMMENT
    fi


  >>>
  output {
    String date = read_string("DATE")
    String version = read_string("VERSION")
    File? iqtree_terminal = "terminal_output.txt"#select_first(["terminal_output3.txt", "terminal_output2.txt", "terminal_output1.txt"])
    File ml_tree = select_first(["~{cluster_name}_msa.tree", "none_tree.txt"])
    File iqtree_report = select_first(["~{cluster_name}_msa.iqtree", "none_iqtree.txt"])
    String? iqtree_model_used = read_string("IQTREE_MODEL")
    String? iqtree_comment = read_string("IQTREE_COMMENT")
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
