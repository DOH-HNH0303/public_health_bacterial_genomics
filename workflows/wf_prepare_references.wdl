version 1.0

import "wf_read_QC_trim.wdl" as read_qc
import "../tasks/assembly/task_shovill.wdl" as shovill
import "../tasks/quality_control/task_quast.wdl" as quast
import "../tasks/quality_control/task_cg_pipeline.wdl" as cg_pipeline
import "../tasks/taxon_id/task_gambit.wdl" as gambit
import "../tasks/task_versioning.wdl" as versioning
import "../tasks/utilities/task_broad_terra_tools.wdl" as terra_tools
import "../tasks/quality_control/task_general_qc.wdl" as general_qc

#Theiagen packages added
import "../tasks/quality_control/task_screen.wdl" as screen
import "../tasks/quality_control/task_busco.wdl" as busco
import "../tasks/gene_typing/task_prokka.wdl" as prokka
import "../tasks/utilities/task_utilities.wdl" as utilities
import "../tasks/task_qc_utils.wdl" as qc
import "../tasks/task_taxon_id.wdl" as taxon_id
import "../tasks/task_denovo_assembly.wdl" as assembly
import "../tasks/task_read_clean.wdl" as read_clean


workflow theiaprok_illumina_pe {
  meta {
    description: "De-novo genome assembly, taxonomic ID, and QC of paired-end bacterial NGS data"
  }
  input {
    String samplename
    String seq_method = "ILLUMINA"
    File read1_raw
    File read2_raw
    String? run_id
    File? taxon_tables
    String terra_project="NA"
    String terra_workspace="NA"

    Int? genome_size
    String? collection_date
    String? originating_lab
    String? city
    String? county
    String? zip
    # by default do not call ANI task, but user has ability to enable this task if working with enteric pathogens or supply their own high-quality reference genome
    Boolean call_ani = false
    Int min_reads = 7472
    Int min_basepairs = 2241820
    Int min_genome_size = 100000
    Int max_genome_size = 18040666
    Int min_coverage = 10
    Int min_proportion = 50
    Boolean call_resfinder = false
    Boolean skip_screen = false
    String wget_dt_docker_image = "inutano/wget:1.20.3-r1"
  }

  call versioning.version_capture{
    input:
  }

  call screen.check_reads as raw_check_reads {
    input:
      read1 = read1_raw,
      read2 = read2_raw,
      min_reads = min_reads,
      min_basepairs = min_basepairs,
      min_genome_size = min_genome_size,
      max_genome_size = max_genome_size,
      min_coverage = min_coverage,
      min_proportion = min_proportion,
      skip_screen = skip_screen
  }
  call taxon_id.kraken2 as kraken2_raw {
    input:
    samplename = samplename,
    read1 = read1_raw,
    read2 = read2_raw
  }
  call read_clean.ncbi_scrub_pe {
    input:
      samplename = samplename,
      read1 = read1_raw,
      read2 = read2_raw
  }
  if (raw_check_reads.read_screen=="PASS") {
    call read_qc.read_QC_trim {
    input:
      samplename = samplename,
      read1_raw = ncbi_scrub_pe.read1_dehosted,
      read2_raw = ncbi_scrub_pe.read2_dehosted
    }

    call screen.check_reads as clean_check_reads {
      input:
        read1 = read_QC_trim.read1_clean,
        read2 = read_QC_trim.read2_clean,
        min_reads = min_reads,
        min_basepairs = min_basepairs,
        min_genome_size = min_genome_size,
        max_genome_size = max_genome_size,
        min_coverage = min_coverage,
        min_proportion = min_proportion,
        skip_screen = skip_screen
    }
    if (clean_check_reads.read_screen=="PASS") {
      call shovill.shovill_pe {
        input:
          samplename = samplename,
          read1_cleaned = read_QC_trim.read1_clean,
          read2_cleaned = read_QC_trim.read2_clean,
          genome_size = select_first([genome_size, clean_check_reads.est_genome_length])
      }
      call quast.quast {
        input:
          assembly = shovill_pe.assembly_fasta,
          samplename = samplename
      }
      call busco.busco {
        input:
          assembly = shovill_pe.assembly_fasta,
          samplename = samplename
      }
      call general_qc.general_qc {
        input:
          assembly_fasta = shovill_pe.assembly_fasta
      }
      call cg_pipeline.cg_pipeline {
        input:
          read1 = read1_raw,
          read2 = read2_raw,
          samplename = samplename,
          genome_length = select_first([genome_size, clean_check_reads.est_genome_length])
      }
      call gambit.gambit {
        input:
          assembly = shovill_pe.assembly_fasta,
          samplename = samplename
      }

      call prokka.prokka {
        input:
          assembly = shovill_pe.assembly_fasta,
          samplename = samplename
      }


  }
  output {
    #Version Captures
    String theiaprok_illumina_pe_version = version_capture.phbg_version
    String theiaprok_illumina_pe_analysis_date = version_capture.date
    #Read Metadata
    String seq_platform = seq_method
    #Sample Screening
    String raw_read_screen = raw_check_reads.read_screen
    String? clean_read_screen = clean_check_reads.read_screen
    #Read QC read_QC_trim.read1_clean
    Int? num_reads_raw1 = read_QC_trim.fastq_scan_raw1
    Int? num_reads_raw2 = read_QC_trim.fastq_scan_raw2
    String? num_reads_raw_pairs = read_QC_trim.fastq_scan_raw_pairs
    String? fastq_scan_version = read_QC_trim.fastq_scan_version
    Int? num_reads_clean1 = read_QC_trim.fastq_scan_clean1
    Int? num_reads_clean2 = read_QC_trim.fastq_scan_clean2
    File? reads_clean1 = read_QC_trim.read1_clean
    File? reads_clean2 = read_QC_trim.read2_clean
    String? num_reads_clean_pairs = read_QC_trim.fastq_scan_clean_pairs
    String? trimmomatic_version = read_QC_trim.trimmomatic_version
    String? trimmomatic_software = read_QC_trim.trimmomatic_pe_software
    String? bbduk_docker = read_QC_trim.bbduk_docker
    Float? r1_mean_q = cg_pipeline.r1_mean_q
    Float? r2_mean_q = cg_pipeline.r2_mean_q

    #Assembly and Assembly QC
    File? assembly_fasta = shovill_pe.assembly_fasta
    File? contigs_gfa = shovill_pe.contigs_gfa
    File? contigs_fastg = shovill_pe.contigs_fastg
    File? contigs_lastgraph = shovill_pe.contigs_lastgraph
    String? shovill_pe_version = shovill_pe.shovill_version
    File? quast_report = quast.quast_report
    String? quast_version = quast.version
    Int? genome_length = quast.genome_length
    Int? number_contigs = quast.number_contigs
    Int? n50_value = quast.n50_value
    Float? gc_content = quast.gc_content
    File? cg_pipeline_report = cg_pipeline.cg_pipeline_report
    String? cg_pipeline_docker = cg_pipeline.cg_pipeline_docker
    Float? est_coverage = cg_pipeline.est_coverage
    String? busco_version = busco.busco_version
    String? busco_database = busco.busco_database
    String? busco_results = busco.busco_results
    File? busco_report = busco.busco_report
    Int? number_N = general_qc.number_N
    Int? number_ATCG = general_qc.number_ATCG
    Int? number_Degenerate = general_qc.number_Degenerate
    Int? number_Total = general_qc.number_Total
    #Taxon ID
    File? gambit_report = gambit.gambit_report_file
    File? gabmit_closest_genomes = gambit.gambit_closest_genomes_file
    String? gambit_predicted_taxon = gambit.gambit_predicted_taxon
    String? gambit_predicted_taxon_rank = gambit.gambit_predicted_taxon_rank
    String? gambit_predicted_strain = gambit.gambit_predicted_strain
    String? gambit_version = gambit.gambit_version
    String? gambit_db_version = gambit.gambit_db_version
    String? gambit_docker = gambit.gambit_docker

    String  kraken2_raw_version              = kraken2_raw.version
    Float   kraken2_raw_human                = kraken2_raw.percent_human
    String  kraken2_raw_report               = kraken2_raw.kraken_report
    String  kraken2_raw_genus              = kraken2_raw.kraken2_genus
    String   kraken2_raw_species                = kraken2_raw.kraken2_species
    String  kraken2_raw_strain               = kraken2_raw.kraken2_strain

    # Prokka Results
    File? prokka_gff = prokka.prokka_gff
    File? prokka_gbk = prokka.prokka_gbk
    File? prokka_sqn = prokka.prokka_sqn

  }
}
