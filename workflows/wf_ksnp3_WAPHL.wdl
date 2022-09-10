version 1.0

import "../tasks/phylogenetic_inference/task_ksnp3.wdl" as ksnp3
import "../tasks/phylogenetic_inference/task_roary.wdl" as roary
import "../tasks/phylogenetic_inference/task_snp_dists.wdl" as snp_dists
import "../tasks/task_versioning.wdl" as versioning

workflow ksnp3_workflow {
  input {
    Array[File] assembly_fasta
    Array[File] prokka_gff
    Array[String] samplename
    String cluster_name
    File transpose_py
    Array[File] ref_genomes
    Array[String] ref_genomes_string
	}
  scatter (i in ref_genomes) {
    String ref_names = basename(i)
  }
  Array[Array[String]] array_refs = [ref_genomes_string, ref_names]

  call roary.roary as roary {
    input:
			assembly_fasta = assembly_fasta,
      samplename = samplename,
      cluster_name = cluster_name,
      ref_genomes = ref_genomes,
      array_refs = array_refs,
      transpose_py = transpose_py,
      ref_names = ref_names,
      prokka_gff = prokka_gff
      }
	call ksnp3.ksnp3 as ksnp3_task {
		input:
			assembly_fasta = assembly_fasta,
      samplename = samplename,
      cluster_name = cluster_name,
      ref_genomes = ref_genomes,
      array_refs = array_refs,
      transpose_py = transpose_py,
      ref_names = ref_names
  }
  call snp_dists.snp_dists as core_snp_dists {
    input:
      cluster_name = cluster_name,
      alignment = ksnp3_task.ksnp3_core_matrix
  }
  call snp_dists.snp_dists as pan_snp_dists {
    input:
      cluster_name = cluster_name,
      alignment = ksnp3_task.ksnp3_pan_matrix
  }
  call versioning.version_capture{
    input:
  }
  output {
    # Version Capture
    String ksnp3_wf_version = version_capture.phbg_version
    String knsp3_wf_analysis_date = version_capture.date
    # ksnp3_outputs
    String ksnp3_snp_dists_version = pan_snp_dists.version
    File ksnp3_core_snp_matrix = core_snp_dists.snp_matrix
    File ksnp3_core_tree = ksnp3_task.ksnp3_core_tree
    File ksnp3_core_vcf = ksnp3_task.ksnp3_core_vcf
    File ksnp3_pan_snp_matrix = pan_snp_dists.snp_matrix
    File ksnp3_pan_parsimony_tree = ksnp3_task.ksnp3_pan_parsimony_tree
    String ksnp3_docker = ksnp3_task.ksnp3_docker_image
  }
}
