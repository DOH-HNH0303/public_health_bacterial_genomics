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
    String docker_image = "broadinstitute/terra-tools:tqdm"
    String samplename
    Int mem_size_gb = 8
    Int CPUs = 4
    File?    tblastn_dt_omega_report
    File?    tblastn_dt_beta_report
    File?    tblastn_dt_beta_homologue_report
  }
  command <<<
  ls>list.txt

  if [ -s ~{tblastn_dt_omega_report} ]
    then
      echo "~{tblastn_dt_omega_report} not empty"
      head -n +1 ~{tblastn_dt_omega_report} | awk '{print $11}' >P00587_EVALUE
      head -n +1 ~{tblastn_dt_omega_report} | awk '{print $12}' >P00587_BITSCORE
  else
      echo "~{tblastn_dt_omega_report} empty"
      echo "negative" >P00587_RESULT
  fi

  if [ -s ~{tblastn_dt_beta_report} ]
    then
      echo "~{tblastn_dt_beta_report} not empty"
      head -n +1 ~{tblastn_dt_beta_report} | awk '{print $11}' >P00588_EVALUE
      head -n +1 ~{tblastn_dt_beta_report} | awk '{print $12}' >P00588_BITSCORE
  else
      echo "~{tblastn_dt_beta_report} empty"
      echo "negative" >P00588_RESULT
  fi

  if [ -s ~{tblastn_dt_beta_homologue_report} ]
    then
      echo "~{tblastn_dt_beta_homologue_report} not empty"
      head -n +1 ~{tblastn_dt_beta_homologue_report} | awk '{print $11}' >P00589_EVALUE
      head -n +1 ~{tblastn_dt_beta_homologue_report} | awk '{print $12}' >P00589_BITSCORE
  else
      echo "~{tblastn_dt_beta_homologue_report} empty"
      echo "negative" >P00589_RESULT
  fi

  python <<CODE
  dt_array=["P00587_EVALUE", "P00588_EVALUE", "P00589_EVALUE"]
  name_array=["dt_omega", "dt_beta_EVAL", "dt_beta_homologue_EVAL"]

  for i in range(len(dt_array)):
    with open(dt_array[i], 'r') as file:
        data = float(file.read().replace('\n', ''))

        if data <=0.01:
          text="possible homolog"

          if data <=1e-50:
            text="positive"

          new_file="~{samplename}"+"_"+name_array[i]+"_RESULT"
          f = open(new_file, "w")

  CODE


  >>>
  output {
    String dt_omega =read_string("~{samplename}_dt_omega_RESULT")
    String dt_beta =read_string("~{samplename}_dt_beta_RESULT")
    String dt_beta_homologue =read_string("~{samplename}_dt_beta_homologue_RESULT")
    Float dt_omega_evalue =read_float("P00587_EVALUE")
    Float dt_beta_evalue =read_float("P00588_EVALUE")
    Float dt_beta_homologue_evalue =read_float("P00589_EVALUE")

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
