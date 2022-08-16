version 1.0

import "../tasks/task_consensus.wdl" as consensus
import "../tasks/task_snp.wdl" as snp

workflow build_bacterial_consensus {

  input {
    String    id
    File      assembly_fasta
    File      reference_seq
  }

  call consensus.assembly_qc as denovo_qc{
    input:
      reference_seq=reference_seq,
      assembly_fasta=assembly_fasta
  }
  call consensus.bwa_pe_de_novo{
    input:
      id=id,
      assembly_fasta=assembly_fasta,
      reference_seq=reference_seq
  }

  call consensus.sam_to_bam {
    input:
      id=id,
      samfile=bwa_pe_de_novo.samfile
  }

  call consensus.bcftools_consensus {
    input:
      id=id,
      reference_seq=reference_seq,
      sorted_bam=sam_to_bam.sorted_bam
  }

  call consensus.assembly_qc as consensus_qc{
    input:
      reference_seq=reference_seq,
      assembly_fasta=bcftools_consensus.consensus_seq
  }


  output {
    File    bwa_pe_de_novo_software=bwa_pe_de_novo.image_software
    File    de_novo_bam=sam_to_bam.bamfile
    File    de_novo_sorted_bam=sam_to_bam.sorted_bam
    File    de_novo_indexed_bam=sam_to_bam.indexed_bam
    File    de_novo_sam_to_bam_software=sam_to_bam.image_software
    File    de_novo_consensus_seq=bcftools_consensus.consensus_seq
    File    de_novo_consensus_variants=bcftools_consensus.consensus_variants
    File    de_novo_bcftools_consensus_software=bcftools_consensus.image_software
    File    de_novo_consensus_qc_software=consensus_qc.image_software

    Int  de_novo_consensus_number_N=consensus_qc.assembly_number_N
    Int  de_novo_consensus_number_ATCG=consensus_qc.assembly_number_ATCG
    Int  de_novo_consensus_number_Degenerate=consensus_qc.assembly_number_Degenerate
    Int  de_novo_consensus_number_Total=consensus_qc.assembly_number_Total
    #Float  de_novo_consensus_percent_reference_coverage=consensus_qc.assembly_percent_reference_coverage

    Int  de_novo_assembly_number_N=denovo_qc.assembly_number_N
    Int  de_novo_assembly_number_ATCG=denovo_qc.assembly_number_ATCG
    Int  de_novo_assembly_number_Degenerate=denovo_qc.assembly_number_Degenerate
    Int  de_novo_assembly_number_Total=denovo_qc.assembly_number_Total
    #Float  de_novo_assembly_percent_reference_coverage=denovo_qc.assembly_percent_reference_coverage





  }
}
