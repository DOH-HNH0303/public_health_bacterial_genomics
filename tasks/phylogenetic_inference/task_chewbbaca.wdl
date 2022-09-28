version 1.0

task chewbbaca {
  input {
    Array[File] assembly_fastas
    String cluster_name
    String docker_image = "ummidock/chewbbaca:2.8.5"
    Int memory = 32
    Int cpu = 8
    Int disk_size = 100
    File cgMLSTschema_zip

  }
  command <<<

  echo ~{cluster_name}

  touch input.tsv
  assembly_array="~{sep='\t' assembly_fastas}"
  for item in "${assembly_array[@]}"; do
    echo $item>>input.tsv
  done

  awk 'BEGIN{OFS="\n"}{for(i=1;i<=NF;i++) print $i}' input.tsv>input_transposed.tsv

  assembly_array_len=$(echo "${#assembly_arrays[@]}")
  echo "assembly array"
  echo $assembly_array
  echo $assembly_array_len

  unzip ~{cgMLSTschema_zip}
  mv cgMLST*_schema cgMLST*_schema_old

  chewBBACA.py AlleleCall -i input_transposed.tsv -g schema/schema_seed --gl cgmlst*_schema_old/cgMLSTschema.txt -o results~{cluster_name}_cgMLST --cpu 6
  chewBBACA.py JoinProfiles -p1 cgMLST*_schema_old/cgMLST.tsv -p2 results~{cluster_name}_cgMLST/*/results_alleles.tsv -o cgMLST_all.tsv
  chewBBACA.py TestGenomeQuality -i cgMLST_all.tsv -n 13 -t 300 -s 5

  ls>ls.txt
  zip -r ~{cluster_name}_cgmlst.zip *

  >>>
  output {
    File chewbbaca_test = "ls.txt"
    File chewbbaca_test2 = "input.tsv"
    File  cluster_cgmlst_zip = "~{cluster_name}_cgmlst.zip"
    String chewbbaca_docker_image = docker_image

  }
  runtime {
    docker: docker_image
    memory: "~{memory} GB"
    cpu: cpu
    disks: "local-disk ~{disk_size} SSD"
    preemptible: 0
    maxRetries: 3
  }
}

task create_cgmlst_schema {
  input {
    Array[File] assembly_fastas
    String cluster_name
    File prodigal_file
    String docker_image = "ummidock/chewbbaca:2.8.5"
    Int memory = 32
    Int cpu = 8
    Int disk_size = 100
    Float threshold

  }
  command <<<

  echo ~{cluster_name}

  touch input.tsv
  assembly_array="~{sep='\t' assembly_fastas}"
  for item in "${assembly_array[@]}"; do
    echo $item>>input.tsv
  done

  awk 'BEGIN{OFS="\n"}{for(i=1;i<=NF;i++) print $i}' input.tsv>input_transposed.tsv

  assembly_array_len=$(echo "${#assembly_arrays[@]}")
  echo "assembly array"
  echo $assembly_array
  echo $assembly_array_len


  #i. Whole Genome Multilocus Sequence Typing (wgMLST) schema creation
  chewBBACA.py CreateSchema -i input_transposed.tsv -o schema --ptf ~{prodigal_file} --cpu 6

  #ii. Allele call using a cg/wgMLST schema
  chewBBACA.py AlleleCall -i input_transposed.tsv -g schema/schema_seed -o results_wgMLST --cpu 6

  # ii.2 remove paralogs
  chewBBACA.py RemoveGenes -i results_wgMLST/*/results_alleles.tsv -g results_wgMLST/*/RepeatedLoci.txt -o results_wgMLST/results_alleles_NoParalogs.tsv

  #iii. Determine annotations for loci in the schema
  chewBBACA.py UniprotFinder -i Cdip -o . --taxa "Corynebacterium diphtheriae" --cpu 6

  #iv. Evaluate wgMLST call quality per genome
  chewBBACA.py TestGenomeQuality -i results_wgMLST/results_alleles_NoParalogs.tsv -n 12 -t 200 -s 5 -o wgmlst_call_quality

  #v. Defining the cgMLST schema
  chewBBACA.py ExtractCgMLST -i results_wgMLST/results_alleles_NoParalogs.tsv -o cgmlst_schema --t ~{threshold}

  zip schema.zip schema/schema_seed

  zip -r cgmlst.zip *

  ls>ls.txt

  >>>
  output {
    File chewbbaca_test = "ls.txt"
    File chewbbaca_test2 = "input.tsv"
    File schema_zip = "schema.zip"
    File cgmlst_zip = "cgmlst.zip"
    File schema_txt = "cgmlst_95_schema/cgMLSTschema.txt"
    String chewbbaca_docker_image = docker_image

  }
  runtime {
    docker: docker_image
    memory: "~{memory} GB"
    cpu: cpu
    disks: "local-disk ~{disk_size} SSD"
    preemptible: 0
    maxRetries: 3
  }
}

task prepare_cgmlst_schema {
  input {
    File locus_list
    String docker_image = "ummidock/chewbbaca:2.8.5"
    Int memory = 32
    Int cpu = 8
    Int disk_size = 100


  }
  command <<<
  echo "cat ~{locus_list}"
  cat ~{locus_list}

  #awk '{ print $2 }' ~{locus_list}  >  file_column2.txt
  #echo "cat file_column2.txt"
  #cat file_column2.txt
  readarray -t column2 < ~{locus_list}
  mkdir -p bigsdb_schema

  for loci in ${column2[@]}
  do
  wget "bigsdb.pasteur.fr/cgi-bin/bigsdb/bigsdb.pl?db=pubmlst_diphtheria_seqdef&page=downloadAlleles&locus=$loci" --referer="bigsdb.pasteur.fr/cgi-bin/bigsdb/" -O $loci.fasta
  mv $loci.fasta bigsdb_schema
  done

  ls bigsdb_schema


  chewBBACA.py PrepExternalSchema -i bigsdb_schema -o schema/schema_seed --cpu 6


  zip -r cgmlst.zip *

  ls>ls.txt

  >>>
  output {
    File chewbbaca_test = "ls.txt"
    File cgmlst_zip = "cgmlst.zip"
    String chewbbaca_docker_image = docker_image

  }
  runtime {
    docker: docker_image
    memory: "~{memory} GB"
    cpu: cpu
    disks: "local-disk ~{disk_size} SSD"
    preemptible: 0
    maxRetries: 3
  }
}
