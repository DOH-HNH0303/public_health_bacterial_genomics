version 1.0

task roary {
  input {
    Array[File] assembly_fasta
    Array[String] samplename
    Array[File] prokka_gff
    String cluster_name
    File transpose_py
    Int kmer_size = 19
    String docker_image = "staphb/roary"
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
  echo -e "~{sep='\t' prokka_gff}"
  ssembly_array=(~{sep=' ' prokka_gff})
  roary -e --mafft -p 8 *.gff

  ls

  >>>
  output {
    #File ksnp3_input = "ksnp3_input.tsv"
    File ksnp3_test = "test.tsv"
    #File ref_transposed_tsv = "transposed_ref.tsv"
    #File ref_tsv = "ref.tsv"


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
