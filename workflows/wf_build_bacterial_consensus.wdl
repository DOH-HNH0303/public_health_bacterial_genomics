version 1.0

import "../tasks/task_consensus.wdl" as consensus
import "../tasks/task_snp.wdl" as snp

workflow build_bacterial_consensus {

  input {
    String    id
    File      reference_seq
    File    read1_trim
    File    read2_trim
  }


    call consensus.bowtie2_pe_ref_based{
      input:
        id=id,
        read1_trim=read1_trim,
        read2_trim=read2_trim,
        reference_seq=reference_seq
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
        assembly_fasta=ref_based_bcf_consensus.consensus_seq
    }


  output {
    #Float  de_novo_consensus_percent_reference_coverage=consensus_qc.assembly_percent_reference_coverage


    File?    ref_based_sorted_bam=bowtie2_pe_ref_based.sorted_bam
    File?    ref_based_indexed_bam =bowtie2_pe_ref_based.indexed_bam

    File?    ref_based_consensus_seq=ref_based_bcf_consensus.consensus_seq
    File?    ref_based_consensus_variants=ref_based_bcf_consensus.consensus_variants
    File?    ref_based_bcf_consensus_software=ref_based_bcf_consensus.image_software
    File?    ref_based_consensus_qc_software=ref_based_consensus_qc.image_software

    Int?  ref_based_consensus_number_N=ref_based_consensus_qc.assembly_number_N
    Int?  ref_based_consensus_number_ATCG=ref_based_consensus_qc.assembly_number_ATCG
    Int?  ref_based_consensus_number_Degenerate=ref_based_consensus_qc.assembly_number_Degenerate
    Int?  ref_based_consensus_number_Total=ref_based_consensus_qc.assembly_number_Total

    #Float  de_novo_assembly_percent_reference_coverage=denovo_qc.assembly_percent_reference_coverage





  }
}
