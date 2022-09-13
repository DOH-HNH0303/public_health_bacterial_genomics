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

task get_dt_results {
  input {
    String docker_image
    String samplename
    Int mem_size_gb = 8
    Int CPUs = 4
    Float? dt_omega_EVAL
    Float? dt_beta_EVAL
    Float? dt_beta_homologue_EVAL
  }
  command <<<
  ls>list.txt
  python <<CODE
  dt_array=["~{dt_omega_EVAL}", "~{dt_beta_EVAL}", "~{dt_beta_homologue_EVAL}"]
  name_array=["dt_omega", "dt_beta_EVAL", "dt_beta_homologue_EVAL"]

  for i in range(len(dt_array)):

    if dt_array[i] <=0.01:
      text="possible homolog"

      if dt_array[i] <=1e-50:
        text="positive"

      new_file=~{samplename}+"_"+name_array[i]+"_RESULT"
      f = open(new_file, "w")

  CODE


  >>>
  output {
    String dt_omega =read_string("~{samplename}_dt_omega_RESULT")
    String dt_beta =read_string("~{samplename}_dt_beta_RESULT")
    String dt_beta_homologue =read_string("~{samplename}_dt_beta__homologue_RESULT")

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
