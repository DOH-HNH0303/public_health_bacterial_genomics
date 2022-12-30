version 1.0

import "../tasks/phylogenetic_inference/task_ksnp3.wdl" as ksnp3
import "../tasks/phylogenetic_inference/task_ska.wdl" as ska
import "../tasks/phylogenetic_inference/task_iqtree.wdl" as iqtree

import "../tasks/task_versioning.wdl" as versioning

workflow recomb_aware_phylo_analysis {
  input {
    Array[File] assembly_fasta
    Array[String] samplename
    File reference_genome
    String cluster_name
    String iqtree_model = "NEWTEST"
  }
  call ska.ska as ska {
    input:
      assembly_fasta = assembly_fasta,
      samplename = samplename,
      cluster_name = cluster_name,
      reference = reference_genome
}
  call iqtree.iqtree as ska_iqtree {
    input:
      alignment = ska.ska_aln,
      cluster_name = cluster_name,
      iqtree_model = iqtree_model
  }
  output {
    File ska_aln = ska.ska_aln
    String ska_docker = ska.ska_docker_image
    String ska_iqtree_date = ska_iqtree.date
    String ska_iqtree_version = ska_iqtree.version
    File ska_iqtree_ml = ska_iqtree.ml_tree
    File ska_iqtree_report = ska_iqtree.iqtree_report
    File ska_iqtree_model = ska_iqtree.iqtree_model
  }
}
