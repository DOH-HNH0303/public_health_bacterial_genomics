version 1.0

task ksnp3 {
  input {
    Array[File] assembly_fasta
    Array[String] samplename
    String cluster_name
    File transpose_py
    Int kmer_size = 19
    String docker_image = "quay.io/staphb/ksnp3:3.1"
    Int memory = 8
    Int cpu = 4
    Int disk_size = 100
    Array[File] ref_genomes
    Array[String] ref_names
    Int ref_genomes_len = length(ref_genomes)
    Int ref_names_len = length(ref_names)
    Array[Array[String]] array_refs



  }
  command <<<
  echo "~{sep=' ' ref_genomes}"


  ref_genome_array=("~{sep=' ' ref_genomes}")
  cat ~{transpose_py}

  #cat ref.tsv | python3 transpose.py>transposed_ref.tsv
  cat~{write_tsv(array_refs)} | python ~"transpose_py">transposed_ref.tsv
  mv ~{write_tsv(array_refs)} "ref.tsv"
  echo $ref_genome_array
 #line 27
  ref_name_array="~{sep=' ' ref_names})"

  echo "ref_name_array"
  echo $ref_name_array
  echo "ref_genomes len, ref_names len"
  echo ~{ref_genomes_len} ~{ref_names_len}

  if [ ~{ref_genomes_len} -ne ~{ref_names_len} ]; then
    echo "Reference arrays are of unequal length." >&2
    exit 1
  fi

  assembly_array=(~{sep=' ' assembly_fasta})
  assembly_array_len=$(echo "${#assembly_array[@]}")
  echo "assembly array"
  echo $assembly_array
  samplename_array=(~{sep=' ' samplename})
  samplename_array_len=$(echo "${#samplename_array[@]}")
  echo $assembly_array_len $samplename_array_len

  # Ensure assembly, and samplename arrays are of equal length
  if [ "$assembly_array_len" -ne "$samplename_array_len" ]; then
    echo "Assembly array (length: $assembly_array_len) and samplename array (length: $samplename_array_len) are of unequal length." >&2
    exit 1
  fi

  # create file of filenames for kSNP3 input
  touch ksnp3_input.tsv
  for index in ${!assembly_array[@]}; do
    assembly=${assembly_array[$index]}
    samplename=${samplename_array[$index]}
    echo -e "${assembly}\t${samplename}" >> ksnp3_input.tsv
  done

  cat ksnp3_input.tsv
  # run ksnp3 on input assemblies



  >>>
  output {
    File ksnp3_input = "ksnp3_input.tsv"
    File ref_transposed_tsv = "transposed_ref.tsv"
    File ref_tsv = "ref.tsv"
    File ksnp3_core_matrix = "ksnp3/${cluster_name}_core_SNPs_matrix.fasta"
    File ksnp3_core_tree = "ksnp3/${cluster_name}_core.tree"
    File ksnp3_core_vcf = "ksnp3/${cluster_name}_core.vcf"
    File ksnp3_pan_matrix = "ksnp3/~{cluster_name}_pan_SNPs_matrix.fasta"
    File ksnp3_pan_parsimony_tree = "ksnp3/~{cluster_name}_pan_parsiomony.tree"
    Array[File] ksnp_outs = glob("ksnp3/*")

    String ksnp3_docker_image = docker_image

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
