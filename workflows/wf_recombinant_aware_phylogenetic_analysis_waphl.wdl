version 1.0

import "../tasks/phylogenetic_inference/task_ksnp3.wdl" as ksnp3
import "../tasks/phylogenetic_inference/task_ska.wdl" as ska
import "../tasks/phylogenetic_inference/task_iqtree.wdl" as iqtree
import "../tasks/phylogenetic_inference/task_gubbins.wdl" as gubbins
import "../tasks/task_versioning.wdl" as versioning
import "wf_ksnp3_WAPHL.wdl" as ksnp3

workflow recomb_aware_phylo_analysis {
  input {
    Array[File] assembly_fasta
    Array[File] assembly_gff
    Array[String] samplename
    File reference_genome
    String cluster_name
    String iqtree_model = "MFP"
    Int snp_clade = 150
  }
  call ska.ska as ska {
    input:
      assembly_fasta = assembly_fasta,
      samplename = samplename,
      cluster_name = cluster_name,
      reference = reference_genome
}
call gubbins.gubbins as gubbins_init {
  input:
    alignment = ska.ska_aln,
    cluster_name = cluster_name
}
call gubbins.mask_gubbins as mask_gubbins_init  {
  input:
    alignment = ska.ska_aln,
    cluster_name = cluster_name,
    recomb = gubbins_init.recomb_predictions

}
call ksnp3.ksnp3_workflow as ksnp3  {
  input:
    assembly_fasta = mask_gubbins_init.masked_fasta_list,
    samplename = samplename,
    cluster_name = cluster_name
}
call split_by_clade  {
  input:
    snp_matrix = ksnp3.ksnp3_core_snp_matrix,
    cluster_name = cluster_name,
    snp_clade = snp_clade
}
scatter (i in split_by_clade.clade_list) {
call split_by_clade  {
  input:
    clade_list = i,
    cluster_name = cluster_name,
    assembly_fastas = assembly_fastas
}
}
  output {
    File ska_aln = ska.ska_aln
    String gubbins_date = gubbins_init.date
    String ska_docker = ska.ska_docker_image

    String gubbins_date = gubbins.date
    File gubbins_polymorph_site_fasta = gubbins_init.polymorph_site_fasta
    File gubbins_polymorph_site_phylip = gubbins_init.polymorph_site_phylip
    File gubbins_branch_stats = gubbins_init.branch_stats
    File gubbins_recomb_gff = gubbins_init.recomb_gff
    File gubbins_snps= gubbins_init.gubbins_snps

    File masked_aln = mask_gubbins_init.date
    File masked_fastas = mask_gubbins_init.masked_fastas
    Array[File] masked_fasta_list = mask_gubbins_init.masked_fasta_list

    File clade_list_file = split_by_clade.clade_list_file
  }
}
