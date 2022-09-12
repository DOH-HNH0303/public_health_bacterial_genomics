version 1.0

task python {
  input {
    File kraken2_report
    String docker_image = "amancevice/pandas:1.4.2-alpine"
    Int mem_size_gb = 8
    Int CPUs = 4
  }
  command <<<
  ls>list.txt
  head ~{kraken2_report}


  >>>
  output {
    File list = "list.txt"
    String python_docker_image = docker_image
  }
  runtime {
    docker: docker_image
    memory: "~{mem_size_gb} GB"
    cpu: CPUs
    disks: "local-disk 100 SSD"
    preemptible: 0
  }
}

task wget_dt {
  input {
    String docker_image
    Int mem_size_gb = 8
    Int CPUs = 4
  }
  command <<<
  ls>list.txt
  hwget https://rest.uniprot.org/uniprotkb/P00587.fasta
  wget https://rest.uniprot.org/uniprotkb/P00588.fasta
  wget https://rest.uniprot.org/uniprotkb/P00589.fasta


  >>>
  output {
    File dt_omega = "P00587.fasta"
    File dt_beta = "P00588.fasta"
    File dt_beta_homologue = "P00587.fasta"
    String wget_dt_docker_image = docker_image
  }
  runtime {
    docker: docker_image
    memory: "~{mem_size_gb} GB"
    cpu: CPUs
    disks: "local-disk 100 SSD"
    preemptible: 0
  }
}
