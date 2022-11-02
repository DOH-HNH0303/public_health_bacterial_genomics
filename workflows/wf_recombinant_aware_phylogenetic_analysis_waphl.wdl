version 1.0

import "../tasks/phylogenetic_inference/task_ksnp3.wdl" as ksnp3
import "../tasks/phylogenetic_inference/task_ska.wdl" as ska
import "../tasks/phylogenetic_inference/task_snp_dists.wdl" as snp_dists

import "../tasks/task_versioning.wdl" as versioning

workflow recomb_aware_phylo_analysis {
  input {
    Array[File] assembly_fasta
    Array[String] samplename
    File reference_genome
    String cluster_name
	}
	call ska.ska as ska {
		input:
			assembly_fasta = assembly_fasta,
      samplename = samplename,
      cluster_name = cluster_name,
      reference = reference_genome
}

  output {
    File ska_aln = ska.ska_aln
    String ska_docker = ska.ska_docker_image
  }
}
