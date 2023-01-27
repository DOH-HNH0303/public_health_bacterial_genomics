version 1.0

import "../tasks/task_consensus.wdl" as consensus
import "../tasks/task_snp.wdl" as snp

workflow build_bacterial_consensus {

  input {
    String    id
    File      assembly_fasta
    File      reference_seq
    File    read1_trim
    File    read2_trim
    Boolean    de_novo=false
  }

    if (de_novo.read_screen==true) {
      call consensus.bwa_pe_de_novo{
        input:
          id=id,
          assembly_fasta=assembly_fasta,
          reference_seq=reference_seq
      }
      call consensus.sam_to_bam as de_novo_s2b{
        input:
          id=id,
          samfile=bwa_pe_de_novo.samfile
        }
      call consensus.bcftools_consensus as de_novo_bcf_consensus {
        input:
          id=id,
          reference_seq=reference_seq,
          sorted_bam=de_novo_s2b.sorted_bam
      }
      call consensus.assembly_qc as de_novo_consensus_qc{
        input:
          reference_seq=reference_seq,
          assembly_fasta= de_novo_bcf_consensus.consensus_seq
      }
    }
    if (de_novo.read_screen==false) {
      call consensus.bowtie2_pe_ref_based{
        input:
          id=id,
          read1_trim=read1_trim,
          read2_trim=read2_trim,
          reference_seq=reference_seq
      }
      call consensus.sam_to_bam as ref_based_s2b{
        input:
          id=id,
          samfile=bwa_pe_ref_based.samfile
        }
      call consensus.bcftools_consensus as ref_based_bcf_consensus {
        input:
          id=id,
          reference_seq=reference_seq,
          sorted_bam=bowtie2_pe_ref_based.sorted_bam
      }
      call consensus.assembly_qc as ref_based_consensus_qc{
        input:
          reference_seq=reference_seq,
          assembly_fasta=ref_based_bcftools_consensus.consensus_seq
      }
    }

  output {
    File?    bwa_pe_de_novo_software=bwa_pe_de_novo.image_software
    File?    de_novo_bam=de_novo_s2b.bamfile
    File?    de_novo_sorted_bam=de_novo_s2b.sorted_bam
    File?    de_novo_indexed_bam=de_novo_s2b.indexed_bam
    File?    de_novo_sam_to_bam_software=de_novo_s2b.image_software
    File?    de_novo_consensus_seq=de_novo_bcf_consensus.consensus_seq
    File?    de_novo_consensus_variants=de_novo_bcf_consensus.consensus_variants
    File?    de_novo_bcftools_consensus_software=de_novo_bcf_consensus.image_software
    File?    de_novo_consensus_qc_software=de_novo_consensus_qc.image_software

    Int?  de_novo_consensus_number_N=de_novo_consensus_qc.assembly_number_N
    Int?  de_novo_consensus_number_ATCG=de_novo_consensus_qc.assembly_number_ATCG
    Int?  de_novo_consensus_number_Degenerate=de_novo_consensus_qc.assembly_number_Degenerate
    Int?  de_novo_consensus_number_Total=de_novo_consensus_qc.assembly_number_Total
    #Float  de_novo_consensus_percent_reference_coverage=consensus_qc.assembly_percent_reference_coverage


    File?    ref_based_sorted_bam=bowtie2_pe_ref_based.sorted_bam
    File?    ref_based_indexed_bam =bowtie2_pe_ref_based.indexed_bam

    File?    ref_based_consensus_seq=ref_based_bcf_consensus.consensus_seq
    File?    ref_based_consensus_variants=ref_based_bcf_consensus.consensus_variants
    File?    ref_based_bcftools_consensus_software=ref_based_bcf_consensus.image_software
    File?    ref_based_consensus_qc_software=ref_based_consensus_qc.image_software

    Int?  ref_based_consensus_number_N=ref_based_consensus_qc.assembly_number_N
    Int?  ref_based_consensus_number_ATCG=ref_based_consensus_qc.assembly_number_ATCG
    Int?  ref_based_consensus_number_Degenerate=ref_based_consensus_qc.assembly_number_Degenerate
    Int?  ref_based_consensus_number_Total=ref_based_consensus_qc.assembly_number_Total

    #Float  de_novo_assembly_percent_reference_coverage=denovo_qc.assembly_percent_reference_coverage





  }
}
