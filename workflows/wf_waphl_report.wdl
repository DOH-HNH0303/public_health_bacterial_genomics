version 1.0

import "../tasks/utilities/task_report_waphl.wdl" as report

workflow waphl_report {

  input {
    String cluster_name
    File treefile
    File? recomb_gff
    File? pirate_aln_gff
    File? pirate_for_scoary_csv
    Array[File?] output_tar
  }

  call report.plot_roary_waphl {
    input:
      cluster_name=cluster_name,
      output_tar = output_tar,
      treefile=treefile,
      recomb_gff=recomb_gff,
      pirate_aln_gff=pirate_aln_gff,
      pirate_for_scoary_csv=pirate_for_scoary_csv,
      cluster_name=cluster_name
  }
  #   call report.cdip_report {
  #   input:
  #     cluster_name=cluster_name,
  #     treefile=treefile,
  #     recomb_gff=recomb_gff,
  #     pirate_aln_gff=pirate_aln_gff,
  #     pirate_for_scoary_csv=pirate_for_scoary_csv,
  #     cluster_name=cluster_name,
  #     snp_clade=snp_clade
  # }

  output {
    File    plot_roary_png  = plot_roary_waphl.plot_roary_png
  }
}

