version 1.0

task trimmomatic_pe {
  input {
    File read1
    File read2
    String samplename
    String docker = "quay.io/staphb/trimmomatic:0.39"
    Int? trimmomatic_minlen = 75
    Int? trimmomatic_window_size = 10
    Int? trimmomatic_quality_trim_score = 20
    Int? threads = 4
  }
  command <<<
    # date and version control
    date | tee DATE
    trimmomatic -version > VERSION && sed -i -e 's/^/Trimmomatic /' VERSION

    trimmomatic PE \
    -threads ~{threads} \
    ~{read1} ~{read2} \
    -baseout ~{samplename}.fastq.gz \
    SLIDINGWINDOW:~{trimmomatic_window_size}:~{trimmomatic_quality_trim_score} \
    MINLEN:~{trimmomatic_minlen} > ~{samplename}.trim.stats.txt

    cat DATE>trimmomatic_pe_software.txt
    echo -e "docker image:\t${docker}">>trimmomatic_pe_software.txt
    echo -e "docker image platform:">>trimmomatic_pe_software.txt
    uname -a>>trimmomatic_pe_software.txt
    echo -e "main tool used:">>trimmomatic_pe_software.txt
    echo -e "\tTrimmomatic\t$trim_v\t\ta program for performs which preforms a variety of useful trimming tasks for illumina paired-end and single ended data">>trimmomatic_pe_software.txt
    echo -e "licenses available at:">>trimmomatic_pe_software.txt
    echo -e "\thttps://github.com/timflutre/trimmomatic/blob/master/distSrc/LICENSE">>trimmomatic_pe_software.txt
    printf '%100s\n' | tr ' ' ->>trimmomatic_pe_software.txt
    dpkg -l>>trimmomatic_pe_software.txt
  >>>
  output {
    File read1_trimmed = "~{samplename}_1P.fastq.gz"
    File read2_trimmed = "~{samplename}_2P.fastq.gz"
    File trimmomatic_stats = "~{samplename}.trim.stats.txt"
    String version = read_string("VERSION")
    String pipeline_date = read_string("DATE")
    File	image_software="trimmomatic_pe_software.txt"
  }
  runtime {
    docker: "~{docker}"
    memory: "8 GB"
    cpu: 4
    disks: "local-disk 100 SSD"
    preemptible:  0
  }
}

task trimmomatic_se {
  input {
    File read1
    String samplename
    String docker="quay.io/staphb/trimmomatic:0.39"
    Int? trimmomatic_minlen = 25
    Int? trimmomatic_window_size=4
    Int? trimmomatic_quality_trim_score=30
    Int? threads = 4
  }
  command <<<
    # date and version control
    date | tee DATE
    trimmomatic -version > VERSION && sed -i -e 's/^/Trimmomatic /' VERSION

    trimmomatic SE \
    -threads ~{threads} \
    ~{read1} \
    ~{samplename}_trimmed.fastq.gz \
    SLIDINGWINDOW:~{trimmomatic_window_size}:~{trimmomatic_quality_trim_score} \
    MINLEN:~{trimmomatic_minlen} > ~{samplename}.trim.stats.txt
  >>>
  output {
    File read1_trimmed = "${samplename}_trimmed.fastq.gz"
    File trimmomatic_stats = "${samplename}.trim.stats.txt"
    String version = read_string("VERSION")
    String pipeline_date = read_string("DATE")
  }
  runtime {
    docker: "~{docker}"
    memory: "8 GB"
    cpu: 4
    disks: "local-disk 100 SSD"
    preemptible: 0
  }
}
