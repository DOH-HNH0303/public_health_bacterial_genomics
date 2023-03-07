version 1.0

import "../tasks/phylogenetic_inference/task_ska.wdl" as ska
import "../tasks/phylogenetic_inference/task_iqtree.wdl" as iqtree
import "../tasks/phylogenetic_inference/task_gubbins.wdl" as gubbins
import "../tasks/phylogenetic_inference/task_pirate.wdl" as pirate
import "../tasks/phylogenetic_inference/task_snp_dists.wdl" as snp_dists
import "../tasks/task_versioning.wdl" as versioning
import "../tasks/gene_typing/task_prokka.wdl" as prokka
import "../tasks/phylogenetic_inference/task_ksnp3.wdl" as ksnp3


workflow clade_analysis {
  input {

    Array[File] prokka_gff
    Array[String] samplename
    String iqtree_model = "MFP"
    Boolean? core = true
    Boolean? pan = false
    String cluster_name
    Float filter_perc = 25.0

  }
  call pirate.pirate as pirate {
    input:
      prokka_gff = prokka_gff,
      cluster_name = cluster_name,
  }

call gubbins.gubbins as gubbins_clade {
  input:
    alignment = pirate.pirate_pangenome_alignment_fasta,
    filter_perc = filter_perc,
    cluster_name = cluster_name
}

if (pan == true) {
  if (gubbins_clade.gubbins_mask == true) {
    call gubbins.maskrc_svg as pan_mask_gubbins_clade  {
      input:
        alignment = pirate.pirate_pangenome_alignment_fasta,
        cluster_name = cluster_name,
        recomb = gubbins_clade.recomb_gff,
        base_reconstruct = gubbins_clade.base_reconstruct,
        recomb_embl = gubbins_clade.recomb_embl,
        polymorph_site_fasta = gubbins_clade.polymorph_site_fasta,
        polymorph_site_phylip = gubbins_clade.polymorph_site_phylip,
        branch_stats = gubbins_clade.branch_stats,
        gubbins_snps = gubbins_clade.gubbins_snps,
        gubbins_final_tre = gubbins_clade.gubbins_final_tre,
        gubbins_log = gubbins_clade.gubbins_log,
        gubbins_node_tre = gubbins_clade.gubbins_node_tre
    }
    call iqtree.iqtree as pan_iqtree {
      input:
        alignment = pan_mask_gubbins_clade.masked_aln,
        cluster_name = cluster_name,
        iqtree_model = iqtree_model
    }
}
  if (gubbins_clade.gubbins_mask == false) {
    call iqtree.iqtree as pan_iqtree {
      input:
        alignment = pan_mask_gubbins_clade.masked_aln,
        cluster_name = cluster_name,
        iqtree_model = iqtree_model
    }
  }
  call snp_dists.snp_dists as pan_snp_dists {
    input:
      alignment = pan_mask_gubbins_clade.masked_aln,
      cluster_name = cluster_name
  }
}
  if (core == true) {
    if (gubbins_clade.gubbins_mask == true) {
      call gubbins.maskrc_svg as core_mask_gubbins_clade  {
        input:
          alignment = pirate.pirate_core_alignment_fasta,
          cluster_name = cluster_name,
          recomb = gubbins_clade.recomb_gff,
          base_reconstruct = gubbins_clade.base_reconstruct,
          recomb_embl = gubbins_clade.recomb_embl,
          polymorph_site_fasta = gubbins_clade.polymorph_site_fasta,
          polymorph_site_phylip = gubbins_clade.polymorph_site_phylip,
          branch_stats = gubbins_clade.branch_stats,
          gubbins_snps = gubbins_clade.gubbins_snps,
          gubbins_final_tre = gubbins_clade.gubbins_final_tre,
          gubbins_log = gubbins_clade.gubbins_log,
          gubbins_node_tre = gubbins_clade.gubbins_node_tre
      }
      call ksnp3.ksnp3 as ksnp3_clade_core {
        input:
          assembly_fasta = core_mask_gubbins_clade.masked_fasta_list,
          samplename = samplename,
          cluster_name = cluster_name
      }
      call iqtree.iqtree as core_iqtree {
        input:
          alignment =ksnp3_clade_core.ksnp3_core_matrix,
          cluster_name = cluster_name,
          iqtree_model = iqtree_model
      }
    }
    if (gubbins_clade.gubbins_mask == false) {
      call iqtree.iqtree as core_iqtree {
        input:
          alignment =pirate.pirate_core_alignment_fasta,
          cluster_name = cluster_name,
          iqtree_model = iqtree_model
      }
    }
    call snp_dists.snp_dists as core_snp_dists {
      input:
        alignment = core_mask_gubbins_clade.masked_aln,
        cluster_name = cluster_name
    }
  }

  output {

    String gubbins_date = gubbins_clade.date
    File gubbins_clade_polymorph_fasta = gubbins_clade.polymorph_site_fasta
    File gubbins_clade_branch_stats = gubbins_clade.branch_stats
    File gubbins_clade_recomb_gff = gubbins_clade.recomb_gff


    File pirate_pangenome_summary = pirate.pirate_pangenome_summary
    File pirate_gene_families_ordered = pirate.pirate_gene_families_ordered
    String pirate_docker_image = pirate.pirate_docker_image
    String pirate_for_scoary_csv = pirate.pirate_for_scoary_csv
    # snp_dists outputs
    String? pirate_snps_dists_version = pan_snp_dists.version
    File? pirate_core_snp_matrix = core_snp_dists.snp_matrix
    File? pirate_pan_snp_matrix = pan_snp_dists.snp_matrix
    # iqtree outputs
    String? clade_iqtree_version = pan_iqtree.version
    File? clade_iqtree_core_tree = core_iqtree.ml_tree
    File? clade_iqtree_pan_tree = pan_iqtree.ml_tree
    File? clade_iqtree_pan_model = pan_iqtree.iqtree_model
    File? clade_iqtree_core_model = core_iqtree.iqtree_model

  }
}
