version 1.0

task ksnp3 {
  input {
    Array[File] assembly_fasta
    Array[String] samplename
    String cluster_name
    Int kmer_size = 19
    String docker_image = "quay.io/staphb/ksnp3:3.1"
    Int memory = 8
    Int cpu = 4
    Int disk_size = 100
    Array[File] ref_genomes
    Array[String] ref_names
  }
  command <<<
  echo "~{sep=' ' ref_genomes}"

  ref_genome_array=("~{sep=' ' ref_genomes}")
  echo $ref_genome_array
  ref_genome_array_len=$(echo "${#ref_genome_array[@]}")

  ref_name_array="~{sep=' ' ref_names})"
  ref_name_array_len=$(echo "${#ref_name_array[@]}")
  echo "ref_name_array"
  echo $ref_name_array
  echo "ref_genome len, ref_name len"
  echo $ref_genome_array_len $ref_name_array_len


  >>>
  output {
    File ksnp3_input = "ksnp3_input.tsv"
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
