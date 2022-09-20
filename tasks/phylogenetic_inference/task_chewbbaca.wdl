version 1.0

task chewbbaca {
  input {
    Array[File] assembly_fastas
    String cluster_name
    File prodigal_file
    String docker_image = "ummidock/chewbbaca:2.8.5"
    Int memory = 32
    Int cpu = 8
    Int disk_size = 100

  }
  command <<<

  echo ~{cluster_name}
  echo -e "~{sep='\t' assembly_fastas}" >temp.tsv

  touch input.tsv
  assembly_array="(~{sep=' ' assembly_fastas})"
  for item in "${assembly_array[@]}"; do
    echo $item>>input.tsv
  done

  echo "cat input.tsv"
  cat input.tsv

  assembly_array_len=$(echo "${#assembly_arrays[@]}")
  echo "assembly array"
  echo $assembly_array
  echo $assembly_array_len


  #i. Whole Genome Multilocus Sequence Typing (wgMLST) schema creation
  chewBBACA.py CreateSchema -i input.tsv -o . --n Cdip --ptf ~{prodigal_file} --cpu 4

  #ii. Allele call using a cg/wgMLST schema
  #chewBBACA.py AlleleCall -i $assembly_array -g Cdip -o . --cpu 4

  #iii. Determine annotations for loci in the schema
  #chewBBACA.py UniprotFinder -i Cdip -o . --taxa "Corynebacterium diphtheriae" --cpu 4

  #iv. Evaluate wgMLST call quality per genome
  #chewBBACA.py TestGenomeQuality -i Cdip/results_alleles.tsv -n 12 -t 200 -s 5 -o wgmlst_call_quality

  #v. Defining the cgMLST schema
  #chewBBACA.py ExtractCgMLST -i /path/to/AlleleCall/results/results_alleles.tsv -o cgmlst_schema

  ls cgmlst>ls.txt

  >>>
  output {
    File chewbbaca_test = "ls.txt"
    File chewbbaca_test2 = "input.tsv"
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
