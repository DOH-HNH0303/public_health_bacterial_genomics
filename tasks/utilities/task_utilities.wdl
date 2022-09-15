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
      echo "" >P00587_EVALUE
      echo "" >P00587_BITSCORE
  fi

  if [ -s ~{tblastn_dt_beta_report} ]
    then
      echo "~{tblastn_dt_beta_report} not empty"
      head -n +1 ~{tblastn_dt_beta_report} | awk '{print $11}' >P00588_EVALUE
      head -n +1 ~{tblastn_dt_beta_report} | awk '{print $12}' >P00588_BITSCORE
  else
      echo "~{tblastn_dt_beta_report} empty"
      echo "negative" >P00588_RESULT
      echo "" >P00588_EVALUE
      echo "" >P00589_BITSCORE
  fi

  if [ -s ~{tblastn_dt_beta_homologue_report} ]
    then
      echo "~{tblastn_dt_beta_homologue_report} not empty"
      head -n +1 ~{tblastn_dt_beta_homologue_report} | awk '{print $11}' >P00589_EVALUE
      head -n +1 ~{tblastn_dt_beta_homologue_report} | awk '{print $12}' >P00589_BITSCORE
  else
      echo "~{tblastn_dt_beta_homologue_report} empty"
      echo "negative" >P00589_RESULT
      echo "" >P00589_EVALUE
      echo "" >P00589_BITSCORE
  fi


  python <<CODE
  dt_array=["P00587", "P00588", "P00589"]
  file_array=["~{tblastn_dt_omega_report}", "~{tblastn_dt_beta_report}", "~{tblastn_dt_beta_homologue_report}"]
  for i in range(len(file_array)):

    with open(file_array[i], 'r') as file:
      count = 1
      for line in file:
        count += 1
        if count==2:
          data_array = line.split()
          eval=data_array[-2]
          eval_name=dt_array[i]+"_EVALUE"
          f = open(eval_name, "w")
          f.write(eval)
          f.close()

          bitscore=data_array[-1]
          bitscore_name=dt_array[i]+"_BITSCORE"
          f = open(bitscore_name, "w")
          f.write(bitscore)
          f.close()

          if float(eval)<=1e-50:
             text="positive"
          elif float(data) <=0.01:
             text="possible homolog"
          else:
             text="negative"

          result_name=dt_array[i]+"_RESULT"
          f = open(result_name, "w")
          f.write(text)
          f.close()

  CODE


  >>>
  output {
    String dt_omega =read_string("~{samplename}_dt_omega_RESULT")
    String dt_beta =read_string("~{samplename}_dt_beta_RESULT")
    String dt_beta_homologue =read_string("~{samplename}_dt_beta_homologue_RESULT")
    Float dt_omega_evalue =read_float("P00587_EVALUE")
    Float dt_beta_evalue =read_float("P00588_EVALUE")
    Float dt_beta_homologue_evalue =read_float("P00589_EVALUE")
    Float dt_omega_bitscore =read_float("P00587_BITSCORE")
    Float dt_beta_bitscore =read_float("P00588_BITSCORE")
    Float dt_beta_homologue_bitscore =read_float("P00589_BITSCORE")

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
