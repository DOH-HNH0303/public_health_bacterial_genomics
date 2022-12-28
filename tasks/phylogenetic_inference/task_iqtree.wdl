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
      ~{iqtree_opts}

      cp msa.fasta.contree ~{cluster_name}_msa.tree
      cp msa.fasta.iqtree ~{cluster_name}_msa.iqtree
    fi
    ls

    python <<CODE
    if ~{iqtree_model} == "TESTNEW":
      with open("~{cluster_name}_msa.iqtree") as file:
        metadata=file.readlines()
        for line in metadata:
          if "Best-fit model according to BIC" in line:
              model= line
              f = open(IQTREE_MODEL, "w")
              f.write(model)
              f.close()
          else:
              pass
    else:
      f = open(IQTREE_MODEL, "w")
      f.write(~{iqtree_model})
      f.close()

    CODE
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
    disks: "local-disk 100 SSD"
    preemptible: 0
    maxRetries: 3
  }
}
