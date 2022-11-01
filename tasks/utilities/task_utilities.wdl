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
  python <<CODE
  print("test 1")
  dt_array=["P00587", "P00588", "P00589"]
  file_array=["~{tblastn_dt_omega_report}", "~{tblastn_dt_beta_report}", "~{tblastn_dt_beta_homologue_report}"]
  for i in range(len(file_array)):

    with open(file_array[i], 'r') as file:
      count = 0
      print("test 2")
      for line in file:
        count += 1
        print("test 3")
        if count==1:
          print("test 4")
          data_array = line.split()
          eval=data_array[-2]
          bitscore=data_array[-1]
          print("test 5")

          if float(eval)<=1e-50:
             text="positive"
             print("test 6")
          elif float(data) <=0.01:
             text="possible homolog"
             print("test 7")
          else:
             text="negative"
             print("test 8")
      print("test 9")
      if count==0:
        text="negative"
        eval="NULL"
        bitscore="NULL"
        print("test 10")

    print("test 11")
    eval_name=dt_array[i]+"_EVALUE"
    print("test 11.2")
    f = open(eval_name, "w")
    print("test 11.3")
    f.write(eval)
    print("test 11.4")
    f.close()

    print("test 12")
    bitscore_name=dt_array[i]+"_BITSCORE"
    f = open(bitscore_name, "w")
    f.write(bitscore)
    f.close()

    print("test 13")
    result_name=dt_array[i]+"_RESULT"
    f = open(result_name, "w")
    f.write(text)
    f.close()

  CODE
  ls


  >>>
  output {
    String dt_omega =read_string("P00587_RESULT")
    String dt_beta =read_string("P00588_RESULT")
    String dt_beta_homologue =read_string("P00589_RESULT")
    String? dt_omega_evalue =read_string("P00587_EVALUE")
    String? dt_beta_evalue =read_string("P00588_EVALUE")
    String? dt_beta_homologue_evalue =read_string("P00589_EVALUE")
    String? dt_omega_bitscore =read_string("P00587_BITSCORE")
    String? dt_beta_bitscore =read_string("P00588_BITSCORE")
    String? dt_beta_homologue_bitscore =read_string("P00589_BITSCORE")

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

task join_genus_species {
  input {
    String genus
    String species
  }
  command <<< >>>
  output {
    String genus_species = "~{genus} ~{species}"
  }
  runtime {
    docker: "amancevice/pandas:1.4.2-alpine"
    memory: "~{mem_size_gb} GB"
    cpu: 4
    disks: "local-disk 100 SSD"
    preemptible: 0
  }
}
