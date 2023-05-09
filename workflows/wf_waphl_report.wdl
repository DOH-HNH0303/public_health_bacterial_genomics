version 1.0

import "../tasks/utilities/task_report_waphl.wdl" as report

workflow waphl_report {

  input {
    String cluster_name
    File treefile
    Array[File?] roary_plot
    Array[File?] output_tars
    Array[File] isolate_tsvs
    Array[File] mlst_tsvs
    String organism="corynebacterium"
  }
  if (defined(output_tars)) {
  scatter (output_tar in output_tars) {
  call report.plot_roary_waphl as plot_roary{
    input:
      cluster_name=cluster_name,
      output_tar = output_tar,
      cluster_name=cluster_name
  }
}
  }
  call report.cdip_report as cdip_report {
  input:
    cluster_name=cluster_name,
    treefile=treefile,
    plot_roary=select_first([roary_plot, plot_roary.plot_roary_png]),
    assembly_tsvs = isolate_tsvs,
    mlst_tsvs = mlst_tsvs
    
  }

  output {
    File    report = cdip_report.report
  }
}

