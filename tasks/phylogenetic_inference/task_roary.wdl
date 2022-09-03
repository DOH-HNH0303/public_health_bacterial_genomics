version 1.0

task roary {
  input {
    Array[File] prokka_gff
    Array[String] samplename
    String cluster_name
    Int kmer_size = 19
    String docker_image = "staphb/roary:3.13.01"
    Int memory = 8
    Int cpu = 4
    Int disk_size = 100
  }
  command <<<
  gff_array=(~{sep=' ' prokka_gff})
  gff_array_len=$(echo "${#prokka_gff[@]}")
  samplename_array=(~{sep=' ' samplename})
  samplename_array_len=$(echo "${#samplename_array[@]}")

  # Ensure assembly, and samplename arrays are of equal length
  if [ "$gff_array_len" -ne "$samplename_array_len" ]; then
    echo "GFF array (length: $gff_array_len) and samplename array (length: $samplename_array_len) are of unequal length." >&2
    exit 1
  fi

  # create file of filenames for kSNP3 input
  touch ksnp3_input.tsv
  for index in ${!gff_array[@]}; do
    gff=${gff_array[$index]}
    samplename=${samplename_array[$index]}
    echo -e "${gff}\t${samplename}" >> ksnp3_input.tsv
  done
  cat ksnp3_input.tsv
  # run ksnp3 on input assemblies
  roary ~{prokka_gff}
  kSNP3 -in ksnp3_input.tsv -outdir ksnp3 -k ~{kmer_size} -core -vcf
  ls >ls.txt
  ls
  echo ""
  ls /data
  echo ""
  ls /data >data_ls.txt
  ls ksnp3
  # rename ksnp3 outputs with cluster name
  mv ksnp3/core_SNPs_matrix.fasta ksnp3/~{cluster_name}_core_SNPs_matrix.fasta
  mv ksnp3/tree.core.tre ksnp3/~{cluster_name}_core.tree
  mv ksnp3/VCF.*.vcf ksnp3/~{cluster_name}_core.vcf
  mv ksnp3/SNPs_all_matrix.fasta ksnp3/~{cluster_name}_pan_SNPs_matrix.fasta
  mv ksnp3/tree.parsimony.tre ksnp3/~{cluster_name}_pan_parsiomony.tree


  >>>
  output {
    File ksnp3_input = "ksnp3_input.tsv"
    File ksnp3_core_matrix = "ksnp3/${cluster_name}_core_SNPs_matrix.fasta"
    File ksnp3_core_tree = "ksnp3/${cluster_name}_core.tree"
    File ksnp3_core_vcf = "ksnp3/${cluster_name}_core.vcf"
    File ksnp3_pan_matrix = "ksnp3/~{cluster_name}_pan_SNPs_matrix.fasta"
    File ksnp3_pan_parsimony_tree = "ksnp3/~{cluster_name}_pan_parsiomony.tree"
    Array[File] ksnp_outs = glob("ksnp3/*")

    String ksnp3_docker_image = docker_image
  }
  runtime {
    docker: docker_image
    memory: "~{memory} GB"
    cpu: cpu
    disks: "local-disk ~{disk_size} SSD"
    preemptible: 0
    maxRetries: 3
  }
}