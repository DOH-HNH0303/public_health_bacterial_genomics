version 1.0

task abricate {
  input {
    File assembly
    String samplename
    String database
    String gene_type = "VIRULENCE"
    # Parameters
    #  --minid Minimum DNA %identity [80]
    # --mincov Minimum DNA %coverage [80]
    Int? minid
    Int? mincov
  }
  command <<<
    date | tee DATE
    abricate -v | tee ABRICATE_VERSION

    abricate \
      --db ~{database} \
      ~{'--minid ' + minid} \
      ~{'--mincov ' + mincov} \
      ~{assembly} > ~{samplename}_abricate_hits.tsv

    genes=$(awk -F '\t' '{ print $6 }' ~{samplename}_abricate_hits.tsv | tail -n+2 | tr '\n' ', ' | sed 's/.$//')

    # if variable for list of genes is EMPTY, write string saying it is empty to float to Terra table
    if [ -z "${genes}" ]; then
       genes="No ~{gene_type} genes detected"


    # create final output strings
    echo "${genes}" > ~{gene_type}_GENES

  >>>
  output {
    File abricate_results = "~{samplename}_abricate_hits.tsv"
    String abricate_database = database
    String abricate_version = read_string("ABRICATE_VERSION")
    String abricate_genes = read_string("~{gene_type}_GENES")
  }
  runtime {
    memory: "8 GB"
    cpu: 4
    docker: "quay.io/staphb/abricate:1.0.0"
    disks: "local-disk 100 HDD"
  }
}
