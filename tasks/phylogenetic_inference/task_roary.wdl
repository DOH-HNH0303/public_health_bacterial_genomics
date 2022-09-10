version 1.0

task roary {
  input {
    Array[File] prokka_gff
    Array[String] samplename
    String cluster_name
    String docker_image = "quay.io/staphb/ksnp3:3.1"#"staphb/roary:3.13.01"
    Int memory = 8
    Int cpu = 4
    Int disk_size = 100
  }
  command <<<

  roary -e --mafft -p 8 ~{prokka_gff}

  ls
  ls>ls.txt


  >>>
  output {
    File roary_test = "ls.txt"
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
