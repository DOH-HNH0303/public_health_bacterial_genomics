version 1.0

workflow basespace_fetch_from_appsession {

  input {
    String    sample_name
    File    run_zip

  }

  call fetch_bs {
    input:
      sample=sample_name,
      run_zip=run_zip
  }

  output {
    File    directory   =fetch_bs.directory
    File    read1   =fetch_bs.read1
    File    read2   =fetch_bs.read2
  }
}

task fetch_bs {

  input {
    String    sample
    String    base_sample= basename(sample, "_L1") 
    File    run_zip
    String    folder_name = basename(run_zip, ".zip") 
  }

  command <<<

    ls ../
    ls /data

    echo ~{folder_name}
    
    unzip ~{run_zip} ~{sample}*_R1_*.fastq.gz
    unzip ~{run_zip} ~{sample}*_R2_*.fastq.gz
    


    mv -f ~{sample}*_R1_*.fastq.gz ~{sample}_R1.fastq.gz
    
    mv -f ~{sample}*_R2_*.fastq.gz ~{sample}_R2.fastq.gz    
    rm -r ~{run_zip}

    ls -R >> directory.txt


  >>>

  output {
    File    directory="directory.txt"
    File    read1="${sample}_R1.fastq.gz"
    File    read2="${sample}_R2.fastq.gz"
  }

  runtime {
    docker:       "theiagen/utility:1.2"
    memory:       "8 GB"
    cpu:          2
    disks:        "local-disk 100 SSD"
    preemptible:  1
  }
}

