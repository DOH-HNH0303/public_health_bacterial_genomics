version 1.0

task gubbins {
  input {
    File alignment
    String cluster_name # For comparison to other tools use HKY for bactopia, GTR+F+I for grandeur, GTR+G4 for nullarbor, GTR+G for dryad
    String docker = "nanozoo/gubbins:3.2.1--d9bcf34"
  }
  command <<<
    # date and version control
    date | tee DATE
    #iqtree --version | grep version | sed 's/.*version/version/;s/ for Linux.*//' | tee VERSION

    numGenomes=`grep -o '>' ~{alignment} | wc -l`
    if [ $numGenomes -gt 3 ]
    then
      run_gubbins.py --prefix ~{cluster_name}  ~{alignment}

      cp msa.fasta.contree ~{cluster_name}_msa.tree
    fi
  >>>
  output {
    String date = read_string("DATE")
    #String version = read_string("VERSION")
    File ml_tree = "~{cluster_name}_msa.tree"
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
