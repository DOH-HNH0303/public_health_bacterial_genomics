version 1.0

task bwa_pe_ref_based {
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

task bwa_pe_de_novo {
  input {
    String  id
    File    assembly_fasta
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
    bwa mem -t 4 ${reference_seq} ${assembly_fasta} >${id}_de_novo.sam

    cat DATE>bwa_from_de_novo_software.txt
    echo -e "docker image:\t${docker_image}">>bwa_from_de_novo_software.txt
    echo -e "docker image platform:">>bwa_from_de_novo_software.txt
    uname -a>>bwa_from_de_novo_software.txt
    echo -e "main tool used:">>bwa_from_de_novo_software.txt
    echo -e "\tBWA\t$bwa_v\t\ta program for aligning sequencing reads against a large reference genome">>bwa_from_de_novo_software.txt
    echo -e "licenses available at:">>bwa_from_de_novo_software.txt
    echo -e "\thttps://github.com/lh3/bwa/blob/master/COPYING">>bwa_from_de_novo_software.txt
    printf '%100s\n' | tr ' ' ->>bwa_from_de_novo_software.txt
    dpkg -l>>bwa_from_de_novo_software.txt

  }

  output {
    File    samfile="${id}_de_novo.sam"
    File	image_software="bwa_from_de_novo_software.txt"
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

task sam_to_bam {

  input {
    String    id
    File      samfile
    String    base=basename(samfile, ".sam")
    Int?      cpus = 4
    String      memory = "8 GB"
    String  docker_image="staphb/samtools:1.12"
  }

  command {
    date | tee DATE
    samtools --version | head -n1 | tee VERSION
    samtools_v=$(cat VERSION)


    samtools view -S -b ${samfile}>${id}.bam
    samtools sort ${id}.bam -o ${id}.sorted.bam
    samtools index ${id}.sorted.bam

    cat DATE>sam_to_bam_software.txt
    echo -e "docker image:\t${docker_image}">>sam_to_bam_software.txt
    echo -e "docker image platform:">>sam_to_bam_software.txt
    uname -a>>sam_to_bam_software.txt
    echo -e "main tool used:">>sam_to_bam_software.txt
    echo -e "\tSamtools\t$samtools_v\t\ta suite of programs for interacting with high-throughput sequencing data">>sam_to_bam_software.txt
    echo -e "licenses available at:">>sam_to_bam_software.txt
    echo -e "\thttps://github.com/samtools/samtools/blob/develop/LICENSE">>sam_to_bam_software.txt
    printf '%100s\n' | tr ' ' ->>sam_to_bam_software.txt
    dpkg -l>>sam_to_bam_software.txt
  }

  output {
    File    bamfile="${id}.bam"
    File	sorted_bam="${id}.sorted.bam"
    File	indexed_bam="${id}.sorted.bam.bai"
    File	image_software="sam_to_bam_software.txt"
    String     version       = read_string("VERSION")
  }

  runtime {
    docker:       "${docker_image}"
    memory:       "${memory}"
    cpu:          cpus
    disks:        "local-disk 100 SSD"
    preemptible:  1
    continueOnReturnCode: "True"
  }
}

task bcftools_consensus {

  input {
    String    id
    File      sorted_bam
    File      reference_seq
    String    base=basename(sorted_bam, ".sorted.bam")
    Int?      cpus = 4
    String      memory = "8 GB"
    String  docker_image="staphb/bcftools:1.14"
    Int         indelgap = "5"

  }


  command {
    date | tee DATE
    bcftools version | head -n1 | tee BCF_VERSION
    bcftools_v=$(cat BCF_VERSION)

    # call variants
    bcftools mpileup -Ou -f ${reference_seq} ${sorted_bam} | bcftools call -mv -Oz -o ${base}_variants.vcf.gz

    bcftools index ${base}_variants.vcf.gz

    # normalize indels
    bcftools norm -f ${reference_seq} ${base}_variants.vcf.gz -Ob -o ${base}_norm_indels.norm.bcf

    # filter adjacent indels within X-bp
    bcftools filter --IndelGap ${indelgap} ${base}_norm_indels.norm.bcf -Ob -o ${base}_filtered_norm_indels.norm.flt-indels.bcf

    # apply variants to create consensus sequence
    cat ${reference_seq} | bcftools consensus ${base}_variants.vcf.gz > ${base}_consensus.fa

    cat DATE>consensus_software.txt
    echo -e "docker image:\t${docker_image}">>bcftools_consensus_software.txt
    echo -e "docker image platform:">>bcftools_consensus_software.txt
    uname -a>>bcftools_consensus_software.txt
    echo -e "main tool used:">>bcftools_consensus_software.txt
    echo -e "\tbcftools\t$bcftools_v\t\ta set of utilities that manipulate variant calls in the Variant Call Format (VCF) and its binary counterpart BCF">>bcftools_consensus_software.txt
    echo -e "licenses available at:">>bcftools_consensus_software.txt
    echo -e "\thttps://github.com/samtools/bcftools/blob/develop/LICENSE">>consensus_software.txt
    printf '%100s\n' | tr ' ' ->>bcftools_consensus_software.txt
    dpkg -l>>bcftools_consensus_software.txt

  }

  output {

    #File      sample_variants = "${id}.variants.tsv"
    File      consensus_seq = "${base}_consensus.fa"
    File      consensus_variants = "${base}_variants.vcf.gz"
    String     version = read_string("BCF_VERSION")
    File	image_software="bcftools_consensus_software.txt"
    #String     variant_num       = read_string("VARIANT_NUM")
  }

  runtime {
    docker:       "${docker_image}"
    memory:       "${memory}"
    cpu:          cpus
    disks:        "local-disk 100 SSD"
    preemptible:  1
  }
  }
task stats_n_coverage {

  input {
    File        bamfile
    String      samplename
  }

  command{
    date | tee DATE
    samtools --version | head -n1 | tee VERSION

    samtools stats ${bamfile} > ${samplename}.stats.txt

    samtools coverage ${bamfile} -m -o ${samplename}.cov.hist
    samtools coverage ${bamfile} -o ${samplename}.cov.txt
    samtools flagstat ${bamfile} > ${samplename}.flagstat.txt

    coverage=$(cut -f 6 ${samplename}.cov.txt | tail -n 1)
    depth=$(cut -f 7 ${samplename}.cov.txt | tail -n 1)
    meanbaseq=$(cut -f 8 ${samplename}.cov.txt | tail -n 1)
    meanmapq=$(cut -f 9 ${samplename}.cov.txt | tail -n 1)

    if [ -z "$coverage" ] ; then coverage="0" ; fi
    if [ -z "$depth" ] ; then depth="0" ; fi
    if [ -z "$meanbaseq" ] ; then meanbaseq="0" ; fi
    if [ -z "$meanmapq" ] ; then meanmapq="0" ; fi

    echo $coverage | tee COVERAGE
    echo $depth | tee DEPTH
    echo $meanbaseq | tee MEANBASEQ
    echo $meanmapq | tee MEANMAPQ
  }

  output {
    String     date = read_string("DATE")
    String     samtools_version = read_string("VERSION")
    File       stats = "${samplename}.stats.txt"
    File       cov_hist = "${samplename}.cov.hist"
    File       cov_stats = "${samplename}.cov.txt"
    File       flagstat = "${samplename}.flagstat.txt"
    Float      coverage = read_string("COVERAGE")
    Float      depth = read_string("DEPTH")
    Float      meanbaseq = read_string("MEANBASEQ")
    Float      meanmapq = read_string("MEANMAPQ")
  }

  runtime {
    docker:       "staphb/samtools:1.10"
    memory:       "8 GB"
    cpu:          2
    disks:        "local-disk 100 SSD"
    preemptible:  0
    maxRetries:   3
  }
}

task assembly_qc {

  input {
    File        assembly_fasta
    File    reference_seq
    String      memory = "2 GB"
    String  docker_image="theiagen/utility:1.1"

  }

  command{
    # capture date and version
    ls
    date | tee DATE

    num_N=$( grep -v ">" ~{assembly_fasta} | grep -o 'N' | wc -l )
    if [ -z "$num_N" ] ; then num_N="0" ; fi
    echo $num_N | tee NUM_N

    num_ACTG=$( grep -v ">" ~{assembly_fasta} | grep -o -E "C|A|T|G" | wc -l )
    if [ -z "$num_ACTG" ] ; then num_ACTG="0" ; fi
    echo $num_ACTG | tee NUM_ACTG

    # calculate percent coverage (Wu Han-1 genome length: 29903bp)

    ref_genome_len=$(grep -v ">" ~{reference_seq} | grep -o -E '[A-Z]' | wc -l)
    echo $ref_genome_len
    python3 -c "print ( round( ($num_ACTG / $ref_genome_len ) * 100, 2 ) )" | tee PERCENT_REF_COVERAGE

    num_degenerate=$( grep -v ">" ~{assembly_fasta} | grep -o -E "B|D|E|F|H|I|J|K|L|M|O|P|Q|R|S|U|V|W|X|Y|Z" | wc -l )
    if [ -z "$num_degenerate" ] ; then num_degenerate="0" ; fi
    echo $num_degenerate | tee NUM_DEGENERATE

    num_total=$( grep -v ">" ~{assembly_fasta} | grep -o -E '[A-Z]' | wc -l )
    if [ -z "$num_total" ] ; then num_total="0" ; fi
    echo $num_total | tee NUM_TOTAL

    cat DATE>assembly_qc_software.txt
    echo -e "docker image:\t${docker_image}">>assembly_qc_software.txt
    echo -e "docker image platform:">>assembly_qc_software.txt
    uname -a>>assembly_qc_software.txt
    printf '%100s\n' | tr ' ' ->>assembly_qc_software.txt
    dpkg -l>>assembly_qc_software.txt
  }

  output {
    Int       assembly_number_N = read_string("NUM_N")
    Int       assembly_number_ATCG = read_string("NUM_ACTG")
    Int       assembly_number_Degenerate = read_string("NUM_DEGENERATE")
    Int       assembly_number_Total = read_string("NUM_TOTAL")
    #Float     #assembly_percent_reference_coverage = read_string("PERCENT_REF_COVERAGE")
    File	image_software="assembly_qc_software.txt"
  }

  runtime {
    docker:       "${docker_image}"
    memory:       "2 GB"
    cpu:          1
    disks:        "local-disk 100 SSD"
    preemptible:  0
  }
}



task bowtie2_pe_ref_based {
  input {
    String  id
    File    read1_trim
    File    read2_trim
    File    reference_seq
    Int?      cpus = 4
    String      memory = "16 GB"
    String  docker_image="staphb/bowtie2:2.4.5"
  }

  command {
    date | tee DATE
    bwa --version | head -n1 | tee VERSION
    bwa_v=$(cat VERSION)
    bowtie2-build ~{reference_seq} /index/ref_seq
    bowtie2 -x /index/ref_seq -1 ~{read1_trim} -2 ~{read2_trim}
    bowtie2-inspect --summary /index/lambda_virus
    samtools sort -T /tmp/aln.sorted -o ~{id}_aln.sorted.bam ~{id}_aln.bam
    samtools index ~{id}_aln.sorted.bam

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

    ls

  }

  output {
    File    bam ="~{id}_aln.bam"
    File    sorted_bam ="~{id}_aln.sorted.bam"
    File    indexed_bam ="~{id}_aln.sorted.bam.bai"
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
