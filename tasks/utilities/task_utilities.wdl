version 1.0

task python {
  input {
    File kraken2_report
    String docker_image = "amancevice/pandas:alpine"
    Int mem_size_gb = 8
    Int CPUs = 4
  }
  command <<<
  ls>list.txt


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
