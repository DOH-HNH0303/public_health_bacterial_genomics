version 1.0

import "wf_clade_analysis_WAPHL.wdl" as clade_analysis
import "../tasks/phylogenetic_inference/task_ska.wdl" as ska
import "../tasks/phylogenetic_inference/task_iqtree.wdl" as iqtree
import "../tasks/phylogenetic_inference/task_gubbins.wdl" as gubbins
import "../tasks/task_versioning.wdl" as versioning
import "wf_ksnp3_WAPHL.wdl" as ksnp3
import "../tasks/utilities/task_utilities.wdl" as utilities

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
    recomb = gubbins_init.recomb_gff

}
call ksnp3.ksnp3_workflow as ksnp3  {
  input:
    assembly_fasta = mask_gubbins_init.masked_fasta_list,
    samplename = samplename,
    cluster_name = cluster_name
}
call utilities.split_by_clade as split_by_clade  {
  input:
    snp_matrix = ksnp3.ksnp3_core_snp_matrix,
    cluster_name = cluster_name,
    snp_clade = snp_clade
}
scatter (i in split_by_clade.clade_list) {
call utilities.scatter_by_clade as scatter_by_clade  {
  input:
    clade_list = i,
    cluster_name = cluster_name,
    assembly_files = assembly_gff
}
call clade_analysis.clade_analysis as clade_analysis  {
  input:
    cluster_name = cluster_name,
    prokka_gff = scatter_by_clade.clade_files,
    reference_genome = reference_genome,
    samplename = samplename
}
}
  output {
    File ska_aln = ska.ska_aln
    String gubbins_date = gubbins_init.date
    String ska_docker = ska.ska_docker_image

    File gubbins_polymorph_site_fasta = gubbins_init.polymorph_site_fasta
    File gubbins_polymorph_site_phylip = gubbins_init.polymorph_site_phylip
    File gubbins_branch_stats = gubbins_init.branch_stats
    File gubbins_recomb_gff = gubbins_init.recomb_gff
    File gubbins_snps= gubbins_init.gubbins_snps

    File masked_aln = mask_gubbins_init.date
    File masked_fastas = mask_gubbins_init.masked_fastas
    Array[File] masked_fasta_list = mask_gubbins_init.masked_fasta_list

    File clade_list_file = split_by_clade.clade_list_file

    Array[File] gubbins_clade_polymorph_fasta = clade_analysis.gubbins_clade_polymorph_fasta
    Array[File] gubbins_clade_branch_stats = clade_analysis.gubbins_clade_branch_stats
    Array[File] gubbins_clade_recomb_gff = clade_analysis.gubbins_clade_recomb_gff

    Array[File?] masked_aln_core_clade = clade_analysis.masked_aln_core_clade
    Array[File?] masked_aln_pan_clade = clade_analysis.masked_aln_pan_clade

    Array[File] pirate_pangenome_summary = clade_analysis.pirate_pangenome_summary
    Array[File] pirate_gene_families_ordered = clade_analysis.pirate_gene_families_ordered
    Array[String] pirate_docker_image = clade_analysis.pirate_docker_image
    Array[String] pirate_for_scoary_csv = clade_analysis.pirate_for_scoary_csv
    # snp_dists outputs
    Array[String?] pirate_snps_dists_version = clade_analysis.pirate_snps_dists_version
    Array[File?] pirate_core_snp_matrix = clade_analysis.pirate_core_snp_matrix
    Array[File?] pirate_pan_snp_matrix = clade_analysis.pirate_pan_snp_matrix
    # iqtree outputs
    Array[String?] pirate_iqtree_version = clade_analysis.pirate_iqtree_version
    Array[File?] pirate_iqtree_core_tree = clade_analysis.pirate_iqtree_core_tree
    Array[File?] pirate_iqtree_pan_tree = clade_analysis.pirate_iqtree_pan_tree
    Array[File?] pirate_iqtree_pan_model = clade_analysis.pirate_iqtree_pan_model
    Array[File?] pirate_iqtree_core_model = clade_analysis.pirate_iqtree_core_model
  }
}
