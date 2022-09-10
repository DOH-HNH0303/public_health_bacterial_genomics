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
  touch "test.tsv"
  echo -e " to test.tsv"
  echo -e "~{sep='\t' ref_genomes}" >test.tsv
  echo -e "~{sep='\t' ref_names}" >>test.tsv
  cat test.tsv

  cat test.tsv | python ~{transpose_py}>transposed_ref.tsv

  echo "cat transposed"
  cat transposed_ref.tsv

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
  touch ksnp3_input.tsv
  for index in ${!assembly_array[@]}; do
    assembly=${assembly_array[$index]}
    samplename=${samplename_array[$index]}
    echo -e "${assembly}\t${samplename}" >> ksnp3_input.tsv
  done
  cat transposed_ref.tsv>>ksnp3_input.tsv

  cat ksnp3_input.tsv

  kSNP3 -in ksnp3_input.tsv -outdir ksnp3 -k ~{kmer_size} -core -vcf
  cat NameErrors.txt
  ls >ls.txt
  ls
  echo ""
  ls /data
  echo ""
  ls /data >data_ls.txt
  ls ksnp3
  # rename ksnp3 outputs with cluster name
  mv ksnp3/core_SNPs_matrix.fasta ksnp3/~{cluster_name}_core_SNPs_matrix.fasta
  mv ksnp3/tree.core.tre ksnp3/~{cluster_name}_core.tree
  mv ksnp3/VCF.*.vcf ksnp3/~{cluster_name}_core.vcf
  mv ksnp3/SNPs_all_matrix.fasta ksnp3/~{cluster_name}_pan_SNPs_matrix.fasta
  mv ksnp3/tree.parsimony.tre ksnp3/~{cluster_name}_pan_parsiomony.tree

  # run ksnp3 on input assemblies



  >>>
  output {
    #File ksnp3_input = "ksnp3_input.tsv"
    File ksnp3_test = "test.tsv"
    #File ref_transposed_tsv = "transposed_ref.tsv"
    #File ref_tsv = "ref.tsv"
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
