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
  echo " to test.tsv"
  echo "~{sep='\t' ref_genomes}" >test.tsv
  echo "~{sep='\t' ref_names}" >>test.tsv
  cat test.tsv

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
