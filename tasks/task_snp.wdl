version 1.0

task cfsan_snp_pipe {
  input {
    String  id
    File    read1_trim
    File    read2_trim
    File    reference_seq
    Int?      cpus = 4
    String      memory = "16 GB"
    String  docker_image="staphb/bwa:0.7.17"
  }

  command {
    date | tee DATE
    bwa --version | head -n1 | tee VERSION
    bwa_v=$(cat VERSION)
    bwa index ${reference_seq}
    bwa mem -t 4 ${reference_seq} ${read1_trim} ${read2_trim}>${id}_ref_based.sam

    cat DATE>bwa_pe_ref_based_software.txt
    echo -e "docker image:\t${docker_image}">>bwa_pe_ref_based_software.txt
    echo -e "docker image platform:">>bwa_pe_ref_based_software.txt
    uname -a>>bwa_pe_ref_based_software.txt
    echo -e "main tool used:">>bwa_pe_ref_based_software.txt
    echo -e "\tBWA\t$bwa_v\t\ta program for aligning sequencing reads against a large reference genome">>bwa_pe_ref_based_software.txt
    echo -e "licenses available at:">>bwa_pe_ref_based_software.txt
    echo -e "\thttps://github.com/lh3/bwa/blob/master/COPYING">>bwa_pe_ref_based_software.txt
    printf '%100s\n' | tr ' ' ->>bwa_pe_ref_based_software.txt
    dpkg -l>>bwa_pe_ref_based_software.txt

  }

  output {
    File    samfile="${id}_ref_based.sam"
    File	image_software="bwa_pe_ref_based_software.txt"
    String     version       = read_string("VERSION")
  }

  runtime {
    docker:       "${docker_image}"
    memory:       "${memory}"
    cpu:          cpus
    disks:        "local-disk 100 SSD"
    preemptible:  0
    continueOnReturnCode: "True"
  }
}
